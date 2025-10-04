#!/bin/bash

################################################################################
#
#  🚀 Mac Command Helper v2.0
#  你的终端效率助手 - 更强大、更智能、更高效
#
#  作者: Claude & User
#  创建日期: 2025-10-04
#  版本: 2.1.0
#  新增: 收藏夹、历史查看、命令组合、快捷执行、30+新命令
#  兼容性: macOS 10.13+
#
################################################################################

# ============================================================================
# 全局配置
# ============================================================================

VERSION="2.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
CONFIG_DIR="$HOME/.mac-cmd-helper"
CONFIG_FILE="$CONFIG_DIR/config.json"
HISTORY_FILE="$CONFIG_DIR/history.log"
FAVORITES_FILE="$CONFIG_DIR/favorites.json"
COMBOS_FILE="$CONFIG_DIR/combos.json"
THEME_FILE="$CONFIG_DIR/theme.conf"
ERROR_LOG="$CONFIG_DIR/error.log"
METRICS_FILE="$CONFIG_DIR/metrics.json"

# 创建配置目录（初始化函数中统一处理）

init_config() {
    mkdir -p "$CONFIG_DIR"
    [ -f "$HISTORY_FILE" ] || : > "$HISTORY_FILE"
    [ -f "$ERROR_LOG" ] || : > "$ERROR_LOG"
    # 初始化收藏与组合
    if [ ! -f "$FAVORITES_FILE" ]; then
        echo "[]" > "$FAVORITES_FILE"
    fi
    if [ ! -f "$COMBOS_FILE" ]; then
        cat > "$COMBOS_FILE" << 'EOF'
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
    fi
}

# ============================================================================
# 颜色系统 - 使用 ANSI 256 色打造现代化界面
# ============================================================================

if [[ -t 1 ]]; then
    export TERM=xterm-256color
fi

# 主色调
COLOR_TITLE='\033[38;5;51m'          # 青色 - 标题
COLOR_ACCENT='\033[38;5;220m'        # 亮黄 - 强调
COLOR_SUCCESS='\033[38;5;48m'        # 青绿 - 成功
COLOR_WARNING='\033[38;5;214m'       # 橙色 - 警告
COLOR_ERROR='\033[38;5;203m'         # 柔和红 - 错误
COLOR_INFO='\033[38;5;75m'           # 淡蓝 - 信息
COLOR_DIM='\033[38;5;240m'           # 暗灰 - 次要信息
COLOR_RESET='\033[0m'                # 重置

# 文字样式
BOLD='\033[1m'
UNDERLINE='\033[4m'
BLINK='\033[5m'

# 背景色
BG_YELLOW='\033[48;5;220m\033[38;5;0m'

# 主题/外观配置
USE_COLOR=1
ENABLE_SPINNER=1

load_theme() {
    # 环境变量优先生效
    if [ "$MCMD_NO_COLOR" = "1" ] || [ -n "$NO_COLOR" ]; then
        USE_COLOR=0
    fi
    if [ -f "$THEME_FILE" ]; then
        while IFS='=' read -r k v; do
            case "$k" in
                color)
                    [ "$v" = "off" ] && USE_COLOR=0 || USE_COLOR=1 ;;
                spinner)
                    [ "$v" = "off" ] && ENABLE_SPINNER=0 || ENABLE_SPINNER=1 ;;
            esac
        done < <(grep -E '^(color|spinner)=' "$THEME_FILE" 2>/dev/null)
    fi
    if [ $USE_COLOR -eq 0 ]; then
        COLOR_TITLE=''; COLOR_ACCENT=''; COLOR_SUCCESS=''; COLOR_WARNING=''; COLOR_ERROR=''; COLOR_INFO=''; COLOR_DIM=''; COLOR_RESET=''; BOLD=''; UNDERLINE=''; BLINK=''; BG_YELLOW=''
    fi
}

# ============================================================================
# 图标系统
# ============================================================================

ICON_PYTHON="🐍"
ICON_SYSTEM="⚙️ "
ICON_HOMEBREW="🍺"
ICON_FILE="📁"
ICON_NETWORK="🌐"
ICON_APPEARANCE="🎨"
ICON_DEV="🔧"
ICON_SECURITY="🔐"
ICON_APP="🚀"
ICON_QUICK="⚡"
ICON_MONITOR="📊"
ICON_REPAIR="🛠️ "
ICON_FAVORITE="⭐"
ICON_SEARCH="🔍"
ICON_COMBO="🎯"
ICON_HISTORY="📜"

ICON_SUCCESS="✅"
ICON_ERROR="❌"
ICON_WARNING="⚠️ "
ICON_INFO="ℹ️ "
ICON_ROCKET="🚀"
ICON_LOADING="⏳"
ICON_LIGHT="💡"
ICON_LOCK="🔒"
ICON_BACK="←"
ICON_ARROW="👉"
ICON_CHECK="✓"
ICON_CROSS="✗"

# ============================================================================
# UI 组件函数
# ============================================================================

get_terminal_width() {
    tput cols 2>/dev/null || echo 80
}

draw_line() {
    local char="${1:-─}"
    local width=$(get_terminal_width)
    printf "%${width}s\n" | tr ' ' "$char"
}

draw_double_line() {
    echo -e "${COLOR_DIM}$(draw_line '━')${COLOR_RESET}"
}

draw_title_box() {
    local title="$1"
    local width=$(get_terminal_width)
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo -e "\n${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    printf "║%${padding}s%s%${padding}s║\n" "" "$title" ""
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}"
}

draw_info_box() {
    local title="$1"
    echo -e "\n${COLOR_INFO}┌$(draw_line '─')┐${COLOR_RESET}"
    echo -e "${COLOR_INFO}│${COLOR_RESET}  ${BOLD}$title${COLOR_RESET}"
    echo -e "${COLOR_INFO}└$(draw_line '─')┘${COLOR_RESET}\n"
}

clear_screen() {
    if [ -t 1 ]; then
        clear
    fi
    draw_title_box "🚀 Mac Command Helper v$VERSION"
    echo -e "${COLOR_DIM}        你的终端效率助手 - 更强大、更智能${COLOR_RESET}\n"
    draw_double_line
}

