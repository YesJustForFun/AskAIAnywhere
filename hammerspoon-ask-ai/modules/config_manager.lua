-- Configuration Manager
-- Handles loading, saving, and managing configuration settings
-- Supports both JSON and YAML formats

local YamlParser = require('yaml_parser')

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager:new()
    local instance = setmetatable({}, ConfigManager)
    instance.config = {}
    instance.yamlParser = YamlParser:new()
    
    -- Support both YAML and JSON configurations
    instance.userConfigPath = hs.configdir .. "/ask-ai-config.yaml"
    instance.userConfigPathJSON = hs.configdir .. "/ask-ai-config.json"
    instance.defaultConfigPath = "config/default_config.yaml"
    instance.defaultConfigPathJSON = "config/default_config.json"
    
    return instance
end

function ConfigManager:load()
    -- Try to load user config first
    local userConfig = self:loadUserConfig()
    
    -- Load default config
    local defaultConfig = self:loadDefaultConfig()
    
    -- Merge configs (user config overrides default)
    self.config = self:mergeConfigs(defaultConfig, userConfig)
    
    return self.config
end

function ConfigManager:loadUserConfig()
    -- Try YAML first, then JSON
    local config = self:loadConfigFile(self.userConfigPath, "yaml")
    if config and next(config) then
        return config
    end
    
    config = self:loadConfigFile(self.userConfigPathJSON, "json")
    return config or {}
end

function ConfigManager:loadDefaultConfig()
    local currentDir = debug.getinfo(1, "S").source:match("@(.*/)")
    if not currentDir then currentDir = "" end
    
    -- Try YAML first, then JSON
    local yamlPath = currentDir .. "../config/default_config.yaml"
    local config = self:loadConfigFile(yamlPath, "yaml")
    if config and next(config) then
        return config
    end
    
    local jsonPath = currentDir .. "../config/default_config.json"
    config = self:loadConfigFile(jsonPath, "json")
    if config and next(config) then
        return config
    end
    
    hs.alert.show("Error: No default configuration found")
    return {}
end

-- Load configuration file with format support
function ConfigManager:loadConfigFile(filePath, format)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        return nil
    end
    
    local success, config
    
    if format == "yaml" then
        success, config = pcall(self.yamlParser.parse, self.yamlParser, content)
    else
        success, config = pcall(hs.json.decode, content)
    end
    
    if not success then
        print("Error parsing " .. format .. " configuration from " .. filePath .. ": " .. (config or "unknown error"))
        return nil
    end
    
    return config or {}
end

function ConfigManager:mergeConfigs(default, user)
    local function deepMerge(t1, t2)
        local result = {}
        
        -- Copy all keys from t1
        for k, v in pairs(t1) do
            if type(v) == "table" then
                result[k] = deepMerge(v, {})
            else
                result[k] = v
            end
        end
        
        -- Override with values from t2
        for k, v in pairs(t2) do
            if type(v) == "table" and type(result[k]) == "table" then
                result[k] = deepMerge(result[k], v)
            else
                result[k] = v
            end
        end
        
        return result
    end
    
    return deepMerge(default, user)
end

function ConfigManager:save(format)
    format = format or "yaml"
    
    local filePath = (format == "yaml") and self.userConfigPath or self.userConfigPathJSON
    local file = io.open(filePath, "w")
    if not file then
        hs.alert.show("Error: Cannot save configuration")
        return false
    end
    
    local content
    local success
    
    if format == "yaml" then
        success, content = pcall(self.yamlParser.toYaml, self.yamlParser, self.config)
    else
        success, content = pcall(hs.json.encode, self.config)
    end
    
    if not success then
        hs.alert.show("Error: Cannot encode configuration")
        file:close()
        return false
    end
    
    file:write(content)
    file:close()
    return true
end

function ConfigManager:get(key, defaultValue)
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local value = self.config
    for _, k in ipairs(keys) do
        if type(value) == "table" and value[k] ~= nil then
            value = value[k]
        else
            return defaultValue
        end
    end
    
    return value
end

function ConfigManager:set(key, value)
    local keys = {}
    for k in string.gmatch(key, "[^.]+") do
        table.insert(keys, k)
    end
    
    local current = self.config
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            current[k] = {}
        end
        current = current[k]
    end
    
    current[keys[#keys]] = value
end

function ConfigManager:getHotkeys()
    return self:get("hotkeys", {})
end

-- Get hotkeys in new format (array) or old format (object)
function ConfigManager:getHotkeysArray()
    local hotkeys = self:get("hotkeys", {})
    
    -- If it's already an array, return it
    if #hotkeys > 0 then
        return hotkeys
    end
    
    -- Convert old object format to new array format
    local hotkeyArray = {}
    for name, hotkeyConfig in pairs(hotkeys) do
        if type(hotkeyConfig) == "table" and hotkeyConfig.key then
            table.insert(hotkeyArray, {
                key = hotkeyConfig.key,
                modifiers = hotkeyConfig.modifiers or {},
                name = name,
                description = "Legacy hotkey: " .. name,
                actions = {
                    {
                        name = "runPrompt",
                        args = { prompt = name }
                    },
                    {
                        name = "displayText",
                        args = { text = "${output}", ui = "default" }
                    }
                }
            })
        end
    end
    
    return hotkeyArray
end

function ConfigManager:getLLMConfig()
    return self:get("llm", {})
end

function ConfigManager:getOperations()
    -- Support both 'operations' (old) and 'prompts' (new) keys
    local operations = self:get("operations", {})
    if next(operations) then
        return operations
    end
    return self:get("prompts", {})
end

function ConfigManager:getUIConfig()
    return self:get("ui", {})
end

function ConfigManager:getOutputMethod()
    return self:get("ui.outputMethod", "display")
end

function ConfigManager:getDefaultProvider()
    return self:get("llm.defaultProvider", "claude")
end

function ConfigManager:getFallbackProvider()
    return self:get("llm.fallbackProvider", "gemini")
end

function ConfigManager:getProviderConfig(provider)
    return self:get("llm.providers." .. provider, {})
end

return ConfigManager