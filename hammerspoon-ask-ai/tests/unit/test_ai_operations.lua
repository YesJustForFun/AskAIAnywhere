-- Unit tests for AI Operations
-- Run with: lua test_ai_operations.lua

local function run_tests()
    -- Mock dependencies
    local mockLLMClient = {
        config = {
            getOperations = function()
                return {
                    improve_writing = {
                        title = "Improve Writing",
                        description = "Enhance text quality",
                        prompt = "Improve this text:"
                    },
                    translate_chinese = {
                        title = "Translate to Chinese", 
                        description = "Translate to Chinese",
                        prompt = "Translate to Chinese:"
                    },
                    summarize = {
                        title = "Summarize",
                        description = "Create summary",
                        prompt = "Summarize this:"
                    }
                }
            end
        },
        formatPrompt = function(self, operation, text)
            return "Mock prompt for " .. operation .. ": " .. text
        end,
        executeWithFallback = function(self, prompt, callback)
            -- Mock successful response
            callback("Mock AI response for: " .. prompt, nil)
        end
    }
    
    -- Load the module
    package.path = package.path .. ";../modules/?.lua"
    local AIOperations = require('ai_operations')
    
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Test 1: AI Operations Creation
    tests.test_creation = function()
        local aiOps = AIOperations:new(mockLLMClient)
        assert(aiOps ~= nil, "AI Operations should be created")
        assert(aiOps.llmClient == mockLLMClient, "Should store LLM client reference")
        return true
    end
    
    -- Test 2: Get Available Operations
    tests.test_get_available_operations = function()
        local aiOps = AIOperations:new(mockLLMClient)
        local operations = aiOps:getAvailableOperations()
        
        assert(type(operations) == "table", "Should return table of operations")
        assert(#operations > 0, "Should have operations available")
        
        local found_improve = false
        for _, op in ipairs(operations) do
            assert(op.operation ~= nil, "Operation should have operation field")
            assert(op.title ~= nil, "Operation should have title field")
            assert(op.description ~= nil, "Operation should have description field")
            if op.operation == "improve_writing" then
                found_improve = true
            end
        end
        assert(found_improve, "Should include improve_writing operation")
        
        return true
    end
    
    -- Test 3: Execute Operation
    tests.test_execute_operation = function()
        local aiOps = AIOperations:new(mockLLMClient)
        local callback_called = false
        local callback_result = nil
        local callback_error = nil
        
        aiOps:execute("improve_writing", "Test input text", function(result, error)
            callback_called = true
            callback_result = result
            callback_error = error
        end)
        
        assert(callback_called, "Callback should be called")
        assert(callback_result ~= nil, "Should receive result")
        assert(callback_error == nil, "Should not receive error")
        
        return true
    end
    
    -- Test 4: Execute with Empty Input
    tests.test_execute_empty_input = function()
        local aiOps = AIOperations:new(mockLLMClient)
        local callback_called = false
        local callback_error = nil
        
        aiOps:execute("improve_writing", "", function(result, error)
            callback_called = true
            callback_error = error
        end)
        
        assert(callback_called, "Callback should be called")
        assert(callback_error ~= nil, "Should receive error for empty input")
        
        return true
    end
    
    -- Test 5: Execute Unknown Operation
    tests.test_execute_unknown_operation = function()
        local aiOps = AIOperations:new(mockLLMClient)
        local callback_called = false
        local callback_error = nil
        
        aiOps:execute("unknown_operation", "Test text", function(result, error)
            callback_called = true
            callback_error = error
        end)
        
        assert(callback_called, "Callback should be called")
        assert(callback_error ~= nil, "Should receive error for unknown operation")
        
        return true
    end
    
    -- Test 6: Post-process Result
    tests.test_post_process_result = function()
        local aiOps = AIOperations:new(mockLLMClient)
        
        -- Test whitespace trimming
        local result1 = aiOps:postProcessResult("improve_writing", "  Test result  ", "original")
        assert(result1 == "Test result", "Should trim whitespace")
        
        -- Test grammar fix cleaning
        local result2 = aiOps:postProcessResult("fix_grammar", "Here's the corrected text:\nFixed text", "original")
        assert(result2 == "Fixed text", "Should clean grammar fix prefix")
        
        -- Test translation cleaning
        local result3 = aiOps:postProcessResult("translate_chinese", "Translation:\n你好", "original")
        assert(result3 == "你好", "Should clean translation prefix")
        
        -- Test summary cleaning
        local result4 = aiOps:postProcessResult("summarize", "Here's a summary:\nThis is summary", "original")
        assert(result4 == "This is summary", "Should clean summary prefix")
        
        return true
    end
    
    -- Test 7: Custom Operation Execution
    tests.test_execute_custom_operation = function()
        local aiOps = AIOperations:new(mockLLMClient)
        local callback_called = false
        local callback_result = nil
        
        aiOps:executeCustomOperation("Custom prompt", "Input text", function(result, error)
            callback_called = true
            callback_result = result
        end)
        
        assert(callback_called, "Callback should be called")
        assert(callback_result ~= nil, "Should receive result")
        
        return true
    end
    
    -- Test 8: Validate Operation
    tests.test_validate_operation = function()
        local aiOps = AIOperations:new(mockLLMClient)
        
        assert(aiOps:validateOperation("improve_writing"), "Should validate existing operation")
        assert(not aiOps:validateOperation("nonexistent_operation"), "Should not validate nonexistent operation")
        
        return true
    end
    
    -- Test 9: Token Estimation
    tests.test_estimate_tokens = function()
        local aiOps = AIOperations:new(mockLLMClient)
        
        local tokens = aiOps:estimateTokens("Hello world")
        assert(type(tokens) == "number", "Should return number")
        assert(tokens > 0, "Should estimate positive tokens")
        
        -- Test longer text
        local longText = string.rep("word ", 100)
        local longTokens = aiOps:estimateTokens(longText)
        assert(longTokens > tokens, "Longer text should have more tokens")
        
        return true
    end
    
    -- Test 10: Text Length Check
    tests.test_check_text_length = function()
        local aiOps = AIOperations:new(mockLLMClient)
        
        local shortText = "Short text"
        local valid, count = aiOps:checkTextLength(shortText, 100)
        assert(valid, "Short text should be valid")
        assert(type(count) == "number", "Should return token count")
        
        local longText = string.rep("word ", 2000)
        local invalid, message = aiOps:checkTextLength(longText, 100)
        assert(not invalid, "Long text should be invalid with low limit")
        assert(type(message) == "string", "Should return error message")
        
        return true
    end
    
    -- Run tests
    print("Running AI Operations Tests...")
    print("=" .. string.rep("=", 40))
    
    for test_name, test_func in pairs(tests) do
        local success, result = pcall(test_func)
        if success and result then
            print("✓ " .. test_name)
            passed = passed + 1
        else
            print("✗ " .. test_name .. " - " .. (result or "Unknown error"))
            failed = failed + 1
        end
    end
    
    print("=" .. string.rep("=", 40))
    print(string.format("Results: %d passed, %d failed", passed, failed))
    
    return failed == 0
end

-- Run tests if this file is executed directly
if arg and arg[0] == "test_ai_operations.lua" then
    local success = run_tests()
    os.exit(success and 0 or 1)
end

return {run_tests = run_tests}