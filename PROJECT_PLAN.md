# Ask AI Anywhere - Hammerspoon Implementation Plan

## Project Overview

Refactoring the existing Alfred-based "Ask AI Anywhere" workflow to use Hammerspoon with Lua scripting. This will provide a simpler, more accessible solution that doesn't require Alfred Powerpack.

### Goals
- Replace Alfred workflow with Hammerspoon Lua scripts
- Use local CLI tools (`gemini -p` and `claude -p`) instead of direct API integration
- Maintain all core functionality from the original workflow
- Provide easier setup and configuration

## Current State Analysis

### Original Alfred Workflow Features
- **Text Selection**: Get selected text from any application
- **LLM Integration**: OpenAI GPT, NotionAI, HuggingFace Chat
- **AI Operations**: 
  - Improve writing
  - Change tone
  - Continue writing
  - Translate (multiple languages)
  - Summarize
  - General chat
- **Output Methods**: Display, replace text, clipboard, keyboard typing
- **Hotkeys**: Global keyboard shortcuts
- **Configuration**: API keys, model selection, custom prompts

### New Hammerspoon Solution
- **LLM Providers**: `gemini -p` and `claude -p` CLI commands
- **Platform**: Hammerspoon Lua scripting
- **Installation**: Simpler setup without Alfred Powerpack

## Implementation Plan

### Phase 1: Core Infrastructure (High Priority)

#### 1.1 Project Setup
- [x] Create project structure
- [ ] Set up Hammerspoon configuration
- [ ] Create basic init.lua file
- [ ] Set up development workflow

#### 1.2 Text Selection & Clipboard
- [ ] Implement text selection capture using AppleScript
- [ ] Create clipboard handling functions
- [ ] Add fallback to clipboard if no text selected
- [ ] Test across different applications

#### 1.3 LLM CLI Integration
- [ ] Create wrapper functions for `gemini -p` command
- [ ] Create wrapper functions for `claude -p` command
- [ ] Implement error handling and validation
- [ ] Add command timeout and retry logic

#### 1.4 Global Hotkey System
- [ ] Define hotkey mappings
- [ ] Implement hotkey registration
- [ ] Create hotkey conflict detection
- [ ] Add hotkey customization support

### Phase 2: User Interface (Medium Priority)

#### 2.1 Menu System
- [ ] Create chooser-based menu UI
- [ ] Add operation icons and descriptions
- [ ] Implement search/filter functionality
- [ ] Add keyboard navigation

#### 2.2 Progress Indicators
- [ ] Add loading indicators for API calls
- [ ] Create progress notifications
- [ ] Implement operation cancellation

#### 2.3 Result Display
- [ ] Multiple output methods (display, replace, clipboard)
- [ ] Result formatting and presentation
- [ ] Error message display

### Phase 3: AI Operations (Medium Priority)

#### 3.1 Core Operations
- [ ] **Improve Writing**: Enhance grammar and clarity
- [ ] **Change Tone**: Professional, casual, friendly options
- [ ] **Continue Writing**: Extend existing text
- [ ] **Translate**: Support major languages
- [ ] **Summarize**: Create concise summaries

#### 3.2 Advanced Operations
- [ ] **General Chat**: Open-ended AI interaction
- [ ] **Custom Prompts**: User-defined operations
- [ ] **Batch Processing**: Multiple operations

### Phase 4: Configuration & Customization (Medium Priority)

#### 4.1 Configuration System
- [ ] JSON-based configuration file
- [ ] Settings UI/editor
- [ ] Configuration validation
- [ ] Default settings

#### 4.2 Customization Features
- [ ] Custom prompt templates
- [ ] Hotkey customization
- [ ] Output method preferences
- [ ] LLM model selection

### Phase 5: Testing & Quality Assurance (Medium Priority)

#### 5.1 Unit Tests
- [ ] Text processing functions
- [ ] CLI integration modules
- [ ] Configuration management
- [ ] Error handling