show_loading() {
    local message="$1"
    local duration=${2:-2}
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local frame_count=${#frames[@]}
    local end_time=$((SECONDS + duration))
    if [ $ENABLE_SPINNER -eq 0 ] || [ ! -t 1 ]; then
        echo -ne "${COLOR_INFO}${message}...${COLOR_RESET}\n"
        sleep "$duration"
        echo -ne "${ICON_SUCCESS} ${message}... ${COLOR_SUCCESS}完成${COLOR_RESET}\n"
        return
    fi
    echo -ne "${COLOR_INFO}"
    while [ $SECONDS -lt $end_time ]; do
        for frame in "${frames[@]}"; do
            echo -ne "\r${frame} ${message}..."
            sleep 0.1
        done
    done
    echo -ne "\r${ICON_SUCCESS} ${message}... ${COLOR_SUCCESS}完成${COLOR_RESET}\n"
}

show_success() {
    echo -e "\n${COLOR_SUCCESS}${ICON_SUCCESS} $1${COLOR_RESET}\n"
}

show_error() {
    echo -e "\n${COLOR_ERROR}${ICON_ERROR} $1${COLOR_RESET}\n"
}

show_warning() {
    echo -e "\n${COLOR_WARNING}${ICON_WARNING} $1${COLOR_RESET}\n"
}

show_info() {
    echo -e "\n${COLOR_INFO}${ICON_INFO} $1${COLOR_RESET}\n"
}

confirm() {
    local message="$1"
    local default="${2:-y}"
    
    if [[ $default == "y" ]]; then
        echo -ne "${COLOR_ACCENT}${message} [Y/n]: ${COLOR_RESET}"
    else
        echo -ne "${COLOR_ACCENT}${message} [y/N]: ${COLOR_RESET}"
    fi
    
    read -r response
    response=${response:-$default}
    [[ $response =~ ^[Yy]$ ]]
}

press_any_key() {
    if [ "${CMD_HELPER_TEST_MODE:-0}" = "1" ] || [ "${MCMD_NONINTERACTIVE:-0}" = "1" ]; then
        return 0
    fi
    echo -e "\n${COLOR_DIM}按任意键继续...${COLOR_RESET}"
    read -n 1 -s
}

# ============================================================================
# 输入校验与清理
# ============================================================================

sanitize_generic() {
    # 拒绝易造成注入的特殊字符：` $ ; & | > < \
    local input="$1"
    if echo "$input" | grep -Eq '[`$;&|><\\]'; then
        return 1
    fi
    return 0
}

sanitize_path() {
    local p="$1"
    # 允许空格和常见路径字符，禁止控制字符和注入符号
    if ! sanitize_generic "$p"; then return 1; fi
    # 去除首尾空格
    p="${p##[[:space:]]}"; p="${p%%[[:space:]]}"
    [ -n "$p" ] || return 1
    return 0
}

sanitize_name() {
    local n="$1"
    if ! sanitize_generic "$n"; then return 1; fi
    [ -n "$n" ] || return 1
    return 0
}

sanitize_email() {
    local e="$1"
    if ! sanitize_generic "$e"; then return 1; fi
    echo "$e" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
}

sanitize_int() {
    local v="$1"
    echo "$v" | grep -Eq '^[0-9]+$'
}

# ============================================================================
# 命令数据结构
# ============================================================================

declare -a COMMANDS

# ============================================================================
# 1. Python 开发环境
# ============================================================================

COMMANDS+=(
"1.1|python|激活虚拟环境|source \$VENV_PATH/bin/activate|no|check_python|激活 Python 虚拟环境，隔离项目依赖|source: 在当前 shell 执行脚本\nbin/activate: 虚拟环境激活脚本|• 开发 Python 项目前\n• 需要特定版本的包时\n• 避免全局包污染|• 激活后命令提示符会显示环境名\n• 使用 deactivate 退出虚拟环境\n• 确保路径正确|• deactivate - 退出虚拟环境\n• python -m venv myenv - 创建虚拟环境"
)

COMMANDS+=(
"1.2|python|创建虚拟环境|python3 -m venv \$VENV_NAME|no|check_python|创建新的 Python 虚拟环境|python3: Python 3 解释器\n-m venv: 使用 venv 模块\n\$VENV_NAME: 环境名称|• 新建 Python 项目时\n• 需要隔离的开发环境|• 环境会创建在当前目录\n• Python 3.3+ 内置 venv|• virtualenv myenv - 使用 virtualenv 工具"
)

COMMANDS+=(
"1.3|python|查看已安装包|pip list|no|check_pip|列出当前环境所有已安装的 Python 包|pip list: 列出所有包|• 检查包是否安装\n• 查看包版本|• 在虚拟环境中运行|• pip show package - 查看包详情"
)

COMMANDS+=(
"1.4|python|导出依赖列表|pip freeze > requirements.txt|no|check_pip|导出当前环境的包依赖到 requirements.txt|pip freeze: 输出可安装格式\n> requirements.txt: 重定向到文件|• 项目部署前\n• 团队协作共享依赖|• 在项目根目录执行\n• 建议在虚拟环境中导出|• pip install -r requirements.txt - 安装依赖"
)

COMMANDS+=(
"1.5|python|安装依赖|pip install -r requirements.txt|no|check_pip|从 requirements.txt 安装所有依赖|pip install: 安装包\n-r: 从文件读取|• 新环境配置\n• 项目初始化|• 确保文件存在\n• 建议在虚拟环境中安装|• pip install package - 安装单个包"
)

COMMANDS+=(
"1.6|python|切换pip镜像源|switch_pip_mirror|no|check_pip|切换 pip 镜像源加速下载|清华源/阿里源/默认源|• 下载速度慢时\n• 国内网络环境|• 临时使用或永久配置|• pip config list - 查看当前配置"
)

COMMANDS+=(
"1.7|python|清理pip缓存|pip cache purge|no|check_pip|清理 pip 下载缓存释放空间|pip cache: 缓存管理\npurge: 清除所有缓存|• 磁盘空间不足\n• 清理旧版本缓存|• 会清除所有已下载的包|• pip cache info - 查看缓存信息"
)

# ============================================================================
# 2. 系统优化与管理
# ============================================================================

COMMANDS+=(
"2.1|system|深度清理系统|cleanup_system|yes|none|清理系统垃圾文件，释放磁盘空间|清理内容包括：\n• 系统缓存和日志\n• 用户缓存\n• Homebrew 缓存\n• 临时文件|• 磁盘空间不足时\n• 定期维护系统|• 清理前会显示可释放空间\n• 需要管理员权限|• du -sh ~/Library/Caches - 查看缓存大小"
)

COMMANDS+=(
"2.2|system|释放内存|sudo purge|yes|none|清除磁盘缓存，释放物理内存|purge: macOS 内置命令|• 内存占用过高时\n• 运行大型应用前|• 执行时会有短暂卡顿|• vm_stat - 查看虚拟内存统计"
)

COMMANDS+=(
"2.3|system|防止系统休眠|caffeinate -d -t 3600|no|none|防止 Mac 在执行长时间任务时休眠|caffeinate: 防休眠工具\n-d: 防止显示器休眠\n-t 3600: 持续 3600 秒|• 下载大文件时\n• 运行长时间脚本|• 可按 Ctrl+C 提前终止|• caffeinate -u -t 7200 - 持续2小时"
)

COMMANDS+=(
"2.4|system|允许任何来源安装|sudo spctl --master-disable|yes|none|允许安装任何来源的应用程序|spctl: 安全评估策略\n--master-disable: 禁用 Gatekeeper|• 安装未签名应用时|• 降低系统安全性|• sudo spctl --master-enable - 恢复保护"
)

COMMANDS+=(
"2.5|system|显示隐藏文件|defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder|no|none|在 Finder 中显示所有隐藏文件|defaults write: 修改系统配置\nkillall Finder: 重启 Finder|• 需要访问系统文件时|• 隐藏文件以 . 开头|• defaults write ... -bool false - 重新隐藏"
)

COMMANDS+=(
"2.6|system|查看系统资源|top -o cpu -n 10|no|none|查看系统资源占用情况|top: 实时进程监控\n-o cpu: 按 CPU 排序\n-n 10: 只显示前 10 个|• 系统变慢时排查原因|• 按 q 退出|• top -o mem - 按内存排序"
)

COMMANDS+=(
"2.7|system|重建Spotlight索引|sudo mdutil -E /|yes|none|重建 Spotlight 搜索索引|mdutil: Spotlight 管理工具\n-E: 擦除并重建索引|• Spotlight 搜索异常\n• 找不到文件|• 重建需要较长时间|• mdutil -s / - 查看索引状态"
)

COMMANDS+=(
"2.8|system|清空废纸篓|rm -rf ~/.Trash/*|no|none|彻底清空废纸篓释放空间|rm -rf: 强制删除|• 废纸篓占用过大\n• 彻底清理文件|• 删除后无法恢复|• sudo rm -rf /Volumes/*/.Trashes - 清理外置设备"
)

COMMANDS+=(
"2.9|system|禁用系统动画|disable_animations|no|none|禁用窗口动画提升响应速度|减少视觉效果提升性能|• 老机器性能优化\n• 追求极致速度|• 可能影响使用体验|• enable_animations - 恢复动画"
)

COMMANDS+=(
"2.10|system|显示隐藏桌面图标|toggle_desktop_icons|no|none|显示或隐藏桌面所有图标|切换桌面图标显示|• 演示/录屏时\n• 保持桌面整洁|• 文件仍在桌面上|• 再次执行恢复显示"
)

# ============================================================================
# 3. Homebrew 包管理
# ============================================================================

COMMANDS+=(
"3.1|homebrew|更新Homebrew|brew update && brew upgrade|no|check_brew|更新 Homebrew 及所有已安装软件|brew update: 更新 Homebrew\nbrew upgrade: 升级所有包|• 定期维护系统\n• 获取最新功能|• 可能需要较长时间|• brew outdated - 查看可更新的包"
)

COMMANDS+=(
"3.2|homebrew|清理旧版本|brew cleanup -s|no|check_brew|清理 Homebrew 缓存和旧版本|brew cleanup: 清理工具\n-s: 清理缓存文件|• 磁盘空间不足时|• 会删除旧版本备份|• brew cleanup --dry-run - 预览"
)

COMMANDS+=(
"3.3|homebrew|查看已安装软件|brew list|no|check_brew|列出所有通过 Homebrew 安装的软件|brew list: 列出所有包|• 检查软件是否已安装|• 包含命令行工具和应用|• brew deps package - 查看依赖"
)

COMMANDS+=(
"3.4|homebrew|诊断问题|brew doctor|no|check_brew|诊断 Homebrew 配置问题|检查环境配置和潜在问题|• Homebrew 工作异常\n• 安装失败后检查|• 按提示修复问题|• brew config - 查看配置"
)

COMMANDS+=(
"3.5|homebrew|切换镜像源|switch_brew_mirror|no|check_brew|切换 Homebrew 镜像源加速下载|中科大/清华/官方源|• 下载速度慢时|• 需要网络连接测试|• 切换后需 brew update"
)

# ============================================================================
# 4. 文件与磁盘操作
# ============================================================================

COMMANDS+=(
"4.1|file|查找大文件|find_large_files|no|none|查找指定目录下的大文件|find: 文件查找命令\n-size: 按文件大小过滤|• 清理磁盘空间|• 可能需要较长时间|• du -sh * | sort -hr - 查看最大目录"
)

COMMANDS+=(
"4.2|file|删除.DS_Store|find . -name '.DS_Store' -type f -delete|no|none|删除所有 .DS_Store 文件|.DS_Store: macOS 文件夹元数据|• Git 仓库中清理\n• 发布项目前|• Finder 会重新创建|• 配合 .gitignore 忽略"
)

COMMANDS+=(
"4.3|file|批量重命名文件|batch_rename|no|none|使用正则表达式批量重命名文件|交互式输入匹配和替换模式|• 整理照片命名\n• 批量添加前缀|• 操作前会预览更改|• rename 命令 (需安装)"
)

COMMANDS+=(
"4.4|file|批量压缩图片|compress_images|no|check_sips|批量压缩图片文件减小体积|使用 sips 压缩图片|• 网站图片优化\n• 节省存储空间|• 会降低图片质量|• sips -Z 1024 image.jpg - 缩放到1024px"
)

COMMANDS+=(
"4.5|file|批量压缩文件|compress_files|no|none|将文件/目录压缩为 zip|zip 命令压缩|• 文件传输\n• 归档备份|• 支持加密压缩|• tar -czf archive.tar.gz dir - tar格式"
)

COMMANDS+=(
"4.6|file|删除文件元数据|remove_exif|no|check_exiftool|删除图片 EXIF 元数据|清除位置、设备等隐私信息|• 保护隐私\n• 发布前清理|• 需要安装 exiftool|• exiftool -all= image.jpg - 清除所有元数据"
)

COMMANDS+=(
"4.7|file|视频格式转换|convert_video|no|check_ffmpeg|转换视频文件格式|使用 ffmpeg 转换|• 格式兼容性\n• 压缩视频|• 需要安装 ffmpeg|• ffmpeg -i input.mp4 output.avi"
)

COMMANDS+=(
"4.8|file|PDF合并|merge_pdf|no|none|合并多个 PDF 文件为一个|使用 Python PDFKit 或命令行工具|• 文档整理\n• 合并扫描件|• 可能需要安装工具|• 保持原文件不变"
)

COMMANDS+=(
"4.9|file|查看文件夹大小|du -sh */ | sort -hr | head -20|no|none|查看当前目录下各文件夹大小|du: 磁盘使用统计\n-sh: 人类可读格式\nsort -hr: 按大小排序|• 查找占空间的目录|• 在指定目录运行|• ncdu - 交互式工具"
)

# ============================================================================
# 5. 网络工具
# ============================================================================

COMMANDS+=(
"5.1|network|网络测速|speedtest_network|no|check_speedtest|测试网络上传和下载速度|speedtest-cli: Python 测速工具|• 检查网络质量|• 需要安装 speedtest-cli|• networkQuality - macOS 12+ 内置"
)

COMMANDS+=(
"5.2|network|查看端口占用|lsof -i :\$PORT|no|none|查看指定端口被哪个进程占用|lsof: 列出打开的文件\n-i: 网络文件|• 端口冲突排查|• 需要输入端口号|• netstat -anv | grep PORT"
)

COMMANDS+=(
"5.3|network|刷新DNS缓存|sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder|yes|none|清除系统 DNS 缓存|dscacheutil: 目录服务缓存工具|• 无法访问网站时\n• DNS 设置更改后|• 需要管理员权限|• scutil --dns - 查看 DNS 配置"
)

COMMANDS+=(
"5.4|network|查看本机IP|get_ip_address|no|none|显示本机内网和外网 IP 地址|ifconfig: 网络接口配置\ncurl: 获取外网 IP|• 配置网络服务\n• 远程访问准备|• 外网 IP 查询需要网络|• curl ifconfig.me - 查询外网 IP"
)

COMMANDS+=(
"5.5|network|切换DNS服务器|switch_dns|yes|none|切换系统 DNS 服务器|Google/Cloudflare/阿里/自定义|• 提升解析速度\n• 访问特定网站|• 需要管理员权限|• networksetup -getdnsservers Wi-Fi - 查看当前DNS"
)

COMMANDS+=(
"5.6|network|查看WiFi密码|get_wifi_password|no|none|查看已连接 WiFi 的密码|从钥匙串读取密码|• 分享WiFi密码\n• 忘记密码时|• 需要输入系统密码|• 仅显示当前网络密码"
)

COMMANDS+=(
"5.7|network|配置系统代理|configure_proxy|no|none|配置系统 HTTP/HTTPS 代理|设置代理服务器和端口|• 使用公司代理\n• 开发调试|• 影响所有网络连接|• networksetup -setwebproxy - 设置代理"
)

COMMANDS+=(
"5.8|network|杀死端口进程|kill_port_process|no|none|杀死占用指定端口的进程|查找并终止占用端口的进程|• 端口被占用\n• 开发端口冲突|• 会强制终止进程|• lsof -ti:端口 | xargs kill -9"
)

COMMANDS+=(
"5.9|network|网络质量测试|network_quality_test|no|none|测试网络延迟和丢包率|ping 测试和统计|• 网络诊断\n• 判断网络稳定性|• 测试时间较长|• ping -c 10 8.8.8.8"
)

# ============================================================================
# 6. 界面与外观优化
# ============================================================================

COMMANDS+=(
"6.1|appearance|修改截图格式|defaults write com.apple.screencapture type \$FORMAT && killall SystemUIServer|no|none|修改截图保存格式|defaults write: 修改系统配置\ntype: 截图格式|• 需要特定格式截图|• 支持 png/jpg/pdf/tiff|• defaults write ... type png - 恢复默认"
)

COMMANDS+=(
"6.2|appearance|修改截图位置|defaults write com.apple.screencapture location \$PATH && killall SystemUIServer|no|none|自定义截图保存位置|location: 保存路径|• 保持桌面整洁|• 路径必须存在|• 恢复默认: ~/Desktop"
)

COMMANDS+=(
"6.3|appearance|调整Dock大小|defaults write com.apple.dock tilesize -int \$SIZE && killall Dock|no|none|调整 Dock 图标大小|tilesize: Dock 图标大小\n范围: 16-128|• 屏幕空间优化|• 大小单位为像素|• 默认值: 48"
)

COMMANDS+=(
"6.4|appearance|切换深色模式|toggle_dark_mode|no|none|快速切换深色/浅色外观模式|osascript: 运行 AppleScript|• 夜间保护眼睛\n• 省电（OLED屏）|• macOS 10.14+ 支持|• 可在系统设置中配置自动"
)

COMMANDS+=(
"6.5|appearance|禁用截图阴影|defaults write com.apple.screencapture disable-shadow -bool true && killall SystemUIServer|no|none|禁用窗口截图的阴影效果|disable-shadow: 控制阴影|• 获得纯净截图|• 仅影响窗口截图|• -bool false 恢复阴影"
)

COMMANDS+=(
"6.6|appearance|Dock自动隐藏|defaults write com.apple.dock autohide -bool true && killall Dock|no|none|启用 Dock 自动隐藏|autohide: 自动隐藏设置|• 扩大屏幕空间|• 鼠标移到边缘显示|• -bool false 取消隐藏"
)

COMMANDS+=(
"6.7|appearance|调整Dock速度|defaults write com.apple.dock autohide-time-modifier -float 0.5 && killall Dock|no|none|调整 Dock 显示/隐藏速度|time-modifier: 动画时间\n0.5 = 更快|• 提升响应速度|• 数值越小越快|• 删除键恢复默认"
)

# ============================================================================
# 7. 开发工具集
# ============================================================================

COMMANDS+=(
"7.1|dev|编辑hosts文件|sudo nano /etc/hosts|yes|none|编辑系统 hosts 文件|hosts: 本地 DNS 映射|• 测试环境配置\n• 屏蔽广告域名|• 需要管理员权限|• dscacheutil -flushcache - 刷新DNS"
)

COMMANDS+=(
"7.2|dev|编辑环境变量|nano ~/.zshrc|no|none|编辑 Zsh 配置文件|.zshrc: Zsh 配置文件|• 添加自定义命令\n• 设置环境变量|• 修改后需 source 生效|• echo \$PATH - 查看当前 PATH"
)

COMMANDS+=(
"7.3|dev|Git全局配置|git config --global user.name \"\$NAME\" && git config --global user.email \"\$EMAIL\"|no|check_git|配置 Git 用户信息|--global: 全局配置|• 首次使用 Git\n• 更换账户信息|• 保存在 ~/.gitconfig|• git config --list - 查看配置"
)

COMMANDS+=(
"7.4|dev|Node版本管理|manage_node_version|no|check_nvm|管理 Node.js 版本|安装/切换 Node 版本|• 多项目不同版本需求|• 需要安装 nvm|• nvm use 16 - 切换版本"
)

COMMANDS+=(
"7.5|dev|Docker快捷操作|docker_operations|no|check_docker|Docker 容器快捷管理|启动/停止/清理容器|• 容器管理\n• 释放空间|• 需要安装 Docker|• docker ps - 查看运行容器"
)

COMMANDS+=(
"7.6|dev|Git批量操作|git_batch_operations|no|check_git|批量操作多个 Git 仓库|批量拉取/提交/推送|• 管理多个项目|• 在包含多个仓库的目录运行|• 会遍历子目录"
)

COMMANDS+=(
"7.7|dev|Xcode清理|clean_xcode|no|none|清理 Xcode 缓存和派生数据|清理 DerivedData 等|• Xcode 占用过大\n• 编译问题|• 可释放数 GB 空间|• ~/Library/Developer/Xcode"
)

COMMANDS+=(
"7.8|dev|代码行数统计|count_code_lines|no|check_cloc|统计项目代码行数|使用 cloc 工具统计|• 项目评估\n• 了解代码规模|• 需要安装 cloc|• cloc . - 统计当前目录"
)

# ============================================================================
# 8. 隐私与安全
# ============================================================================

COMMANDS+=(
"11.1|security|清除使用痕迹|clear_traces|no|none|清除系统使用痕迹保护隐私|清除最近文件、搜索历史等|• 保护隐私\n• 公共电脑使用后|• 不影响正常功能|• 可选择清理项目"
)

COMMANDS+=(
"11.2|security|加密文件夹|encrypt_folder|no|none|创建加密的磁盘镜像|使用磁盘工具创建加密 DMG|• 保护敏感文件\n• 便携加密存储|• 需要记住密码|• 使用 AES-256 加密"
)

COMMANDS+=(
"11.3|security|查看网络连接|lsof -i -P -n | grep LISTEN|no|none|查看所有网络监听端口|列出监听的端口和程序|• 安全审计\n• 检查异常连接|• 某些需要 sudo|• netstat -anv - 详细信息"
)

COMMANDS+=(
"11.4|security|生成强密码|generate_password|no|none|生成随机强密码|可自定义长度和复杂度|• 创建新账号\n• 定期更换密码|• 自动复制到剪贴板|• 建议 16 位以上"
)

COMMANDS+=(
"11.5|security|安全删除文件|srm -rfm \$FILE|no|check_srm|多次覆写安全删除文件|srm: 安全删除工具\n多次覆写防止恢复|• 删除敏感文件\n• 确保数据不可恢复|• 删除速度较慢|• 删除后无法恢复"
)

COMMANDS+=(
"11.6|security|查看应用权限|check_app_permissions|no|none|查看应用的系统权限|查看相机、麦克风等权限|• 隐私审计\n• 检查权限授予|• macOS 10.15+ 支持|• 系统设置中可管理"
)

COMMANDS+=(
"11.7|security|配置防火墙|configure_firewall|yes|none|配置 macOS 防火墙|启用/禁用防火墙和规则|• 提升安全性\n• 控制网络访问|• 需要管理员权限|• 系统设置中也可配置"
)

COMMANDS+=(
"11.8|security|查看钥匙串|open -a 'Keychain Access'|no|none|打开钥匙串访问应用|查看保存的密码和证书|• 查看保存的密码\n• 管理证书|• 需要输入系统密码|• 钥匙串中的密码已加密"
)

# ============================================================================
# 9. 应用管理
# ============================================================================

COMMANDS+=(
"8.1|app|强制退出应用|killall -9 \$APP_NAME|no|none|强制终止指定应用程序|killall: 按名称终止进程\n-9: 强制终止|• 应用无响应时|• 数据可能丢失|• pkill APP - 模糊匹配"
)

COMMANDS+=(
"8.2|app|查看启动项|launchctl list | grep -v com.apple|no|none|查看开机自启动项|launchctl: 启动项管理|• 优化开机速度\n• 检查自启动软件|• 第一列是 PID|• 系统设置中可管理"
)

COMMANDS+=(
"8.3|app|完全卸载应用|uninstall_app_completely|no|none|完全卸载应用及相关文件|删除应用、偏好设置、缓存等|• 彻底删除应用\n• 释放完整空间|• 删除前建议备份|• 需要输入应用名"
)

COMMANDS+=(
"8.4|app|查看应用大小|du -sh /Applications/* | sort -hr | head -20|no|none|查看应用程序占用空间|列出最大的 20 个应用|• 清理大型应用\n• 了解空间占用|• 仅显示 /Applications|• 不包括用户数据"
)

COMMANDS+=(
"8.5|app|导出应用列表|export_app_list|no|none|导出已安装应用列表|生成应用清单文件|• 系统迁移\n• 备份记录|• 保存为文本文件|• 包括 Mac App Store 应用"
)

# ============================================================================
# 10. 快捷操作中心
# ============================================================================

COMMANDS+=(
"9.1|quick|重启Finder|killall Finder|no|none|重启 Finder 解决显示问题|killall Finder: 重启访达|• Finder 无响应\n• 文件显示异常|• 会关闭所有 Finder 窗口|• 自动重新打开"
)

COMMANDS+=(
"9.2|quick|重启Dock|killall Dock|no|none|重启 Dock 解决显示问题|killall Dock: 重启程序坞|• Dock 图标异常\n• 设置不生效|• 会短暂消失后恢复|• defaults delete com.apple.dock - 重置设置"
)

COMMANDS+=(
"9.3|quick|打开常用目录|open_common_dirs|no|none|快速打开常用系统目录|open: 打开文件或目录|• 快速导航\n• 访问系统目录|• 用 Finder 打开|• open . - 打开当前目录"
)

COMMANDS+=(
"9.4|quick|快速截图|screencapture -i ~/Desktop/screenshot.png|no|none|交互式截图工具|screencapture: 截图命令\n-i: 交互式选择|• 快速截图\n• 命令行截图|• 保存到桌面|• -T 5 延时5秒"
)

COMMANDS+=(
"9.5|quick|音频设备切换|switch_audio_device|no|check_switchaudio|快速切换音频输入/输出设备|切换扬声器、耳机等|• 快速切换音频设备|• 需要安装 switchaudio-osx|• brew install switchaudio-osx"
)

# ============================================================================
# 11. 性能与监控
# ============================================================================

COMMANDS+=(
"10.1|monitor|系统资源监控|system_monitor|no|none|实时显示系统资源使用情况|综合显示CPU、内存、磁盘等|• 性能监控\n• 资源占用分析|• 按 q 退出|• Activity Monitor.app - 图形界面"
)

COMMANDS+=(
"10.2|monitor|CPU占用排行|ps aux | sort -rk 3 | head -11|no|none|显示 CPU 占用前 10 的进程|ps: 进程状态\nsort -rk 3: 按CPU排序|• 查找耗CPU进程\n• 性能问题排查|• 实时快照|• top -o cpu - 实时监控"
)

COMMANDS+=(
"10.3|monitor|内存占用排行|ps aux | sort -rk 4 | head -11|no|none|显示内存占用前 10 的进程|sort -rk 4: 按内存排序|• 查找耗内存进程\n• 内存泄漏排查|• 实时快照|• top -o mem - 实时监控"
)

COMMANDS+=(
"10.4|monitor|磁盘IO监控|iostat -w 1 -c 10|no|none|监控磁盘 I/O 活动|iostat: I/O 统计工具|• 磁盘性能问题\n• 查找频繁读写进程|• 支持所有 macOS|• -w 1 每秒刷新，-c 10 次数"
)

COMMANDS+=(
"10.5|monitor|电池健康检查|system_profiler SPPowerDataType|no|none|查看电池健康状态|显示循环次数、健康度等|• 了解电池状态\n• 判断是否需要更换|• 仅限笔记本电脑|• coconutBattery - 更详细信息"
)

# ============================================================================
# 辅助函数 - 依赖检查
# ============================================================================

check_python() {
    if ! command -v python3 &> /dev/null; then
        show_error "未检测到 Python 3"
        show_info "请安装 Python 3: https://www.python.org/downloads/"
        return 1
    fi
    return 0
}

check_pip() {
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        show_error "未检测到 pip"
        show_info "请运行: python3 -m ensurepip --upgrade"
        return 1
    fi
    return 0
}

check_brew() {
    if ! command -v brew &> /dev/null; then
        show_error "未检测到 Homebrew"
        if confirm "是否现在安装 Homebrew？"; then
            show_info "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            return $?
        fi
        return 1
    fi
    return 0
}

check_git() {
    if ! command -v git &> /dev/null; then
        show_error "未检测到 Git"
        show_info "请运行: xcode-select --install"
        return 1
    fi
    return 0
}

check_speedtest() {
    if ! command -v speedtest-cli &> /dev/null; then
        show_warning "未检测到 speedtest-cli"
        if confirm "是否现在安装？(需要 pip)"; then
            pip3 install speedtest-cli --break-system-packages
            return $?
        fi
        return 1
    fi
    return 0
}

check_sips() {
    # sips 是 macOS 内置工具，一般都有
    return 0
}

check_exiftool() {
    if ! command -v exiftool &> /dev/null; then
        show_warning "未检测到 exiftool"
        if confirm "是否现在安装？(需要 Homebrew)"; then
            brew install exiftool
            return $?
        fi
        return 1
    fi
    return 0
}

check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        show_warning "未检测到 ffmpeg"
        if confirm "是否现在安装？(需要 Homebrew)"; then
            brew install ffmpeg
            return $?
        fi
        return 1
    fi
    return 0
}

