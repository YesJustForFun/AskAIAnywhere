-- Ask AI Anywhere - Hammerspoon Implementation
-- A powerful tool for AI-assisted text processing from anywhere
-- Replaces the Alfred workflow with a simpler Hammerspoon solution
-- Updated with extensible action-based architecture

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
local actionRegistry = require('action_registry')
print("🤖 ✓ action_registry loaded")
local ExecutionContext = require('execution_context')
print("🤖 ✓ execution_context loaded")

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
    instance.actionRegistry = actionRegistry:new()
    
    -- Set up parent references for config access
    instance.uiManager:setParent(instance)
    
    -- Load configuration
    instance.config:load()
    
    -- Set up hotkeys
    instance:setupHotkeys()
    
    return instance
end

-- Create execution context for action chains
function AskAI:createExecutionContext(input)
    input = input or self.textHandler:getSelectedText()
    if not input or input == "" then
        input = self.textHandler:getClipboard()
    end
    
    local components = {
        textHandler = self.textHandler,
        llmClient = self.llmClient,
        uiManager = self.uiManager,
        actionRegistry = self.actionRegistry
    }
    
    return ExecutionContext:new(input, self.config, components)
end

function AskAI:setupHotkeys()
    print("🤖 Setting up hotkeys...")
    
    -- Get hotkeys in new array format
    local hotkeyArray = self.config:getHotkeysArray()
    
    if #hotkeyArray == 0 then
        print("🤖 No hotkeys configured")
        return
    end
    
    print("🤖 Found " .. #hotkeyArray .. " hotkey configurations")
    
    -- Create context callback
    local createContextCallback = function()
        return self:createExecutionContext()
    end
    
    -- Bind action-based hotkeys
    local results = self.hotkeyManager:bindActionHotkeys(
        hotkeyArray, 
        self.actionRegistry, 
        createContextCallback
    )
    
    -- Report results
    local successCount = 0
    local failureCount = 0
    
    for name, result in pairs(results) do
        if result.success then
            successCount = successCount + 1
        else
            failureCount = failureCount + 1
            print("🤖 ✗ Failed to bind hotkey '" .. name .. "': " .. result.message)
        end
    end
    
    print("🤖 Hotkey setup complete: " .. successCount .. " success, " .. failureCount .. " failed")
    
    -- Setup legacy hotkeys if no new-format hotkeys are available
    if successCount == 0 then
        print("🤖 Falling back to legacy hotkey format...")
        self:setupLegacyHotkeys()
    end
end

-- Legacy hotkey setup for backward compatibility
function AskAI:setupLegacyHotkeys()
    local hotkeys = self.config:getHotkeys()
    print("🤖 Legacy hotkeys config: " .. hs.inspect(hotkeys))
    
    -- Main menu hotkey
    if hotkeys.mainMenu then
        print("🤖 Binding legacy main menu hotkey: " .. hs.inspect(hotkeys.mainMenu))
        local success, result = self.hotkeyManager:bind(hotkeys.mainMenu, function()
            print("🤖 Legacy main menu hotkey triggered!")
            self:showMainMenu()
        end)
        if success then
            print("🤖 ✓ Legacy main menu hotkey bound successfully")
        else
            print("🤖 ✗ Failed to bind legacy main menu hotkey: " .. (result or "unknown error"))
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
            self:quickAction('translate_chinese')
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
    
    -- Get prompts from new configuration format
    local prompts = self.config:get("prompts") or {}
    local operations = {}
    
    for promptName, promptData in pairs(prompts) do
        table.insert(operations, {
            operation = promptName,
            title = promptData.title or promptName,
            description = promptData.description or "No description",
            text = promptData.title or promptName,
            subText = promptData.description or "No description"
        })
    end
    
    -- Sort by title
    table.sort(operations, function(a, b)
        return a.title < b.title
    end)
    
    print("🤖 Available operations: " .. #operations)
    
    self.uiManager:showOperationChooser(operations, function(choice)
        if choice then
            print("🤖 Operation selected: " .. choice.operation)
            
            -- Use action-based execution
            local context = self:createExecutionContext(inputText)
            context:executeActions({
                {
                    name = "runPrompt",
                    args = { prompt = choice.operation }
                },
                {
                    name = "displayText",
                    args = { text = "${output}", ui = "default" }
                }
            })
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

-- Test configuration functionality
function AskAI:testConfiguration()
    print("🤖 Testing configuration...")
    
    -- Test LLM providers
    local llmConfig = self.config:getLLMConfig()
    local defaultProvider = llmConfig.defaultProvider
    local fallbackProvider = llmConfig.fallbackProvider
    
    print("🤖 Default provider: " .. (defaultProvider or "none"))
    print("🤖 Fallback provider: " .. (fallbackProvider or "none"))
    
    -- Test provider availability
    if defaultProvider then
        local providerConfig = self.config:getProviderConfig(defaultProvider)
        if providerConfig and providerConfig.enabled then
            print("🤖 ✓ Default provider (" .. defaultProvider .. ") is enabled")
        else
            print("🤖 ✗ Default provider (" .. defaultProvider .. ") is not enabled")
        end
    end
    
    -- Test hotkey configuration
    local hotkeyArray = self.config:getHotkeysArray()
    print("🤖 Configured hotkeys: " .. #hotkeyArray)
    
    for i, hotkey in ipairs(hotkeyArray) do
        local display = self.hotkeyManager:formatHotkeyDisplay(hotkey.modifiers, hotkey.key)
        print("🤖   " .. i .. ". " .. (hotkey.name or "unnamed") .. " (" .. display .. ") - " .. #(hotkey.actions or {}) .. " actions")
    end
    
    hs.alert.show("Configuration test completed - check console for details")
end

-- Reload configuration
function AskAI:reloadConfiguration()
    print("🤖 Reloading configuration...")
    
    -- Unbind all hotkeys
    self.hotkeyManager:unbindAll()
    
    -- Reload config
    self.config:load()
    
    -- Re-setup hotkeys
    self:setupHotkeys()
    
    hs.alert.show("Configuration reloaded")
    print("🤖 Configuration reloaded successfully")
end

-- Debug function
function AskAI:debug()
    print("🤖 Ask AI Debug Information:")
    print("🤖 =========================")
    
    -- Configuration debug
    local hotkeyArray = self.config:getHotkeysArray()
    print("🤖 Total hotkeys configured: " .. #hotkeyArray)
    
    -- Hotkey manager debug
    self.hotkeyManager:debug()
    
    -- Action registry debug
    local actions = self.actionRegistry:getAvailableActions()
    print("🤖 Available actions: " .. hs.inspect(actions))
    
    -- UI config debug
    local uiConfig = self.config:get("ui", {})
    print("🤖 UI configuration: " .. hs.inspect(uiConfig))
end

-- Global cleanup function for Hammerspoon reload
if _G.askAI then
    print("🤖 Cleaning up previous instance...")
    if _G.askAI.uiManager and _G.askAI.uiManager.cleanup then
        _G.askAI.uiManager:cleanup()
    end
    if _G.askAI.hotkeyManager and _G.askAI.hotkeyManager.unbindAll then
        _G.askAI.hotkeyManager:unbindAll()
    end
    if _G.askAI.menubar then
        _G.askAI.menubar:delete()
    end
end

-- Initialize and start the application
print("🤖 Initializing Ask AI application...")
local askAI = AskAI:new()

-- Create menu bar for easy access and store reference to prevent garbage collection
askAI.menubar = askAI.uiManager:createMenuBar()

print("🤖 ✓ Ask AI Anywhere initialized successfully!")

-- Print helpful information
local hotkeyArray = askAI.config:getHotkeysArray()
if #hotkeyArray > 0 then
    print("🤖 Available hotkeys:")
    for i, hotkey in ipairs(hotkeyArray) do
        local display = askAI.hotkeyManager:formatHotkeyDisplay(hotkey.modifiers, hotkey.key)
        local description = hotkey.description or hotkey.name or ("Hotkey " .. i)
        print("🤖   " .. display .. " - " .. description)
    end
else
    print("🤖 No hotkeys configured. Check your configuration file.")
end

print("🤖 Use the menu bar (🤖) for quick access to features")

-- Store global reference for cleanup on reload
_G.askAI = askAI

-- Export for debugging and external access
return askAI