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

# 3. Detect Shell Correctly
# Check if a target file is provided as an argument
if [ -n "$1" ]; then
    TARGET_FILE="$1"
elif [ -n "$ZSH_VERSION" ]; then
    TARGET_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"zsh"* ]]; then
    TARGET_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bash_profile" ]; then
        TARGET_FILE="$HOME/.bash_profile"
    else
        TARGET_FILE="$HOME/.bashrc"
    fi
else
    # Fallback
    TARGET_FILE="$HOME/.zshrc"
fi

echo "🎯 Targeted Config File: $TARGET_FILE"

# 2. Define Wrapper (Fixing escapes)
# We use single quotes for the inner logic to avoid excessive escaping hell
CONFIG_BLOCK="
# ==========================================
# Gemini CLI Wrapper (Auto-Commit)
# Added by install script on $(date)
# ==========================================
gemini() {
    \"$GEMINI_BIN_PATH\" \"\$@\"
    local exit_code=\$?

    if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
        if [ -f \"$HANDLER_SCRIPT\" ]; then
            bash \"$HANDLER_SCRIPT\"
        fi
    fi
    return \$exit_code
}
"

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
