-- AI Operations Module
-- Handles different AI operations and their execution

local AIOperations = {}
AIOperations.__index = AIOperations

function AIOperations:new(llmClient)
    local instance = setmetatable({}, AIOperations)
    instance.llmClient = llmClient
    return instance
end

function AIOperations:getAvailableOperations()
    local operations = self.llmClient.config:getOperations()
    local availableOperations = {}
    
    for key, config in pairs(operations) do
        table.insert(availableOperations, {
            operation = key,
            title = config.title or key,
            description = config.description or "",
            text = config.title or key,
            subText = config.description or ""
        })
    end
    
    -- Sort by title
    table.sort(availableOperations, function(a, b)
        return a.title < b.title
    end)
    
    return availableOperations
end

function AIOperations:execute(operation, inputText, callback)
    -- Validate input
    if not inputText or inputText == "" then
        callback(nil, "No input text provided")
        return
    end
    
    -- Get operation configuration
    local operations = self.llmClient.config:getOperations()
    local operationConfig = operations[operation]
    
    if not operationConfig then
        callback(nil, "Unknown operation: " .. operation)
        return
    end
    
    -- Format the prompt
    local prompt = self.llmClient:formatPrompt(operation, inputText)
    
    -- Execute with LLM
    self.llmClient:executeWithFallback(prompt, function(result, error)
        if result then
            -- Post-process result if needed
            local processedResult = self:postProcessResult(operation, result, inputText)
            callback(processedResult, nil)
        else
            callback(nil, error)
        end
    end)
end

function AIOperations:postProcessResult(operation, result, originalText)
    -- Clean up the result
    result = result:match("^%s*(.-)%s*$") -- Trim whitespace
    
    -- Operation-specific post-processing
    if operation == "fix_grammar" then
        -- For grammar fixes, ensure we don't add extra content
        result = self:cleanGrammarFix(result, originalText)
    elseif operation == "translate_chinese" or operation == "translate_english" then
        -- For translations, remove any explanatory text
        result = self:cleanTranslation(result)
    elseif operation == "summarize" then
        -- For summaries, ensure it's concise
        result = self:cleanSummary(result)
    end
    
    return result
end

function AIOperations:cleanGrammarFix(result, originalText)
    -- Remove common AI prefixes/suffixes
    local cleanResult = result:gsub("^Here's the corrected text:?\n?", "")
    cleanResult = cleanResult:gsub("^Here is the corrected version:?\n?", "")
    cleanResult = cleanResult:gsub("^Corrected text:?\n?", "")
    cleanResult = cleanResult:gsub("^The corrected text is:?\n?", "")
    
    return cleanResult:match("^%s*(.-)%s*$")
end

function AIOperations:cleanTranslation(result)
    -- Remove translation prefixes/suffixes
    local cleanResult = result:gsub("^Here's the translation:?\n?", "")
    cleanResult = cleanResult:gsub("^Translation:?\n?", "")
    cleanResult = cleanResult:gsub("^The translation is:?\n?", "")
    
    return cleanResult:match("^%s*(.-)%s*$")
end

function AIOperations:cleanSummary(result)
    -- Remove summary prefixes
    local cleanResult = result:gsub("^Here's a summary:?\n?", "")
    cleanResult = cleanResult:gsub("^Summary:?\n?", "")
    cleanResult = cleanResult:gsub("^Here is a summary:?\n?", "")
    
    return cleanResult:match("^%s*(.-)%s*$")
end

function AIOperations:executeCustomOperation(prompt, inputText, callback)
    -- Execute a custom operation with user-provided prompt
    local fullPrompt = prompt .. "\n\n" .. inputText
    
    self.llmClient:executeWithFallback(fullPrompt, function(result, error)
        if result then
            -- Minimal post-processing for custom operations
            local processedResult = result:match("^%s*(.-)%s*$")
            callback(processedResult, nil)
        else
            callback(nil, error)
        end
    end)
end

function AIOperations:getOperationByTitle(title)
    local operations = self:getAvailableOperations()
    for _, op in ipairs(operations) do
        if op.title == title then
            return op.operation
        end
    end
    return nil
end

function AIOperations:validateOperation(operation)
    local operations = self.llmClient.config:getOperations()
    return operations[operation] ~= nil
end

function AIOperations:getOperationPrompt(operation)
    local operations = self.llmClient.config:getOperations()
    local operationConfig = operations[operation]
    
    if operationConfig then
        return operationConfig.prompt
    end
    
    return nil
end

function AIOperations:preProcessText(text, operation)
    -- Pre-process text based on operation type
    if operation == "translate_chinese" or operation == "translate_english" then
        -- For translations, preserve formatting
        return text
    elseif operation == "fix_grammar" then
        -- For grammar fixes, preserve original structure
        return text
    elseif operation == "summarize" then
        -- For summaries, clean up extra whitespace
        return text:gsub("%s+", " "):match("^%s*(.-)%s*$")
    else
        -- Default: basic cleanup
        return text:match("^%s*(.-)%s*$")
    end
end

function AIOperations:estimateTokens(text)
    -- Rough estimation: 1 token ≈ 4 characters
    return math.ceil(string.len(text) / 4)
end

function AIOperations:checkTextLength(text, maxTokens)
    maxTokens = maxTokens or 4000 -- Default limit
    local estimatedTokens = self:estimateTokens(text)
    
    if estimatedTokens > maxTokens then
        return false, "Text is too long (" .. estimatedTokens .. " tokens, max: " .. maxTokens .. ")"
    end
    
    return true, estimatedTokens
end

function AIOperations:truncateText(text, maxTokens)
    maxTokens = maxTokens or 4000
    local maxChars = maxTokens * 4 -- Rough conversion
    
    if string.len(text) <= maxChars then
        return text
    end
    
    -- Truncate at word boundary
    local truncated = string.sub(text, 1, maxChars)
    local lastSpace = truncated:find("%s[^%s]*$")
    
    if lastSpace then
        truncated = string.sub(truncated, 1, lastSpace - 1)
    end
    
    return truncated .. "..."
end

return AIOperations