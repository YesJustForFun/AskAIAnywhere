-- Comprehensive unit tests for text selection debugging
-- Tests various scenarios that might cause text selection issues

local function setup_test_environment()
    -- Add the parent directory to the path
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Store original clipboard content to restore later
    local originalClipboard = ""
    
    -- Mock different states for testing
    local mockStates = {
        normal = {
            selected_text = "This is selected text",
            clipboard_content = "Original clipboard",
            frontmost_app = "TextEdit",
            element_role = "AXTextArea",
            has_selection = true
        },
        no_selection = {
            selected_text = "",
            clipboard_content = "Original clipboard",
            frontmost_app = "TextEdit", 
            element_role = "AXTextArea",
            has_selection = false
        },
        clipboard_same_as_selection = {
            selected_text = "Same text",
            clipboard_content = "Same text",
            frontmost_app = "TextEdit",
            element_role = "AXTextArea",
            has_selection = true
        },
        accessibility_failure = {
            selected_text = "Selected text",
            clipboard_content = "Different clipboard",
            frontmost_app = nil,
            element_role = nil,
            has_selection = true
        },
        command_like_text = {
            selected_text = "gemini.py --api-key test123",
            clipboard_content = "Original clipboard",
            frontmost_app = "Terminal",
            element_role = "AXTextArea",
            has_selection = true
        }
    }
    
    local currentState = "normal"
    
    -- Mock Hammerspoon functions for testing
    hs = {
        application = {
            frontmostApplication = function()
                local state = mockStates[currentState]
                if not state.frontmost_app then
                    return nil
                end
                return {
                    name = function() return state.frontmost_app end,
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
                local state = mockStates[currentState]
                if not state.frontmost_app then
                    return nil
                end
                return {
                    attributeValue = function(self, attr)
                        if attr == "AXFocusedUIElement" then
                            return {
                                attributeValue = function(self, attr)
                                    if attr == "AXSelectedText" then
                                        return state.has_selection and state.selected_text or ""
                                    elseif attr == "AXValue" then
                                        return "Full text content with " .. state.selected_text .. " selected"
                                    elseif attr == "AXSelectedTextRange" then
                                        return state.has_selection and {location = 20, length = #state.selected_text} or {location = 0, length = 0}
                                    elseif attr == "AXRole" then
                                        return state.element_role
                                    elseif attr == "AXSubrole" then
                                        return "AXStandardText"
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
                return mockStates[currentState].clipboard_content
            end,
            setContents = function(content)
                mockStates[currentState].clipboard_content = content
            end
        },
        eventtap = {
            keyStroke = function(modifiers, key)
                if key == "c" then
                    -- Simulate copy operation
                    local state = mockStates[currentState]
                    if state.has_selection then
                        state.clipboard_content = state.selected_text
                    end
                    -- If no selection, clipboard remains unchanged
                end
            end
        },
        timer = {
            usleep = function(microseconds) end,
            doAfter = function(delay, fn) fn() end
        }
    }
    
    return {
        setState = function(stateName)
            currentState = stateName
        end,
        getState = function()
            return currentState
        end,
        getMockStates = function()
            return mockStates
        end
    }
end

local function test_normal_text_selection()
    print("Testing normal text selection...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("normal")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test accessibility API
    local accessibilityText = handler:getSelectedTextViaAccessibility()
    if accessibilityText ~= "This is selected text" then
        print("✗ Accessibility API failed")
        print("  Expected: This is selected text")
        print("  Got: " .. (accessibilityText or "nil"))
        return false
    end
    
    -- Test clipboard method
    local clipboardText = handler:getSelectedTextViaClipboard()
    if clipboardText ~= "This is selected text" then
        print("✗ Clipboard method failed")
        print("  Expected: This is selected text")
        print("  Got: " .. (clipboardText or "nil"))
        return false
    end
    
    -- Test main method
    local selectedText = handler:getSelectedText()
    if selectedText ~= "This is selected text" then
        print("✗ Main selection method failed")
        print("  Expected: This is selected text")
        print("  Got: " .. (selectedText or "nil"))
        return false
    end
    
    print("✓ Normal text selection works correctly")
    return true
end

local function test_no_selection_scenario()
    print("Testing no selection scenario...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("no_selection")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test accessibility API
    local accessibilityText = handler:getSelectedTextViaAccessibility()
    if accessibilityText ~= "" then
        print("✗ Accessibility API should return empty for no selection")
        print("  Got: " .. (accessibilityText or "nil"))
        return false
    end
    
    -- Test clipboard method
    local clipboardText = handler:getSelectedTextViaClipboard()
    if clipboardText ~= "" then
        print("✗ Clipboard method should return empty for no selection")
        print("  Got: " .. (clipboardText or "nil"))
        return false
    end
    
    -- Test main method - should fall back to clipboard
    local selectedText = handler:getSelectedText()
    if selectedText ~= "Original clipboard" then
        print("✗ Main method should fall back to clipboard")
        print("  Expected: Original clipboard")
        print("  Got: " .. (selectedText or "nil"))
        return false
    end
    
    print("✓ No selection scenario works correctly")
    return true
end

local function test_clipboard_same_as_selection()
    print("Testing clipboard same as selection...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("clipboard_same_as_selection")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- This is a critical test - when clipboard already contains the selected text,
    -- the clipboard method might fail to detect that text is selected
    local clipboardText = handler:getSelectedTextViaClipboard()
    if clipboardText == "" then
        print("✗ CRITICAL: Clipboard method failed when clipboard already contains selected text")
        print("  This is likely the root cause of the issue!")
        return false
    end
    
    print("✓ Clipboard same as selection handled correctly")
    return true
end

local function test_accessibility_failure()
    print("Testing accessibility API failure...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("accessibility_failure")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test accessibility API failure
    local accessibilityText = handler:getSelectedTextViaAccessibility()
    if accessibilityText ~= "" then
        print("✗ Accessibility API should fail gracefully")
        print("  Got: " .. (accessibilityText or "nil"))
        return false
    end
    
    -- Test fallback to clipboard
    local selectedText = handler:getSelectedText()
    if selectedText ~= "Selected text" then
        print("✗ Should fallback to clipboard when accessibility fails")
        print("  Expected: Selected text")
        print("  Got: " .. (selectedText or "nil"))
        return false
    end
    
    print("✓ Accessibility failure handled correctly")
    return true
end

local function test_command_like_text()
    print("Testing command-like text selection...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("command_like_text")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test that command-like text is still selected properly
    local selectedText = handler:getSelectedText()
    if selectedText ~= "gemini.py --api-key test123" then
        print("✗ Command-like text should be selected properly")
        print("  Expected: gemini.py --api-key test123")
        print("  Got: " .. (selectedText or "nil"))
        return false
    end
    
    print("✓ Command-like text selected correctly")
    return true
end

local function test_timing_issues()
    print("Testing timing issues...")
    
    local testEnv = setup_test_environment()
    testEnv.setState("normal")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test rapid successive calls
    local results = {}
    for i = 1, 3 do
        local result = handler:getSelectedText()
        table.insert(results, result)
        -- Small delay between calls
        hs.timer.usleep(10000)
    end
    
    -- All results should be the same
    for i = 2, #results do
        if results[i] ~= results[1] then
            print("✗ Timing issue detected - inconsistent results")
            print("  First result: " .. (results[1] or "nil"))
            print("  Result " .. i .. ": " .. (results[i] or "nil"))
            return false
        end
    end
    
    print("✓ Timing issues handled correctly")
    return true
end

local function run_text_selection_debug_tests()
    print("Running Text Selection Debug Tests...")
    print("=" .. string.rep("=", 50))
    
    local tests = {
        test_normal_text_selection,
        test_no_selection_scenario,
        test_clipboard_same_as_selection,
        test_accessibility_failure,
        test_command_like_text,
        test_timing_issues
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
    print(string.format("Text Selection Debug Tests: %d/%d passed", passed, total))
    
    if passed < total then
        print("❌ Some tests failed - these indicate potential root causes:")
        print("1. Check if clipboard method fails when clipboard already contains selected text")
        print("2. Check if accessibility API is working properly")
        print("3. Check for timing issues in text selection")
    else
        print("✅ All text selection debug tests passed!")
    end
    
    return passed == total
end

-- Run tests if this file is executed directly
if arg and arg[0] == "test_text_selection_debugging.lua" then
    local success = run_text_selection_debug_tests()
    os.exit(success and 0 or 1)
end

return {
    run_text_selection_debug_tests = run_text_selection_debug_tests,
    test_normal_text_selection = test_normal_text_selection,
    test_no_selection_scenario = test_no_selection_scenario,
    test_clipboard_same_as_selection = test_clipboard_same_as_selection,
    test_accessibility_failure = test_accessibility_failure,
    test_command_like_text = test_command_like_text,
    test_timing_issues = test_timing_issues
}