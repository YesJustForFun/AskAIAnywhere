# Contributing to Ask AI Anywhere

Thank you for your interest in contributing to Ask AI Anywhere! This document provides guidelines for testing, development, and contributing to the project.

## Overview

Ask AI Anywhere is a Hammerspoon-based AI text processing tool that allows users to select text from any macOS application and process it with AI providers like Claude and Gemini. The project is structured as a modular system with comprehensive testing.

## Development Setup

### Prerequisites

- macOS with Hammerspoon installed
- Lua 5.3 or later
- Terminal access
- One or more AI provider CLI tools:
  - `@anthropic-ai/claude-code` for Claude
  - `@google/gemini-cli` for Gemini

### Installation

1. Clone the repository to your Hammerspoon directory:
   ```bash
   cd ~/.hammerspoon
   git clone <repository-url> ask-ai-anywhere
   ```

2. Add to your Hammerspoon `init.lua`:
   ```lua
   require('ask-ai-anywhere.init')
   ```

3. Reload Hammerspoon configuration

## Testing

The project includes comprehensive unit tests and integration tests to ensure reliability and catch regressions.

### Test Structure

```
tests/
├── run_tests.lua           # Main test runner
├── unit/                   # Unit tests for individual modules
│   ├── test_config_manager.lua
│   ├── test_ai_operations.lua
│   ├── test_hotkey_manager.lua
│   ├── test_text_handler.lua
│   ├── test_llm_client.lua
│   └── test_execution_context.lua
└── integration/            # Integration tests for full workflows
    ├── test_full_workflow.lua
    └── test_end_to_end.lua
```

### Running Tests

#### All Tests
```bash
cd tests
lua run_tests.lua
```

#### Unit Tests Only
```bash
cd tests
lua run_tests.lua --pattern unit
```

#### Integration Tests Only
```bash
cd tests
lua run_tests.lua --pattern integration
```

#### Specific Test Suite
```bash
cd tests
lua run_tests.lua test_text_handler
lua run_tests.lua test_end_to_end
```

#### Test Help
```bash
cd tests
lua run_tests.lua --help
```

### Test Types

#### Unit Tests

Unit tests test individual modules in isolation with mocked dependencies:

- **test_config_manager**: Configuration loading, validation, and access
- **test_ai_operations**: AI operation definitions and execution
- **test_hotkey_manager**: Hotkey binding, validation, and conflict detection
- **test_text_handler**: Text selection, clipboard operations, and validation
- **test_llm_client**: Command building, provider management, and execution
- **test_execution_context**: Variable substitution, context management, and action execution

#### Integration Tests

Integration tests verify complete workflows with all components working together:

- **test_full_workflow**: Basic workflow integration testing
- **test_end_to_end**: Complete end-to-end testing including:
  - Text selection from applications
  - LLM processing with real command execution
  - UI interactions (chooser, result display)
  - Hotkey execution
  - Error handling
  - Full translation workflow

### Test Coverage

The tests cover:

- ✅ **Text Selection**: Accessibility API, clipboard fallback, text cleaning
- ✅ **LLM Integration**: Command building, provider management, error handling
- ✅ **Hotkey Management**: Binding, validation, conflict detection, execution
- ✅ **Action System**: Variable substitution, context management, async execution
- ✅ **UI Components**: Chooser menus, result display, progress indicators
- ✅ **Configuration**: Loading, validation, hierarchical access
- ✅ **Error Handling**: Graceful degradation, user feedback
- ✅ **End-to-End Workflows**: Complete user scenarios

### Writing Tests

#### Unit Test Template

```lua
local function test_feature_name()
    print("Testing feature...")
    
    -- Setup test environment
    local module = require('module_name')
    local instance = module:new()
    
    -- Test cases
    local test_cases = {
        {
            input = "test input",
            expected = "expected output",
            description = "Test description"
        }
    }
    
    local passed = 0
    local total = #test_cases
    
    for i, test_case in ipairs(test_cases) do
        local result = instance:method(test_case.input)
        if result == test_case.expected then
            print("✓ Test " .. i .. ": " .. test_case.description)
            passed = passed + 1
        else
            print("✗ Test " .. i .. ": " .. test_case.description)
            print("  Expected: " .. test_case.expected)
            print("  Got: " .. result)
        end
    end
    
    print(string.format("Tests: %d/%d passed", passed, total))
    return passed == total
end
```

