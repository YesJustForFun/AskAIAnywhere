# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hammerspoon-based AI text processing tool that allows users to select text from any macOS application and process it with AI providers like Claude and Gemini. It's a reimplementation of an Alfred workflow using Hammerspoon and local CLI tools.

## Development Commands

### Testing
```bash
# Run all tests
cd hammerspoon-ask-ai/tests && lua run_tests.lua

# Run specific test
cd hammerspoon-ask-ai/tests && lua run_tests.lua test_config_manager

# Run tests with pattern
cd hammerspoon-ask-ai/tests && lua run_tests.lua --pattern config

# Show test help
cd hammerspoon-ask-ai/tests && lua run_tests.lua --help
```

### Installation and Setup
The tool is installed as a Hammerspoon extension:
```bash
# Typical installation location
cd ~/.hammerspoon
git clone <repository-url> ask-ai-anywhere
```

Add to Hammerspoon init.lua:
```lua
require('ask-ai-anywhere.init')
```

## Architecture Overview

### Core Components

1. **Main Application** (`init.lua`) - Orchestrates all components and handles the main workflow
2. **ConfigManager** (`modules/config_manager.lua`) - Hierarchical configuration with deep merging of user and default configs  
3. **LLMClient** (`modules/llm_client.lua`) - CLI-based communication with AI providers (Gemini, Claude)
4. **AIOperations** (`modules/ai_operations.lua`) - Manages AI operations and result post-processing
5. **UIManager** (`modules/ui_manager.lua`) - Handles user interface with chooser menus and WebView result dialogs
6. **TextHandler** (`modules/text_handler.lua`) - Multi-method text selection, clipboard management
7. **HotkeyManager** (`modules/hotkey_manager.lua`) - Global hotkey registration with conflict detection

### Key Architectural Patterns

**CLI Integration Strategy**: Uses external CLI tools (`npx @anthropic-ai/claude-code -p`, `npx @google/gemini-cli@latest -p`) rather than direct API calls. This provides simpler authentication and leverages existing CLI tools.

**Modular Design**: Each component has clear responsibilities with minimal coupling. The main application acts as an orchestrator.

**Configuration-Driven**: Highly customizable through JSON configuration files with user config overlaying defaults.

**Provider Fallback System**: Primary/fallback provider mechanism with automatic failover and provider health checking.

### Data Flow
```
User Input (Hotkey) → HotkeyManager → TextHandler → AIOperations → LLMClient → CLI Tools
                                                            ↓
User Interface ← UIManager ← Result Processing ← AI Response
```

## Configuration System

### Configuration Files
- **Default**: `hammerspoon-ask-ai/config/default_config.json`
- **User**: `~/.hammerspoon/ask-ai-config.json` (auto-created)

### Key Configuration Sections
- `environment`: Custom PATH for CLI tools
- `llm.providers`: AI provider configurations with commands and timeouts
- `hotkeys`: Global keyboard shortcuts
- `ui`: Interface preferences including persistent result dialogs
- `operations`: AI operation definitions with custom prompts

### Configuration Access
Uses dot notation for nested access (e.g., `config:get("llm.defaultProvider")`).

## AI Operations

### Built-in Operations
- `improve_writing`: Enhance grammar, clarity, and style
- `continue_writing`: Extend existing text 
- `change_tone_professional/casual`: Tone adjustment
- `translate_to_chinese/english`: Language translation
- `summarize`: Create concise summaries
- `fix_grammar`: Grammar and spelling correction
- `explain`: Explain complex text

### Custom Operations
Operations are configurable through the config file with custom prompts and post-processing rules.

## User Interface

### Components
- **Operation Chooser**: Hammerspoon chooser for selecting AI operations
- **Progress Indicators**: Visual feedback during processing
- **Result Display**: Configurable WebView dialogs with HTML styling and persistent positioning
- **Error Handling**: User-friendly error messages with fallback options

### Output Methods
- `display`: Show in popup window with copy option
- `clipboard`: Copy directly to clipboard  
- `replace`: Replace selected text
- `keyboard`: Type at cursor position

## Text Processing

### Text Selection Methods
1. **AppleScript**: Primary method for universal text selection
2. **Accessibility API**: Fallback for complex applications
3. **Clipboard**: Final fallback option

The system preserves clipboard content during operations and handles various text encoding scenarios.

## Development Notes

### Testing Strategy
- **Unit Tests**: Individual module testing (config, operations, hotkeys)
- **Integration Tests**: Full workflow testing (`test_full_workflow.lua`)
- **Environment Validation**: Checks for required modules and dependencies

### Error Handling
- Graceful degradation with multiple fallback mechanisms
- Provider-level fallbacks for failed AI requests
- User-friendly error messages without technical details
- Comprehensive validation at configuration and runtime levels

### Extensibility
- Plugin-like operation system for easy addition of new AI operations
- Configurable prompts without code changes
- Multiple output method support
- Environment PATH customization for CLI tool discovery

## CLI Tool Requirements

The system requires at least one of these CLI tools:
- `@anthropic-ai/claude-code` (Claude provider)
- `@google/gemini-cli` (Gemini provider)

These are installed via npm/npx and must be available in the configured PATH.