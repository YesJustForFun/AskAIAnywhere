-- llm.lua
-- LLM provider interface for gemini and claude

local config = require("modules.config")
local llm = {}

-- Execute shell command with timeout
local function executeCommand(command, timeout)
    timeout = timeout or 30
    
    local output = ""
    local exitCode = -1
    
    -- Use hs.execute with timeout
    local task = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        output = stdOut or ""
        if stdErr and stdErr ~= "" then
            output = output .. "\nError: " .. stdErr
        end
    end, {"-c", command})
    
    if task then
        task:start()
        
        -- Wait for completion with timeout
        local startTime = hs.timer.secondsSinceEpoch()
        while task:isRunning() do
            if hs.timer.secondsSinceEpoch() - startTime > timeout then
                task:terminate()
                return false, "Command timed out after " .. timeout .. " seconds"
            end
            hs.timer.usleep(100000) -- 0.1 second
        end
        
        exitCode = task:terminationStatus()
    end
    
    return exitCode == 0, output
end

-- Escape text for shell command
local function escapeShellArg(arg)
    return "'" .. string.gsub(arg, "'", "'\"'\"'") .. "'"
end

-- Build prompt for different operations
local function buildPrompt(operation, text, options)
    options = options or {}
    
    local prompts = {
        improve = "Please improve the writing of the following text, making it clearer, more concise, and better structured:\n\n" .. text,
        
        translate_en = "Please translate the following text to English:\n\n" .. text,
        
        translate_zh = "Please translate the following text to Chinese:\n\n" .. text,
        
        translate = "Please translate the following text to " .. (options.language or "English") .. ":\n\n" .. text,
        
        summarize = "Please provide a concise summary of the following text:\n\n" .. text,
        
        tone_professional = "Please rewrite the following text in a professional tone:\n\n" .. text,
        
        tone_casual = "Please rewrite the following text in a casual, friendly tone:\n\n" .. text,
        
        tone = "Please rewrite the following text in a " .. (options.tone or "professional") .. " tone:\n\n" .. text,
        
        continue = "Please continue writing the following text in the same style and context:\n\n" .. text,
        
        custom = (options.prompt or "Please help with the following text:\n\n") .. text,
    }
    
    return prompts[operation] or prompts.custom
end

-- Call LLM provider
function llm.call(provider, prompt, options)
    options = options or {}
    local timeout = options.timeout or config.get("llm.timeout") or 30
    
    local command
    if provider == "gemini" then
        command = config.get("llm.gemini_command") or "gemini -p"
    elseif provider == "claude" then
        command = config.get("llm.claude_command") or "claude -p"
    else
        return false, "Unknown provider: " .. tostring(provider)
    end
    
    -- Build full command
    local fullCommand = command .. " " .. escapeShellArg(prompt)
    
    -- Execute command
    local success, output = executeCommand(fullCommand, timeout)
    
    if success then
        -- Clean up the output
        output = string.gsub(output, "^%s+", "") -- remove leading whitespace
        output = string.gsub(output, "%s+$", "") -- remove trailing whitespace
        return true, output
    else
        return false, output
    end
end

-- Perform text operation
function llm.performOperation(operation, text, options)
    options = options or {}
    local provider = options.provider or config.get("llm.default_provider") or "gemini"
    
    -- Validate inputs
    if not text or text == "" then
        return false, "No text provided"
    end
    
    if not operation or operation == "" then
        return false, "No operation specified"
    end
    
    -- Build appropriate prompt
    local prompt = buildPrompt(operation, text, options)
    
    -- Call LLM
    return llm.call(provider, prompt, options)
end

-- Test LLM connectivity
function llm.test(provider)
    provider = provider or config.get("llm.default_provider") or "gemini"
    
    local testPrompt = "Please respond with just the word 'OK' if you can see this message."
    local success, response = llm.call(provider, testPrompt, {timeout = 10})
    
    if success then
        -- Check if response contains "OK"
        if string.find(string.upper(response), "OK") then
            return true, provider .. " is working correctly"
        else
            return false, provider .. " responded but with unexpected output: " .. response
        end
    else
        return false, "Failed to connect to " .. provider .. ": " .. response
    end
end

-- Get available providers
function llm.getAvailableProviders()
    local providers = {}
    
    -- Test gemini
    local geminiSuccess = llm.test("gemini")
    if geminiSuccess then
        table.insert(providers, "gemini")
    end
    
    -- Test claude
    local claudeSuccess = llm.test("claude")
    if claudeSuccess then
        table.insert(providers, "claude")
    end
    
    return providers
end

return llm
