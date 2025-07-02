-- UI Manager Module
-- Handles user interface components and interactions

local UIManager = {}
UIManager.__index = UIManager

function UIManager:new()
    local instance = setmetatable({}, UIManager)
    instance.chooser = nil
    instance.progressAlert = nil
    return instance
end

function UIManager:showOperationChooser(operations, callback)
    -- Always create a new chooser to avoid callback issues
    if self.chooser then
        self.chooser:delete()
    end
    
    self.chooser = hs.chooser.new(callback)
    
    -- Configure chooser appearance
    self.chooser:bgDark(true)
    self.chooser:fgColor({["red"]=1,["blue"]=1,["green"]=1,["alpha"]=1})
    self.chooser:subTextColor({["red"]=0.7,["blue"]=0.7,["green"]=0.7,["alpha"]=1})
    
    -- Set width and rows
    self.chooser:width(20)
    self.chooser:rows(8)
    
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

function UIManager:showResult(result)
    -- Copy to clipboard for convenience
    hs.pasteboard.setContents(result or "")
    print("🤖 AI Result: " .. (result or "No result"))
    
    -- Show result in configurable dialog
    self:showResultDialog(result or "No result")
end

function UIManager:showResultDialog(text)
    -- Get UI configuration
    local uiConfig = self:getUIConfig()
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
                    line-height: 1.7;
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
    
    -- Set up global hotkey to close
    if self.closeDialogHotkey then
        self.closeDialogHotkey:delete()
    end
    
    self.closeDialogHotkey = hs.hotkey.bind({}, "escape", function()
        if self.currentDialog then
            self.currentDialog:delete()
            self.currentDialog = nil
            if self.closeDialogHotkey then
                self.closeDialogHotkey:delete()
                self.closeDialogHotkey = nil
            end
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

return UIManager