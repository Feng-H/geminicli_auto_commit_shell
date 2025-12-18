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
COMMIT_LANGUAGE=${COMMIT_LANGUAGE:-en}
AUTO_INIT=${AUTO_INIT:-true}

# Define Prompts
PROMPT_EN="You are an automated git commit message generator. Analyze the following git diff and generate a single, concise commit message adhering to Conventional Commits.
Requirements:
1. Format: <type>(<scope>): <subject>
2. Security: Check for sensitive data (API keys, passwords). If found, return ONLY 'SECURITY_ALERT: Found potential sensitive data.'.
3. Content: Brief explanation of changes.
Return ONLY the raw commit message string. Diff Content:"

PROMPT_ZH="你是一个专业的代码审查和 Git 提交消息生成助手。请分析以下 git diff 内容，生成符合 Conventional Commits 规范的提交信息。
要求如下：
1. **格式**：<type>(<scope>): <subject>

<body>
2. **语言**：标题和正文必须严格使用【中文】。
3. **标题**：简洁明了，概括核心变更。
4. **正文**：详细说明变更的原因和影响。
5. **安全性**：如果发现敏感信息（API Key、密码等），仅返回 'SECURITY_ALERT: Found potential sensitive data.' 并停止。
只返回最终的提交消息内容，不要包含 Markdown 代码块。
Diff Content:"

if [ -z "$PROMPT_TEMPLATE" ]; then
    if [ "$COMMIT_LANGUAGE" == "zh-CN" ]; then
        PROMPT_TEMPLATE="$PROMPT_ZH"
    else
        PROMPT_TEMPLATE="$PROMPT_EN"
    fi
fi

# 1. Check if inside a git repository, init if needed
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ "$AUTO_INIT" = "true" ]; then
        echo "📂 No git repository detected. Initializing new repository..."
        git init
    else
        # echo "📂 No git repository detected. Skipping."
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
