-- ui.lua
-- User interface components for Ask AI Anywhere

local config = require("modules.config")
local textOps = require("modules.text_operations")

local ui = {}

-- Main menu chooser
ui.mainChooser = nil

-- Create the main operation chooser
function ui.createMainChooser()
    if ui.mainChooser then
        ui.mainChooser:delete()
    end
    
    local operations = config.get("operations") or {}
    
    -- Build chooser items
    local chooserItems = {}
    
    -- Add preview of selected text if available
    local inputText, inputSource = textOps.getInputText()
    if inputText and inputText ~= "" then
        local truncatedText = textOps.truncateText(inputText, 60)
        table.insert(chooserItems, {
            text = "📄 " .. (inputSource == "selection" and "Selected: " or "Clipboard: ") .. truncatedText,
            subText = "Source text for AI operations",
            valid = false,
            uuid = "preview"
        })
        
        -- Add separator
        table.insert(chooserItems, {
            text = string.rep("─", 50),
            subText = "",
            valid = false,
            uuid = "separator"
        })
    end
    
    -- Add operations
    for _, op in ipairs(operations) do
        table.insert(chooserItems, {
            text = (op.icon or "🤖") .. " " .. op.name,
            subText = "Perform " .. string.lower(op.name) .. " on the text",
            operation = op.key,
            uuid = op.key
        })
    end
    
    -- Add settings option
    table.insert(chooserItems, {
        text = string.rep("─", 50),
        subText = "",
        valid = false,
        uuid = "separator2"
    })
    
    table.insert(chooserItems, {
        text = "⚙️ Settings",
        subText = "Configure Ask AI Anywhere",
        operation = "settings",
        uuid = "settings"
    })
    
    -- Create chooser
    ui.mainChooser = hs.chooser.new(function(choice)
        if not choice then return end
        
        if choice.operation == "settings" then
            ui.showSettings()
        elseif choice.operation == "custom" then
            textOps.customPrompt()
        elseif choice.operation then
            -- Determine output mode based on operation
            local outputMode = "replace"
            if choice.operation == "summarize" or choice.operation == "custom" then
                outputMode = "dialog"
            end
            
            textOps.performOperation(choice.operation, {outputMode = outputMode})
        end
    end)
    
    ui.mainChooser:choices(chooserItems)
    ui.mainChooser:width(config.get("ui.menu_width") or 20)
    ui.mainChooser:rows(10)
    ui.mainChooser:searchSubText(false)
end

-- Show the main chooser
function ui.showMainChooser()
    -- Recreate chooser to refresh with current text
    ui.createMainChooser()
    
    if ui.mainChooser then
        ui.mainChooser:show()
    end
end

-- Settings dialog
function ui.showSettings()
    local currentProvider = config.get("llm.default_provider") or "gemini"
    local showNotifications = config.get("ui.show_notifications") and "Yes" or "No"
    
    local settingsText = string.format([[Current Settings:

• Default LLM Provider: %s
• Show Notifications: %s
• Gemini Command: %s
• Claude Command: %s

You can modify these settings by editing the configuration file or using the menu options below.]], 
        currentProvider,
        showNotifications,
        config.get("llm.gemini_command") or "gemini -p",
        config.get("llm.claude_command") or "claude -p"
    )
    
    local button, _ = hs.dialog.textPrompt(
        "Ask AI Anywhere - Settings",
        settingsText,
        "",
        "Test LLM Connection",
        "Close"
    )
    
    if button == "Test LLM Connection" then
        ui.testLLMConnection()
    end
end

-- Test LLM connection dialog
function ui.testLLMConnection()
    local llm = require("modules.llm")
    
    -- Show progress
    local progressNotification = hs.notify.new({
        title = "Ask AI Anywhere",
        informativeText = "Testing LLM connections...",
        hasActionButton = false
    })
    
    if config.get("ui.show_notifications") then
        progressNotification:send()
    end
    
    hs.timer.doAfter(0.1, function()
        if progressNotification then
            progressNotification:withdraw()
        end
        
        -- Test both providers
        local geminiSuccess, geminiMessage = llm.test("gemini")
        local claudeSuccess, claudeMessage = llm.test("claude")
        
        local resultText = string.format([[LLM Connection Test Results:

Gemini: %s
%s

Claude: %s
%s

%s]], 
            geminiSuccess and "✅ Working" or "❌ Failed",
            geminiMessage,
            claudeSuccess and "✅ Working" or "❌ Failed", 
            claudeMessage,
            (geminiSuccess or claudeSuccess) and "At least one provider is working!" or "No providers are working. Please check your setup."
        )
        
        hs.dialog.blockAlert(
            "LLM Connection Test",
            resultText,
            "OK"
        )
    end)
end

-- Output mode chooser
function ui.showOutputModeChooser(operation, callback)
    local outputModes = {
        {text = "📋 Copy to Clipboard", mode = "clipboard"},
        {text = "↩️ Replace Selected Text", mode = "replace"},
        {text = "⌨️ Type at Cursor", mode = "insert"},
        {text = "💬 Show in Dialog", mode = "dialog"},
    }
    
    local chooserItems = {}
    for _, mode in ipairs(outputModes) do
        table.insert(chooserItems, {
            text = mode.text,
            subText = "Output result using this method",
            mode = mode.mode
        })
    end
    
    local outputChooser = hs.chooser.new(function(choice)
        if choice and callback then
            callback(choice.mode)
        end
    end)
    
    outputChooser:choices(chooserItems)
    outputChooser:width(20)
    outputChooser:show()
end

-- Provider chooser
function ui.showProviderChooser(callback)
    local providers = {
        {text = "🧠 Gemini", provider = "gemini", subText = "Google's Gemini AI"},
        {text = "🤖 Claude", provider = "claude", subText = "Anthropic's Claude AI"},
    }
    
    local chooserItems = {}
    for _, p in ipairs(providers) do
        table.insert(chooserItems, {
            text = p.text,
            subText = p.subText,
            provider = p.provider
        })
    end
    
    local providerChooser = hs.chooser.new(function(choice)
        if choice and callback then
            callback(choice.provider)
        end
    end)
    
    providerChooser:choices(chooserItems)
    providerChooser:width(20)
    providerChooser:show()
end

-- Initialize UI
function ui.init()
    ui.createMainChooser()
end

-- Cleanup UI
function ui.cleanup()
    if ui.mainChooser then
        ui.mainChooser:delete()
        ui.mainChooser = nil
    end
end

return ui
