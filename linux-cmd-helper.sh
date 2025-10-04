#!/usr/bin/env bash

################################################################################
#
#  🐧 Linux Command Helper (Debian/Ubuntu)
#  服务器终端助手 - 安全、稳健、好用
#
#  版本: 1.0.0
#  平台: Debian 11+/Ubuntu 20.04+
#
################################################################################

set -o pipefail

L_VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"
CONFIG_DIR="$HOME/.linux-cmd-helper"
CONFIG_FILE="$CONFIG_DIR/config.json"
HISTORY_FILE="$CONFIG_DIR/history.log"
FAVORITES_FILE="$CONFIG_DIR/favorites.json"
COMBOS_FILE="$CONFIG_DIR/combos.json"
ERROR_LOG="$CONFIG_DIR/error.log"
METRICS_FILE="$CONFIG_DIR/metrics.json"

mkdir -p "$CONFIG_DIR"
touch "$HISTORY_FILE" "$ERROR_LOG"
[ -f "$FAVORITES_FILE" ] || echo "[]" > "$FAVORITES_FILE"
[ -f "$COMBOS_FILE" ] || cat > "$COMBOS_FILE" << 'EOF'
{
  "预设组合": [
    {"name":"系统更新","description":"apt update+upgrade+autoremove","commands":["1.1","1.2","1.3"]},
    {"name":"日志与磁盘","description":"清理journal+APT缓存+磁盘检查","commands":["1.5","1.4","4.1"]},
    {"name":"网络排查","description":"IP+端口+Ping","commands":["3.1","3.3","3.5"]}
  ],
  "自定义组合": []
}
EOF

# Colors & styles (support NO_COLOR)
USE_COLOR=1
if [ "$NO_COLOR" = "1" ] || [ "$LCMD_NO_COLOR" = "1" ]; then USE_COLOR=0; fi

if [ $USE_COLOR -eq 1 ]; then
  COLOR_TITLE='\033[38;5;39m'
  COLOR_ACCENT='\033[38;5;220m'
  COLOR_SUCCESS='\033[38;5;48m'
  COLOR_WARNING='\033[38;5;214m'
  COLOR_ERROR='\033[38;5;203m'
  COLOR_INFO='\033[38;5;75m'
  COLOR_DIM='\033[38;5;240m'
  COLOR_RESET='\033[0m'
  BOLD='\033[1m'
else
  COLOR_TITLE=''; COLOR_ACCENT=''; COLOR_SUCCESS=''; COLOR_WARNING=''; COLOR_ERROR=''; COLOR_INFO=''; COLOR_DIM=''; COLOR_RESET=''; BOLD=''
fi

ICON_CHECK="✓"; ICON_ERROR="✗"; ICON_INFO="ℹ️"; ICON_SUCCESS="✅"; ICON_WARNING="⚠️"; ICON_ROCKET="🚀"

get_terminal_width() { tput cols 2>/dev/null || echo 80; }
draw_line() { local c="${1:-─}"; printf "%$(get_terminal_width)s\n" | tr ' ' "$c"; }
draw_double_line() { echo -e "${COLOR_DIM}$(draw_line '━')${COLOR_RESET}"; }

draw_title() {
  echo -e "${COLOR_TITLE}${BOLD}Linux Command Helper v$L_VERSION${COLOR_RESET}\n"
}

clear_screen() {
  clear
  draw_title
  echo -e "${COLOR_DIM}面向 Debian/Ubuntu 的服务器终端助手${COLOR_RESET}\n"
  draw_double_line
}

show_success() { echo -e "\n${COLOR_SUCCESS}${ICON_SUCCESS} $1${COLOR_RESET}\n"; }
show_error() { echo -e "\n${COLOR_ERROR}${ICON_ERROR} $1${COLOR_RESET}\n"; }
show_warning() { echo -e "\n${COLOR_WARNING}${ICON_WARNING} $1${COLOR_RESET}\n"; }
show_info() { echo -e "\n${COLOR_INFO}${ICON_INFO} $1${COLOR_RESET}\n"; }

confirm() {
  local message="$1"; local default="${2:-y}"
  if [ "$default" = "y" ]; then echo -ne "${COLOR_ACCENT}$message [Y/n]: ${COLOR_RESET}"; else echo -ne "${COLOR_ACCENT}$message [y/N]: ${COLOR_RESET}"; fi
  read -r ans; ans=${ans:-$default}; [[ $ans =~ ^[Yy]$ ]]
}

press_any_key() {
  if [ "${CMD_HELPER_TEST_MODE:-0}" = "1" ] || [ "${LCMD_NONINTERACTIVE:-0}" = "1" ]; then
    return 0
  fi
  echo -e "\n${COLOR_DIM}按任意键继续...${COLOR_RESET}"; read -n 1 -s
}

# Input validation
sanitize_generic() { echo "$1" | grep -Eq '[`$;&|><\\]' && return 1 || return 0; }
sanitize_path() { local p="$1"; sanitize_generic "$p" || return 1; [ -n "$p" ] || return 1; return 0; }
sanitize_name() { local n="$1"; sanitize_generic "$n" || return 1; [ -n "$n" ] || return 1; return 0; }
sanitize_int() { echo "$1" | grep -Eq '^[0-9]+$'; }

