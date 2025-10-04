#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/tests/lib/test_env.sh"

setup_test_env "linux"

SCRIPT="$REPO_ROOT/linux-cmd-helper.sh"
CONFIG_DIR="$HOME/.linux-cmd-helper"
HISTORY_FILE="$CONFIG_DIR/history.log"
FAVORITES_FILE="$CONFIG_DIR/favorites.json"
METRICS_FILE="$CONFIG_DIR/metrics.json"
ERROR_LOG="$CONFIG_DIR/error.log"

run_expect_regex "version flag" "Linux Command Helper v[0-9]+\\.[0-9]+\\.[0-9]+" "$TEST_BASH" "$SCRIPT" version
run_expect_regex "help command" "帮助" "$TEST_BASH" "$SCRIPT" help
run_expect_json_array "search json output" "$TEST_BASH" "$SCRIPT" search APT --json

reset_command_log
run_expect_success "search run executes" "$TEST_BASH" "$SCRIPT" search 网络 --run 3.1
assert_log_contains "search run log" '^3\.1\|'

reset_command_log
run_expect_success "search first executes" "$TEST_BASH" "$SCRIPT" search APT --first
assert_log_contains "search first log" '^1\.1\|'

reset_command_log
run_expect_success "quick execute 1.2" "$TEST_BASH" "$SCRIPT" 1.2
assert_log_contains "quick execute log" '^1\.2\|'
assert_file_contains "history records success" "$HISTORY_FILE" '1\.2\|APT 升级\|success'
assert_file_contains "metrics updated" "$METRICS_FILE" '"1.2"'

export CMD_HELPER_TEST_FAIL_IDS="1.4"
reset_command_log
run_expect_failure "simulated failure exit" "$TEST_BASH" "$SCRIPT" 1.4
export CMD_HELPER_TEST_FAIL_IDS=""
assert_log_contains "failure logged" '^1\.4\|'
assert_file_contains "history records failure" "$HISTORY_FILE" '1\.4\|APT 清缓存\|failed'
assert_file_contains "error log entry" "$ERROR_LOG" '1\.4'

if output="$(printf '1\n1\nf\n0\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  record_result 0 "add favorite via menu"
else
  echo "--- Command output ---"
  echo "$output"
  echo "----------------------"
  record_result 1 "add favorite via menu"
fi
assert_file_contains "favorite stored" "$FAVORITES_FILE" '1\.1'

if favorites_output="$(printf 'f\n0\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  if grep -q 'APT 更新' <<<"$favorites_output"; then
    record_result 0 "favorites menu lists entry"
  else
    echo "--- Favorites output ---"
    echo "$favorites_output"
    echo "------------------------"
    record_result 1 "favorites menu lists entry"
  fi
else
  record_result 1 "favorites menu lists entry"
fi

reset_command_log
run_expect_success "combo executes" "$TEST_BASH" "$SCRIPT" combo 1
assert_file_contains "combo history 1.1" "$HISTORY_FILE" '1\.1\|APT 更新\|success'
assert_file_contains "combo history 1.2" "$HISTORY_FILE" '1\.2\|APT 升级\|success'
assert_file_contains "combo history 1.3" "$HISTORY_FILE" '1\.3\|APT 清理旧包\|success'

if history_output="$(printf 'r\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  if grep -q 'success' <<<"$history_output"; then
    record_result 0 "history view shows entries"
  else
    echo "--- History output ---"
    echo "$history_output"
    echo "----------------------"
    record_result 1 "history view shows entries"
  fi
else
  record_result 1 "history view shows entries"
fi

if output_no_jq="$(CMD_HELPER_DISABLE_JQ=1 "$TEST_BASH" "$SCRIPT" search APT --json 2>&1)"; then
  if grep -q '(system)' <<<"$output_no_jq"; then
    record_result 0 "search falls back without jq"
  else
    echo "--- search output without jq ---"
    echo "$output_no_jq"
    echo "--------------------------------"
    record_result 1 "search falls back without jq"
  fi
else
  record_result 1 "search falls back without jq"
fi

if output_fav_no_jq="$(CMD_HELPER_DISABLE_JQ=1 "$TEST_BASH" "$SCRIPT" <<< $'f\n0\nq\n' 2>&1)"; then
  if grep -q '收藏功能需要 jq' <<<"$output_fav_no_jq"; then
    record_result 0 "favorites warn without jq"
  else
    echo "--- favorites without jq ---"
    echo "$output_fav_no_jq"
    echo "----------------------------"
    record_result 1 "favorites warn without jq"
  fi
else
  record_result 1 "favorites warn without jq"
fi

if ! summarize_results; then
  exit 1
fi