#### Integration Test Template

```lua
local function test_workflow_name()
    print("Testing workflow...")
    
    -- Setup comprehensive test environment
    local env = setup_integration_environment()
    
    -- Set up test data
    _test_selected_text = "Test input text"
    
    -- Load and configure modules
    local module = require('module_name')
    local instance = module:new()
    
    -- Execute workflow
    local success = pcall(instance.method, instance, args)
    
    -- Restore environment
    env.restore()
    
    -- Verify results
    if success and _test_expected_result then
        print("✓ Workflow works correctly")
        return true
    else
        print("✗ Workflow failed")
        return false
    end
end
```

### Test Debugging

#### Debug Information

Tests provide detailed debug information:

```bash
cd tests
lua run_tests.lua test_text_handler
```

Output includes:
- Test case descriptions
- Expected vs actual results
- Pass/fail status for each test
- Summary statistics

#### Common Issues

1. **Mock Environment**: Tests use mocked Hammerspoon APIs
2. **Path Issues**: Ensure module paths are correct
3. **Async Operations**: Some tests simulate async behavior
4. **File Operations**: Tests mock file I/O operations

### Manual Testing

For testing the actual Hammerspoon integration:

#### Basic Functionality
1. Select text in any application
2. Press configured hotkey (e.g., Cmd+Ctrl+Alt+C)
3. Verify text is processed by AI
4. Check result display

#### Text Selection Testing
1. Test in various applications (TextEdit, Browser, Terminal)
2. Try different text types (plain text, formatted text, code)
3. Verify clipboard preservation

#### UI Testing
1. Test operation chooser menu
2. Verify result display window
3. Check progress indicators
4. Test keyboard shortcuts (ESC to close)

#### Error Handling
1. Test with no text selected
2. Test with invalid AI provider
3. Test with network issues
4. Verify graceful error messages

## Development Guidelines

### Code Style

- Use consistent indentation (4 spaces)
- Follow Lua naming conventions
- Add descriptive comments
- Use meaningful variable names

### Module Structure

Each module should follow this pattern:

```lua
-- Module Name
-- Description of module purpose

local ModuleName = {}
ModuleName.__index = ModuleName

function ModuleName:new()
    local instance = setmetatable({}, ModuleName)
    -- Initialize instance
    return instance
end

function ModuleName:method()
    -- Method implementation
end

return ModuleName
```

### Testing Requirements

All contributions must include:

1. **Unit Tests**: For any new modules or functions
2. **Integration Tests**: For new workflows or major features
3. **Test Documentation**: Clear description of what is being tested
4. **Error Cases**: Tests for error conditions and edge cases

### Pull Request Process

1. **Create Tests**: Write tests before implementing features
2. **Run Test Suite**: Ensure all tests pass
3. **Update Documentation**: Update relevant documentation
4. **Code Review**: Submit PR for review

### Debug Logging

The system includes comprehensive debug logging:

```lua
-- Logs are written to ~/.hammerspoon/ask-ai-debug.log
-- Check logs for troubleshooting:
tail -f ~/.hammerspoon/ask-ai-debug.log
```

## Troubleshooting

### Common Issues

1. **Tests Failing**: Check module paths and dependencies
2. **Hammerspoon Issues**: Verify Hammerspoon is running
3. **AI Provider Issues**: Ensure CLI tools are installed
4. **Permission Issues**: Check accessibility permissions

### Getting Help

1. Check the test output for specific error messages
2. Review the debug logs
3. Ensure all dependencies are installed
4. Verify configuration is correct

### Performance Testing

For performance-critical features:

1. Test with large text selections
2. Verify memory usage
3. Check response times
4. Test with multiple concurrent operations

## Release Testing

Before releases, run the full test suite:

```bash
cd tests
lua run_tests.lua
```

Verify:
- All unit tests pass
- All integration tests pass
- Manual testing in real Hammerspoon environment
- No regressions in existing functionality

## Contributing Workflow

1. **Fork** the repository
2. **Create** a feature branch
3. **Write** tests for your changes
4. **Implement** your changes
5. **Run** the test suite
6. **Submit** a pull request

Thank you for contributing to Ask AI Anywhere! Your tests and contributions help ensure the tool works reliably for all users.