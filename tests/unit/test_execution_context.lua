-- Unit tests for ExecutionContext module
-- Tests variable substitution, context management, and action execution

local function setup_test_environment()
    -- Add the parent directory to the path
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Mock configuration
    local mockConfig = {
        get = function(self, key)
            if key == "llm.defaultProvider" then
                return "test-provider"
            elseif key == "ui.default" then
                return {outputMethod = "display", showProgress = true}
            elseif key == "prompts.test_prompt" then
                return {
                    title = "Test Prompt",
                    description = "A test prompt",
                    template = "Process this text: ${input}"
                }
            end
            return nil
        end
    }
    
    -- Mock components
    local mockComponents = {
        textHandler = {
            getSelectedText = function(self)
                return "Mock selected text"
            end,
            getClipboard = function(self)
                return "Mock clipboard text"
            end,
            setClipboard = function(self, text)
                -- Mock clipboard set
            end
        },
        llmClient = {
            execute = function(self, provider, prompt, callback)
                -- Mock LLM execution
                callback("Mock LLM response", nil)
            end
        },
        uiManager = {
            showResult = function(self, result)
                -- Mock UI display
            end
        },
        actionRegistry = {
            execute = function(self, actionName, args, context)
                if actionName == "test-action" then
                    return "test-result"
                end
                return nil
            end
        }
    }
    
    return mockConfig, mockComponents
end

