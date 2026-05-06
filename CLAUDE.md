# team-tools — 团队 AI 工具管理框架

基于 Git 仓库统一管理、分发 Claude Code 的 skill / MCP / CLI 工具。去中心化架构——成员无需 clone 仓库，一条命令安装、一条命令提交。

## 版本

当前 v0.3.0

## 数据存储

| 存储位置 | 用途 |
|---|---|
| `~/.ttconfig` | 配置：`REMOTE=<url>`、`GITLAB_TOKEN=<token>`、`PROJECT_<ns>=<path>` |
| `~/.claude/team-tools/.registry.json` | 本地注册表，记录已安装工具及版本 |
| `~/.claude/skills|mcp|cli/<name>/` | 全局工具的实际安装目录 |
| `<project>/.claude/skills|mcp|cli/<name>/` | 应用级工具安装目录 |
| `~/.claude/bin/<name>` | CLI 工具软链接 |
| `~/.claude/settings.json` | MCP 配置合并目标 |

远程仓库结构：

```
global/skill|mcp|cli/<name>/
  tool.yaml          ← 元信息（最新版本号等）
  v1.0.0/            ← 版本化内容
    tool.yaml
    SKILL.md / server.json / <executable>

apps/<ns>/skill|mcp|cli/<name>/   ← 应用级工具同上
```

## 两种角色

- **成员**：安装、使用、创建、提交工具
- **审核人员**：审核 MR、通过合入、驳回

## 成员工作流

### 前置配置（一次性）

| 操作 | 参数 | 实际发生 |
|---|---|---|
| `tt config set REMOTE=<url>` | 团队仓库 Git 地址 | 写入 `~/.ttconfig` 的 `REMOTE=` 行 |
| `tt config set GITLAB_TOKEN=<token>` | GitLab Personal Access Token（api 权限） | 写入 `~/.ttconfig` 的 `GITLAB_TOKEN=` 行 |
| `tt config set PROJECT_<ns>=<path>` | 应用命名空间 → 项目绝对路径 | 写入 `~/.ttconfig` 的 `PROJECT_<ns>=` 行 |

依赖：`git`、`python3`、`PyYAML`、`curl`，以及 GitLab Access Token（submit/review 需要）

### 浏览远程工具

**`tt list --remote`**
- 参数：无
- 前提：已配置 REMOTE
- 实际发生：`git clone --depth 1 <remote>` 到临时目录 → 遍历 `global/*/<name>/` 和 `apps/<ns>/*/<name>/` → 打印列表 → 删除临时目录

**`tt search <keyword>`**
- 参数：关键词
- 实际发生：调 `tt list --remote` + `grep -i`

**`tt info <tool>`**
- 参数：`[type/]namespace/name`
- 前提：工具已本地安装
- 实际发生：读本地 `tool.yaml` 打印元信息 → `git clone --depth 1` 远程列出版本列表

### 安装工具

**`tt install <spec>`（单个）**
- 参数：`[type/]namespace/name[@version]`
- 实际发生：
  1. 解析 spec → type, ns, name, version
  2. 计算本地目标目录（global → `~/.claude/<type>s/<name>`，app → `<project>/.claude/<type>s/<name>`）
  3. 若已存在则覆盖
  4. `git clone --depth 1` → 定位路径 → 若未指定 version 取最新 → `cp -r` 到目标
  5. 后置操作：mcp → 合并 `server.json` 到 `settings.json`；cli → `ln -sf` 到 `~/.claude/bin/`
  6. 写入 `.registry.json`

**`tt install --all [--scope global|app] [--type skill|mcp|cli]`**
- 参数：可选过滤
- 实际发生：`tt list --remote` → 过滤 → 逐个 `tt install`

### 更新与回滚

**`tt update [tool]`**
- 参数：可选 `[type/]namespace/name`，不传 = 全部
- 实际发生：`git clone --depth 1` 取最新版本号 → 比对本地 version → 不同则 `tt install ...@latest`

