# API Documentation

This document describes the internal API and architecture of Ask AI Anywhere.

## Module Structure

```
hammerspoon-ask-ai/
├── init.lua                 # Main entry point and application logic
└── modules/
    ├── config.lua          # Configuration management
    ├── llm.lua             # LLM provider interface
    ├── text_operations.lua # Text processing functions
    └── ui.lua              # User interface components
```

## Core Modules

### config.lua

Manages application configuration with persistence.

#### Functions

##### `config.load()`
Loads configuration from file, merging with defaults.

**Returns:** `table` - Complete configuration object

##### `config.save()`  
Saves current configuration to file.

**Returns:** `boolean` - Success status

##### `config.get(key)`
Gets configuration value using dot notation.

**Parameters:**
- `key` (string): Configuration key (e.g., "llm.default_provider")

**Returns:** `any` - Configuration value or nil

##### `config.set(key, value)`
Sets configuration value using dot notation.

**Parameters:**
- `key` (string): Configuration key
- `value` (any): Value to set

#### Configuration Schema

```lua
{
  hotkeys = {
    main_trigger = {"cmd", "shift", "a"},
    quick_improve = {"cmd", "shift", "i"},
    quick_translate = {"cmd", "shift", "t"}
  },
  llm = {
    default_provider = "gemini",
    gemini_command = "gemini -p",
    claude_command = "claude -p", 
    timeout = 30
  },
  ui = {
    menu_title = "Ask AI Anywhere",
    show_notifications = true,
    menu_width = 300
  },
  operations = {
    {name = "Improve Writing", key = "improve", icon = "✨"},
    -- ... more operations
  }
}
```

### llm.lua

Interface for LLM providers (Gemini and Claude).

#### Functions

##### `llm.call(provider, prompt, options)`
Makes a direct call to an LLM provider.

**Parameters:**
- `provider` (string): "gemini" or "claude"
- `prompt` (string): Text prompt to send
- `options` (table, optional): Additional options
  - `timeout` (number): Command timeout in seconds

**Returns:** `boolean, string` - Success status and response/error

##### `llm.performOperation(operation, text, options)`
Performs a predefined text operation using AI.

**Parameters:**
- `operation` (string): Operation type ("improve", "translate", etc.)
- `text` (string): Input text to process
- `options` (table, optional): Operation options
  - `provider` (string): LLM provider to use
  - `language` (string): Target language for translation
  - `tone` (string): Target tone for tone changes
  - `prompt` (string): Custom prompt for "custom" operations

**Returns:** `boolean, string` - Success status and result/error

##### `llm.test(provider)`
Tests connectivity to an LLM provider.

**Parameters:**
- `provider` (string, optional): Provider to test (defaults to configured default)

**Returns:** `boolean, string` - Success status and message

##### `llm.getAvailableProviders()`
Returns list of working LLM providers.

**Returns:** `table` - Array of provider names

#### Supported Operations

- `improve`: Improve writing quality
- `translate`: Translate text (use options.language)
- `translate_en`: Quick translate to English
- `translate_zh`: Quick translate to Chinese
- `summarize`: Create text summary
- `tone`: Change tone (use options.tone)
- `tone_professional`: Change to professional tone
- `tone_casual`: Change to casual tone
- `continue`: Continue writing text
- `custom`: Use custom prompt (use options.prompt)

### text_operations.lua

High-level text processing functions with UI integration.

#### Functions

##### `textOps.getInputText()`
Gets text input from selection or clipboard.

**Returns:** `string, string` - Text content and source ("selection"/"clipboard"/"none")

##### `textOps.getSelectedText()`
Gets currently selected text by copying to clipboard.

**Returns:** `string` - Selected text or nil

##### `textOps.outputResult(result, outputMode, originalText)`
Outputs processing result to specified destination.

**Parameters:**
- `result` (string): Text to output
- `outputMode` (string): "clipboard", "replace", "insert", or "dialog"
- `originalText` (string, optional): Original text for dialog display

**Returns:** `boolean` - Success status

##### `textOps.performOperation(operation, options)`
Performs complete text operation with UI feedback.

**Parameters:**
- `operation` (string): Operation to perform
- `options` (table, optional): Operation and output options
  - `outputMode` (string): How to output result
  - `provider` (string): LLM provider to use
  - Other operation-specific options

