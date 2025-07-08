-- Unit tests for TextHandler module
-- Tests text selection, clipboard operations, and text validation

local function setup_test_environment()
    -- Add the parent directory to the path
    package.path = package.path .. ";../../modules/?.lua;../../?.lua"
    
    -- Mock Hammerspoon functions for testing
    hs = {
        application = {
            frontmostApplication = function()
                return {
                    name = function() return "TestApp" end
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
                                        return "Selected test text"
                                    elseif attr == "AXValue" then
                                        return "Full text content with selected portion"
                                    elseif attr == "AXSelectedTextRange" then
                                        return {location = 10, length = 8}
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
                -- Mock key stroke
                print("Mock keyStroke: " .. table.concat(modifiers, "+") .. "+" .. key)
            end,
            keyStrokes = function(text)
                -- Mock typing
                print("Mock keyStrokes: " .. text)
            end
        },
        timer = {
            usleep = function(microseconds)
                -- Mock sleep
            end,
            doAfter = function(delay, fn)
                -- Mock timer
                fn()
            end
        }
    }
    
    -- Global test clipboard content
    _test_clipboard_content = ""
end

local function test_text_cleaning()
    print("Testing text cleaning and validation...")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test cases for text cleaning
    local test_cases = {
        {
            input = "Normal text",
            expected = "Normal text",
            description = "Normal text should remain unchanged"
        },
        {
            input = "Text\r\nwith\rline\nendings",
            expected = "Text\nwith\nline\nendings",
            description = "Line endings should be normalized"
        },
        {
            input = "Text   with    extra   spaces",
            expected = "Text with extra spaces",
            description = "Multiple spaces should be reduced to single"
        },
        {
            input = "Text\000with\031control\127chars",
            expected = "Textwithcontrolchars",
            description = "Control characters should be removed"
        },
        {
            input = "  \t\n  Trimmed text  \t\n  ",
            expected = "Trimmed text",
            description = "Leading and trailing whitespace should be trimmed"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = handler:cleanAndValidateText(test_case.input)
        if result == test_case.expected then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: '" .. test_case.expected .. "'")
            print("  Got: '" .. result .. "'")
        end
    end
    
    print(string.format("Text cleaning tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_clipboard_operations()
    print("Testing clipboard operations...")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    local test_cases = {
        {
            test_content = "Test clipboard content",
            description = "Basic clipboard get/set operations"
        },
        {
            test_content = "Multi-line\nclipboard\ncontent",
            description = "Multi-line clipboard content"
        },
        {
            test_content = "Special chars: !@#$%^&*()",
            description = "Special characters in clipboard"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        -- Set clipboard content
        handler:setClipboard(test_case.test_content)
        
        -- Get clipboard content
        local retrieved = handler:getClipboard()
        
        -- Compare (after cleaning)
        local expected = handler:cleanAndValidateText(test_case.test_content)
        
        if retrieved == expected then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: '" .. expected .. "'")
            print("  Got: '" .. retrieved .. "'")
        end
    end
    
    print(string.format("Clipboard tests: %d/%d passed", passed, total))
    return passed == total
end

local function test_accessibility_selection()
    print("Testing accessibility text selection...")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test accessibility API
    local selected_text = handler:getSelectedTextViaAccessibility()
    
    -- Should get the mocked selected text
    if selected_text == "Selected test text" then
        print("✓ Accessibility API returned correct selected text")
        return true
    else
        print("✗ Accessibility API failed")
        print("  Expected: 'Selected test text'")
        print("  Got: '" .. (selected_text or "nil") .. "'")
        return false
    end
end

local function test_text_selection_fallback()
    print("Testing text selection fallback mechanism...")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Mock the accessibility to fail
    local original_axuielement = hs.axuielement
    hs.axuielement = {
        applicationElement = function(app)
            return nil  -- Simulate accessibility failure
        end
    }
    
    -- Set clipboard content for fallback test
    _test_clipboard_content = "Original clipboard"
    
    -- Mock the clipboard change during copy operation
    local original_keyStroke = hs.eventtap.keyStroke
    local original_getContents = hs.pasteboard.getContents
    
    hs.eventtap.keyStroke = function(modifiers, key)
        if key == "c" then
            _test_clipboard_content = "Fallback clipboard text"
        end
    end
    
    -- Mock pasteboard to return different values on consecutive calls
    local callCount = 0
    hs.pasteboard.getContents = function()
        callCount = callCount + 1
        if callCount == 1 then
            return "Original clipboard"  -- First call (store original)
        else
            return "Fallback clipboard text"  -- Second call (after copy)
        end
    end
    
    -- Test that it falls back to clipboard
    local result = handler:getSelectedText()
    local expected = handler:cleanAndValidateText("Fallback clipboard text")
    
    -- Restore original mocks
    hs.axuielement = original_axuielement
    hs.eventtap.keyStroke = original_keyStroke
    hs.pasteboard.getContents = original_getContents
    
    if result == expected then
        print("✓ Fallback to clipboard works correctly")
        return true
    else
        print("✗ Fallback to clipboard failed")
        print("  Expected: '" .. expected .. "'")
        print("  Got: '" .. (result or "nil") .. "'")
        return false
    end
end

local function test_text_typing()
    print("Testing text typing functionality...")
    
    local textHandler = require('text_handler')
    local handler = textHandler:new()
    
    -- Test typing different text lengths
    local test_cases = {
        "Short text",
        "Medium length text that should be handled normally",
        string.rep("Very long text that needs to be chunked. ", 10)
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_text in ipairs(test_cases) do
        -- This would normally simulate typing, but we can't easily test the actual typing
        -- So we'll just verify the function doesn't crash
        local success = pcall(handler.typeText, handler, test_text)
        
        if success then
            print("✓ Test " .. i .. ": Text typing succeeded (length: " .. #test_text .. ")")
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": Text typing failed")
        end
    end
    
    print(string.format("Text typing tests: %d/%d passed", passed, total))
    return passed == total
end

local function run_tests()
    print("Running TextHandler unit tests...")
    print("=" .. string.rep("=", 40))
    
    -- Setup test environment
    setup_test_environment()
    
    local tests = {
        test_text_cleaning,
        test_clipboard_operations,
        test_accessibility_selection,
        test_text_selection_fallback,
        test_text_typing
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
    print(string.format("TextHandler tests: %d/%d passed", passed, total))
    
    return passed == total
end

return {
    run_tests = run_tests,
    test_text_cleaning = test_text_cleaning,
    test_clipboard_operations = test_clipboard_operations,
    test_accessibility_selection = test_accessibility_selection,
    test_text_selection_fallback = test_text_selection_fallback,
    test_text_typing = test_text_typing
}