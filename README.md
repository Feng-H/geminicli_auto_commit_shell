# Gemini Auto-Commit Feature (自动提交助手)

本项目提供基于 Gemini (LLM) 的自动化 Git 提交功能。它能自动检测文件变更，并根据 diff 内容生成符合 Conventional Commits 规范的提交信息。

## 目录结构

- `install.sh`: **一键安装脚本**。自动将命令添加到你的 Shell 配置文件中。
- `auto_git_handler.sh`: **核心处理脚本**。执行一次完整的流程：检测变更 -> git add -> 生成 commit message -> git commit。
- `git_monitor.sh`: **监控脚本**。负责监听文件变动（支持 `fswatch` 事件驱动或轮询模式），并调用核心脚本。
- `config.env`: **配置文件**。定义检测频率、Prompt 模板等。

## 功能特性

- **智能提交信息**: 分析 `git diff` 生成有意义的提交记录（如 `feat:`, `fix:`）。
- **安全无冲突**: 采用独立命令 `gemini_auto_commit` 触发，不干扰原有 CLI 环境。
- **自动初始化**: 如果目录没有 git 仓库，尝试自动初始化。
- **实时监控 (可选)**: 提供后台监控脚本，保存即提交。

## 快速开始

### 1. 依赖检查

核心功能依赖 `gemini` 命令行工具（即当前 CLI 环境）。
推荐安装 `fswatch` 以获得最佳监控体验（macOS）：

```bash
brew install fswatch
```

### 2. 一键安装

在当前目录下运行安装脚本：

```bash
bash install.sh
```

脚本会自动检测路径并将配置写入你的 `~/.zshrc` 或 `~/.bashrc`。
安装完成后，请执行 `source ~/.zshrc` 使配置生效。

### 3. 使用方法

#### 方式一：手动触发 (推荐)

在任何 Git 项目目录下，当你完成工作想要提交时，只需输入：

```bash
gemini_auto_commit
```

程序会自动：
1. 检测变更。
2. 分析 Diff。
3. 调用 Gemini 生成语义化 Commit Message。
4. 执行提交。

#### 方式二：后台实时监控

如果你希望在写代码时自动保存（类似 IDE 的自动保存，但带版本控制）：

```bash
./git_monitor.sh
```

- 如果安装了 `fswatch`，它会监听文件事件，响应速度快。
- 如果没有，它会每隔 10 秒（可配置）轮询一次。

## 高级配置

编辑 `config.env` 文件可自定义行为：

- `CHECK_INTERVAL`: 轮询模式下的检查间隔（秒）。
- `MAX_DIFF_LINES`: 发送给 LLM 的最大 diff 行数（防止 token 溢出，默认 200 行）。
- `PROMPT_TEMPLATE`: 自定义提示词模板，你可以修改为你喜欢的风格。

## 故障排查

- **gemini command not found**: 确保脚本运行环境能找到 `gemini` 命令。
- **提交失败**: 检查是否有待提交的文件（`git status`）。
- **权限问题**: 确保 `chmod +x` 已执行。

## 关联项目

本项目设计用于配合 **Work Report Generator** 使用。通过生成高质量的提交记录，后续可自动生成工作周报/日报。
