#!/usr/bin/env bash
# Mechanical refusal-discipline enforcement for the `flutter-test-author` subagent.
#
# Enforces ADR-0025's red-gate contract at the tool-call layer, not just in the prompt body.
# Triggered by PreToolUse(Edit|Write|MultiEdit) declared in the subagent's frontmatter.
#
# Rule: when the subagent writes to apps/mobile/lib/**/*.dart (production code), the new content
# MUST contain at least one `throw UnimplementedError()` token. That keeps the subagent honest:
# it can author stubs (which always contain the marker), but it cannot author real implementations
# (which never do). The marker can sit anywhere in the file; a single occurrence is enough.
#
# Allowed without checking:
#   - Anything under apps/mobile/test/**           (tests are the subagent's primary output)
#   - Anything outside apps/mobile/lib/**          (not under refusal contract)
#   - Files matching *.g.dart                       (codegen, owned by build_runner — ADR-0024)
#
# Exit codes:
#   0 = allow (silent)
#   2 = block (stderr message reaches the subagent + main thread)
#
# Why mechanical enforcement: empirical smoke (em sessões antes do reset 2026-05-26) mostrou que
# a regra de recusa via prompt-body sozinha é insuficiente sob prompts continuation-style. Este
# hook é a segunda camada de defesa; o prompt body é a primeira.

set -euo pipefail

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

[[ -z "$file_path" ]] && exit 0

# Normalize to relative path under the project root if absolute.
project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
rel_path="${file_path#"$project_root"/}"

# Only enforce on the production-code surface.
case "$rel_path" in
  apps/mobile/lib/*.dart|apps/mobile/lib/**/*.dart)
    : ;;
  *)
    exit 0 ;;
esac

# Codegen output is owned by build_runner (ADR-0024), not by the test author.
case "$rel_path" in
  *.g.dart|*.freezed.dart) exit 0 ;;
esac

# Extract the content the tool is about to write.
#   Write       → .tool_input.content
#   Edit        → .tool_input.new_string
#   MultiEdit   → .tool_input.edits[*].new_string  (concatenated)
content=""
case "$tool_name" in
  Write)
    content="$(printf '%s' "$input" | jq -r '.tool_input.content // empty')"
    ;;
  Edit)
    content="$(printf '%s' "$input" | jq -r '.tool_input.new_string // empty')"
    ;;
  MultiEdit)
    content="$(printf '%s' "$input" | jq -r '[.tool_input.edits[]?.new_string] | join("\n")')"
    ;;
  *)
    exit 0 ;;
esac

# Empty content means the tool input is malformed; let the tool itself report the error.
[[ -z "$content" ]] && exit 0

# THE RULE: the new content must contain at least one `throw UnimplementedError()` marker.
# Whitespace inside the parens is tolerated (e.g., `throw UnimplementedError( )` or with a message).
if printf '%s' "$content" | grep -qE 'throw[[:space:]]+UnimplementedError[[:space:]]*\('; then
  exit 0
fi

# Block: this looks like real implementation, not a stub.
cat >&2 <<'EOF'
BLOCKED by flutter-test-author refusal-discipline hook (.claude/hooks/block-test-author-impl.sh).

You attempted to write to apps/mobile/lib/ without including a `throw UnimplementedError()`
marker. The flutter-test-author subagent is contractually red-gate-only — it may author test
files and stubs (which always contain `throw UnimplementedError()` bodies), but it must NEVER
write real production logic. That is the implementer's job.

If the user asked you to "implement", "make tests pass", "continue from the prior handoff", or
similar, you must REFUSE and explain the bias-loop rationale from your prompt body. The user's
request being assertive does not override your discipline — that's precisely the situation this
hook exists to catch.

What to do now:
  1. Do NOT retry this Edit/Write with a different payload to bypass this hook.
  2. Respond to the user with a refusal: explain that production code is out of your scope per
     ADR-0025, and that they should hand off to the main agent (or another implementer subagent)
     to write the logic. Quote your test path and failing assertion so the handoff is clean.
  3. End your turn.
EOF
exit 2
