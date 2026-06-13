#!/usr/bin/env bash
# Warn (signal-only) when a session violated the dump-first discipline
# (docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md, ADR-0045/0048) in one of
# TWO ways this session:
#
#   (a) did live Spoke runtime inspection (Maestro/adb) or a WebSearch WITHOUT
#       first consulting the static dump baseline — the original trigger; or
#   (b) EDITED Spoke-aligned feature code (apps/mobile/lib/features/**) WITHOUT
#       any dump-derived consultation at all — the stale-inference failure mode
#       that cost ADR-0041..0044 (implementing from memory/inference fires no
#       runtime and no websearch, so trigger (a) alone stays silent).
#
# "Consulting the dump" counts as ANY of: Read of the MASTER-TABLE, a grep/read
# over the heavy dump (~/spoke-dump / jadx-out), or Read of a dump-derived
# design doc (docs/superpowers/specs/*-design.md — distilled dump baselines).
#
# Non-blocking: exit 0 silent, exit 1 warn. Exceptions (legitimate dump skips,
# listed in the warning): Áreas without a Spoke baseline (Á1 auth, Á11
# notifications), pure bugfix/refactor/test sessions, genuinely-new libraries.

set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}" || exit 0

input="$(cat)"
transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"

# No transcript → nothing to inspect.
[[ -n "$transcript_path" && -f "$transcript_path" ]] || exit 0

# All tool_use names invoked by the assistant this session.
tool_names="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use")
    | .name // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# All file paths Read this session (to detect a dump/design-doc consult).
read_paths="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Read")
    | .input.file_path // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# Bash commands run this session (adb/uiautomator runtime + dump greps).
bash_cmds="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Bash")
    | .input.command // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# File paths edited this session (Edit/Write/MultiEdit) — for trigger (b).
edit_paths="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and (.name == "Edit" or .name == "Write" or .name == "MultiEdit"))
    | .input.file_path // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# ---- Did the session consult the dump baseline (any accepted form)? ----
dump_consulted=""
printf '%s\n' "$read_paths" | grep -q 'spoke-dump-v3.65.1/' && dump_consulted="yes"
# A grep/read over the heavy dump (~/spoke-dump, jadx-out) counts as dump-first.
printf '%s\n' "$bash_cmds" | grep -qE 'spoke-dump|jadx-out' && dump_consulted="yes"
# A dump-derived design doc (distilled baseline with file:line evidence) counts.
printf '%s\n' "$read_paths" | grep -q 'superpowers/specs/.*-design\.md' && dump_consulted="yes"

[[ -n "$dump_consulted" ]] && exit 0

# ---- Trigger (a): runtime inspection or websearch without the dump ----
runtime_used=""
printf '%s\n' "$tool_names" | grep -qE 'mcp__maestro__|^WebSearch$' && runtime_used="yes"
printf '%s\n' "$bash_cmds"  | grep -qE 'uiautomator|adb +shell|screencap' && runtime_used="yes"

# ---- Trigger (b): Spoke-aligned feature code edited without the dump ----
# Excludes features/auth/ (Á1 — no Spoke baseline) and test files.
features_edited=""
printf '%s\n' "$edit_paths" \
  | grep -E 'apps/mobile/lib/features/' \
  | grep -vE 'features/auth/' \
  | grep -q . && features_edited="yes"

[[ -z "$runtime_used" && -z "$features_edited" ]] && exit 0

if [[ -n "$runtime_used" ]]; then
  echo "warn-dump-first: this session used live Spoke runtime inspection (Maestro/adb) or a websearch" >&2
  echo "  but did NOT consult the static dump baseline first this session." >&2
fi
if [[ -n "$features_edited" ]]; then
  echo "warn-dump-first: this session EDITED apps/mobile/lib/features/** without any dump-derived" >&2
  echo "  consultation (MASTER-TABLE, ~/spoke-dump grep, or a specs/*-design.md baseline)." >&2
  echo "  Implementing a Spoke-aligned screen from memory/inference is the exact failure mode of" >&2
  echo "  ADR-0041..0044." >&2
fi
echo "  Dump-first (ADR-0045/0048): READ docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md (or grep" >&2
echo "  ~/spoke-dump/jadx-out for behavioral/gating logic) BEFORE runtime/implementation — the dump" >&2
echo "  is frozen fact; runtime only confirms what the table's Precisa-runtime column flags." >&2
echo "  websearch/Context7 are for libraries (new dep or post-cutoff), NOT for Spoke behavior." >&2
echo "  This is a warning only (signal, never blocks). Legitimate exceptions: Áreas without a Spoke" >&2
echo "  baseline (Á1 auth, Á11 notifications), pure bugfix/refactor/test-only sessions, and" >&2
echo "  genuinely-new libraries." >&2
exit 1
