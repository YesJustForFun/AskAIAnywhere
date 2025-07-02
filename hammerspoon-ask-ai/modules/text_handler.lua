-- Text Handler Module
-- Handles text selection, clipboard operations, and text input/output

local TextHandler = {}
TextHandler.__index = TextHandler

function TextHandler:new()
    local instance = setmetatable({}, TextHandler)
    return instance
end

function TextHandler:getSelectedText()
    -- Use AppleScript to get selected text from any application
    local script = [[
        try
            tell application "System Events"
                set selectedText to ""
                -- Try to get selected text using copy command
                keystroke "c" using command down
                delay 0.1
                set selectedText to (the clipboard as string)
                return selectedText
            end tell
        on error
            return ""
        end try
    ]]
    
    -- Store current clipboard content
    local originalClipboard = hs.pasteboard.getContents()
    
    -- Execute AppleScript to copy selected text
    local success, result = hs.osascript.applescript(script)
    
    if success and result and result ~= "" and result ~= originalClipboard then
        -- Restore original clipboard if it was different
        if originalClipboard then
            hs.timer.doAfter(0.1, function()
                hs.pasteboard.setContents(originalClipboard)
            end)
        end
        return result
    end
    
    return ""
end

function TextHandler:getClipboard()
    return hs.pasteboard.getContents() or ""
end

function TextHandler:setClipboard(text)
    hs.pasteboard.setContents(text)
end

function TextHandler:replaceSelectedText(text)
    -- First copy the replacement text to clipboard
    local originalClipboard = hs.pasteboard.getContents()
    hs.pasteboard.setContents(text)
    
    -- Use AppleScript to paste the text
    local script = [[
        tell application "System Events"
            keystroke "v" using command down
        end tell
    ]]
    
    hs.osascript.applescript(script)
    
    -- Restore original clipboard after a short delay
    if originalClipboard then
        hs.timer.doAfter(0.5, function()
            hs.pasteboard.setContents(originalClipboard)
        end)
    end
end

function TextHandler:typeText(text)
    -- Type text directly using Hammerspoon
    -- Split into smaller chunks to avoid issues with long text
    local maxChunkSize = 100
    local textLength = string.len(text)
    
    if textLength <= maxChunkSize then
        hs.eventtap.keyStrokes(text)
    else
        -- Split into chunks and type with small delays
        for i = 1, textLength, maxChunkSize do
            local chunk = string.sub(text, i, math.min(i + maxChunkSize - 1, textLength))
            hs.eventtap.keyStrokes(chunk)
            if i + maxChunkSize <= textLength then
                hs.timer.usleep(50000) -- 50ms delay between chunks
            end
        end
    end
end

function TextHandler:getSelectedTextAdvanced()
    -- More robust method using accessibility API
    local app = hs.application.frontmostApplication()
    if not app then
        return self:getSelectedText()
    end
    
    local element = hs.uielement.focusedElement()
    if element then
        local selectedText = element:selectedText()
        if selectedText and selectedText ~= "" then
            return selectedText
        end
    end
    
    -- Fallback to standard method
    return self:getSelectedText()
end

function TextHandler:insertTextAtCursor(text)
    -- Insert text at current cursor position without replacing selection
    hs.eventtap.keyStrokes(text)
end

function TextHandler:getTextFromApp(appName)
    -- Get text from specific application
    local app = hs.application.get(appName)
    if not app then
        return ""
    end
    
    -- Focus the application
    app:activate()
    hs.timer.usleep(100000) -- 100ms delay
    
    -- Try to select all and copy
    local script = string.format([[
        tell application "%s"
            activate
        end tell
        
        tell application "System Events"
            keystroke "a" using command down
            delay 0.1
            keystroke "c" using command down
            delay 0.1
        end tell
    ]], appName)
    
    local originalClipboard = hs.pasteboard.getContents()
    local success, result = hs.osascript.applescript(script)
    
    if success then
        local newClipboard = hs.pasteboard.getContents()
        if newClipboard and newClipboard ~= originalClipboard then
            -- Restore original clipboard
            if originalClipboard then
                hs.timer.doAfter(0.1, function()
                    hs.pasteboard.setContents(originalClipboard)
                end)
            end
            return newClipboard
        end
    end
    
    return ""
end

function TextHandler:validateText(text)
    -- Validate that text is not empty and contains meaningful content
    if not text or text == "" then
        return false, "No text provided"
    end
    
    -- Remove whitespace and check if still has content
    local trimmed = text:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return false, "Text contains only whitespace"
    end
    
    -- Check for minimum length
    if string.len(trimmed) < 3 then
        return false, "Text too short"
    end
    
    return true, trimmed
end

function TextHandler:formatText(text, options)
    options = options or {}
    
    -- Trim whitespace
    text = text:match("^%s*(.-)%s*$")
    
    -- Remove extra line breaks if requested
    if options.removeExtraLineBreaks then
        text = text:gsub("\n\n+", "\n\n")
    end
    
    -- Convert line breaks if requested
    if options.lineBreakStyle == "unix" then
        text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    elseif options.lineBreakStyle == "windows" then
        text = text:gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\n", "\r\n")
    end
    
    return text
end

return TextHandler