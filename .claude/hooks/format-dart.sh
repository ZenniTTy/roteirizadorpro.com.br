#!/usr/bin/env bash
# Auto-format Dart files after Edit/Write inside apps/mobile/.
# Fast (<1s for one file). Keeps the codebase consistent without slowing iteration.
# Triggered by PostToolUse on Edit|Write|MultiEdit.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

[[ -z "$file_path" ]] && exit 0
[[ "$file_path" != *.dart ]] && exit 0
[[ "$file_path" != *"/apps/mobile/"* ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0

if command -v dart >/dev/null 2>&1; then
  dart format "$file_path" >/dev/null 2>&1 || true
fi

exit 0
