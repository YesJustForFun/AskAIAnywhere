-- Execution Context for Ask AI Anywhere
-- Manages execution state and variable substitution for action chains

local ExecutionContext = {}
ExecutionContext.__index = ExecutionContext

function ExecutionContext:new(input, config, components)
    -- Capture the original focus context immediately
    local originalApp = hs.application.frontmostApplication()
    local originalWindow = nil
    if originalApp then
        originalWindow = originalApp:focusedWindow()
    end
    
    local context = {
        input = input or "",
        output = nil,
        variables = {
            input = input or "",
            selected_text = input or "",
            timestamp = os.date("%Y%m%d_%H%M%S"),
            date = os.date("%Y-%m-%d"),
            time = os.date("%H:%M:%S")
        },
        config = config,
        textHandler = components.textHandler,
        llmClient = components.llmClient,
        uiManager = components.uiManager,
        actionRegistry = components.actionRegistry,
        metadata = {},
        parent = nil,
        executionId = tostring(math.random(1000000, 9999999)),
        executionDepth = 0,
        maxExecutionDepth = 5,
        isExecuting = false,
        -- Store original focus context for text replacement
        originalFocusContext = {
            app = originalApp,
            window = originalWindow,
            appName = originalApp and originalApp:name() or "Unknown",
            bundleID = originalApp and originalApp:bundleID() or "Unknown"
        }
    }
    setmetatable(context, ExecutionContext)
    return context
end

-- Create a child context (for nested operations)
function ExecutionContext:createChild()
    local child = ExecutionContext:new(self.input, self.config, {
        textHandler = self.textHandler,
        llmClient = self.llmClient,
        uiManager = self.uiManager,
        actionRegistry = self.actionRegistry
    })
    
    -- Inherit variables from parent
    for key, value in pairs(self.variables) do
        child.variables[key] = value
    end
    
    child.parent = self
    child.output = self.output
    child.executionDepth = self.executionDepth + 1
    child.executionId = self.executionId .. "_child"
    
    -- Inherit the original focus context from parent
    child.originalFocusContext = self.originalFocusContext
    
    return child
end

-- Set a variable in the context
function ExecutionContext:setVariable(key, value)
    self.variables[key] = value
    print("🤖 Context variable set: " .. key .. " = " .. tostring(value):sub(1, 50) .. (tostring(value):len() > 50 and "..." or ""))
end

-- Get a variable from the context
function ExecutionContext:getVariable(key)
    -- Check local variables first
    if self.variables[key] ~= nil then
        return self.variables[key]
    end
    
    -- Check context properties
    if self[key] ~= nil then
        return self[key]
    end
    
    -- Check parent context if available
    if self.parent then
        return self.parent:getVariable(key)
    end
    
    return nil
end

-- Substitute variables in text using ${variable} syntax
function ExecutionContext:substituteVariables(text)
    if type(text) ~= "string" then 
        return text 
    end
    
    local result = text
    local maxIterations = 10  -- Prevent infinite loops
    local iteration = 0
    
    while result:match("%${[^}]+}") and iteration < maxIterations do
        iteration = iteration + 1
        
        result = result:gsub("%${([^}]+)}", function(varName)
            local value = self:resolveVariable(varName)
            print("🤖 Substituting ${" .. varName .. "} = " .. tostring(value or "nil"))
            return tostring(value or "")
        end)
    end
    
    if iteration >= maxIterations then
        print("🤖 Warning: Variable substitution reached maximum iterations")
    end
    
    -- Process escape sequences after variable substitution
    result = result:gsub("\\n", "\n")
    result = result:gsub("\\t", "\t")
    result = result:gsub("\\r", "\r")
    
    return result
end

-- Resolve a variable name (supports dot notation)
function ExecutionContext:resolveVariable(varName)
    -- Handle dot notation (e.g., "llm.defaultProvider")
    if varName:match("%.") then
        return self:resolveDotNotation(varName)
    end
    
    -- Simple variable lookup
    return self:getVariable(varName)
end

-- Resolve dot notation variables (e.g., "llm.defaultProvider")
function ExecutionContext:resolveDotNotation(varName)
    local parts = {}
    for part in varName:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        return nil
    end
    
    -- Check if it's a config variable
    if parts[1] == "config" or parts[1] == "llm" or parts[1] == "ui" or parts[1] == "environment" then
        return self.config:get(varName)
    end
    
    -- Check context variables with dot notation
    local current = self.variables
    for i, part in ipairs(parts) do
        if type(current) == "table" and current[part] ~= nil then
            current = current[part]
        else
            return nil
        end
    end
    
    return current
