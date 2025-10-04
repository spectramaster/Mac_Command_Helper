#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/tests/lib/test_env.sh"

setup_test_env "mac"

SCRIPT="$REPO_ROOT/mac-cmd-helper-v2.sh"
CONFIG_DIR="$HOME/.mac-cmd-helper"
HISTORY_FILE="$CONFIG_DIR/history.log"
FAVORITES_FILE="$CONFIG_DIR/favorites.json"
METRICS_FILE="$CONFIG_DIR/metrics.json"
ERROR_LOG="$CONFIG_DIR/error.log"

run_expect_regex "version flag" "Mac Command Helper v[0-9]+\\.[0-9]+\\.[0-9]+" "$TEST_BASH" "$SCRIPT" version
run_expect_regex "help details" "命令详解" "$TEST_BASH" "$SCRIPT" help 2.1
run_expect_json_array "search json output" "$TEST_BASH" "$SCRIPT" search 清理 --json

reset_command_log
run_expect_success "search run executes" "$TEST_BASH" "$SCRIPT" search 清理 --run 2.1
assert_log_contains "search run log" '^2\.1\|'

reset_command_log
run_expect_success "search first executes" "$TEST_BASH" "$SCRIPT" search Homebrew --first
assert_log_contains "search first log" '^3\.1\|'

reset_command_log
run_expect_success "quick execute 2.3" "$TEST_BASH" "$SCRIPT" 2.3
assert_log_contains "quick execute log" '^2\.3\|'
assert_file_contains "history success entry" "$HISTORY_FILE" '2\.3\|防止系统休眠\|success'
assert_file_contains "metrics updated" "$METRICS_FILE" '"2.3"'

export CMD_HELPER_TEST_FAIL_IDS="2.2"
reset_command_log
run_expect_failure "simulated failure" "$TEST_BASH" "$SCRIPT" 2.2
export CMD_HELPER_TEST_FAIL_IDS=""
assert_log_contains "failure recorded" '^2\.2\|'
assert_file_contains "history failure entry" "$HISTORY_FILE" '2\.2\|释放内存\|failed'
assert_file_contains "error log entry" "$ERROR_LOG" '2\.2'

if output="$(printf '2\n1\nf\n0\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  record_result 0 "add favorite via menu"
else
  echo "--- Command output ---"
  echo "$output"
  echo "----------------------"
  record_result 1 "add favorite via menu"
fi
assert_file_contains "favorite stored" "$FAVORITES_FILE" '2\.1'

if favorites_output="$(printf 'f\n0\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  if grep -q '深度清理系统' <<<"$favorites_output"; then
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
run_expect_success "combo cli executes" "$TEST_BASH" "$SCRIPT" combo 1
assert_log_contains "combo includes 2.1" '^2\.1\|'
assert_log_contains "combo includes 3.2" '^3\.2\|'
assert_log_contains "combo includes 2.2" '^2\.2\|'

if history_output="$(printf 'r\n0\nq\n' | "$TEST_BASH" "$SCRIPT" 2>&1)"; then
  if grep -q '2\.3' <<<"$history_output"; then
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

if output_no_jq="$(CMD_HELPER_DISABLE_JQ=1 "$TEST_BASH" "$SCRIPT" search 清理 --json 2>&1)"; then
  if grep -q '(system)' <<<"$output_no_jq"; then
    record_result 0 "search fallback without jq"
  else
    echo "--- Search output without jq ---"
    echo "$output_no_jq"
    echo "--------------------------------"
    record_result 1 "search fallback without jq"
  fi
else
  record_result 1 "search fallback without jq"
fi

if output_fav_no_jq="$(CMD_HELPER_DISABLE_JQ=1 "$TEST_BASH" "$SCRIPT" <<< $'f\nq\n' 2>&1)"; then
  if grep -q '收藏功能需要 jq' <<<"$output_fav_no_jq"; then
    record_result 0 "favorites warn without jq"
  else
    echo "--- Favorites without jq ---"
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
