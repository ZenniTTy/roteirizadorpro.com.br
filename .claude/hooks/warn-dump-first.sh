#!/usr/bin/env bash
# Warn (signal-only) when a session did live Spoke runtime inspection or a
# websearch WITHOUT first consulting the static dump baseline
# (docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md, ADR-0045) this session.
#
# Dump-first discipline (ADR-0045/0048): the static dump is the source of WHAT
# exists (frozen fact); runtime/websearch only CONFIRM behavior the dump can't
# carry. Reaching for Maestro/adb or WebSearch before reading the dump is the
# stale-inference failure mode the dump exists to kill — and it can pollute the
# licensed Spoke account with test state. This hook is the in-loop nudge,
# mirroring warn-adr-drift. Non-blocking: exit 0 silent, exit 1 warn.

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

# All file paths Read this session (to detect a MASTER-TABLE consult).
read_paths="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Read")
    | .input.file_path // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# Bash commands run this session (to detect adb/uiautomator runtime inspection).
bash_cmds="$(
  jq -r '
    select(.type == "assistant")
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Bash")
    | .input.command // empty
  ' "$transcript_path" 2>/dev/null || true
)"

# Did the session reach for RUNTIME Spoke inspection or a WEBSEARCH?
runtime_used=""
printf '%s\n' "$tool_names" | grep -qE 'mcp__maestro__|^WebSearch$' && runtime_used="yes"
printf '%s\n' "$bash_cmds"  | grep -qE 'uiautomator|adb +shell|screencap' && runtime_used="yes"

[[ -n "$runtime_used" ]] || exit 0

# Did the session consult the static dump baseline (MASTER-TABLE) first?
dump_consulted=""
printf '%s\n' "$read_paths" | grep -q 'spoke-dump-v3.65.1/MASTER-TABLE.md' && dump_consulted="yes"
# A grep over the heavy dump (~/spoke-dump/jadx-out) also counts as dump-first.
printf '%s\n' "$bash_cmds" | grep -qE 'spoke-dump|jadx-out' && dump_consulted="yes"

[[ -n "$dump_consulted" ]] && exit 0

echo "warn-dump-first: this session used live Spoke runtime inspection (Maestro/adb) or a websearch" >&2
echo "  but did NOT consult the static dump baseline first this session." >&2
echo "  Dump-first (ADR-0045/0048): READ docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md (or grep" >&2
echo "  ~/spoke-dump/jadx-out for behavioral/gating logic) BEFORE runtime — the dump is frozen fact;" >&2
echo "  runtime only confirms what the table's Precisa-runtime column flags." >&2
echo "  websearch/Context7 are for libraries (new dep or post-cutoff), NOT for Spoke behavior." >&2
echo "  This is a warning only (signal, never blocks). Exceptions: Áreas without a Spoke baseline" >&2
echo "  (Á1 auth, Á11 notifications) and genuinely-new libraries legitimately skip the dump." >&2
exit 1