**Returns:** `boolean` - Success status

##### Quick Operation Functions

- `textOps.quickImprove(outputMode)`: Quick improve writing
- `textOps.quickTranslate(language, outputMode)`: Quick translation
- `textOps.quickSummarize(outputMode)`: Quick summarization  
- `textOps.customPrompt()`: Show custom prompt dialog

### ui.lua

User interface components and chooser menus.

#### Functions

##### `ui.createMainChooser()`
Creates the main operation selection menu.

##### `ui.showMainChooser()`
Displays the main chooser with current text preview.

##### `ui.showSettings()`
Shows settings dialog with current configuration.

##### `ui.testLLMConnection()`
Shows LLM connection test dialog.

##### `ui.showOutputModeChooser(operation, callback)`
Shows output mode selection dialog.

**Parameters:**
- `operation` (string): Operation being performed
- `callback` (function): Called with selected mode

##### `ui.showProviderChooser(callback)`
Shows LLM provider selection dialog.

**Parameters:**
- `callback` (function): Called with selected provider

##### `ui.init()`
Initializes UI components.

##### `ui.cleanup()`
Cleans up UI resources.

## Main Application (init.lua)

### Global Object: `askAI`

The main application object accessible as `hs.askai`.

#### Properties

- `version` (string): Application version
- `name` (string): Application name
- `hotkeys` (table): Array of active hotkey objects
- `initialized` (boolean): Initialization status

#### Functions

##### `askAI.init()`
Initializes the complete application.

##### `askAI.cleanup()`
Cleans up all resources and hotkeys.

##### `askAI.reload()`
Reloads the entire application.

##### `askAI.test()`
Runs comprehensive system test.

##### `askAI.setupHotkeys()`
Configures hotkey bindings from configuration.

##### `askAI.autoStart()`
Auto-starts the application on Hammerspoon load.

## Event Flow

### Text Operation Flow

1. User triggers hotkey or menu selection
2. `textOps.getInputText()` retrieves selected text or clipboard
3. UI shows progress notification
4. `llm.performOperation()` processes text with AI
5. `textOps.outputResult()` handles result based on output mode
6. UI shows completion notification

### Configuration Flow

1. Application starts with `config.load()`
2. Settings merged from defaults and saved config
3. Configuration accessible via `config.get()`
4. Changes saved with `config.set()` and `config.save()`

### Error Handling

- All LLM calls include timeout handling
- UI shows error notifications for failures
- Console logging for debugging
- Graceful degradation when AI providers unavailable

## Extension Points

### Adding New Operations

1. Add operation to default config in `config.lua`:
```lua
{name = "New Operation", key = "new_op", icon = "🆕"}
```

2. Add prompt template in `llm.lua` `buildPrompt()` function:
```lua
new_op = "Your custom prompt:\n\n" .. text
```

### Adding New LLM Providers

1. Extend `llm.call()` to handle new provider
2. Add provider to `llm.getAvailableProviders()`
3. Update configuration schema
4. Add UI elements in provider chooser

### Custom UI Components

UI components can be extended by:
- Adding new chooser types in `ui.lua`
- Extending menu items in operation lists
- Adding new dialog types for complex interactions

## Testing

### Running Tests

```bash
cd hammerspoon-ask-ai/tests
lua test_runner.lua
```

### Test Structure

- `test_config.lua`: Configuration management tests
- `test_llm.lua`: LLM provider tests with mocked commands
- `test_runner.lua`: Main test orchestrator

### Writing Tests

Follow the existing pattern:
```lua
function tests.test_new_feature()
    -- Test setup
    local result = module.function_to_test()
    
    -- Assertions
    assert(result, "Should return valid result")
    print("✅ test_new_feature passed")
end
```

## Development

### Code Style

- Use clear, descriptive function names
- Document all public functions
- Handle errors gracefully with meaningful messages
- Use consistent indentation (4 spaces)
- Add type hints in comments where helpful

### Debugging

Use Hammerspoon console for debugging:
```lua
-- Enable debug logging
hs.askai.config.set("debug", true)

-- Test individual components
hs.askai.test()

-- Check configuration
print(hs.inspect(hs.askai.config.current))
```
