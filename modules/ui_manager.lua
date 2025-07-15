-- UI Manager Module
-- Handles user interface components and interactions

local UIManager = {}
UIManager.__index = UIManager

function UIManager:new()
    local instance = setmetatable({}, UIManager)
    instance.chooser = nil
    instance.progressAlert = nil
    instance.currentDialog = nil
    instance.closeDialogHotkey = nil
    instance.resultChooser = nil
    return instance
end

function UIManager:showOperationChooser(operations, callback, uiName)
    uiName = uiName or "menu"
    
    -- Get UI configuration
    local uiConfig = self:getUIConfigByName(uiName)
    
    -- Always create a new chooser to avoid callback issues
    if self.chooser then
        self.chooser:delete()
    end
    
    self.chooser = hs.chooser.new(callback)
    
    -- Configure chooser appearance
    self.chooser:bgDark(true)
    self.chooser:fgColor({["red"]=1,["blue"]=1,["green"]=1,["alpha"]=1})
    self.chooser:subTextColor({["red"]=0.7,["blue"]=0.7,["green"]=0.7,["alpha"]=1})
    
    -- Set width and rows from UI config
    local menuWidth = uiConfig.menuWidth or 400
    local menuRows = uiConfig.menuRows or 8
    
    self.chooser:width(menuWidth / 20)  -- Hammerspoon uses character width units
    self.chooser:rows(menuRows)
    
    -- Add search functionality
    self.chooser:searchSubText(true)
    
    -- Set choices and show
    self.chooser:choices(operations)
    self.chooser:show()
end

function UIManager:hideOperationChooser()
    if self.chooser then
        self.chooser:hide()
    end
end

function UIManager:showProgress(message)
    if self.progressAlert then
        self.progressAlert:closeAlert()
    end
    
    self.progressAlert = hs.alert.show(message, {
        textColor = {white = 1},
        fillColor = {white = 0.05, alpha = 0.95},
        strokeColor = {white = 0.25},
        strokeWidth = 2,
        radius = 8,
        atScreenEdge = 0,
        fadeInDuration = 0.15,
        fadeOutDuration = 0.15,
    }, "indefinite")
end

function UIManager:hideProgress()
    if self.progressAlert then
        hs.alert.closeSpecific(self.progressAlert)
        self.progressAlert = nil
    end
end

function UIManager:showResult(result, uiName)
    uiName = uiName or "default"
    
    -- Get UI configuration
    local uiConfig = self:getUIConfigByName(uiName)
    local outputMethod = uiConfig.outputMethod or "display"
    
    print("🤖 AI Result (" .. outputMethod .. "): " .. (result or "No result"))
    
    if outputMethod == "display" then
        -- Copy to clipboard for convenience
        hs.pasteboard.setContents(result or "")
        -- Show result in configurable dialog
        self:showResultDialog(result or "No result", uiConfig)
    elseif outputMethod == "clipboard" then
        -- Just copy to clipboard
        hs.pasteboard.setContents(result or "")
        if uiConfig.showNotifications ~= false then
            hs.alert.show("Result copied to clipboard")
        end
    elseif outputMethod == "chooser" then
        -- Show in chooser format (useful for selection)
        self:showResultInChooser(result or "No result", uiConfig)
    end
end

function UIManager:showResultDialog(text, uiConfig)
    uiConfig = uiConfig or self:getUIConfigByName("default")
    local dialogConfig = uiConfig.resultDialog or {}
    
    local widthPercentage = dialogConfig.widthPercentage or 50
    local maxLines = dialogConfig.maxLines or 20
    local persistent = dialogConfig.persistent ~= false -- default true
    
    -- Calculate dialog size
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local dialogWidth = math.floor(screenFrame.w * widthPercentage / 100)
    
    -- Truncate text if too long
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    if #lines > maxLines then
        local truncatedLines = {}
        for i = 1, maxLines - 1 do
            table.insert(truncatedLines, lines[i])
        end
        table.insert(truncatedLines, "... (truncated, full result copied to clipboard)")
        text = table.concat(truncatedLines, "\n")
    end
    
    -- Create persistent dialog
    if persistent then
        self:showPersistentDialog(text, dialogWidth)
    else
        hs.alert.show(text, 10)
    end
end

