#!/usr/bin/env bash
# tt — Team Tools 一键安装脚本  v0.3.0
# 用法:
#   curl -sL <url>/install.sh | bash
#   ./install.sh [git-repo-url]   # 自定义仓库地址（可选）

set -euo pipefail

TT_HOME="${HOME}/.claude/team-tools"
BIN_DIR="${HOME}/bin"
DEFAULT_REMOTE="git@github.com:linkeee/team-tools.git"
REMOTE_URL="${1:-$DEFAULT_REMOTE}"

info() { echo "  → $*"; }
ok()   { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       tt — Team Tools Installer     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# 1. 创建缓存目录（不再是 git clone）
info "初始化 tt 缓存目录 ..."
mkdir -p "$TT_HOME"
ok "缓存目录: $TT_HOME"

# 2. 安装 tt 命令
info "安装 tt 命令 ..."
mkdir -p "$BIN_DIR"

# 优先从本地仓库复制（开发者场景）
if [ -f "bin/tt" ]; then
    chmod +x "bin/tt"
    cp "bin/tt" "$BIN_DIR/tt"
    ok "tt → ${BIN_DIR}/tt (本地)"
else
    # 从远程下载 bin/tt
    TMPDIR=$(mktemp -d)
    git clone --depth 1 "$REMOTE_URL" "$TMPDIR" --quiet 2>/dev/null || {
        rm -rf "$TMPDIR"
        warn "克隆失败，请检查 URL: $REMOTE_URL"
        exit 1
    }
    if [ -f "$TMPDIR/bin/tt" ]; then
        chmod +x "$TMPDIR/bin/tt"
        cp "$TMPDIR/bin/tt" "$BIN_DIR/tt"
        ok "tt → ${BIN_DIR}/tt (远程)"
    else
        rm -rf "$TMPDIR"
        warn "仓库中未找到 bin/tt"
        exit 1
    fi
    rm -rf "$TMPDIR"
fi

# 3. 初始化配置文件
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
    ok ".ttconfig 已更新"
fi

# 4. 初始化注册表
if [ ! -f "$TT_HOME/.registry.json" ]; then
    echo '{"tools":{}}' > "$TT_HOME/.registry.json"
    ok "注册表已初始化"
fi

# 5. 检查 PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    warn "请将 ~/bin 添加到 PATH:"
    echo ""
    echo "    echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc"
    echo "    source ~/.zshrc"
    echo ""
fi

# 6. 检查依赖
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
echo "    tt install --all --scope global --type skill"
echo "                            批量安装所有全局 skill"
echo "    tt list --remote        查看可用 tool"
echo "    tt install <tool>       安装 tool"
echo "    tt new <name>           创建新 tool"
echo ""
echo "  配置应用映射 (让应用级 tool 生效):"
echo "    tt config set PROJECT_<app>=/path/to/project"
echo ""
