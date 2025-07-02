# Contributing to Ask AI Anywhere

Thank you for your interest in contributing! This guide will help you get started with development and contributing to the project.

## Development Setup

### Prerequisites

- macOS 10.12 or later
- [Hammerspoon](https://www.hammerspoon.org/) installed
- Lua 5.3+ (comes with Hammerspoon)
- Git
- Text editor with Lua support

### Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/ask-ai-anywhere.git
   cd ask-ai-anywhere
   ```

2. **Set Up Development Environment**
   ```bash
   # Link to Hammerspoon config directory for testing
   ln -sf "$(pwd)/hammerspoon-ask-ai" ~/.hammerspoon/ask-ai-anywhere-dev
   ```

3. **Create Development Config**
   ```lua
   -- Add to ~/.hammerspoon/init.lua for development
   require("ask-ai-anywhere-dev.init")
   ```

4. **Test Installation**
   ```lua
   -- In Hammerspoon console
   hs.askai.test()
   ```

## Code Organization

### File Structure
```
hammerspoon-ask-ai/
├── init.lua                 # Main entry point
├── modules/
│   ├── config.lua          # Configuration management
│   ├── llm.lua             # LLM provider interface  
│   ├── text_operations.lua # Text processing
│   └── ui.lua              # User interface
├── tests/
│   ├── test_config.lua     # Config tests
│   ├── test_llm.lua        # LLM tests
│   └── test_runner.lua     # Test orchestrator
└── docs/
    ├── API.md              # API documentation
    └── TROUBLESHOOTING.md  # Troubleshooting guide
```

### Code Style

**General Principles:**
- Prefer clarity over cleverness
- Use descriptive names for functions and variables
- Add comments for complex logic
- Handle errors gracefully

**Lua Style:**
```lua
-- Use snake_case for functions and variables
local function get_selected_text()
    -- Function body
end

-- Use camelCase for module names when required by Hammerspoon
local textOps = {}

-- Use UPPER_CASE for constants
local DEFAULT_TIMEOUT = 30

-- Indentation: 4 spaces
if condition then
    local result = some_function()
    return result
end

-- Table formatting
local config = {
    provider = "gemini",
    timeout = 30,
    options = {
        verbose = true,
        notifications = false
    }
}
```

**Error Handling:**
```lua
-- Always return success boolean + result/error
function module.operation(input)
    if not input then
        return false, "No input provided"
    end
    
    local success, result = pcall(risky_operation, input)
    if not success then
        return false, "Operation failed: " .. result
    end
    
    return true, result
end
```

## Development Workflow

### Making Changes

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   ```lua
   -- Run test suite
   hs.execute("cd ~/.hammerspoon/ask-ai-anywhere-dev/tests && lua test_runner.lua")
   
   -- Manual testing
   hs.askai.reload()
   hs.askai.test()
   ```

4. **Update Documentation**
   - Update README if adding features
   - Add API documentation for new functions
   - Update troubleshooting guide if needed

### Testing

#### Running Tests
```bash
cd hammerspoon-ask-ai/tests
lua test_runner.lua
```

#### Writing Tests
Create test functions following this pattern:
```lua
-- In appropriate test file
function tests.test_new_feature()
    -- Setup
    local input = "test input"
    
    -- Execute
    local success, result = module.new_feature(input)
    
    -- Assert
    assert(success, "Operation should succeed")
    assert(result == "expected", "Should return expected result")
    
    print("✅ test_new_feature passed")
end

-- Add to run_all function
function tests.run_all()
    -- ... existing tests
    tests.test_new_feature()
    -- ...
end
```

#### Manual Testing Checklist
- [ ] Hotkeys work correctly
- [ ] Text selection/clipboard detection works
- [ ] All operations produce reasonable results
- [ ] Error handling works (test with no AI commands)
- [ ] UI elements display correctly
- [ ] Configuration persists across reloads

## Contributing Guidelines

### Types of Contributions

**Bug Fixes:**
- Fix functionality issues
- Improve error handling
- Performance improvements

**Features:**
- New text operations
- Additional LLM providers
- UI improvements
- Configuration options

**Documentation:**
- API documentation
- Usage examples
- Troubleshooting guides
- Installation instructions

### Submission Process

1. **Check Existing Issues**
   - Search for existing issues or feature requests
   - Comment on relevant issues to avoid duplication

2. **Create Issue (for major changes)**
   - Describe the problem or feature request
   - Discuss approach before implementing
   - Get feedback from maintainers

3. **Implement Changes**
   - Follow code style guidelines
   - Add appropriate tests
   - Update documentation

4. **Create Pull Request**
   - Use descriptive title and description
   - Reference related issues
   - Include testing instructions

### Pull Request Guidelines

**Title Format:**
- `feat: add new translation operation`
- `fix: resolve hotkey conflict issue`
- `docs: update installation guide`
- `test: add LLM provider tests`

**Description Should Include:**
- What changed and why
- How to test the changes
- Any breaking changes
- Screenshots for UI changes

**Before Submitting:**
- [ ] Tests pass locally
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No console errors in Hammerspoon
- [ ] Functionality tested manually

## Specific Contribution Areas

### Adding New LLM Providers

1. **Extend `llm.lua`:**
   ```lua
   -- Add provider to call function
   elseif provider == "new_provider" then
       command = config.get("llm.new_provider_command") or "new_provider -p"
   ```

2. **Update Configuration Schema:**
   ```lua
   -- In config.lua defaults
   llm = {
       new_provider_command = "new_provider -p"
   }
   ```

3. **Add Tests:**
   ```lua
   -- In test_llm.lua
   function tests.test_call_new_provider()
       -- Test implementation
   end
   ```

### Adding New Text Operations

1. **Define Operation:**
   ```lua
   -- In config.lua defaults
   operations = {
       {name = "New Operation", key = "new_op", icon = "🆕"}
   }
   ```

2. **Add Prompt Template:**
   ```lua
   -- In llm.lua buildPrompt function
   new_op = "Custom prompt for new operation:\n\n" .. text
   ```

3. **Add Quick Operation (optional):**
   ```lua
   -- In text_operations.lua
   function textOps.quickNewOperation(outputMode)
       return textOps.performOperation("new_op", {outputMode = outputMode})
   end
   ```

### Improving UI Components

1. **Extend Chooser Options:**
   ```lua
   -- In ui.lua
   local newChooserItems = {
       {text = "New Option", subText = "Description", operation = "new_op"}
   }
   ```

2. **Add New Dialogs:**
   ```lua
   function ui.showNewDialog()
       -- Dialog implementation
   end
   ```

### Performance Improvements

**Common Areas:**
- Reduce startup time
- Optimize text processing
- Improve LLM call efficiency
- Minimize UI blocking operations

**Profiling:**
```lua
-- Time operations
local start = hs.timer.secondsSinceEpoch()
-- ... operation
local elapsed = hs.timer.secondsSinceEpoch() - start
print("Operation took: " .. elapsed .. " seconds")
```

## Release Process

### Version Numbers
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version in `init.lua`
- Create git tag for releases

### Changelog
- Maintain CHANGELOG.md
- Group changes by type (Added, Changed, Fixed, Removed)
- Include issue/PR references

### Testing Before Release
1. Run full test suite
2. Test on clean Hammerspoon installation
3. Verify all documented features work
4. Test with both AI providers
5. Check performance on large text inputs

## Community

### Communication
- Use GitHub issues for bug reports and feature requests
- Discussions for questions and general topics
- Be respectful and constructive

### Getting Help
- Check existing documentation first
- Search closed issues for similar problems
- Provide clear reproduction steps
- Include system information

### Code of Conduct
- Be welcoming and inclusive
- Respect different viewpoints
- Focus on constructive feedback
- Help others learn and contribute

## Development Tips

### Debugging Hammerspoon Scripts
```lua
-- Use print for simple debugging
print("Variable value:", variable)

-- Use hs.inspect for complex objects
print(hs.inspect(complex_table))

-- Check console regularly
-- Open Hammerspoon menu → Console
```

### Testing AI Operations Without API Calls
```lua
-- Mock LLM responses for testing
local function mockLLMCall(provider, prompt)
    return true, "Mock response for: " .. prompt
end

-- Replace real function temporarily
local originalCall = llm.call
llm.call = mockLLMCall
-- ... test code
llm.call = originalCall
```

### Quick Reload During Development
```lua
-- Add to your development config
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "r", function()
    hs.askai.reload()
    hs.notify.new({title="Ask AI", informativeText="Reloaded"}):send()
end)
```

Thank you for contributing to Ask AI Anywhere! Your improvements help make the tool better for everyone.
