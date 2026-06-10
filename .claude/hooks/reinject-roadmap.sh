#!/usr/bin/env bash
# Re-inject the canonical M2 roadmap head + current TODO state after context compaction.
# Triggered by SessionStart with matcher "compact" — output goes straight into Claude's context.
# Per Anthropic docs (en/hooks-guide): "Any text your command writes to stdout is added to Claude's context."

set -euo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

echo "## Re-injected after compaction — canonical M2 sources"
echo
echo "Per CLAUDE.md, the single source of truth for M2 is docs/08-ROADMAP-v2.md."
echo "Slice-execution discipline lives in docs/M2-SLICE-CHECKLIST.md."
echo

if [[ -f docs/08-ROADMAP-v2.md ]]; then
  echo "### docs/08-ROADMAP-v2.md (head)"
  echo '```'
  sed -n '1,40p' docs/08-ROADMAP-v2.md
  echo '```'
  echo
fi

if [[ -f TODO.md ]]; then
  echo "### TODO.md (head)"
  echo '```'
  sed -n '1,25p' TODO.md
  echo '```'
  echo
fi

echo "### Dump-first + modern-practices gate (ADR-0045/0048)"
echo
echo "- **Dump-first:** for any Slice 2/3 screen with a Spoke equivalent, READ"
echo "  docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md FIRST (or grep ~/spoke-dump/jadx-out"
echo "  for behavioral/gating logic — gates, defaults, branches). The dump is frozen FACT;"
echo "  runtime (Maestro/adb) only CONFIRMS what the table's Precisa-runtime column flags."
echo "  Reaching for runtime before the dump is the stale-inference failure mode (ADR-0041..0044)"
echo "  and can pollute the licensed Spoke account. The Stop hook warn-dump-first.sh signals this."
echo "- **websearch/Context7 only when needed:** use them for LIBRARIES (a new dependency or a"
echo "  post-cutoff API), per the Context7-Mandatory rule + Dart-MCP-first precedence. They are"
echo "  NOT the source for Spoke behavior — that is the dump (and runtime confirmation)."
echo "- **Exceptions (skip the dump legitimately):** Áreas without a Spoke baseline — Á1 (auth"
echo "  leftovers) and Á11 (notifications) — and genuinely-new libraries."

exit 0
