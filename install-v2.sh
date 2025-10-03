#!/bin/bash

################################################################################
#
#  Mac Command Helper v2.0 - 安装脚本
#  快速安装和配置工具
#
################################################################################

set -e  # 遇到错误立即退出

# 非交互模式与安装模式
BATCH=0
MODE=""   # global|user|alias

while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes)
      BATCH=1 ;;
    --user)
      MODE="user" ;;
    --alias)
      MODE="alias" ;;
    -h|--help)
      echo "Usage: $0 [-y|--yes] [--user|--alias]"; exit 0 ;;
  esac
  shift || break
done

# 颜色定义
COLOR_SUCCESS='\033[38;5;48m'
COLOR_INFO='\033[38;5;75m'
COLOR_WARNING='\033[38;5;214m'
COLOR_ERROR='\033[38;5;203m'
COLOR_RESET='\033[0m'

# 图标
ICON_SUCCESS="✅"
ICON_INFO="ℹ️ "
ICON_WARNING="⚠️ "
ICON_ERROR="❌"

# 配置
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="mcmd"
VERSION="2.1.0"

# 函数定义
show_success() {
    echo -e "${COLOR_SUCCESS}${ICON_SUCCESS} $1${COLOR_RESET}"
}

show_info() {
    echo -e "${COLOR_INFO}${ICON_INFO} $1${COLOR_RESET}"
}

show_warning() {
    echo -e "${COLOR_WARNING}${ICON_WARNING} $1${COLOR_RESET}"
}

show_error() {
    echo -e "${COLOR_ERROR}${ICON_ERROR} $1${COLOR_RESET}"
}

confirm() {
    local message="$1"
    if [ "$BATCH" = "1" ]; then
        echo -e "${COLOR_INFO}${message} [Y/n]: Y (auto)${COLOR_RESET}"
        return 0
    fi
    echo -ne "${COLOR_INFO}${message} [Y/n]: ${COLOR_RESET}"
    read -r response
    response=${response:-Y}
    [[ $response =~ ^[Yy]$ ]]
}

# 显示欢迎信息
clear
echo "╔════════════════════════════════════════════════╗"
echo "║  🚀 Mac Command Helper v${VERSION} 安装向导   ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# 检查系统
show_info "检查系统环境..."

# 检查 macOS
if [[ "$(uname)" != "Darwin" ]]; then
    show_error "此工具仅支持 macOS 系统"
    exit 1
fi

show_success "系统检查通过"

# 检查脚本文件
if [ ! -f "mac-cmd-helper-v2.sh" ]; then
    show_error "未找到 mac-cmd-helper-v2.sh 文件"
    show_info "请确保安装脚本与主程序在同一目录"
    exit 1
fi

# 选择安装方式
echo ""
show_info "请选择安装方式："
echo ""
echo "  1. 全局安装（推荐）"
echo "     - 安装到 $INSTALL_DIR"
echo "     - 可以在任何地方运行 '$SCRIPT_NAME'"
echo "     - 需要管理员权限"
echo ""
echo "  2. 用户安装"
echo "     - 安装到 ~/bin"
echo "     - 只对当前用户有效"
echo "     - 不需要管理员权限"
echo ""
echo "  3. 仅设置别名"
echo "     - 不复制文件"
echo "     - 在当前位置运行"
echo "     - 最简单的方式"
echo ""
if [ "$MODE" = "user" ]; then
  install_choice=2
elif [ "$MODE" = "alias" ]; then
  install_choice=3
elif [ "$BATCH" = "1" ]; then
  install_choice=1
else
  echo -ne "${COLOR_INFO}请输入选项 [1]: ${COLOR_RESET}"
  read -r install_choice
  install_choice=${install_choice:-1}
fi

case $install_choice in
    1)
        # 全局安装
        show_info "执行全局安装..."
        
        if ! sudo cp mac-cmd-helper-v2.sh "$INSTALL_DIR/$SCRIPT_NAME"; then
            show_error "安装失败"
            exit 1
        fi
        
        sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
        
        show_success "已安装到 $INSTALL_DIR/$SCRIPT_NAME"
        show_success "现在可以在任何地方运行: $SCRIPT_NAME"
        
        INSTALLED_PATH="$INSTALL_DIR/$SCRIPT_NAME"
        ;;
        
    2)
        # 用户安装
        show_info "执行用户安装..."
        
        mkdir -p ~/bin
        cp mac-cmd-helper-v2.sh ~/bin/$SCRIPT_NAME
        chmod +x ~/bin/$SCRIPT_NAME
        
        show_success "已安装到 $HOME/bin/$SCRIPT_NAME"
        
        # 检查 PATH
        if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
            show_warning "$HOME/bin 不在 PATH 中"
            
            if confirm "是否自动添加到 PATH？"; then
                # 检测 shell
                if [ -n "$ZSH_VERSION" ] || [ -f ~/.zshrc ]; then
                    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
                    show_success "已添加到 ~/.zshrc"
                    show_info "请运行: source ~/.zshrc"
                elif [ -n "$BASH_VERSION" ] || [ -f ~/.bash_profile ]; then
                    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_profile
                    show_success "已添加到 ~/.bash_profile"
                    show_info "请运行: source ~/.bash_profile"
                fi
            fi
        fi
        
        INSTALLED_PATH="$HOME/bin/$SCRIPT_NAME"
        ;;
        
    3)
        # 仅设置别名
        show_info "设置别名..."
        
        CURRENT_PATH="$(pwd)/mac-cmd-helper-v2.sh"
        chmod +x "$CURRENT_PATH"
        
        # 检测 shell 并添加别名
        if [ -n "$ZSH_VERSION" ] || [ -f ~/.zshrc ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ] || [ -f ~/.bash_profile ]; then
            SHELL_RC="$HOME/.bash_profile"
        else
            SHELL_RC="$HOME/.bashrc"
        fi
        
        # 检查是否已存在别名
        if grep -q "alias $SCRIPT_NAME=" "$SHELL_RC" 2>/dev/null; then
            show_warning "别名已存在"
            if confirm "是否覆盖？"; then
                sed -i.bak "/alias $SCRIPT_NAME=/d" "$SHELL_RC"
            else
                show_info "跳过别名设置"
                exit 0
            fi
        fi
        
        echo "alias $SCRIPT_NAME=\"$CURRENT_PATH\"" >> "$SHELL_RC"
        show_success "已添加别名到 $SHELL_RC"
        show_info "请运行: source $SHELL_RC"
        show_info "或重新打开终端"
        
        INSTALLED_PATH="$CURRENT_PATH"
        ;;
        
    *)
        show_error "无效选项"
        exit 1
        ;;