# 读取配置键（需要 jq）
read_config_key() {
    local key="$1"
    if [ "${CMD_HELPER_DISABLE_JQ:-0}" != "1" ] && command -v jq >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
        jq -r --arg k "$key" '.[$k] // empty' "$CONFIG_FILE" 2>/dev/null
    fi
}

telemetry_enabled() {
    # 环境变量优先
    if [ "$MCMD_TELEMETRY" = "1" ]; then
        return 0
    fi
    # 配置文件
    local val
    val=$(read_config_key telemetry)
    [ "$val" = "on" ] && return 0
    return 1
}

record_metric() {
    local cmd_id="$1"; local status="$2"; local duration="$3"
    telemetry_enabled || return 0
    mkdir -p "$CONFIG_DIR"
    if [ "${CMD_HELPER_DISABLE_JQ:-0}" != "1" ] && command -v jq >/dev/null 2>&1; then
        [ -f "$METRICS_FILE" ] || echo '{"total":0,"commands":{}}' > "$METRICS_FILE"
        tmp=$(mktemp)
        jq --arg id "$cmd_id" --arg s "$status" --arg d "$duration" '
            .total += 1 |
            .commands[$id].count = ( (.commands[$id].count // 0) + 1 ) |
            .commands[$id].last_status = $s |
            .commands[$id].last_duration = $d
        ' "$METRICS_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$METRICS_FILE"
    else
        echo "$(date +%s)|$cmd_id|$status|$duration" >> "$CONFIG_DIR/metrics.log"
    fi
}

# jq 依赖（收藏与组合需要）
check_jq() {
    if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq &> /dev/null; then
        show_warning "未检测到 jq"
        show_info "收藏夹与命令组合需要 jq。建议安装: brew install jq"
        return 1
    fi
    return 0
}

check_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        show_warning "未检测到 nvm"
        if confirm "是否现在安装 nvm？"; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
            return $?
        fi
        return 1
    fi
    return 0
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        show_error "未检测到 Docker"
        show_info "请访问: https://www.docker.com/products/docker-desktop"
        return 1
    fi
    return 0
}

check_cloc() {
    if ! command -v cloc &> /dev/null; then
        show_warning "未检测到 cloc"
        if confirm "是否现在安装？(需要 Homebrew)"; then
            brew install cloc
            return $?
        fi
        return 1
    fi
    return 0
}

check_srm() {
    if ! command -v srm &> /dev/null; then
        show_warning "未检测到 srm"
        show_info "macOS 10.12+ 已移除 srm，将使用替代方法"
        return 0
    fi
    return 0
}

check_iotop() {
    # macOS 没有原生 iotop，提示使用替代方案
    show_warning "macOS 没有 iotop，将使用 fs_usage"
    return 0
}

check_switchaudio() {
    if ! command -v SwitchAudioSource &> /dev/null; then
        show_warning "未检测到 switchaudio-osx"
        if confirm "是否现在安装？(需要 Homebrew)"; then
            brew install switchaudio-osx
            return $?
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# 命令实现函数
# ============================================================================

# 系统清理
cleanup_system() {
    show_info "正在扫描可清理的空间..."
    
    echo -e "\n${COLOR_INFO}将清理以下内容:${COLOR_RESET}"
    
    if [ -d ~/Library/Caches ]; then
        local cache_size=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}')
        echo "  • 用户缓存: $cache_size"
    fi
    
    if [ -d ~/Library/Logs ]; then
        local log_size=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}')
        echo "  • 日志文件: $log_size"
    fi
    
    if command -v brew &> /dev/null && [ -d ~/Library/Caches/Homebrew ]; then
        local brew_size=$(du -sh ~/Library/Caches/Homebrew 2>/dev/null | awk '{print $1}')
        echo "  • Homebrew 缓存: $brew_size"
    fi
    
    echo "  • 系统临时文件"
    echo "  • 系统缓存和日志"
    
    if ! confirm "确认清理？"; then
        show_info "已取消清理"
        return
    fi
    
    show_loading "清理用户缓存" 1
    rm -rf ~/Library/Caches/* 2>/dev/null
    
    show_loading "清理日志文件" 1
    rm -rf ~/Library/Logs/* 2>/dev/null
    
    if command -v brew &> /dev/null; then
        show_loading "清理 Homebrew 缓存" 1
        brew cleanup -s 2>/dev/null
    fi

    # 出于安全考虑，系统级清理默认不执行
    show_info "已完成用户级清理（系统级清理已禁用，降低风险）"
    
    show_success "系统清理完成！建议重启 Finder 刷新显示"
}

# 查找大文件
find_large_files() {
    echo -ne "${COLOR_ACCENT}请输入文件大小阈值 (MB) [默认: 100]: ${COLOR_RESET}"
    read -r size_threshold
    size_threshold=${size_threshold:-100}
    
    echo -ne "${COLOR_ACCENT}请输入搜索目录 [默认: ~]: ${COLOR_RESET}"
    read -r search_dir
    search_dir=${search_dir:-~}
    
    show_loading "搜索大于 ${size_threshold}MB 的文件" 2
    
    echo -e "\n${COLOR_INFO}找到以下大文件:${COLOR_RESET}\n"
    find "$search_dir" -type f -size +${size_threshold}M -exec ls -lh {} \; 2>/dev/null | \
        awk '{printf "%-10s %s\n", $5, $9}' | \
        sort -hr | \
        head -20
}

# 批量重命名
batch_rename() {
    echo -ne "${COLOR_ACCENT}请输入文件所在目录 [默认: 当前目录]: ${COLOR_RESET}"
    read -r target_dir
    target_dir=${target_dir:-.}
    
    echo -ne "${COLOR_ACCENT}请输入文件匹配模式 (如: *.txt): ${COLOR_RESET}"
    read -r pattern
    
    echo -ne "${COLOR_ACCENT}请输入查找字符串: ${COLOR_RESET}"
    read -r find_str
    
    echo -ne "${COLOR_ACCENT}请输入替换字符串: ${COLOR_RESET}"
    read -r replace_str
    
    echo -e "\n${COLOR_INFO}预览更改:${COLOR_RESET}\n"
    
    local count=0
    for file in "$target_dir"/$pattern; do
        if [ -f "$file" ]; then
            local new_name=$(basename "$file" | sed "s/$find_str/$replace_str/")
            echo "  $(basename "$file") → $new_name"
            ((count++))
        fi
    done
    
    if [ $count -eq 0 ]; then
        show_warning "未找到匹配的文件"
        return
    fi
    
    if confirm "确认重命名 $count 个文件？"; then
        for file in "$target_dir"/$pattern; do
            if [ -f "$file" ]; then
                local new_name=$(basename "$file" | sed "s/$find_str/$replace_str/")
                mv "$file" "$target_dir/$new_name"
            fi
        done
        show_success "重命名完成！"
    else
        show_info "已取消操作"
    fi
}

# 网络测速
speedtest_network() {
    show_loading "连接测速服务器" 2
    echo ""
    speedtest-cli --simple
}

# 获取 IP 地址
get_ip_address() {
    echo -e "\n${COLOR_INFO}${ICON_NETWORK} 网络信息:${COLOR_RESET}\n"
    
    local_ip=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -n "$local_ip" ]; then
        echo "  内网 IP (Wi-Fi): $local_ip"
    fi
    
    local_ip_eth=$(ipconfig getifaddr en1 2>/dev/null)
    if [ -n "$local_ip_eth" ]; then
        echo "  内网 IP (以太网): $local_ip_eth"
    fi
    
    echo -ne "  外网 IP: "
    public_ip=$(curl -s --max-time 5 ifconfig.me)
    if [ -n "$public_ip" ]; then
        echo "$public_ip"
    else
        echo "获取失败"
    fi
    
    echo ""
}

# 切换深色模式
toggle_dark_mode() {
    current_mode=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
    
    if [ "$current_mode" == "Dark" ]; then
        osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to false' 2>/dev/null
        show_success "已切换到浅色模式"
    else
        osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true' 2>/dev/null
        show_success "已切换到深色模式"
    fi
}

# 打开常用目录
open_common_dirs() {
    echo -e "\n${COLOR_INFO}请选择要打开的目录:${COLOR_RESET}\n"
    echo "  1. 桌面 (Desktop)"
    echo "  2. 下载 (Downloads)"
    echo "  3. 文档 (Documents)"
    echo "  4. 应用程序 (Applications)"
    echo "  5. 用户库 (~/Library)"
    echo "  6. 系统库 (/Library)"
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1) open ~/Desktop && show_success "已打开桌面" ;;
        2) open ~/Downloads && show_success "已打开下载" ;;
        3) open ~/Documents && show_success "已打开文档" ;;
        4) open /Applications && show_success "已打开应用程序" ;;
        5) open ~/Library && show_success "已打开用户库" ;;
        6) open /Library && show_success "已打开系统库" ;;
        *) show_error "无效选项" ;;
    esac
}

# 系统资源监控
system_monitor() {
    echo -e "\n${COLOR_INFO}${ICON_MONITOR} 系统资源监控${COLOR_RESET}\n"
    
    echo "CPU 使用率前 5:"
    ps aux | sort -rk 3 | head -6 | tail -5 | awk '{printf "  %-20s %5.1f%%\n", $11, $3}'
    
    echo -e "\n内存使用率前 5:"
    ps aux | sort -rk 4 | head -6 | tail -5 | awk '{printf "  %-20s %5.1f%%\n", $11, $4}'
    
    echo -e "\n磁盘使用情况:"
    df -h / | tail -1 | awk '{printf "  已用: %s / 总计: %s (使用率: %s)\n", $3, $2, $5}'
    
    echo -e "\n内存使用情况:"
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("  %-20s % 8.2f MB\n", "$1:", $2 * $size / 1048576);'
    
    echo -e "\n${COLOR_DIM}提示: 使用 Activity Monitor.app 查看更详细信息${COLOR_RESET}"
}

# 切换 pip 镜像源
switch_pip_mirror() {
    echo -e "\n${COLOR_INFO}选择 pip 镜像源:${COLOR_RESET}\n"
    echo "  1. 清华大学镜像（推荐国内用户）"
    echo "  2. 阿里云镜像"
    echo "  3. 豆瓣镜像"
    echo "  4. 恢复官方源"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
            show_success "已切换到清华大学镜像"
            ;;
        2)
            pip3 config set global.index-url https://mirrors.aliyun.com/pypi/simple/
            show_success "已切换到阿里云镜像"
            ;;
        3)
            pip3 config set global.index-url https://pypi.douban.com/simple/
            show_success "已切换到豆瓣镜像"
            ;;
        4)
            pip3 config unset global.index-url
            show_success "已恢复官方源"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 禁用系统动画
disable_animations() {
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    defaults write com.apple.dock launchanim -bool false
    defaults write com.apple.dock expose-animation-duration -float 0.1
    killall Dock
    show_success "已禁用系统动画，重启 Dock 生效"
}

# 启用系统动画
enable_animations() {
    defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled
    defaults delete NSGlobalDomain NSWindowResizeTime
    defaults delete com.apple.dock launchanim
    defaults delete com.apple.dock expose-animation-duration
    killall Dock
    show_success "已恢复系统动画"
}

# 切换桌面图标显示
toggle_desktop_icons() {
    current_state=$(defaults read com.apple.finder CreateDesktop 2>/dev/null)
    
    if [ "$current_state" == "0" ] || [ "$current_state" == "false" ]; then
        defaults write com.apple.finder CreateDesktop -bool true
        show_success "已显示桌面图标"
    else
        defaults write com.apple.finder CreateDesktop -bool false
        show_success "已隐藏桌面图标"
    fi
    
    killall Finder
}

# 切换 Homebrew 镜像源
switch_brew_mirror() {
    echo -e "\n${COLOR_INFO}选择 Homebrew 镜像源:${COLOR_RESET}\n"
    echo "  1. 中科大镜像（推荐）"
    echo "  2. 清华大学镜像"
    echo "  3. 恢复官方源"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
            export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
            export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
            export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
            show_success "已切换到中科大镜像（当前会话有效）"
            show_info "要永久生效，请将上述 export 语句添加到 ~/.zshrc"
            ;;
        2)
            export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
            export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
            show_success "已切换到清华大学镜像（当前会话有效）"
            ;;
        3)
            unset HOMEBREW_API_DOMAIN
            unset HOMEBREW_BOTTLE_DOMAIN
            unset HOMEBREW_BREW_GIT_REMOTE
            unset HOMEBREW_CORE_GIT_REMOTE
            show_success "已恢复官方源"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 压缩图片
compress_images() {
    echo -ne "${COLOR_ACCENT}请输入图片所在目录 [默认: 当前目录]: ${COLOR_RESET}"
    read -r target_dir
    target_dir=${target_dir:-.}
    
    echo -ne "${COLOR_ACCENT}请输入压缩质量 (1-100) [默认: 80]: ${COLOR_RESET}"
    read -r quality
    quality=${quality:-80}
    
    echo -ne "${COLOR_ACCENT}请输入文件匹配模式 (如: *.jpg) [默认: *.jpg]: ${COLOR_RESET}"
    read -r pattern
    pattern=${pattern:-"*.jpg"}
    
    local count=0
    for file in "$target_dir"/$pattern; do
        if [ -f "$file" ]; then
            sips -s format jpeg -s formatOptions "$quality" "$file" --out "$file" 2>/dev/null
            ((count++))
        fi
    done
    
    if [ $count -gt 0 ]; then
        show_success "已压缩 $count 个图片文件"
    else
        show_warning "未找到匹配的图片文件"
    fi
}

# 压缩文件
compress_files() {
    echo -ne "${COLOR_ACCENT}请输入要压缩的文件/目录路径: ${COLOR_RESET}"
    read -r source
    
    if [ ! -e "$source" ]; then
        show_error "路径不存在: $source"
        return
    fi
    
    echo -ne "${COLOR_ACCENT}请输入输出文件名 [默认: archive.zip]: ${COLOR_RESET}"
    read -r output
    output=${output:-archive.zip}
    
    if confirm "是否加密压缩？"; then
        echo -ne "${COLOR_ACCENT}请输入密码: ${COLOR_RESET}"
        read -rs password
        echo ""
        zip -r -e -P "$password" "$output" "$source"
    else
        zip -r "$output" "$source"
    fi
    
    if [ $? -eq 0 ]; then
        show_success "压缩完成: $output"
    else
        show_error "压缩失败"
    fi
}

# 删除 EXIF
remove_exif() {
    echo -ne "${COLOR_ACCENT}请输入图片文件或目录: ${COLOR_RESET}"
    read -r target
    
    if [ ! -e "$target" ]; then
        show_error "路径不存在: $target"
        return
    fi
    
    if [ -d "$target" ]; then
        exiftool -all= -r "$target"
    else
        exiftool -all= "$target"
    fi
    
    show_success "EXIF 元数据已删除"
}

# 视频格式转换
convert_video() {
    echo -ne "${COLOR_ACCENT}请输入输入视频文件: ${COLOR_RESET}"
    read -r input
    
    if [ ! -f "$input" ]; then
        show_error "文件不存在: $input"
        return
    fi
    
    echo -ne "${COLOR_ACCENT}请输入输出格式 (mp4/avi/mkv/mov): ${COLOR_RESET}"
    read -r format
    
    output="${input%.*}.$format"
    
    show_loading "正在转换视频格式" 1
    ffmpeg -i "$input" "$output" -y 2>/dev/null
    
    if [ $? -eq 0 ]; then
        show_success "转换完成: $output"
    else
        show_error "转换失败"
    fi
}

# PDF 合并
merge_pdf() {
    echo -ne "${COLOR_ACCENT}请输入PDF文件所在目录: ${COLOR_RESET}"
    read -r pdf_dir
    
    if [ ! -d "$pdf_dir" ]; then
        show_error "目录不存在: $pdf_dir"
        return
    fi
    
    echo -ne "${COLOR_ACCENT}请输入输出文件名 [默认: merged.pdf]: ${COLOR_RESET}"
    read -r output
    output=${output:-merged.pdf}
    
    # 使用 Python 合并 PDF
    python3 << 'EOF'
import sys
import os
from PyPDF2 import PdfMerger
import glob

pdf_dir = input()
output = input()

merger = PdfMerger()
pdf_files = sorted(glob.glob(os.path.join(pdf_dir, "*.pdf")))

for pdf in pdf_files:
    merger.append(pdf)

merger.write(output)
merger.close()
print(f"已合并 {len(pdf_files)} 个 PDF 文件")
EOF
}

# 切换 DNS
switch_dns() {
    echo -e "\n${COLOR_INFO}选择 DNS 服务器:${COLOR_RESET}\n"
    echo "  1. Google DNS (8.8.8.8, 8.8.4.4)"
    echo "  2. Cloudflare DNS (1.1.1.1, 1.0.0.1)"
    echo "  3. 阿里 DNS (223.5.5.5, 223.6.6.6)"
    echo "  4. 114 DNS (114.114.114.114)"
    echo "  5. 自定义 DNS"
    echo "  6. 恢复自动 DNS"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    # 获取当前网络服务
    local network_service=$(networksetup -listallnetworkservices | grep -v asterisk | head -n 1)
    
    case $choice in
        1)
            sudo networksetup -setdnsservers "$network_service" 8.8.8.8 8.8.4.4
            show_success "已切换到 Google DNS"
            ;;
        2)
            sudo networksetup -setdnsservers "$network_service" 1.1.1.1 1.0.0.1
            show_success "已切换到 Cloudflare DNS"
            ;;
        3)
            sudo networksetup -setdnsservers "$network_service" 223.5.5.5 223.6.6.6
            show_success "已切换到阿里 DNS"
            ;;
        4)
            sudo networksetup -setdnsservers "$network_service" 114.114.114.114
            show_success "已切换到 114 DNS"
            ;;
        5)
            echo -ne "${COLOR_ACCENT}请输入DNS服务器地址（多个用空格分隔）: ${COLOR_RESET}"
            read -r custom_dns
            sudo networksetup -setdnsservers "$network_service" $custom_dns
            show_success "已切换到自定义 DNS"
            ;;
        6)
            sudo networksetup -setdnsservers "$network_service" "Empty"
            show_success "已恢复自动 DNS"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
    
    # 刷新 DNS 缓存
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}

# 查看 WiFi 密码
get_wifi_password() {
    # 识别 Wi-Fi 设备
    local wifi_device
    wifi_device=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi|Wi\xfFi|AirPort/{getline; if($1=="Device:") print $2}')
    [ -z "$wifi_device" ] && wifi_device="en0"

    local ssid
    ssid=$(networksetup -getairportnetwork "$wifi_device" 2>/dev/null | awk -F': ' '{print $2}')

    if [ -z "$ssid" ] || [[ "$ssid" == *"not associated"* ]]; then
        # 尝试使用 airport 获取
        local airport_bin="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
        if [ -x "$airport_bin" ]; then
            ssid=$("$airport_bin" -I 2>/dev/null | awk -F': ' '/ SSID/{print $2; exit}')
        fi
    fi

    if [ -z "$ssid" ]; then
        show_error "未连接到 Wi‑Fi 网络"
        return
    fi

    echo -e "\n${COLOR_INFO}当前网络: $ssid${COLOR_RESET}\n"
    show_info "需要系统密码以从钥匙串读取 Wi‑Fi 密码"

    # 优先使用 -wa 输出纯密码；失败时回退 -ga
    local pass
    pass=$(security find-generic-password -wa "$ssid" 2>/dev/null)
    if [ -n "$pass" ]; then
        echo "password: $pass"
    else
        security find-generic-password -ga "$ssid" 2>&1 | grep "password:"
    fi
}

# 配置系统代理
configure_proxy() {
    echo -e "\n${COLOR_INFO}配置系统代理:${COLOR_RESET}\n"
    echo "  1. 设置 HTTP 代理"
    echo "  2. 设置 HTTPS 代理"
    echo "  3. 设置 SOCKS5 代理"
    echo "  4. 禁用代理"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    local network_service=$(networksetup -listallnetworkservices | grep -v asterisk | head -n 1)
    
    case $choice in
        1|2|3)
            echo -ne "${COLOR_ACCENT}请输入代理服务器地址: ${COLOR_RESET}"
            read -r proxy_host
            
            echo -ne "${COLOR_ACCENT}请输入代理端口: ${COLOR_RESET}"
            read -r proxy_port
            
            if [ "$choice" == "1" ]; then
                networksetup -setwebproxy "$network_service" "$proxy_host" "$proxy_port"
                show_success "已设置 HTTP 代理"
            elif [ "$choice" == "2" ]; then
                networksetup -setsecurewebproxy "$network_service" "$proxy_host" "$proxy_port"
                show_success "已设置 HTTPS 代理"
            else
                networksetup -setsocksfirewallproxy "$network_service" "$proxy_host" "$proxy_port"
                show_success "已设置 SOCKS5 代理"
            fi
            ;;
        4)
            networksetup -setwebproxystate "$network_service" off
            networksetup -setsecurewebproxystate "$network_service" off
            networksetup -setsocksfirewallproxystate "$network_service" off
            show_success "已禁用所有代理"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 杀死端口进程
kill_port_process() {
    echo -ne "${COLOR_ACCENT}请输入要释放的端口号: ${COLOR_RESET}"
    read -r port
    
    local pid=$(lsof -ti:$port)
    
    if [ -z "$pid" ]; then
        show_warning "端口 $port 未被占用"
        return
    fi
    
    echo -e "\n${COLOR_INFO}端口 $port 被以下进程占用:${COLOR_RESET}"
    lsof -i:$port
    
    if confirm "确认杀死该进程？"; then
        kill -9 $pid
        show_success "已杀死占用端口 $port 的进程"
    else
        show_info "已取消操作"
    fi
}

# 网络质量测试
network_quality_test() {
    echo -ne "${COLOR_ACCENT}请输入测试目标 [默认: 8.8.8.8]: ${COLOR_RESET}"
    read -r target
    target=${target:-8.8.8.8}
    
    echo -ne "${COLOR_ACCENT}请输入测试次数 [默认: 10]: ${COLOR_RESET}"
    read -r count
    count=${count:-10}
    
    show_loading "正在测试网络质量" 1
    
    echo -e "\n${COLOR_INFO}Ping 测试结果:${COLOR_RESET}\n"
    ping -c $count $target | tail -2
}

# Node 版本管理
manage_node_version() {
    if [ ! -d "$HOME/.nvm" ]; then
        show_error "nvm 未安装"
        return
    fi
    
    source "$HOME/.nvm/nvm.sh"
    
    echo -e "\n${COLOR_INFO}Node.js 版本管理:${COLOR_RESET}\n"
    echo "  1. 查看已安装版本"
    echo "  2. 安装最新 LTS 版本"
    echo "  3. 切换 Node 版本"
    echo "  4. 查看当前版本"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            nvm list
            ;;
        2)
            nvm install --lts
            show_success "已安装最新 LTS 版本"
            ;;
        3)
            nvm list
            echo -ne "\n${COLOR_ACCENT}请输入要切换的版本: ${COLOR_RESET}"
            read -r version
            nvm use $version
            ;;
        4)
            node --version
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# Docker 操作
docker_operations() {
    echo -e "\n${COLOR_INFO}Docker 快捷操作:${COLOR_RESET}\n"
    echo "  1. 启动所有容器"
    echo "  2. 停止所有容器"
    echo "  3. 删除所有停止的容器"
    echo "  4. 删除无用镜像"
    echo "  5. 清理所有未使用资源"
    echo "  6. 查看资源占用"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            docker ps -aq | xargs -n 1 docker start 2>/dev/null || true
            show_success "已启动所有容器"
            ;;
        2)
            docker ps -aq | xargs -n 1 docker stop 2>/dev/null || true
            show_success "已停止所有容器"
            ;;
        3)
            docker ps -aq -f status=exited | xargs -n 1 docker rm 2>/dev/null || true
            show_success "已删除所有停止的容器"
            ;;
        4)
            docker image prune -a -f
            show_success "已删除无用镜像"
            ;;
        5)
            docker system prune -a -f --volumes
            show_success "已清理所有未使用资源"
            ;;
        6)
            docker system df
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# Git 批量操作
git_batch_operations() {
    echo -e "\n${COLOR_INFO}Git 批量操作:${COLOR_RESET}\n"
    echo "  1. 批量拉取更新（当前目录下所有仓库）"
    echo "  2. 批量查看状态"
    echo "  3. 批量清理本地分支"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo -e "\n${COLOR_INFO}更新: $dir${COLOR_RESET}"
                    (cd "$dir" && git pull)
                fi
            done
            show_success "批量更新完成"
            ;;
        2)
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo -e "\n${COLOR_INFO}$dir${COLOR_RESET}"
                    (cd "$dir" && git status -s)
                fi
            done
            ;;
        3)
            echo -ne "${COLOR_ACCENT}请输入要保留的分支（多个用空格分隔）[默认: main master]: ${COLOR_RESET}"
            read -r keep_branches
            keep_branches=${keep_branches:-"main master"}
            
            for dir in */; do
                if [ -d "$dir/.git" ]; then
                    echo -e "\n${COLOR_INFO}清理: $dir${COLOR_RESET}"
                    (cd "$dir" && git branch | grep -v -E "$(echo $keep_branches | tr ' ' '|')" | xargs git branch -d)
                fi
            done
            show_success "批量清理完成"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# Xcode 清理
clean_xcode() {
    local derived_data="$HOME/Library/Developer/Xcode/DerivedData"
    local device_support="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    local archives="$HOME/Library/Developer/Xcode/Archives"
    
    echo -e "\n${COLOR_INFO}Xcode 清理选项:${COLOR_RESET}\n"
    echo "  1. 清理 DerivedData"
    echo "  2. 清理设备支持文件"
    echo "  3. 清理归档文件"
    echo "  4. 全部清理"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            : "${derived_data:?}"
            rm -rf "$derived_data"/*
            show_success "已清理 DerivedData"
            ;;
        2)
            : "${device_support:?}"
            rm -rf "$device_support"/*
            show_success "已清理设备支持文件"
            ;;
        3)
            : "${archives:?}"
            rm -rf "$archives"/*
            show_success "已清理归档文件"
            ;;
        4)
            : "${derived_data:?}"; rm -rf "$derived_data"/*
            : "${device_support:?}"; rm -rf "$device_support"/*
            : "${archives:?}"; rm -rf "$archives"/*
            show_success "已完成全部清理"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 代码行数统计
count_code_lines() {
    echo -ne "${COLOR_ACCENT}请输入项目目录 [默认: 当前目录]: ${COLOR_RESET}"
    read -r project_dir
    project_dir=${project_dir:-.}
    
    if [ ! -d "$project_dir" ]; then
        show_error "目录不存在: $project_dir"
        return
    fi
    
    show_loading "正在统计代码行数" 2
    
    echo ""
    cloc "$project_dir"
}

# 清除使用痕迹
clear_traces() {
    echo -e "\n${COLOR_INFO}选择清除项目:${COLOR_RESET}\n"
    echo "  1. 清除最近使用的文件/应用"
    echo "  2. 清除 Safari 浏览历史"
    echo "  3. 清除 Spotlight 搜索历史"
    echo "  4. 清除终端命令历史"
    echo "  5. 全部清除"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            defaults write com.apple.recentitems RecentDocuments -dict-add maxAmount 0
            defaults write com.apple.recentitems RecentApplications -dict-add maxAmount 0
            killall Finder
            show_success "已清除最近使用的文件/应用"
            ;;
        2)
            rm -rf ~/Library/Safari/History.db*
            rm -rf ~/Library/Safari/HistoryIndex.sk
            show_success "已清除 Safari 浏览历史"
            ;;
        3)
            rm -rf ~/Library/Application\ Support/com.apple.spotlight/
            show_success "已清除 Spotlight 搜索历史"
            ;;
        4)
            cat /dev/null > ~/.zsh_history
            cat /dev/null > ~/.bash_history
            show_success "已清除终端命令历史"
            ;;
        5)
            defaults write com.apple.recentitems RecentDocuments -dict-add maxAmount 0
            defaults write com.apple.recentitems RecentApplications -dict-add maxAmount 0
            rm -rf ~/Library/Safari/History.db*
            rm -rf ~/Library/Safari/HistoryIndex.sk
            rm -rf ~/Library/Application\ Support/com.apple.spotlight/
            cat /dev/null > ~/.zsh_history
            cat /dev/null > ~/.bash_history
            killall Finder
            show_success "已完成全部清除"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 加密文件夹
encrypt_folder() {
    echo -ne "${COLOR_ACCENT}请输入要加密的文件夹路径: ${COLOR_RESET}"
    read -r folder_path
    
    if [ ! -d "$folder_path" ]; then
        show_error "文件夹不存在: $folder_path"
        return
    fi
    
    local folder_name=$(basename "$folder_path")
    local output_dmg="$folder_name.dmg"
    
    echo -ne "${COLOR_ACCENT}请输入加密密码: ${COLOR_RESET}"
    read -rs password
    echo ""
    
    show_loading "正在创建加密镜像" 2
    
    hdiutil create -encryption AES-256 -stdinpass -volname "$folder_name" -srcfolder "$folder_path" "$output_dmg" <<< "$password"
    
    if [ $? -eq 0 ]; then
        show_success "加密完成: $output_dmg"
        show_info "双击 DMG 文件并输入密码即可访问"
    else
        show_error "加密失败"
    fi
}

# 生成强密码
generate_password() {
    echo -ne "${COLOR_ACCENT}请输入密码长度 [默认: 16]: ${COLOR_RESET}"
    read -r length
    length=${length:-16}
    
    local password=$(LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c $length)
    
    echo -e "\n${COLOR_SUCCESS}生成的密码: ${BOLD}$password${COLOR_RESET}\n"
    
    # 复制到剪贴板
    echo -n "$password" | pbcopy
    show_success "密码已复制到剪贴板"
}

# 查看应用权限
check_app_permissions() {
    echo -e "\n${COLOR_INFO}系统权限查看:${COLOR_RESET}\n"
    echo "  1. 查看相机权限"
    echo "  2. 查看麦克风权限"
    echo "  3. 查看位置服务权限"
    echo "  4. 查看完全磁盘访问权限"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceCamera';"
            ;;
        2)
            sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceMicrophone';"
            ;;
        3)
            show_info "请在 系统设置 > 隐私与安全 > 位置服务 中查看"
            ;;
        4)
            show_info "请在 系统设置 > 隐私与安全 > 完全磁盘访问权限 中查看"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 配置防火墙
configure_firewall() {
    echo -e "\n${COLOR_INFO}防火墙配置:${COLOR_RESET}\n"
    echo "  1. 启用防火墙"
    echo "  2. 禁用防火墙"
    echo "  3. 查看防火墙状态"
    echo "  4. 启用隐身模式"
    echo ""
    
    echo -ne "${COLOR_ACCENT}请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
            show_success "已启用防火墙"
            ;;
        2)
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
            show_success "已禁用防火墙"
            ;;
        3)
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
            ;;
        4)
            sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
            show_success "已启用隐身模式"
            ;;
        *)
            show_error "无效选项"
            ;;
    esac
}

# 完全卸载应用
uninstall_app_completely() {
    echo -ne "${COLOR_ACCENT}请输入要卸载的应用名称 (如: Chrome): ${COLOR_RESET}"
    read -r app_name
    
    local app_path="/Applications/$app_name.app"
    
    if [ ! -d "$app_path" ]; then
        show_error "应用不存在: $app_path"
        return
    fi
    
    echo -e "\n${COLOR_WARNING}将删除以下内容:${COLOR_RESET}"
    echo "  • 应用本体: $app_path"
    echo "  • 偏好设置: ~/Library/Preferences/*$app_name*"
    echo "  • 缓存文件: ~/Library/Caches/*$app_name*"
    echo "  • 日志文件: ~/Library/Logs/*$app_name*"
    echo "  • 应用支持: ~/Library/Application Support/*$app_name*"
    
    if ! confirm "确认完全卸载？"; then
        show_info "已取消卸载"
        return
    fi
    
    # 删除应用本体
    sudo rm -rf "$app_path"
    
    # 删除相关文件
    rm -rf ~/Library/Preferences/*$app_name* 2>/dev/null
    rm -rf ~/Library/Caches/*$app_name* 2>/dev/null
    rm -rf ~/Library/Logs/*$app_name* 2>/dev/null
    rm -rf ~/Library/Application\ Support/*$app_name* 2>/dev/null
    rm -rf ~/Library/Saved\ Application\ State/*$app_name* 2>/dev/null
    
    show_success "已完全卸载 $app_name"
}

# 导出应用列表
export_app_list() {
    local output_file="installed_apps_$(date +%Y%m%d).txt"
    
    echo -e "\n${COLOR_INFO}正在导出应用列表...${COLOR_RESET}\n"
    
    {
        echo "=== Mac 已安装应用列表 ==="
        echo "导出时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "=== Applications 文件夹 ==="
        find /Applications -maxdepth 1 -type d -name "*.app" -prune -print | sed 's#.*/##; s/.app$//'
        echo ""
        echo "=== Homebrew Cask 应用 ==="
        brew list --cask 2>/dev/null || echo "未安装 Homebrew 或无 Cask 应用"
    } > "$output_file"
    
    show_success "应用列表已导出到: $output_file"
}