# History & metrics
rotate_file() { local f="$1"; local keep=${2:-5000}; [ -f "$f" ] || return 0; local lines; lines=$(wc -l < "$f" 2>/dev/null || echo 0); [ "$lines" -gt "$keep" ] && tail -n "$keep" "$f" > "$f.tmp" && mv "$f.tmp" "$f" || true; }

log_to_history() {
  local id="$1"; local name="$2"; local status="$3"; local duration="$4"; local exit_code="$5"
  echo "$(date '+%Y-%m-%d %H:%M:%S')|$id|$name|$status|${duration}s|${exit_code}" >> "$HISTORY_FILE"; rotate_file "$HISTORY_FILE" 5000
}

record_metric() {
  local id="$1"; local status="$2"; local duration="$3"
  if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq >/dev/null 2>&1; then
    echo "$(date +%s)|$id|$status|$duration" >> "$CONFIG_DIR/metrics.log"
    rotate_file "$CONFIG_DIR/metrics.log" 5000
    return
  fi
  [ -f "$METRICS_FILE" ] || echo '{"total":0,"commands":{}}' > "$METRICS_FILE"
  tmp=$(mktemp)
  jq --arg id "$id" --arg s "$status" --arg d "$duration" '
    .total += 1 |
    .commands[$id].count = ( (.commands[$id].count // 0) + 1 ) |
    .commands[$id].last_status = $s |
    .commands[$id].last_duration = $d
  ' "$METRICS_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$METRICS_FILE"
}

# Favorites & combos
init_favorites() { [ -f "$FAVORITES_FILE" ] || echo "[]" > "$FAVORITES_FILE"; }
add_to_favorites() {
  local id="$1"; init_favorites
  if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq >/dev/null 2>&1; then
    show_error "收藏功能需要 jq"
    return 1
  fi
  if grep -q "\"$id\"" "$FAVORITES_FILE" 2>/dev/null; then show_warning "已在收藏夹"; return 0; fi
  tmp=$(mktemp); jq ". += [\"$id\"]" "$FAVORITES_FILE" > "$tmp" 2>/dev/null && mv "$tmp" "$FAVORITES_FILE"; show_success "已收藏";
}

init_combos() {
  [ -f "$COMBOS_FILE" ] || cat > "$COMBOS_FILE" << 'EOF'
{
  "预设组合": [
    {"name":"系统更新","description":"apt update+upgrade+autoremove","commands":["1.1","1.2","1.3"]}
  ],
  "自定义组合": []
}
EOF
}

# Dependency checks
check_cmd() { command -v "$1" >/dev/null 2>&1; }
require_cmd() { if ! check_cmd "$1"; then show_error "未检测到 $1"; return 1; fi; return 0; }

# UI helpers
show_command_info() {
  local cmd_data="$1"; IFS='|' read -r id category name command needs_sudo dependency desc params scenarios notes related <<< "$cmd_data"
  clear_screen
  echo -e "${COLOR_INFO}${BOLD}命令详解${COLOR_RESET}\n"
  echo -e "${COLOR_ACCENT}📌 功能:${COLOR_RESET} $desc\n"
  echo -e "${COLOR_ACCENT}🔧 命令:${COLOR_RESET} ${COLOR_DIM}$command${COLOR_RESET}\n"
  [ "$needs_sudo" = "yes" ] && echo -e "${COLOR_WARNING}${ICON_WARNING} 需要管理员权限${COLOR_RESET}\n"
  draw_double_line
}

execute_command() {
  local cmd_data="$1"; local skip_confirm="${2:-no}"
  IFS='|' read -r id category name command needs_sudo dependency desc params scenarios notes related <<< "$cmd_data"

  if [ "$skip_confirm" != "yes" ]; then
    show_command_info "$cmd_data"
    echo -e "${COLOR_INFO}操作: [y 执行] [f 收藏] [0 返回]${COLOR_RESET}"
    echo -ne "${COLOR_ACCENT}请选择: ${COLOR_RESET}"; read -r action
    case "$action" in
      f|F) add_to_favorites "$id"; press_any_key; return 0;;
      y|Y) ;; 0) show_info "已取消"; press_any_key; return 1;;
      *) show_info "已取消"; press_any_key; return 1;;
    esac
  fi

  # dependency
  if [ "$dependency" != "none" ] && ! $dependency; then press_any_key; return 1; fi

  echo ""; draw_double_line; echo -e "${COLOR_INFO}${ICON_ROCKET} 正在执行...${COLOR_RESET}\n"; draw_double_line; echo ""
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
    if [ "$needs_sudo" = "yes" ]; then
      bash -c "sudo bash -c '$command'" 2>"$err_file"
    else
      bash -c "$command" 2>"$err_file"
    fi
    exit_code=$?
  fi

  local end_time=$(date +%s); local duration=$((end_time - start_time))

  if [ $exit_code -eq 0 ]; then
    show_success "命令执行成功！（耗时: ${duration}秒）"
    log_to_history "$id" "$name" "success" "$duration" "$exit_code"
    record_metric "$id" "success" "$duration"
    if [ -n "$err_file" ] && [ -s "$err_file" ]; then
      rm -f "$err_file"
    fi
    press_any_key; return 0
  else
    show_error "命令执行失败（退出码: $exit_code）"
    log_to_history "$id" "$name" "failed" "$duration" "$exit_code"
    record_metric "$id" "failed" "$duration"
    if [ -n "$err_file" ] && [ -s "$err_file" ]; then
      {
        echo ">>> $(date '+%Y-%m-%d %H:%M:%S') | $id | $name | exit: $exit_code"; echo "stderr:"; tail -n 50 "$err_file"; echo "<<<"
      } >> "$ERROR_LOG"; rotate_file "$ERROR_LOG" 5000
    elif [ "${CMD_HELPER_TEST_MODE:-0}" = "1" ]; then
      {
        echo ">>> $(date '+%Y-%m-%d %H:%M:%S') | $id | $name | exit: $exit_code"
        echo "stderr:"
        echo "(simulated failure)"
        echo "<<<"
      } >> "$ERROR_LOG"; rotate_file "$ERROR_LOG" 5000
    fi
    if [ -n "$err_file" ]; then
      rm -f "$err_file" 2>/dev/null || true
    fi
    press_any_key; return 1
  fi
}

