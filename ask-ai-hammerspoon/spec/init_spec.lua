describe("askAI function", function()
    local config = require("config")

    beforeEach(function()
        _G.hs = {
            task = {
                new = function(command, callback, args)
                    _G.mock_task_command = command
                    _G.mock_task_args = args
                    _G.mock_task_callback = callback
                    return {start = function() end}
                end
            },
            alert = {
                show = function(message)
                    _G.mock_alert_message = message
                end
            }
        }
    end)

    afterEach(function()
        _G.hs = nil
        _G.mock_task_command = nil
        _G.mock_task_args = nil
        _G.mock_task_callback = nil
        _G.mock_alert_message = nil
    end)

    it("should call the correct AI command with the query", function()
        local query = "What is the capital of France?"
        local expected_command = "/usr/bin/env"
        local expected_args = {config.default_provider, "-p", query}

        local ask_ai_core = require("ask_ai_core")
        ask_ai_core.askAI(query)

        assert.are.equal(expected_command, _G.mock_task_command)
        assert.are.same(expected_args, _G.mock_task_args)
    end)

    it("should display the AI response on success", function()
        local query = "Hello"
        local mock_stdout = "Hi there!"

        local ask_ai_core = require("ask_ai_core")
        ask_ai_core.askAI(query)

        -- Simulate task completion
        _G.mock_task_callback(0, mock_stdout, "")

        assert.are.equal(mock_stdout, _G.mock_alert_message)
    end)

    it("should display an error message on failure", function()
        local query = "Error test"
        local mock_stderr = "Command not found"

        local ask_ai_core = require("ask_ai_core")
        ask_ai_core.askAI(query)

        -- Simulate task completion with error
        _G.mock_task_callback(1, "", mock_stderr)

        assert.are.equal("Error: " .. mock_stderr, _G.mock_alert_message)
    end)
end)