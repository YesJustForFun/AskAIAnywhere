### Refactoring Plan: `alfred-ask-ai-anywhere-workflow` to Hammerspoon

**Objective:** Create a simple and easy-to-use Hammerspoon script to ask AI (Gemini or Claude) questions from anywhere on the system, replacing the old Alfred workflow.

**Phase 1: Project Setup & Core Logic**

1.  **Initialize Project:**
    *   [x] Create the initial project structure including `init.lua`, `config.lua`, and a `.gitignore` file.
    *   [x] Initialize a Git repository in the `ask-ai-hammerspoon` directory.

2.  **Configuration:**
    *   [x] Implement `config.lua` to manage settings like AI provider and hotkeys.
    *   [x] Load the configuration in `init.lua`.

3.  **Core Functionality:**
    *   [x] Set up a hotkey to trigger the workflow.
    *   [x] Create a UI for user input.
    *   [x] Get the selected text from the current application.
    *   [x] Execute the appropriate AI command (`gemini -p` or `claude -p`).
    *   [x] Display the AI's response.
    *   [ ] Create a UI for user input.
    *   [ ] Get the selected text from the current application.
    *   [ ] Execute the appropriate AI command (`gemini -p` or `claude -p`).
    *   [ ] Display the AI's response.

**Phase 2: Testing & Documentation**

4.  **Testing:**
    *   [x] Manual testing within Hammerspoon.

5.  **Documentation:**
    *   [x] Create a `README.md` with setup and usage instructions.
    *   [x] Add code comments for clarity.