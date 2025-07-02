-- Configuration Manager
-- Handles loading, saving, and managing configuration settings

local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager:new()
    local instance = setmetatable({}, ConfigManager)
    instance.config = {}
    instance.configPath = hs.configdir .. "/ask-ai-config.json"
    instance.defaultConfigPath = "config/default_config.json"
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
    local file = io.open(self.configPath, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, config = pcall(hs.json.decode, content)
    if not success then
        hs.alert.show("Error parsing user configuration")
        return {}
    end
    
    return config or {}
end

function ConfigManager:loadDefaultConfig()
    local currentDir = debug.getinfo(1, "S").source:match("@(.*/)") or ""
    local configPath = currentDir:gsub("modules/", "") .. "config/default_config.json"
    
    local file = io.open(configPath, "r")
    if not file then
        hs.alert.show("Error: Default configuration not found")
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local success, config = pcall(hs.json.decode, content)
    if not success then
        hs.alert.show("Error parsing default configuration")
        return {}
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

function ConfigManager:save()
    local file = io.open(self.configPath, "w")
    if not file then
        hs.alert.show("Error: Cannot save configuration")
        return false
    end
    
    local success, jsonStr = pcall(hs.json.encode, self.config)
    if not success then
        hs.alert.show("Error: Cannot encode configuration")
        file:close()
        return false
    end
    
    file:write(jsonStr)
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

function ConfigManager:getLLMConfig()
    return self:get("llm", {})
end

function ConfigManager:getOperations()
    return self:get("operations", {})
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