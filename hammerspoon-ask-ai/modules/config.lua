-- config.lua
-- Configuration management for Ask AI Anywhere

local config = {}

-- Default configuration
config.defaults = {
    -- Hotkeys (modifier combinations)
    hotkeys = {
        main_trigger = {"cmd", "shift", "a"},  -- Main hotkey to trigger the menu
        quick_improve = {"cmd", "shift", "i"}, -- Quick improve writing
        quick_translate = {"cmd", "shift", "t"}, -- Quick translate
    },
    
    -- LLM providers
    llm = {
        default_provider = "gemini",  -- "gemini" or "claude"
        gemini_command = "gemini -p",
        claude_command = "claude -p",
        timeout = 30,  -- seconds
    },
    
    -- UI settings
    ui = {
        menu_title = "Ask AI Anywhere",
        show_notifications = true,
        menu_width = 300,
    },
    
    -- Text operations
    operations = {
        {name = "Improve Writing", key = "improve", icon = "✨"},
        {name = "Translate to English", key = "translate_en", icon = "🌍"},
        {name = "Translate to Chinese", key = "translate_zh", icon = "🇨🇳"},
        {name = "Summarize", key = "summarize", icon = "📝"},
        {name = "Change Tone (Professional)", key = "tone_professional", icon = "👔"},
        {name = "Change Tone (Casual)", key = "tone_casual", icon = "😊"},
        {name = "Continue Writing", key = "continue", icon = "➡️"},
        {name = "Custom Prompt", key = "custom", icon = "💭"},
    }
}

-- Current configuration (starts with defaults)
config.current = {}

-- Load configuration from file
function config.load()
    local configFile = hs.configdir .. "/ask_ai_config.json"
    
    -- Start with defaults
    for k, v in pairs(config.defaults) do
        config.current[k] = v
    end
    
    -- Try to load saved config
    local file = io.open(configFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, saved = pcall(hs.json.decode, content)
        if success and saved then
            -- Merge saved config with defaults
            for k, v in pairs(saved) do
                if config.current[k] then
                    if type(v) == "table" then
                        for k2, v2 in pairs(v) do
                            config.current[k][k2] = v2
                        end
                    else
                        config.current[k] = v
                    end
                end
            end
        end
    end
    
    return config.current
end

-- Save configuration to file
function config.save()
    local configFile = hs.configdir .. "/ask_ai_config.json"
    local file = io.open(configFile, "w")
    if file then
        file:write(hs.json.encode(config.current))
        file:close()
        return true
    end
    return false
end

-- Get configuration value
function config.get(key)
    if not config.current or not next(config.current) then
        config.load()
    end
    
    local keys = {}
    for k in string.gmatch(key, "[^%.]+") do
        table.insert(keys, k)
    end
    
    local value = config.current
    for _, k in ipairs(keys) do
        if value[k] then
            value = value[k]
        else
            return nil
        end
    end
    
    return value
end

-- Set configuration value
function config.set(key, value)
    if not config.current or not next(config.current) then
        config.load()
    end
    
    local keys = {}
    for k in string.gmatch(key, "[^%.]+") do
        table.insert(keys, k)
    end
    
    local current = config.current
    for i = 1, #keys - 1 do
        local k = keys[i]
        if not current[k] then
            current[k] = {}
        end
        current = current[k]
    end
    
    current[keys[#keys]] = value
    config.save()
end

return config
