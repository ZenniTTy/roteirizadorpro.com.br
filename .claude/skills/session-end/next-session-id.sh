#!/usr/bin/env bash
# Echo the next session ID in the format YYYY-MM-DD-NN, using America/Sao_Paulo time.
# NN is the next sequence number for today, computed from existing files in docs/sessions/.

set -euo pipefail

today="$(TZ=America/Sao_Paulo date +%Y-%m-%d)"
sessions_dir="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/docs/sessions"

if [[ ! -d "$sessions_dir" ]]; then
  echo "error: docs/sessions/ not found at $sessions_dir" >&2
  exit 1
fi

last_seq="$(
  find "$sessions_dir" -maxdepth 1 -type f -name "${today}-*.md" -print 2>/dev/null \
    | sed -E "s|.*/${today}-([0-9]+)-.*|\1|" \
    | grep -E '^[0-9]+$' \
    | sort -n \
    | tail -n1 \
    || true
)"

if [[ -z "$last_seq" ]]; then
  next="01"
else
  next="$(printf '%02d' $((10#$last_seq + 1)))"
fi

echo "${today}-${next}"
