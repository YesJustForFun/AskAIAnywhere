# Troubleshooting Guide

This guide helps you diagnose and fix common issues with Ask AI Anywhere.

## Quick Diagnostics

First, run the built-in test to identify issues:

```lua
-- In Hammerspoon console
hs.askai.test()
```

This will check:
- Configuration loading
- LLM provider connectivity  
- Basic functionality

## Common Issues

### 1. Hotkeys Not Working

**Symptoms:**
- Pressing configured hotkeys does nothing
- No menu appears when hotkey is pressed

**Possible Causes & Solutions:**

#### Accessibility Permissions Missing
1. Go to **System Preferences → Security & Privacy → Privacy**
2. Select **Accessibility** from the sidebar
3. Ensure Hammerspoon is listed and checked
4. If not listed, click `+` and add Hammerspoon
5. Restart Hammerspoon

#### Hotkey Conflicts
1. Try different hotkey combinations
2. Check other running applications for conflicts
3. Temporarily disable other hotkey apps to test

#### Configuration Issues
```lua
-- Check current hotkeys in console
print(hs.inspect(hs.askai.config.get("hotkeys")))

-- Reset to defaults
hs.askai.config.set("hotkeys.main_trigger", {"cmd", "shift", "a"})
hs.askai.reload()
```

### 2. AI Providers Not Working

**Symptoms:**
- "No AI providers working" error
- Long delays followed by timeout errors
- "Command not found" errors

**Diagnostic Steps:**

#### Test Commands Directly
```bash
# Test in Terminal
gemini -p "Hello, please respond with 'OK'"
claude -p "Hello, please respond with 'OK'"
```

#### Check Command Paths
```bash
which gemini
which claude
echo $PATH
```

#### Common Solutions

**Commands Not Found:**
- Install the missing AI command tools
- Ensure they're in your PATH
- Restart Terminal and test again

**Authentication Issues:**
- Check API keys are properly configured
- Verify account access and quotas
- Re-authenticate if necessary

**Network Issues:**
- Check internet connection
- Try different network (VPN, cellular hotspot)
- Check firewall settings

#### Increase Timeout
```lua
-- In Hammerspoon console
hs.askai.config.set("llm.timeout", 60)  -- 60 seconds
hs.askai.reload()
```

### 3. Text Selection Issues

**Symptoms:**
- "No text selected or in clipboard" error
- Wrong text being processed
- Selection not detected properly

**Solutions:**

#### Manual Text Input
1. Copy text to clipboard first
2. Then trigger the AI operation
3. Script will use clipboard if no selection detected

#### Application-Specific Issues
- Some apps don't support standard copy operations
- Try using `Cmd+C` to copy before triggering hotkey
- Test in standard apps (TextEdit, Notes) first

#### Clipboard Interference
- Other clipboard managers might interfere
- Temporarily disable other clipboard tools
- Clear clipboard and try again

### 4. Menu Not Appearing

**Symptoms:**
- Hotkey pressed but no chooser menu shows
- Menu appears empty or malformed

**Solutions:**

#### Recreate UI Components
```lua
-- In Hammerspoon console
hs.askai.ui.cleanup()
hs.askai.ui.init()
```

#### Check Console for Errors
1. Open Hammerspoon console
2. Look for red error messages
3. Try triggering hotkey while watching console

#### Reset Configuration
```lua
-- Reset UI settings
hs.askai.config.set("ui.menu_width", 300)
hs.askai.config.set("ui.show_notifications", true)
hs.askai.reload()
```

### 5. Slow Performance

**Symptoms:**
- Long delays before operations start
- Timeouts on normally working commands
- System becomes unresponsive

**Solutions:**

#### Optimize Configuration
```lua
-- Reduce timeout for faster failure
hs.askai.config.set("llm.timeout", 15)

-- Disable notifications to reduce overhead
hs.askai.config.set("ui.show_notifications", false)
```

