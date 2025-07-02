-- text_operations.lua
-- Text processing and manipulation functions

local llm = require("modules.llm")
local config = require("modules.config")

local textOps = {}

-- Get currently selected text or clipboard content
function textOps.getInputText()
    -- Try to get selected text first
    local selectedText = textOps.getSelectedText()
    
    if selectedText and selectedText ~= "" then
        return selectedText, "selection"
    end
    
    -- Fallback to clipboard
    local clipboardText = hs.pasteboard.getContents()
    if clipboardText and clipboardText ~= "" then
        return clipboardText, "clipboard"
    end
    
    return nil, "none"
end

-- Get selected text from current application
function textOps.getSelectedText()
    -- Save current clipboard content
    local originalClipboard = hs.pasteboard.getContents()
    
    -- Copy selected text to clipboard
    hs.eventtap.keyStroke({"cmd"}, "c")
    
    -- Wait a bit for the copy to complete
    hs.timer.usleep(200000) -- 0.2 seconds
    
    -- Get the copied text
    local selectedText = hs.pasteboard.getContents()
    
    -- Restore original clipboard if nothing was selected
    if selectedText == originalClipboard then
        selectedText = nil
    else
        -- We got new text, but we should restore clipboard later
        -- For now, we'll keep the selected text in clipboard
    end
    
    return selectedText
end

-- Output result to the specified destination
function textOps.outputResult(result, outputMode, originalText)
    outputMode = outputMode or "clipboard"
    
    if not result or result == "" then
        hs.notify.new({
            title = "Ask AI Anywhere",
            informativeText = "No result to output",
            hasActionButton = false
        }):send()
        return false
    end
    
    if outputMode == "clipboard" then
        hs.pasteboard.setContents(result)
        if config.get("ui.show_notifications") then
            hs.notify.new({
                title = "Ask AI Anywhere",
                informativeText = "Result copied to clipboard",
                hasActionButton = false
            }):send()
        end
        
    elseif outputMode == "replace" then
        -- Replace selected text with result
        hs.pasteboard.setContents(result)
        hs.eventtap.keyStroke({"cmd"}, "v")
        
    elseif outputMode == "insert" then
        -- Insert result at cursor position
        hs.eventtap.keyStrokes(result)
        
    elseif outputMode == "dialog" then
        -- Show result in a dialog
        textOps.showResultDialog(result, originalText)
        
    else
        -- Default to clipboard
        hs.pasteboard.setContents(result)
    end
    
    return true
end

-- Show result in a dialog window
function textOps.showResultDialog(result, originalText)
    local dialogText = result
    
    if originalText and originalText ~= "" then
        dialogText = "Original:\n" .. string.sub(originalText, 1, 200) .. 
                     (string.len(originalText) > 200 and "..." or "") .. 
                     "\n\n" .. string.rep("-", 40) .. "\n\nResult:\n" .. result
    end
    
    local button, text = hs.dialog.textPrompt(
        "Ask AI Anywhere - Result",
        "Here's the AI response:",
        dialogText,
        "Copy to Clipboard",
        "Close"
    )
    
    if button == "Copy to Clipboard" then
        hs.pasteboard.setContents(result)
        if config.get("ui.show_notifications") then
            hs.notify.new({
                title = "Ask AI Anywhere",
                informativeText = "Result copied to clipboard",
                hasActionButton = false
            }):send()
        end
    end
end

-- Perform text operation with progress indication
function textOps.performOperation(operation, options)
    options = options or {}
    
    -- Get input text
    local inputText, inputSource = textOps.getInputText()
    
    if not inputText or inputText == "" then
        hs.notify.new({
            title = "Ask AI Anywhere",
            informativeText = "No text selected or in clipboard",
            hasActionButton = false
        }):send()
        return false
    end
    
    -- Show progress notification
    local progressNotification = hs.notify.new({
        title = "Ask AI Anywhere",
        informativeText = "Processing with AI...",
        hasActionButton = false
    })
    
    if config.get("ui.show_notifications") then
        progressNotification:send()
    end
    
    -- Perform the operation asynchronously
    hs.timer.doAfter(0.1, function()
        local success, result = llm.performOperation(operation, inputText, options)
        
        -- Withdraw progress notification
        if progressNotification then
            progressNotification:withdraw()
        end
        
        if success then
            -- Determine output mode
            local outputMode = options.outputMode or "clipboard"
            textOps.outputResult(result, outputMode, inputText)
        else
            -- Show error
            hs.notify.new({
                title = "Ask AI Anywhere - Error",
                informativeText = result or "Unknown error occurred",
                hasActionButton = false
            }):send()
        end
    end)
    
    return true
end

-- Quick operations (bypass menu)
function textOps.quickImprove(outputMode)
    return textOps.performOperation("improve", {outputMode = outputMode or "replace"})
end

function textOps.quickTranslate(language, outputMode)
    language = language or "en"
    local operation = "translate_" .. language
    return textOps.performOperation(operation, {outputMode = outputMode or "replace"})
end

function textOps.quickSummarize(outputMode)
    return textOps.performOperation("summarize", {outputMode = outputMode or "dialog"})
end

-- Custom prompt operation
function textOps.customPrompt()
    local inputText, inputSource = textOps.getInputText()
    
    if not inputText or inputText == "" then
        hs.notify.new({
            title = "Ask AI Anywhere",
            informativeText = "No text selected or in clipboard",
            hasActionButton = false
        }):send()
        return false
    end
    
    -- Show prompt dialog
    local button, customPrompt = hs.dialog.textPrompt(
        "Ask AI Anywhere - Custom Prompt",
        "Enter your custom prompt (the selected text will be appended):",
        "",
        "Process",
        "Cancel"
    )
    
    if button == "Process" and customPrompt and customPrompt ~= "" then
        return textOps.performOperation("custom", {
            prompt = customPrompt .. "\n\n",
            outputMode = "dialog"
        })
    end
    
    return false
end

-- Utility function to truncate text for display
function textOps.truncateText(text, maxLength)
    maxLength = maxLength or 50
    if string.len(text) <= maxLength then
        return text
    end
    return string.sub(text, 1, maxLength - 3) .. "..."
end

return textOps