# 切换音频设备
switch_audio_device() {
    echo -e "\n${COLOR_INFO}音频设备列表:${COLOR_RESET}\n"
    
    SwitchAudioSource -a
    
    echo -ne "\n${COLOR_ACCENT}请输入设备名称: ${COLOR_RESET}"
    read -r device_name
    
    SwitchAudioSource -s "$device_name"
    
    if [ $? -eq 0 ]; then
        show_success "已切换到: $device_name"
    else
        show_error "切换失败"
    fi
}

# ============================================================================
# 命令说明显示
# ============================================================================

show_command_info() {
    local cmd_data="$1"
    
    IFS='|' read -r id category name command needs_sudo dependency desc params scenarios notes related <<< "$cmd_data"
    
    clear_screen
    
    echo -e "${COLOR_INFO}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${COLOR_RESET}"
    echo -e "${COLOR_INFO}┃${COLOR_RESET}  ${ICON_LIGHT} ${BOLD}命令详解${COLOR_RESET}"
    echo -e "${COLOR_INFO}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${COLOR_RESET}\n"
    
    echo -e "${COLOR_ACCENT}📌 功能说明:${COLOR_RESET}"
    echo -e "   $desc\n"
    
    # 检查是否是函数调用
    local is_function=0
    case "$command" in
        cleanup_system|find_large_files|batch_rename|speedtest_network|get_ip_address|toggle_dark_mode|open_common_dirs|system_monitor|switch_pip_mirror|disable_animations|enable_animations|toggle_desktop_icons|switch_brew_mirror|compress_images|compress_files|remove_exif|convert_video|merge_pdf|switch_dns|get_wifi_password|configure_proxy|kill_port_process|network_quality_test|manage_node_version|docker_operations|git_batch_operations|clean_xcode|count_code_lines|clear_traces|encrypt_folder|generate_password|check_app_permissions|configure_firewall|uninstall_app_completely|export_app_list|switch_audio_device)
            is_function=1
            ;;
    esac
    
    if [ $is_function -eq 0 ]; then
        echo -e "${COLOR_ACCENT}🔧 命令内容:${COLOR_RESET}"
        echo -e "   ${COLOR_DIM}$command${COLOR_RESET}\n"
    fi
    
    echo -e "${COLOR_ACCENT}📖 参数解释:${COLOR_RESET}"
    echo -e "$params" | while IFS= read -r line; do
        [ -n "$line" ] && echo "   $line"
    done
    echo ""
    
    echo -e "${COLOR_ACCENT}💼 使用场景:${COLOR_RESET}"
    echo -e "$scenarios" | while IFS= read -r line; do
        [ -n "$line" ] && echo "   $line"
    done
    echo ""
    
    echo -e "${COLOR_WARNING}⚠️  注意事项:${COLOR_RESET}"
    echo -e "$notes" | while IFS= read -r line; do
        [ -n "$line" ] && echo "   $line"
    done
    echo ""
    
    echo -e "${COLOR_INFO}🔗 相关命令:${COLOR_RESET}"
    echo -e "$related" | while IFS= read -r line; do
        [ -n "$line" ] && echo "   $line"
    done
    echo ""
    
    if [ "$needs_sudo" == "yes" ]; then
        echo -e "${COLOR_WARNING}${ICON_LOCK} 此命令需要管理员权限${COLOR_RESET}\n"
    fi
    
    draw_double_line
}

