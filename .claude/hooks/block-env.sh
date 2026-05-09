#!/usr/bin/env bash
# Block edits/writes to .env* files (except .env.example).
# Enforces the "Secrets" rule from CLAUDE.md as a hook, not just convention.
# Triggered by PreToolUse on Edit|Write|MultiEdit.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

[[ -z "$file_path" ]] && exit 0

basename="${file_path##*/}"

if [[ "$basename" == ".env.example" ]]; then
  exit 0
fi

if [[ "$basename" == ".env" || "$basename" == .env.* ]]; then
  echo "BLOCKED: edits to '$basename' are forbidden by CLAUDE.md (gitignored secret file)." >&2
  echo "If you need to change env handling, edit .env.example or update docs/07-INFRA.md." >&2
  exit 2
fi

exit 0