# Search
search_commands() {
  clear_screen
  echo -e "${COLOR_TITLE}${BOLD}🔍 智能搜索${COLOR_RESET}\n"
  echo -ne "${COLOR_ACCENT}输入关键词: ${COLOR_RESET}"; read -r keyword
  [ -z "$keyword" ] && show_warning "请输入关键词" && press_any_key && return
  local results=(); local idx=1
  for cmd_data in "${COMMANDS[@]}"; do
    IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"
    if [[ "$name" == *"$keyword"* ]] || [[ "$desc" == *"$keyword"* ]] || [[ "$command" == *"$keyword"* ]]; then results+=("$cmd_data"); fi
  done
  [ ${#results[@]} -eq 0 ] && show_warning "未找到" && press_any_key && return
  echo -e "${COLOR_INFO}找到 ${#results[@]} 个命令:${COLOR_RESET}\n"
  for cmd_data in "${results[@]}"; do IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"; echo -e "  ${BOLD}$idx.${COLOR_RESET} $name ${COLOR_DIM}[$id/$cat]${COLOR_RESET}"; idx=$((idx+1)); done
  echo -ne "\n${COLOR_ACCENT}选择编号执行 (0 返回): ${COLOR_RESET}"; read -r choice
  [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#results[@]} ] && execute_command "${results[$((choice-1))]}"
}

show_help() {
  clear_screen
  echo -e "${COLOR_TITLE}${BOLD}📚 帮助${COLOR_RESET}\n"
  echo "- 通过数字选择分类与命令"
  echo "- 搜索: s    收藏: f    历史: r    组合: c    帮助: h    退出: q"
  echo "- 快捷执行: $SCRIPT_NAME 1.1  或  $SCRIPT_NAME search nginx --first"
  echo "- 配置目录: $CONFIG_DIR"
  draw_double_line; press_any_key
}

# Menus
show_main_menu() {
  clear_screen
  echo -e "${COLOR_INFO}请选择功能分类：${COLOR_RESET}\n"
  echo "  1. 系统管理       2. 服务进程       3. 网络工具"
  echo "  4. 存储文件       5. 安全防护       6. 用户权限"
  echo "  7. 容器与开发     8. 监控日志       9. 备份与计划"
  echo "  10. 快捷工具"
  echo ""
  draw_line '─'
  echo -e "\n  收藏夹(f)   历史(r)   组合(c)   搜索(s)   帮助(h)   退出(q)\n"
  draw_double_line
  echo -ne "${COLOR_ACCENT}输入选项: ${COLOR_RESET}"
}

LAST_CATEGORY_CMDS=(); LAST_CATEGORY_COUNT=0
show_category_menu() {
  local category="$1"; local title="$2"
  clear_screen
  echo -e "${COLOR_TITLE}${BOLD}$title${COLOR_RESET}\n"
  LAST_CATEGORY_CMDS=(); LAST_CATEGORY_COUNT=0
  local idx=0
  for cmd_data in "${COMMANDS[@]}"; do IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"; if [ "$cat" = "$category" ]; then idx=$((idx+1)); LAST_CATEGORY_CMDS[$idx]="$id"; LAST_CATEGORY_COUNT=$idx; echo -e "  ${BOLD}$idx.${COLOR_RESET} $name ${COLOR_DIM}[$id]${COLOR_RESET}"; fi; done
  [ $idx -eq 0 ] && echo -e "  ${COLOR_DIM}暂无可用命令${COLOR_RESET}"
  echo -e "\n  ← 返回 (0)\n"; draw_double_line; echo -ne "${COLOR_ACCENT}输入选项: ${COLOR_RESET}"
}

quick_execute() {
  local want="$1"; for cmd_data in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$cmd_data"; [ "$id" = "$want" ] && clear_screen && execute_command "$cmd_data" "yes" && exit $?; done
  echo "未找到命令 ID: $want"; exit 1
}

# CLI entry
cli_entry() {
  if [ $# -gt 0 ]; then
    case "$1" in
      search)
        [ -z "$2" ] && echo "用法: $SCRIPT_NAME search <关键词> [--first|--run <ID>|--json]" && exit 1
        local keyword="$2"; shift 2; local run_first=0 run_id="" output_json=0
        while [ $# -gt 0 ]; do case "$1" in --first) run_first=1;; --run) shift; run_id="$1";; --json) output_json=1;; esac; shift || break; done
        local matches=()
        for cmd_data in "${COMMANDS[@]}"; do IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"; if [[ "$name" == *"$keyword"* ]] || [[ "$desc" == *"$keyword"* ]] || [[ "$command" == *"$keyword"* ]]; then matches+=("$cmd_data"); fi; done
        [ ${#matches[@]} -eq 0 ] && echo "未找到" && exit 1
        if [ $output_json -eq 1 ] && [ "${CMD_HELPER_DISABLE_JQ:-0}" != "1" ] && command -v jq >/dev/null 2>&1; then
          local json_output
          json_output="$(
            i=0
            printf '['
            for cmd_data in "${matches[@]}"; do
              IFS='|' read -r id cat name command _ _ desc _ _ _ _ <<< "$cmd_data"
              printf '{"id":"%s","category":"%s","name":"%s"}' "$id" "$cat" "$name"
              i=$((i+1))
              [ $i -lt ${#matches[@]} ] && printf ','
            done
            printf ']\n'
          )"
          printf '%s' "$json_output" | jq '.'
        else
          for cmd_data in "${matches[@]}"; do IFS='|' read -r id cat name _ _ _ _ _ _ _ _ <<< "$cmd_data"; printf '%-6s %-12s %s\n' "[$id]" "($cat)" "$name"; done
        fi
        [ -n "$run_id" ] && quick_execute "$run_id"
        [ $run_first -eq 1 ] && IFS='|' read -r first_id _ _ _ _ _ _ _ _ _ _ <<< "${matches[0]}" && quick_execute "$first_id"; exit 0;
        ;;
      combo)
        if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq >/dev/null 2>&1; then
          echo "命令组合需要 jq，无法执行"
          exit 1
        fi
        [ -z "$2" ] && echo "用法: $SCRIPT_NAME combo <index|name>" && exit 1
        init_combos
        local sel="$2"; shift 2
        local cmd_ids=""
        if [[ "$sel" =~ ^[0-9]+$ ]]; then
          cmd_ids=$(jq -r '."预设组合"['"$((sel-1))"'].commands | join(" ")' "$COMBOS_FILE" 2>/dev/null)
        else
          cmd_ids=$(jq -r '."预设组合"[] | select(.name=="'"$sel"'") | .commands | join(" ")' "$COMBOS_FILE" 2>/dev/null)
        fi
        if [ -z "$cmd_ids" ] || [ "$cmd_ids" = "null" ]; then
          echo "未找到命令组合: $sel"
          exit 1
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
      help|-h|--help) show_help; exit 0;;
      version|-v|--version) echo "Linux Command Helper v$L_VERSION"; exit 0;;
      *) quick_execute "$1";;
    esac
  fi
}

################################################################################
# 命令定义（id|category|name|command|needs_sudo|dependency|desc|params|scenarios|notes|related）
################################################################################

declare -a COMMANDS

# 1. 系统管理
COMMANDS+=(
"1.1|system|APT 更新|apt update|yes|require_cmd apt|更新软件包索引|apt update|• 刷新索引\n• 升级前准备|• 需要网络|• 使用国内镜像可提速"
)
COMMANDS+=(
"1.2|system|APT 升级|apt upgrade -y|yes|require_cmd apt|升级已安装的软件包|apt upgrade -y|• 安全更新|• 批量升级|• 建议维护窗口执行"
)
COMMANDS+=(
"1.3|system|APT 清理旧包|apt autoremove -y|yes|require_cmd apt|移除不再需要的包|apt autoremove|• 清理依赖|• 释放空间|• 注意不要中断"
)
COMMANDS+=(
"1.4|system|APT 清缓存|apt clean|yes|require_cmd apt|清理 APT 下载缓存|apt clean|• 磁盘吃紧|• 可与 journal 清理配合|• 不影响已安装软件"
)
COMMANDS+=(
"1.5|system|清理 journal 日志|journalctl --vacuum-time=7d|yes|require_cmd journalctl|删除 7 天前的日志|--vacuum-time=7d|• 日志过大|• 释放空间|• 可改为 --vacuum-size=2G"
)
COMMANDS+=(
"1.6|system|查看系统信息|lsb_release -a || cat /etc/os-release|no|none|查看发行版与版本|lsb_release -a|• 基础信息|• 版本确认|• 低权限可执行"
)
COMMANDS+=(
"1.7|system|启用时间同步|timedatectl set-ntp true|yes|require_cmd timedatectl|启用系统时间同步|timedatectl|• 保持时钟准确|• 需要 systemd"
)
COMMANDS+=(
"1.8|system|切换 APT 源(预览)|switch_apt_mirror|yes|require_cmd apt|切换为国内/官方镜像（预览+备份）|自动识别代号|• 下载慢时|• 先预览变更|• 双确认，自动备份 sources.list"
)

# 2. 服务与进程
COMMANDS+=(
"2.1|service|服务状态|manage_service status|yes|require_cmd systemctl|查看服务状态|systemctl status <name>|• 服务排查|• 支持nginx/ssh等|• 需要服务名"
)
COMMANDS+=(
"2.2|service|启动服务|manage_service start|yes|require_cmd systemctl|启动指定服务|systemctl start <name>|• 手动拉起|• 需要服务名"
)
COMMANDS+=(
"2.3|service|重启服务|manage_service restart|yes|require_cmd systemctl|重启指定服务|systemctl restart <name>|• 配置生效|• 需要服务名"
)
COMMANDS+=(
"2.4|service|开机自启|manage_service enable|yes|require_cmd systemctl|启用自启动|systemctl enable <name>|• 重要服务|• 需要服务名"
)
COMMANDS+=(
"2.5|service|取消自启|manage_service disable|yes|require_cmd systemctl|禁用自启动|systemctl disable <name>|• 非必要服务|• 需要服务名"
)

# 3. 网络工具
COMMANDS+=(
"3.1|network|查看 IP/路由|ip a && echo '' && ip r|no|require_cmd ip|查看 IP 与路由|ip a; ip r|• 网络排查|• 基本信息"
)
COMMANDS+=(
"3.2|network|查看 DNS|resolvectl status || systemd-resolve --status|no|none|查看系统 DNS 配置|resolvectl|• DNS 故障排查|• 需要 systemd-resolved"
)
COMMANDS+=(
"3.3|network|端口监听|sudo ss -ltnp|yes|require_cmd ss|查看监听端口|ss -ltnp|• 查看端口被占用|• 需要 sudo 显示进程"
)
COMMANDS+=(
"3.4|network|DNS 查询 dig|dig +nocmd example.com any +multiline +noall +answer|no|require_cmd dig|通过 dig 查询 DNS|dig <domain>|• DNS 验证|• 需安装 dnsutils"
)
COMMANDS+=(
"3.5|network|Ping 测试|ping -c 4 8.8.8.8|no|require_cmd ping|网络连通性测试|ping -c 4 <host>|• 连通性检查|• 可改为目标域名"
)
COMMANDS+=(
"3.6|network|Traceroute|traceroute -n 8.8.8.8|no|require_cmd traceroute|路由追踪|traceroute <host>|• 延迟/跳点分析|• 需安装 traceroute"
)

# 4. 存储与文件
COMMANDS+=(
"4.1|storage|磁盘使用情况|df -h|no|require_cmd df|查看磁盘占用|df -h|• 空间预警|• 基础信息"
)
COMMANDS+=(
"4.2|storage|目录占用排行|du -xh /var/log | sort -hr | head -50|no|require_cmd du|查看 /var/log 占用排行|du -xh <dir> | sort -hr | head -50|• 清理依据"
)
COMMANDS+=(
"4.3|storage|查找大文件|find_large_files_linux|no|none|查找指定目录超过阈值的大文件|find <dir> -size +XM|• 磁盘吃紧|• 精准定位"
)
COMMANDS+=(
"4.4|storage|压缩为 tar.gz|compress_tar_gz|no|require_cmd tar|将目录压缩为 tar.gz|tar -czf out.tar.gz dir|• 备份归档|• 传输方便"
)
COMMANDS+=(
"4.5|storage|解压 tar.gz|decompress_tar_gz|no|require_cmd tar|解压 tar.gz 文件|tar -xzf file -C dir|• 恢复备份|• 常见场景"
)
COMMANDS+=(
"4.6|storage|安全删除（shred）|secure_delete|yes|require_cmd shred|用 shred 多次覆写删除|shred -u -n 3 -z <file>|• 物理介质|• SSD/CoW 文件系统效果有限"
)

# 5. 安全与防火墙
COMMANDS+=(
"5.1|security|UFW 状态|ufw status verbose|yes|require_cmd ufw|查看 UFW 状态与规则|ufw status|• 端口规则审计|• 需要 root"
)
COMMANDS+=(
"5.2|security|安全启用 UFW|enable_ufw_safe|yes|require_cmd ufw|在允许 SSH 的前提下启用 UFW|先允许 22/tcp|• 防断连|• 双确认"
)
COMMANDS+=(
"5.3|security|Fail2ban 状态|fail2ban_client_status|yes|none|查看 Fail2ban 状态|fail2ban-client status|• 暴力破解防护|• 如果已安装"
)
COMMANDS+=(
"5.4|security|SSHD 加固|harden_sshd|yes|require_cmd sshd|备份+禁用密码登录/禁 root 登陆（预览/回滚）|sshd_config|• 安全加固|• 双确认+测试"
)
COMMANDS+=(
"5.5|security|自动安全更新|unattended_upgrades_status|yes|none|启用/检查自动安全更新|unattended-upgrades|• 服务器安全"
)

# 6. 用户与权限
COMMANDS+=(
"6.1|user|新增用户|add_user|yes|require_cmd adduser|交互创建用户|adduser <name>|• 新用户创建|• 自动加入 sudo 可选"
)
COMMANDS+=(
"6.2|user|赋予 sudo 权限|grant_sudo|yes|require_cmd usermod|将用户加入 sudo 组|usermod -aG sudo <name>|• 提权|• 小心使用"
)

# 7. 容器与开发
COMMANDS+=(
"7.1|dev|Docker 状态|systemctl status docker|yes|require_cmd systemctl|查看 Docker 服务状态|systemctl status docker|• 运维基础"
)
COMMANDS+=(
"7.2|dev|Docker 清理|docker system prune -a -f --volumes|yes|require_cmd docker|清理未使用的镜像与卷|docker system prune|• 释放空间|• 慎用"
)
COMMANDS+=(
"7.3|dev|Git 全局配置|git_config_global|no|require_cmd git|配置 Git 用户名与邮箱|git config --global|• 统一身份|• 便于提交"
)

# 8. 监控与日志
COMMANDS+=(
"8.1|monitor|系统概览|hostnamectl; echo ''; top -b -n1 | head -n 20|no|require_cmd top|查看主机名与Top|top -b -n1|• 快速概览"
)
COMMANDS+=(
"8.2|monitor|CPU/内存占用前10|ps aux | sort -rk 3 | head -11; echo ''; ps aux | sort -rk 4 | head -11|no|require_cmd ps|按 CPU/内存排序|ps aux|• 定位高占用"
)
COMMANDS+=(
"8.3|monitor|最近错误日志|journalctl -p err -n 100 --no-pager|yes|require_cmd journalctl|查看最近错误|journalctl -p err|• 异常排查"
)

# 9. 备份与计划
COMMANDS+=(
"9.1|backup|rsync 备份(预览)|rsync_backup|yes|require_cmd rsync|rsync 目录备份（dry-run 预览）|rsync -aAXv --dry-run src/ dest/|• 备份迁移|• 预览后再执行"
)
COMMANDS+=(
"9.2|backup|编辑定时任务|crontab -e|yes|require_cmd crontab|编辑当前用户定时任务|crontab -e|• 定时维护|• 安全执行"
)

# 10. 快捷
COMMANDS+=(
"10.1|quick|显示帮助|show_help|no|none|显示使用帮助|帮助页面|• 不熟悉时|• 学习入口"
)

################################################################################
# 命令实现函数（Linux专用）
################################################################################

switch_apt_mirror() {
  if ! require_cmd lsb_release; then show_warning "未检测到 lsb_release，将尝试从 /etc/os-release 读取"; fi
  local codename=$(lsb_release -cs 2>/dev/null || . /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-focal}")
  local src="/etc/apt/sources.list"; local backup="/etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)"
  echo -e "\n${COLOR_INFO}当前系统代号: $codename${COLOR_RESET}\n"
  echo "  1. 官方源"
  echo "  2. 阿里云"
  echo "  3. 清华"
  echo "  4. 中科大"
  echo ""
  echo -ne "${COLOR_ACCENT}选择镜像: ${COLOR_RESET}"; read -r choice
  local base=""; case "$choice" in
    1) base="http://archive.ubuntu.com/ubuntu" ;;
    2) base="https://mirrors.aliyun.com/ubuntu" ;;
    3) base="https://mirrors.tuna.tsinghua.edu.cn/ubuntu" ;;
    4) base="https://mirrors.ustc.edu.cn/ubuntu" ;;
    *) show_error "无效选项"; return ;;
  esac
  echo -e "\n${COLOR_INFO}预览新 sources.list:${COLOR_RESET}\n"
  cat <<SRC
