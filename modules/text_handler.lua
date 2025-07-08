-- Text Handler Module
-- Handles text selection, clipboard operations, and text input/output

local TextHandler = {}
TextHandler.__index = TextHandler

function TextHandler:new()
    local instance = setmetatable({}, TextHandler)
    return instance
end

function TextHandler:getSelectedText()
    print("🤖 Getting selected text...")
    
    -- Try accessibility API first (fastest, most reliable)
    local accessibilityText = self:getSelectedTextViaAccessibility()
    if accessibilityText and accessibilityText ~= "" then
        print("🤖 Accessibility API returned: " .. accessibilityText:sub(1, 50) .. (accessibilityText:len() > 50 and "..." or ""))
        return self:cleanAndValidateText(accessibilityText)
    end
    
    print("🤖 Accessibility API failed, trying clipboard method...")
    -- Fallback to clipboard method if accessibility doesn't work
    local clipboardText = self:getSelectedTextViaClipboard()
    print("🤖 Clipboard method returned: " .. (clipboardText or "nil"):sub(1, 50) .. (((clipboardText or ""):len() > 50) and "..." or ""))
    return clipboardText
end

function TextHandler:getSelectedTextViaAccessibility()
    print("🤖 Trying accessibility API...")
    
    -- Get the frontmost application
    local app = hs.application.frontmostApplication()
    if not app then
        print("🤖 No frontmost application")
        return ""
    end
    
    print("🤖 Frontmost app: " .. app:name())
    
    -- Try to get the focused UI element using accessibility
    local axApp = hs.axuielement.applicationElement(app)
    if not axApp then
        print("🤖 No accessibility app element")
        return ""
    end
    
    -- Get the focused element
    local focusedAXElement = axApp:attributeValue("AXFocusedUIElement")
    if not focusedAXElement then
        print("🤖 No focused accessibility element")
        return ""
    end
    
    -- Try to get selected text directly
    local selectedText = focusedAXElement:attributeValue("AXSelectedText")
    if selectedText and selectedText ~= "" then
        print("🤖 Found selected text via AXSelectedText: " .. selectedText:sub(1, 50) .. "...")
        return selectedText
    end
    
    -- If no selected text, try to get value and selection range
    local value = focusedAXElement:attributeValue("AXValue")
    local selectedRange = focusedAXElement:attributeValue("AXSelectedTextRange")
    
    if value and selectedRange and selectedRange.length > 0 then
        local startPos = selectedRange.location + 1  -- Lua is 1-indexed
        local endPos = startPos + selectedRange.length - 1
        local rangeText = value:sub(startPos, endPos)
        print("🤖 Found selected text via range: " .. rangeText:sub(1, 50) .. "...")
        return rangeText
    end
    
    print("🤖 No selected text found via accessibility")
    return ""
end

function TextHandler:getSelectedTextViaClipboard()
    -- Store current clipboard content
    local originalClipboard = hs.pasteboard.getContents()
    
    -- Copy selected text to clipboard
    hs.eventtap.keyStroke({"cmd"}, "c")
    
    -- Small delay to ensure clipboard is updated
    hs.timer.usleep(100000)  -- 100ms
    
    -- Get the new clipboard content
    local newClipboard = hs.pasteboard.getContents()
    
    -- Restore original clipboard after a short delay
    if originalClipboard then
        hs.timer.doAfter(0.1, function()
            hs.pasteboard.setContents(originalClipboard)
        end)
    end
    
    -- Return the selected text if it's different from original
    if newClipboard and newClipboard ~= originalClipboard then
        return self:cleanAndValidateText(newClipboard)
    end
    
    return ""
end

function TextHandler:cleanAndValidateText(text)
    if not text or type(text) ~= "string" then
        return ""
    end
    
    -- Remove null bytes and control characters (except newlines, tabs, carriage returns)
    text = text:gsub("[\000-\008\011\012\014-\031\127]", "")
    
    -- Normalize line endings to Unix style
    text = text:gsub("\r\n", "\n")
    text = text:gsub("\r", "\n")
    
    -- Remove excessive whitespace while preserving intentional spacing
    text = text:gsub("[ \t]+", " ")  -- Multiple spaces/tabs to single space
    text = text:gsub("\n[ \t]+", "\n")  -- Remove leading whitespace on lines
    text = text:gsub("[ \t]+\n", "\n")  -- Remove trailing whitespace on lines
    text = text:gsub("\n\n\n+", "\n\n")  -- Multiple blank lines to double newline
    
    -- Trim leading and trailing whitespace
    text = text:match("^%s*(.-)%s*$") or ""
    
    -- Validate text length (warn if too long)
    if #text > 50000 then
        print("🤖 Warning: Text is very long (" .. #text .. " chars), might cause processing issues")
    end
    
    return text
end

function TextHandler:getClipboard()
    local clipboardContent = hs.pasteboard.getContents() or ""
    return self:cleanAndValidateText(clipboardContent)
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