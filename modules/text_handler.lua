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
    
    -- For efficiency, try clipboard method first for known problematic apps
    local app = hs.application.frontmostApplication()
    if app then
        local appName = app:name()
        local skipAccessibility = (appName == "Code" or appName == "Visual Studio Code" or 
                                 appName == "Terminal" or appName == "iTerm2" or
                                 appName == "Sublime Text" or appName == "Atom" or
                                 appName == "Arc" or appName == "Google Chrome" or
                                 appName == "Firefox" or appName == "Safari")
        
        if skipAccessibility then
            print("🤖 App " .. appName .. " - using clipboard method directly")
            local clipboardText = self:getSelectedTextViaClipboard()
            if clipboardText and clipboardText ~= "" then
                print("🤖 Clipboard method returned: " .. clipboardText:sub(1, 50) .. (clipboardText:len() > 50 and "..." or ""))
                return clipboardText
            end
        end
    end
    
    -- Try accessibility API for other apps
    local accessibilityText = self:getSelectedTextViaAccessibility()
    if accessibilityText and accessibilityText ~= "" then
        print("🤖 Accessibility API returned: " .. accessibilityText:sub(1, 50) .. (accessibilityText:len() > 50 and "..." or ""))
        return self:cleanAndValidateText(accessibilityText)
    end
    
    print("🤖 Accessibility API failed, trying clipboard method...")
    -- Fallback to clipboard method if accessibility doesn't work
    local clipboardText = self:getSelectedTextViaClipboard()
    if clipboardText and clipboardText ~= "" then
        print("🤖 Clipboard method returned: " .. clipboardText:sub(1, 50) .. (clipboardText:len() > 50 and "..." or ""))
        return clipboardText
    end
    
    print("🤖 Clipboard method failed, trying AppleScript method...")
    -- Try AppleScript as another fallback
    local appleScriptText = self:getSelectedTextViaAppleScript()
    if appleScriptText and appleScriptText ~= "" then
        return appleScriptText
    end
    
    print("🤖 No selected text found, falling back to current clipboard content...")
    -- Final fallback: return current clipboard content
    local fallbackText = self:getClipboard()
    print("🤖 Fallback clipboard content: " .. (fallbackText or "nil"):sub(1, 50) .. (((fallbackText or ""):len() > 50) and "..." or ""))
    return fallbackText
end