deb $base $codename main restricted universe multiverse
deb $base $codename-updates main restricted universe multiverse
deb $base $codename-backports main restricted universe multiverse
deb $base $codename-security main restricted universe multiverse
SRC
  if confirm "是否备份并应用？"; then
    sudo cp "$src" "$backup" && show_success "已备份到 $backup"
    cat <<SRC | sudo tee "$src" >/dev/null
deb $base $codename main restricted universe multiverse
deb $base $codename-updates main restricted universe multiverse
deb $base $codename-backports main restricted universe multiverse
deb $base $codename-security main restricted universe multiverse
SRC
    show_success "已写入新源"; show_info "执行 apt update 刷新索引"; sudo apt update
  else
    show_info "已取消"
  fi
}

manage_service() {
  local action="$1"; echo -ne "${COLOR_ACCENT}输入服务名（如 nginx/ssh/mysql）: ${COLOR_RESET}"; read -r svc
  if ! sanitize_name "$svc"; then show_error "名称不合法"; return; fi
  case "$action" in
    status|start|stop|restart) sudo systemctl "$action" "$svc" ;;
    enable|disable) sudo systemctl "$action" "$svc" ;;
    *) show_error "未知动作" ;;
  esac
}

find_large_files_linux() {
  echo -ne "${COLOR_ACCENT}输入目录 [默认: /var]: ${COLOR_RESET}"; read -r dir; dir=${dir:-/var}
  echo -ne "${COLOR_ACCENT}阈值(MB) [默认: 200]: ${COLOR_RESET}"; read -r mb; mb=${mb:-200}
  if ! sanitize_path "$dir" || ! sanitize_int "$mb"; then show_error "输入不合法"; return; fi
  show_info "查找大于 ${mb}MB 的文件于 $dir (最多 200 条)"
  sudo find "$dir" -xdev -type f -size +${mb}M -printf '%s %p\n' 2>/dev/null | sort -nr | head -200 | awk '{ sz=$1/1024/1024; $1=""; printf "%-8.1fMB %s\n", sz, substr($0,2)}'
}