#### Check System Resources
- Monitor CPU usage during operations
- Check available memory
- Close unnecessary applications

#### Switch Providers
- Try different AI provider if one is slow
- Test both Gemini and Claude performance

### 6. Installation Issues

**Symptoms:**
- Script won't load at all
- Syntax errors in console
- Missing files or modules

**Solutions:**

#### Verify File Structure
```bash
ls -la ~/.hammerspoon/ask-ai-anywhere/
# Should show: init.lua, modules/, tests/, docs/
```

#### Check Main Config
Ensure `~/.hammerspoon/init.lua` contains:
```lua
require("ask-ai-anywhere.init")
```

#### Reload Hammerspoon
1. **Menu bar:** Click Hammerspoon icon → Reload Config
2. **Console:** Type `hs.reload()`
3. **Hotkey:** `Cmd+Option+Ctrl+R` (if configured)

#### Check for Syntax Errors
```lua
-- Test loading individual modules
require("ask-ai-anywhere.modules.config")
require("ask-ai-anywhere.modules.llm")
-- etc.
```

## Advanced Diagnostics

### Enable Debug Logging

```lua
-- Enable verbose output
hs.askai.config.set("debug", true)
hs.askai.reload()

-- Check configuration
print(hs.inspect(hs.askai.config.current))
```

### Test Individual Components

```lua
-- Test configuration
local config = require("ask-ai-anywhere.modules.config")
config.load()
print("Config loaded:", config.get("llm.default_provider"))

-- Test LLM directly
local llm = require("ask-ai-anywhere.modules.llm") 
local success, result = llm.call("gemini", "Hello")
print("LLM test:", success, result)

-- Test text operations
local textOps = require("ask-ai-anywhere.modules.text_operations")
local text, source = textOps.getInputText()
print("Input text:", text, "from", source)
```

### Monitor System Calls

```bash
# Monitor file access
sudo fs_usage -w -f filesystem Hammerspoon

# Monitor network calls
sudo lsof -i -P | grep -i hammerspoon
```

## Error Messages Reference

### "Unknown provider: X"
- Provider name typo in configuration
- Unsupported provider specified
- Fix: Use "gemini" or "claude" only

### "Command timed out after X seconds"
- AI command taking too long
- Network connectivity issues
- Fix: Increase timeout or check connection

### "Command not found"
- AI command not installed or not in PATH
- Fix: Install/reinstall AI command tools

### "No text provided"
- No text selected or in clipboard
- Fix: Select text first or copy to clipboard

### "Failed to connect to X"
- Network issues
- Authentication problems
- Fix: Check internet and API credentials

## Getting More Help

### Console Output
Always check the Hammerspoon console first:
1. Open Hammerspoon menu → Console
2. Clear console (Cmd+K)
3. Reproduce the issue
4. Look for error messages

### System Information
When reporting issues, include:
- macOS version: `sw_vers`
- Hammerspoon version: Check About menu
- AI command versions: `gemini --version`, `claude --version`
- Configuration: `hs.inspect(hs.askai.config.current)`

### Clean Reinstall

If all else fails:
```bash
# Backup configuration
cp ~/.hammerspoon/ask_ai_config.json ~/ask_ai_config_backup.json

# Remove installation
rm -rf ~/.hammerspoon/ask-ai-anywhere/

# Reinstall following INSTALL.md
# Restore configuration
cp ~/ask_ai_config_backup.json ~/.hammerspoon/ask_ai_config.json
```

### Community Support

1. Check existing issues in the repository
2. Search discussions for similar problems
3. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Console output
   - System information

## Prevention Tips

### Regular Maintenance
- Update AI command tools regularly
- Test connection periodically
- Keep Hammerspoon updated
- Backup your configuration

### Best Practices
- Use stable hotkey combinations
- Don't modify core files directly
- Use configuration files for customization
- Test changes in small increments

### Monitoring
- Check console occasionally for warnings
- Monitor performance with Activity Monitor
- Keep an eye on network usage during AI operations