# ============================================================================
# 命令执行引擎
# ============================================================================

execute_command() {
    local cmd_data="$1"
    local skip_confirm="${2:-no}"
    
    IFS='|' read -r id category name command needs_sudo dependency desc params scenarios notes related <<< "$cmd_data"
    
    # 显示命令说明
    if [ "$skip_confirm" != "yes" ]; then
        show_command_info "$cmd_data"
        echo -e "${COLOR_INFO}操作: [y 执行] [f 收藏] [0 返回]${COLOR_RESET}"
        echo -ne "${COLOR_ACCENT}请选择: ${COLOR_RESET}"
        read -r action
        case "$action" in
            f|F)
                if check_jq; then
                    add_to_favorites "$id"
                else
                    show_error "缺少 jq，无法添加到收藏"
                fi
                press_any_key
                return 0
                ;;
            y|Y)
                ;;
            0)
                show_info "已取消执行"
                press_any_key
                return 1
                ;;
            *)
                show_info "已取消执行"
                press_any_key
                return 1
                ;;
        esac
    fi
    
    # 检查依赖
    if [ "$dependency" != "none" ]; then
        if ! $dependency; then
            press_any_key
            return 1
        fi
    fi
    
    echo ""
    draw_double_line
    echo -e "${COLOR_INFO}${ICON_ROCKET} 正在执行命令...${COLOR_RESET}\n"
    draw_double_line
    echo ""

    local start_time=$(date +%s)
    local err_file=""
    local exit_code=0

    if [ "${CMD_HELPER_TEST_MODE:-0}" = "1" ]; then
        [ -n "${CMD_HELPER_TEST_LOG:-}" ] && printf "%s|%s|%s\n" "$id" "$needs_sudo" "$command" >> "$CMD_HELPER_TEST_LOG"
        if [[ ",${CMD_HELPER_TEST_FAIL_IDS:-}," == *",$id,"* ]]; then
            exit_code=${CMD_HELPER_TEST_FAIL_CODE:-1}
        else
            exit_code=0
        fi
    else
        err_file=$(mktemp)
        if [[ "$command" == *"\$"* ]]; then
            case "$command" in
                *\$VENV_PATH*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入虚拟环境路径: ${COLOR_RESET}"
                        read -r venv_path
                        if sanitize_path "$venv_path"; then break; else show_error "路径不合法，请重试"; fi
                    done
                    command=${command//\$VENV_PATH/$venv_path}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    ;;
                *\$VENV_NAME*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入虚拟环境名称: ${COLOR_RESET}"
                        read -r venv_name
                        if sanitize_name "$venv_name"; then break; else show_error "名称不合法，请重试"; fi
                    done
                    command=${command//\$VENV_NAME/$venv_name}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    ;;
                *\$PORT*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入端口号: ${COLOR_RESET}"
                        read -r port
                        if sanitize_int "$port"; then break; else show_error "端口必须是数字"; fi
                    done
                    command=${command//\$PORT/$port}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    ;;
                *\$FORMAT*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入格式 (png/jpg/pdf): ${COLOR_RESET}"
                        read -r format
                        case "$format" in png|jpg|pdf) break;; *) show_error "格式仅支持 png/jpg/pdf";; esac
                    done
                    command=${command//\$FORMAT/$format}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    show_success "截图格式已更改为 $format"
                    ;;
                *\$PATH*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入路径: ${COLOR_RESET}"
                        read -r path
                        if sanitize_path "$path"; then break; else show_error "路径不合法，请重试"; fi
                    done
                    command=${command//\$PATH/$path}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    ;;
                *\$SIZE*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入大小 (16-128): ${COLOR_RESET}"
                        read -r size
                        if sanitize_int "$size" && [ "$size" -ge 16 ] && [ "$size" -le 128 ]; then break; else show_error "请输入 16-128 的数字"; fi
                    done
                    command=${command//\$SIZE/$size}
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    show_success "Dock 大小已调整"
                    ;;
                *\$APP_NAME*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入应用名称: ${COLOR_RESET}"
                        read -r app_name
                        if sanitize_name "$app_name"; then break; else show_error "名称不合法，请重试"; fi
                    done
                    killall -9 "$app_name" 2>"$err_file"
                    exit_code=$?
                    if [ $exit_code -eq 0 ]; then
                        show_success "已强制退出 $app_name"
                    else
                        show_error "未找到应用: $app_name"
                    fi
                    ;;
                *\$NAME*|*\$EMAIL*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入用户名: ${COLOR_RESET}"
                        read -r git_name
                        if sanitize_name "$git_name"; then break; else show_error "用户名不合法，请重试"; fi
                    done
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入邮箱: ${COLOR_RESET}"
                        read -r git_email
                        if sanitize_email "$git_email"; then break; else show_error "邮箱格式不正确"; fi
                    done
                    git config --global user.name "$git_name" 2>"$err_file"
                    git config --global user.email "$git_email" 2>>"$err_file"
                    exit_code=0
                    show_success "Git 配置完成"
                    ;;
                *"FILE"*)
                    while true; do
                        echo -ne "${COLOR_ACCENT}请输入文件路径: ${COLOR_RESET}"
                        read -r file_path
                        if sanitize_path "$file_path"; then break; else show_error "路径不合法，请重试"; fi
                    done
                    if command -v srm &> /dev/null; then
                        command=${command//\$FILE/$file_path}
                        eval "$command" 2>"$err_file"
                        exit_code=$?
                        if [ $exit_code -eq 0 ]; then
                            show_success "文件已安全删除"
                        else
                            show_error "删除失败"
                        fi
                    else
                        rm -f "$file_path" 2>"$err_file"
                        exit_code=$?
                        if [ $exit_code -eq 0 ]; then
                            show_warning "文件已删除（APFS 上无法保证不可恢复）"
                        else
                            show_error "删除失败"
                        fi
                    fi
                    ;;
                *)
                    eval "$command" 2>"$err_file"
                    exit_code=$?
                    ;;
            esac
        else
            if [ "$needs_sudo" == "yes" ]; then
                sudo bash -c "$command" 2>"$err_file"
            else
                eval "$command" 2>"$err_file"
            fi
            exit_code=$?
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    draw_double_line
    
    if [ $exit_code -eq 0 ]; then
        show_success "命令执行成功！（耗时: ${duration}秒）"
        
        # 学习要点
        echo -e "${COLOR_INFO}${ICON_LIGHT} 学习要点:${COLOR_RESET}"
        case "$category" in
            python)
                echo "  ${ICON_CHECK} Python 虚拟环境可以隔离项目依赖"
                echo "  ${ICON_CHECK} 使用 requirements.txt 管理依赖版本"
                ;;
            system)
                echo "  ${ICON_CHECK} 定期清理系统可以提升性能"
                echo "  ${ICON_CHECK} 使用系统命令比第三方工具更安全"
                ;;
            network)
                echo "  ${ICON_CHECK} 了解网络命令有助于排查连接问题"
                echo "  ${ICON_CHECK} DNS 缓存问题是网络故障常见原因"
                ;;
            security)
                echo "  ${ICON_CHECK} 定期检查隐私设置保护个人信息"
                echo "  ${ICON_CHECK} 使用强密码和加密保护敏感数据"
                ;;
            *)
                echo "  ${ICON_CHECK} 熟练使用终端可以大幅提升效率"
                ;;
        esac
        
        # 记录历史与指标
        log_to_history "$id" "$name" "success" "$duration" "$exit_code"
        record_metric "$id" "success" "$duration"
        
        if [ -n "$err_file" ] && [ -f "$err_file" ]; then
            rm -f "$err_file"
        fi
        if [ "$skip_confirm" != "yes" ]; then
            press_any_key
        fi
        return 0
    else
        show_error "命令执行失败（退出码: $exit_code）"
        log_to_history "$id" "$name" "failed" "$duration" "$exit_code"
        record_metric "$id" "failed" "$duration"
        # 记录错误日志摘要
        if [ -n "$err_file" ] && [ -s "$err_file" ]; then
            {
                echo ">>> $(date '+%Y-%m-%d %H:%M:%S') | $id | $name | exit: $exit_code"
                echo "stderr:"
                tail -n 50 "$err_file"
                echo "<<<"
            } >> "$ERROR_LOG"
            rotate_file "$ERROR_LOG" 5000
        elif [ "${CMD_HELPER_TEST_MODE:-0}" = "1" ]; then
            {
                echo ">>> $(date '+%Y-%m-%d %H:%M:%S') | $id | $name | exit: $exit_code"
                echo "stderr:"
                echo "(simulated failure)"
                echo "<<<"
            } >> "$ERROR_LOG"
            rotate_file "$ERROR_LOG" 5000
        fi
        if [ -n "$err_file" ] && [ -f "$err_file" ]; then
            rm -f "$err_file"
        fi
        if [ "$skip_confirm" != "yes" ]; then
            press_any_key
        fi
        return 1
    fi
    
    # end execute_command
}

