-- Ask AI Anywhere - Hammerspoon Implementation
-- A powerful tool for AI-assisted text processing from anywhere
-- Replaces the Alfred workflow with a simpler Hammerspoon solution

-- Get the directory of this script and set up module paths
local scriptPath = debug.getinfo(1, "S").source:match("@(.*)init%.lua$")
if scriptPath then
    package.path = package.path .. ";" .. scriptPath .. "modules/?.lua"
    package.path = package.path .. ";" .. scriptPath .. "?.lua"
end

-- Import required modules
local textHandler = require('text_handler')
local llmClient = require('llm_client')
local aiOperations = require('ai_operations')
local uiManager = require('ui_manager')
local configManager = require('config_manager')
local hotkeyManager = require('hotkey_manager')

-- Initialize the application
local AskAI = {}
AskAI.__index = AskAI

function AskAI:new()
    local instance = setmetatable({}, AskAI)
    
    -- Initialize components
    instance.config = configManager:new()
    instance.textHandler = textHandler:new()
    instance.llmClient = llmClient:new(instance.config)
    instance.aiOperations = aiOperations:new(instance.llmClient)
    instance.uiManager = uiManager:new()
    instance.hotkeyManager = hotkeyManager:new()
    
    -- Load configuration
    instance.config:load()
    
    -- Set up hotkeys
    instance:setupHotkeys()
    
    return instance
end

function AskAI:setupHotkeys()
    local hotkeys = self.config:getHotkeys()
    
    -- Main menu hotkey
    if hotkeys.mainMenu then
        self.hotkeyManager:bind(hotkeys.mainMenu, function()
            self:showMainMenu()
        end)
    end
    
    -- Quick action hotkeys
    if hotkeys.improveWriting then
        self.hotkeyManager:bind(hotkeys.improveWriting, function()
            self:quickAction('improve_writing')
        end)
    end
    
    if hotkeys.continueWriting then
        self.hotkeyManager:bind(hotkeys.continueWriting, function()
            self:quickAction('continue_writing')
        end)
    end
    
    if hotkeys.translate then
        self.hotkeyManager:bind(hotkeys.translate, function()
            self:quickAction('translate')
        end)
    end
    
    if hotkeys.summarize then
        self.hotkeyManager:bind(hotkeys.summarize, function()
            self:quickAction('summarize')
        end)
    end
end

function AskAI:showMainMenu()
    local inputText = self.textHandler:getSelectedText()
    if not inputText or inputText == "" then
        inputText = self.textHandler:getClipboard()
    end
    
    if not inputText or inputText == "" then
        hs.alert.show("No text selected or in clipboard")
        return
    end
    
    local operations = self.aiOperations:getAvailableOperations()
    self.uiManager:showOperationChooser(operations, function(choice)
        if choice then
            self:executeOperation(choice.operation, inputText)
        end
    end)
end

function AskAI:quickAction(operation)
    local inputText = self.textHandler:getSelectedText()
    if not inputText or inputText == "" then
        inputText = self.textHandler:getClipboard()
    end
    
    if not inputText or inputText == "" then
        hs.alert.show("No text selected or in clipboard")
        return
    end
    
    self:executeOperation(operation, inputText)
end

function AskAI:executeOperation(operation, inputText)
    -- Show progress indicator
    self.uiManager:showProgress("Processing with AI...")
    
    -- Execute the AI operation
    self.aiOperations:execute(operation, inputText, function(result, error)
        self.uiManager:hideProgress()
        
        if error then
            hs.alert.show("Error: " .. error)
            return
        end
        
        if result then
            -- Handle the result based on configuration
            local outputMethod = self.config:getOutputMethod()
            self:handleResult(result, outputMethod)
        end
    end)
end

function AskAI:handleResult(result, outputMethod)
    if outputMethod == "display" then
        self.uiManager:showResult(result)
    elseif outputMethod == "clipboard" then
        self.textHandler:setClipboard(result)
        hs.alert.show("Result copied to clipboard")
    elseif outputMethod == "replace" then
        self.textHandler:replaceSelectedText(result)
    elseif outputMethod == "keyboard" then
        self.textHandler:typeText(result)
    end
end

-- Initialize and start the application
local askAI = AskAI:new()

-- Export for debugging
return askAI