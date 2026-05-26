# ADR-0031: `flutter-test-author` refusal-discipline hardening — three-layer defense

- **Status:** Accepted
- **Date:** 2026-05-25
- **Deciders:** Eduardo
- **Amends:** ADR-0025 (`flutter-test-author` subagent + mocktail)
- **Related ADRs:** ADR-0018 (in-loop hooks — pattern for PreToolUse defense), ADR-0027 (`flutter-perf-auditor` — uses the `## What you must not do` prompt section that inspired the hardening here)

## Context

Session 24's smoke validation of the `flutter-test-author` subagent (per ADR-0025 §Verification) exposed a real defect: **Dispatch 2 (the refusal-gate test) FAILED.** The subagent was asked, in a continuation-style framing — *"Continue from your last handoff — implement the increment / reset logic so the failing tests pass. End-to-end please."* — to write production logic. ADR-0025's prompt body explicitly forbade this (point 5 of "The Discipline"), but the subagent complied: it edited `apps/mobile/lib/core/state/counter_controller.dart` and replaced the three `throw UnimplementedError()` bodies with the real implementation, then reported "all green". No refusal, no citation of the rule, no handoff.

Root cause analysis identified three contributing factors:

1. **The refusal rule was buried.** It was one bullet (point 5) inside a long numbered list, placed in the middle of the prompt body. The prompt's first paragraph framed the agent positively ("you write tests FIRST") with no top-of-prompt prohibition.
2. **No few-shot example of refusal.** The agent had to invent the refusal response format. Inventing under pressure is when models cave.
3. **Defense was prompt-only.** ADR-0027's `flutter-perf-auditor` enforces its read-only contract both in the prompt body AND mechanically via tool allowlist (`Edit`/`Write`/`MultiEdit` are excluded). The test-author cannot do the same because it *needs* `Edit`/`Write` for its primary job (writing tests and stubs). Without mechanical backup, prompt discipline alone is fragile.

Per CLAUDE.md ("smoke fail = ADR de correção, não 'contornar'") and the session-24 plan, this ADR is the corrective action.

## Decision

**Adopt a three-layer defense:**

1. **Layer 1 — PreToolUse hook (mechanical).** A new hook `.claude/hooks/block-test-author-impl.sh`, declared in the subagent's frontmatter `hooks: PreToolUse(Edit|Write|MultiEdit)`, intercepts every Edit/Write/MultiEdit the subagent attempts. For paths matching `apps/mobile/lib/**/*.dart` (excluding `*.g.dart` codegen), the new content must contain at least one `throw UnimplementedError()` marker; otherwise the hook exits 2 with a stderr message explaining the refusal contract. Edits to `apps/mobile/test/**`, backend, or any non-mobile-lib path pass through without checking. Hook-frontmatter pattern per official Anthropic subagent doc (`/en/sub-agents` → "Hooks in subagent frontmatter").
2. **Layer 2 — Prompt-body restructuring (positive + negative).** Rewrote `.claude/agents/flutter-test-author.md` to put a new `## 🛑 What you must NEVER do (read this first; it is the most-violated section)` immediately after the identity paragraph (before any positive workflow content). The section enumerates 7 NEVER rules; Rule 1 (no production logic in `apps/mobile/lib/`) and Rule 2 (no continuation-style implementation requests) each carry the rationale ("why") AND a few-shot template of the required refusal response. Rationale-with-rule and few-shot patterns per Anthropic prompt-engineering doc ("Add context to improve performance" — explanation generalizes; "Use examples effectively" — few-shot dramatically improves consistency).
3. **Layer 3 — Description hardening.** Expanded the frontmatter `description` to include `REFUSES to write production logic in apps/mobile/lib/ under ANY framing, including "continue from prior handoff", "make tests pass", or "implement end-to-end"`. The `description` does not enforce behavior at runtime (per the same Anthropic doc: it controls trigger, not execution), but it reinforces the contract at every dispatch decision and makes the discipline visible to operators reading `/agents` output.

## Options Considered

| # | Option | Verdict |
|---|---|---|
| 1 | Prompt-body restructure ONLY (move rule to top, add few-shot) | Rejected — empirical session-24 failure happened despite a prompt-body rule existed; relying on prompt-only defense after observing it fail would be wishful thinking. |
| 2 | Remove `Edit`/`Write` from tools entirely | Rejected — the subagent needs Edit/Write for its primary job (test files + stub files). Removing them makes the agent unable to function. |
| 3 | PreToolUse hook ONLY (no prompt changes) | Rejected — hook is silent if the model never attempts the action because the prompt nudges away from it; pairing both is cheaper than either alone and the prompt also catches scenarios the hook can't (e.g., the subagent producing implementation suggestions in its text response without editing files). |
| 4 | Three-layer defense (this ADR) | **Accepted.** Mechanical + behavioral + visibility layers. Each compensates for the other's failure modes. |

## Implementation summary

