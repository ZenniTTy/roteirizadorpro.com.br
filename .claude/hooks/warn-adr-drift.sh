#!/usr/bin/env bash
# Warn when stack-affecting manifests were edited this turn but no ADR was added/modified.
# Shadows adr-guardian as in-loop signal (vs pre-PR audit). ADR-0018.
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

stack_hits="$(
  printf '%s\n' "$edited_files" \
    | grep -E '(apps/mobile/pubspec\.yaml|apps/backend/package\.json|apps/landing/package\.json|^package\.json$|apps/backend/prisma/schema\.prisma|infra/docker-compose\.ya?ml)$' \
    || true
)"

[[ -z "$stack_hits" ]] && exit 0

adr_changes="$(git status --porcelain -- 'docs/decisions/*.md' 2>/dev/null | grep -v '0000-template.md' || true)"

if [[ -z "$adr_changes" ]]; then
  echo "warn-adr-drift: stack-affecting file(s) edited this turn without a new/modified ADR." >&2
  echo "  CLAUDE.md → 'Stack — Locked Versions': any change requires a new ADR in docs/decisions/." >&2
  echo "  Files edited:" >&2
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    echo "    - $f" >&2
  done <<< "$stack_hits"
  echo "  Fix: author docs/decisions/NNNN-<slug>.md from docs/decisions/0000-template.md before opening the PR." >&2
  echo "  This is a warning only; adr-guardian remains the pre-PR gate." >&2
  exit 1
fi

exit 0
