-- Integration tests for Ask AI Anywhere
-- Tests complete end-to-end workflows including text selection, processing, and UI

local function setup_integration_environment()
    -- Add the parent directory to the path
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Mock Hammerspoon environment more comprehensively
    hs = {
        application = {
            frontmostApplication = function()
                return {
                    name = function() return "TestApp" end,
                    focusedWindow = function() 
                        return {
                            title = function() return "Test Window" end
                        }
                    end
                }
            end
        },
        axuielement = {
            applicationElement = function(app)
                return {
                    attributeValue = function(self, attr)
                        if attr == "AXFocusedUIElement" then
                            return {
                                attributeValue = function(self, attr)
                                    if attr == "AXSelectedText" then
                                        return _test_selected_text or ""
                                    end
                                    return nil
                                end
                            }
                        end
                        return nil
                    end
                }
            end
        },
        pasteboard = {
            getContents = function()
                return _test_clipboard_content or ""
            end,
            setContents = function(content)
                _test_clipboard_content = content
            end
        },
        eventtap = {
            keyStroke = function(modifiers, key)
                _test_key_events = _test_key_events or {}
                table.insert(_test_key_events, {modifiers = modifiers, key = key})
            end,
            keyStrokes = function(text)
                _test_typed_text = text
            end
        },
        task = {
            new = function(shell, callback, args)
                return {
                    start = function(self)
                        -- Simulate LLM processing
                        local input = _test_llm_input or "default input"
                        local response = "Processed: " .. input
                        _test_llm_output = response
                        callback(0, response, "")
                    end,
                    isRunning = function(self) return false end,
                    terminate = function(self) end
                }
            end
        },
        timer = {
            usleep = function(ms) end,
            doAfter = function(delay, fn) fn() end
        },
        hotkey = {
            bind = function(modifiers, key, callback)
                _test_hotkey_callbacks = _test_hotkey_callbacks or {}
                local hotkeyId = table.concat(modifiers, "+") .. "+" .. key
                _test_hotkey_callbacks[hotkeyId] = callback
                return {
                    delete = function() end,
                    disable = function() end,
                    enable = function() end
                }
            end
        },
        alert = {
            show = function(message, duration)
                _test_alerts = _test_alerts or {}
                table.insert(_test_alerts, message)
            end
        },
        chooser = {
            new = function(callback)
                return {
                    choices = function(self, choices)
                        _test_chooser_choices = choices
                    end,
                    show = function(self)
                        _test_chooser_shown = true
                        -- Simulate user selection
                        if _test_chooser_selection and _test_chooser_choices then
                            for _, choice in ipairs(_test_chooser_choices) do
                                if choice.operation == _test_chooser_selection then
                                    callback(choice)
                                    break
                                end
                            end
                        end
                    end,
                    hide = function(self) end,
                    delete = function(self) end,
                    bgDark = function(self, dark) return self end,
                    fgColor = function(self, color) return self end,
                    subTextColor = function(self, color) return self end,
                    width = function(self, width) return self end,
                    rows = function(self, rows) return self end,
                    searchSubText = function(self, enable) return self end
                }
            end
        },
        webview = {
            new = function(rect, prefs, userContentController)
                return {
                    loadHTMLString = function(self, html, baseURL)
                        _test_webview_html = html
                    end,
                    show = function(self)
                        _test_webview_shown = true
                    end,
                    hide = function(self) end,
                    delete = function(self) end,
                    frame = function(self, rect)
                        if rect then
                            _test_webview_frame = rect
                        end
                        return _test_webview_frame or {x=0, y=0, w=400, h=300}
                    end,
                    html = function(self, html)
                        if html then
                            _test_webview_html = html
                        end
                        return _test_webview_html
                    end,
                    windowStyle = function(self, style) return self end,
                    windowTitle = function(self, title) return self end,
                    bringToFront = function(self) return self end,
                    windowCallback = function(self, callback) return self end,
                    closeOnEscape = function(self, enable) return self end,
                    allowGestures = function(self, enable) return self end,
                    allowNewWindows = function(self, enable) return self end,
                    allowTextEntry = function(self, enable) return self end,
                    transparent = function(self, enable) return self end,
                    level = function(self, level) return self end,
                    behavior = function(self, behavior) return self end,
                    userContentController = function(self, controller) return self end,
                    url = function(self, url) return self end,
                    reload = function(self) return self end,
                    evaluateJavaScript = function(self, js, callback) 
                        if callback then callback("", nil) end
                        return self 
                    end
                }
            end
        },
        logger = {
            setGlobalLogLevel = function(level) end,
            new = function(name, level)
                return {
                    setLogFile = function(self, file) end
                }
            end
        },
        menubar = {
            new = function()
                return {
                    setTitle = function(self, title) end,
                    setMenu = function(self, menu) end,
                    delete = function(self) end
                }
            end
        },
        screen = {
            mainScreen = function()
                return {
                    frame = function()
                        return {x=0, y=0, w=1920, h=1080}
                    end
                }
            end
        }
    }
    
    -- Initialize test globals
    _test_selected_text = ""
    _test_clipboard_content = ""
    _test_key_events = {}
    _test_typed_text = ""
    _test_llm_input = ""
    _test_llm_output = ""
    _test_hotkey_callbacks = {}
    _test_alerts = {}
    _test_chooser_choices = {}
    _test_chooser_shown = false
    _test_chooser_selection = nil
    _test_webview_html = ""
    _test_webview_shown = false
    _test_webview_frame = nil
    
    -- Mock file operations
    _test_file_contents = {}
    local original_io_open = io.open
    io.open = function(filename, mode)
        if mode == "w" then
            return {
                write = function(self, content)
                    _test_file_contents[filename] = content
                    return true  -- Return success
                end,
                close = function(self) end
            }
        elseif mode == "r" then
            local content = _test_file_contents[filename]
            if content then
                return {
                    read = function(self, format)
                        if format == "*all" then
                            return content
                        end
                        return content
                    end,
                    close = function(self) end
                }
            end
        elseif mode == "a" then
            return {
                write = function(self, content)
                    _test_file_contents[filename] = (_test_file_contents[filename] or "") .. content
                    return true  -- Return success
                end,
                close = function(self) end
            }
        end
        return original_io_open(filename, mode)
    end
    
    -- Mock os.remove
    local original_os_remove = os.remove
    os.remove = function(filename)
        _test_file_contents[filename] = nil
        return true
    end
    
    return {
        restore = function()
            io.open = original_io_open
            os.remove = original_os_remove
        end
    }
