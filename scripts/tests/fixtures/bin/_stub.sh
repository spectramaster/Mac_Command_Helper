#!/usr/bin/env bash
if [ -n "${CMD_HELPER_TEST_STUB_LOG:-}" ]; then
  printf "%s|%s\n" "$(basename "$0")" "$*" >> "$CMD_HELPER_TEST_STUB_LOG"
fi
# simulate some useful output for certain commands
case "$(basename "$0")" in
  jq)
    # fallback to real jq if available and script expects it
    if [ -n "$CMD_HELPER_ALLOW_REAL_JQ" ] && [ -n "${TEST_JQ_PATH:-}" ]; then
      exec "$TEST_JQ_PATH" "$@"
    fi
    ;;
esac
exit 0
