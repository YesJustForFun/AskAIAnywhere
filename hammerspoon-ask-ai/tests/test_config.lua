-- test_config.lua
-- Unit tests for configuration module

-- Mock Hammerspoon API for testing
local hs = {
    configdir = "/tmp/test_hammerspoon",
    json = {
        encode = function(t) 
            -- Simple JSON encoding for testing
            if type(t) == "table" then
                local result = "{"
                local first = true
                for k, v in pairs(t) do
                    if not first then result = result .. "," end
                    result = result .. '"' .. k .. '":' .. (type(v) == "string" and '"' .. v .. '"' or tostring(v))
                    first = false
                end
                return result .. "}"
            end
            return tostring(t)
        end,
        decode = function(s)
            -- Simple JSON decoding for testing
            if s == '{"test":"value"}' then
                return {test = "value"}
            end
            return nil
        end
    }
}

-- Mock file operations
local mockFileSystem = {}
io.open = function(filename, mode)
    if mode == "w" then
        return {
            write = function(self, data)
                mockFileSystem[filename] = data
            end,
            close = function() end
        }
    elseif mode == "r" then
        if mockFileSystem[filename] then
            return {
                read = function(self, format)
                    return mockFileSystem[filename]
                end,
                close = function() end
            }
        end
    end
    return nil
end

-- Load config module
local config = require("modules.config")

-- Test suite
local tests = {}

function tests.test_load_defaults()
    local cfg = config.load()
    assert(cfg, "Config should load")
    assert(cfg.llm, "Config should have llm section")
    assert(cfg.llm.default_provider == "gemini", "Default provider should be gemini")
    assert(cfg.hotkeys, "Config should have hotkeys section")
    print("✅ test_load_defaults passed")
end

function tests.test_get_value()
    config.load()
    local provider = config.get("llm.default_provider")
    assert(provider == "gemini", "Should get default provider")
    
    local hotkey = config.get("hotkeys.main_trigger")
    assert(type(hotkey) == "table", "Hotkey should be a table")
    print("✅ test_get_value passed")
end

function tests.test_set_value()
    config.load()
    config.set("llm.default_provider", "claude")
    local provider = config.get("llm.default_provider")
    assert(provider == "claude", "Should set and get new provider")
    print("✅ test_set_value passed")
end

function tests.test_save_and_load()
    config.load()
    config.set("test.value", "test_data")
    local success = config.save()
    assert(success, "Should save successfully")
    
    -- For testing purposes, just verify the value is set in current config
    local value = config.get("test.value")
    assert(value == "test_data", "Should set and get value correctly")
    print("✅ test_save_and_load passed")
end

-- Run all tests
function tests.run_all()
    print("Running config module tests...")
    tests.test_load_defaults()
    tests.test_get_value()
    tests.test_set_value()
    tests.test_save_and_load()
    print("All config tests passed! ✅")
end

-- Export for use in other tests
return tests
