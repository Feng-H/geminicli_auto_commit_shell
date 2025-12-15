#!/bin/bash

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDLER_SCRIPT="$SCRIPT_DIR/auto_git_handler.sh"

# Load Config
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi
CHECK_INTERVAL=${CHECK_INTERVAL:-10}

# Check if inside a git repository
if [ ! -d .git ] && [ -z "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
    echo "Error: Not in a git repository."
    exit 1
fi

echo "🟢 Starting Gemini Auto-Commit Monitor..."
echo "📂 Monitoring directory: $(pwd)"

# Trap Ctrl+C to exit gracefully
trap "echo -e '\n🔴 Auto-commit stopped.'; exit 0" SIGINT

# Check for fswatch (Mac/Linux)
if command -v fswatch &> /dev/null; then
    echo "⚡ Using fswatch for event-driven monitoring."
    # Monitor for Created, Updated, Removed, Renamed events. 
    # Excluding .git directory to avoid loops.
    fswatch -o . -e ".*\.git/.*" --event Created --event Updated --event Removed --event Renamed | while read change_event; do
        echo "🔔 File change detected. Triggering handler..."
        bash "$HANDLER_SCRIPT"
    done
else
    echo "⚠️  fswatch not found. Falling back to polling (Interval: ${CHECK_INTERVAL}s)."
    echo "ℹ️  Install fswatch for better performance (e.g., 'brew install fswatch')."
    
    while true; do
        # Check for changes (staged or unstaged)
        if [[ -n $(git status --porcelain) ]]; then
           bash "$HANDLER_SCRIPT"
        fi
        sleep "$CHECK_INTERVAL"
    done
fi