function UIManager:showPersistentDialog(text, width)
    -- Close any existing dialog
    if self.currentDialog then
        self.currentDialog:delete()
    end
    
    -- Create a simple webview dialog
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    
    -- Calculate height based on text length (rough estimate)
    local lines = select(2, text:gsub('\n', '\n')) + 1
    local height = math.min(math.max(lines * 25 + 100, 200), screenFrame.h * 0.8)
    
    local dialogFrame = {
        x = (screenFrame.w - width) / 2,
        y = (screenFrame.h - height) / 2,
        w = width,
        h = height
    }
    
    self.currentDialog = hs.webview.new(dialogFrame)
    
    -- Simple HTML content
    local htmlContent = string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333;
                    margin: 20px;
                    background-color: #f8f9fa;
                }
                .container {
                    background-color: white;
                    border-radius: 8px;
                    padding: 20px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    height: calc(100vh - 40px);
                    display: flex;
                    flex-direction: column;
                }
                .header {
                    border-bottom: 1px solid #eee;
                    padding-bottom: 10px;
                    margin-bottom: 20px;
                    font-weight: 600;
                    color: #555;
                }
                .content {
                    flex: 1;
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    overflow-y: auto;
                    font-size: 16px;
                    line-height: 1.8;
                    max-height: 70vh;
                    padding: 10px 0;
                }
                .footer {
                    margin-top: 20px;
                    padding-top: 10px;
                    border-top: 1px solid #eee;
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">🤖 AI Result</div>
                <div class="content">%s</div>
                <div class="footer">
                    Press ESC to close • Result copied to clipboard
                </div>
            </div>
            
            <script>
                document.addEventListener('keydown', function(event) {
                    if (event.key === 'Escape') {
                        window.close();
                    }
                });
            </script>
        </body>
        </html>
    ]], self:escapeHtml(text))
    
    self.currentDialog:html(htmlContent)
    self.currentDialog:windowStyle({"titled", "closable"})
    self.currentDialog:windowTitle("Ask AI - Result")
    self.currentDialog:show()
    self.currentDialog:bringToFront()
    
    -- Set up ESCAPE hotkey with proper conflict avoidance
    if self.closeDialogHotkey then
        self.closeDialogHotkey:delete()
    end
    
    -- Create ESCAPE hotkey but keep it disabled initially
    self.closeDialogHotkey = hs.hotkey.bind({}, "escape", function()
        if self.currentDialog then
            print("🤖 Closing result dialog via ESCAPE key")
            self.currentDialog:delete()
            self.currentDialog = nil
            if self.closeDialogHotkey then
                self.closeDialogHotkey:delete()
                self.closeDialogHotkey = nil
            end
        end
    end)
    
    -- Helper functions for hotkey management
    local function enableEscapeHotkey()
        if self.closeDialogHotkey then
            self.closeDialogHotkey:enable()
            print("🤖 ESCAPE hotkey enabled for result dialog")
        end
    end
    
    local function disableEscapeHotkey()
        if self.closeDialogHotkey then
            self.closeDialogHotkey:disable()
            print("🤖 ESCAPE hotkey disabled for result dialog")
        end
    end
    
    -- Set up window callback for focus and close management
    self.currentDialog:windowCallback(function(action, webview, frame)
        if action == "closing" then
            print("🤖 Result dialog closing")
            disableEscapeHotkey()
            if self.closeDialogHotkey then
                self.closeDialogHotkey:delete()
                self.closeDialogHotkey = nil
            end
            self.currentDialog = nil
        elseif action == "focusChange" then
            -- Enable ESCAPE only when dialog has focus
            if webview:hswindow() and webview:hswindow():isFocused() then
                enableEscapeHotkey()
            else
                disableEscapeHotkey()
            end
        end
    end)
    
    -- Start with hotkey disabled
    disableEscapeHotkey()
    
    -- Enable after a brief delay to ensure dialog is ready
    hs.timer.doAfter(0.1, function()
        if self.currentDialog then
            enableEscapeHotkey()
        end
    end)
end

function UIManager:getUIConfig()
    -- Try to get UI config from parent's config manager
    if self.parent and self.parent.config then
        return self.parent.config:getUIConfig()
    end
    
    -- Fallback default
    return {
        resultDialog = {
            widthPercentage = 50,
            maxLines = 20,
            persistent = true
        }
    }
end

