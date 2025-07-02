# Ask AI Anywhere - Hammerspoon Refactor Plan

## Project Overview
Refactoring the Alfred-based "Ask AI Anywhere" workflow to use Hammerspoon for a simpler setup and better maintainability.

**Original Features:**
- Text selection anywhere + hotkey trigger
- Multiple AI providers (NotionAI, OpenAI, HuggingFace)
- Various text operations: improve writing, translate, summarize, change tone, continue writing
- Clipboard integration
- Multiple output modes (clipboard, keyboard input, stdout)

**New Implementation:**
- Use Hammerspoon Lua scripts instead of Alfred workflow
- Use local `gemini -p` and `claude -p` commands for LLM providers
- Maintain core functionality with simpler setup

## Implementation Plan

### Phase 1: Project Setup ✅
- [x] Create project structure
- [x] Initialize git repository
- [x] Create this planning document

### Phase 2: Core Hammerspoon Script
- [ ] Create main Hammerspoon init.lua
- [ ] Implement text selection detection
- [ ] Set up hotkey bindings
- [ ] Create menu/dialog system for operation selection

### Phase 3: LLM Integration
- [ ] Create LLM provider module for gemini/claude
- [ ] Implement command execution wrapper
- [ ] Add error handling and validation
- [ ] Test LLM connectivity

### Phase 4: Text Operations
- [ ] Implement improve writing function
- [ ] Implement translation function
- [ ] Implement summarization function
- [ ] Implement tone change function
- [ ] Implement continue writing function
- [ ] Add custom prompt support

### Phase 5: UI and UX
- [ ] Create selection menu interface
- [ ] Add progress indicators
- [ ] Implement clipboard handling
- [ ] Add keyboard output functionality

### Phase 6: Configuration and Settings
- [ ] Create configuration system
- [ ] Add hotkey customization
- [ ] Add provider selection
- [ ] Create settings UI

### Phase 7: Testing and Documentation
- [ ] Create unit tests
- [ ] Integration testing
- [ ] Performance testing
- [ ] Write user documentation
- [ ] Create installation guide

### Phase 8: Final Polish
- [ ] Error handling improvements
- [ ] Performance optimization
- [ ] Code cleanup and documentation
- [ ] Final testing

## File Structure
```
hammerspoon-ask-ai/
├── README.md
├── INSTALL.md
├── init.lua                 # Main Hammerspoon script
├── modules/
│   ├── llm.lua             # LLM provider interface
│   ├── text_operations.lua # Text processing functions
│   ├── ui.lua              # User interface components
│   └── config.lua          # Configuration management
├── tests/
│   ├── test_llm.lua
│   ├── test_text_operations.lua
│   └── test_ui.lua
└── docs/
    ├── API.md
    └── TROUBLESHOOTING.md
```

## Key Requirements
1. **Simplicity**: Easy setup compared to Alfred workflow
2. **Local LLM**: Use `gemini -p` and `claude -p` commands
3. **Cross-app compatibility**: Work in any application
4. **Hotkey driven**: Quick access via keyboard shortcuts
5. **Multiple output modes**: Clipboard, direct typing, dialog display

## Technical Considerations
- Hammerspoon's text selection API limitations
- Async command execution for LLM calls
- Error handling for command failures
- UI responsiveness during LLM processing
- Configuration persistence

## Success Criteria
- [ ] Can select text anywhere and trigger AI operations via hotkey
- [ ] All original text operations working (improve, translate, summarize, etc.)
- [ ] Integration with local gemini/claude commands
- [ ] Simple installation process
- [ ] Comprehensive documentation
- [ ] Unit tests covering core functionality

## Progress Tracking
- **Started**: July 2, 2025
- **Current Phase**: Phase 1 (Setup) ✅
- **Next Phase**: Phase 2 (Core Hammerspoon Script)
- **Target Completion**: TBD

## Notes
- Original Alfred project kept for reference only
- No modifications to `alfred-ask-ai-anywhere-workflow/` directory
- All new code in separate project structure
- Git commits at each major milestone