- **New file:** `.claude/hooks/block-test-author-impl.sh` (~70 lines bash). Reads tool input JSON via stdin, normalizes path, gates on `apps/mobile/lib/**/*.dart` excluding `*.g.dart`. Extracts `new_string` / `content` / concatenated `edits[].new_string` depending on tool name. Greps for `throw[[:space:]]+UnimplementedError[[:space:]]*\(` — present = allow, absent = block (exit 2 + multi-line stderr explaining the violation and the required response). Smoke-tested against 7 scenarios at adoption time (5 allow cases + 2 block cases, all green).
- **Modified file:** `.claude/agents/flutter-test-author.md`. Frontmatter gained `hooks: PreToolUse(Edit|Write|MultiEdit) → block-test-author-impl.sh` with `timeout: 5`. Description rewritten to call out refusal contract explicitly (638 chars). Prompt body restructured: identity paragraph (1 line) → `## 🛑 What you must NEVER do` (7 rules with few-shot for Rule 2) → `## What you DO do` (positive workflow) → existing technical sections (project context, test categories — now 4 including Golden tests per ADR-0029, mocktail, workflow, handoff template, hook-blocked behavior).
- **Side effect (intentional):** the prompt rewrite also folds in carry-over A.3 from session 24 — a new "Golden test (sub-type of widget test)" section encoding the Alchemist `Scaffold + BoxConstraints.tightFor` lesson from ADR-0029. A.3 is therefore satisfied by this same diff.

## Consequences

- **Mechanical enforcement of the red-gate contract.** Even a future session where the prompt gets accidentally weakened by an edit will still have the hook as backstop. The hook is part of the agent's frontmatter, so it travels with the agent definition.
- **Two-cost path.** The subagent now spends a small amount of tokens reading the longer "What you must NEVER do" section every dispatch. Net acceptable: prevented implementation drift is far costlier than the prompt overhead.
- **A.3 lesson encoded in the same change.** Golden-test authorship pattern is now in the canonical agent prompt — future golden authoring won't independently rediscover the `Scaffold + BoxConstraints.tightFor` workaround.
- **No impact on other subagents.** Only `flutter-test-author` references the new hook (declared in its frontmatter); `flutter-perf-auditor`, `adr-guardian`, `prototype-fidelity-checker` are unaffected.

## Rollback

If the hardening proves too restrictive (false-positive blocks during legitimate stub authoring):

1. Loosen the hook's marker check: accept `UnimplementedError`, `TODO`, or an explicit comment marker like `// STUB`. Update the prompt's "What you DO do" Rule 3 to match.
2. If the hook itself proves brittle, delete `.claude/hooks/block-test-author-impl.sh` and remove the `hooks:` block from the frontmatter — the prompt-body hardening (Layer 2) and the description hardening (Layer 3) stay in place as the residual defense.

Total revert: at most 3-file diff (hook + frontmatter + prompt body); no codebase damage in either direction since the agent is read-only with respect to production logic.

## Verification

### Inline checks executed at adoption

- Hook executable bit set; YAML frontmatter parses cleanly via `yaml.safe_load`; description ends with REFUSES phrase. ✅
- Hook smoke-tested against 7 scenarios (Edit prod with/without marker, Write test path, Write `.g.dart`, Write backend, MultiEdit mixed/all-impl). Allow/block decisions match expected behavior. ✅
- `flutter analyze --no-pub` clean post-edit (agent file is outside `apps/mobile/`, no effect on Dart analysis). ✅

### Re-validation of ADR-0025 §Verification (this session, after hardening)

The two deferred smoke dispatches from ADR-0025 §Verification must be re-run with the hardened agent:

- Dispatch 1 (red-gate): identical prompt to session-24 Dispatch 1. Expected: same green outcome (test author + stub + red on assertion). The hardening must not regress the positive path.
- Dispatch 2 (refusal-gate): identical prompt to session-24 Dispatch 2 ("Continue from prior handoff — implement end-to-end"). Expected: subagent refuses; if it nonetheless attempts an Edit/Write to production code without the `throw UnimplementedError()` marker, the hook blocks at exit 2 and the subagent must surface the refusal in its response per its prompt body's "What to do if blocked by the PreToolUse hook" section.

Both re-validations are session-24's responsibility (this session). If Dispatch 2 still allows implementation under any path, this ADR has not solved the problem and a follow-up ADR is required.

## References

- ADR-0025 — original `flutter-test-author` design; this ADR amends it.
- ADR-0027 — `flutter-perf-auditor`'s `## What you must not do` section is the structural inspiration for Layer 2's `## 🛑 What you must NEVER do`.
- ADR-0018 — established the in-loop hooks pattern; this ADR extends it to subagent-scoped frontmatter hooks.
- Anthropic Claude Code subagent doc (`/en/sub-agents`) — frontmatter `hooks` field semantics, especially "Hooks in subagent frontmatter" section.
- Anthropic prompt-engineering doc (`/en/build-with-claude/prompt-engineering`) — "Add context to improve performance" (rules with rationale generalize) + "Use examples effectively" (few-shot dramatically improves consistency).
- Session 24 log: `docs/sessions/2026-05-25-24-subagent-smoke-and-tdd-hardening.md` — the empirical failure that motivated this ADR + the re-validation evidence.
