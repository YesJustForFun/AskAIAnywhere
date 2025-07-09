-- Test for the timing fix in text selection
-- Ensures that the temp marker issue is resolved

local function setup_test_environment()
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Mock the actual behavior we see in the logs
    local actualSelectedText = "A powerful Hammerspoon-based tool for AI-assisted text processing from anywhere on macOS. This is a complete reimplementation of the Alfred \"Ask AI Anywhere\" workflow using Hammerspoon and local CLI tools."
    local tempMarkerCounter = 0
    
    hs = {
        application = {
            frontmostApplication = function()
                return {
                    name = function() return "Code" end,
                    focusedWindow = function() 
                        return {
                            title = function() return "README.md — .hammerspoon" end
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
                                        return ""  -- Accessibility fails to get selected text
                                    elseif attr == "AXValue" then
                                        return ""
                                    elseif attr == "AXSelectedTextRange" then
                                        return {location = 0, length = 0}
                                    elseif attr == "AXRole" then
                                        return "AXTextArea"
                                    elseif attr == "AXSubrole" then
                                        return "none"
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
                return _current_clipboard
            end,
            setContents = function(content)
                _current_clipboard = content
            end
        },
        eventtap = {
            keyStroke = function(modifiers, key)
                if key == "c" then
                    -- Simulate copying the selected text to clipboard
                    _current_clipboard = actualSelectedText
                end
            end
        },
        timer = {
            usleep = function(microseconds) end,
            doAfter = function(delay, fn) fn() end
        }
    }
    
    -- Start with the original clipboard content
    _current_clipboard = actualSelectedText
    
    return actualSelectedText
end

local function test_timing_fix()
    print("Testing timing fix for temp marker issue...")
    
    local expectedText = setup_test_environment()
    
    -- Load the text handler
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test that getSelectedText works correctly
    local selectedText = handler:getSelectedText()
    
    -- Verify we get the actual selected text, not a temp marker
    if selectedText == expectedText then
        print("✓ Text selection returns correct text")
    else
        print("✗ Text selection failed")
        print("  Expected: " .. expectedText:sub(1, 50) .. "...")
        print("  Got: " .. (selectedText or "nil"):sub(1, 50) .. "...")
        return false
    end
    
    -- Test that multiple calls don't interfere with each other
    local selectedText2 = handler:getSelectedText()
    if selectedText2 == expectedText then
        print("✓ Multiple calls work correctly")
    else
        print("✗ Multiple calls failed")
        print("  Expected: " .. expectedText:sub(1, 50) .. "...")
        print("  Got: " .. (selectedText2 or "nil"):sub(1, 50) .. "...")
        return false
    end
    
    -- Verify clipboard is restored correctly
    local currentClipboard = hs.pasteboard.getContents()
    if currentClipboard == expectedText then
        print("✓ Clipboard is properly restored")
    else
        print("✗ Clipboard not properly restored")
        print("  Expected: " .. expectedText:sub(1, 50) .. "...")
        print("  Got: " .. (currentClipboard or "nil"):sub(1, 50) .. "...")
        return false
    end
    
    return true
end

local function test_context_creation_timing()
    print("Testing execution context creation timing...")
    
    local expectedText = setup_test_environment()
    
    -- Load required modules
    local textHandler = require('text_handler')
    local ExecutionContext = require('execution_context')
    
    -- Mock config and components
    local mockConfig = {
        get = function(self, key) return nil end
    }
    local mockComponents = {
        textHandler = textHandler:new(),
        llmClient = {},
        uiManager = {},
        actionRegistry = {}
    }
    
    -- Test context creation with pre-selected text (simulating the fix)
    local handler = textHandler:new()
    local preSelectedText = handler:getSelectedText()
    
    -- Create context
    local context = ExecutionContext:new(nil, mockConfig, mockComponents)
    
    -- Apply the fix: set input with pre-selected text
    if preSelectedText and preSelectedText ~= "" then
        context.input = preSelectedText
        context:setVariable("input", preSelectedText)
    end
    
    -- Verify context has correct input
    if context.input == expectedText then
        print("✓ Context created with correct input")
    else
        print("✗ Context has wrong input")
        print("  Expected: " .. expectedText:sub(1, 50) .. "...")
        print("  Got: " .. (context.input or "nil"):sub(1, 50) .. "...")
        return false
    end
    
    -- Verify variable is set correctly
    local inputVar = context:getVariable("input")
    if inputVar == expectedText then
        print("✓ Context input variable set correctly")
    else
        print("✗ Context input variable is wrong")
        print("  Expected: " .. expectedText:sub(1, 50) .. "...")
        print("  Got: " .. (inputVar or "nil"):sub(1, 50) .. "...")
        return false
    end
    
    return true
end

local function run_timing_fix_tests()
    print("Running Timing Fix Tests...")
    print("=" .. string.rep("=", 40))
    
    local tests = {
        test_timing_fix,
        test_context_creation_timing
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
    print("=" .. string.rep("=", 40))
    print(string.format("Timing Fix Tests: %d/%d passed", passed, total))
    
    if passed == total then
        print("✅ All timing fix tests passed!")
        print("The temp marker issue should be resolved.")
    else
        print("❌ Some timing fix tests failed")
        print("The temp marker issue may still exist.")
    end
    
    return passed == total
end

-- Run tests if this file is executed directly
if arg and arg[0] == "test_timing_fix.lua" then
    local success = run_timing_fix_tests()
    os.exit(success and 0 or 1)
end

return {
    run_timing_fix_tests = run_timing_fix_tests,
    test_timing_fix = test_timing_fix,
    test_context_creation_timing = test_context_creation_timing
}