function TextHandler:getSelectedTextViaAccessibility()
    print("🤖 Trying accessibility API...")
    
    -- Get the frontmost application
    local app = hs.application.frontmostApplication()
    if not app then
        print("🤖 No frontmost application")
        return ""
    end
    
    local appName = app:name()
    print("🤖 Frontmost app: " .. appName)
    
    -- Check if this app is known to have accessibility issues
    local problematicApps = {
        ["Code"] = "VS Code",
        ["Visual Studio Code"] = "VS Code", 
        ["Sublime Text"] = "Text Editor",
        ["Atom"] = "Text Editor",
        ["Terminal"] = "Terminal App",
        ["iTerm2"] = "Terminal App",
        ["Arc"] = "Browser",
        ["Google Chrome"] = "Browser",
        ["Firefox"] = "Browser",
        ["Safari"] = "Browser"
    }
    
    if problematicApps[appName] then
        print("🤖 ⚠️  " .. appName .. " has known accessibility limitations (" .. problematicApps[appName] .. ")")
        print("🤖 Skipping accessibility API, will use clipboard method")
        return ""
    end
    
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
    
    -- Debug: Show element info
    local elementRole = focusedAXElement:attributeValue("AXRole")
    local elementSubrole = focusedAXElement:attributeValue("AXSubrole")
    local elementDescription = focusedAXElement:attributeValue("AXDescription")
    print("🤖 Focused element: " .. (elementRole or "unknown") .. " / " .. (elementSubrole or "none"))
    if elementDescription then
        print("🤖 Element description: " .. elementDescription:sub(1, 50) .. "...")
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
    
    -- Debug: Show what we found
    print("🤖 Element value length: " .. (value and #value or "nil"))
    print("🤖 Selection range: " .. (selectedRange and ("loc=" .. selectedRange.location .. " len=" .. selectedRange.length) or "nil"))
    
    -- For problematic elements, give up early
    if not value or #value == 0 then
        print("🤖 Element has no text content - accessibility not supported")
        return ""
    end
    
    if value and selectedRange and selectedRange.length > 0 then
        local startPos = selectedRange.location + 1  -- Lua is 1-indexed
        local endPos = startPos + selectedRange.length - 1
        
        -- Safety check for range bounds
        if startPos > 0 and endPos <= #value and startPos <= endPos then
            local rangeText = value:sub(startPos, endPos)
            print("🤖 Found selected text via range: " .. rangeText:sub(1, 50) .. "...")
            return rangeText
        else
            print("🤖 Invalid range bounds: start=" .. startPos .. " end=" .. endPos .. " valueLen=" .. #value)
        end
    end
    
    print("🤖 No selected text found via accessibility")
    return ""
end

function TextHandler:getSelectedTextViaClipboard()
    print("🤖 Trying clipboard method...")
    
    -- Store current clipboard content
    local originalClipboard = hs.pasteboard.getContents()
    print("🤖 Original clipboard: " .. (originalClipboard or "nil"):sub(1, 50) .. (((originalClipboard or ""):len() > 50) and "..." or ""))
    
    -- For browsers and complex apps, try a different approach
    local app = hs.application.frontmostApplication()
    local isBrowser = app and (app:name() == "Arc" or app:name() == "Safari" or 
                               app:name() == "Google Chrome" or app:name() == "Firefox")
    
    if isBrowser then
        print("🤖 Using browser-optimized clipboard method")
        
        -- For browsers, give more time and try multiple attempts
        local attempts = 0
        local maxAttempts = 3
        
        while attempts < maxAttempts do
            attempts = attempts + 1
            print("🤖 Attempt " .. attempts .. "/" .. maxAttempts)
            
            -- Set unique marker
            local tempMarker = "~~TEMP_MARKER_" .. os.time() .. "_" .. attempts .. "~~"
            hs.pasteboard.setContents(tempMarker)
            
            -- Longer delay for browsers
            hs.timer.usleep(150000)  -- 150ms
            
            -- Copy selected text
            hs.eventtap.keyStroke({"cmd"}, "c")
            
            -- Longer wait for browser response
            hs.timer.usleep(200000)  -- 200ms
            
            local newClipboard = hs.pasteboard.getContents()
            
            if newClipboard and newClipboard ~= tempMarker and newClipboard ~= originalClipboard then
                local selectedText = self:cleanAndValidateText(newClipboard)
                print("🤖 Browser clipboard method succeeded on attempt " .. attempts)
                print("🤖 Result: " .. selectedText:sub(1, 50) .. (selectedText:len() > 50 and "..." or ""))
                
                -- Restore original clipboard
                if originalClipboard then
                    hs.pasteboard.setContents(originalClipboard)
                end
                
                return selectedText
            end
            
            print("🤖 Attempt " .. attempts .. " failed, clipboard: " .. (newClipboard or "nil"):sub(1, 30) .. "...")
        end
        
        print("🤖 All browser attempts failed")
        
        -- Restore original clipboard
        if originalClipboard then
            hs.pasteboard.setContents(originalClipboard)
        end
        
        return ""
    else
        -- Original method for non-browsers
        local tempMarker = "~~TEMP_MARKER_" .. os.time() .. "~~"
        hs.pasteboard.setContents(tempMarker)
        
        -- Small delay to ensure clipboard is set
        hs.timer.usleep(50000)  -- 50ms
        
        -- Copy selected text to clipboard
        print("🤖 Sending Cmd+C...")
        hs.eventtap.keyStroke({"cmd"}, "c")
        
        -- Small delay to ensure clipboard is updated
        hs.timer.usleep(100000)  -- 100ms
        
        -- Get the new clipboard content
        local newClipboard = hs.pasteboard.getContents()
        print("🤖 New clipboard: " .. (newClipboard or "nil"):sub(1, 50) .. (((newClipboard or ""):len() > 50) and "..." or ""))
        
        -- Check if clipboard changed from our temp marker
        local clipboardChanged = (newClipboard ~= tempMarker)
        print("🤖 Clipboard changed from temp marker: " .. tostring(clipboardChanged))
        
        local selectedText = ""
        
        if clipboardChanged and newClipboard then
            -- Text was selected and copied
            selectedText = self:cleanAndValidateText(newClipboard)
            print("🤖 Clipboard method result: " .. selectedText:sub(1, 50) .. (selectedText:len() > 50 and "..." or ""))
        else
            print("🤖 No text selection detected via clipboard")
        end
        
        -- Restore original clipboard immediately
        if originalClipboard then
            hs.pasteboard.setContents(originalClipboard)
        end
        
        return selectedText
    end
end

function TextHandler:getSelectedTextViaAppleScript()
    print("🤖 Trying AppleScript method...")
    
    -- Store current clipboard
    local originalClipboard = hs.pasteboard.getContents()
    
    -- AppleScript to copy selected text
    local script = [[
        tell application "System Events"
            keystroke "c" using command down
            delay 0.1
        end tell
        return the clipboard as string
    ]]
    
    local success, result = hs.osascript.applescript(script)
    
    if success and result and result ~= originalClipboard then
        -- Restore original clipboard
        if originalClipboard then
            hs.timer.doAfter(0.1, function()
                hs.pasteboard.setContents(originalClipboard)
            end)
        end
        
        local cleanText = self:cleanAndValidateText(result)
        print("🤖 AppleScript method result: " .. cleanText:sub(1, 50) .. (cleanText:len() > 50 and "..." or ""))
        return cleanText
    end
    
    print("🤖 AppleScript method failed")
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
    
    -- Clean whitespace more conservatively to preserve formatting
    text = text:gsub("[ \t]+", " ")  -- Multiple spaces/tabs to single space
    text = text:gsub("\n[ \t]+", "\n")  -- Remove leading whitespace on lines
    text = text:gsub("[ \t]+\n", "\n")  -- Remove trailing whitespace on lines
    
    -- Only reduce excessive blank lines (4 or more) to double newlines
    text = text:gsub("\n\n\n\n+", "\n\n")
    
    -- Trim leading and trailing whitespace, but preserve internal structure
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

function TextHandler:replaceSelectedText(text, originalFocusContext)
    -- Use the stored original focus context if provided, otherwise get current
    local originalApp, originalWindow, originalAppName
    if originalFocusContext and originalFocusContext.app then
        originalApp = originalFocusContext.app
        originalWindow = originalFocusContext.window
        originalAppName = originalFocusContext.appName
        print("🤖 Using stored focus context: " .. originalAppName)
    else
        originalApp = hs.application.frontmostApplication()
        originalWindow = nil
        if originalApp then
            originalWindow = originalApp:focusedWindow()
            originalAppName = originalApp:name()
        end
        print("🤖 Using current focus context: " .. (originalAppName or "Unknown"))
    end
    
    -- First copy the replacement text to clipboard
    local originalClipboard = hs.pasteboard.getContents()
    hs.pasteboard.setContents(text)
    
    -- Small delay to ensure clipboard is set
    hs.timer.usleep(50000)  -- 50ms
    
    -- Always try to restore focus to the original app/window
    if originalApp then
        local currentApp = hs.application.frontmostApplication()
        local needsRestore = false
        
        if not currentApp then
            needsRestore = true
        elseif originalFocusContext and originalFocusContext.bundleID then
            -- Use stored bundle ID for more reliable comparison
            needsRestore = (currentApp:bundleID() ~= originalFocusContext.bundleID)
        else
            needsRestore = (currentApp:bundleID() ~= originalApp:bundleID())
        end
        
        if needsRestore then
            print("🤖 Focus changed, attempting to restore to: " .. originalAppName)
            
            -- Try to bring the original app to front
            local success = originalApp:activate()
            if success then
                hs.timer.usleep(200000)  -- 200ms for app activation
                
                -- Try to restore window focus
                if originalWindow then
                    local windowSuccess = originalWindow:focus()
                    if windowSuccess then
                        hs.timer.usleep(100000)  -- 100ms for window focus
                        print("🤖 ✓ Focus restored to: " .. originalAppName)
                    else
                        print("🤖 ⚠️ Failed to restore window focus")
                    end
                else
                    print("🤖 ⚠️ No original window to restore")
                end
            else
                print("🤖 ⚠️ Failed to restore app focus to: " .. originalAppName)
            end
        else
            print("🤖 Focus is already correct: " .. (currentApp and currentApp:name() or "Unknown"))
        end
    end
    
    -- Use AppleScript to paste the text
    local script = [[
        tell application "System Events"
            keystroke "v" using command down
        end tell
    ]]
    
    local success, result = hs.osascript.applescript(script)
    if not success then
        print("🤖 ⚠️ AppleScript paste failed, trying direct keystroke")
        -- Fallback to direct keystroke
        hs.eventtap.keyStroke({"cmd"}, "v")
    end
    
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