-- Get UI configuration by name (supports new multi-UI format)
function UIManager:getUIConfigByName(uiName)
    uiName = uiName or "default"
    
    if self.parent and self.parent.config then
        local allUIConfigs = self.parent.config:get("ui", {})
        
        -- Handle both array and object format
        if type(allUIConfigs) == "table" then
            -- Try object format first: ui.default, ui.minimal, etc.
            if allUIConfigs[uiName] then
                return allUIConfigs[uiName]
            end
            
            -- Try array format: find by name
            for _, uiConfig in ipairs(allUIConfigs) do
                if type(uiConfig) == "table" and uiConfig.name == uiName then
                    return uiConfig
                end
            end
            
            -- If single UI config (old format), return it for any name
            if allUIConfigs.outputMethod or allUIConfigs.resultDialog then
                return allUIConfigs
            end
        end
    end
    
    -- Fallback defaults based on UI name
    local defaults = {
        default = {
            outputMethod = "display",
            showProgress = true,
            menuWidth = 400,
            menuRows = 8,
            resultDialog = {
                widthPercentage = 50,
                maxLines = 20,
                persistent = true
            }
        },
        minimal = {
            outputMethod = "clipboard",
            showProgress = false,
            showNotifications = true
        },
        comparison = {
            outputMethod = "display",
            showProgress = true,
            resultDialog = {
                widthPercentage = 70,
                persistent = true,
                title = "Text Comparison",
                maxLines = 30
            }
        },
        menu = {
            outputMethod = "chooser",
            menuWidth = 500,
            menuRows = 10,
            showProgress = true
        }
    }
    
    return defaults[uiName] or defaults.default
end

function UIManager:createResultWindow(text)
    -- Create a webview to display the result
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Calculate window size (80% of screen width, 60% of screen height)
    local windowWidth = math.floor(frame.w * 0.8)
    local windowHeight = math.floor(frame.h * 0.6)
    local windowX = math.floor((frame.w - windowWidth) / 2)
    local windowY = math.floor((frame.h - windowHeight) / 2)
    
    local windowFrame = {
        x = windowX,
        y = windowY,
        w = windowWidth,
        h = windowHeight
    }
    
    -- Create webview
    local webview = hs.webview.new(windowFrame)
    
    -- HTML content with the result
    local htmlContent = string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #333;
                    margin: 20px;
                    background-color: #f8f9fa;
                }
                .container {
                    max-width: 100%%;
                    margin: 0 auto;
                    padding: 20px;
                    background-color: white;
                    border-radius: 8px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .result-text {
                    white-space: pre-wrap;
                    word-wrap: break-word;
                    font-size: 16px;
                    line-height: 1.7;
                }
                .header {
                    border-bottom: 1px solid #eee;
                    padding-bottom: 10px;
                    margin-bottom: 20px;
                    font-weight: 600;
                    color: #555;
                }
                .footer {
                    margin-top: 20px;
                    padding-top: 10px;
                    border-top: 1px solid #eee;
                    text-align: center;
                    color: #666;
                    font-size: 12px;
                }
                .copy-button {
                    background-color: #007AFF;
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 12px;
                    margin-right: 10px;
                }
                .copy-button:hover {
                    background-color: #0056CC;
                }
                .close-button {
                    background-color: #FF3B30;
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 12px;
                }
                .close-button:hover {
                    background-color: #CC2E24;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">AI Result</div>
                <div class="result-text">%s</div>
                <div class="footer">
                    <button class="copy-button" onclick="copyToClipboard()">Copy to Clipboard</button>
                    <button class="close-button" onclick="closeWindow()">Close</button>
                </div>
            </div>
            
            <script>
                function copyToClipboard() {
                    const text = document.querySelector('.result-text').textContent;
                    navigator.clipboard.writeText(text).then(function() {
                        const button = document.querySelector('.copy-button');
                        const originalText = button.textContent;
                        button.textContent = 'Copied!';
                        setTimeout(function() {
                            button.textContent = originalText;
                        }, 1000);
                    }).catch(function(err) {
                        console.error('Failed to copy text: ', err);
                    });
                }
                
                function closeWindow() {
                    // Close window using Hammerspoon (simplified)
                    window.close();
                }
                
                // Close on escape key
                document.addEventListener('keydown', function(event) {
                    if (event.key === 'Escape') {
                        closeWindow();
                    }
                });
            </script>
        </body>
        </html>
    ]], self:escapeHtml(text))
    
    -- Set up webview
    webview:html(htmlContent)
    webview:allowTextEntry(true)
    webview:windowStyle({"titled", "closable", "resizable"})
    webview:windowTitle("Ask AI - Result")
    
    -- Handle close action (simplified - no JavaScript callbacks)
    -- User can close with Escape key or close button
    
    -- Auto-focus and bring to front
    webview:bringToFront()
    
    return webview
end