# ============================================================================
# 历史记录功能
# ============================================================================

rotate_history() {
    # 保留最近 5000 行
    if [ -f "$HISTORY_FILE" ]; then
        local lines
        lines=$(wc -l < "$HISTORY_FILE" 2>/dev/null || echo 0)
        if [ "$lines" -gt 5000 ]; then
            tail -n 5000 "$HISTORY_FILE" > "$HISTORY_FILE.tmp" && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
        fi
    fi
}

rotate_file() {
    local file="$1"; local keep=${2:-5000}
    if [ -f "$file" ]; then
        local lines
        lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        if [ "$lines" -gt "$keep" ]; then
            tail -n "$keep" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        fi
    fi
}

log_to_history() {
    local cmd_id="$1"
    local cmd_name="$2"
    local status="$3"
    local duration="$4"
    local exit_code="$5"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$cmd_id|$cmd_name|$status|${duration}s|${exit_code}" >> "$HISTORY_FILE"
    rotate_history
}

view_history() {
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  ${ICON_HISTORY} 执行历史"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        show_info "暂无执行历史"
        press_any_key
        return
    fi
    
    echo -e "${COLOR_INFO}最近 20 条执行记录:${COLOR_RESET}\n"
    
    tail -20 "$HISTORY_FILE" | tac | while IFS='|' read -r timestamp cmd_id cmd_name status duration exit_code; do
        local status_icon
        local status_color
        
        if [ "$status" == "success" ]; then
            status_icon="${ICON_SUCCESS}"
            status_color="${COLOR_SUCCESS}"
        else
            status_icon="${ICON_ERROR}"
            status_color="${COLOR_ERROR}"
        fi
        
        # 兼容旧记录（无 exit_code）
        [ -z "$exit_code" ] && exit_code="-"
        echo -e "  ${status_color}${status_icon}${COLOR_RESET} ${BOLD}$cmd_name${COLOR_RESET} ${COLOR_DIM}[$cmd_id]${COLOR_RESET}"
        echo -e "     ${COLOR_DIM}时间: $timestamp | 耗时: $duration | 退出码: $exit_code${COLOR_RESET}"
        echo ""
    done
    
    echo -e "\n${COLOR_INFO}操作选项:${COLOR_RESET}\n"
    echo "  1. 重新执行历史命令"
    echo "  2. 清除历史记录"
    echo "  0. 返回主菜单"
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
    read -r choice
    
    case $choice in
        1)
            echo -ne "${COLOR_ACCENT}请输入要重新执行的命令ID: ${COLOR_RESET}"
            read -r cmd_id
            
            for cmd_data in "${COMMANDS[@]}"; do
                IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                if [ "$id" == "$cmd_id" ]; then
                    execute_command "$cmd_data"
                    return
                fi
            done
            
            show_error "未找到命令ID: $cmd_id"
            press_any_key
            ;;
        2)
            if confirm "确认清除所有历史记录？"; then
                : > "$HISTORY_FILE"
                show_success "历史记录已清除"
            fi
            press_any_key
            ;;
        0)
            return
            ;;
        *)
            show_error "无效选项"
            press_any_key
            ;;
    esac
}