esac

# 创建配置目录
echo ""
show_info "创建配置目录..."
mkdir -p ~/.mac-cmd-helper

# 初始化配置文件
if [ ! -f ~/.mac-cmd-helper/favorites.json ]; then
    echo "[]" > ~/.mac-cmd-helper/favorites.json
    show_success "已创建收藏夹配置"
fi

if [ ! -f ~/.mac-cmd-helper/combos.json ]; then
    cat > ~/.mac-cmd-helper/combos.json << 'EOF'
{
  "预设组合": [
    {
      "name": "完整清理",
      "description": "深度清理系统、清理Homebrew、释放内存",
      "commands": ["2.1", "3.2", "2.2"]
    },
    {
      "name": "系统优化",
      "description": "清理系统、禁用动画、释放内存",
      "commands": ["2.1", "2.9", "2.2"]
    },
    {
      "name": "网络诊断",
      "description": "刷新DNS、查看IP、网络测速",
      "commands": ["5.3", "5.4", "5.1"]
    }
  ],
  "自定义组合": []
}
EOF
    show_success "已创建命令组合配置"
fi

# 检查依赖（可选）
echo ""
show_info "检查可选依赖..."

check_dependency() {
    local cmd=$1
    local name=$2
    local install_cmd=$3
    
    if command -v $cmd &> /dev/null; then
        show_success "$name 已安装"
        return 0
    else
        show_warning "$name 未安装"
        if confirm "是否现在安装 $name？"; then
            eval $install_cmd
            if [ $? -eq 0 ]; then
                show_success "$name 安装成功"
            else
                show_error "$name 安装失败"
            fi
        fi
        return 1
    fi
}

# 检查 Homebrew
if ! command -v brew &> /dev/null; then
    show_warning "Homebrew 未安装"
    if confirm "Homebrew 是包管理器，强烈推荐安装。是否现在安装？"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
else
    show_success "Homebrew 已安装"
fi

# 检查 jq（收藏与组合需要）
check_dependency jq jq "brew install jq"

# 安装完成
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  🎉 安装完成！                                 ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

show_success "Mac Command Helper v${VERSION} 已成功安装！"
echo ""

# 显示使用说明
show_info "快速开始："
echo ""

if [ $install_choice -eq 3 ]; then
    echo "  1. 重新加载配置文件："
    echo "     source $SHELL_RC"
    echo ""
    echo "  2. 运行程序："
    echo "     $SCRIPT_NAME"
else
    echo "  直接运行："
    echo "  $SCRIPT_NAME"
fi

echo ""
show_info "更多帮助："
echo ""
echo "  查看帮助：    $SCRIPT_NAME help"
echo "  快速入门：    cat QUICKSTART_V2.md"
echo "  命令速查：    cat CHEATSHEET_V2.md"
echo "  完整文档：    cat README_V2.md"
echo ""

# 提示可选功能
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
show_info "💡 提示："
echo ""
echo "  某些高级功能需要额外工具："
echo ""
echo "  • exiftool   - 删除图片元数据"
echo "  • ffmpeg     - 视频格式转换"
echo "  • jq         - 收藏与组合（JSON 解析）"
echo "  • nvm        - Node.js 版本管理"
echo "  • cloc       - 代码行数统计"
echo ""
echo "  程序会在需要时提示安装这些工具"
echo ""

# 是否立即运行
echo ""
if confirm "是否立即运行 Mac Command Helper？"; then
    echo ""
    if [ $install_choice -eq 3 ]; then
        show_info "请手动运行："
        echo "  source $SHELL_RC && $SCRIPT_NAME"
    else
        exec "$INSTALLED_PATH"
    fi
fi

echo ""
show_success "感谢使用 Mac Command Helper v${VERSION}！"
echo ""