function UIManager:escapeHtml(text)
    -- Escape HTML special characters
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    text = text:gsub('"', "&quot;")
    text = text:gsub("'", "&#39;")
    
    -- Convert literal \n to actual newlines (in case they come as escaped)
    text = text:gsub("\\n", "\n")
    
    -- Convert newlines to HTML line breaks
    text = text:gsub("\n", "<br>")
    
    return text
end

function UIManager:showError(message, title)
    title = title or "Error"
    
    hs.alert.show(title .. ": " .. message, {
        textColor = {white = 1},
        fillColor = {red = 0.8, alpha = 0.9},
        strokeColor = {red = 1},
        strokeWidth = 2,
        radius = 8,
    }, 3)
end

function UIManager:showSuccess(message, title)
    title = title or "Success"
    
    hs.alert.show(title .. ": " .. message, {
        textColor = {white = 1},
        fillColor = {green = 0.6, alpha = 0.9},
        strokeColor = {green = 0.8},
        strokeWidth = 2,
        radius = 8,
    }, 2)
end

function UIManager:showConfirmation(message, callback)
    -- Show a confirmation dialog using hs.dialog
    local result = hs.dialog.blockAlert(
        "Confirm Action",
        message,
        "Yes",
        "No"
    )
    
    callback(result == "Yes")
end

function UIManager:showTextInput(title, message, defaultText, callback)
    -- Show text input dialog
    local result = hs.dialog.textPrompt(title, message, defaultText or "", "OK", "Cancel")
    
    if result.buttonReturned == "OK" then
        callback(result.text)
    else
        callback(nil)
    end
end

function UIManager:showConfigurableTextInput(title, message, defaultText, callback, uiConfig)
    -- Extract input configuration
    local inputConfig = uiConfig.textInput or {}
    local widthPercentage = inputConfig.widthPercentage or 50
    local heightPercentage = inputConfig.heightPercentage or 25
    local multiline = inputConfig.multiline or true
    
    -- Get screen dimensions
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()
    local dialogWidth = math.floor(screenFrame.w * widthPercentage / 100)
    local dialogHeight = math.floor(screenFrame.h * heightPercentage / 100)
    
    -- Center the dialog
    local dialogFrame = {
        x = (screenFrame.w - dialogWidth) / 2,
        y = (screenFrame.h - dialogHeight) / 2,
        w = dialogWidth,
        h = dialogHeight
    }
    
    -- Create WebView for input dialog
    local inputDialog = hs.webview.new(dialogFrame)
    
    -- Generate HTML content
    local inputType = multiline and "textarea" or "input"
    local inputElement = multiline and 
        string.format('<textarea id="userInput" placeholder="%s" rows="8">%s</textarea>', 
                      message or "", defaultText or "") or
        string.format('<input type="text" id="userInput" placeholder="%s" value="%s" />', 
                      message or "", defaultText or "")
    
    local htmlContent = string.format([[
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 0;
                    padding: 20px;
                    background: #f5f5f5;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                    box-sizing: border-box;
                }
                .dialog-container {
                    background: white;
                    border-radius: 8px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
                    padding: 20px;
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                }
                .title {
                    font-size: 16px;
                    font-weight: 600;
                    margin-bottom: 10px;
                    color: #333;
                }
                .message {
                    font-size: 14px;
                    color: #666;
                    margin-bottom: 15px;
                }
                #userInput {
                    width: 100%%;
                    padding: 8px;
                    font-size: 14px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    box-sizing: border-box;
                    resize: vertical;
                    flex: 1;
                }
                .buttons {
                    display: flex;
                    gap: 10px;
                    justify-content: flex-end;
                    margin-top: 15px;
                }
                button {
                    padding: 8px 16px;
                    border: none;
                    border-radius: 4px;
                    font-size: 14px;
                    cursor: pointer;
                }
                .cancel {
                    background: #f0f0f0;
                    color: #333;
                }
                .ok {
                    background: #007AFF;
                    color: white;
                }
                button:hover {
                    opacity: 0.8;
                }
            </style>
        </head>
        <body>
            <div class="dialog-container">
                <div class="title">%s</div>
                <div class="message">%s</div>
                %s
                <div class="buttons">
                    <button class="cancel" onclick="handleCancel()">Cancel</button>
                    <button class="ok" onclick="handleSubmit()">OK</button>
                </div>
            </div>
            <script>
                function handleSubmit() {
                    const input = document.getElementById('userInput');
                    const value = input.value.trim();
                    if (value) {
                        window.location.href = 'askaisubmit://submit/' + encodeURIComponent(value);
                    } else {
                        window.location.href = 'askaisubmit://cancel';
                    }
                }
                
                function handleCancel() {
                    window.location.href = 'askaisubmit://cancel';
                }
                
                document.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
                        handleSubmit();
                    } else if (e.key === 'Escape') {
                        handleCancel();
                    }
                });
                
                // Focus the input
                document.getElementById('userInput').focus();
            </script>
        </body>
        </html>
    ]], title, message or "", inputElement)
    
    -- Set up the WebView
    inputDialog:html(htmlContent)
    inputDialog:allowGestures(true)
    inputDialog:windowStyle({"titled", "closable", "resizable"})
    inputDialog:closeOnEscape(true)
    inputDialog:windowTitle(title)
    
    -- Handle URL navigation for form submission
    inputDialog:navigationCallback(function(action, webview, navType, url)
        -- Handle nil URL (occurs during navigation events)
        if not url then
            return true
        end
        
        if url:match("^askaisubmit://") then
            local action = url:match("askaisubmit://([^/]+)")
            if action == "submit" then
                local value = url:match("askaisubmit://submit/(.+)")
                if value then
                    value = hs.http.urlDecode(value)
                    callback(value)
                else
                    callback(nil)
                end
            else
                callback(nil)
            end
            inputDialog:delete()
            return false
        end
        return true
    end)
    
    -- Handle window close
    inputDialog:windowCallback(function(action, webview, window)
        if action == "closing" then
            callback(nil)
        end
    end)
    
    -- Show the dialog
    inputDialog:show()