**`tt rollback <tool> [version]`**
- 参数：`[type/]namespace/name` + 可选版本号
- 实际发生：未指定版本则列出版本列表 → 调 `tt install <tool>@<version>`

**`tt uninstall <tool>`**
- 参数：`[type/]namespace/name`
- 实际发生：`rm -rf` 工具目录 → 清理 cli 软链 / mcp 配置 → 从 `.registry.json` 移除

### 创建与提交

**`tt new <name> [--type skill|mcp|cli] [--ns global|app]`**
- 参数：名称（必填），类型默认 skill，ns 默认 global
- 实际发生：创建目录 → 生成 `tool.yaml` (v1.0.0) → 按类型生成模板文件（SKILL.md / server.json / bash 脚本）

**`tt submit [path]`**
- 参数：工具目录路径，默认 `.`
- 前提：已配置 REMOTE 和 GITLAB_TOKEN
- 实际发生：
  1. 从路径自动检测 type/ns/name（匹配 `~/.claude/<type>s/` 模式 → 兜底看文件内容）
  2. 检查必要文件（SKILL.md / server.json）
  3. 处理 tool.yaml：新建 → 交互输描述；已有 → 交互输新版本（默认 patch+1）
  4. `git clone --depth 1 <remote>` 到临时目录
  5. 构建 `global/<type>/<name>/v<version>/`（或 apps 路径）
  6. 复制工具文件 + tool.yaml → 分支名 `submit/<type>/<ns>/<name>/v<version>`
  7. `git add` → `git commit` → `git push origin <branch>`
  8. 通过 GitLab API (`POST /api/v4/projects/:id/merge_requests`) 创建 MR
  9. 清理临时目录

### 辅助操作

**`tt list`（本地）**
- 参数：无
- 实际发生：读 `.registry.json`，打印表格

**`tt stats`**
- 参数：无
- 实际发生：读 `.registry.json`，统计总数 / 按 namespace / 按 type 分布

## 审核人员工作流

### `tt review [mr-id]`
- 参数：可选 MR 编号
- 前提：已配置 GITLAB_TOKEN
- 实际发生：无参 → `GET /api/v4/projects/:id/merge_requests?state=opened` 格式化打印列表；有参 → `GET .../merge_requests/:iid` 显示 MR 详情

### `tt approve <mr-id>`
- 参数：MR 编号（必填）
- 前提：已配置 GITLAB_TOKEN；有仓库写权限
- 实际发生：`POST .../merge_requests/:iid/approve` → `PUT .../merge_requests/:iid/merge` (squash + remove branch)

### `tt reject <mr-id> [reason]`
- 参数：MR 编号（必填）+ 可选理由（默认"需要修改后重新提交"）
- 实际发生：`POST .../merge_requests/:iid/notes` 添加驳回评论 → `PUT .../merge_requests/:iid` (state_event=close)

## CI 自动流程

合入 main 后，`.ci/tag.sh`（需在 CI pipeline 中配置触发）：

1. 遍历所有非版本目录内的 `tool.yaml`
2. 读 name/type/ns/version → 构造 tag `<type>/<ns>/<name>/v<version>`
3. 已存在的 tag 跳过，不存在的创建
4. `git push origin --tags`

## 关键设计决策

- **去中心化**：成员只在标准 `~/.claude/` 目录下工作，无需 clone 团队仓库。`tt` 通过 `git clone --depth 1` 临时拉取远程信息
- **零额外 CLI 依赖**：MR 操作通过 `curl` + GitLab REST API 实现，无需安装 `gh`/`glab`
- **版本化**：每个工具内容按 semver 版本目录存放，`tool.yaml` 在父级记录当前最新版本
- **双 reg 分离**：工具内容在标准 Claude 目录，注册表在 `~/.claude/team-tools/`，互不污染
- **spec 三段格式**：`[type/]namespace/name[@version]`，2 段时 type 自动从注册表或标准目录推断
