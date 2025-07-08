#!/usr/bin/env lua
-- Test runner for Ask AI Anywhere Hammerspoon implementation
-- Runs all unit and integration tests

local function run_all_tests()
    print("Ask AI Anywhere - Test Suite")
    print("=" .. string.rep("=", 60))
    print("Running comprehensive tests for Hammerspoon implementation")
    print("")
    
    local total_passed = 0
    local total_failed = 0
    local test_suites = {}
    
    -- Add test suite paths
    package.path = package.path .. ";unit/?.lua;integration/?.lua"
    
    -- Unit Tests
    print("UNIT TESTS")
    print("-" .. string.rep("-", 30))
    
    local unit_tests = {
        "test_config_manager",
        "test_ai_operations", 
        "test_hotkey_manager",
        "test_text_handler",
        "test_llm_client",
        "test_execution_context"
    }
    
    for _, test_name in ipairs(unit_tests) do
        print("Running " .. test_name .. "...")
        local success, test_module = pcall(require, test_name)
        
        if success and test_module and test_module.run_tests then
            local test_success = test_module.run_tests()
            if test_success then
                print("✓ " .. test_name .. " - ALL PASSED")
                total_passed = total_passed + 1
            else
                print("✗ " .. test_name .. " - SOME FAILED")
                total_failed = total_failed + 1
            end
        else
            print("✗ " .. test_name .. " - COULD NOT RUN")
            total_failed = total_failed + 1
        end
        print("")
    end
    
    -- Integration Tests
    print("INTEGRATION TESTS")
    print("-" .. string.rep("-", 30))
    
    local integration_tests = {
        "test_full_workflow",
        "test_end_to_end"
    }
    
    for _, test_name in ipairs(integration_tests) do
        print("Running " .. test_name .. "...")
        local success, test_module = pcall(require, test_name)
        
        if success and test_module and test_module.run_integration_tests then
            local test_success = test_module.run_integration_tests()
            if test_success then
                print("✓ " .. test_name .. " - ALL PASSED")
                total_passed = total_passed + 1
            else
                print("✗ " .. test_name .. " - SOME FAILED")
                total_failed = total_failed + 1
            end
        else
            print("✗ " .. test_name .. " - COULD NOT RUN")
            total_failed = total_failed + 1
        end
        print("")
    end
    
    -- Summary
    print("=" .. string.rep("=", 60))
    print("TEST SUMMARY")
    print(string.format("Total test suites: %d", total_passed + total_failed))
    print(string.format("Passed: %d", total_passed))
    print(string.format("Failed: %d", total_failed))
    
    if total_failed == 0 then
        print("\n🎉 ALL TESTS PASSED!")
        print("The Ask AI Anywhere implementation is ready for use.")
    else
        print("\n❌ SOME TESTS FAILED")
        print("Please review the test output and fix any issues before deployment.")
    end
    
    return total_failed == 0
end

-- Function to run tests with specific pattern
local function run_pattern_tests(pattern)
    print("Running tests matching pattern: " .. pattern)
    -- Implementation would filter tests by pattern
    return run_all_tests()
end

-- Function to run individual test
local function run_single_test(test_name)
    print("Running single test: " .. test_name)
    
    local success, test_module = pcall(require, test_name)
    if success and test_module then
        if test_module.run_tests then
            return test_module.run_tests()
        elseif test_module.run_integration_tests then
            return test_module.run_integration_tests()
        else
            print("Error: Test module does not have run_tests or run_integration_tests function")
            return false
        end
    else
        print("Error: Could not load test module " .. test_name)
        return false
    end
end

-- Command line interface
local function main()
    local args = arg or {}
    
    if #args == 0 then
        -- Run all tests
        local success = run_all_tests()
        os.exit(success and 0 or 1)
    elseif args[1] == "--help" or args[1] == "-h" then
        print("Ask AI Anywhere Test Runner")
        print("")
        print("Usage:")
        print("  lua run_tests.lua                 Run all tests")
        print("  lua run_tests.lua <test_name>     Run specific test")
        print("  lua run_tests.lua --pattern <p>   Run tests matching pattern")
        print("  lua run_tests.lua --help          Show this help")
        print("")
        print("Examples:")
        print("  lua run_tests.lua test_config_manager")
        print("  lua run_tests.lua --pattern config")
        os.exit(0)
    elseif args[1] == "--pattern" then
        if args[2] then
            local success = run_pattern_tests(args[2])
            os.exit(success and 0 or 1)
        else
            print("Error: --pattern requires a pattern argument")
            os.exit(1)
        end
    else
        -- Run specific test
        local success = run_single_test(args[1])
        os.exit(success and 0 or 1)
    end
end

-- Quick validation function
local function validate_environment()
    print("Validating test environment...")
    
    -- Check if required directories exist
    local required_dirs = {"unit", "integration", "../modules"}
    for _, dir in ipairs(required_dirs) do
        local file = io.open(dir, "r")
        if file then
            file:close()
        else
            -- Try to stat the directory
            local result = os.execute("test -d " .. dir .. " 2>/dev/null")
            if result ~= 0 then
                print("Warning: Directory " .. dir .. " not found")
            end
        end
    end
    
    -- Check if module files exist
    local required_modules = {
        "../modules/config_manager.lua",
        "../modules/ai_operations.lua", 
        "../modules/hotkey_manager.lua"
    }
    
    for _, module_path in ipairs(required_modules) do
        local file = io.open(module_path, "r")
        if file then
            file:close()
        else
            print("Warning: Module " .. module_path .. " not found")
        end
    end
    
    print("✓ Environment validation complete")
    print("")
end

-- Run validation and main
if arg and arg[0] and arg[0]:match("run_tests%.lua$") then
    validate_environment()
    main()
end

return {
    run_all_tests = run_all_tests,
    run_pattern_tests = run_pattern_tests,
    run_single_test = run_single_test,
    validate_environment = validate_environment
}