end

local function create_test_config()
    -- Create a test configuration
    local config = {
        llm = {
            defaultProvider = "test-provider",
            fallbackProvider = "test-fallback",
            providers = {
                ["test-provider"] = {
                    enabled = true,
                    command = "test-llm",
                    args = {"--test"},
                    timeout = 30
                },
                ["test-fallback"] = {
                    enabled = true,
                    command = "fallback-llm",
                    args = {},
                    timeout = 30
                }
            }
        },
        hotkeys = {
            {
                name = "test-translate",
                key = "t",
                modifiers = {"cmd", "ctrl"},
                actions = {
                    {name = "runPrompt", args = {prompt = "translate_chinese"}},
                    {name = "displayText", args = {text = "${output}", ui = "default"}}
                }
            },
            {
                name = "test-menu",
                key = "m",
                modifiers = {"cmd", "ctrl"},
                actions = {
                    {name = "showMainMenu", args = {}}
                }
            }
        },
        prompts = {
            translate_chinese = {
                title = "Translate to Chinese",
                description = "Translate text to Chinese",
                template = "Please translate the following text to Chinese: ${selected_text}"
            },
            improve_writing = {
                title = "Improve Writing",
                description = "Improve the writing quality",
                template = "Please improve the following text: ${selected_text}"
            }
        },
        ui = {
            default = {
                outputMethod = "display",
                showProgress = true,
                menuWidth = 400,
                menuRows = 8
            }
        },
        environment = {
            paths = {"/usr/local/bin", "/opt/homebrew/bin"}
        }
    }
    
    return {
        get = function(self, key)
            local keys = {}
            for k in key:gmatch("[^%.]+") do
                table.insert(keys, k)
            end
            
            local value = config
            for _, k in ipairs(keys) do
                if type(value) == "table" and value[k] then
                    value = value[k]
                else
                    return nil
                end
            end
            return value
        end,
        getHotkeysArray = function(self)
            return config.hotkeys
        end,
        getProviderConfig = function(self, provider)
            return config.llm.providers[provider]
        end,
        getDefaultProvider = function(self)
            return config.llm.defaultProvider
        end,
        getFallbackProvider = function(self)
            return config.llm.fallbackProvider
        end,
        getLLMConfig = function(self)
            return config.llm
        end,
        load = function(self) end
    }
end

