# claude_worker

基于 `docker-box/ai_workspace` 的 Claude Code 沙箱镜像，内置 `@anthropic-ai/claude-code` CLI 和 `yolo` 别名。

## 启动前准备

1. 构建镜像：

```bash
cd images/claude_worker
./build.sh
```

2. 创建 `.env`（参考 `.env.example` 填入真实值）：

```bash
cp .env.example .env
```

`.env` 已加入 `.gitignore` / `.dockerignore`，不会泄漏。

## 挂载说明

| 挂载项   | 容器路径                    | 用途                                       | 是否必需 |
| -------- | --------------------------- | ------------------------------------------ | -------- |
| 工作区   | `/workspace`                | 待处理的代码仓库                           | **必需** |
| SSH 密钥 | `/home/worker/.ssh`         | 容器内 git push/pull                       | 推荐     |
| Git 配置 | `/home/worker/.gitconfig`   | 提交时的身份（`user.name` / `user.email`） | 推荐     |
| 环境变量 | 通过 `--env-file .env` 注入 | Claude Code API 凭证                       | **必需** |

> `~/.claude/CLAUDE.md`（行为规范）已 baked 到镜像中，无需额外挂载。如需项目级覆盖，在工作区根目录放置 `CLAUDE.md` 即可。

## 启动示例

以下示例均使用 bash/zsh 语法；Windows 用户请将 `$(pwd)` 替换为绝对路径或对应的 PowerShell 变量。

### 1. 交互模式

进入容器的 zsh，手动执行 `yolo` 或 `claude`：

```bash
docker run -it --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  -v "$HOME/.ssh:/home/worker/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/worker/.gitconfig:ro" \
  claude-worker:latest
```

进入后运行 `yolo` 启动 Claude Code，或直接执行其他开发任务。

### 2. YOLO 模式（非交互式，单次任务）

覆盖 CMD，直接让 Claude Code 执行一个任务并退出：

```bash
docker run --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  -v "$HOME/.ssh:/home/worker/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/worker/.gitconfig:ro" \
  claude-worker:latest \
  zsh -c 'claude --dangerously-skip-permissions -p "为 README 添加安装说明"'
```

> `-p`（print）模式：执行一次任务后退出，不进入 REPL。适合 CI/自动化场景。

### 3. 启用 SSHD（供 IDE Remote-SSH 连接）

```bash
docker run -d --rm \
  --name claude_sshd \
  --env-file .env \
  -e ENABLE_SSHD=1 \
  -e SSH_PORT=2222 \
  -e SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/id_*.pub)" \
  -v "$(pwd):/workspace" \
  -v "$HOME/.ssh:/home/worker/.ssh:ro" \
  -v "$HOME/.gitconfig:/home/worker/.gitconfig:ro" \
  -p 2222:2222 \
  claude-worker:latest

# 连接后 attach
docker attach claude_sshd
```

### 4. 仅挂载工作区（无需 git）

```bash
docker run -it --rm \
  --env-file .env \
  -v "$(pwd):/workspace" \
  claude-worker:latest
```

适合纯代码生成、无推送需求的场景。
