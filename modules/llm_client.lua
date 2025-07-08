-- LLM Client Module
-- Handles communication with LLM providers via CLI commands

local LLMClient = {}
LLMClient.__index = LLMClient

function LLMClient:new(configManager)
    local instance = setmetatable({}, LLMClient)
    instance.config = configManager
    return instance
end

function LLMClient:execute(provider, prompt, callback)
    -- Get provider configuration
    local providerConfig = self.config:getProviderConfig(provider)
    if not providerConfig or not providerConfig.enabled then
        callback(nil, "Provider " .. provider .. " is not enabled or configured")
        return
    end
    
    -- Build command
    local command = self:buildCommand(providerConfig, prompt)
    if not command then
        callback(nil, "Failed to build command for provider " .. provider)
        return
    end
    
    -- Execute command asynchronously
    self:executeCommand(command, providerConfig.timeout or 30, callback)
end

function LLMClient:buildCommand(providerConfig, prompt)
    local cmd = providerConfig.command
    local args = providerConfig.args or {}
    
    -- Check for extremely long prompts
    if #prompt > 32000 then
        print("🤖 Warning: Prompt is very long (" .. #prompt .. " chars), might cause issues")
    end
    
    -- For very long prompts or prompts with special characters, use temp file
    -- For short, simple prompts, use direct piping for better performance
    if #prompt > 4000 or self:hasSpecialCharacters(prompt) then
        print("🤖 Using temp file approach for complex prompt")
        return self:buildCommandWithTempFile(cmd, prompt, args)
    else
        print("🤖 Using direct piping for simple prompt")
        return self:buildCommandWithDirectPipe(cmd, prompt, args)
    end
end

function LLMClient:hasSpecialCharacters(text)
    -- Check for characters that might cause shell issues
    return text:match("['\"`\\$%*%?%[%]%{%}%(%)%|&;<>%s]") ~= nil
end

function LLMClient:buildCommandWithDirectPipe(cmd, prompt, args)
    -- Escape prompt for shell
    local escapedPrompt = self:escapeShellArg(prompt)
    
    -- Build command string
    local command = "echo " .. escapedPrompt .. " | " .. cmd
    
    -- Add arguments
    for _, arg in ipairs(args) do
        command = command .. " " .. self:escapeShellArg(arg)
    end
    
    return command
end

function LLMClient:buildCommandWithTempFile(cmd, prompt, args)
    -- Create temporary file path
    local tempFile = "/tmp/ask_ai_input_" .. os.time() .. "_" .. math.random(1000, 9999) .. ".txt"
    
    -- Write prompt directly to temp file using Lua I/O
    local success, error = self:writeToTempFile(tempFile, prompt)
    if not success then
        print("🤖 ✗ Failed to write temp file: " .. error)
        return nil
    end
    
    -- Build command to read from temp file
    local command = cmd
    
    -- Add arguments
    for _, arg in ipairs(args) do
        command = command .. " " .. self:escapeShellArg(arg)
    end
    
    -- Add temp file as input and cleanup
    command = command .. " < " .. tempFile .. " && rm " .. tempFile
    
    return command
end

function LLMClient:writeToTempFile(tempFile, content)
    -- Write content directly to file using Lua I/O
    local file, error = io.open(tempFile, "w")
    if not file then
        return false, "Cannot open temp file: " .. (error or "unknown error")
    end
    
    local success, writeError = file:write(content)
    file:close()
    
    if not success then
        return false, "Cannot write to temp file: " .. (writeError or "unknown error")
    end
    
    return true, nil
end

function LLMClient:escapeShellArg(arg)
    -- Escape shell argument with single quotes
    return "'" .. arg:gsub("'", "'\"'\"'") .. "'"
end

function LLMClient:expandPath(path)
    -- Expand ~ and $HOME in paths
    if not path then return path end
    
    -- Replace ~ with home directory
    path = path:gsub("^~", os.getenv("HOME") or "~")
    
    -- Replace $HOME with actual home directory
    path = path:gsub("$HOME", os.getenv("HOME") or "$HOME")
    
    return path
end

function LLMClient:buildEnvironmentCommand()
    -- Get custom PATH from configuration
    local customPaths = self.config:get("environment.paths", {})
    
    if #customPaths == 0 then
        -- No custom paths, just use basic environment
        return ""
    end
    
    -- Expand paths and build PATH export
    local expandedPaths = {}
    for _, path in ipairs(customPaths) do
        table.insert(expandedPaths, self:expandPath(path))
    end
    
    -- Add current PATH at the end
    table.insert(expandedPaths, "$PATH")
    
    local pathString = table.concat(expandedPaths, ":")
    return "export PATH=\"" .. pathString .. "\"; "
end

function LLMClient:executeCommand(command, timeout, callback)
    -- Build environment command with custom PATH
    local envCommand = self:buildEnvironmentCommand() .. command
    
    -- Log the command being executed
    print("🤖 Executing command: " .. envCommand)
    
    -- Create a task to execute the command
    local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            -- Success
            local result = stdOut:match("^%s*(.-)%s*$") -- Trim whitespace
            callback(result, nil)
        else
            -- Error
            local error = stdErr ~= "" and stdErr or "Command failed with exit code " .. exitCode
            callback(nil, error)
        end
    end, {"-c", envCommand})
    
    -- Set timeout
    if timeout then
        hs.timer.doAfter(timeout, function()
            if task:isRunning() then
                task:terminate()
                callback(nil, "Command timed out after " .. timeout .. " seconds")
            end
        end)
    end
    
    -- Start the task
    task:start()
