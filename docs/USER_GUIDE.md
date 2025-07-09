# User Guide

A comprehensive guide to using Ask AI Anywhere for AI-assisted text processing on macOS.

## Table of Contents

- [Getting Started](#getting-started)
- [Basic Usage](#basic-usage)
- [Available Operations](#available-operations)
- [Output Methods](#output-methods)
- [Hotkeys and Shortcuts](#hotkeys-and-shortcuts)
- [Advanced Features](#advanced-features)
- [Tips and Tricks](#tips-and-tricks)

## Getting Started

### First Use

After installation, you can start using Ask AI Anywhere immediately:

1. **Open any application** with text (TextEdit, Notes, Slack, etc.)
2. **Select some text** you want to process
3. **Press `⌘ + ⌥ + ⌃ + /`** to open the main menu
4. **Choose an operation** from the list
5. **Wait for the AI response** and review the result

### Menu Bar Access

Look for the 🤖 icon in your menu bar for quick access to:
- Main operation menu
- Configuration testing
- Reload configuration

## Basic Usage

### Text Selection Methods

Ask AI Anywhere can work with text in several ways:

#### 1. Selected Text (Primary)
- **Select text** in any application
- The selected text will be used as input

#### 2. Clipboard Content (Fallback)
- If no text is selected, clipboard content is used
- **Copy text** (`⌘ + C`) before triggering AI operations

#### 3. Manual Input
- Some operations may prompt for manual text input
- Type or paste your text when prompted

### Operating Workflow

The standard workflow is:

1. **Input** → Select text or copy to clipboard
2. **Trigger** → Use hotkey or click menu bar icon
3. **Choose** → Select operation from menu
4. **Process** → AI processes your text
5. **Output** → Review and use the result

## Available Operations

### Writing Enhancement

#### **Improve Writing**
- **Purpose**: Enhance grammar, clarity, and style
- **Use case**: Polish drafts, fix errors, improve readability
- **Example**: "i dont think this is write" → "I don't think this is right"

#### **Fix Grammar**  
- **Purpose**: Correct grammar and spelling only
- **Use case**: Quick proofreading without style changes
- **Example**: "She don't like it" → "She doesn't like it"

#### **Continue Writing**
- **Purpose**: Extend existing text naturally
- **Use case**: Overcome writer's block, extend paragraphs
- **Example**: "The meeting was productive..." → "...we covered all agenda items and made key decisions."

### Tone and Style

#### **Make Professional**
- **Purpose**: Convert to professional tone
- **Use case**: Business emails, formal documents
- **Example**: "Hey, can you help me out?" → "Could you please assist me with this matter?"

#### **Make Casual**
- **Purpose**: Convert to casual, friendly tone  
- **Use case**: Personal messages, informal communication
- **Example**: "I would appreciate your assistance" → "I'd love your help with this!"

### Translation

#### **Translate to Chinese**
- **Purpose**: Translate any language to Chinese
- **Use case**: Communication, content localization
- **Example**: "Hello world" → "你好世界"

#### **Translate to English**
- **Purpose**: Translate any language to English
- **Use case**: Understanding foreign content
- **Example**: "Bonjour le monde" → "Hello world"

### Content Processing

#### **Summarize**
- **Purpose**: Create concise summaries
- **Use case**: Long articles, meeting notes, reports
- **Example**: Long article → "Key points: 1) Main finding, 2) Supporting evidence, 3) Conclusion"

#### **Explain**
- **Purpose**: Explain complex content simply
- **Use case**: Technical docs, academic papers
- **Example**: Complex theory → Simple, clear explanation

## Output Methods

You can configure how AI results are delivered:

### Display (Default)
- **Description**: Shows result in a popup window
- **Features**: 
  - Copy to clipboard button
  - Close button
  - Keyboard shortcut (Escape to close)
- **Best for**: Reviewing results before using them

### Clipboard
- **Description**: Copies result directly to clipboard
- **Features**: 
  - Silent operation
  - Notification alert
- **Best for**: Quick copying for pasting elsewhere

### Replace
- **Description**: Replaces selected text with AI result
- **Features**: 
  - Direct text replacement
  - Preserves original clipboard
- **Best for**: In-place text editing

### Keyboard
- **Description**: Types result directly at cursor position
- **Features**: 
  - Simulates keyboard typing
  - Works in any text field
- **Best for**: Continuous writing workflows

## Hotkeys and Shortcuts

### Default Hotkeys

| Hotkey | Action | Description |
|--------|--------|-------------|
| `⌘ + ⌥ + ⌃ + /` | Main Menu | Opens operation selection menu |
| `⌘ + ⌥ + ⌃ + I` | Improve Writing | Improve writing and paste at cursor |
| `⌘ + ⌥ + ⌃ + P` | Continue Writing | Continue writing and paste at cursor |
| `⌘ + ⌥ + ⌃ + E` | Translate to English | Translate to English and paste at cursor |
| `⌘ + ⌥ + ⌃ + C` | Translate to Chinese | Translate to Chinese and show comparison |
| `⌘ + ⌥ + ⌃ + S` | Summarize | Summarize and copy quietly |
| `⌘ + ⌥ + ⌃ + F` | Fix Grammar | Fix grammar and replace selected text |

### Menu Navigation

Within the operation menu:
- **Type to search**: Filter operations by name
- **Arrow keys**: Navigate up/down
- **Enter**: Select operation
- **Escape**: Close menu

### Result Window Controls

In the result display window:
- **Escape**: Close window
- **⌘ + C**: Copy result to clipboard (when focused)
- **Click "Copy"**: Copy to clipboard
- **Click "Close"**: Close window

## Advanced Features

### Custom Operations

You can create custom AI operations by editing your configuration:

```yaml
prompts:
  code_review:
    title: "Code Review"
    description: "Review code for improvements"
    category: "development"
    template: "Please review this code and suggest improvements:\n\n${input}"
  meeting_notes:
    title: "Format Meeting Notes"
    description: "Structure meeting notes professionally"
    category: "productivity"
    template: "Please format these meeting notes in a professional structure:\n\n${input}"
```

Then create hotkeys to use your custom prompts:

```yaml
hotkeys:
  - key: "r"
    modifiers: ["cmd", "alt", "ctrl"]
    name: "codeReview"
    description: "Review code for improvements"
    actions:
      - name: "runPrompt"
        args:
          prompt: "code_review"
      - name: "displayText"
        args:
          text: "${output}"
```

### Multiple AI Providers

Configure multiple providers for reliability:

```yaml
llm:
  defaultProvider: "gemini"
  fallbackProvider: "claude"
  providers:
    claude:
      command: "claude"
      args: ["-p"]
      enabled: true
      timeout: 30
    gemini:
      command: "gemini"
      args: ["-m", "gemini-2.5-flash", "-p"]
      enabled: true
      timeout: 30
```

If the primary provider fails, the system automatically tries the fallback.

### Batch Processing

Process multiple pieces of text efficiently:

1. **Copy multiple items** to clipboard (using clipboard manager)
2. **Use quick hotkeys** for repetitive operations
3. **Chain operations** by using results as input for next operation

### Text Preprocessing

The system automatically:
- **Trims whitespace** from input and output
- **Validates text length** to prevent oversized requests
- **Handles special characters** and formatting
- **Preserves line breaks** when appropriate

## Tips and Tricks

### Productivity Tips

1. **Use Quick Hotkeys**: Memorize frequent operation hotkeys
2. **Select Before Copy**: Always select text before copying for clipboard fallback
3. **Chain Operations**: Use AI output as input for another operation
4. **Custom Prompts**: Create operation shortcuts for repeated tasks

### Text Selection Tips

1. **Triple-click**: Select entire paragraph quickly
2. **Shift + Arrow**: Extend selection precisely  
3. **⌘ + A**: Select all text in application
4. **Double-click**: Select entire word

### Efficiency Workflows

#### Email Enhancement
1. **Draft email** quickly
2. **Select content** 
3. **Press `⌘ + ⌥ + ⌃ + I`** (improve writing)
4. **Review result**
5. **Replace or copy** improved version

#### Translation Workflow
1. **Copy foreign text**
2. **Press `⌘ + ⌥ + ⌃ + E`** (translate to English)
3. **Choose target language**
4. **Get instant translation**

#### Content Summarization
1. **Select long article/document**
2. **Press `⌘ + ⌥ + ⌃ + S`** (summarize)
3. **Get key points**
4. **Use for notes/reference**

### Troubleshooting Usage Issues

#### No Text Detected Issue
- **Solution**: Ensure text is properly selected
- **Alternative**: Copy text to clipboard first
- **Test**: Try in different applications

#### Slow Response Times
- **Check**: Internet connection
- **Verify**: CLI tool authentication
- **Consider**: Using shorter text inputs

#### Unexpected Results
- **Review**: Input text for context
- **Try**: Different operations
- **Consider**: Adding more specific prompts

### Integration with Other Tools

#### Text Editors
- Works with: VS Code, Sublime Text, Atom, Vim, Emacs
- **Tip**: Use in code comments and documentation

#### Communication Apps  
- Works with: Slack, Discord, Messages, Mail
- **Tip**: Great for professional communication

#### Web Browsers
- Works with: Safari, Chrome, Firefox
- **Tip**: Process web content and form text

#### Office Applications
- Works with: Pages, Word, Keynote, PowerPoint
- **Tip**: Enhance presentations and documents

## Getting Help

### Built-in Help
- **Menu bar icon** → Test Configuration
- **Hammerspoon Console** for error messages
- **System notifications** for status updates

### Documentation
- Check the `/docs` folder for detailed guides
- Review configuration examples
- Read troubleshooting guides

### Community Support
- GitHub Issues for bug reports
- GitHub Discussions for questions
- Community contributions welcome

---

**Happy AI-assisted writing! 🚀**