end

-- Set metadata for the execution
function ExecutionContext:setMetadata(key, value)
    self.metadata[key] = value
end

-- Get metadata from the execution
function ExecutionContext:getMetadata(key)
    local value = self.metadata[key]
    if value ~= nil then
        return value
    end
    
    -- Check parent metadata
    if self.parent then
        return self.parent:getMetadata(key)
    end
    
    return nil
end

-- Execute a sequence of actions (with async support)
function ExecutionContext:executeActions(actions)
    if not actions or #actions == 0 then
        print("🤖 No actions to execute")
        return
    end
    
    -- Loop detection and prevention
    if self.isExecuting then
        print("🤖 ✗ Loop detected! Execution already in progress for context " .. self.executionId)
        error("Loop detected: Context is already executing actions")
        return
    end
    
    if self.executionDepth > self.maxExecutionDepth then
        print("🤖 ✗ Maximum execution depth exceeded (" .. self.executionDepth .. " > " .. self.maxExecutionDepth .. ")")
        error("Maximum execution depth exceeded: " .. self.executionDepth)
        return
    end
    
    print("🤖 Executing " .. #actions .. " actions (depth: " .. self.executionDepth .. ", id: " .. self.executionId .. ")")
    
    -- DEBUG: Show current text selection state before executing actions
    self:debugTextSelectionState()
    
    self.isExecuting = true
    
    -- Execute actions recursively to handle async operations
    self:_executeActionsRecursive(actions, 1)
end

-- Private method to execute actions recursively with async support
function ExecutionContext:_executeActionsRecursive(actions, index)
    if index > #actions then
        print("🤖 All actions completed successfully")
        self.isExecuting = false
        return
    end
    
    local action = actions[index]
    print("🤖 Action " .. index .. "/" .. #actions .. ": " .. action.name)
    
    local success, result = pcall(function()
        return self.actionRegistry:execute(action.name, action.args or {}, self)
    end)
    
    if not success then
        print("🤖 ✗ Action failed: " .. action.name .. " - " .. result)
        self.isExecuting = false
        error("Action chain failed at step " .. index .. " (" .. action.name .. "): " .. result)
        return
    end
    
    -- Handle async operations
    if result == "async_pending" and self._asyncOperation then
        local asyncOp = self._asyncOperation
        self._asyncOperation = nil -- Clear the operation
        
        if asyncOp.type == "llm" then
            print("🤖 Starting async LLM operation...")
            
            -- Execute LLM operation asynchronously
            self.llmClient:execute(asyncOp.provider, asyncOp.prompt, function(llmResult, llmError)
                if llmError then
                    print("🤖 ✗ LLM operation failed: " .. llmError)
                    hs.alert.show("AI operation failed: " .. llmError)
                    return
                end
                
                print("🤖 ✓ LLM operation completed")
                
                -- Update context with result
                self.output = llmResult
                self:setVariable("output", llmResult)
                
                -- Store action result
                self:setMetadata("lastAction", action.name)
                self:setMetadata("lastResult", llmResult)
                
                -- Continue with next action
                self:_executeActionsRecursive(actions, index + 1)
            end)
            
            return -- Exit here, continuation happens in callback
        elseif asyncOp.type == "input_dialog" then
            print("🤖 Starting async input dialog operation...")
            
            -- Check if showConfigurableTextInput method exists (for fallback)
            if self.uiManager.showConfigurableTextInput then
                print("🤖 Using configurable WebView input dialog")
                -- Show configurable text input dialog
                self.uiManager:showConfigurableTextInput(
                    asyncOp.title,
                    asyncOp.message,
                    asyncOp.defaultText,
                    function(userInput)
                        if userInput and userInput ~= "" then
                            print("🤖 ✓ User provided input: " .. userInput)
                            
                            -- Create the prompt template with user input
                            local fullTemplate = userInput .. "\n\n" .. asyncOp.template
                            
                            -- Save the prompt to memory (temporary prompts table)
                            -- Use the config's set method to properly save the prompt
                            local promptData = {
                                title = "Ad-hoc: " .. userInput:sub(1, 50) .. (userInput:len() > 50 and "..." or ""),
                                description = "User-defined ad-hoc prompt",
                                template = fullTemplate,
                                category = "custom",
                                adhoc = true
                            }
                            
                            -- Save to config using the proper path
                            self.config:set("prompts." .. asyncOp.outputPromptName, promptData)
                            
                            -- Also save to the prompts table directly as fallback
                            if not self.config.prompts then
                                self.config.prompts = {}
                            end
                            self.config.prompts[asyncOp.outputPromptName] = promptData
                            
                            print("🤖 ✓ Prompt saved to memory as: " .. asyncOp.outputPromptName)
                            
                            -- Set variables for immediate use
                            self:setVariable("input_prompt", userInput)
                            self:setVariable("output", asyncOp.outputPromptName)
                            
                            -- Store action result
                            self:setMetadata("lastAction", action.name)
                            self:setMetadata("lastResult", asyncOp.outputPromptName)
                            
                            -- Continue with next action
                            self:_executeActionsRecursive(actions, index + 1)
                        else
                            print("🤖 ✗ Input dialog cancelled")
                            hs.alert.show("Input cancelled")
                            self.isExecuting = false
                            return
                        end
                    end,
                    asyncOp.uiConfig
                )
            else
                print("🤖 ⚠️ Fallback to simple text input dialog")
                -- Fallback to simple dialog
                self.uiManager:showTextInput(
                    asyncOp.title,
                    asyncOp.message,
                    asyncOp.defaultText,
                    function(userInput)
                        if userInput and userInput ~= "" then
                            print("🤖 ✓ User provided input (fallback): " .. userInput)
                            
                            -- Create the prompt template with user input
                            local fullTemplate = userInput .. "\n\n" .. asyncOp.template
                            
                            -- Save the prompt to memory
                            -- Use the config's set method to properly save the prompt
                            local promptData = {
                                title = "Ad-hoc: " .. userInput:sub(1, 50) .. (userInput:len() > 50 and "..." or ""),
                                description = "User-defined ad-hoc prompt",
                                template = fullTemplate,
                                category = "custom",
                                adhoc = true
                            }
                            
                            -- Save to config using the proper path
                            self.config:set("prompts." .. asyncOp.outputPromptName, promptData)
                            
                            -- Also save to the prompts table directly as fallback
                            if not self.config.prompts then
                                self.config.prompts = {}
                            end
                            self.config.prompts[asyncOp.outputPromptName] = promptData
                            
                            print("🤖 ✓ Prompt saved to memory as: " .. asyncOp.outputPromptName)
                            
                            -- Set variables for immediate use
                            self:setVariable("input_prompt", userInput)
                            self:setVariable("output", asyncOp.outputPromptName)
                            
                            -- Store action result
                            self:setMetadata("lastAction", action.name)
                            self:setMetadata("lastResult", asyncOp.outputPromptName)
                            
                            -- Continue with next action
                            self:_executeActionsRecursive(actions, index + 1)
                        else
                            print("🤖 ✗ Input dialog cancelled")
                            hs.alert.show("Input cancelled")
                            self.isExecuting = false
                            return
                        end
                    end
                )
            end
            
            return -- Exit here, continuation happens in callback
        end
    else
        print("🤖 ✓ Action completed: " .. action.name)
        
        -- Store action result
        self:setMetadata("lastAction", action.name)
        self:setMetadata("lastResult", result)
    end
    
    -- Continue with next action
    self:_executeActionsRecursive(actions, index + 1)
end

-- Helper function to validate input text
function ExecutionContext:validateInput()
    print("🤖 Validating input...")
    
    if not self.input or self.input == "" then
        print("🤖 No input in context, getting from text selection...")
        
        -- Try to get input from text selection or clipboard
        local input = self.textHandler:getSelectedText()
        print("🤖 Text selection result: " .. (input or "nil"):sub(1, 100) .. (((input or ""):len() > 100) and "..." or ""))
        
        if not input or input == "" then
            print("🤖 No selected text, falling back to clipboard...")
            input = self.textHandler:getClipboard()
            print("🤖 Clipboard result: " .. (input or "nil"):sub(1, 100) .. (((input or ""):len() > 100) and "..." or ""))
        end
        
        if not input or input == "" then
            error("No input text available. Please select text or copy to clipboard.")
        end
        
        self.input = input
        self:setVariable("input", input)
        self:setVariable("selected_text", input)
        print("🤖 Input acquired: " .. input:sub(1, 50) .. (input:len() > 50 and "..." or ""))
    else
        -- Input already exists, just validate it's not corrupted
        print("🤖 Input already exists: " .. self.input:sub(1, 50) .. (self.input:len() > 50 and "..." or ""))
        
        -- Double check input is not a command string
        if self.input:match("^[%w%.]+%s+%-%-") or self.input:match("gemini%.py") or self.input:match("claude") then
            print("🤖 ⚠️ Input looks like a command, trying to get fresh text...")
            local freshInput = self.textHandler:getSelectedText()
            print("🤖 Fresh text result: " .. (freshInput or "nil"):sub(1, 100) .. (((freshInput or ""):len() > 100) and "..." or ""))
            
            if freshInput and freshInput ~= "" and not freshInput:match("^[%w%.]+%s+%-%-") then
                print("🤖 Using fresh input: " .. freshInput:sub(1, 50) .. (freshInput:len() > 50 and "..." or ""))
                self.input = freshInput
                self:setVariable("input", freshInput)
                self:setVariable("selected_text", freshInput)
            else
                print("🤖 Fresh input also looks like command or is empty, keeping original")
            end
        end
    end
    
    print("🤖 Input validated: " .. self.input:sub(1, 50) .. (self.input:len() > 50 and "..." or ""))
    return self.input
end

-- Helper function to get UI configuration
function ExecutionContext:getUIConfig(uiName)
    uiName = uiName or "default"
    local uiConfigs = self.config:get("ui") or {}
    
    -- Handle both array and object format
    if type(uiConfigs) == "table" then
        if uiConfigs[uiName] then
            -- Object format: ui.default, ui.minimal, etc.
            return uiConfigs[uiName]
        else
            -- Array format: find by name
            for _, uiConfig in ipairs(uiConfigs) do
                if uiConfig.name == uiName then
                    return uiConfig
                end
            end
        end
    end
    
    -- Return default UI config if not found
    return {
        outputMethod = "display",
        showProgress = true,
        menuWidth = 400,
        menuRows = 8
    }
end

-- Debug function to print context state
function ExecutionContext:debug()
    print("🤖 Context Debug:")
    print("  Input: " .. (self.input or "nil"):sub(1, 50) .. (((self.input or ""):len() > 50) and "..." or ""))
    print("  Output: " .. (self.output or "nil"):sub(1, 50) .. (((self.output or ""):len() > 50) and "..." or ""))
    print("  Variables:")
    for key, value in pairs(self.variables) do
        local valueStr = tostring(value):sub(1, 30) .. ((tostring(value):len() > 30) and "..." or "")
        print("    " .. key .. " = " .. valueStr)
    end
    print("  Metadata:")
    for key, value in pairs(self.metadata) do
        print("    " .. key .. " = " .. tostring(value))
    end
end

-- Debug function to show text selection state before action execution
function ExecutionContext:debugTextSelectionState()
    print("🤖 ===== TEXT SELECTION DEBUG =====")
    
    -- Show current context input
    print("🤖 Context Input: " .. (self.input or "nil"):sub(1, 100) .. (((self.input or ""):len() > 100) and "..." or ""))
    
    -- Test accessibility API directly
    local accessibilityText = self.textHandler:getSelectedTextViaAccessibility()
    print("🤖 Accessibility API Result: " .. (accessibilityText or "nil"):sub(1, 100) .. (((accessibilityText or ""):len() > 100) and "..." or ""))
    
    -- Test clipboard content
    local clipboardText = self.textHandler:getClipboard()
    print("🤖 Current Clipboard: " .. (clipboardText or "nil"):sub(1, 100) .. (((clipboardText or ""):len() > 100) and "..." or ""))
    
    -- Test full text selection method
    local selectedText = self.textHandler:getSelectedText()
    print("🤖 Full Selection Method: " .. (selectedText or "nil"):sub(1, 100) .. (((selectedText or ""):len() > 100) and "..." or ""))
    
    -- Show frontmost application
    local app = hs.application.frontmostApplication()
    if app then
        print("🤖 Frontmost App: " .. app:name())
        
        -- Show window title if available
        local window = app:focusedWindow()
        if window then
            print("🤖 Focused Window: " .. (window:title() or "untitled"))
        end
    end
    
    -- Compare all three sources
    local allSame = (self.input == accessibilityText) and (accessibilityText == clipboardText)
    local inputMatchesClipboard = (self.input == clipboardText)
    local inputMatchesAccessibility = (self.input == accessibilityText)
    
    print("🤖 Text Source Comparison:")
    print("🤖   Input == Accessibility: " .. tostring(inputMatchesAccessibility))
    print("🤖   Input == Clipboard: " .. tostring(inputMatchesClipboard))
    print("🤖   All sources same: " .. tostring(allSame))
    
    -- Check if input looks like a command
    local looksLikeCommand = (self.input or ""):match("^[%w%.]+%s+%-%-") or 
                             (self.input or ""):match("gemini%.py") or 
                             (self.input or ""):match("claude")
    print("🤖   Input looks like command: " .. tostring(looksLikeCommand))
    
    print("🤖 ================================")
end

return ExecutionContext