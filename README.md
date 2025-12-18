# Gemini Auto-Commit Shell (自动git commit提交脚本)

本项目提供基于 Gemini (LLM) 的自动化 Git 提交功能。它能自动检测文件变更，并根据 diff 内容生成符合 Conventional Commits 规范的提交信息。

## 目录结构

- `install.sh`: **一键安装脚本**。自动将命令添加到你的 Shell 配置文件中。
- `auto_git_handler.sh`: **核心处理脚本**。执行一次完整的流程：检测变更 -> git add -> 生成 commit message -> git commit。

- `config.env`: **配置文件**。定义检测频率、Prompt 模板等。

## 功能特性

- **无感集成**: 自动 Hook `gemini` 命令，执行任意 Gemini 操作后尝试自动提交。
- **智能提交信息**: 分析 `git diff` 生成有意义的提交记录（如 `feat:`, `fix:`）。
- **自动初始化**: 如果目录没有 git 仓库，尝试自动初始化。
- **实时监控 (可选)**: 提供后台监控脚本，保存即提交。

## 快速开始

### 1. 一键安装

为了确保本项目的正常运行，请先安装以下依赖：

### 1. Gemini CLI

核心功能依赖于 `gemini` 命令行工具。请确保您已安装并配置好 Gemini CLI。如果您尚未安装，请通过以下命令进行安装：

```bash
pip install gemini-cli
# 或者，如果您使用的是 conda 环境
# conda install -c conda-forge gemini-cli
```
安装完成后，请确保您已登录并配置好 Gemini API 密钥。

### 2. Git

本项目是一个 Git 自动提交工具，因此需要您已经安装 Git 并熟练使用。

```bash
# 如果您尚未安装 Git，可以通过以下命令安装 (以 macOS 为例)
brew install git
```

在当前目录下运行安装脚本：

```bash
bash install.sh
```

脚本会自动检测路径并将配置写入你的 `~/.zshrc` 或 `~/.bashrc`。
安装完成后，请执行 `source ~/.zshrc` (或 `source ~/.bashrc`) 使配置生效。

### 3. 使用方法

#### 方式一：命令行触发 (默认)

安装脚本会安装 Shell Hooks（钩子）。
在任何 Git 项目目录下，当你运行 **任意 gemini 命令** 时（例如 `gemini chat` 或单纯调用 `gemini`）：

1. **首先执行 Gemini 命令**：你正常使用 Gemini CLI，没有任何中间层干扰。
2. **随后触发自动提交**：Gemini 进程结束后，Shell 钩子会自动检测刚才运行的命令，如果发现是 `gemini`，则触发自动提交流程。

```bash
gemini
# 此时进入 Gemini 交互模式...
# 做了一些操作...
# 退出交互模式 (exit)
# -> 自动触发 Git 提交流程
```

程序流程：
1. 用户执行原 `gemini` 命令。
2. Shell 钩子捕获命令结束事件。
3. 脚本检测到刚才运行的是 `gemini`。
4. 自动调用 handler 脚本：检测 Git 变更 -> 分析 Diff -> 生成 Commit Message -> 提交。

## 工作原理

用户可能会疑问，本项目是如何在不修改 `gemini` 原生命令的前提下实现自动提交的。答案是利用 Shell 的 **Hooks (钩子) 机制**。

### Shell Hooks 机制

我们摒弃了传统的 `alias` 或 `function` 覆盖做法，采用了更底层且无侵入性的 Hook 方案：

1.  **无侵入 (No Shadowing)**：我们不再定义名为 `gemini` 的函数来覆盖系统命令。这意味着 `type gemini` 返回的永远是原生可执行文件路径，避免了路径解析错误和递归调用问题。
2.  **Zsh 实现**: 利用 `preexec` 钩子在命令执行前标记状态，利用 `precmd` 钩子在命令执行后检查状态。如果刚才执行的是 `gemini`，则触发提交脚本。
3.  **Bash 实现**: 利用 `PROMPT_COMMAND` 环境变量。Bash 在每次显示提示符前都会执行该变量中的命令。我们通过检查历史记录 (`history`) 来判断上一条命令是否为 `gemini`。

这种方式确保了：
*   **兼容性强**：完全不干扰 Gemini CLI 的参数传递和执行逻辑。
*   **稳定性高**：避免了复杂的 Shell 函数嵌套和转义问题。

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

本项目设计用于配合 **Work Report Generator** (项目还在初版,还没有提交github)使用。通过生成高质量的提交记录，后续可自动生成工作周报/日报。()
