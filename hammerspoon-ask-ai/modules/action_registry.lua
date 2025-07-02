-- Action Registry for Ask AI Anywhere
-- Manages all available actions and their execution

local ActionRegistry = {}
ActionRegistry.__index = ActionRegistry

function ActionRegistry:new()
    local instance = setmetatable({}, ActionRegistry)
    instance.actions = {}
    instance.metadata = {}
    
    -- Register core actions
    instance:registerCoreActions()
    
    return instance
end

-- Register a new action
function ActionRegistry:register(name, actionFunc, metadata)
    if type(actionFunc) ~= "function" then
        error("Action function must be a function, got: " .. type(actionFunc))
    end
    
    self.actions[name] = actionFunc
    self.metadata[name] = metadata or {}
    
    print("🤖 Action registered: " .. name)
end

-- Execute an action with arguments and context
function ActionRegistry:execute(actionName, args, context)
    local action = self.actions[actionName]
    if not action then
        error("Unknown action: " .. actionName)
    end
    
    print("🤖 Executing action: " .. actionName)
    
    -- Validate arguments if metadata exists
    local metadata = self.metadata[actionName]
    if metadata and metadata.parameters then
        args = self:validateAndProcessArgs(args, metadata.parameters, context)
    end
    
    -- Execute the action
    local success, result = pcall(action, args, context)
    if not success then
        error("Action execution failed for '" .. actionName .. "': " .. result)
    end
    
    return result
end

-- Validate and process arguments according to metadata
function ActionRegistry:validateAndProcessArgs(args, parameterDefs, context)
    local processedArgs = {}
    
    -- Process each parameter definition
    for paramName, paramDef in pairs(parameterDefs) do
        local value = args[paramName]
        
        -- Handle default values
        if value == nil and paramDef.default then
            if type(paramDef.default) == "string" and paramDef.default:match("^%${.+}$") then
                -- Substitute variable in default value
                value = context:substituteVariables(paramDef.default)
            else
                value = paramDef.default
            end
        end
        
        -- Check required parameters
        if paramDef.required and value == nil then
            error("Required parameter '" .. paramName .. "' missing for action")
        end
        
        -- Type validation
        if value ~= nil and paramDef.type then
            local actualType = type(value)
            if actualType ~= paramDef.type then
                -- Try to convert if possible
                if paramDef.type == "string" then
                    value = tostring(value)
                elseif paramDef.type == "number" then
                    local num = tonumber(value)
                    if num then
                        value = num
                    else
                        error("Parameter '" .. paramName .. "' must be a number, got: " .. actualType)
                    end
                else
                    error("Parameter '" .. paramName .. "' must be " .. paramDef.type .. ", got: " .. actualType)
                end
            end
        end
        
        processedArgs[paramName] = value
    end
    
    return processedArgs
end

-- Get list of available actions
function ActionRegistry:getAvailableActions()
    local actions = {}
    for name, metadata in pairs(self.metadata) do
        actions[name] = {
            name = name,
            description = metadata.description or "No description",
            parameters = metadata.parameters or {}
        }
    end
    return actions
end

