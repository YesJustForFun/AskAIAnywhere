-- Unit tests for Hotkey Manager
-- Run with: lua test_hotkey_manager.lua

local function run_tests()
    -- Mock hs module for testing
    hs = {
        hotkey = {
            bind = function(modifiers, key, callback)
                return {
                    delete = function() end
                }
            end
        }
    }
    
    -- Load the module
    package.path = package.path .. ";../modules/?.lua"
    local HotkeyManager = require('hotkey_manager')
    
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Test 1: Hotkey Manager Creation
    tests.test_creation = function()
        local hkm = HotkeyManager:new()
        assert(hkm ~= nil, "Hotkey manager should be created")
        assert(type(hkm.hotkeys) == "table", "Should have hotkeys table")
        assert(type(hkm.registeredKeys) == "table", "Should have registeredKeys table")
        return true
    end
    
    -- Test 2: Create Hotkey ID
    tests.test_create_hotkey_id = function()
        local hkm = HotkeyManager:new()
        
        local id1 = hkm:createHotkeyId({"cmd", "shift"}, "a")
        assert(type(id1) == "string", "Should return string ID")
        assert(id1 == "cmd+shift+a", "Should create correct ID")
        
        -- Test order independence
        local id2 = hkm:createHotkeyId({"shift", "cmd"}, "a")
        assert(id1 == id2, "Should create same ID regardless of modifier order")
        
        return true
    end
    
    -- Test 3: Validate Hotkey Config
    tests.test_validate_hotkey_config = function()
        local hkm = HotkeyManager:new()
        
        -- Valid config
        local validConfig = {
            key = "a",
            modifiers = {"cmd", "shift"}
        }
        local valid, message = hkm:validateHotkeyConfig(validConfig)
        assert(valid, "Valid config should pass validation")
        
        -- Invalid - no key
        local invalidConfig1 = {
            modifiers = {"cmd"}
        }
        local invalid1, message1 = hkm:validateHotkeyConfig(invalidConfig1)
        assert(not invalid1, "Config without key should fail")
        assert(type(message1) == "string", "Should return error message")
        
        -- Invalid - no modifiers
        local invalidConfig2 = {
            key = "a"
        }
        local invalid2, message2 = hkm:validateHotkeyConfig(invalidConfig2)
        assert(not invalid2, "Config without modifiers should fail")
        
        -- Invalid - empty modifiers
        local invalidConfig3 = {
            key = "a",
            modifiers = {}
        }
        local invalid3, message3 = hkm:validateHotkeyConfig(invalidConfig3)
        assert(not invalid3, "Config with empty modifiers should fail")
        
        -- Invalid - bad modifier
        local invalidConfig4 = {
            key = "a",
            modifiers = {"invalid_modifier"}
        }
        local invalid4, message4 = hkm:validateHotkeyConfig(invalidConfig4)
        assert(not invalid4, "Config with invalid modifier should fail")
        
        return true
    end
    
    -- Test 4: Bind Hotkey
    tests.test_bind_hotkey = function()
        local hkm = HotkeyManager:new()
        
        local config = {
            key = "a",
            modifiers = {"cmd", "shift"}
        }
        
        local callback = function() end
        local success, id = hkm:bind(config, callback)
        
        assert(success, "Binding should succeed")
        assert(type(id) == "string", "Should return hotkey ID")
        assert(hkm.registeredKeys[id] ~= nil, "Should register the hotkey")
        
        return true
    end
    
    -- Test 5: Unbind Hotkey
    tests.test_unbind_hotkey = function()
        local hkm = HotkeyManager:new()
        
        local config = {
            key = "a",
            modifiers = {"cmd", "shift"}
        }
        
        local callback = function() end
        local success, id = hkm:bind(config, callback)
        assert(success, "Binding should succeed")
        
        local unbindSuccess = hkm:unbind(id)
        assert(unbindSuccess, "Unbinding should succeed")
        assert(hkm.registeredKeys[id] == nil, "Should unregister the hotkey")
        
        return true
    end
    
    -- Test 6: Check Hotkey Registration
    tests.test_is_hotkey_registered = function()
        local hkm = HotkeyManager:new()
        
        local modifiers = {"cmd", "shift"}
        local key = "a"
        
        assert(not hkm:isHotkeyRegistered(modifiers, key), "Should not be registered initially")
        
        local config = {key = key, modifiers = modifiers}
        hkm:bind(config, function() end)
        
        assert(hkm:isHotkeyRegistered(modifiers, key), "Should be registered after binding")
        
        return true
    end
    
    -- Test 7: Format Hotkey Display
    tests.test_format_hotkey_display = function()
        local hkm = HotkeyManager:new()
        
        local display1 = hkm:formatHotkeyDisplay({"cmd", "shift"}, "a")
        assert(display1 == "⇧⌘A", "Should format display correctly")
        
        local display2 = hkm:formatHotkeyDisplay({"ctrl", "alt"}, "f1")
        assert(display2 == "⌃⌥F1", "Should format special keys correctly")
        
        return true
    end
    
    -- Test 8: Check Conflicts
    tests.test_check_conflicts = function()
        local hkm = HotkeyManager:new()
        
        -- Test system hotkey conflict
        local hasConflict1, message1 = hkm:checkConflicts({"cmd"}, "space")
        assert(hasConflict1, "Should detect system hotkey conflict")
        assert(type(message1) == "string", "Should return conflict message")
        
        -- Test non-conflicting hotkey
        local hasConflict2, message2 = hkm:checkConflicts({"cmd", "shift"}, "z")
        assert(not hasConflict2, "Should not detect conflict for non-system hotkey")
        
        return true
    end
    
    -- Test 9: Suggest Alternatives
    tests.test_suggest_alternatives = function()
        local hkm = HotkeyManager:new()
        
        local alternatives = hkm:suggestAlternatives({"cmd"}, "a")
        assert(type(alternatives) == "table", "Should return alternatives table")
        assert(#alternatives > 0, "Should suggest alternatives")
        
        for _, alt in ipairs(alternatives) do
            assert(alt.modifiers ~= nil, "Alternative should have modifiers")
            assert(alt.key ~= nil, "Alternative should have key")
            assert(alt.display ~= nil, "Alternative should have display")
        end
        
        return true
    end
    
    -- Test 10: Get Registered Hotkeys
    tests.test_get_registered_hotkeys = function()
        local hkm = HotkeyManager:new()
        
        -- Initially empty
        local initial = hkm:getRegisteredHotkeys()
        assert(type(initial) == "table", "Should return table")
        assert(#initial == 0, "Should be empty initially")
        
        -- Add some hotkeys
        hkm:bind({key = "a", modifiers = {"cmd", "shift"}}, function() end)
        hkm:bind({key = "b", modifiers = {"ctrl", "alt"}}, function() end)
        
        local registered = hkm:getRegisteredHotkeys()
        assert(#registered == 2, "Should have 2 registered hotkeys")
        
        for _, hotkey in ipairs(registered) do
            assert(hotkey.id ~= nil, "Should have ID")
            assert(hotkey.key ~= nil, "Should have key")
            assert(hotkey.modifiers ~= nil, "Should have modifiers")
            assert(hotkey.display ~= nil, "Should have display")
        end
        
        return true
    end
    
    -- Run tests
    print("Running Hotkey Manager Tests...")
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
if arg and arg[0] == "test_hotkey_manager.lua" then
    local success = run_tests()
    os.exit(success and 0 or 1)
end

return {run_tests = run_tests}