#!/usr/bin/env bash
# Run `flutter analyze --no-pub` over Dart files in apps/mobile/lib/ that were edited this turn.
# Stop hook — fires once per agent stop, batched across edits. ADR-0018.
# Non-blocking: exit 0 silent (clean or out of scope), exit 1 warn (issues found), never exit 2.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0

input="$(cat)"
transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"

if [[ -n "$transcript_path" && -f "$transcript_path" ]]; then
  edited_files="$(
    jq -r '
      select(.type == "assistant")
      | .message.content[]?
      | select(.type == "tool_use" and (.name == "Edit" or .name == "Write" or .name == "MultiEdit"))
      | .input.file_path // .input.path // empty
    ' "$transcript_path" 2>/dev/null | sort -u || true
  )"
else
  exit 0
fi

[[ -z "$edited_files" ]] && exit 0

dart_targets=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  [[ "$f" != *.dart ]] && continue
  [[ "$f" != *"apps/mobile/lib/"* ]] && continue
  [[ "$f" == *.g.dart ]] && continue
  [[ ! -f "$f" ]] && continue
  rel="${f#*apps/mobile/}"
  dart_targets="${dart_targets}${rel}"$'\n'
done <<< "$edited_files"

dart_targets="${dart_targets%$'\n'}"

[[ -z "$dart_targets" ]] && exit 0

if ! command -v flutter >/dev/null 2>&1; then
  exit 0
fi

cd apps/mobile || exit 0

output="$(printf '%s\n' "$dart_targets" | tr '\n' '\0' | xargs -0 flutter analyze --no-pub 2>&1 || true)"

if printf '%s\n' "$output" | grep -qE '^\s*(error|warning|info)\s'; then
  echo "analyze-changed-dart: flutter analyze surfaced issues in turn-edited Dart files." >&2
  echo "$output" >&2
  exit 1
fi

exit 0
