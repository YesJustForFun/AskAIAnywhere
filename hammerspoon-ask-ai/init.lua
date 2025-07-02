-- init.lua
-- Ask AI Anywhere - Hammerspoon Script
-- A simple and powerful AI text processing tool

-- Ensure modules directory is in package path
local currentDir = debug.getinfo(1).source:match("@?(.*[/\\])")
package.path = currentDir .. "?.lua;" .. package.path

-- Load modules
local config = require("modules.config")
local textOps = require("modules.text_operations")
local ui = require("modules.ui")
local llm = require("modules.llm")

-- App state
local askAI = {
    version = "1.0.0",
    name = "Ask AI Anywhere",
    hotkeys = {},
    initialized = false
}

-- Initialize the application
function askAI.init()
    if askAI.initialized then
        askAI.cleanup()
    end
    
    -- Load configuration
    config.load()
    
    -- Initialize UI
    ui.init()
    
    -- Set up hotkeys
    askAI.setupHotkeys()
    
    -- Show startup notification
    if config.get("ui.show_notifications") then
        hs.notify.new({
            title = askAI.name,
            informativeText = "Ready! Press " .. table.concat(config.get("hotkeys.main_trigger"), "+") .. " to start",
            hasActionButton = false
        }):send()
    end
    
    askAI.initialized = true
    print("Ask AI Anywhere initialized successfully")
end

-- Set up hotkey bindings
function askAI.setupHotkeys()
    -- Clear existing hotkeys
    for _, hotkey in ipairs(askAI.hotkeys) do
        hotkey:delete()
    end
    askAI.hotkeys = {}
    
    -- Main trigger hotkey (show menu)
    local mainTrigger = config.get("hotkeys.main_trigger")
    if mainTrigger then
        local modifiers, key = {}, ""
        for i = 1, #mainTrigger - 1 do
            table.insert(modifiers, mainTrigger[i])
        end
        key = mainTrigger[#mainTrigger]
        
        local mainHotkey = hs.hotkey.bind(modifiers, key, function()
            ui.showMainChooser()
        end)
        table.insert(askAI.hotkeys, mainHotkey)
    end
    
    -- Quick improve writing hotkey
    local quickImprove = config.get("hotkeys.quick_improve")
    if quickImprove then
        local modifiers, key = {}, ""
        for i = 1, #quickImprove - 1 do
            table.insert(modifiers, quickImprove[i])
        end
        key = quickImprove[#quickImprove]
        
        local improveHotkey = hs.hotkey.bind(modifiers, key, function()
            textOps.quickImprove("replace")
        end)
        table.insert(askAI.hotkeys, improveHotkey)
    end
    
    -- Quick translate hotkey
    local quickTranslate = config.get("hotkeys.quick_translate")
    if quickTranslate then
        local modifiers, key = {}, ""
        for i = 1, #quickTranslate - 1 do
            table.insert(modifiers, quickTranslate[i])
        end
        key = quickTranslate[#quickTranslate]
        
        local translateHotkey = hs.hotkey.bind(modifiers, key, function()
            textOps.quickTranslate("en", "replace")
        end)
        table.insert(askAI.hotkeys, translateHotkey)
    end
    
    print("Hotkeys configured:")
    print("  Main menu: " .. table.concat(config.get("hotkeys.main_trigger"), "+"))
    print("  Quick improve: " .. table.concat(config.get("hotkeys.quick_improve"), "+"))
    print("  Quick translate: " .. table.concat(config.get("hotkeys.quick_translate"), "+"))
end

-- Cleanup function
function askAI.cleanup()
    -- Delete hotkeys
    for _, hotkey in ipairs(askAI.hotkeys) do
        if hotkey then
            hotkey:delete()
        end
    end
    askAI.hotkeys = {}
    
    -- Cleanup UI
    ui.cleanup()
    
    askAI.initialized = false
    print("Ask AI Anywhere cleaned up")
end

-- Configuration reload
function askAI.reload()
    print("Reloading Ask AI Anywhere...")
    askAI.cleanup()
    askAI.init()
end

-- Test function for debugging
function askAI.test()
    print("Testing Ask AI Anywhere...")
    
    -- Test configuration
    print("Config test:")
    print("  Default provider: " .. (config.get("llm.default_provider") or "not set"))
    print("  Show notifications: " .. tostring(config.get("ui.show_notifications")))
    
    -- Test LLM connection
    print("LLM test:")
    local success, message = llm.test(config.get("llm.default_provider"))
    print("  " .. (success and "✅" or "❌") .. " " .. message)
    
    -- Test text operations
    print("Text operations test:")
    local testText = "This is a test text for AI processing."
    print("  Input text: " .. testText)
    
    -- Show test completion
    if config.get("ui.show_notifications") then
        hs.notify.new({
            title = askAI.name,
            informativeText = "Test completed - check console for results",
            hasActionButton = false
        }):send()
    end
end

-- Menu bar item (optional)
function askAI.createMenuBar()
    if askAI.menuBar then
        askAI.menuBar:delete()
    end
    
    askAI.menuBar = hs.menubar.new()
    if askAI.menuBar then
        askAI.menuBar:setTitle("🤖")
        askAI.menuBar:setTooltip("Ask AI Anywhere")
        
        askAI.menuBar:setMenu({
            {title = "Show Menu", fn = function() ui.showMainChooser() end},
            {title = "-"},
            {title = "Test Connection", fn = function() ui.testLLMConnection() end},
            {title = "Settings", fn = function() ui.showSettings() end},
            {title = "-"},
            {title = "Reload", fn = function() askAI.reload() end},
            {title = "Disable", fn = function() askAI.cleanup() end},
        })
    end
end

-- Auto-start when Hammerspoon loads
function askAI.autoStart()
    -- Small delay to ensure Hammerspoon is fully loaded
    hs.timer.doAfter(1, function()
        askAI.init()
        -- Optionally create menu bar item
        -- askAI.createMenuBar()
    end)
end

-- Handle Hammerspoon config reload
hs.loadSpoon = function(name)
    if name == "ReloadConfiguration" then
        hs.spoons.use("ReloadConfiguration", {
            start = true,
            hotkeys = {
                reloadConfiguration = {{"cmd", "alt", "ctrl"}, "r"}
            }
        })
    end
end

-- Global functions for console access
hs.askai = askAI

-- Print startup message
print("Ask AI Anywhere loaded. Use hs.askai.init() to start, or it will auto-start in 1 second.")

-- Auto-start
askAI.autoStart()

-- Return the module for require() usage
return askAI
