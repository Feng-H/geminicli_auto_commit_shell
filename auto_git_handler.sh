#!/bin/bash

# ==========================================
# Gemini Auto-Git Handler
# ==========================================

# 1. Check if inside a git repository
if [ ! -d .git ]; then
    echo "📂 No git repository detected."
    # Check if directory is not empty
    if [ "$(ls -A .)" ]; then
        echo "✨ Initializing new Git repository..."
        git init
        # First commit needs to allow empty just in case, but usually we have files
    else
        echo "Directory is empty. Skipping git init."
        exit 0
    fi
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
# Limit diff size to ~200 lines to keep it fast and within token limits
DIFF_CONTENT=$(git diff --staged | head -n 200)

# 4. Construct the Prompt (Optimized for Meaningful Context)
PROMPT="You are an expert developer assistant. 
Review the following 'git diff' from the user's current project.
Generate a SINGLE, concise git commit message adhering to Conventional Commits (e.g., feat:, docs:, fix:, chore:).

CRITICAL REQUIREMENTS:
1. Do NOT write generic messages like 'update file' or 'modify text'.
2. FOCUS ON THE CONTENT: What knowledge was added? What logic changed?
3. If it's a resume/markdown file, mention specifically what section or info was updated.
4. Return ONLY the raw commit message string. No quotes, no markdown, no explanations.

Diff Content:
$DIFF_CONTENT"

echo "📝 Analyzing changes for context..."

# 5. Call Gemini to generate the message
# We use the 'gemini' command available in the path
COMMIT_MSG=$(gemini "$PROMPT" 2>/dev/null)

# Clean up output (remove quotes if LLM adds them)
COMMIT_MSG=$(echo "$COMMIT_MSG" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

# Fallback if generation failed
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="chore: auto-save work context $(date '+%Y-%m-%d %H:%M')"
fi

echo "✅ Commit Message: $COMMIT_MSG"

# 6. Commit
git commit -m "$COMMIT_MSG"
echo "🚀 Saved."
echo "----------------------------------------"
