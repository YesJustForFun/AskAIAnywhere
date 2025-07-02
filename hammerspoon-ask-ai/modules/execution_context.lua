-- Execution Context for Ask AI Anywhere
-- Manages execution state and variable substitution for action chains

local ExecutionContext = {}
ExecutionContext.__index = ExecutionContext

function ExecutionContext:new(input, config, components)
    local context = {
        input = input or "",
        output = nil,
        variables = {
            input = input or "",
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
        parent = nil
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
            return tostring(value or "")
        end)
    end
    
    if iteration >= maxIterations then
        print("🤖 Warning: Variable substitution reached maximum iterations")
    end
    
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

-- Execute a sequence of actions
function ExecutionContext:executeActions(actions)
    if not actions or #actions == 0 then
        print("🤖 No actions to execute")
        return
    end
    
    print("🤖 Executing " .. #actions .. " actions")
    
    for i, action in ipairs(actions) do
        print("🤖 Action " .. i .. "/" .. #actions .. ": " .. action.name)
        
        local success, result = pcall(function()
            return self.actionRegistry:execute(action.name, action.args or {}, self)
        end)
        
        if not success then
            print("🤖 ✗ Action failed: " .. action.name .. " - " .. result)
            error("Action chain failed at step " .. i .. " (" .. action.name .. "): " .. result)
        else
            print("🤖 ✓ Action completed: " .. action.name)
            
            -- Store action result if needed
            self:setMetadata("lastAction", action.name)
            self:setMetadata("lastResult", result)
        end
    end
    
    print("🤖 All actions completed successfully")
end

-- Helper function to validate input text
function ExecutionContext:validateInput()
    if not self.input or self.input == "" then
        -- Try to get input from text selection or clipboard
        local input = self.textHandler:getSelectedText()
        if not input or input == "" then
            input = self.textHandler:getClipboard()
        end
        
        if not input or input == "" then
            error("No input text available. Please select text or copy to clipboard.")
        end
        
        self.input = input
        self:setVariable("input", input)
        print("🤖 Input acquired: " .. input:sub(1, 50) .. (input:len() > 50 and "..." or ""))
    end
    
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

return ExecutionContext