end

function LLMClient:executeWithFallback(prompt, callback)
    local primaryProvider = self.config:getDefaultProvider()
    local fallbackProvider = self.config:getFallbackProvider()
    
    -- Try primary provider first
    self:execute(primaryProvider, prompt, function(result, error)
        if result then
            callback(result, nil)
        elseif fallbackProvider and fallbackProvider ~= primaryProvider then
            -- Try fallback provider
            self:execute(fallbackProvider, prompt, function(fallbackResult, fallbackError)
                if fallbackResult then
                    callback(fallbackResult, nil)
                else
                    -- Both failed
                    local combinedError = "Primary provider (" .. primaryProvider .. ") failed: " .. (error or "unknown error")
                    if fallbackError then
                        combinedError = combinedError .. "; Fallback provider (" .. fallbackProvider .. ") failed: " .. fallbackError
                    end
                    callback(nil, combinedError)
                end
            end)
        else
            -- No fallback, return original error
            callback(nil, error)
        end
    end)
end

function LLMClient:testProvider(provider, callback)
    local testPrompt = "Hello, please respond with 'OK' if you can read this message."
    
    self:execute(provider, testPrompt, function(result, error)
        if result then
            -- Check if response contains expected text
            local success = result:lower():find("ok") ~= nil
            callback(success, success and "Provider is working" or "Unexpected response: " .. result)
        else
            callback(false, error)
        end
    end)
end

function LLMClient:testAllProviders(callback)
    local llmConfig = self.config:getLLMConfig()
    local providers = llmConfig.providers or {}
    local results = {}
    local remaining = 0
    
    -- Count enabled providers
    for name, config in pairs(providers) do
        if config.enabled then
            remaining = remaining + 1
        end
    end
    
    if remaining == 0 then
        callback({})
        return
    end
    
    -- Test each enabled provider
    for name, config in pairs(providers) do
        if config.enabled then
            self:testProvider(name, function(success, message)
                results[name] = {
                    success = success,
                    message = message
                }
                
                remaining = remaining - 1
                if remaining == 0 then
                    callback(results)
                end
            end)
        end
    end
end

function LLMClient:checkCommandAvailability(command, callback)
    local checkCommand = "command -v " .. command
    
    hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        callback(exitCode == 0, exitCode == 0 and stdOut:match("^%s*(.-)%s*$") or nil)
    end, {"-c", checkCommand}):start()
end

function LLMClient:validateConfiguration()
    local llmConfig = self.config:getLLMConfig()
    local providers = llmConfig.providers or {}
    local issues = {}
    
    -- Check if any providers are enabled
    local hasEnabledProvider = false
    for name, config in pairs(providers) do
        if config.enabled then
            hasEnabledProvider = true
            
            -- Check if command exists
            if not config.command or config.command == "" then
                table.insert(issues, "Provider " .. name .. " has no command specified")
            end
        end
    end
    
    if not hasEnabledProvider then
        table.insert(issues, "No LLM providers are enabled")
    end
    
    -- Check default provider
    local defaultProvider = llmConfig.defaultProvider
    if defaultProvider and (not providers[defaultProvider] or not providers[defaultProvider].enabled) then
        table.insert(issues, "Default provider " .. defaultProvider .. " is not enabled")
    end
    
    return #issues == 0, issues
end

function LLMClient:formatPrompt(operation, text, customPrompt)
    local prompt
    
    if customPrompt and customPrompt ~= "" then
        prompt = customPrompt
    else
        local operations = self.config:getOperations()
        local operationConfig = operations[operation]
        if operationConfig and operationConfig.prompt then
            prompt = operationConfig.prompt
        else
            prompt = "Please process the following text:"
        end
    end
    
    return prompt .. "\n\n" .. text
end

return LLMClient