-- ask_ai_core.lua
-- This module contains the core logic for interacting with the AI CLI tools.

local hs = require("hs")
local config = require("config")

local M = {}

--- askAI(query)
--- Sends a query to the configured AI provider and displays the response.
--- @param query string The question or prompt to send to the AI.
function M.askAI(query)
    local provider = config.default_provider
    local command = provider
    local args = {"-p", query}

    -- Execute the AI command in a new task
    hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            -- Display the AI's response on success
            hs.alert.show(stdOut)
        else
            -- Display an error message on failure
            hs.alert.show("Error: " .. stdErr)
        end
    end, {command, unpack(args)}):start()
end

return M