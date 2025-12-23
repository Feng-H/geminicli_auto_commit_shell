# Gemini Auto-Commit

> [Chinese Version](./README.md)

This project is a Shell plugin that seamlessly integrates **automatic Git commits** for the `gemini` command-line tool.
When you finish code generation or Q&A using `gemini`, this plugin automatically detects file changes in the current directory, uses the Gemini model to generate commit messages complying with Conventional Commits specifications, and executes the commit automatically.

## Core Features

- **Seamless Integration (Shell Hooks)**: No need to change your usage habits. Just run `gemini` commands as usual, and the plugin takes over automatically after the operation.
- **Smart Commit Messages**: Analyzes code changes based on `git diff` and automatically generates standardized Commit Messages in formats like `feat:`, `fix:`, etc.
- **Auto Initialization**: Configurable to automatically execute `git init` if the current directory is not a Git repository.
- **Security Check**: Built-in basic security filtering to prevent sensitive information like API Keys from being written into commit records.

## Directory Structure

- `install.sh`: **Installation Script**. Automatically detects Shell (Bash/Zsh) and configures Hooks.
- `auto_git_handler.sh`: **Core Logic Script**. Performs Git status detection, Diff analysis, LLM invocation, and commit operations.
- `config.env`: **Configuration File**. Sets language, Diff length limits, etc.

## Quick Start

### 1. Prerequisites

Ensure the following tools are installed on your system and available in PATH:

*   **Gemini CLI**: You must have the `gemini` command-line tool installed (Installation guide: https://geminicli.com).
    *   Verification: Run `type gemini` or `which gemini` in the terminal; it should output the path.
*   **Git**: Version recommended >= 2.0.

### 2. Installation

Run the one-click installation script in the current directory:

```bash
bash install.sh
```

The script will automatically detect your Shell type (`zsh` or `bash`) and append the necessary Hook configurations to `~/.zshrc` or `~/.bash_profile` / `~/.bashrc`.

**After installation, be sure to restart your terminal or manually load the configuration:**

```bash
# If you are a Zsh user
source ~/.zshrc

# If you are a Bash user
source ~/.bash_profile
# OR
source ~/.bashrc
```

### 3. Usage

After successful installation, you don't need to learn new commands.

1.  In any Git project directory, run any Gemini command:
    ```bash
    gemini "Write a Hello World in Python for me"
    ```
    Or enter interactive mode:
    ```bash
    gemini
    # ... conversations in interactive mode ...
    # ... exit interactive mode ...
    ```

2.  **Auto Trigger**:
    When the `gemini` command finishes execution (or interactive mode exits), the Shell Hook automatically triggers `auto_git_handler.sh`.

3.  **Auto Commit**:
    *   The script detects file changes.
    *   The script calls `gemini` to generate a Commit Message.
    *   The script executes `git add .` and `git commit`.

## Configuration

You can edit the `config.env` file to adjust behavior:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `COMMIT_LANGUAGE` | `zh-CN` | Language for commit messages. Options: `en` (English) or `zh-CN` (Chinese). |
| `AUTO_INIT` | `true` | Whether to automatically initialize if the current directory is not a Git repository. |
| `MAX_DIFF_LINES` | `200` | Maximum number of Diff lines sent to AI for analysis (to prevent excessive Token usage). |
| `PROMPT_TEMPLATE` | (Built-in) | Custom prompt template (optional). |

## How It Works

This plugin does not replace or overwrite the native `gemini` command via `alias`. Instead, it leverages the Shell's **Hooks** mechanism, ensuring high compatibility and stability.

- **Zsh**: Uses `preexec` to record commands and `precmd` to trigger checks after commands finish.
- **Bash**: Uses `PROMPT_COMMAND` to check the previous command before printing the prompt each time.

## Troubleshooting

- **Auto-commit not triggered?**
    *   Check if you have executed `source ~/.zshrc` (or bash config file).
    *   Check if there are file changes in the current directory (`git status`).
    *   Ensure `auto_git_handler.sh` has execution permissions (`chmod +x auto_git_handler.sh`; the installation script usually handles this).
- **Sensitivity Alert**
    *   If AI detects sensitive information like keys in the Diff, it will automatically terminate the commit and execute `git reset` (unstage). Please check your code before committing manually.
