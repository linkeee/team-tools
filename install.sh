#!/usr/bin/env bash
# tt — Team Tools 一键安装脚本
# 用法:
#   curl -sL <raw-url>/install.sh | bash -s -- <git-repo-url>
#   本地: ./install.sh [git-repo-url]

set -euo pipefail

TT_HOME="${HOME}/.claude/team-tools"
BIN_DIR="${HOME}/bin"
REMOTE_URL="${1:-}"

info() { echo "  → $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       tt — Team Tools Installer     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# 1. 确定远程仓库 URL
if [ -z "$REMOTE_URL" ]; then
    if [ -f "${HOME}/.ttconfig" ]; then
        REMOTE_URL=$(grep '^REMOTE=' "${HOME}/.ttconfig" 2>/dev/null | cut -d= -f2- || true)
    fi
fi

if [ -z "$REMOTE_URL" ]; then
    warn "未指定远程仓库 URL"
    echo ""
    echo "  用法:"
    echo "    curl -sL <url>/install.sh | bash -s -- <git-repo-url>"
    echo "    ./install.sh <git-repo-url>"
    echo ""
    exit 1
fi

# 2. 克隆 / 更新仓库
if [ -d "$TT_HOME/.git" ]; then
    info "更新本地仓库 ..."
    git -C "$TT_HOME" pull --ff-only 2>/dev/null || warn "git pull 失败，使用现有版本"
    ok "仓库已更新"
else
    info "克隆团队仓库 ..."
    if [ -d "$TT_HOME" ]; then
        # 目录存在但不是 git repo，备份
        mv "$TT_HOME" "${TT_HOME}.bak.$(date +%s)"
    fi
    git clone "$REMOTE_URL" "$TT_HOME" 2>/dev/null || {
        echo "  ✗ 克隆失败，请检查 URL: $REMOTE_URL"
        exit 1
    }
    ok "仓库已克隆"
fi

# 3. 安装 tt 命令到 PATH
info "安装 tt 命令 ..."
mkdir -p "$BIN_DIR"
if [ -f "$TT_HOME/bin/tt" ]; then
    chmod +x "$TT_HOME/bin/tt"
    ln -sf "$TT_HOME/bin/tt" "$BIN_DIR/tt"
    ok "tt → ${BIN_DIR}/tt"
else
    warn "仓库中未找到 bin/tt，tt 命令不可用"
fi

# 4. 初始化本地配置文件
if [ ! -f "${HOME}/.ttconfig" ]; then
    cat > "${HOME}/.ttconfig" <<EOF
# tt — Team Tools 配置
REMOTE=${REMOTE_URL}

# namespace → 项目路径映射（应用级 tool 需要）
# PROJECT_<namespace>=/absolute/path/to/project
# 例: PROJECT_trade-inventory-platform=/Users/zhangsan/work/trade-platform
EOF
    ok ".ttconfig 已创建"
else
    # 更新 REMOTE 配置
    if grep -q '^REMOTE=' "${HOME}/.ttconfig" 2>/dev/null; then
        sed -i '' "s|^REMOTE=.*|REMOTE=${REMOTE_URL}|" "${HOME}/.ttconfig"
    else
        echo "REMOTE=${REMOTE_URL}" >> "${HOME}/.ttconfig"
    fi
fi

# 5. 初始化注册表
if [ ! -f "$TT_HOME/.registry.json" ]; then
    echo '{"tools":{}}' > "$TT_HOME/.registry.json"
    ok "注册表已初始化"
fi

# 6. 检查 PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    warn "请将 ~/bin 添加到 PATH:"
    echo ""
    echo "    echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc"
    echo "    source ~/.zshrc"
    echo ""
fi

# 7. 检查依赖
if ! command -v python3 >/dev/null 2>&1; then
    warn "需要 python3"
fi
if ! python3 -c "import yaml" 2>/dev/null; then
    warn "需要 PyYAML，执行: pip3 install pyyaml"
fi

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║        安装完成                      ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
echo "  快速开始:"
echo "    tt --help              查看帮助"
echo "    tt list --remote       查看可用 tool"
echo "    tt install <tool>      安装 tool"
echo "    tt sync                同步到 Claude Code"
echo ""
echo "  配置应用映射 (让应用级 tool 生效):"
echo "    tt config set PROJECT_<app>=/path/to/project"
echo ""
