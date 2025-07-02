-- Ask AI Anywhere - Hammerspoon Implementation
-- A powerful tool for AI-assisted text processing from anywhere
-- Replaces the Alfred workflow with a simpler Hammerspoon solution

print("🤖 Ask AI Anywhere: Starting initialization...")

-- Get the directory of this script and set up module paths
local scriptPath = debug.getinfo(1, "S").source:match("@(.*)init%.lua$")
print("🤖 Script path detected: " .. (scriptPath or "nil"))

if scriptPath then
    local modulePath = scriptPath .. "modules/?.lua"
    package.path = package.path .. ";" .. modulePath
    package.path = package.path .. ";" .. scriptPath .. "?.lua"
    print("🤖 Added module path: " .. modulePath)
end

-- Import required modules
print("🤖 Loading modules...")
local textHandler = require('text_handler')
print("🤖 ✓ text_handler loaded")
local llmClient = require('llm_client')
print("🤖 ✓ llm_client loaded")
local aiOperations = require('ai_operations')
print("🤖 ✓ ai_operations loaded")
local uiManager = require('ui_manager')
print("🤖 ✓ ui_manager loaded")
local configManager = require('config_manager')
print("🤖 ✓ config_manager loaded")
local hotkeyManager = require('hotkey_manager')
print("🤖 ✓ hotkey_manager loaded")

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
    
    -- Set up parent references for config access
    instance.uiManager:setParent(instance)
    
    -- Load configuration
    instance.config:load()
    
    -- Set up hotkeys
    instance:setupHotkeys()
    
    return instance
end

function AskAI:setupHotkeys()
    local hotkeys = self.config:getHotkeys()
    print("🤖 Setting up hotkeys...")
    print("🤖 Hotkeys config: " .. hs.inspect(hotkeys))
    
    -- Main menu hotkey
    if hotkeys.mainMenu then
        print("🤖 Binding main menu hotkey: " .. hs.inspect(hotkeys.mainMenu))
        local success, result = self.hotkeyManager:bind(hotkeys.mainMenu, function()
            print("🤖 Main menu hotkey triggered!")
            self:showMainMenu()
        end)
        if success then
            print("🤖 ✓ Main menu hotkey bound successfully")
        else
            print("🤖 ✗ Failed to bind main menu hotkey: " .. (result or "unknown error"))
        end
    else
        print("🤖 ✗ No main menu hotkey configuration found")
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
    print("🤖 Opening main menu...")
    
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
            print("🤖 Operation selected: " .. choice.operation)
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
print("🤖 Initializing Ask AI application...")
local askAI = AskAI:new()
print("🤖 ✓ Ask AI Anywhere initialized successfully!")
print("🤖 Try pressing ⌘ + Shift + / to open the main menu")

-- Export for debugging
return askAI