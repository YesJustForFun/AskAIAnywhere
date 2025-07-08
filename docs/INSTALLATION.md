# Installation Guide

This guide will walk you through setting up Ask AI Anywhere on your macOS system.

## Prerequisites

Before installing Ask AI Anywhere, ensure you have the following:

### 1. macOS Requirements
- macOS 10.12 Sierra or later
- Administrator access to install applications

### 2. Hammerspoon
Hammerspoon is required to run this application.

**Install via Homebrew (Recommended):**
```bash
brew install --cask hammerspoon
```

**Manual Installation:**
1. Download from [https://www.hammerspoon.org/](https://www.hammerspoon.org/)
2. Drag Hammerspoon.app to your Applications folder
3. Launch Hammerspoon
4. Grant necessary permissions when prompted

### 3. LLM CLI Tools

You need at least one of the following CLI tools:

#### Claude CLI (Recommended)
```bash
# Install claude CLI (follow official Anthropic documentation)
# Example installation methods:
pip install claude-cli
# or
npm install -g @anthropic-ai/claude-cli
# or download from official release

# Authenticate
claude auth login
```

#### Gemini CLI (Alternative)
```bash
# Install gemini CLI (follow official Google documentation)
# Example installation methods:
pip install google-generativeai
# or
npm install -g @google/generative-ai-cli
# or download from official release

# Authenticate
gemini auth login
```

#### Verify CLI Installation
Test your CLI tools:
```bash
# Test Claude
echo "Hello, please respond with 'OK'" | claude -p

# Test Gemini
echo "Hello, please respond with 'OK'" | gemini -p
```

You should see "OK" or similar response from each tool.

## Installation Steps

### Step 1: Download Ask AI Anywhere

**Option A: Git Clone (Recommended)**
```bash
cd ~/.hammerspoon
git clone https://github.com/your-username/ask-ai-anywhere.git
```

**Option B: Manual Download**
1. Download the ZIP file from the repository
2. Extract to `~/.hammerspoon/ask-ai-anywhere/`

### Step 2: Configure Hammerspoon

Edit your Hammerspoon configuration file:
```bash
# Open the Hammerspoon init file
open ~/.hammerspoon/init.lua
```

Add this line to the file:
```lua
-- Load Ask AI Anywhere
require('ask-ai-anywhere.init')
```

If the file doesn't exist, create it with just the above content.

### Step 3: Reload Hammerspoon

1. **Open Hammerspoon app** from Applications or Spotlight
2. **Reload configuration**:
   - Click the Hammerspoon menu bar icon
   - Select "Reload Config"
   - Or press `⌘ + R` in the Hammerspoon console

### Step 4: Grant Permissions

Hammerspoon will request several permissions:

1. **Accessibility Access**:
   - Go to System Preferences → Security & Privacy → Privacy → Accessibility
   - Check the box next to Hammerspoon

2. **Screen Recording** (if needed):
   - Go to System Preferences → Security & Privacy → Privacy → Screen Recording
   - Check the box next to Hammerspoon

3. **Input Monitoring**:
   - Go to System Preferences → Security & Privacy → Privacy → Input Monitoring
   - Check the box next to Hammerspoon

### Step 5: Test Installation

1. **Open any text editor** (TextEdit, Notes, etc.)
2. **Type some text** and select it
3. **Press `⌘ + Shift + /`** (default hotkey)
4. **Choose "Improve Writing"** from the menu
5. **Wait for the result** to appear

If you see the AI response, installation is successful! 🎉

## Configuration

### Basic Configuration

Create a custom configuration file:
```bash
touch ~/.hammerspoon/ask-ai-config.json
```

Add your preferences:
```json
{
  "llm": {
    "defaultProvider": "claude",
    "fallbackProvider": "gemini"
  },
  "ui": {
    "outputMethod": "display"
  },
  "hotkeys": {
    "mainMenu": {
      "key": "/",
      "modifiers": ["cmd", "shift"]
    }
  }
}
```

### Advanced Configuration

For advanced configuration options, see [CONFIGURATION.md](CONFIGURATION.md).

## Verification

### Test Checklist

- [ ] Hammerspoon is installed and running
- [ ] At least one LLM CLI tool is installed and authenticated
- [ ] Ask AI Anywhere loads without errors
- [ ] Hotkeys are working (try `⌘ + Shift + /`)
- [ ] Text selection works in different applications
- [ ] AI operations complete successfully
- [ ] Results are displayed/copied correctly

### Common Installation Issues

#### Issue: "Module not found"
**Solution**: Ensure the ask-ai-anywhere folder is in `~/.hammerspoon/`

#### Issue: "Command not found" errors
**Solution**: 
1. Verify CLI tools are installed: `which claude` or `which gemini`
2. Check PATH in terminal: `echo $PATH`
3. Restart Hammerspoon after installing CLI tools

#### Issue: Permission denied errors
**Solution**: Grant all required permissions in System Preferences → Security & Privacy

#### Issue: Hotkeys not working
**Solution**: 
1. Check for conflicts with other applications
2. Try different hotkey combinations
3. Verify Hammerspoon has Input Monitoring permission

### Diagnostic Commands

Run these in Terminal to diagnose issues:

```bash
# Check Hammerspoon installation
ls -la ~/.hammerspoon/

# Check Ask AI Anywhere installation
ls -la ~/.hammerspoon/ask-ai-anywhere/

# Test CLI tools
claude --version
gemini --version

# Check authentication
claude auth status
gemini auth status
```

## Updating

### Automatic Updates (Git)
```bash
cd ~/.hammerspoon/ask-ai-anywhere
git pull origin main
```

### Manual Updates
1. Download the latest version
2. Replace the old files
3. Reload Hammerspoon configuration

## Uninstallation

To remove Ask AI Anywhere:

1. **Remove from Hammerspoon config**:
   ```bash
   # Edit ~/.hammerspoon/init.lua
   # Remove or comment out the require line
   ```

2. **Delete the files**:
   ```bash
   rm -rf ~/.hammerspoon/ask-ai-anywhere/
   ```

3. **Reload Hammerspoon**:
   - Click Hammerspoon menu bar icon → "Reload Config"

## Next Steps

- Read the [User Guide](USER_GUIDE.md) for detailed usage instructions
- Explore [Configuration Options](CONFIGURATION.md) for customization
- Check out [Advanced Usage](ADVANCED_USAGE.md) for power user features

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review the [FAQ](FAQ.md)
3. Open an issue on GitHub with:
   - Your macOS version
   - Hammerspoon version
   - CLI tool versions
   - Error messages
   - Steps to reproduce the issue