compress_tar_gz() {
  echo -ne "${COLOR_ACCENT}输入要压缩的目录: ${COLOR_RESET}"; read -r d; sanitize_path "$d" || { show_error "路径不合法"; return; }
  echo -ne "${COLOR_ACCENT}输出文件名 [默认: archive.tar.gz]: ${COLOR_RESET}"; read -r o; o=${o:-archive.tar.gz}
  tar -czf "$o" -C "$(dirname "$d")" "$(basename "$d")" && show_success "已生成 $o"
}

decompress_tar_gz() {
  echo -ne "${COLOR_ACCENT}输入 tar.gz 文件: ${COLOR_RESET}"; read -r f; [ -f "$f" ] || { show_error "文件不存在"; return; }
  echo -ne "${COLOR_ACCENT}解压到目录 [默认: 当前目录]: ${COLOR_RESET}"; read -r d; d=${d:-.}
  tar -xzf "$f" -C "$d" && show_success "已解压到 $d"
}

secure_delete() {
  echo -ne "${COLOR_ACCENT}输入文件路径: ${COLOR_RESET}"; read -r f; [ -f "$f" ] || { show_error "文件不存在"; return; }
  show_warning "将使用 shred 多次覆写删除，此操作在某些文件系统上不保证不可恢复。"
  if confirm "确认删除？"; then sudo shred -u -n 3 -z "$f" && show_success "已删除"; else show_info "已取消"; fi
}

