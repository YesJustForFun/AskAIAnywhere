# Ask AI Anywhere - Hammerspoon Edition

A powerful, simple AI text processing tool for macOS. This project is a complete refactor of the original Alfred workflow, now using Hammerspoon for easier setup and better functionality.

## 🎯 Project Overview

This repository contains a modern replacement for the complex Alfred-based "Ask AI Anywhere" workflow. The new implementation:

- ✅ **Simpler Setup**: No Alfred Powerpack required
- ✅ **Local AI Integration**: Uses `gemini -p` and `claude -p` commands
- ✅ **Universal Compatibility**: Works in any macOS application
- ✅ **Highly Configurable**: Easy to customize and extend
- ✅ **Open Source**: Fully transparent and modifiable

## 🚀 Quick Start

### Prerequisites
- macOS 10.12+
- [Hammerspoon](https://hammerspoon.org) installed
- At least one working AI command: `gemini -p` or `claude -p`

### Installation
```bash
# 1. Copy the script
cp -r hammerspoon-ask-ai ~/.hammerspoon/ask-ai-anywhere/

# 2. Add to your Hammerspoon config
echo 'require("ask-ai-anywhere.init")' >> ~/.hammerspoon/init.lua

# 3. Reload Hammerspoon (Cmd+Shift+R or menu)
```

### Usage
1. **Select text** anywhere on your Mac
2. **Press `Cmd+Shift+A`** to open the AI operations menu
3. **Choose an operation** (improve writing, translate, summarize, etc.)
4. **Wait for AI processing** and see the result

## 📁 Project Structure

```
ask-ai-anywhere/
├── README.md                    # This file
├── REFACTOR_PLAN.md            # Complete refactoring plan and progress
├── .gitignore                  # Git ignore rules
├── alfred-ask-ai-anywhere-workflow/  # Original Alfred project (reference only)
└── hammerspoon-ask-ai/         # New Hammerspoon implementation
    ├── README.md               # User documentation
    ├── INSTALL.md              # Detailed installation guide
    ├── CONTRIBUTING.md         # Development guidelines
    ├── init.lua                # Main application entry point
    ├── modules/                # Core functionality modules
    │   ├── config.lua          # Configuration management
    │   ├── llm.lua             # LLM provider interface
    │   ├── text_operations.lua # Text processing functions
    │   └── ui.lua              # User interface components
    ├── tests/                  # Unit test suite
    │   ├── test_config.lua     # Configuration tests
    │   ├── test_llm.lua        # LLM integration tests
    │   └── test_runner.lua     # Test orchestrator
    └── docs/                   # Technical documentation
        ├── API.md              # API documentation
        └── TROUBLESHOOTING.md  # Troubleshooting guide
```

## 🎯 Features

### Text Operations
- **Improve Writing**: Enhance clarity, grammar, and structure
- **Translation**: Multi-language support with quick English/Chinese options
- **Summarization**: Create concise summaries
- **Tone Adjustment**: Professional, casual, or custom tones
- **Continue Writing**: AI-powered text continuation
- **Custom Prompts**: Use your own AI instructions

### User Experience
- **Hotkey Driven**: Quick access via keyboard shortcuts
- **Multiple Output Modes**: Replace text, clipboard, type at cursor, or dialog
- **Progress Indicators**: Visual feedback during AI processing
- **Error Handling**: Graceful failure with helpful error messages
- **Settings UI**: Easy configuration through dialogs

### Technical Features
- **Modular Architecture**: Clean, maintainable code structure
- **Configurable**: JSON-based settings with live reload
- **Extensible**: Easy to add new operations and providers
- **Tested**: Comprehensive unit test suite
- **Documented**: Complete API and user documentation

## 🔧 Configuration

Default hotkeys:
- `Cmd+Shift+A`: Main operations menu
- `Cmd+Shift+I`: Quick improve writing
- `Cmd+Shift+T`: Quick translate to English

Customize by editing `~/.hammerspoon/ask_ai_config.json`:

```json
{
  "hotkeys": {
    "main_trigger": ["cmd", "alt", "a"],
    "quick_improve": ["cmd", "alt", "i"],
    "quick_translate": ["cmd", "alt", "t"]
  },
  "llm": {
    "default_provider": "gemini",
    "timeout": 30
  }
}
```

## 🧪 Testing

Run the test suite:
```bash
cd hammerspoon-ask-ai/tests
lua test_runner.lua
```

Test in Hammerspoon console:
```lua
hs.askai.test()  -- Run comprehensive system test
hs.askai.reload()  -- Reload configuration
```

## 📚 Documentation

- **[User Guide](hammerspoon-ask-ai/README.md)**: Complete usage instructions
- **[Installation Guide](hammerspoon-ask-ai/INSTALL.md)**: Step-by-step setup
- **[API Documentation](hammerspoon-ask-ai/docs/API.md)**: Technical reference
- **[Troubleshooting](hammerspoon-ask-ai/docs/TROUBLESHOOTING.md)**: Problem solving
- **[Contributing](hammerspoon-ask-ai/CONTRIBUTING.md)**: Development guide

## 🚧 Project Status

**Status**: ✅ **Complete and Ready for Use**

All planned features have been implemented:
- [x] Core Hammerspoon integration
- [x] LLM provider support (Gemini & Claude)
- [x] All text operations from original Alfred workflow
- [x] Configuration system
- [x] User interface components
- [x] Comprehensive testing
- [x] Complete documentation

See [REFACTOR_PLAN.md](REFACTOR_PLAN.md) for detailed progress tracking.

## 🔄 Migration from Alfred Version

### Advantages of Hammerspoon Version
- **No Alfred Powerpack required** (saves $50+)
- **Simpler installation** (no complex workflow setup)
- **Better error handling** and user feedback
- **More customizable** and extensible
- **Open source** and community-driven
- **Better performance** with local AI commands

### Feature Parity
All original Alfred workflow features are supported:
- ✅ Text selection and clipboard integration
- ✅ Improve writing, translate, summarize operations
- ✅ Tone adjustment and continue writing
- ✅ Custom prompts and operations
- ✅ Multiple output modes
- ✅ Configuration persistence

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](hammerspoon-ask-ai/CONTRIBUTING.md) for:
- Development setup instructions
- Code style guidelines
- Testing requirements
- Pull request process

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Original [Alfred workflow](alfred-ask-ai-anywhere-workflow/) for inspiration
- [Hammerspoon](https://hammerspoon.org) for the amazing automation platform
- Local AI command providers (Gemini, Claude) for API access

---

**Ready to enhance your text with AI?** Follow the [installation guide](hammerspoon-ask-ai/INSTALL.md) and start using Ask AI Anywhere today! 🎉
