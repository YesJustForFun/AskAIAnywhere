# Ask AI Anywhere - Hammerspoon Implementation

A powerful Hammerspoon-based tool for AI-assisted text processing from anywhere on macOS. This is a complete reimplementation of the Alfred "Ask AI Anywhere" workflow using Hammerspoon and local CLI tools.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Hammerspoon](https://img.shields.io/badge/requires-Hammerspoon-orange.svg)

## ✨ Features

- **Universal Text Processing**: Select text from any application and process it with AI
- **Multiple AI Providers**: Support for `gemini -p` and `claude -p` CLI commands
- **Rich Operations**: Improve writing, translate, summarize, change tone, and more
- **Global Hotkeys**: Quick access with customizable keyboard shortcuts
- **Multiple Output Methods**: Display results, copy to clipboard, replace selected text, or type directly
- **Smart Text Selection**: Automatically uses selected text or falls back to clipboard content
- **Customizable Prompts**: Define your own AI operations and prompts
- **Progress Indicators**: Visual feedback during AI processing
- **Error Handling**: Robust error handling with fallback providers

## 🚀 Quick Start

### Prerequisites

1. **Hammerspoon**: Install from [https://www.hammerspoon.org/](https://www.hammerspoon.org/)
2. **LLM CLI Tools**: Install either or both:
   - `claude` CLI: Follow installation instructions from Anthropic
   - `gemini` CLI: Follow installation instructions from Google

### Installation

1. **Clone the repository**:
   ```bash
   cd ~/.hammerspoon
   git clone <repository-url> ask-ai-anywhere
   ```

2. **Add to your Hammerspoon init.lua**:
   ```lua
   require('ask-ai-anywhere.init')
   ```

3. **Reload Hammerspoon configuration**:
   - Press `⌘ + Space`, type "Hammerspoon", and press Enter
   - Click "Reload Config" or press `⌘ + R`

4. **Test the installation**:
   - Select some text in any application
   - Press `⌘ + ⌥ + ⌃ + /` to open the main menu

## 🔧 Configuration

### Default Hotkeys

| Hotkey | Action |
|--------|--------|
| `⌘ + ⌥ + ⌃ + /` | Show main operation menu |
| `⌘ + ⌥ + ⌃ + I` | Improve writing and paste at cursor |
| `⌘ + ⌥ + ⌃ + P` | Continue writing and paste at cursor |
| `⌘ + ⌥ + ⌃ + E` | Translate to English and paste at cursor |
| `⌘ + ⌥ + ⌃ + C` | Translate to Chinese and show comparison |
| `⌘ + ⌥ + ⌃ + S` | Summarize and copy quietly |
| `⌘ + ⌥ + ⌃ + F` | Fix grammar and replace selected text |

### Custom Configuration

Create a configuration file at `~/.hammerspoon/ask-ai-config.yaml`:

```yaml
llm:
  defaultProvider: claude
  fallbackProvider: gemini
  providers:
    claude:
      command: claude
      args: ["-p"]
      enabled: true
      timeout: 30
    gemini:
      command: gemini
      args: ["-p"]
      enabled: true
      timeout: 30

ui:
  outputMethod: display
  showProgress: true

hotkeys:
  - key: "/"
    modifiers: ["cmd", "alt", "ctrl"]
    name: "mainMenu"
    actions:
      - name: "showMainMenu"
```

### Available Operations

- **Improve Writing**: Enhance grammar, clarity, and style
- **Continue Writing**: Extend and continue existing text
- **Change Tone**: Make text professional or casual
- **Translate**: Translate between languages (Chinese ↔ English)
- **Summarize**: Create concise summaries
- **Fix Grammar**: Correct grammar and spelling errors
- **Explain**: Explain complex text in simple terms

## 📖 Usage

### Basic Workflow

1. **Select text** in any application (or copy to clipboard)
2. **Press hotkey** (`⌘ + ⌥ + ⌃ + /` by default)
3. **Choose operation** from the menu
4. **Wait for processing** (progress indicator will show)
5. **Review result** in the display window

### Output Methods

- **Display**: Show result in a popup window with copy option
- **Clipboard**: Copy result directly to clipboard
- **Replace**: Replace selected text with AI result
- **Keyboard**: Type result directly at cursor position

### Advanced Usage

#### Custom Prompts

You can create custom operations by modifying the configuration:

```yaml
operations:
  custom_operation:
    title: "My Custom Operation"
    description: "Does something specific"
    prompt: "Please perform this specific task on the following text:"
```

#### Menu Bar Access

The application adds a menu bar item (🤖) for quick access to:
- Main operation menu
- Configuration testing
- Configuration reloading

## 🛠️ Development

### Project Structure

```
hammerspoon-ask-ai/
├── init.lua                 # Main application entry point
├── modules/
│   ├── config_manager.lua   # Configuration management
│   ├── text_handler.lua     # Text selection and clipboard
│   ├── llm_client.lua       # LLM CLI integration
│   ├── ai_operations.lua    # AI operation implementations
│   ├── ui_manager.lua       # User interface components
│   └── hotkey_manager.lua   # Global hotkey management
├── config/
│   └── default_config.yaml  # Default configuration
├── tests/
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── run_tests.lua        # Test runner
└── docs/                    # Documentation
```

### Running Tests

```bash
cd hammerspoon-ask-ai/tests
lua run_tests.lua                    # Run all tests
lua run_tests.lua test_config_manager # Run specific test
lua run_tests.lua --help             # Show test options
```

### Debugging

1. **Enable Hammerspoon Console**: 
   - Open Hammerspoon
   - Window → Console
   - View logs and errors

2. **Test Configuration**:
   - Use menu bar item → "Test Configuration"
   - Check that CLI commands are working

3. **Verbose Logging**:
   ```lua
   -- Add to your config
   hs.logger.defaultLogLevel = 'debug'
   ```

## 🔍 Troubleshooting

### Common Issues

**"No text selected or in clipboard"**
- Make sure you have text selected or copied to clipboard
- Try using different applications to test text selection

**"Command timed out"**
- Check your internet connection
- Verify CLI tools are properly installed and authenticated
- Increase timeout in configuration

**"Provider not enabled or configured"** 
- Install the required CLI tool (`claude` or `gemini`)
- Ensure CLI tool is in your PATH
- Test CLI tool manually in Terminal

**Hotkey conflicts**
- Check for conflicts with other applications
- Customize hotkeys in configuration file
- Use the conflict detection in hotkey manager

### CLI Tool Setup

#### Claude CLI
```bash
# Install and authenticate claude CLI
# Follow official Anthropic documentation
claude auth login
```

#### Gemini CLI  
```bash
# Install and authenticate gemini CLI
# Follow official Google documentation
gemini auth login
```

### Verification Commands

Test your CLI tools manually:
```bash
# Test Claude
echo "Hello, please respond with OK" | claude -p

# Test Gemini  
echo "Hello, please respond with OK" | gemini -p
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

### Development Setup

1. Clone the repository
2. Set up the development environment:
   ```bash
   cd hammerspoon-ask-ai
   # Run tests to verify setup
   cd tests && lua run_tests.lua
   ```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by the original Alfred "Ask AI Anywhere" workflow
- Built with [Hammerspoon](https://hammerspoon.org/) automation platform
- Uses local CLI tools for AI integration

## 📞 Support

- **Issues**: Report bugs and request features on GitHub Issues
- **Documentation**: Check the `/docs` directory for detailed guides
- **Community**: Join discussions in GitHub Discussions

---

**Made with ❤️ for macOS power users who want AI assistance everywhere**