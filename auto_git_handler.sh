#!/bin/bash

# ==========================================
# Gemini Auto-Git Handler
# ==========================================

# Load Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

# Set defaults if not configured
MAX_DIFF_LINES=${MAX_DIFF_LINES:-200}
PROMPT_TEMPLATE=${PROMPT_TEMPLATE:-"You are an automated git commit message generator. Analyze the following git diff and generate a single, concise commit message adhering to Conventional Commits. Return ONLY the raw commit message string. Diff Content:"}

# 1. Check if inside a git repository
if [ ! -d .git ]; then
    # echo "📂 No git repository detected. Skipping."
    exit 0
fi

# 2. Check for changes (staged or unstaged)
if [[ -z $(git status --porcelain) ]]; then
    exit 0
fi

echo "----------------------------------------"
echo "🤖 Gemini Auto-Commit Triggered"

# Stage all changes
git add .

# 3. Get Diff for LLM Analysis
# Limit diff size to keep it fast and within token limits
DIFF_CONTENT=$(git diff --staged | head -n "$MAX_DIFF_LINES")

# 4. Construct the Prompt
PROMPT="$PROMPT_TEMPLATE
$DIFF_CONTENT"

echo "📝 Analyzing changes for context..."

# 5. Call Gemini to generate the message
# We use the 'gemini' command available in the path
COMMIT_MSG=$(gemini "$PROMPT" 2>/dev/null)

# Clean up output (remove quotes if LLM adds them)
COMMIT_MSG=$(echo "$COMMIT_MSG" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

# Security Check: Abort if LLM flagged sensitive info
if [[ "$COMMIT_MSG" == *"SECURITY_ALERT"* ]]; then
    echo "🚨 Security Alert Triggered!"
    echo "The AI detected potential sensitive information in your changes."
    echo "Message from AI: $COMMIT_MSG"
    echo "❌ Commit aborted. Staged changes have been reset."
    git reset
    exit 1
fi

# Fallback if generation failed
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="chore: auto-save work context $(date '+%Y-%m-%d %H:%M')"
fi

echo "✅ Commit Message: $COMMIT_MSG"

# 6. Commit
git commit -m "$COMMIT_MSG"
echo "🚀 Saved."
echo "----------------------------------------"