-- Register core actions
function ActionRegistry:registerCoreActions()
    
    -- Run AI Prompt
    self:register("runPrompt", function(args, context)
        local prompt = args.prompt
        local provider = args.provider
        
        if not prompt then
            error("No prompt specified")
        end
        
        print("🤖 Running prompt: " .. prompt .. " with provider: " .. (provider or "default"))
        
        -- Get prompt template
        local promptTemplate = context.config:get("prompts." .. prompt)
        if not promptTemplate then
            error("Unknown prompt template: " .. prompt)
        end
        
        -- Substitute variables in prompt template
        local promptText = context:substituteVariables(promptTemplate.template or promptTemplate.prompt)
        
        -- Execute with LLM client
        local result = context.llmClient:execute(promptText, provider)
        
        -- Update context with result
        context.output = result
        context:setVariable("output", result)
        
        return result
    end, {
        description = "Execute an AI prompt",
        parameters = {
            prompt = {
                type = "string",
                required = true,
                description = "Prompt template name"
            },
            provider = {
                type = "string",
                default = "${llm.defaultProvider}",
                description = "LLM provider to use"
            }
        }
    })
    
    -- Copy to Clipboard
    self:register("copyToClipboard", function(args, context)
        local text = context:substituteVariables(args.text)
        
        if not text or text == "" then
            print("🤖 Warning: Empty text for clipboard")
            return
        end
        
        context.textHandler:setClipboard(text)
        print("🤖 Text copied to clipboard")
        return text
    end, {
        description = "Copy text to clipboard",
        parameters = {
            text = {
                type = "string",
                required = true,
                description = "Text to copy (supports variables)"
            }
        }
    })
    
    -- Display Text
    self:register("displayText", function(args, context)
        local text = context:substituteVariables(args.text)
        local ui = args.ui or "default"
        
        if not text or text == "" then
            print("🤖 Warning: Empty text for display")
            return
        end
        
        context.uiManager:showResult(text, ui)
        print("🤖 Text displayed with UI: " .. ui)
        return text
    end, {
        description = "Display text using specified UI",
        parameters = {
            text = {
                type = "string",
                required = true,
                description = "Text to display (supports variables)"
            },
            ui = {
                type = "string",
                default = "default",
                description = "UI configuration name"
            }
        }
    })
    
    -- Paste at Cursor
    self:register("pasteAtCursor", function(args, context)
        local text = context:substituteVariables(args.text)
        
        if not text or text == "" then
            print("🤖 Warning: Empty text for paste")
            return
        end
        
        context.textHandler:typeText(text)
        print("🤖 Text pasted at cursor")
        return text
    end, {
        description = "Type text at cursor position",
        parameters = {
            text = {
                type = "string",
                required = true,
                description = "Text to type (supports variables)"
            }
        }
    })
    
    -- Show Notification
    self:register("showNotification", function(args, context)
        local message = context:substituteVariables(args.message)
        local duration = args.duration or 3
        
        if not message or message == "" then
            print("🤖 Warning: Empty notification message")
            return
        end
        
        hs.alert.show(message, duration)
        print("🤖 Notification shown: " .. message)
        return message
    end, {
        description = "Show system notification",
        parameters = {
            message = {
                type = "string",
                required = true,
                description = "Notification message"
            },
            duration = {
                type = "number",
                default = 3,
                description = "Display duration in seconds"
            }
        }
    })
    
    -- Show Main Menu
    self:register("showMainMenu", function(args, context)
        local title = args.title or "Ask AI Anywhere"
        local ui = args.ui or "menu"
        
        print("🤖 Showing main menu with title: " .. title)
        
        -- Get available operations from prompts
        local prompts = context.config:get("prompts") or {}
        local operations = {}
        
        for promptName, promptData in pairs(prompts) do
            table.insert(operations, {
                operation = promptName,
                title = promptData.title or promptName,
                description = promptData.description or "No description",
                category = promptData.category or "general"
            })
        end
        
        -- Show chooser with operations
        context.uiManager:showOperationChooser(operations, function(choice)
            if choice then
                print("🤖 Menu selection: " .. choice.operation)
                -- Execute the selected operation
                local newContext = context:createChild()
                context.actionRegistry:execute("runPrompt", {prompt = choice.operation}, newContext)
                context.actionRegistry:execute("displayText", {text = "${output}", ui = "default"}, newContext)
            end
        end, ui)
        
        return title
    end, {
        description = "Show the main operations menu",
        parameters = {
            title = {
                type = "string",
                default = "Ask AI Anywhere",
                description = "Menu title"
            },
            ui = {
                type = "string",
                default = "menu", 
                description = "UI configuration for menu"
            }
        }
    })
    
    -- Replace Selected Text
    self:register("replaceSelectedText", function(args, context)
        local text = context:substituteVariables(args.text)
        
        if not text or text == "" then
            print("🤖 Warning: Empty text for replacement")
            return
        end
        
        context.textHandler:replaceSelectedText(text)
        print("🤖 Selected text replaced")
        return text
    end, {
        description = "Replace currently selected text",
        parameters = {
            text = {
                type = "string",
                required = true,
                description = "Replacement text (supports variables)"
            }
        }
    })
    
    -- Save to File
    self:register("saveToFile", function(args, context)
        local filename = context:substituteVariables(args.filename)
        local content = context:substituteVariables(args.content)
        
        if not filename or filename == "" then
            error("No filename specified")
        end
        
        if not content then
            content = ""
        end
        
        -- Expand home directory
        filename = filename:gsub("^~", os.getenv("HOME"))
        
        -- Write file
        local file = io.open(filename, "w")
        if not file then
            error("Could not open file for writing: " .. filename)
        end
        
        file:write(content)
        file:close()
        
        print("🤖 Content saved to file: " .. filename)
        return filename
    end, {
        description = "Save text to file",
        parameters = {
            filename = {
                type = "string",
                required = true,
                description = "File path to save to (supports variables)"
            },
            content = {
                type = "string",
                required = true,
                description = "Content to save (supports variables)"
            }
        }
    })
    
    print("🤖 Core actions registered successfully")
end

return ActionRegistry