#!/bin/bash

# ==========================================
# Gemini Auto-Commit Installer (Smart Shell Detect)
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDLER_SCRIPT="$SCRIPT_DIR/auto_git_handler.sh"

# 1. Find binary
GEMINI_BIN_PATH=$(type -P gemini || which gemini)

if [ -z "$GEMINI_BIN_PATH" ]; then
    echo "❌ Error: Could not find 'gemini' executable in PATH."
    exit 1
fi

echo "🔍 Found Gemini binary at: $GEMINI_BIN_PATH"

if [ ! -f "$HANDLER_SCRIPT" ]; then
    echo "❌ Error: Could not find 'auto_git_handler.sh'"
    exit 1
fi

# 2. Define Wrapper
CONFIG_BLOCK="
# ==========================================
# Gemini CLI Wrapper (Auto-Commit)
# Added by install script on $(date)
# ==========================================
gemini() {
    \"$GEMINI_BIN_PATH\" \"\$@\"
    local exit_code=\\$?\

    if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
        if [ -f \"$HANDLER_SCRIPT\" ]; then
            bash \"$HANDLER_SCRIPT\"
        fi
    fi
    return \\$exit_code
}
"

# 3. Detect Shell Correctly
# We use ps to find the name of the parent process (the shell)
CURRENT_SHELL=$(ps -p $$ -o comm=) 
# If that fails or is just 'bash' (from the script itself), we check parent of parent or just assume based on user invoking it.
# Simpler: check if $BASH_VERSION is set (since we are running this with bash, it always is). 
# We rely on the USER's interactive shell.

# Strategy: Check if the user passed an argument, otherwise guess.
# Since the script is run via 'bash install.sh', $0 is bash. 
# We'll check the config files existence and prioritize.

if [ -n "$ZSH_VERSION" ]; then
    TARGET_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    # We are running IN bash, but are we configuring FOR bash?
    # If the user is in a bash shell (ps check), use bash profile.
    PARENT_SHELL=$(ps -o comm= -p $PPID)
    if [[ "$PARENT_SHELL" == *"zsh"* ]]; then
         TARGET_FILE="$HOME/.zshrc"
    else
         # Default to bash profile if parent is bash or we can't tell
         if [ -f "$HOME/.bash_profile" ]; then
            TARGET_FILE="$HOME/.bash_profile"
         else
            TARGET_FILE="$HOME/.bashrc"
         fi
    fi
fi

echo "🎯 Targeted Config File: $TARGET_FILE"

# 4. Clean & Install
if grep -q "gemini() {" "$TARGET_FILE"; then
    echo "🔄 Updating existing wrapper in $TARGET_FILE..."
    # Simple backup
    cp "$TARGET_FILE" "${TARGET_FILE}.bak_gemini"
    # Remove old block (basic filter)
    grep -v "gemini() {" "$TARGET_FILE" | grep -v "command gemini" | grep -v "Gemini CLI Wrapper" | grep -v "gemini-cli/auto-commit-feature" | grep -v "$GEMINI_BIN_PATH" > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
fi

echo "$CONFIG_BLOCK" >> "$TARGET_FILE"
echo "✅ Installed to $TARGET_FILE"
echo ""
echo "👉 Run this to apply:"
echo "   source $TARGET_FILE"
