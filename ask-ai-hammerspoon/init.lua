-- init.lua
-- Main entry point for the Ask AI Hammerspoon script.

print("🤖 Ask AI Anywhere: Starting initialization...")

-- Get the directory of this script and set up module paths
local scriptPath = debug.getinfo(1, "S").source:match("@(.*)init%.lua$")
print("🤖 Script path detected: " .. (scriptPath or "nil"))

if scriptPath then
    package.path = package.path .. ";" .. scriptPath .. "?.lua"
    print("🤖 Added module path: " .. scriptPath .. "?.lua")
end

-- Load configuration from config.lua
local config = require("config")

-- Load the core AI interaction logic
local ask_ai_core = require("ask_ai_core")

--- Bind the hotkey to trigger the AI prompt.
--- When the hotkey is pressed, it gets selected text (if any),
--- prompts the user for input, and then calls the ask_ai_core.askAI function.
hs.hotkey.bind(config.hotkey, function()
    -- Get currently selected text to pre-fill the input prompt
    local selectedText = hs.selectedText()

    -- Display an input prompt to the user
    hs.input.getText("Ask a question...", selectedText, function(result)
        -- If the user provides input (not empty or cancelled)
        if result and result ~= "" then
            -- Call the core AI function with the user's query
            ask_ai_core.askAI(result)
        end
    end)
end)
