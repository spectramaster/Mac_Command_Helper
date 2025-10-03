#!/usr/bin/env bash
set -euo pipefail

# Collect shell files portably (macOS bash 3.2 compatible)
files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find . -type f -name "*.sh" -not -path "*/node_modules/*" -not -path "./dist/*" -print0)

if ! command -v shellcheck &>/dev/null; then
  echo "shellcheck not found; skipping" >&2
  exit 0
fi

echo "Running shellcheck on ${#files[@]} files..."
shellcheck \
  --severity=warning \
  --exclude=SC1090,SC1091,SC2155,SC2154 \
  "${files[@]}"

echo "shellcheck passed."
