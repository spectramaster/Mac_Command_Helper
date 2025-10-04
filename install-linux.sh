#!/usr/bin/env bash
set -e

COLOR_INFO='\033[38;5;75m'; COLOR_SUCCESS='\033[38;5;48m'; COLOR_WARNING='\033[38;5;214m'; COLOR_ERROR='\033[38;5;203m'; COLOR_RESET='\033[0m'
ICON_INFO="ℹ️"; ICON_SUCCESS="✅"; ICON_WARNING="⚠️"; ICON_ERROR="❌"

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="lcmd"

BATCH=0; MODE=""
while [ $# -gt 0 ]; do case "$1" in -y|--yes) BATCH=1;; --user) MODE="user";; --alias) MODE="alias";; -h|--help) echo "Usage: $0 [-y|--yes] [--user|--alias]"; exit 0;; esac; shift || break; done

say_info(){ echo -e "${COLOR_INFO}${ICON_INFO} $1${COLOR_RESET}"; }
say_ok(){ echo -e "${COLOR_SUCCESS}${ICON_SUCCESS} $1${COLOR_RESET}"; }
say_warn(){ echo -e "${COLOR_WARNING}${ICON_WARNING} $1${COLOR_RESET}"; }
say_err(){ echo -e "${COLOR_ERROR}${ICON_ERROR} $1${COLOR_RESET}"; }
confirm(){ local msg="$1"; if [ "$BATCH" = "1" ]; then echo -e "${COLOR_INFO}$msg [Y/n]: Y (auto)${COLOR_RESET}"; return 0; fi; echo -ne "${COLOR_INFO}$msg [Y/n]: ${COLOR_RESET}"; read -r a; a=${a:-Y}; [[ $a =~ ^[Yy]$ ]]; }

clear; echo "╔══════════════════════════════════════╗"; echo "║  🐧 Linux Command Helper 安装向导    ║"; echo "╚══════════════════════════════════════╝"; echo ""

if [ ! -f "linux-cmd-helper.sh" ]; then say_err "未找到 linux-cmd-helper.sh"; exit 1; fi

say_info "选择安装方式："
echo "  1) 全局安装 (需要 sudo)"
echo "  2) 用户安装 (~/bin)"
echo "  3) 仅设置别名 (当前路径)"

if [ "$MODE" = "user" ]; then choice=2; elif [ "$MODE" = "alias" ]; then choice=3; elif [ "$BATCH" = "1" ]; then choice=1; else echo -ne "输入选项 [1]: "; read -r choice; choice=${choice:-1}; fi

case $choice in
  1)
    say_info "全局安装到 $INSTALL_DIR/$SCRIPT_NAME"
    sudo cp linux-cmd-helper.sh "$INSTALL_DIR/$SCRIPT_NAME" && sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME" && say_ok "安装成功"
    INSTALLED_PATH="$INSTALL_DIR/$SCRIPT_NAME"
    ;;
  2)
    say_info "用户安装到 $HOME/bin/$SCRIPT_NAME"
    mkdir -p "$HOME/bin"; cp linux-cmd-helper.sh "$HOME/bin/$SCRIPT_NAME"; chmod +x "$HOME/bin/$SCRIPT_NAME"; say_ok "安装成功"
    case ":$PATH:" in *":$HOME/bin:"*) :;; *) say_warn "$HOME/bin 不在 PATH"; confirm "是否添加到 PATH？" && { echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"; say_ok "已写入 ~/.bashrc (请 source ~/.bashrc)"; }; esac
    INSTALLED_PATH="$HOME/bin/$SCRIPT_NAME"
    ;;
  3)
    say_info "设置别名到 shell 配置文件"
    CURRENT_PATH="$(pwd)/linux-cmd-helper.sh"; chmod +x "$CURRENT_PATH"
    SHELL_RC="$HOME/.bashrc"; [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
    grep -q "alias $SCRIPT_NAME=" "$SHELL_RC" 2>/dev/null && sed -i.bak "/alias $SCRIPT_NAME=/d" "$SHELL_RC"
    echo "alias $SCRIPT_NAME=\"$CURRENT_PATH\"" >> "$SHELL_RC"
    say_ok "已添加别名到 $SHELL_RC (请 source)"
    INSTALLED_PATH="$CURRENT_PATH"
    ;;
  *)
    say_err "无效选项"; exit 1;;
esac

echo ""; say_info "初始化配置目录..."; mkdir -p "$HOME/.linux-cmd-helper"; [ -f "$HOME/.linux-cmd-helper/favorites.json" ] || echo "[]" > "$HOME/.linux-cmd-helper/favorites.json"
[ -f "$HOME/.linux-cmd-helper/combos.json" ] || cat > "$HOME/.linux-cmd-helper/combos.json" << 'EOF'
{
  "预设组合": [
    {"name":"系统更新","description":"apt update+upgrade+autoremove","commands":["1.1","1.2","1.3"]}
  ],
  "自定义组合": []
}
EOF
say_ok "配置已就绪"

echo ""; say_info "可选依赖 (按需安装)：jq, dnsutils(dig), traceroute, rsync, ufw, fail2ban, unattended-upgrades, docker"
confirm "是否现在检查并提示安装缺失依赖？" && {
  check_install(){ local c="$1"; local pkg="${2:-$1}"; command -v "$c" >/dev/null 2>&1 || { say_warn "$c 未安装"; confirm "安装 $pkg？" && sudo apt update && sudo apt install -y "$pkg"; }; }
  check_install jq jq
  check_install dig dnsutils
  check_install traceroute traceroute
  check_install rsync rsync
}

echo ""; say_ok "安装完成！你可以运行: $SCRIPT_NAME"

