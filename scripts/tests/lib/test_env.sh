#!/usr/bin/env bash
set -euo pipefail

TEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_LIB_DIR/../../.." && pwd)"
TEST_FIXTURE_BIN="$REPO_ROOT/scripts/tests/fixtures/bin"
TEST_BASH="$(command -v bash)"
TEST_JQ_PATH="$(command -v jq || true)"

TEST_PASS=0
TEST_FAIL=0
TEST_TOTAL=0

setup_test_env() {
  local platform="$1"
  TEST_TMPDIR="$(mktemp -d)"
  trap 'cleanup_test_env' EXIT
  export HOME="$TEST_TMPDIR"
  export NO_COLOR=1
  export LCMD_NO_COLOR=1
  export MCMD_NO_COLOR=1
  export LCMD_NONINTERACTIVE=1
  export MCMD_NONINTERACTIVE=1
  export CMD_HELPER_TEST_MODE=1
  export CMD_HELPER_TEST_FAIL_IDS=""
  export CMD_HELPER_TEST_LOG="$TEST_TMPDIR/command-log.txt"
  export CMD_HELPER_TEST_STUB_LOG="$TEST_TMPDIR/stub-log.txt"
  if [ -n "$TEST_JQ_PATH" ]; then
    export CMD_HELPER_ALLOW_REAL_JQ=1
  else
    unset CMD_HELPER_ALLOW_REAL_JQ || true
  fi
  : >"$CMD_HELPER_TEST_LOG"
  : >"$CMD_HELPER_TEST_STUB_LOG"
  mkdir -p "$TEST_TMPDIR/bin"
  export PATH="$TEST_FIXTURE_BIN:$PATH"
  platform_specific_env "$platform"
}

platform_specific_env() {
  local platform="$1"
  case "$platform" in
    linux)
      export TERM=${TERM:-xterm}
      ;;
    mac)
      export TERM=${TERM:-xterm}
      export MCMD_TELEMETRY=1
      ;;
  esac
}

cleanup_test_env() {
  local status=$?
  [ -n "${TEST_TMPDIR:-}" ] && rm -rf "$TEST_TMPDIR"
  exit $status
}

record_result() {
  local status="$1"
  local name="$2"
  if [ "$status" -eq 0 ]; then
    echo "[PASS] $name"
    TEST_PASS=$((TEST_PASS + 1))
  else
    echo "[FAIL] $name"
    TEST_FAIL=$((TEST_FAIL + 1))
  fi
  TEST_TOTAL=$((TEST_TOTAL + 1))
}

reset_command_log() {
  : > "$CMD_HELPER_TEST_LOG"
}

run_expect_success() {
  local name="$1"
  shift
  local output
  if output="$($@ 2>&1)"; then
    record_result 0 "$name"
  else
    echo "--- Command output ---"
    echo "$output"
    echo "----------------------"
    record_result 1 "$name"
  fi
}

run_expect_failure() {
  local name="$1"
  shift
  local output
  set +e
  output="$($@ 2>&1)"
  local status=$?
  set -e
  if [ $status -ne 0 ]; then
    record_result 0 "$name"
  else
    echo "--- Command output ---"
    echo "$output"
    echo "----------------------"
    record_result 1 "$name"
  fi
}

run_expect_regex() {
  local name="$1"
  local pattern="$2"
  shift 2
  local output
  if output="$($@ 2>&1)"; then
    if grep -E "$pattern" <<<"$output" >/dev/null; then
      record_result 0 "$name"
    else
      echo "--- Command output ---"
      echo "$output"
      echo "----------------------"
      record_result 1 "$name"
    fi
  else
    record_result 1 "$name"
  fi
}

run_expect_json_array() {
  local name="$1"
  shift
  local output
  if output="$($@ 2>&1)"; then
    if jq -e '. | type == "array"' <<<"$output" >/dev/null 2>&1; then
      record_result 0 "$name"
    else
      echo "--- Command output ---"
      echo "$output"
      echo "----------------------"
      record_result 1 "$name"
    fi
  else
    record_result 1 "$name"
  fi
}

assert_file_contains() {
  local name="$1"
  local file="$2"
  local pattern="$3"
  if [ -f "$file" ] && grep -E "$pattern" "$file" >/dev/null 2>&1; then
    record_result 0 "$name"
  else
    echo "--- File contents ($file) ---"
    [ -f "$file" ] && cat "$file"
    echo "--------------------------------"
    record_result 1 "$name"
  fi
}

assert_file_equals() {
  local name="$1"
  local file="$2"
  local expected="$3"
  if [ -f "$file" ] && [ "$(cat "$file")" = "$expected" ]; then
    record_result 0 "$name"
  else
    echo "--- File contents ($file) ---"
    [ -f "$file" ] && cat "$file"
    echo "--------------------------------"
    record_result 1 "$name"
  fi
}

assert_log_contains() {
  local name="$1"
  local pattern="$2"
  if grep -E "$pattern" "$CMD_HELPER_TEST_LOG" >/dev/null 2>&1; then
    record_result 0 "$name"
  else
    echo "--- Command log ---"
    cat "$CMD_HELPER_TEST_LOG"
    echo "--------------------"
    record_result 1 "$name"
  fi
}

summarize_results() {
  echo "--- Summary ---"
  echo "Total: $TEST_TOTAL, Pass: $TEST_PASS, Fail: $TEST_FAIL"
  if [ "$TEST_FAIL" -ne 0 ]; then
    return 1
  fi
  return 0
}

without_jq_path() {
  local cleaned=()
  local jq_dir
  jq_dir="${TEST_JQ_PATH%/*}"
  IFS=':' read -r -a parts <<< "$PATH"
  for part in "${parts[@]}"; do
    if [ -n "$jq_dir" ] && [ "$part" = "$jq_dir" ]; then
      continue
    fi
    cleaned+=("$part")
  done
  local new_path
  new_path="$(IFS=':'; echo "${cleaned[*]}")"
  echo "$new_path"
}
