# Installation Guide

This guide will walk you through setting up Ask AI Anywhere step by step.

## Prerequisites Check

Before starting, verify you have:

- [ ] macOS 10.12 or later
- [ ] Administrative access to your Mac
- [ ] Terminal access
- [ ] Internet connection

## Step 1: Install Hammerspoon

### Option A: Direct Download
1. Visit [hammerspoon.org](https://www.hammerspoon.org/)
2. Download the latest release
3. Drag Hammerspoon.app to your Applications folder
4. Launch Hammerspoon and grant necessary permissions

### Option B: Using Homebrew
```bash
brew install --cask hammerspoon
```

### Grant Permissions
Hammerspoon needs accessibility permissions:
1. Go to **System Preferences → Security & Privacy → Privacy**
2. Select **Accessibility** from the left sidebar
3. Click the lock to make changes
4. Add Hammerspoon if it's not already there
5. Ensure the checkbox is checked

## Step 2: Set Up AI Commands

You need at least one working AI command. Choose your preferred option:

### Option A: Gemini Setup

If you don't have the `gemini` command installed, you'll need to set it up according to Google's documentation. The command should work like this:

```bash
gemini -p "Your prompt here"
```

Test it:
```bash
gemini -p "Please respond with just 'OK' if you can see this"
```

### Option B: Claude Setup

If you don't have the `claude` command installed, you'll need to set it up according to Anthropic's documentation. The command should work like this:

```bash
claude -p "Your prompt here"  
```

Test it:
```bash
claude -p "Please respond with just 'OK' if you can see this"
```

### Verify AI Commands

At least one of these commands must return a successful response before proceeding.

## Step 3: Install Ask AI Anywhere

### Download the Script

#### Option A: Git Clone (Recommended)
```bash
cd ~/.hammerspoon
git clone <repository-url> ask-ai-anywhere
```

#### Option B: Manual Download
1. Download the ZIP file from the repository
2. Extract it to `~/.hammerspoon/ask-ai-anywhere/`

### File Structure Check

Verify your `~/.hammerspoon/` directory looks like this:
```
~/.hammerspoon/
├── init.lua (your main config)
└── ask-ai-anywhere/
    ├── init.lua
    ├── modules/
    │   ├── config.lua
    │   ├── llm.lua
    │   ├── text_operations.lua
    │   └── ui.lua
    ├── tests/
    └── README.md
```

## Step 4: Configure Hammerspoon

### Update Your Main Config

Edit `~/.hammerspoon/init.lua` to include Ask AI Anywhere:

```lua
-- Your existing Hammerspoon config...

-- Add Ask AI Anywhere
require("ask-ai-anywhere.init")

-- Your other config continues...
```

### Create Initial Config (Optional)

Create `~/.hammerspoon/ask_ai_config.json` with your preferences:

```json
{
  "llm": {
    "default_provider": "gemini",
    "gemini_command": "gemini -p",
    "claude_command": "claude -p",
    "timeout": 30
  },
  "hotkeys": {
    "main_trigger": ["cmd", "shift", "a"],
    "quick_improve": ["cmd", "shift", "i"], 
    "quick_translate": ["cmd", "shift", "t"]
  },
  "ui": {
    "show_notifications": true,
    "menu_width": 300
  }
}
```

## Step 5: Launch and Test

### Reload Hammerspoon

1. **Menu Bar Method**: Click the Hammerspoon icon in the menu bar and select "Reload Config"
2. **Keyboard Method**: Press `Cmd+Option+Ctrl+R` (if you have ReloadConfiguration spoon)
3. **Console Method**: Open Hammerspoon console and type `hs.reload()`

### Verify Installation

You should see a notification: "Ask AI Anywhere Ready!" with the hotkey combination.

### Test Basic Functionality

1. **Open any text application** (TextEdit, Notes, etc.)
2. **Type some text**: "This is a test sentence"
3. **Select the text**
4. **Press `Cmd+Shift+A`** (or your configured hotkey)
5. **Choose "Improve Writing"** from the menu
6. **Wait for the result**

If everything works, the text should be replaced with an improved version.

## Step 6: Test AI Connection

### Using the GUI
1. Press your main hotkey (`Cmd+Shift+A`)
2. Select "Settings" from the menu
3. Choose "Test LLM Connection"
4. Review the results

### Using the Console
1. Open Hammerspoon console (`Cmd+Space`, type "Hammerspoon", press Enter)
2. Type: `hs.askai.test()`
3. Press Enter and review the output

## Troubleshooting Installation

### Hammerspoon Won't Load Script

**Check console for errors:**
1. Open Hammerspoon console
2. Look for red error messages
3. Common issues:
   - File path problems
   - Syntax errors in config files
   - Missing permissions

**Solutions:**
- Verify file paths are correct
- Check JSON syntax in config files
- Ensure Hammerspoon has proper permissions

### AI Commands Not Working

**Test commands directly:**
```bash
# Test in Terminal
which gemini  # Should show path if installed
which claude  # Should show path if installed

# Test actual commands
gemini -p "test"
claude -p "test"
```

**Common solutions:**
- Restart Terminal and test commands
- Check PATH environment variable
- Reinstall AI command tools
- Verify API keys/authentication

### Hotkeys Not Responding

**Check for conflicts:**
- Try different hotkey combinations
- Check other apps aren't using the same keys
- Verify Hammerspoon accessibility permissions

**Reset hotkeys:**
1. Delete `~/.hammerspoon/ask_ai_config.json`
2. Reload Hammerspoon (will use defaults)
3. Test with default hotkeys

### Permission Issues

**Grant all necessary permissions:**
1. System Preferences → Security & Privacy → Privacy
2. Check these sections:
   - **Accessibility**: Hammerspoon should be listed and enabled
   - **Full Disk Access**: May be needed for some operations

## Customization After Installation

### Change Default Hotkeys

Edit `~/.hammerspoon/ask_ai_config.json`:
```json
{
  "hotkeys": {
    "main_trigger": ["cmd", "alt", "a"],
    "quick_improve": ["cmd", "alt", "i"],
    "quick_translate": ["cmd", "alt", "t"]
  }
}
```

### Add Custom Operations

```json
{
  "operations": [
    {"name": "Make Concise", "key": "concise", "icon": "🎯"},
    {"name": "Add Emoji", "key": "emoji", "icon": "😊"}
  ]
}
```

### Switch Default Provider

```json
{
  "llm": {
    "default_provider": "claude"
  }
}
```

## Getting Help

If you encounter issues:

1. **Check the main README.md** for usage instructions
2. **Review console output** for specific error messages  
3. **Test individual components** using the test functions
4. **Verify AI commands work** outside of Hammerspoon first

## Next Steps

Once installed successfully:

1. **Read the main README** for detailed usage instructions
2. **Customize hotkeys and operations** to your preferences
3. **Try all the text operations** to familiarize yourself
4. **Set up menu bar item** if desired (optional)

Congratulations! Ask AI Anywhere should now be working on your system. 🎉
