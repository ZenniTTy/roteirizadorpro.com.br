#!/usr/bin/env bash
# Re-inject the canonical M2 roadmap head + current TODO state after context compaction.
# Triggered by SessionStart with matcher "compact" — output goes straight into Claude's context.
# Per Anthropic docs (en/hooks-guide): "Any text your command writes to stdout is added to Claude's context."

set -euo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

echo "## Re-injected after compaction — canonical M2 sources"
echo
echo "Per CLAUDE.md, the single source of truth for M2 is docs/08-ROADMAP.md."
echo "Slice-execution discipline lives in docs/M2-SLICE-CHECKLIST.md."
echo

if [[ -f docs/08-ROADMAP.md ]]; then
  echo "### docs/08-ROADMAP.md (head)"
  echo '```'
  sed -n '1,40p' docs/08-ROADMAP.md
  echo '```'
  echo
fi

if [[ -f TODO.md ]]; then
  echo "### TODO.md (head)"
  echo '```'
  sed -n '1,25p' TODO.md
  echo '```'
fi

exit 0