# ============================================================================
# 收藏夹功能
# ============================================================================

init_favorites() {
    if [ ! -f "$FAVORITES_FILE" ]; then
        echo "[]" > "$FAVORITES_FILE"
    fi
}

add_to_favorites() {
    local cmd_id="$1"
    if ! check_jq; then
        show_error "缺少 jq，无法添加到收藏"
        return 1
    fi
    
    init_favorites
    
    # 检查是否已收藏
    if grep -q "\"$cmd_id\"" "$FAVORITES_FILE" 2>/dev/null; then
        show_warning "该命令已在收藏夹中"
        return
    fi
    
    # 添加到收藏
    local temp_file=$(mktemp)
    jq ". += [\"$cmd_id\"]" "$FAVORITES_FILE" > "$temp_file" 2>/dev/null && mv "$temp_file" "$FAVORITES_FILE"
    
    show_success "已添加到收藏夹"
}

view_favorites() {
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  ${ICON_FAVORITE} 我的收藏"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    init_favorites
    if ! check_jq; then
        show_error "收藏功能需要 jq，请先安装 jq"
        press_any_key
        return
    fi
    
    # 读取收藏列表
    local favorites=$(cat "$FAVORITES_FILE" 2>/dev/null)
    
    if [ "$favorites" == "[]" ] || [ -z "$favorites" ]; then
        show_info "收藏夹为空"
        show_info "提示: 在命令详情页面选择 'f' 添加到收藏"
        press_any_key
        return
    fi
    
    echo -e "${COLOR_INFO}收藏的命令:${COLOR_RESET}\n"
    
    local index=1
    local favorite_cmds=()
    local valid_ids=()
    
    # 遍历收藏的命令ID
    while IFS= read -r cmd_id; do
        cmd_id=$(echo "$cmd_id" | tr -d '",[]' | xargs)
        [ -z "$cmd_id" ] && continue
        
        for cmd_data in "${COMMANDS[@]}"; do
            IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"
            if [ "$id" == "$cmd_id" ]; then
                local cat_icon=""
                case "$cat" in
                    python) cat_icon="$ICON_PYTHON" ;;
                    system) cat_icon="$ICON_SYSTEM" ;;
                    homebrew) cat_icon="$ICON_HOMEBREW" ;;
                    file) cat_icon="$ICON_FILE" ;;
                    network) cat_icon="$ICON_NETWORK" ;;
                    appearance) cat_icon="$ICON_APPEARANCE" ;;
                    dev) cat_icon="$ICON_DEV" ;;
                    security) cat_icon="$ICON_SECURITY" ;;
                    app) cat_icon="$ICON_APP" ;;
                    quick) cat_icon="$ICON_QUICK" ;;
                    monitor) cat_icon="$ICON_MONITOR" ;;
                esac
                
                echo -e "  ${BOLD}$index.${COLOR_RESET} $cat_icon $name ${COLOR_DIM}[$id]${COLOR_RESET}"
                favorite_cmds[$index]="$cmd_data"
                valid_ids+=("$id")
                ((index++))
                break
            fi
        done
    done < <(echo "$favorites" | jq -r '.[]' 2>/dev/null)

    # 清理收藏中已失效的命令 ID
    if [ ${#valid_ids[@]} -gt 0 ]; then
        tmp=$(mktemp)
        printf '%s\n' "${valid_ids[@]}" | jq -R . | jq -s . > "$tmp" 2>/dev/null && mv "$tmp" "$FAVORITES_FILE"
    fi
    
    echo -e "\n  ${ICON_BACK} 返回主菜单 (${COLOR_ACCENT}0${COLOR_RESET})   🗑️  删除收藏 (${COLOR_ACCENT}d${COLOR_RESET})\n"
    draw_double_line
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -lt $index ]; then
        execute_command "${favorite_cmds[$choice]}"
    elif [ "$choice" = "d" ] || [ "$choice" = "D" ]; then
        echo -ne "${COLOR_ACCENT}请输入要删除的编号: ${COLOR_RESET}"
        read -r del_index
        if [[ "$del_index" =~ ^[0-9]+$ ]] && [ "$del_index" -gt 0 ] && [ "$del_index" -lt $index ]; then
            # 找到对应的 ID
            IFS='|' read -r del_id _ _ _ _ _ _ _ _ _ _ <<< "${favorite_cmds[$del_index]}"
            tmp=$(mktemp)
            jq "map(select(. != \"$del_id\"))" "$FAVORITES_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$FAVORITES_FILE"
            show_success "已从收藏夹移除: $del_id"
        else
            show_error "无效编号"
        fi
        press_any_key
    fi
}

# ============================================================================
# 命令组合功能
# ============================================================================

init_combos() {
    if [ ! -f "$COMBOS_FILE" ]; then
        cat > "$COMBOS_FILE" << 'EOF'
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
    fi
}

view_combos() {
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  ${ICON_COMBO} 命令组合"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    init_combos
    if ! check_jq; then
        show_error "命令组合功能需要 jq，请先安装 jq"
        press_any_key
        return
    fi
    
    echo -e "${COLOR_INFO}预设组合:${COLOR_RESET}\n"
    
    local index=1
    jq -r '.["预设组合"][] | "\(.name)|\(.description)|\(.commands | join(","))"' "$COMBOS_FILE" 2>/dev/null | while IFS='|' read -r combo_name desc cmd_ids; do
        echo -e "  ${BOLD}$index.${COLOR_RESET} $combo_name"
        echo -e "     ${COLOR_DIM}$desc${COLOR_RESET}"
        echo -e "     ${COLOR_DIM}命令: $cmd_ids${COLOR_RESET}"
        echo ""
        ((index++))
    done
    
    echo -e "\n  ${ICON_BACK} 返回主菜单 (${COLOR_ACCENT}0${COLOR_RESET})\n"
    draw_double_line
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
    read -r choice
    
    if [ "$choice" == "0" ]; then
        return
    fi
    
    # 获取选中的组合
    local combo_data=$(jq -r ".[\"预设组合\"][ $((choice-1)) ]" "$COMBOS_FILE" 2>/dev/null)
    
    if [ "$combo_data" == "null" ] || [ -z "$combo_data" ]; then
        show_error "无效选项"
        press_any_key
        return
    fi
    
    local combo_name=$(echo "$combo_data" | jq -r '.name')
    local cmd_ids=$(echo "$combo_data" | jq -r '.commands | join(" ")')
    
    echo -e "\n${COLOR_INFO}将执行组合: ${BOLD}$combo_name${COLOR_RESET}\n"
    
    if ! confirm "确认执行？"; then
        show_info "已取消"
        press_any_key
        return
    fi
    
    # 依次执行命令
    for cmd_id in $cmd_ids; do
        echo -e "\n${COLOR_INFO}━━━ 执行命令 $cmd_id ━━━${COLOR_RESET}\n"
        
        for cmd_data in "${COMMANDS[@]}"; do
            IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
            if [ "$id" == "$cmd_id" ]; then
                execute_command "$cmd_data" "yes"
                break
            fi
        done
        
        sleep 1
    done
    
    show_success "组合执行完成！"
    press_any_key
}

# ============================================================================
# 搜索命令
# ============================================================================

search_commands() {
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  ${ICON_SEARCH} 智能搜索"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    echo -ne "${COLOR_ACCENT}🔎 输入关键词: ${COLOR_RESET}"
    read -r keyword
    
    if [ -z "$keyword" ]; then
        show_warning "请输入搜索关键词"
        press_any_key
        return
    fi
    
    echo -e "\n${COLOR_DIM}💡 搜索建议: 虚拟环境、清理、网络、截图...${COLOR_RESET}\n"
    draw_double_line
    echo ""
    
    local results=()
    for cmd_data in "${COMMANDS[@]}"; do
        IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"
        if [[ "$name" == *"$keyword"* ]] || [[ "$desc" == *"$keyword"* ]] || [[ "$command" == *"$keyword"* ]]; then
            results+=("$cmd_data")
        fi
    done
    
    if [ ${#results[@]} -eq 0 ]; then
        show_warning "未找到相关命令"
        press_any_key
        return
    fi
    
    echo -e "${COLOR_INFO}📋 找到 ${#results[@]} 个相关命令:${COLOR_RESET}\n"
    
    local idx=1
    for cmd_data in "${results[@]}"; do
        IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"
        local cat_icon=""
        case "$cat" in
            python) cat_icon="$ICON_PYTHON" ;;
            system) cat_icon="$ICON_SYSTEM" ;;
            homebrew) cat_icon="$ICON_HOMEBREW" ;;
            file) cat_icon="$ICON_FILE" ;;
            network) cat_icon="$ICON_NETWORK" ;;
            appearance) cat_icon="$ICON_APPEARANCE" ;;
            dev) cat_icon="$ICON_DEV" ;;
            security) cat_icon="$ICON_SECURITY" ;;
            app) cat_icon="$ICON_APP" ;;
            quick) cat_icon="$ICON_QUICK" ;;
            monitor) cat_icon="$ICON_MONITOR" ;;
        esac
        echo -e "  ${BOLD}$idx.${COLOR_RESET} $cat_icon $name         ${COLOR_DIM}[$id]${COLOR_RESET}"
        ((idx++))
    done
    
    echo -e "\n  ${ICON_BACK} 返回 (${COLOR_ACCENT}0${COLOR_RESET})\n"
    draw_double_line
    echo ""
    
    echo -ne "${COLOR_ACCENT}选择命令编号: ${COLOR_RESET}"
    read -r choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le ${#results[@]} ]; then
        execute_command "${results[$((choice-1))]}"
    fi
}

# ============================================================================
# 帮助信息
# ============================================================================