local function test_text_selection_workflow()
    print("Testing text selection workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test text
    _test_selected_text = "This is a test document for translation."
    
    -- Load modules
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test text selection
    local selectedText = handler:getSelectedText()
    
    env.restore()
    
    if selectedText == "This is a test document for translation." then
        print("✓ Text selection workflow works correctly")
        return true
    else
        print("✗ Text selection workflow failed")
        print("  Expected: This is a test document for translation.")
        print("  Got: " .. tostring(selectedText))
        return false
    end
end

local function test_llm_processing_workflow()
    print("Testing LLM processing workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test input
    _test_llm_input = "Test input for LLM processing"
    
    -- Load modules
    local llmClient = require('llm_client')
    local client = llmClient:new(config)
    
    -- Test LLM execution
    local result = nil
    local error = nil
    
    client:execute("test-provider", "Test prompt", function(res, err)
        result = res
        error = err
    end)
    
    env.restore()
    
    if result and result:match("Processed:") then
        print("✓ LLM processing workflow works correctly")
        return true
    else
        print("✗ LLM processing workflow failed")
        print("  Result: " .. tostring(result))
        print("  Error: " .. tostring(error))
        return false
    end
end

local function test_hotkey_execution_workflow()
    print("Testing hotkey execution workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test environment
    _test_selected_text = "Test text for hotkey processing"
    
    -- Load modules
    local hotkeyManager = require('hotkey_manager')
    local actionRegistry = require('action_registry')
    local ExecutionContext = require('execution_context')
    local textHandler = require('text_handler')
    local llmClient = require('llm_client')
    local uiManager = require('ui_manager')
    
    -- Create components
    local components = {
        textHandler = textHandler:new(),
        llmClient = llmClient:new(config),
        uiManager = uiManager:new(),
        actionRegistry = actionRegistry:new()
    }
    
    local manager = hotkeyManager:new()
    
    -- Create execution context callback
    local createContextCallback = function()
        return ExecutionContext:new(nil, config, components)
    end
    
    -- Bind hotkeys
    local hotkeyArray = config:getHotkeysArray()
    local results = manager:bindActionHotkeys(hotkeyArray, components.actionRegistry, createContextCallback)
    
    -- Test hotkey trigger
    local hotkeyId = "cmd+ctrl+t"
    if _test_hotkey_callbacks[hotkeyId] then
        _test_hotkey_callbacks[hotkeyId]()
    end
    
    env.restore()
    
    -- Check if hotkey was bound successfully
    if results["test-translate"] and results["test-translate"].success then
        print("✓ Hotkey execution workflow works correctly")
        return true
    else
        print("✗ Hotkey execution workflow failed")
        if results["test-translate"] then
            print("  Result: " .. tostring(results["test-translate"].success))
            print("  Message: " .. tostring(results["test-translate"].message))
        end
        return false
    end
end

local function test_action_execution_workflow()
    print("Testing action execution workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test environment
    _test_selected_text = "Test text for action execution"
    
    -- Load modules
    local actionRegistry = require('action_registry')
    local ExecutionContext = require('execution_context')
    local textHandler = require('text_handler')
    local llmClient = require('llm_client')
    local uiManager = require('ui_manager')
    
    -- Create components
    local components = {
        textHandler = textHandler:new(),
        llmClient = llmClient:new(config),
        uiManager = uiManager:new(),
        actionRegistry = actionRegistry:new()
    }
    
    -- Create execution context
    local context = ExecutionContext:new("Test input text", config, components)
    
    -- Test action execution
    local actions = {
        {name = "copyToClipboard", args = {text = "${selected_text}"}},
        {name = "showNotification", args = {message = "Test notification"}}
    }
    
    local success = pcall(context.executeActions, context, actions)
    
    env.restore()
    
    if success and _test_clipboard_content == "Test input text" then
        print("✓ Action execution workflow works correctly")
        return true
    else
        print("✗ Action execution workflow failed")
        print("  Success: " .. tostring(success))
        print("  Clipboard: " .. tostring(_test_clipboard_content))
        return false
    end
end

local function test_ui_interaction_workflow()
    print("Testing UI interaction workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test environment
    _test_chooser_selection = "translate_chinese"
    
    -- Load modules
    local uiManager = require('ui_manager')
    local manager = uiManager:new()
    
    -- Test operation chooser
    local operations = {
        {
            operation = "translate_chinese",
            title = "Translate to Chinese",
            description = "Translate text to Chinese",
            text = "Translate to Chinese",
            subText = "Translate text to Chinese"
        },
        {
            operation = "improve_writing",
            title = "Improve Writing",
            description = "Improve writing quality",
            text = "Improve Writing",
            subText = "Improve writing quality"
        }
    }
    
    local selectedOperation = nil
    manager:showOperationChooser(operations, function(choice)
        selectedOperation = choice
    end)
    
    -- Test result display
    manager:showResult("Test result content")
    
    env.restore()
    
    if _test_chooser_shown and selectedOperation and selectedOperation.operation == "translate_chinese" and _test_webview_shown then
        print("✓ UI interaction workflow works correctly")
        return true
    else
        print("✗ UI interaction workflow failed")
        print("  Chooser shown: " .. tostring(_test_chooser_shown))
        print("  Selected operation: " .. tostring(selectedOperation and selectedOperation.operation))
        print("  Webview shown: " .. tostring(_test_webview_shown))
        return false
    end
end

local function test_error_handling_workflow()
    print("Testing error handling workflow...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Test invalid provider
    local llmClient = require('llm_client')
    local client = llmClient:new(config)
    
    local errorReceived = false
    client:execute("invalid-provider", "Test prompt", function(result, error)
        if error then
            errorReceived = true
        end
    end)
    
    -- Test execution context with invalid actions
    local ExecutionContext = require('execution_context')
    local textHandler = require('text_handler')
    local uiManager = require('ui_manager')
    local actionRegistry = require('action_registry')
    
    local components = {
        textHandler = textHandler:new(),
        llmClient = client,
        uiManager = uiManager:new(),
        actionRegistry = actionRegistry:new()
    }
    
    local context = ExecutionContext:new("Test input", config, components)
    
    -- Test invalid action
    local actions = {
        {name = "invalid-action", args = {}}
    }
    
    local success, error = pcall(context.executeActions, context, actions)
    
    env.restore()
    
    if errorReceived and not success then
        print("✓ Error handling workflow works correctly")
        return true
    else
        print("✗ Error handling workflow failed")
        print("  Error received: " .. tostring(errorReceived))
        print("  Action execution success: " .. tostring(success))
        print("  Error: " .. tostring(error))
        return false
    end
end

local function test_full_translation_workflow()
    print("Testing full translation workflow (end-to-end)...")
    
    local env = setup_integration_environment()
    local config = create_test_config()
    
    -- Set up test environment for full workflow
    _test_selected_text = "Hello, this is a test document that needs translation."
    
    -- Load all modules
    local textHandler = require('text_handler')
    local llmClient = require('llm_client')
    local uiManager = require('ui_manager')
    local actionRegistry = require('action_registry')
    local ExecutionContext = require('execution_context')
    
    -- Create components
    local components = {
        textHandler = textHandler:new(),
        llmClient = llmClient:new(config),
        uiManager = uiManager:new(),
        actionRegistry = actionRegistry:new()
    }
    
    -- Create execution context
    local context = ExecutionContext:new(nil, config, components)
    
    -- Execute translation workflow
    local actions = {
        {name = "runPrompt", args = {prompt = "translate_chinese"}},
        {name = "displayText", args = {text = "${output}", ui = "default"}},
        {name = "copyToClipboard", args = {text = "${output}"}}
    }
    
    local success = pcall(context.executeActions, context, actions)
    
    env.restore()
    
    -- Check workflow completed successfully
    if success and _test_llm_output and _test_webview_shown and _test_clipboard_content then
        print("✓ Full translation workflow works correctly")
        print("  Input processed: " .. tostring(_test_selected_text))
        print("  LLM output: " .. tostring(_test_llm_output))
        print("  UI displayed: " .. tostring(_test_webview_shown))
        print("  Clipboard updated: " .. tostring(_test_clipboard_content ~= ""))
        return true
    else
        print("✗ Full translation workflow failed")
        print("  Success: " .. tostring(success))
        print("  LLM output: " .. tostring(_test_llm_output))
        print("  Webview shown: " .. tostring(_test_webview_shown))
        print("  Clipboard content: " .. tostring(_test_clipboard_content))
        return false
    end
end

local function run_integration_tests()
    print("Running Ask AI Anywhere Integration Tests...")
    print("=" .. string.rep("=", 50))
    
    local tests = {
        test_text_selection_workflow,
        test_llm_processing_workflow,
        test_hotkey_execution_workflow,
        test_action_execution_workflow,
        test_ui_interaction_workflow,
        test_error_handling_workflow,
        test_full_translation_workflow
    }
    
    local passed = 0
    local total = #tests
    
    for i, test_func in ipairs(tests) do
        print("")
        local success = test_func()
        if success then
            passed = passed + 1
        end
    end
    
    print("")
    print("=" .. string.rep("=", 50))
    print(string.format("Integration tests: %d/%d passed", passed, total))
    
    if passed == total then
        print("🎉 All integration tests passed!")
        print("The Ask AI Anywhere system is working correctly end-to-end.")
    else
        print("❌ Some integration tests failed")
        print("Please review the test output and fix any issues.")
    end
    
    return passed == total
end

return {
    run_integration_tests = run_integration_tests,
    test_text_selection_workflow = test_text_selection_workflow,
    test_llm_processing_workflow = test_llm_processing_workflow,
    test_hotkey_execution_workflow = test_hotkey_execution_workflow,
    test_action_execution_workflow = test_action_execution_workflow,
    test_ui_interaction_workflow = test_ui_interaction_workflow,
    test_error_handling_workflow = test_error_handling_workflow,
    test_full_translation_workflow = test_full_translation_workflow
}