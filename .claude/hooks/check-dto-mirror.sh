#!/usr/bin/env bash
# Warn when a TypeBox schema in apps/backend/src/<feature>/schemas.ts was edited
# this turn but its Dart DTO mirror at apps/mobile/lib/features/<feature>/data/dto/*.dart was not.
# Materializes ADR-0013 ("// Mirror of:" contract). ADR-0018.
# Non-blocking: exit 0 silent, exit 1 warn.

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

schemas_edited="$(printf '%s\n' "$edited_files" | grep -E 'apps/backend/src/[^/]+/schemas\.ts$' || true)"

[[ -z "$schemas_edited" ]] && exit 0

drift_lines=""
while IFS= read -r schema; do
  [[ -z "$schema" ]] && continue
  rel_schema="${schema#*apps/backend/}"
  rel_schema="apps/backend/${rel_schema}"

  mirrors="$(grep -rl "Mirror of: ${rel_schema}" apps/mobile/lib/features 2>/dev/null || true)"
  [[ -z "$mirrors" ]] && continue

  while IFS= read -r mirror; do
    [[ -z "$mirror" ]] && continue
    if ! printf '%s\n' "$edited_files" | grep -qxF "$mirror"; then
      drift_lines="${drift_lines}  - ${rel_schema} changed; mirror ${mirror} did NOT change this turn."$'\n'
    fi
  done <<< "$mirrors"
done <<< "$schemas_edited"

drift_lines="${drift_lines%$'\n'}"

if [[ -n "$drift_lines" ]]; then
  echo "check-dto-mirror: ADR-0013 contract drift — TypeBox schema(s) edited without matching Dart DTO update." >&2
  printf '%s\n' "$drift_lines" >&2
  echo "  Fix: update the mirror file in the same commit, per docs/decisions/0013-api-contract-source-of-truth.md." >&2
  exit 1
fi

exit 0