show_help() {
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  📚 使用帮助"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    echo -e "${COLOR_ACCENT}${BOLD}基本使用:${COLOR_RESET}"
    echo "  1. 在主菜单选择功能分类"
    echo "  2. 在子菜单选择具体命令"
    echo "  3. 查看命令详细说明"
    echo "  4. 确认后执行命令"
    echo ""
    
    echo -e "${COLOR_ACCENT}${BOLD}快捷键:${COLOR_RESET}"
    echo "  ${ICON_CHECK} s - 搜索命令"
    echo "  ${ICON_CHECK} f - 查看收藏夹"
    echo "  ${ICON_CHECK} c - 命令组合"
    echo "  ${ICON_CHECK} r - 执行历史"
    echo "  ${ICON_CHECK} h - 显示帮助"
    echo "  ${ICON_CHECK} q - 退出程序"
    echo "  ${ICON_CHECK} 0 - 返回上级菜单"
    echo ""
    
    echo -e "${COLOR_ACCENT}${BOLD}快捷执行模式:${COLOR_RESET}"
    echo "  直接执行命令："
    echo "  ${COLOR_DIM}$ $SCRIPT_NAME 2.1${COLOR_RESET}  # 执行系统清理"
    echo "  ${COLOR_DIM}$ $SCRIPT_NAME search python${COLOR_RESET}  # 搜索 python"
    echo "  ${COLOR_DIM}$ $SCRIPT_NAME search dns --first${COLOR_RESET}  # 搜索并执行第一个"
    echo "  ${COLOR_DIM}$ $SCRIPT_NAME combo 1${COLOR_RESET}  # 执行第1个预设组合"
    echo "  ${COLOR_DIM}$ $SCRIPT_NAME help 2.1${COLOR_RESET}  # 查看命令 2.1 详情"
    echo ""
    
    echo -e "${COLOR_ACCENT}${BOLD}配置文件位置:${COLOR_RESET}"
    echo "  • 配置: $CONFIG_FILE"
    echo "  • 历史: $HISTORY_FILE"
    echo "  • 收藏: $FAVORITES_FILE"
    echo "  • 组合: $COMBOS_FILE"
    echo ""
    
    echo -e "${COLOR_ACCENT}${BOLD}新功能亮点:${COLOR_RESET}"
    echo "  ⭐ 收藏夹 - 收藏常用命令快速访问"
    echo "  📜 历史记录 - 查看和重新执行历史命令"
    echo "  🎯 命令组合 - 一键执行多个相关命令"
    echo "  ⚡ 快捷模式 - 命令行参数直接执行"
    echo "  🔐 隐私安全 - 8 个新增安全命令"
    echo "  📁 文件增强 - 压缩、转换、加密等"
    echo "  🌐 网络增强 - DNS、代理、测速等"
    echo ""
    
    draw_double_line
    press_any_key
}

# ============================================================================
# 菜单系统
# ============================================================================

show_main_menu() {
    clear_screen
    
    draw_info_box "请选择功能分类："
    
    echo -e "  ${ICON_PYTHON}  ${BOLD}1.${COLOR_RESET} Python 开发环境     ${ICON_SYSTEM}  ${BOLD}2.${COLOR_RESET} 系统管理"
    echo ""
    echo -e "  ${ICON_HOMEBREW}  ${BOLD}3.${COLOR_RESET} Homebrew 管理       ${ICON_FILE}  ${BOLD}4.${COLOR_RESET} 文件操作"
    echo ""
    echo -e "  ${ICON_NETWORK}  ${BOLD}5.${COLOR_RESET} 网络工具           ${ICON_APPEARANCE}  ${BOLD}6.${COLOR_RESET} 界面外观"
    echo ""
    echo -e "  ${ICON_DEV}  ${BOLD}7.${COLOR_RESET} 开发工具           ${ICON_APP}  ${BOLD}8.${COLOR_RESET} 应用管理"
    echo ""
    echo -e "  ${ICON_QUICK}  ${BOLD}9.${COLOR_RESET} 快捷操作           ${ICON_MONITOR}  ${BOLD}10.${COLOR_RESET} 性能监控"
    echo ""
    echo -e "  ${ICON_SECURITY}  ${BOLD}11.${COLOR_RESET} 隐私与安全"
    echo ""
    
    draw_line '─'
    echo ""
    echo -e "  ${ICON_FAVORITE}  收藏夹 (${COLOR_ACCENT}f${COLOR_RESET})    ${ICON_HISTORY}  执行历史 (${COLOR_ACCENT}r${COLOR_RESET})    ${ICON_COMBO}  命令组合 (${COLOR_ACCENT}c${COLOR_RESET})"
    echo ""
    echo -e "  ${ICON_SEARCH}  ${COLOR_DIM}搜索命令 (${COLOR_ACCENT}s${COLOR_DIM})    📝  使用帮助 (${COLOR_ACCENT}h${COLOR_DIM})    🚪  退出 (${COLOR_ACCENT}q${COLOR_DIM})${COLOR_RESET}"
    echo ""
    draw_double_line
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
}

show_category_menu() {
    local category="$1"
    local title="$2"
    local icon="$3"
    
    clear_screen
    
    echo -e "${COLOR_TITLE}${BOLD}"
    echo "╔$(draw_line '═')╗"
    echo "║  $icon $title"
    echo "╚$(draw_line '═')╝"
    echo -e "${COLOR_RESET}\n"
    
    local count=0
    LAST_CATEGORY_CMDS=()
    LAST_CATEGORY_COUNT=0
    for cmd_data in "${COMMANDS[@]}"; do
        IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"
        if [ "$cat" == "$category" ]; then
            count=$((count+1))
            LAST_CATEGORY_COUNT=$count
            LAST_CATEGORY_CMDS[$count]="$id"
            echo -e "  ${BOLD}$count.${COLOR_RESET} $name   ${COLOR_DIM}[$id]${COLOR_RESET}"
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "  ${COLOR_DIM}暂无可用命令${COLOR_RESET}"
    fi
    
    echo -e "\n  ${ICON_BACK} 返回主菜单 (${COLOR_ACCENT}0${COLOR_RESET})\n"
    draw_double_line
    echo ""
    
    echo -ne "${COLOR_ACCENT}${ICON_ARROW} 请输入选项: ${COLOR_RESET}"
}

# ============================================================================
# 快捷执行模式
# ============================================================================

quick_execute() {
    local cmd_id="$1"

    # Ensure configuration directories/files exist when running in quick mode
    init_config
    
    for cmd_data in "${COMMANDS[@]}"; do
        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
        if [ "$id" == "$cmd_id" ]; then
            clear_screen
            if execute_command "$cmd_data" "yes"; then
                exit 0
            else
                exit 1
            fi
        fi
    done
    
    echo -e "${COLOR_ERROR}错误: 未找到命令 ID '$cmd_id'${COLOR_RESET}"
    echo -e "${COLOR_INFO}使用 '$SCRIPT_NAME search keyword' 搜索命令${COLOR_RESET}"
    exit 1
}

# ============================================================================
# 主程序
# ============================================================================

main() {
    # 载入主题/外观配置
    load_theme
    # 检查快捷执行模式
    if [ $# -gt 0 ]; then
        case "$1" in
            search|s)
                if [ -z "$2" ]; then
                    echo "用法: $SCRIPT_NAME search <关键词> [--first|--run <ID>|--json]"
                    exit 1
                fi
                keyword="$2"; shift 2
                run_first=0; run_id=""; output_json=0
                while [ $# -gt 0 ]; do
                    case "$1" in
                        --first) run_first=1 ;;
                        --run) shift; run_id="$1" ;;
                        --json) output_json=1 ;;
                    esac
                    shift || break
                done
                # 搜索匹配
                matches=()
                for cmd_data in "${COMMANDS[@]}"; do
                    IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"
                    if [[ "$name" == *"$keyword"* ]] || [[ "$desc" == *"$keyword"* ]] || [[ "$command" == *"$keyword"* ]]; then
                        matches+=("$cmd_data")
                    fi
                done
                if [ ${#matches[@]} -eq 0 ]; then
                    echo "未找到匹配的命令"
                    exit 1
                fi
                if [ "$output_json" -eq 1 ] && [ "${CMD_HELPER_DISABLE_JQ:-0}" != "1" ] && command -v jq >/dev/null 2>&1; then
                    # 输出 JSON
                    local json_output
                    json_output="$({
                        printf '['
                        idx=0
                        total=${#matches[@]}
                        local esc_command esc_desc
                        for cmd_data in "${matches[@]}"; do
                            IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"
                            esc_command=$(printf '%s' "$command" | sed 's/"/\\"/g')
                            esc_desc=$(printf '%s' "$desc" | sed 's/"/\\"/g')
                            printf '{"id":"%s","category":"%s","name":"%s","command":"%s","desc":"%s"}' \
                                "$id" "$cat" "$name" "$esc_command" "$esc_desc"
                            idx=$((idx+1))
                            [ $idx -lt $total ] && printf ','
                        done
                        printf ']\n'
                    })"
                    printf '%s' "$json_output" | jq '.'
                else
                    # 表格输出
                    for cmd_data in "${matches[@]}"; do
                        IFS='|' read -r id cat name _ _ _ desc _ _ _ _ <<< "$cmd_data"
                        printf '%-6s %-10s %s\n' "[$id]" "($cat)" "$name"
                    done
                fi
                if [ -n "$run_id" ]; then
                    quick_execute "$run_id"
                elif [ $run_first -eq 1 ]; then
                    IFS='|' read -r first_id _ _ _ _ _ _ _ _ _ _ <<< "${matches[0]}"
                    quick_execute "$first_id"
                fi
                exit 0
                ;;
            help|h|-h|--help)
                if [ -n "$2" ]; then
                    # 显示指定命令详情
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" = "$2" ]; then
                            show_command_info "$cmd_data"
                            draw_double_line
                            exit 0
                        fi
                    done
                    echo "未找到命令 ID: $2"; exit 1
                else
                    show_help
                    exit 0
                fi
                ;;
            version|v|-v|--version)
                echo "Mac Command Helper v$VERSION"
                exit 0
                ;;
            combo)
                if ! check_jq; then
                    echo "命令组合功能需要 jq。请先安装 jq (brew install jq)"
                    exit 1
                fi
                if [ -z "$2" ]; then
                    echo "用法: $SCRIPT_NAME combo <index|name>"
                    exit 1
                fi
                init_config
                local sel="$2"; shift 2
                local cmd_ids
                if [[ "$sel" =~ ^[0-9]+$ ]]; then
                    cmd_ids=$(jq -r ".[\"预设组合\"][ $((sel-1)) ].commands | join(\" \")" "$COMBOS_FILE" 2>/dev/null)
                else
                    cmd_ids=$(jq -r ".[\"预设组合\"][] | select(.name==\"$sel\") | .commands | join(\" \")" "$COMBOS_FILE" 2>/dev/null)
                fi
                if [ -z "$cmd_ids" ] || [ "$cmd_ids" = "null" ]; then
                    echo "未找到命令组合: $sel"; exit 1
                fi
                for cid in $cmd_ids; do
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" = "$cid" ]; then
                            execute_command "$cmd_data" "yes"
                            break
                        fi
                    done
                done
                exit 0
                ;;
            *)
                # 尝试作为命令 ID 执行
                quick_execute "$1"
                ;;
        esac
    fi
    
    # 初始化
    init_config
    
    # 主循环
    while true; do
        show_main_menu
        read -r main_choice
        
        case "$main_choice" in
            1) # Python
                while true; do
                    show_category_menu "python" "Python 开发环境" "$ICON_PYTHON"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            2) # 系统
                while true; do
                    show_category_menu "system" "系统管理" "$ICON_SYSTEM"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            3) # Homebrew
                while true; do
                    show_category_menu "homebrew" "Homebrew 管理" "$ICON_HOMEBREW"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            4) # 文件
                while true; do
                    show_category_menu "file" "文件操作" "$ICON_FILE"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            5) # 网络
                while true; do
                    show_category_menu "network" "网络工具" "$ICON_NETWORK"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            6) # 界面
                while true; do
                    show_category_menu "appearance" "界面外观" "$ICON_APPEARANCE"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            7) # 开发
                while true; do
                    show_category_menu "dev" "开发工具" "$ICON_DEV"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            8) # 应用
                while true; do
                    show_category_menu "app" "应用管理" "$ICON_APP"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            9) # 快捷操作
                while true; do
                    show_category_menu "quick" "快捷操作" "$ICON_QUICK"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    target_id=""
                    if [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                        if [ "$sub_choice" -ge 1 ] && [ "$sub_choice" -le "${LAST_CATEGORY_COUNT:-0}" ]; then
                            target_id="${LAST_CATEGORY_CMDS[$sub_choice]}"
                        else
                            show_error "无效选项"; sleep 1; continue
                        fi
                    else
                        target_id="$sub_choice"
                    fi
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$target_id" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            10) # 性能监控
                while true; do
                    show_category_menu "monitor" "性能监控" "$ICON_MONITOR"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$sub_choice" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            11) # 隐私与安全
                while true; do
                    show_category_menu "security" "隐私与安全" "$ICON_SECURITY"
                    read -r sub_choice
                    
                    if [ "$sub_choice" == "0" ]; then
                        break
                    fi
                    
                    for cmd_data in "${COMMANDS[@]}"; do
                        IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"
                        if [ "$id" == "$sub_choice" ]; then
                            execute_command "$cmd_data"
                            break
                        fi
                    done
                done
                ;;
                
            f|F) # 收藏夹
                view_favorites
                ;;
                
            r|R) # 执行历史
                view_history
                ;;
                
            c|C) # 命令组合
                view_combos
                ;;
                
            s|S) # 搜索
                search_commands
                ;;
                
            h|H) # 帮助
                show_help
                ;;
                
            q|Q) # 退出
                clear_screen
                echo -e "${COLOR_SUCCESS}${ICON_SUCCESS} 感谢使用 Mac Command Helper v$VERSION！${COLOR_RESET}\n"
                exit 0
                ;;
                
            *)
                show_error "无效选项，请重新输入"
                sleep 1
                ;;
        esac
    done
}

# 启动程序
main "$@"