enable_ufw_safe() {
  if ! check_cmd ufw; then show_error "未安装 ufw"; return; fi
  echo -e "${COLOR_INFO}当前 UFW 状态:${COLOR_RESET}"; sudo ufw status verbose
  echo -e "\n${COLOR_INFO}检测 SSH 端口:${COLOR_RESET}"; local ssh_port=$(ss -ltnp 2>/dev/null | awk -F'[: ]+' '/:22/ {print 22; exit}')
  if [ -z "$ssh_port" ]; then
    show_warning "未检测到 22 端口监听，请确认 SSH 端口。"
  fi
  echo -ne "${COLOR_ACCENT}允许 SSH 端口（默认 22）: ${COLOR_RESET}"; read -r p; p=${p:-22}
  if ! sanitize_int "$p"; then show_error "端口不合法"; return; fi
  echo -e "${COLOR_INFO}预执行: ufw allow ${p}/tcp && ufw enable${COLOR_RESET}"
  if confirm "是否继续？"; then
    sudo ufw allow "$p"/tcp && sudo ufw enable && show_success "UFW 已启用，并允许 ${p}/tcp"
  else
    show_info "已取消"
  fi
}

fail2ban_client_status() {
  if check_cmd fail2ban-client; then sudo fail2ban-client status; else show_warning "未安装 fail2ban"; fi
}

