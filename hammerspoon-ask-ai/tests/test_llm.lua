-- test_llm.lua
-- Unit tests for LLM module

-- Mock Hammerspoon API for testing
local hs = {
    task = {
        new = function(path, callback, args)
            -- Mock task that simulates command execution
            return {
                start = function(self)
                    -- Simulate async execution
                    local command = args[2] -- Get the actual command from "-c", "command"
                    local output = ""
                    local exitCode = 0
                    
                    if string.find(command, "gemini") then
                        if string.find(command, "respond with just the word 'OK'") then
                            output = "OK"
                        else
                            output = "This is a mock response from Gemini."
                        end
                    elseif string.find(command, "claude") then
                        if string.find(command, "respond with just the word 'OK'") then
                            output = "OK"
                        else
                            output = "This is a mock response from Claude."
                        end
                    else
                        exitCode = 1
                        output = "Command not found"
                    end
                    
                    -- Call callback immediately for testing
                    callback(exitCode, output, "")
                end,
                isRunning = function(self) return false end,
                terminate = function(self) end,
                terminationStatus = function(self) return 0 end
            }
        end
    },
    timer = {
        secondsSinceEpoch = function() return os.time() end,
        usleep = function(microseconds) end
    },
    configdir = "/tmp/test_hammerspoon"
}

-- Setup global mocks first
_G.hs = hs

-- Mock config module
_G.mockConfig = {
    current = {
        llm = {
            default_provider = "gemini",
            gemini_command = "gemini -p",
            claude_command = "claude -p",
            timeout = 30
        }
    },
    get = function(key)
        local keys = {}
        for k in string.gmatch(key, "[^%.]+") do
            table.insert(keys, k)
        end
        
        local value = _G.mockConfig.current
        for _, k in ipairs(keys) do
            if value[k] then
                value = value[k]
            else
                return nil
            end
        end
        return value
    end
}

-- Replace require calls for testing
local originalRequire = require
_G.require = function(module)
    if module == "modules.config" then
        return _G.mockConfig
    end
    return originalRequire(module)
end

-- Load LLM module
local llm = require("modules.llm")

-- Test suite
local tests = {}

function tests.test_call_gemini()
    local success, response = llm.call("gemini", "Test prompt")
    assert(success, "Gemini call should succeed")
    assert(response and response ~= "", "Should get response from Gemini")
    assert(string.find(response, "Gemini"), "Response should mention Gemini")
    print("✅ test_call_gemini passed")
end

function tests.test_call_claude()
    local success, response = llm.call("claude", "Test prompt")
    assert(success, "Claude call should succeed")
    assert(response and response ~= "", "Should get response from Claude")
    assert(string.find(response, "Claude"), "Response should mention Claude")
    print("✅ test_call_claude passed")
end

function tests.test_call_invalid_provider()
    local success, response = llm.call("invalid", "Test prompt")
    assert(not success, "Invalid provider should fail")
    assert(string.find(response, "Unknown provider"), "Should get appropriate error message")
    print("✅ test_call_invalid_provider passed")
end

function tests.test_perform_operation_improve()
    local success, response = llm.performOperation("improve", "This is test text.")
    assert(success, "Improve operation should succeed")
    assert(response and response ~= "", "Should get improved text")
    print("✅ test_perform_operation_improve passed")
end

function tests.test_perform_operation_translate()
    local success, response = llm.performOperation("translate", "Hello world", {language = "Spanish"})
    assert(success, "Translate operation should succeed")
    assert(response and response ~= "", "Should get translated text")
    print("✅ test_perform_operation_translate passed")
end

function tests.test_perform_operation_no_text()
    local success, response = llm.performOperation("improve", "")
    assert(not success, "Should fail with empty text")
    assert(string.find(response, "No text provided"), "Should get appropriate error")
    print("✅ test_perform_operation_no_text passed")
end

function tests.test_perform_operation_no_operation()
    local success, response = llm.performOperation("", "Test text")
    assert(not success, "Should fail with empty operation")
    assert(string.find(response, "No operation specified"), "Should get appropriate error")
    print("✅ test_perform_operation_no_operation passed")
end

function tests.test_test_connection()
    local success, message = llm.test("gemini")
    assert(success, "Test connection should succeed for gemini")
    assert(string.find(message, "working correctly"), "Should get success message")
    print("✅ test_test_connection passed")
end

function tests.test_custom_prompt()
    local success, response = llm.performOperation("custom", "Test text", {
        prompt = "Please uppercase the following text:\n\n"
    })
    assert(success, "Custom prompt should succeed")
    assert(response and response ~= "", "Should get response for custom prompt")
    print("✅ test_custom_prompt passed")
end

-- Run all tests
function tests.run_all()
    print("Running LLM module tests...")
    tests.test_call_gemini()
    tests.test_call_claude()
    tests.test_call_invalid_provider()
    tests.test_perform_operation_improve()
    tests.test_perform_operation_translate()
    tests.test_perform_operation_no_text()
    tests.test_perform_operation_no_operation()
    tests.test_test_connection()
    tests.test_custom_prompt()
    print("All LLM tests passed! ✅")
end

-- Restore original require
_G.require = originalRequire

-- Export for use in other tests
return tests
