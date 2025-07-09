# Ask AI Hammerspoon Script

This Hammerspoon script allows you to quickly ask questions to Gemini or Claude from anywhere on your macOS system using a customizable hotkey.

## Features

*   **Quick AI Access:** Trigger a prompt with a hotkey to ask questions to your preferred LLM.
*   **Selected Text Integration:** Automatically pre-fills the prompt with any selected text.
*   **Configurable:** Easily switch between Gemini and Claude, and customize the hotkey.

## Prerequisites

*   **Hammerspoon:** Make sure you have Hammerspoon installed and running. You can download it from [https://www.hammerspoon.org/](https://www.hammerspoon.org/).
*   **`gemini` and/or `claude` CLI tools:** These tools should be installed and accessible in your system's PATH. You can typically install them via `pip` or other package managers depending on the tool.
    *   For `gemini`: Ensure you have the `gemini` CLI tool installed and configured to use `gemini -p` for prompts.
    *   For `claude`: Ensure you have the `claude` CLI tool installed and configured to use `claude -p` for prompts.

## Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository_url> ask-ai-hammerspoon
    ```

2.  **Move to Hammerspoon Configuration:**

    Move the `ask-ai-hammerspoon` directory into your Hammerspoon configuration directory. By default, this is `~/.hammerspoon/`.

    ```bash
    mv ask-ai-hammerspoon ~/.hammerspoon/
    ```

3.  **Reload Hammerspoon Configuration:**

    After moving the directory, reload your Hammerspoon configuration. You can do this by clicking the Hammerspoon icon in your menubar and selecting "Reload Config".

## Usage

1.  **Trigger the Prompt:**

    Press the configured hotkey (default: `Cmd + Alt + C`).

2.  **Enter Your Question:**

    A prompt will appear. If you had text selected, it will be pre-filled. Type your question or modify the pre-filled text.

3.  **Get AI Response:**

    Press `Enter` to send your question to the configured AI. The response will appear as a Hammerspoon alert.

## Configuration

You can customize the script by editing `~/.hammerspoon/ask-ai-hammerspoon/config.lua`:

```lua
-- Configuration for Ask AI
return {
    -- Default AI provider ('gemini' or 'claude')
    default_provider = 'gemini',

    -- Hotkey to trigger the AI prompt
    hotkey = {'cmd', 'alt', 'c'},
}
```

*   `default_provider`: Change to `'claude'` if you prefer to use Claude by default.
*   `hotkey`: Modify the hotkey combination. For example, `{'ctrl', 'alt', 'g'}` for Control + Alt + G.

## Troubleshooting

*   **AI command not found:** Ensure that `gemini` and/or `claude` CLI tools are correctly installed and their executables are in your system's PATH.
*   **Hammerspoon alerts not appearing:** Check the Hammerspoon console (`Hammerspoon -> Open Console`) for any errors.
*   **Hotkey not working:** Ensure no other application is using the same hotkey. Try changing the hotkey in `config.lua`.

## Contributing

Feel free to contribute to this project by submitting issues or pull requests.