harden_sshd() {
  local cfg="/etc/ssh/sshd_config"; local bak="/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"
  echo -e "${COLOR_INFO}当前 sshd_config 预览(前20行):${COLOR_RESET}"; head -n 20 "$cfg" 2>/dev/null || true
  echo -e "\n${COLOR_INFO}将进行以下修改（预览）:${COLOR_RESET}\n  - PasswordAuthentication no\n  - PermitRootLogin no"
  if confirm "是否备份并应用？"; then
    sudo cp "$cfg" "$bak" && show_success "已备份到 $bak"
    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$cfg"
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$cfg"
    if sudo sshd -t; then sudo systemctl reload sshd || sudo systemctl reload ssh; show_success "已应用并重载"; else show_error "配置语法校验失败，已保持备份"; fi
  else
    show_info "已取消"
  fi
}

unattended_upgrades_status() {
  if check_cmd unattended-upgrades; then
    echo -e "${COLOR_INFO}unattended-upgrades 状态:${COLOR_RESET}"; sudo systemctl status unattended-upgrades || true
  else
    show_warning "未安装 unattended-upgrades"
    confirm "是否现在安装 unattended-upgrades？" && sudo apt update && sudo apt install -y unattended-upgrades && show_success "已安装"
  fi
}

git_config_global() {
  echo -ne "${COLOR_ACCENT}用户名: ${COLOR_RESET}"; read -r name; sanitize_name "$name" || { show_error "用户名不合法"; return; }
  echo -ne "${COLOR_ACCENT}邮箱: ${COLOR_RESET}"; read -r email; echo "$email" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' || { show_error "邮箱不合法"; return; }
  git config --global user.name "$name" && git config --global user.email "$email" && show_success "Git 配置完成"
}

add_user() {
  echo -ne "${COLOR_ACCENT}新用户名: ${COLOR_RESET}"; read -r u; sanitize_name "$u" || { show_error "不合法"; return; }
  sudo adduser "$u" && show_success "已创建用户 $u"
}

grant_sudo() {
  echo -ne "${COLOR_ACCENT}用户名: ${COLOR_RESET}"; read -r u; sanitize_name "$u" || { show_error "不合法"; return; }
  sudo usermod -aG sudo "$u" && show_success "已将 $u 加入 sudo 组"
}

rsync_backup() {
  echo -ne "${COLOR_ACCENT}源目录: ${COLOR_RESET}"; read -r src
  echo -ne "${COLOR_ACCENT}目标目录: ${COLOR_RESET}"; read -r dst
  if ! sanitize_path "$src" || ! sanitize_path "$dst"; then show_error "路径不合法"; return; fi
  echo -e "${COLOR_INFO}预览(dry-run):${COLOR_RESET}"
  sudo rsync -aAXv --dry-run "$src"/ "$dst"/
  if confirm "确认执行同步？"; then sudo rsync -aAXv "$src"/ "$dst"/ && show_success "同步完成"; else show_info "已取消"; fi
}