#### 5.2 Integration Tests
- [ ] End-to-end workflow testing
- [ ] Cross-application compatibility
- [ ] Performance testing
- [ ] Edge case handling

#### 5.3 User Testing
- [ ] Manual testing scenarios
- [ ] Documentation validation
- [ ] Setup process verification

### Phase 6: Documentation & Deployment (Low Priority)

#### 6.1 Documentation
- [ ] README with installation instructions
- [ ] User guide with examples
- [ ] Configuration reference
- [ ] Troubleshooting guide
- [ ] API documentation

#### 6.2 Deployment
- [ ] Installation script
- [ ] Version management
- [ ] Update mechanism
- [ ] Backup/restore functionality

## Technical Architecture

### File Structure
```
hammerspoon-ask-ai/
├── init.lua                 # Main Hammerspoon entry point
├── modules/
│   ├── text_handler.lua     # Text selection and clipboard
│   ├── llm_client.lua       # CLI integration (gemini/claude)
│   ├── ai_operations.lua    # AI operation implementations
│   ├── ui_manager.lua       # Menu and UI components
│   ├── config_manager.lua   # Configuration handling
│   └── hotkey_manager.lua   # Global hotkey management
├── config/
│   ├── default_config.json  # Default configuration
│   └── prompts.json         # AI prompt templates
├── tests/
│   ├── unit/                # Unit tests
│   └── integration/         # Integration tests
└── docs/                    # Documentation
    ├── README.md
    ├── USER_GUIDE.md
    └── API_REFERENCE.md
```

### Key Design Decisions

#### LLM Integration Strategy
- Use local CLI commands (`gemini -p`, `claude -p`) instead of direct API calls
- Benefits: Simpler authentication, better CLI tool integration
- Command format: `echo "prompt" | gemini -p` or `claude -p "prompt"`

#### Text Selection Method
- Primary: AppleScript for universal text selection
- Fallback: System clipboard content
- Cross-platform compatibility considerations

#### Configuration Management
- JSON-based configuration files
- Hot-reloading for development
- User-friendly setting names with validation

#### Error Handling Strategy
- Graceful degradation for failed operations
- User-friendly error messages
- Logging for debugging purposes

## Success Criteria

### Functional Requirements
- [ ] All original Alfred workflow features replicated
- [ ] Works across all major macOS applications
- [ ] Reliable text selection and output
- [ ] Fast response times (< 3 seconds for most operations)
- [ ] Stable hotkey handling without conflicts

### Non-Functional Requirements
- [ ] Easy installation (< 5 minutes setup)
- [ ] Intuitive user interface
- [ ] Comprehensive documentation
- [ ] Reliable error handling
- [ ] Performance comparable to original workflow

### User Experience Goals
- [ ] Seamless text processing workflow
- [ ] Discoverable features and shortcuts
- [ ] Consistent behavior across applications
- [ ] Quick access to common operations

## Timeline Estimate

- **Phase 1 (Core Infrastructure)**: 2-3 days
- **Phase 2 (User Interface)**: 1-2 days  
- **Phase 3 (AI Operations)**: 1-2 days
- **Phase 4 (Configuration)**: 1 day
- **Phase 5 (Testing)**: 1-2 days
- **Phase 6 (Documentation)**: 1 day

**Total Estimated Time**: 7-11 days

## Risk Assessment

### High Risk Items
- Text selection reliability across different applications
- CLI command integration and error handling
- Hotkey conflicts with existing system shortcuts

### Mitigation Strategies
- Extensive testing across popular applications
- Robust error handling and fallback mechanisms
- Configurable hotkey system with conflict detection
- Comprehensive user documentation

## Next Steps

1. Set up basic Hammerspoon project structure
2. Implement core text selection functionality
3. Create LLM CLI integration
4. Build basic UI and hotkey system
5. Iteratively add AI operations and features

## Progress Tracking

This document will be updated throughout development to track progress and any changes to the plan.

---

*Last Updated: 2025-07-02*
*Status: Planning Complete - Ready for Implementation*