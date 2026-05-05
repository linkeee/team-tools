# team-tools

团队 AI 工具管理框架 — 使用 Git 仓库统一管理、分发 Claude Code 的 skill / MCP / CLI 工具。

## 核心理念

- **成员零感知仓库**：团队成员只需在标准 Claude 目录（`~/.claude/skills/` 等）下创作和使用工具，无需 clone 团队仓库
- **一条命令提交**：`tt submit` 自动检测工具元信息，交互式补全描述，一键推送并创建 PR
- **一条命令安装**：`tt install` 从团队仓库下载工具到本地，支持批量安装

## 架构

```
团队 Git 仓库 (单点真源)              成员本地 (标准 Claude 目录)
┌─────────────────────────┐          ┌──────────────────────────┐
│ global/skill/<name>/    │          │ ~/.claude/skills/<name>/ │
│   tool.yaml             │   tt     │   tool.yaml              │
│   v1.0.0/               │  install │   SKILL.md               │
│   v1.1.0/               │ ◄─────── │                          │
│ apps/<ns>/<type>/<name>/│          │ ~/.claude/mcp/<name>/    │
│   tool.yaml             │   tt     │   tool.yaml              │
│   v1.0.0/               │  submit │   server.json            │
│                         │ ───────► │                          │
└─────────────────────────┘          │ ~/bin/<name>  (CLI)      │
                                     └──────────────────────────┘
```

## 安装

```bash
# 一键安装（需要团队仓库地址）
./install.sh <git-repo-url>

# 或远程安装
curl -sL <raw-install-url> | bash -s -- <git-repo-url>
```

依赖：`git`、`python3`、`PyYAML`（`pip3 install pyyaml`）、`gh`（创建 PR 需要）

## 快速开始

```bash
# 配置团队仓库地址
tt config set REMOTE=git@github.com:team/team-tools.git

# 查看远程可用工具
tt list --remote

# 批量安装所有全局 skill
tt install --all --scope global --type skill

# 安装单个工具
tt install global/code-review

# 创建自己的工具
tt new my-skill --type skill
cd ~/.claude/skills/my-skill
# ... 编辑 SKILL.md ...

# 提交到团队
tt submit
```

## 命令参考

### 成员命令

| 命令 | 说明 |
|------|------|
| `tt install <tool>` | 安装指定工具，格式：`[type/]namespace/name[@version]` |
| `tt install --all [--scope global\|app] [--type skill\|mcp\|cli]` | 批量安装 |
| `tt update [tool]` | 检查并更新工具到最新版本 |
| `tt list [--remote]` | 列出已安装 / 远程可用工具 |
| `tt search <keyword>` | 搜索工具 |
| `tt info <tool>` | 查看工具详情和远程版本 |
| `tt rollback <tool> [version]` | 回滚到指定版本 |
| `tt uninstall <tool>` | 卸载工具 |

### 创作命令

| 命令 | 说明 |
|------|------|
| `tt new <name> [--type skill\|mcp\|cli] [--ns global\|app]` | 在标准目录下创建新工具 |
| `tt submit [path]` | 提交工具到团队仓库（自动检测 + 交互确认 + 创建 PR） |

### 管理命令

| 命令 | 说明 |
|------|------|
| `tt review [mr-id]` | 查看待审核 PR 列表或详情 |
| `tt approve <mr-id>` | 通过并合入 PR |
| `tt reject <mr-id> [reason]` | 驳回 PR |
| `tt stats` | 统计已安装工具 |

### 配置命令

| 命令 | 说明 |
|------|------|
| `tt config set REMOTE=<url>` | 设置团队仓库地址 |
| `tt config set PROJECT_<ns>=<path>` | 配置应用级项目路径（用于项目级工具） |
| `tt config list` | 列出所有配置 |

## tool.yaml 规范

每个工具目录下必须包含 `tool.yaml`（`tt submit` 可自动生成）：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | 是 | 工具名称，小写字母+数字+连字符 |
| `type` | string | 是 | `skill` / `mcp` / `cli` |
| `namespace` | string | 是 | `global` 或应用名 |
| `version` | string | 是 | 语义化版本 `X.Y.Z` |
| `description` | string | 是 | 一句话描述 |
| `author` | string | 是 | 作者名 |
| `entrypoint` | string | 是 | skill→`SKILL.md`，mcp→`server.json`，cli→可执行文件名 |
| `dependencies` | []string | 否 | 依赖的其他工具 |
| `min_claude_version` | string | 否 | 最低 Claude Code 版本要求 |

## 目录结构

```
~/.claude/
├── skills/              ← 全局 skill（成员在此创作）
│   └── <name>/
│       ├── tool.yaml
│       └── SKILL.md
├── mcp/                 ← 全局 MCP
│   └── <name>/
│       ├── tool.yaml
│       └── server.json
├── cli/                 ← 全局 CLI
│   └── <name>/
│       ├── tool.yaml
│       └── <executable>
└── team-tools/          ← tt 缓存/注册表（自动管理）
    ├── .registry.json
    └── .cache/

<project>/.claude/       ← 项目级工具（同上结构）
```

团队 Git 仓库结构：

```
global/
  skill/<name>/
    tool.yaml
    v1.0.0/
      tool.yaml
      SKILL.md
  mcp/<name>/...
  cli/<name>/...
apps/
  <namespace>/skill/<name>/...
```

## 工作流

### 成员：安装团队工具

```bash
tt list --remote          # 查看可用工具
tt install global/code-review
tt install --all --scope global --type skill  # 一键安装全部
```

### 成员：创建并提交新工具

```bash
tt new my-skill --type skill
# 编辑 ~/.claude/skills/my-skill/SKILL.md
tt submit ~/.claude/skills/my-skill
# → 自动检测 skill/global/my-skill
# → 输入描述信息
# → 自动创建 PR
```

### 成员：更新已有工具

```bash
# 修改代码后
tt submit ~/.claude/skills/code-review
# → 提示当前版本 1.0.0
# → 输入新版本 [1.0.1]
# → 自动创建 PR
```

### 管理员：审核与合入

```bash
tt review              # 查看待审核 PR
tt review 42           # 查看 #42 详情
tt approve 42          # 通过并合入
tt reject 42 "缺少 SKILL.md"  # 驳回
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `TT_HOME` | 缓存/注册表目录 | `~/.claude/team-tools` |

## CI 集成

合入 main 分支后，`.ci/tag.sh` 自动扫描 `tool.yaml` 并为每个版本创建 Git tag，格式：

```
<type>/<namespace>/<name>/v<version>
```

示例：`skill/global/code-review/v1.2.0`
