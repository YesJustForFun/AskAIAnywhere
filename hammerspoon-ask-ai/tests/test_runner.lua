-- test_runner.lua
-- Test runner for all modules

-- Set up test environment
package.path = "../?.lua;" .. package.path

-- Mock Hammerspoon environment for testing
_G.hs = {
    configdir = "/tmp/test_hammerspoon",
    json = {
        encode = function(t) return "mock_json" end,
        decode = function(s) return {test = "value"} end
    },
    task = {
        new = function() return {start = function() end} end
    },
    timer = {
        secondsSinceEpoch = function() return os.time() end,
        usleep = function() end,
        doAfter = function(delay, fn) fn() end  -- Execute immediately for testing
    },
    pasteboard = {
        getContents = function() return "mock clipboard content" end,
        setContents = function(content) end
    },
    notify = {
        new = function() return {send = function() end, withdraw = function() end} end
    },
    eventtap = {
        keyStroke = function() end,
        keyStrokes = function() end
    },
    chooser = {
        new = function() return {
            choices = function() end,
            width = function() end,
            rows = function() end,
            show = function() end,
            delete = function() end
        } end
    },
    dialog = {
        textPrompt = function() return "OK", "test response" end,
        blockAlert = function() end
    },
    hotkey = {
        bind = function() return {delete = function() end} end
    },
    spoons = {
        use = function() end
    },
    loadSpoon = function() end,
    reload = function() end
}

-- Load and run tests
local function runTests()
    print("=== Ask AI Anywhere Test Suite ===\n")
    
    local testResults = {
        total = 0,
        passed = 0,
        failed = 0
    }
    
    -- Test config module
    print("--- Testing Config Module ---")
    local configTests = require("test_config")
    local success, error = pcall(configTests.run_all)
    testResults.total = testResults.total + 1
    if success then
        testResults.passed = testResults.passed + 1
        print("Config module tests: PASSED ✅\n")
    else
        testResults.failed = testResults.failed + 1
        print("Config module tests: FAILED ❌")
        print("Error: " .. tostring(error) .. "\n")
    end
    
    -- Test LLM module
    print("--- Testing LLM Module ---")
    local llmTests = require("test_llm")
    local success, error = pcall(llmTests.run_all)
    testResults.total = testResults.total + 1
    if success then
        testResults.passed = testResults.passed + 1
        print("LLM module tests: PASSED ✅\n")
    else
        testResults.failed = testResults.failed + 1
        print("LLM module tests: FAILED ❌")
        print("Error: " .. tostring(error) .. "\n")
    end
    
    -- Test text operations module (basic loading test)
    print("--- Testing Text Operations Module ---")
    local success, error = pcall(function()
        require("modules.text_operations")
        print("✅ Text operations module loads successfully")
    end)
    testResults.total = testResults.total + 1
    if success then
        testResults.passed = testResults.passed + 1
        print("Text operations module: PASSED ✅\n")
    else
        testResults.failed = testResults.failed + 1
        print("Text operations module: FAILED ❌")
        print("Error: " .. tostring(error) .. "\n")
    end
    
    -- Test UI module (basic loading test)
    print("--- Testing UI Module ---")
    local success, error = pcall(function()
        require("modules.ui")
        print("✅ UI module loads successfully")
    end)
    testResults.total = testResults.total + 1
    if success then
        testResults.passed = testResults.passed + 1
        print("UI module: PASSED ✅\n")
    else
        testResults.failed = testResults.failed + 1
        print("UI module: FAILED ❌")
        print("Error: " .. tostring(error) .. "\n")
    end
    
    -- Test main init module (basic loading test)
    print("--- Testing Main Init Module ---")
    local success, error = pcall(function()
        -- Mock additional dependencies for init
        _G.debug = {
            getinfo = function() return {source = "@/test/init.lua"} end
        }
        _G.print = function(...) end  -- Suppress print output during testing
        local originalPrint = print
        local init = require("init")
        print = originalPrint
        print("✅ Main init module loads successfully")
    end)
    testResults.total = testResults.total + 1
    if success then
        testResults.passed = testResults.passed + 1
        print("Main init module: PASSED ✅\n")
    else
        testResults.failed = testResults.failed + 1
        print("Main init module: FAILED ❌")
        print("Error: " .. tostring(error) .. "\n")
    end
    
    -- Print summary
    print("=== Test Summary ===")
    print(string.format("Total: %d, Passed: %d, Failed: %d", 
          testResults.total, testResults.passed, testResults.failed))
    
    if testResults.failed == 0 then
        print("🎉 All tests passed!")
        return true
    else
        print("❌ Some tests failed!")
        return false
    end
end

-- Run the tests
local success = runTests()
os.exit(success and 0 or 1)
