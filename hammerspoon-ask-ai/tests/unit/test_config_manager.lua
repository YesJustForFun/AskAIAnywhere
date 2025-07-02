-- Unit tests for Config Manager
-- Run with: lua test_config_manager.lua

local function run_tests()
    -- Mock hs module for testing
    hs = {
        configdir = "/tmp/test_hammerspoon",
        json = {
            encode = function(obj) return "mock_json" end,
            decode = function(str) return {test = "data"} end
        },
        alert = {
            show = function(msg) print("Alert: " .. msg) end
        }
    }
    
    -- Create temp directory for testing
    os.execute("mkdir -p /tmp/test_hammerspoon")
    
    -- Load the module
    package.path = package.path .. ";../modules/?.lua"
    local ConfigManager = require('config_manager')
    
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Test 1: Config Manager Creation
    tests.test_creation = function()
        local config = ConfigManager:new()
        assert(config ~= nil, "Config manager should be created")
        assert(type(config.config) == "table", "Config should be a table")
        return true
    end
    
    -- Test 2: Default Config Loading
    tests.test_default_config = function()
        local config = ConfigManager:new()
        -- Create a mock default config file
        local defaultConfig = {
            version = "1.0.0",
            llm = {
                defaultProvider = "claude"
            },
            test = "value"
        }
        
        -- Write mock config file
        local file = io.open("/tmp/test_hammerspoon/default_config.json", "w")
        file:write('{"version":"1.0.0","llm":{"defaultProvider":"claude"},"test":"value"}')
        file:close()
        
        local result = config:loadDefaultConfig()
        assert(type(result) == "table", "Default config should be loaded as table")
        return true
    end
    
    -- Test 3: Config Merging
    tests.test_config_merge = function()
        local config = ConfigManager:new()
        local default = {
            a = 1,
            b = {
                c = 2,
                d = 3
            }
        }
        local user = {
            b = {
                c = 99
            },
            e = 5
        }
        
        local merged = config:mergeConfigs(default, user)
        assert(merged.a == 1, "Default value should be preserved")
        assert(merged.b.c == 99, "User value should override default")
        assert(merged.b.d == 3, "Nested default value should be preserved")
        assert(merged.e == 5, "User value should be added")
        return true
    end
    
    -- Test 4: Get/Set Configuration
    tests.test_get_set = function()
        local config = ConfigManager:new()
        config.config = {
            test = {
                nested = {
                    value = "original"
                }
            }
        }
        
        -- Test get
        local value = config:get("test.nested.value")
        assert(value == "original", "Should get nested value")
        
        -- Test get with default
        local defaultValue = config:get("nonexistent.key", "default")
        assert(defaultValue == "default", "Should return default for nonexistent key")
        
        -- Test set
        config:set("test.nested.value", "modified")
        assert(config:get("test.nested.value") == "modified", "Should set nested value")
        
        -- Test set new path
        config:set("new.path.value", "new")
        assert(config:get("new.path.value") == "new", "Should create new nested path")
        
        return true
    end
    
    -- Test 5: Helper methods
    tests.test_helpers = function()
        local config = ConfigManager:new()
        config.config = {
            hotkeys = {test = "hotkey"},
            llm = {
                defaultProvider = "claude",
                fallbackProvider = "gemini",
                providers = {
                    claude = {enabled = true}
                }
            },
            operations = {test = "operation"},
            ui = {outputMethod = "display"}
        }
        
        assert(config:getHotkeys().test == "hotkey", "Should get hotkeys")
        assert(config:getLLMConfig().defaultProvider == "claude", "Should get LLM config")
        assert(config:getOperations().test == "operation", "Should get operations")
        assert(config:getOutputMethod() == "display", "Should get output method")
        assert(config:getDefaultProvider() == "claude", "Should get default provider")
        assert(config:getFallbackProvider() == "gemini", "Should get fallback provider")
        assert(config:getProviderConfig("claude").enabled == true, "Should get provider config")
        
        return true
    end
    
    -- Run tests
    print("Running Config Manager Tests...")
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
    
    -- Cleanup
    os.execute("rm -rf /tmp/test_hammerspoon")
    
    return failed == 0
end

-- Run tests if this file is executed directly
if arg and arg[0] == "test_config_manager.lua" then
    local success = run_tests()
    os.exit(success and 0 or 1)
end

return {run_tests = run_tests}