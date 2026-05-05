#!/usr/bin/env bash
# tag.sh — CI 脚本：合入 main 后自动为新增/变更的 tool 打 tag
# 遍历每个 tool，比较远程是否有对应版本的 tag，若没有则创建

set -euo pipefail

REMOTE="${1:-origin}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 查找所有 tool.yaml 文件（跳过 v*/ 版本目录内的）
find "$REPO_ROOT" -name tool.yaml | grep -v '/v[0-9]' | while read -r meta; do
    TOOL_DIR="$(dirname "$meta")"
    NAME=$(yq '.name' "$meta")
    TYPE=$(yq '.type' "$meta")
    NS=$(yq '.namespace' "$meta")
    VERSION="v$(yq '.version' "$meta")"
    TAG="${TYPE}/${NS}/${NAME}/${VERSION}"

    if git rev-parse "$TAG" >/dev/null 2>&1; then
        echo "[SKIP] Tag $TAG already exists"
    else
        git tag -a "$TAG" -m "Release ${TYPE} ${NS}/${NAME} ${VERSION}"
        echo "[DONE] Created tag: $TAG"
    fi
done

git push "$REMOTE" --tags
echo "[DONE] All tags pushed"