end

function UIManager:createMenuBar()
    -- Create a menu bar item for quick access
    local menubar = hs.menubar.new()
    
    if menubar then
        menubar:setTitle("🤖")
        menubar:setTooltip("Ask AI Anywhere")
        
        local menuItems = {
            {
                title = "Show Main Menu",
                fn = function() 
                    if self.parent and self.parent.showMainMenu then
                        self.parent:showMainMenu()
                    end
                end
            },
            {
                title = "-" -- Separator
            },
            {
                title = "Test Configuration",
                fn = function()
                    if self.parent and self.parent.testConfiguration then
                        self.parent:testConfiguration()
                    end
                end
            },
            {
                title = "Test Hotkeys",
                fn = function()
                    if self.parent and self.parent.testHotkeys then
                        self.parent:testHotkeys()
                    end
                end
            },
            {
                title = "Reload Configuration",
                fn = function()
                    if self.parent and self.parent.reloadConfiguration then
                        self.parent:reloadConfiguration()
                    end
                end
            }
        }
        
        menubar:setMenu(menuItems)
    end
    
    return menubar
end

function UIManager:setParent(parent)
    self.parent = parent
end

-- Cleanup method to properly dispose of UI resources
function UIManager:cleanup()
    print("🤖 Cleaning up UI Manager resources")
    
    -- Clean up choosers
    if self.chooser then
        self.chooser:delete()
        self.chooser = nil
    end
    
    if self.resultChooser then
        self.resultChooser:delete()
        self.resultChooser = nil
    end
    
    -- Clean up progress alert
    if self.progressAlert then
        hs.alert.closeSpecific(self.progressAlert)
        self.progressAlert = nil
    end
    
    -- Clean up current dialog and its hotkey
    if self.closeDialogHotkey then
        self.closeDialogHotkey:delete()
        self.closeDialogHotkey = nil
    end
    
    if self.currentDialog then
        self.currentDialog:delete()
        self.currentDialog = nil
    end
    
    print("🤖 UI Manager cleanup completed")
end

-- Show result in chooser format (for selection/browsing)
function UIManager:showResultInChooser(text, uiConfig)
    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, {
            text = line,
            subText = "Line " .. #lines + 1
        })
    end
    
    if #lines == 0 then
        lines = {{text = text, subText = "Result"}}
    end
    
    -- Create chooser for browsing result
    if self.resultChooser then
        self.resultChooser:delete()
    end
    
    self.resultChooser = hs.chooser.new(function(choice)
        if choice then
            hs.pasteboard.setContents(choice.text)
            hs.alert.show("Line copied to clipboard")
        end
    end)
    
    self.resultChooser:choices(lines)
    self.resultChooser:placeholderText("Browse result lines...")
    self.resultChooser:width((uiConfig.menuWidth or 500) / 20)
    self.resultChooser:rows(uiConfig.menuRows or 10)
    self.resultChooser:show()
end

return UIManager