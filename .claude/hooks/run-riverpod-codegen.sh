#!/usr/bin/env bash
# Regenerate Riverpod `.g.dart` files after Edit/Write of a Dart file that
# contains `@riverpod` annotations or a `part '*.g.dart'` directive.
# PostToolUse hook (Edit|Write|MultiEdit). ADR-0024 — extends ADR-0018.
#
# Non-blocking: exit 0 silent on every path except when build_runner itself
# fails, in which case we surface stderr (exit 1) so the assistant sees it.
#
# Debounce: a lock file under the OS temp dir prevents two concurrent
# build_runner invocations when the assistant edits multiple providers in
# the same turn — only the first edit triggers codegen; subsequent ones
# in the same ~120s window are skipped.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

[[ -z "$file_path" ]] && exit 0
[[ "$file_path" != *.dart ]] && exit 0
[[ "$file_path" != *"/apps/mobile/lib/"* ]] && exit 0
[[ "$file_path" == *.g.dart ]] && exit 0
[[ ! -f "$file_path" ]] && exit 0

# Only run if the edited file participates in Riverpod codegen.
if ! grep -qE '^@[Rr]iverpod|^part .+\.g\.dart' "$file_path"; then
  exit 0
fi

# Debounce — skip if another invocation ran in the last 90s.
lock="${TMPDIR:-/tmp}/roteirizador-riverpod-codegen.lock"
now=$(date +%s)
if [[ -f "$lock" ]]; then
  last=$(cat "$lock" 2>/dev/null || echo 0)
  if (( now - last < 90 )); then
    exit 0
  fi
fi
echo "$now" > "$lock"

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/apps/mobile" || exit 0

command -v dart >/dev/null 2>&1 || exit 0

if ! output="$(dart run build_runner build --delete-conflicting-outputs 2>&1)"; then
  echo "run-riverpod-codegen: build_runner failed for $file_path" >&2
  echo "$output" | tail -30 >&2
  exit 1
fi

exit 0