local function test_variable_substitution()
    print("Testing variable substitution...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local context = ExecutionContext:new("test input", mockConfig, mockComponents)
    
    -- Set some test variables
    context:setVariable("testVar", "test value")
    context:setVariable("number", 42)
    
    local test_cases = {
        {
            input = "Hello ${testVar}",
            expected = "Hello test value",
            description = "Simple variable substitution"
        },
        {
            input = "Number is ${number}",
            expected = "Number is 42",
            description = "Number variable substitution"
        },
        {
            input = "Input: ${input}",
            expected = "Input: test input",
            description = "Built-in input variable"
        },
        {
            input = "No variables here",
            expected = "No variables here",
            description = "Text without variables"
        },
        {
            input = "${nonexistent}",
            expected = "",
            description = "Non-existent variable becomes empty"
        },
        {
            input = "Date: ${date}",
            expected_pattern = "^Date: %d%d%d%d%-%d%d%-%d%d$",
            description = "Built-in date variable"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = context:substituteVariables(test_case.input)
        local success = false
        
        if test_case.expected then
            success = (result == test_case.expected)
        elseif test_case.expected_pattern then
            success = (result:match(test_case.expected_pattern) ~= nil)
        end
        
        if success then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            if test_case.expected then
                print("  Expected: " .. test_case.expected)
            elseif test_case.expected_type then
                print("  Expected type: " .. test_case.expected_type)
            elseif test_case.expected_pattern then
                print("  Expected pattern: " .. test_case.expected_pattern)
            end
            print("  Got: " .. result)
        end
    end
    
    print(string.format("Variable substitution tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_dot_notation_resolution()
    print("Testing dot notation variable resolution...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local context = ExecutionContext:new("test input", mockConfig, mockComponents)
    
    local test_cases = {
        {
            input = "${llm.defaultProvider}",
            expected = "test-provider",
            description = "Config dot notation"
        },
        {
            input = "UI config: ${ui.default}",
            expected_pattern = "UI config: table:",
            description = "Config object resolution"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = context:substituteVariables(test_case.input)
        local success = false
        
        if test_case.expected then
            success = (result == test_case.expected)
        elseif test_case.expected_type then
            success = (type(result) == test_case.expected_type)
        elseif test_case.expected_pattern then
            success = (result:match(test_case.expected_pattern) ~= nil)
        end
        
        if success then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            if test_case.expected then
                print("  Expected: " .. test_case.expected)
            else
                print("  Expected type: " .. test_case.expected_type)
            end
            print("  Got: " .. tostring(result) .. " (type: " .. type(result) .. ")")
        end
    end
    
    print(string.format("Dot notation tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_context_hierarchy()
    print("Testing context hierarchy...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local parentContext = ExecutionContext:new("parent input", mockConfig, mockComponents)
    parentContext:setVariable("parentVar", "parent value")
    parentContext:setVariable("sharedVar", "parent shared")
    
    local childContext = parentContext:createChild()
    childContext:setVariable("childVar", "child value")
    childContext:setVariable("sharedVar", "child shared")
    
    local test_cases = {
        {
            context = childContext,
            variable = "childVar",
            expected = "child value",
            description = "Child context should access child variables"
        },
        {
            context = childContext,
            variable = "parentVar",
            expected = "parent value",
            description = "Child context should access parent variables"
        },
        {
            context = childContext,
            variable = "sharedVar",
            expected = "child shared",
            description = "Child variables should override parent variables"
        },
        {
            context = parentContext,
            variable = "childVar",
            expected = nil,
            description = "Parent context should not access child variables"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = test_case.context:getVariable(test_case.variable)
        local success = (result == test_case.expected)
        
        if success then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: " .. tostring(test_case.expected))
            print("  Got: " .. tostring(result))
        end
    end
    
    print(string.format("Context hierarchy tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_execution_depth_limits()
    print("Testing execution depth limits...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local context = ExecutionContext:new("test input", mockConfig, mockComponents)
    
    -- Test depth tracking
    local child1 = context:createChild()
    local child2 = child1:createChild()
    local child3 = child2:createChild()
    
    if context.executionDepth == 0 and 
       child1.executionDepth == 1 and 
       child2.executionDepth == 2 and 
       child3.executionDepth == 3 then
        print("✓ Execution depth tracking works correctly")
        return true
    else
        print("✗ Execution depth tracking failed")
        print("  Parent depth: " .. context.executionDepth)
        print("  Child1 depth: " .. child1.executionDepth)
        print("  Child2 depth: " .. child2.executionDepth)
        print("  Child3 depth: " .. child3.executionDepth)
        return false
    end
end

local function test_loop_detection()
    print("Testing loop detection...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local context = ExecutionContext:new("test input", mockConfig, mockComponents)
    
    -- Test that we can't execute when already executing
    context.isExecuting = true
    
    local actions = {{name = "test-action", args = {}}}
    
    local success, error = pcall(context.executeActions, context, actions)
    
    if not success and error:match("Loop detected") then
        print("✓ Loop detection works correctly")
        return true
    else
        print("✗ Loop detection failed")
        print("  Expected loop detection error")
        print("  Got: " .. tostring(error))
        return false
    end
end

local function test_input_validation()
    print("Testing input validation...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    -- Test with valid input
    local context1 = ExecutionContext:new("valid input", mockConfig, mockComponents)
    local validatedInput = context1:validateInput()
    
    if validatedInput == "valid input" then
        print("✓ Valid input validation works")
    else
        print("✗ Valid input validation failed")
        return false
    end
    
    -- Test with empty input (should get from textHandler)
    local context2 = ExecutionContext:new("", mockConfig, mockComponents)
    local validatedInput2 = context2:validateInput()
    
    if validatedInput2 == "Mock selected text" then
        print("✓ Empty input validation with text selection works")
    else
        print("✗ Empty input validation failed")
        print("  Expected: Mock selected text")
        print("  Got: " .. tostring(validatedInput2))
        return false
    end
    
    -- Test command detection
    local context3 = ExecutionContext:new("gemini.py --api-key test", mockConfig, mockComponents)
    local validatedInput3 = context3:validateInput()
    
    if validatedInput3 == "Mock selected text" then
        print("✓ Command detection and fresh input retrieval works")
    else
        print("✗ Command detection failed")
        print("  Expected: Mock selected text")
        print("  Got: " .. tostring(validatedInput3))
        return false
    end
    
    return true
end

local function test_metadata_management()
    print("Testing metadata management...")
    
    local mockConfig, mockComponents = setup_test_environment()
    local ExecutionContext = require('execution_context')
    
    local context = ExecutionContext:new("test input", mockConfig, mockComponents)
    
    -- Test setting and getting metadata
    context:setMetadata("testKey", "testValue")
    context:setMetadata("numKey", 123)
    
    local value1 = context:getMetadata("testKey")
    local value2 = context:getMetadata("numKey")
    local value3 = context:getMetadata("nonexistent")
    
    if value1 == "testValue" and value2 == 123 and value3 == nil then
        print("✓ Metadata management works correctly")
        return true
    else
        print("✗ Metadata management failed")
        print("  testKey: " .. tostring(value1))
        print("  numKey: " .. tostring(value2))
        print("  nonexistent: " .. tostring(value3))
        return false
    end
end

local function run_tests()
    print("Running ExecutionContext unit tests...")
    print("=" .. string.rep("=", 40))
    
    local tests = {
        test_variable_substitution,
        test_dot_notation_resolution,
        test_context_hierarchy,
        test_execution_depth_limits,
        test_loop_detection,
        test_input_validation,
        test_metadata_management
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
    print(string.format("ExecutionContext tests: %d/%d passed", passed, total))
    
    return passed == total
end

return {
    run_tests = run_tests,
    test_variable_substitution = test_variable_substitution,
    test_dot_notation_resolution = test_dot_notation_resolution,
    test_context_hierarchy = test_context_hierarchy,
    test_execution_depth_limits = test_execution_depth_limits,
    test_loop_detection = test_loop_detection,
    test_input_validation = test_input_validation,
    test_metadata_management = test_metadata_management
}