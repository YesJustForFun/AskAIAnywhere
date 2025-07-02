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
    
    -- Escape prompt for shell
    local escapedPrompt = self:escapeShellArg(prompt)
    
    -- Build command string
    local command = "echo " .. escapedPrompt .. " | " .. cmd
    
    -- Add arguments
    for _, arg in ipairs(args) do
        command = command .. " " .. arg
    end
    
    return command
end

function LLMClient:escapeShellArg(arg)
    -- Escape shell argument with single quotes
    return "'" .. arg:gsub("'", "'\"'\"'") .. "'"
end

function LLMClient:executeCommand(command, timeout, callback)
    -- Get user's shell and PATH environment, including asdf
    local envCommand = "source ~/.asdf/asdf.sh 2>/dev/null || true; source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true; " .. command
    
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