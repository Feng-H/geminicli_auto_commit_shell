#!/bin/bash

# Configuration
CHECK_INTERVAL=10  # Seconds between checks

# Check if inside a git repository
if [ ! -d .git ] && [ -z "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

echo "🟢 Starting Gemini Auto-Commit. Press Ctrl+C to stop."
echo "📂 Monitoring directory: $(pwd)"

# Trap Ctrl+C to exit gracefully
trap "echo -e '\n🔴 Auto-commit stopped.'; exit 0" SIGINT

while true; do
    # Check for changes (staged or unstaged)
    if [[ -n $(git status --porcelain) ]]; then
        echo "----------------------------------------"
        echo "📝 Changes detected at $(date '+%H:%M:%S'). Processing..."
        
        # Stage all changes
        git add .
        
        # Get the diff for the prompt
        # We limit the diff size to avoid token limits if files are huge
        DIFF_CONTENT=$(git diff --staged | head -n 500)
        
        # Construct the prompt for Gemini
        PROMPT="You are an automated git commit message generator. 
        Analyze the following git diff and generate a single, concise commit message adhering to Conventional Commits.
        IMPORTANT: Return ONLY the raw commit message string. Do not use Markdown formatting, do not use quotes, and do not provide explanations.
        
        Diff:
        $DIFF_CONTENT"
        
        echo "🤖 Asking Gemini for a commit message..."
        
        # Call Gemini in non-interactive mode
        # We capture the output. 
        COMMIT_MSG=$(gemini "$PROMPT" 2>/dev/null)
        
        # Clean up the message (remove potential leading/trailing whitespace or quotes)
        COMMIT_MSG=$(echo "$COMMIT_MSG" | sed -e 's/^"//' -e 's/"$//' -e s/^'//' -e s/'$//')
        
        # Fallback if Gemini returns empty (e.g., network error or refusal)
        if [ -z "$COMMIT_MSG" ]; then
            echo "⚠️  Gemini didn't return a message. Using timestamp fallback."
            COMMIT_MSG="chore: auto-commit at $(date '+%Y-%m-%d %H:%M:%S')"
        else
            echo "✅ Generated message: $COMMIT_MSG"
        fi
        
        # Commit
        git commit -m "$COMMIT_MSG"
        echo "🚀 Committed."
        
    fi
    
    # Wait for the next check
    sleep $CHECK_INTERVAL
done
