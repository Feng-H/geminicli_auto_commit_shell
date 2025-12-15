# Gemini Auto-Commit Feature (自动提交助手)

本项目提供基于 Gemini (LLM) 的自动化 Git 提交功能。它能自动检测文件变更，并根据 diff 内容生成符合 Conventional Commits 规范的提交信息。

## 目录结构

- `auto_git_handler.sh`: **核心处理脚本**。执行一次完整的流程：检测变更 -> git add -> 生成 commit message -> git commit。
- `git_monitor.sh`: **监控脚本**。负责监听文件变动（支持 `fswatch` 事件驱动或轮询模式），并调用核心脚本。
- `config.env`: **配置文件**。定义检测频率、Prompt 模板等。

## 功能特性

- **智能提交信息**: 分析 `git diff` 生成有意义的提交记录（如 `feat:`, `fix:`）。
- **零配置 Shell Hook**: 可集成到 Shell (zsh/bash) 中，在退出 CLI 时自动检查并提交。
- **自动初始化**: 如果目录没有 git 仓库，尝试自动初始化。
- **实时监控**: 提供后台监控脚本，保存即提交。

## 安装与配置

### 1. 依赖检查

核心功能依赖 `gemini` 命令行工具（即当前 CLI 环境）。
推荐安装 `fswatch` 以获得最佳监控体验（macOS）：

```bash
brew install fswatch
```

### 2. 配置文件 (config.env)

项目根目录下已提供 `config.env`，你可以修改以下参数：

- `CHECK_INTERVAL`: 轮询模式下的检查间隔（秒）。
- `MAX_DIFF_LINES`: 发送给 LLM 的最大 diff 行数（防止 token 溢出）。
- `PROMPT_TEMPLATE`: 自定义提示词模板。

### 3. 赋予执行权限

确保脚本可执行：

```bash
chmod +x auto_git_handler.sh git_monitor.sh
```

## 使用方法

### 模式一：Shell Hook (推荐 - 退出 CLI 时自动提交)

将以下函数添加到你的 Shell 配置文件（如 `~/.zshrc` 或 `~/.bashrc`）中。
**请修改路径为你的实际路径**。

```bash
# ==========================================
# Gemini Auto-Commit Hook
# ==========================================
function gemini() {
    # 1. 运行原始 gemini 程序 (使用绝对路径避免递归)
    # 使用 'type -a gemini' 查看真实路径
    /path/to/your/original/gemini "$@"
    
    # 2. 退出时触发自动提交检查
    echo -e "\n🤖 Gemini 会话结束. 正在检查变更..."
    bash ~/gemini-cli/auto-commit-feature/auto_git_handler.sh
}
```

重新加载配置：`source ~/.zshrc`。
之后每次使用完 `gemini` 命令退出时，脚本会自动帮你提交代码。

### 模式二：后台实时监控

如果你希望在写代码时自动保存（类似 IDE 的自动保存，但带版本控制）：

```bash
./git_monitor.sh
```

- 如果安装了 `fswatch`，它会监听文件事件，响应速度快。
- 如果没有，它会每隔 10 秒（可配置）轮询一次。

## 故障排查

- **gemini command not found**: 确保脚本运行环境能找到 `gemini` 命令。
- **Git 循环提交**: 脚本默认会忽略 `.git` 目录的变更，但如果 `config.env` 或 `.gitignore` 配置不当，可能会导致死循环。
- **权限问题**: 确保 `chmod +x` 已执行。

## 关联项目

本项目设计用于配合 **Work Report Generator** 使用。通过生成高质量的提交记录，后续可自动生成工作周报/日报。