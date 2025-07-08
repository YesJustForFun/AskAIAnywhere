-- Integration tests for full workflow
-- Tests the complete Ask AI workflow

local function run_integration_tests()
    print("Running Integration Tests...")
    print("=" .. string.rep("=", 50))
    
    -- Mock Hammerspoon environment
    hs = {
        configdir = "/tmp/test_ask_ai",
        json = {
            encode = function(obj)
                -- Simple JSON encoding for testing
                if type(obj) == "table" then
                    local result = "{"
                    local first = true
                    for k, v in pairs(obj) do
                        if not first then result = result .. "," end
                        first = false
                        result = result .. '"' .. k .. '":' .. (type(v) == "string" and '"' .. v .. '"' or tostring(v))
                    end
                    return result .. "}"
                end
                return tostring(obj)
            end,
            decode = function(str)
                -- Simple JSON decoding for testing
                return {
                    version = "1.0.0",
                    llm = {
                        defaultProvider = "claude",
                        providers = {
                            claude = {
                                command = "echo",
                                args = {"Mock Claude response"},
                                enabled = true,
                                timeout = 30
                            }
                        }
                    },
                    operations = {
                        improve_writing = {
                            title = "Improve Writing",
                            description = "Enhance text quality",
                            prompt = "Improve this text:"
                        }
                    },
                    hotkeys = {
                        mainMenu = {
                            key = "/",
                            modifiers = {"cmd", "shift"}
                        }
                    },
                    ui = {
                        outputMethod = "display"
                    }
                }
            end
        },
        alert = {
            show = function(msg) print("Alert: " .. msg) end,
            closeSpecific = function(alert) end
        },
        pasteboard = {
            getContents = function() return "test clipboard content" end,
            setContents = function(content) print("Clipboard set to: " .. content) end
        },
        application = {
            frontmostApplication = function()
                return {
                    name = function() return "TestApp" end,
                    focusedWindow = function() return {} end
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
                                        return "Test selected text from full workflow"
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
        eventtap = {
            keyStroke = function(modifiers, key)
                print("Mock keyStroke: " .. table.concat(modifiers, "+") .. "+" .. key)
            end,
            keyStrokes = function(text)
                print("Mock keyStrokes: " .. text)
            end
        },
        timer = {
            usleep = function(ms) end,
            doAfter = function(delay, fn) fn() end
        },
        osascript = {
            applescript = function(script) 
                return true, "selected text from applescript"
            end
        },
        task = {
            new = function(command, callback, args)
                return {
                    start = function()
                        -- Simulate successful command execution
                        callback(0, "Mock AI response: Improved version of the text", "")
                    end,
                    isRunning = function() return false end,
                    terminate = function() end
                }
            end
        },
        hotkey = {
            bind = function(modifiers, key, callback)
                print("Hotkey bound: " .. table.concat(modifiers, "+") .. "+" .. key)
                return {
                    delete = function() print("Hotkey deleted") end
                }
            end
        },
        chooser = {
            new = function(callback)
                return {
                    bgDark = function() end,
                    fgColor = function() end,
                    subTextColor = function() end,
                    width = function() end,
                    rows = function() end,
                    searchSubText = function() end,
                    completionFn = function() end,
                    choices = function(choices) 
                        print("Chooser choices set: " .. #choices .. " items")
                    end,
                    show = function() print("Chooser shown") end,
                    hide = function() print("Chooser hidden") end
                }
            end
        },
        timer = {
            doAfter = function(delay, callback)
                callback() -- Execute immediately for testing
            end,
            usleep = function(microseconds) end
        },
        eventtap = {
            keyStrokes = function(text) 
                print("Typing: " .. text)
            end
        }
    }
    
    -- Create test directory
    os.execute("mkdir -p /tmp/test_ask_ai")
    
    -- Set up module path
    package.path = package.path .. ";../modules/?.lua;../../modules/?.lua"
    
    local tests = {}
    local passed = 0
    local failed = 0
    
    -- Test 1: Complete Application Initialization
    tests.test_app_initialization = function()
        print("\n--- Test: Application Initialization ---")
        
        -- Create config file
        local configFile = io.open("/tmp/test_ask_ai/ask-ai-config.json", "w")
        configFile:write('{"test": "config"}')
        configFile:close()
        
        -- Load main application
        local success, AskAI = pcall(function()
            -- Load modules individually for testing
            local ConfigManager = require('config_manager')
            local TextHandler = require('text_handler')
            local LLMClient = require('llm_client')
            local AIOperations = require('ai_operations')
            local UIManager = require('ui_manager')
            local HotkeyManager = require('hotkey_manager')
            
            -- Create mock application
            local app = {}
            app.config = ConfigManager:new()
            app.textHandler = TextHandler:new()
            app.llmClient = LLMClient:new(app.config)
            app.aiOperations = AIOperations:new(app.llmClient)
            app.uiManager = UIManager:new()
            app.hotkeyManager = HotkeyManager:new()
            
            -- Load configuration
            app.config:load()
            
            return app
        end)
        
        assert(success, "Application should initialize successfully")
        assert(AskAI ~= nil, "Application object should be created")
        print("✓ Application initialized successfully")
        
        return true
    end
    
    -- Test 2: Text Selection Workflow
    tests.test_text_selection_workflow = function()
        print("\n--- Test: Text Selection Workflow ---")
        
        local TextHandler = require('text_handler')
        local textHandler = TextHandler:new()
        
        -- Test getting selected text
        local selectedText = textHandler:getSelectedText()
        assert(type(selectedText) == "string", "Should return string")
        print("✓ Selected text retrieved: " .. selectedText)
        
        -- Test clipboard fallback
        local clipboardText = textHandler:getClipboard()
        assert(type(clipboardText) == "string", "Should return clipboard string")
        print("✓ Clipboard text retrieved: " .. clipboardText)
        
        -- Test text validation
        local valid, result = textHandler:validateText("Valid text input")
        assert(valid, "Valid text should pass validation")
        print("✓ Text validation passed")
        
        return true
    end
    
    -- Test 3: LLM Integration Workflow
    tests.test_llm_integration_workflow = function()
        print("\n--- Test: LLM Integration Workflow ---")
        
        local ConfigManager = require('config_manager')
        local LLMClient = require('llm_client')
        
        local config = ConfigManager:new()
        config:load()
        
        local llmClient = LLMClient:new(config)
        
        -- Test command building
        local providerConfig = {
            command = "echo",
            args = {"test"},
            enabled = true
        }
        
        local command = llmClient:buildCommand(providerConfig, "Test prompt")
        assert(type(command) == "string", "Should build command string")
        assert(command:find("echo"), "Command should contain echo")
        print("✓ Command built: " .. command)
        
        -- Test execution (mock)
        local callback_called = false
        llmClient:executeWithFallback("Test prompt", function(result, error)
            callback_called = true
            assert(result ~= nil, "Should receive result")
            assert(error == nil, "Should not receive error")
            print("✓ LLM execution completed: " .. tostring(result))
        end)
        
        assert(callback_called, "Callback should be called")
        
        return true
    end
    
    -- Test 4: AI Operations Workflow
    tests.test_ai_operations_workflow = function()
        print("\n--- Test: AI Operations Workflow ---")
        
        local ConfigManager = require('config_manager')
        local LLMClient = require('llm_client')
        local AIOperations = require('ai_operations')
        
        local config = ConfigManager:new()
        config:load()
        
        local llmClient = LLMClient:new(config)
        local aiOperations = AIOperations:new(llmClient)
        
        -- Test getting available operations
        local operations = aiOperations:getAvailableOperations()
        assert(type(operations) == "table", "Should return operations table")
        assert(#operations > 0, "Should have operations available")
        print("✓ Available operations: " .. #operations)
        
        -- Test operation execution
        local callback_called = false
        aiOperations:execute("improve_writing", "Test input text", function(result, error)
            callback_called = true
            assert(result ~= nil, "Should receive result")
            print("✓ Operation executed: " .. tostring(result))
        end)
        
        assert(callback_called, "Operation callback should be called")
        
        return true
    end
    
    -- Test 5: Hotkey Management Workflow
    tests.test_hotkey_workflow = function()
        print("\n--- Test: Hotkey Management Workflow ---")
        
        local HotkeyManager = require('hotkey_manager')
        local hotkeyManager = HotkeyManager:new()
        
        -- Test hotkey binding
        local config = {
            key = "a",
            modifiers = {"cmd", "shift"}
        }
        
        local callback_called = false
        local success, id = hotkeyManager:bind(config, function()
            callback_called = true
        end)
        
        assert(success, "Hotkey binding should succeed")
        assert(type(id) == "string", "Should return hotkey ID")
        print("✓ Hotkey bound: " .. id)
        
        -- Test hotkey is registered
        assert(hotkeyManager:isHotkeyRegistered({"cmd", "shift"}, "a"), "Hotkey should be registered")
        print("✓ Hotkey registration verified")
        
        return true
    end
    
    -- Test 6: UI Management Workflow
    tests.test_ui_workflow = function()
        print("\n--- Test: UI Management Workflow ---")
        
        local UIManager = require('ui_manager')
        local uiManager = UIManager:new()
        
        -- Test operation chooser
        local operations = {
            {operation = "test", title = "Test Operation", description = "Test description"}
        }
        
        local callback_called = false
        uiManager:showOperationChooser(operations, function(choice)
            callback_called = true
            print("✓ Operation chooser callback called")
        end)
        
        -- Test progress indicators
        uiManager:showProgress("Testing progress...")
        print("✓ Progress indicator shown")
        
        uiManager:hideProgress()
        print("✓ Progress indicator hidden")
        
        return true
    end
    
    -- Test 7: End-to-End Workflow Simulation
    tests.test_end_to_end_workflow = function()
        print("\n--- Test: End-to-End Workflow Simulation ---")
        
        -- Simulate complete workflow
        local ConfigManager = require('config_manager')
        local TextHandler = require('text_handler')
        local LLMClient = require('llm_client')
        local AIOperations = require('ai_operations')
        
        -- 1. Initialize components
        local config = ConfigManager:new()
        config:load()
        
        local textHandler = TextHandler:new()
        local llmClient = LLMClient:new(config)
        local aiOperations = AIOperations:new(llmClient)
        
        print("✓ Components initialized")
        
        -- 2. Get input text
        local inputText = textHandler:getSelectedText()
        if not inputText or inputText == "" then
            inputText = textHandler:getClipboard()
        end
        
        assert(inputText and inputText ~= "", "Should have input text")
        print("✓ Input text obtained: " .. inputText)
        
        -- 3. Execute AI operation
        local workflow_completed = false
        aiOperations:execute("improve_writing", inputText, function(result, error)
            workflow_completed = true
            
            if error then
                print("✗ Workflow failed: " .. error)
                return
            end
            
            assert(result and result ~= "", "Should receive result")
            print("✓ AI operation completed: " .. result)
            
            -- 4. Handle result (simulate clipboard copy)
            textHandler:setClipboard(result)
            print("✓ Result copied to clipboard")
        end)
        
        assert(workflow_completed, "Workflow should complete")
        print("✓ End-to-end workflow completed successfully")
        
        return true
    end
    
    -- Run all tests
    for test_name, test_func in pairs(tests) do
        local success, result = pcall(test_func)
        if success and result then
            print("✓ " .. test_name .. " PASSED")
            passed = passed + 1
        else
            print("✗ " .. test_name .. " FAILED - " .. (result or "Unknown error"))
            failed = failed + 1
        end
    end
    
    -- Cleanup
    os.execute("rm -rf /tmp/test_ask_ai")
    
    print("\n" .. "=" .. string.rep("=", 50))
    print(string.format("Integration Test Results: %d passed, %d failed", passed, failed))
    
    return failed == 0
end

-- Run tests if this file is executed directly
if arg and arg[0] == "test_full_workflow.lua" then
    local success = run_integration_tests()
    os.exit(success and 0 or 1)
end

return {run_integration_tests = run_integration_tests}