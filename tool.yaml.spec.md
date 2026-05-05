# tool.yaml 规范

每个 skill / mcp / cli 目录下必须包含一个 `tool.yaml` 文件。

## 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | tool 名称，只能包含小写字母、数字和连字符，如 `code-review` |
| type | string | 是 | 类型：`skill` / `mcp` / `cli` |
| namespace | string | 是 | 命名空间：`global` 或应用名（如 `trade-inventory-platform`） |
| version | string | 是 | 版本号，遵循 semver 格式 `X.Y.Z` |
| description | string | 是 | 一句话描述 tool 的用途 |
| author | string | 是 | 作者名 |
| entrypoint | string | 是 | 入口文件；skill 为 SKILL.md，mcp 为 server.json，cli 为可执行文件名 |
| dependencies | []string | 否 | 依赖的其他 tool 列表，格式为 `<type>/<namespace>/<name>` |
| min_claude_version | string | 否 | 最低 Claude Code 版本要求 |

## 示例

```yaml
name: code-review
type: skill
namespace: global
version: 1.2.0
description: 代码审查助手，检查安全漏洞和代码规范
author: zhangsan
entrypoint: SKILL.md
dependencies: []
min_claude_version: "1.0.0"
```

## 目录规范

```
<namespace>/<type>/<name>/
├── tool.yaml          ← 元数据（提交时校验必含）
├── v<major>.<minor>.<patch>/
│   ├── tool.yaml      ← 此版本的元数据副本（含确认后的 version）
│   ├── SKILL.md       ← skill 内容（或 mcp 的 server.json / cli 的可执行文件）
│   └── ...            ← 其他资源文件
```
