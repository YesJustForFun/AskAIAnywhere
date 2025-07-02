# Ask AI Anywhere - Hammerspoon Edition

A powerful and simple AI text processing tool for macOS using Hammerspoon. Select any text anywhere and instantly apply AI operations like improving writing, translation, summarization, and more.

## Features

- 🚀 **Simple Setup**: No complex Alfred workflows or external dependencies
- 🤖 **Multiple AI Providers**: Support for Gemini and Claude via local commands
- ⌨️ **Universal Text Processing**: Works in any application on macOS
- 🎯 **Quick Actions**: Hotkey-driven interface for fast text operations
- 🔧 **Highly Configurable**: Customize hotkeys, providers, and operations
- 📋 **Multiple Output Modes**: Replace text, copy to clipboard, type at cursor, or show in dialog

## Text Operations

- **Improve Writing**: Enhance clarity, grammar, and structure
- **Translation**: Translate to any language (quick options for English/Chinese)
- **Summarization**: Create concise summaries of long text
- **Tone Adjustment**: Change between professional, casual, and custom tones
- **Continue Writing**: AI-powered text continuation
- **Custom Prompts**: Use your own AI prompts

## Requirements

- macOS 10.12 or later
- [Hammerspoon](https://www.hammerspoon.org/) installed
- One or both of the following local AI command tools:
  - `gemini -p` command (Google Gemini)
  - `claude -p` command (Anthropic Claude)

## Installation

### 1. Install Hammerspoon

Download and install Hammerspoon from [hammerspoon.org](https://www.hammerspoon.org/).

### 2. Set Up AI Commands

Ensure you have at least one of these commands working in your terminal:

```bash
# Test Gemini
gemini -p "Hello, can you respond with 'OK'?"

# Test Claude  
claude -p "Hello, can you respond with 'OK'?"
```

If you don't have these commands, you'll need to install and configure them according to their respective documentation.

### 3. Install Ask AI Anywhere

1. **Copy the script**: Copy the entire `hammerspoon-ask-ai` folder to your Hammerspoon configuration directory:
   ```bash
   cp -r hammerspoon-ask-ai ~/.hammerspoon/ask-ai-anywhere/
   ```

2. **Load the script**: Add this line to your `~/.hammerspoon/init.lua`:
   ```lua
   require("ask-ai-anywhere.init")
   ```

3. **Reload Hammerspoon**: Press `Cmd+Shift+R` (or use the Hammerspoon menu) to reload the configuration.

### 4. Verify Installation

You should see a notification saying "Ask AI Anywhere Ready!" with the main hotkey combination.

## Usage

### Quick Start

1. **Select any text** in any application
2. **Press `Cmd+Shift+A`** (default hotkey) to open the operations menu
3. **Choose an operation** from the list
4. **Wait for AI processing** and see the result

### Default Hotkeys

- `Cmd+Shift+A`: Show main operations menu
- `Cmd+Shift+I`: Quick improve writing (replaces selected text)
- `Cmd+Shift+T`: Quick translate to English (replaces selected text)

### Input Methods

The script will use text in this priority order:
1. **Selected text** in the current application
2. **Clipboard content** if no text is selected

### Output Modes

- **Replace**: Replace the selected text with the AI result
- **Clipboard**: Copy result to clipboard
- **Insert**: Type result at current cursor position
- **Dialog**: Show result in a popup dialog

## Configuration

### Changing Hotkeys

Edit the configuration by modifying `~/.hammerspoon/ask_ai_config.json` or use the settings menu:

```json
{
  "hotkeys": {
    "main_trigger": ["cmd", "shift", "a"],
    "quick_improve": ["cmd", "shift", "i"],
    "quick_translate": ["cmd", "shift", "t"]
  }
}
```

### Changing AI Provider

Set your preferred default provider:

```json
{
  "llm": {
    "default_provider": "gemini",
    "gemini_command": "gemini -p",
    "claude_command": "claude -p",
    "timeout": 30
  }
}
```

### Custom Operations

Add your own operations to the menu:

```json
{
  "operations": [
    {"name": "Make Funny", "key": "funny", "icon": "😂"},
    {"name": "Formal Style", "key": "formal", "icon": "🎩"}
  ]
}
```

## Console Commands

Access these commands in the Hammerspoon console:

```lua
-- Test the installation
hs.askai.test()

-- Reload the script
hs.askai.reload()  

-- Show settings
hs.askai.showSettings()

-- Test LLM connection
hs.askai.testConnection()
```

## Troubleshooting

### Common Issues

1. **"No AI providers working"**
   - Verify `gemini -p` or `claude -p` commands work in Terminal
   - Check that the commands are in your PATH
   - Try running the test connection from settings

2. **"No text selected or in clipboard"**
   - Make sure to select text before triggering the hotkey
   - Or copy text to clipboard first

3. **Hotkeys not working**
   - Check for conflicts with other applications
   - Verify Hammerspoon has accessibility permissions in System Preferences
   - Try different hotkey combinations

4. **Slow AI responses**
   - Increase timeout in configuration
   - Check your internet connection
   - Try switching AI providers

### Getting Help

1. **Check the Hammerspoon console** for error messages
2. **Run the test function**: `hs.askai.test()` in the console
3. **Review logs** in the Hammerspoon console window

## Advanced Usage

### Custom Prompts

Use the "Custom Prompt" option to create your own AI interactions:

1. Select text
2. Choose "Custom Prompt" from the menu
3. Enter your custom prompt
4. The selected text will be appended to your prompt

### Scripting Integration

You can call operations programmatically:

```lua
-- Improve writing programmatically
hs.askai.improveText("Your text here")

-- Custom operation
hs.askai.performOperation("translate", "Hello world", {language = "Spanish"})
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Built with [Hammerspoon](https://www.hammerspoon.org/)
- Inspired by the original Alfred workflow
- Icons from system emoji set
