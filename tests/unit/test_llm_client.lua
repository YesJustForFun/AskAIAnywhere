-- Unit tests for LLMClient module
-- Tests command building, text processing, and provider management

local function setup_test_environment()
    -- Add the parent directory to the path
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Mock Hammerspoon functions for testing
    hs = {
        task = {
            new = function(shell, callback, args)
                return {
                    start = function(self)
                        -- Mock successful execution
                        local mockOutput = "Mock LLM response"
                        callback(0, mockOutput, "")
                    end,
                    isRunning = function(self)
                        return false
                    end,
                    terminate = function(self)
                        -- Mock termination
                    end
                }
            end
        },
        timer = {
            doAfter = function(delay, fn)
                -- Mock timer - don't actually call fn for timeout simulation
            end
        }
    }
    
    -- Mock configuration manager
    local mockConfig = {
        getProviderConfig = function(self, provider)
            if provider == "test-provider" then
                return {
                    enabled = true,
                    command = "test-command",
                    args = {"-p", "test-arg"},
                    timeout = 30
                }
            elseif provider == "gemini-py" then
                return {
                    enabled = true,
                    command = "gemini.py",
                    args = {"--api-key", "test-key"},
                    timeout = 30
                }
            end
            return nil
        end,
        getDefaultProvider = function(self)
            return "test-provider"
        end,
        getFallbackProvider = function(self)
            return "gemini-py"
        end,
        getLLMConfig = function(self)
            return {
                providers = {
                    ["test-provider"] = {
                        enabled = true,
                        command = "test-command"
                    },
                    ["gemini-py"] = {
                        enabled = true,
                        command = "gemini.py"
                    }
                },
                defaultProvider = "test-provider"
            }
        end,
        get = function(self, key)
            if key == "environment.paths" then
                return {"/usr/local/bin", "/opt/homebrew/bin"}
            end
            return nil
        end
    }
    
    return mockConfig
end