show_history() {
  clear_screen
  echo -e "${COLOR_TITLE}${BOLD}📜 执行历史${COLOR_RESET}\n"
  if [ ! -s "$HISTORY_FILE" ]; then show_info "暂无历史"; press_any_key; return; fi
  tail -n 20 "$HISTORY_FILE" | tac
  press_any_key
}

view_favorites_menu() {
  clear_screen; echo -e "${COLOR_TITLE}${BOLD}⭐ 收藏夹${COLOR_RESET}\n"; init_favorites
  if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq >/dev/null 2>&1; then
    show_error "收藏功能需要 jq"
    press_any_key
    return
  fi
  local favorites=$(cat "$FAVORITES_FILE")
  [ "$favorites" = "[]" ] && show_info "收藏夹为空" && press_any_key && return
  local index=1; local favorite_cmds=()
  while IFS= read -r id; do id=$(echo "$id" | tr -d '",[]' | xargs); [ -z "$id" ] && continue; for c in "${COMMANDS[@]}"; do IFS='|' read -r cid _ name _ _ _ _ _ _ _ _ <<< "$c"; [ "$cid" = "$id" ] && echo -e "  ${BOLD}$index.${COLOR_RESET} $name ${COLOR_DIM}[$cid]${COLOR_RESET}" && favorite_cmds[$index]="$c" && index=$((index+1)) && break; done; done < <(echo "$favorites" | jq -r '.[]')
  echo -ne "\n${COLOR_ACCENT}选择编号执行(0返回): ${COLOR_RESET}"; read -r ch; [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -lt "$index" ] && execute_command "${favorite_cmds[$ch]}"
}

view_combos() {
  clear_screen; echo -e "${COLOR_TITLE}${BOLD}🎯 命令组合${COLOR_RESET}\n"; init_combos
  if [ "${CMD_HELPER_DISABLE_JQ:-0}" = "1" ] || ! command -v jq >/dev/null 2>&1; then
    show_error "命令组合需要 jq"
    press_any_key
    return
  fi
  echo -e "${COLOR_INFO}预设组合:${COLOR_RESET}\n"
  local idx=1
  jq -r '.预设组合[] | "\(.name)|\(.description)|\(.commands | join(","))"' "$COMBOS_FILE" | while IFS='|' read -r name desc ids; do echo -e "  ${BOLD}$idx.${COLOR_RESET} $name\n     ${COLOR_DIM}$desc${COLOR_RESET}\n     ${COLOR_DIM}命令: $ids${COLOR_RESET}\n"; idx=$((idx+1)); done
  echo -ne "${COLOR_ACCENT}选择编号执行(0返回): ${COLOR_RESET}"; read -r choice; [ "$choice" = "0" ] && return
  local combo=$(jq -r ".预设组合[$((choice-1))]" "$COMBOS_FILE")
  [ "$combo" = "null" ] && show_error "无效选项" && press_any_key && return
  local cmd_ids=$(echo "$combo" | jq -r '.commands | join(" ")')
  echo -e "\n${COLOR_INFO}将执行组合:${COLOR_RESET} $(echo "$combo" | jq -r '.name')\n"; if ! confirm "确认执行？"; then show_info "已取消"; press_any_key; return; fi
  for cid in $cmd_ids; do for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$cid" ] && execute_command "$c" "yes" && break; done; done
  show_success "组合执行完成"; press_any_key
}

################################################################################
# 主循环
################################################################################

cli_entry "$@"

while true; do
  show_main_menu; read -r main_choice
  case "$main_choice" in
    1)
      while true; do show_category_menu "system" "系统管理"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    2)
      while true; do show_category_menu "service" "服务与进程"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    3)
      while true; do show_category_menu "network" "网络工具"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    4)
      while true; do show_category_menu "storage" "存储与文件"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    5)
      while true; do show_category_menu "security" "安全与防火墙"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    6)
      while true; do show_category_menu "user" "用户与权限"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    7)
      while true; do show_category_menu "dev" "容器与开发"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    8)
      while true; do show_category_menu "monitor" "监控与日志"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    9)
      while true; do show_category_menu "backup" "备份与计划"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    10)
      while true; do show_category_menu "quick" "快捷工具"; read -r sub; [ "$sub" = "0" ] && break; if [[ "$sub" =~ ^[0-9]+$ ]] && [ "$sub" -ge 1 ] && [ "$sub" -le "${LAST_CATEGORY_COUNT:-0}" ]; then target_id="${LAST_CATEGORY_CMDS[$sub]}"; else target_id="$sub"; fi; for c in "${COMMANDS[@]}"; do IFS='|' read -r id _ _ _ _ _ _ _ _ _ _ <<< "$c"; [ "$id" = "$target_id" ] && execute_command "$c" && break; done; done
      ;;
    f|F) view_favorites_menu ;;
    r|R) show_history ;;
    c|C) view_combos ;;
    s|S) search_commands ;;
    h|H) show_help ;;
    q|Q) clear; echo -e "${COLOR_SUCCESS}${ICON_SUCCESS} 再见！${COLOR_RESET}"; exit 0 ;;
    *) show_error "无效选项"; sleep 1 ;;
  esac
done

