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

# 2. Define Hooks (No more function wrapping)

# ZSH Implementation: uses preexec to flag, precmd to execute
# This avoids shadowing the binary and infinite loops
ZSH_CONFIG_BLOCK="
# ==========================================
# Gemini Auto-Commit Hooks (Zsh)
# Added by install script on $(date)
# ==========================================
typeset -g __GEMINI_AC_PENDING=0

gemini_ac_preexec() {
    # Check if the command being executed starts with 'gemini'
    # \$1 is the full command string
    local cmd_first_word=\"\${1%% *}\"
    if [[ \"\$cmd_first_word\" == \"gemini\" ]]; then
        __GEMINI_AC_PENDING=1
    else
        __GEMINI_AC_PENDING=0
    fi
}

gemini_ac_precmd() {
    if [[ \"\$__GEMINI_AC_PENDING\" -eq 1 ]]; then
        __GEMINI_AC_PENDING=0
        if [ -f \"$HANDLER_SCRIPT\" ]; then
            bash \"$HANDLER_SCRIPT\"
        fi
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec gemini_ac_preexec
add-zsh-hook precmd gemini_ac_precmd
"

# BASH Implementation: uses PROMPT_COMMAND
BASH_CONFIG_BLOCK="
# ==========================================
# Gemini Auto-Commit Hooks (Bash)
# Added by install script on $(date)
# ==========================================
gemini_ac_prompt_command() {
    # Get the last history command
    # history 1 returns: '  123  gemini foo'
    local last_hist=\$(history 1)
    # Remove leading numbers and spaces
    local last_cmd=\$(echo \"\$last_hist\" | sed 's/^[ ]*[0-9]*[ ]*//')
    local cmd_first_word=\"\${last_cmd%% *}\"
    
    if [[ \"\$cmd_first_word\" == \"gemini\" ]]; then
         if [ -f \"$HANDLER_SCRIPT\" ]; then
            bash \"$HANDLER_SCRIPT\"
        fi
    fi
}

# Append to PROMPT_COMMAND if not already there
if [[ ! \"\$PROMPT_COMMAND\" =~ gemini_ac_prompt_command ]]; then
    PROMPT_COMMAND=\"gemini_ac_prompt_command;\$PROMPT_COMMAND\"
fi
"

# 4. Clean & Install
if grep -q "gemini() {" "$TARGET_FILE" || grep -q "Gemini Auto-Commit Hooks" "$TARGET_FILE"; then
    echo "🔄 Removing old configuration from $TARGET_FILE..."
    cp "$TARGET_FILE" "${TARGET_FILE}.bak_gemini"
    
    # Remove old wrapper function style
    grep -v "gemini() {" "$TARGET_FILE" | \
    grep -v "command gemini" | \
    grep -v "Gemini CLI Wrapper" | \
    grep -v "gemini-cli/auto-commit-feature" | \
    grep -v "$GEMINI_BIN_PATH" | \
    grep -v "local exit_code=" | \
    grep -v "return \$exit_code" | \
    grep -v "Gemini Auto-Commit Hooks" | \
    grep -v "__GEMINI_AC_PENDING" | \
    grep -v "gemini_ac_preexec" | \
    grep -v "gemini_ac_precmd" | \
    grep -v "add-zsh-hook preexec gemini_ac_preexec" | \
    grep -v "add-zsh-hook precmd gemini_ac_precmd" | \
    grep -v "gemini_ac_prompt_command" \
    > "${TARGET_FILE}.tmp" && mv "${TARGET_FILE}.tmp" "$TARGET_FILE"
fi

echo "Installing hooks..."

if [[ "$TARGET_FILE" == *".zshrc" ]]; then
    echo "$ZSH_CONFIG_BLOCK" >> "$TARGET_FILE"
else
    echo "$BASH_CONFIG_BLOCK" >> "$TARGET_FILE"
fi

echo "✅ Installed to $TARGET_FILE"
echo ""
echo "👉 Run this to apply:"
echo "   source $TARGET_FILE"