local function test_shell_escaping()
    print("Testing shell argument escaping...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local test_cases = {
        {
            input = "simple text",
            expected = "'simple text'",
            description = "Simple text should be quoted"
        },
        {
            input = "text with 'quotes'",
            expected = "'text with '\"'\"'quotes'\"'\"''",
            description = "Text with quotes should be properly escaped"
        },
        {
            input = "text with $variables",
            expected = "'text with $variables'",
            description = "Variables should be escaped"
        },
        {
            input = "text with `backticks`",
            expected = "'text with `backticks`'",
            description = "Backticks should be escaped"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = client:escapeShellArg(test_case.input)
        if result == test_case.expected then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: " .. test_case.expected)
            print("  Got: " .. result)
        end
    end
    
    print(string.format("Shell escaping tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_special_character_detection()
    print("Testing special character detection...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local test_cases = {
        {
            input = "simple text",
            expected = true,  -- Has spaces
            description = "Simple text with spaces"
        },
        {
            input = "text'with'quotes",
            expected = true,
            description = "Text with quotes"
        },
        {
            input = "text$with$variables",
            expected = true,
            description = "Text with variables"
        },
        {
            input = "simpletext",
            expected = false,
            description = "Simple text without special chars"
        },
        {
            input = "text|with|pipes",
            expected = true,
            description = "Text with pipes"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = client:hasSpecialCharacters(test_case.input)
        if result == test_case.expected then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: " .. tostring(test_case.expected))
            print("  Got: " .. tostring(result))
        end
    end
    
    print(string.format("Special character detection tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_command_building()
    print("Testing command building...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local providerConfig = {
        command = "test-command",
        args = {"-p", "param1", "--flag"},
        timeout = 30
    }
    
    -- Test simple command (should use direct piping)
    local simplePrompt = "Helloworld"  -- No spaces to avoid special char detection
    local simpleCommand = client:buildCommand(providerConfig, simplePrompt)
    
    if simpleCommand and simpleCommand:match("echo.*test%-command") then
        print("✓ Simple command uses direct piping")
    elseif simpleCommand and simpleCommand:match("test%-command.*</tmp/") then
        print("✓ Simple command uses temp file (acceptable)")
    else
        print("✗ Simple command building failed")
        print("  Got: " .. (simpleCommand or "nil"))
        return false
    end
    
    -- Test complex command (should use temp file)
    local complexPrompt = string.rep("Complex prompt with special chars: $'\"` |&;", 100)
    local complexCommand = client:buildCommand(providerConfig, complexPrompt)
    
    if complexCommand and complexCommand:match("test%-command.*<.*tmp.*txt") then
        print("✓ Complex command uses temp file")
    else
        print("✗ Complex command building failed")
        print("  Got: " .. (complexCommand or "nil"))
        print("  Expected pattern: test%-command.*<.*tmp.*txt")
        return false
    end
    
    return true
end

local function test_temp_file_operations()
    print("Testing temporary file operations...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local testContent = "This is test content\nwith multiple lines\nand special chars: !@#$%"
    local tempFile = "/tmp/test_ask_ai_" .. os.time() .. ".txt"
    
    -- Test writing to temp file
    local success, error = client:writeToTempFile(tempFile, testContent)
    
    if not success then
        print("✗ Failed to write temp file: " .. (error or "unknown error"))
        return false
    end
    
    -- Test reading back the content
    local file = io.open(tempFile, "r")
    if not file then
        print("✗ Failed to read temp file")
        return false
    end
    
    local readContent = file:read("*all")
    file:close()
    
    -- Clean up
    os.remove(tempFile)
    
    if readContent == testContent then
        print("✓ Temp file operations work correctly")
        return true
    else
        print("✗ Temp file content mismatch")
        print("  Expected: " .. testContent)
        print("  Got: " .. readContent)
        return false
    end
end

local function test_provider_validation()
    print("Testing provider validation...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    -- Test configuration validation
    local isValid, issues = client:validateConfiguration()
    
    if isValid then
        print("✓ Configuration validation passed")
    else
        print("✗ Configuration validation failed")
        for _, issue in ipairs(issues) do
            print("  Issue: " .. issue)
        end
        return false
    end
    
    return true
end

local function test_path_expansion()
    print("Testing path expansion...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local test_cases = {
        {
            input = "~/Documents/test.txt",
            expected_pattern = "^/Users/.*Documents/test%.txt$",
            description = "Tilde expansion"
        },
        {
            input = "$HOME/test.txt",
            expected_pattern = "^/Users/.*test%.txt$",
            description = "$HOME expansion"
        },
        {
            input = "/absolute/path/test.txt",
            expected_pattern = "^/absolute/path/test%.txt$",
            description = "Absolute path unchanged"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = client:expandPath(test_case.input)
        if result:match(test_case.expected_pattern) then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Input: " .. test_case.input)
            print("  Expected pattern: " .. test_case.expected_pattern)
            print("  Got: " .. result)
        end
    end
    
    print(string.format("Path expansion tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_environment_command_building()
    print("Testing environment command building...")
    
    local mockConfig = setup_test_environment()
    local llmClient = require('llm_client')
    local client = llmClient:new(mockConfig)
    
    local envCommand = client:buildEnvironmentCommand()
    
    -- Should include custom paths
    if envCommand:match("export PATH=") and envCommand:match("/usr/local/bin") then
        print("✓ Environment command includes custom paths")
        return true
    else
        print("✗ Environment command building failed")
        print("  Got: " .. (envCommand or "nil"))
        return false
    end
end

local function run_tests()
    print("Running LLMClient unit tests...")
    print("=" .. string.rep("=", 40))
    
    local tests = {
        test_shell_escaping,
        test_special_character_detection,
        test_command_building,
        test_temp_file_operations,
        test_provider_validation,
        test_path_expansion,
        test_environment_command_building
    }
    
    local passed = 0
    local total = #tests
    
    for i, test_func in ipairs(tests) do
        print("")
        local success = test_func()
        if success then
            passed = passed + 1
        end
    end
    
    print("")
    print("=" .. string.rep("=", 40))
    print(string.format("LLMClient tests: %d/%d passed", passed, total))
    
    return passed == total
end

return {
    run_tests = run_tests,
    test_shell_escaping = test_shell_escaping,
    test_special_character_detection = test_special_character_detection,
    test_command_building = test_command_building,
    test_temp_file_operations = test_temp_file_operations,
    test_provider_validation = test_provider_validation,
    test_path_expansion = test_path_expansion,
    test_environment_command_building = test_environment_command_building
}