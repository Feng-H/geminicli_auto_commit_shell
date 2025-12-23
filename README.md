# Gemini Auto-Commit (自动 Git 提交助手)

本项目是一个 Shell 插件，能够为 `gemini` 命令行工具无缝集成 **自动 Git 提交** 功能。
当你使用 `gemini` 完成代码生成或问答后，本插件会自动检测当前目录的文件变更，利用 Gemini 模型生成符合 Conventional Commits 规范的提交信息，并自动执行提交。

## 核心特性

- **无感集成 (Shell Hooks)**: 无需改变你的使用习惯。只需像往常一样运行 `gemini` 命令，操作结束后插件会自动接管。
- **智能提交信息**: 基于 `git diff` 分析代码变更，自动生成 `feat:`, `fix:` 等格式的规范 Commit Message。
- **自动初始化**: 如果当前目录不是 Git 仓库，可配置自动执行 `git init`。
- **安全检查**: 内置基础的安全过滤，防止将 API Key 等敏感信息写入提交记录。

## 目录结构

- `install.sh`: **安装脚本**。自动识别 Shell (Bash/Zsh) 并配置 Hooks。
- `auto_git_handler.sh`: **核心逻辑脚本**。执行 Git 状态检测、Diff 分析、LLM 调用和提交操作。
- `config.env`: **配置文件**。设置语言、Diff 长度限制等。

## 快速开始

### 1. 前置要求

确保你的系统中已安装以下工具，并且在 PATH 中可用：

*   **Gemini CLI**: 必须安装 `gemini` 命令行工具。
    *   验证方式: 在终端运行 `type gemini` 或 `which gemini`，应输出路径。
*   **Git**: 版本建议 >= 2.0。

### 2. 安装

在当前目录下运行一键安装脚本：

```bash
bash install.sh
```

脚本会自动检测你的 Shell 类型 (`zsh` 或 `bash`)，并将必要的 Hook 配置追加到 `~/.zshrc` 或 `~/.bash_profile` / `~/.bashrc` 中。

**安装完成后，请务必重启终端或手动加载配置：**

```bash
# 如果你是 Zsh 用户
source ~/.zshrc

# 如果你是 Bash 用户
source ~/.bash_profile
# 或者
source ~/.bashrc
```

### 3. 使用方法

安装成功后，你无需学习新命令。

1.  在任何 Git 项目目录下，运行任意 Gemini 命令：
    ```bash
    gemini "帮我写一个 Python 的 Hello World"
    ```
    或者进入交互模式：
    ```bash
    gemini
    # ... 在交互模式中进行对话 ...
    # ... 退出交互模式 ...
    ```

2.  **自动触发**：
    当 `gemini` 命令执行结束（或交互模式退出）时，Shell Hook 会自动触发 `auto_git_handler.sh`。

3.  **自动提交**：
    *   脚本检测到文件变更。
    *   脚本调用 `gemini` 生成 Commit Message。
    *   脚本执行 `git add .` 和 `git commit`。

## 配置说明

你可以编辑 `config.env` 文件来调整行为：

| 变量名 | 默认值 | 说明 |
| :--- | :--- | :--- |
| `COMMIT_LANGUAGE` | `zh-CN` | 提交信息的语言。可选 `en` (英文) 或 `zh-CN` (中文)。 |
| `AUTO_INIT` | `true` | 如果当前目录不是 Git 仓库，是否自动初始化。 |
| `MAX_DIFF_LINES` | `200` | 发送给 AI 分析的 Diff 最大行数（防止 Token 消耗过多）。 |
| `PROMPT_TEMPLATE` | (内置) | 自定义提示词模板（可选）。 |

## 工作原理

本插件不替换也不通过 `alias` 覆盖原生的 `gemini` 命令，而是利用 Shell 的 **Hooks** 机制，保证了极高的兼容性和稳定性。

- **Zsh**: 使用 `preexec` 记录命令，`precmd` 在命令结束后触发检查。
- **Bash**: 使用 `PROMPT_COMMAND` 在每次打印提示符前检查上一条命令。

## 故障排查

- **没有触发自动提交？**
    *   检查是否已执行 `source ~/.zshrc` (或 bash 配置文件)。
    *   检查当前目录是否有文件变更 (`git status`)。
    *   确保 `auto_git_handler.sh` 具有执行权限 (`chmod +x auto_git_handler.sh`，安装脚本通常会自动处理)。
- **Sensitivity Alert (安全警告)**
    *   如果 AI 检测到 Diff 中包含类似密钥的敏感信息，会自动终止提交并执行 `git reset` (撤销暂存)。请检查代码后再手动提交。