# Gemini Auto-Commit Feature

This project provides automated Git commit functionality for the Gemini CLI workflow. It uses Gemini (LLM) to generate semantic commit messages based on file changes.

## Features

- **Smart Commit Messages**: Analyzes `git diff` to generate meaningful Conventional Commits (e.g., `feat:`, `docs:`, `fix:`).
- **Zero-Config Global Hook**: Can be integrated into your shell to automatically commit work when you exit the Gemini CLI.
- **Auto-Initialization**: Automatically initializes a git repository if one doesn't exist.
- **Continuous Monitoring**: Includes a standalone script for real-time monitoring of changes.

## Installation

### 1. Script Setup
The core scripts are located in this directory. You can keep them here or move them to a central location like `~/.gemini/scripts/`.

- `auto_git_handler.sh`: The one-shot handler script (used by the shell hook).
- `git_monitor.sh`: A loop-based script that runs continuously.

Make sure they are executable:
```bash
chmod +x auto_git_handler.sh git_monitor.sh
```

### 2. Shell Hook Configuration (Recommended)
To enable "Auto-Commit on Exit", add the following wrapper function to your shell configuration file (e.g., `~/.zshrc` or `~/.bashrc`).

Update the path to point to where you saved `auto_git_handler.sh`.

```bash
# ==========================================
# Gemini Auto-Commit Hook
# ==========================================
function gemini() {
    # 1. Run the original gemini program (use absolute path to avoid recursion)
    # Check your actual path with: type -a gemini
    /opt/homebrew/bin/gemini "$@"
    
    # 2. Trigger auto-commit check upon exit
    echo -e "\n🤖 Gemini Session Ended. Checking for changes..."
    # Replace with the actual path to your script
    bash ~/gemini-cli/auto-commit-feature/auto_git_handler.sh
}
```

Reload your shell config:
```bash
source ~/.zshrc
```

## Usage

### Mode 1: Auto-Commit on Exit (Hook)
Once the shell hook is configured, simply use `gemini` as usual.
1. Work in any directory.
2. Exit the CLI (`/exit` or `Ctrl+C`).
3. The script will automatically check for changes, add them, and commit with an AI-generated message.

### Mode 2: Continuous Monitor
If you prefer a background process that watches for changes while you work (independent of the CLI session):

```bash
./git_monitor.sh
```
This script checks for changes every 10 seconds. Press `Ctrl+C` to stop it.

## Troubleshooting

- **"gemini command not found" inside the script**: Ensure the `gemini` CLI tool is in your system PATH.
- **No commit happened**:
    - The script skips if there are no file changes.
    - Check if you are in a git repo (though the script tries to `git init`).
- **Hook not firing**: Verify that `gemini` is recognized as a function:
    ```bash
    type gemini
    # Output should be: gemini is a shell function
    ```
