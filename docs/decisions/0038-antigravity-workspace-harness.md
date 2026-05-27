# ADR-0038: Dual-IDE Harness — Google Antigravity Alongside Claude Code

- **Status:** Accepted (pending Trial — see §Trial Validation)
- **Date:** 2026-05-27
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Supersedes:** none
- **Related ADRs:** ADR-0023 (Dart MCP server — first MCP precedent), ADR-0024 (PostUse Riverpod codegen hook — Claude Code hook precedent), ADR-0025 (`flutter-test-author` subagent — Claude Code subagent precedent), ADR-0036 (`spoke-parity-checker` subagent), ADR-0037 (Maestro MCP)

## Context

The repo today has a fully-built **Claude Code harness** in `.claude/` (agents + hooks + skills + settings + MCP servers). This harness mechanically enforces several non-negotiable rules:

- `.claude/hooks/block-env.sh` — prevents Claude Code from editing `.env*`, `*.jks`, signing keys, `google-services.json`
- `.claude/hooks/analyze-changed-dart.sh` — runs `flutter analyze` over edited Dart files at end of turn
- `.claude/hooks/run-riverpod-codegen.sh` (per ADR-0024) — regenerates `.g.dart` after `@riverpod` annotation edits
- `.claude/hooks/check-dto-mirror.sh` — warns when backend TypeBox schema edits lack paired Dart DTO mirror update (per ADR-0013)
- `.claude/hooks/warn-adr-drift.sh` — warns when stack-affecting files were edited without an accompanying ADR
- `.claude/agents/flutter-test-author.md` + `.claude/hooks/block-test-author-impl.sh` (per ADR-0031) — mechanically blocks the test-author from writing production code

These are all **Claude Code-specific**. The hook system doesn't exist in other IDEs.

Eduardo has started using **Google Antigravity** in parallel with Claude Code — an agentic IDE from Google that exposes a similar primitive set (rules, workflows, skills) but with **different mechanics**:

- **No PreToolUse hook equivalent.** Antigravity has no way to mechanically block an edit before it happens. Enforcement is via Rule text (passive guidelines).
- **Rules** = passive markdown files in `.agent/rules/` with activation modes (Always On / Glob-matched / Model Decision)
- **Workflows** = `/`-triggered saved prompts in `.agent/workflows/` with YAML frontmatter
- **Skills** = reusable capabilities in `.agent/skills/<name>/SKILL.md` (mirror of Claude Code subagents)
- **Settings** = manual UI-only (Customizations → Rules → activation mode) — NOT committable from repo

The risk this ADR addresses: if Antigravity sessions don't have an equivalent harness, the operator working through Antigravity lands in a **different operating environment** than the operator working through Claude Code. The mandatory pre-action ritual (CLAUDE.md → ROADMAP → inventory → ADRs), the forbidden-file list, the stack-change-requires-ADR rule, the Spoke canonical hierarchy — all of this is encoded in Claude Code subagents and hooks that don't run in Antigravity.

**Without a parallel harness, dual-IDE adoption causes drift:** Claude Code agent refuses to edit `.env`; Antigravity agent edits it freely. Claude Code dispatches `spoke-parity-checker` before slice 2 brainstorming; Antigravity skips it. Claude Code runs Riverpod codegen automatically; Antigravity doesn't. Same repo, two different effective contracts.

## Options Considered

### Option A — Single-IDE strategy: drop Antigravity, stay Claude Code only

- Pros: Single harness to maintain. Existing hooks + subagents do their job.
- Cons: Eduardo loses an IDE he values (faster iteration cycles for some tasks). Future collaborators who prefer Antigravity get no onboarding scaffold.
- Cost: Operational loss of optionality.

### Option B — Dual-IDE with no parallel harness (current state)

- Pros: Zero new files.
- Cons: Silent drift between IDEs. Same task may produce different outcomes depending on which IDE the operator chose. Forbidden-file rules, ADR-requires-stack-change rule, pre-action ritual — all enforced in Claude Code only.
- Cost: Hidden risk that surfaces only when an Antigravity session does something a Claude Code session would have blocked.

### Option C — Dual-IDE with parallel `.agent/` harness mirroring `.claude/` (this decision)

- Pros: Operator opens repo in either IDE and lands in the same operating environment. Pre-action ritual, forbidden-file list, stack-change ADR rule, Spoke canonical hierarchy, TDD discipline — all reified in `.agent/` for Antigravity to consume. Skills mirror Claude Code subagents (spoke-parity-checker, flutter-perf-auditor, etc.) so reusable capabilities work in both. Workflows replace `/`-commands (`/commit`, `/verify-slice`, `/release-apk`, `/session-end`, `/new-screen`) so muscle memory transfers.
- Cons: Two harnesses to maintain. When Claude Code hooks change (e.g., new file added to block-env.sh), Antigravity rule needs parallel update. Antigravity lacks PreToolUse hook equivalent, so rules are *advisory* — agent compliance is the only enforcement layer, not mechanical guarantee.
- Cost: ~30 min of authoring per major rule/skill change (mirror Claude Code → Antigravity); ~5 min Trial Validation per new operator opening the repo in Antigravity first time (manual UI activation).

## Decision

Adopt **Option C**. Maintain a parallel `.agent/` harness alongside `.claude/`, structurally mirroring `.claude/` capabilities to provide the same operating environment when working through Google Antigravity.

**Structure (per Antigravity canonical paths confirmed via Context7 `alphaperseii3000/google-antigravity-docs` + community references):**

- `.agent/rules/` — 5 passive guidelines:
  - `00-pre-action-ritual.md` (Always On) — pointers to AGENTS.md → CLAUDE.md → ROADMAP-v2 → inventory
  - `01-secrets-and-self-mod.md` (Always On) — forbidden-file list (mirrors `block-env.sh`) + stack-change-requires-ADR + self-modification rule
  - `02-context7-and-mcp.md` (Glob: when adding deps) — Context7 mandatory before installing libraries
  - `03-spoke-canonical.md` (Glob: when touching slices 2/3) — Spoke = canonical funcional per ADR-0035 + dispatch spoke-parity-checker
  - `04-flutter-conventions.md` (Glob: when editing Dart) — Riverpod codegen + DTO mirror duties (mirrors `run-riverpod-codegen.sh` + `check-dto-mirror.sh`)

- `.agent/workflows/` — 5 `/`-triggered saved prompts:
  - `commit.md` — interactive Conventional Commit wizard (mirrors Claude Code `/commit` skill)
  - `new-screen.md` — boilerplate for adding a new slice 2 screen (D1 brainstorm → spec → implement → D4 review)
  - `release-apk.md` — wraps `bash apps/mobile/scripts/build-release-apk.sh` workflow
  - `session-end.md` — opt-in session log per CLAUDE.md §"Session End Protocol"
  - `verify-slice.md` — pre-PR gate per `docs/M2-SLICE-CHECKLIST.md` §Verification

- `.agent/skills/<name>/SKILL.md` — 3 reusable capabilities mirroring Claude Code subagents:
  - `spoke-inspect/SKILL.md` — manual Maestro MCP inspection workflow (per ADR-0037)
  - `perf-audit/SKILL.md` — manual Flutter performance audit workflow (per `flutter-perf-auditor` subagent contract)
  - `brainstorm-slice/SKILL.md` — D1 brainstorming workflow per `superpowers:brainstorming` skill

**Both harnesses honor AGENTS.md → CLAUDE.md as canonical operating manual.** When Antigravity rules and CLAUDE.md conflict, CLAUDE.md wins for this repo.

This decision is policy. Execution lives in the commit set that ships this ADR (`0573a46` cherry-picked into `feat/antigravity-workspace-harness`), scoped to:

- `.agent/` (new directory) — 14 files: 5 rules + 5 workflows + 3 skills + (implicit AGENTS.md edit)
- `AGENTS.md` (drive-by fix: `08-ROADMAP.md` → `08-ROADMAP-v2.md` per 2026-05-26 reset; adds inventory step + per-tool harness section)
- This file (`docs/decisions/0038-antigravity-workspace-harness.md`)

No `apps/` code is touched.

## Consequences

### Positive

- **Operator parity across IDEs.** Eduardo (or any future contracted dev/agent) opens the repo in either Claude Code or Antigravity and lands in the same operating environment. Pre-action ritual, forbidden-file list, stack-change ADR rule — all consistently enforced as advisory in Antigravity and as mechanical in Claude Code.
- **Lower onboarding cost.** New collaborator using Antigravity doesn't need a separate handoff doc — `.agent/rules/00-pre-action-ritual.md` is the entry point and points to canonical sources.
- **Skill portability.** A skill like `spoke-inspect` works in both IDEs (it's mostly Maestro MCP commands), reducing context switching cost for the operator.

### Negative

- **Two harnesses to maintain.** When a Claude Code hook gains a new forbidden file pattern, the equivalent Antigravity rule needs parallel update. Risk of silent drift if maintainer forgets to mirror.
- **Mitigation:** Document the mirroring duty in CLAUDE.md §"When You Disagree With This File" (or new §"Dual-Harness Maintenance"). Make it explicit that `.agent/rules/01-secrets-and-self-mod.md` is the manual mirror of `.claude/hooks/block-env.sh` — both must be updated together.
- **Antigravity rules are advisory, not mechanical.** Antigravity has no PreToolUse hook. Rule text is the only line of defense. A misbehaving agent could ignore the rule. Claude Code hooks would have blocked the action mechanically.
- **Mitigation:** Rule 01 (secrets + self-mod) is written to be as categorical as possible. Antigravity's terminal allowlist/denylist (configured in Settings UI, not in this repo) provides a second layer for commands. Trust + verify operator behavior — if drift surfaces, reevaluate dual-IDE strategy.

### Neutral

- **`.mcp.json` is already shared between both IDEs.** Both Antigravity and Claude Code read `.mcp.json` to discover MCP servers (Dart, Maestro). No new wiring needed for that side.
- **CLAUDE.md remains canonical.** Both harnesses point to it. If a rule conflicts between `.agent/` and CLAUDE.md, CLAUDE.md wins (and the rule must be updated to align).

## Trial Validation

This ADR is marked **Accepted (pending Trial)** because Eduardo confirmed adoption intent but has not yet validated the activation mechanics in Antigravity UI. Required manual steps post-merge:

1. **Open the repo in Antigravity.** Verify `.agent/` directory is recognized (Customizations → Rules / Workflows / Skills should list the files).
2. **Set activation modes manually** per the comment header in each rule file:
   - `00-pre-action-ritual.md` → Always On
   - `01-secrets-and-self-mod.md` → Always On
   - `02-context7-and-mcp.md` → Glob (active when editing `package.json`, `pubspec.yaml`)
   - `03-spoke-canonical.md` → Glob (active when editing files in `apps/mobile/lib/features/routes/` or `apps/mobile/lib/features/stops/`)
   - `04-flutter-conventions.md` → Glob (active when editing `*.dart`)
3. **Verify `/mcp` (or Antigravity equivalent)** lists `dart ✅ connected` and `maestro ✅ connected` per `.mcp.json` — required before `spoke-inspect` or any Dart MCP-dependent skill can be trusted.
4. **Run `/commit` once on a trivial change** to confirm the YAML frontmatter shape is accepted by Antigravity's workflow parser. If it errors, fix the frontmatter format and amend.
5. **Run a non-trivial task** (e.g., open the Editar parada spec from `docs/inventory/dumps/hierarchy_after_coleta.json`) and verify Antigravity respects:
   - Rule 00 (reads CLAUDE.md → ROADMAP-v2 → inventory before suggesting code)
   - Rule 01 (refuses to edit `.env` if asked)
   - Rule 03 (dispatches `spoke-inspect` skill or references inventory §10/§11/§12/§13 when planning a Spoke-aligned screen)

If Trial surfaces any rule that doesn't work as intended (e.g., Glob matcher doesn't fire, or Always On rule is silently ignored), amend this ADR with the failure mode and revised rule. Status moves from "Accepted (pending Trial)" → "Accepted" once Trial passes.

## Implementation Notes

- **Antigravity precedence trap:** Antigravity respects `~/.gemini/GEMINI.md` (machine-global) with HIGHER priority than `AGENTS.md` (repo-local). If a global rule on Eduardo's machine conflicts with this project's CLAUDE.md, the global silently wins. Rule `00-pre-action-ritual.md` includes a verification step for this.
- **Filename convention** per Antigravity canonical paths:
  - Rules: `.agent/rules/<NN>-<topic>.md` with HTML comment header declaring activation mode (UI-driven, but documented for reproducibility)
  - Workflows: `.agent/workflows/<name>.md` with YAML frontmatter (`description`, `auto_execution_mode`)
  - Skills: `.agent/skills/<name>/SKILL.md` (skill name = directory name)
- **AGENTS.md** is the universal entry point read by both Antigravity and Claude Code. CLAUDE.md is referenced from AGENTS.md but is Claude Code's specific manual. This separation lets us add tool-specific notes (e.g., the `.agent/` section in AGENTS.md) without polluting CLAUDE.md.
- **No `.agent/settings.json`.** Antigravity Settings (allowlist/denylist of terminal commands, MCP server activation, rule activation modes) are managed via Antigravity UI per machine, not committed to repo. This is by design from Google — repo-committed settings would lock all operators into the same configuration.

## References

- Antigravity canonical docs: https://antigravity.google/docs/rules-workflows (SPA-rendered, requires JS)
- Context7 mirror: `context7.com/alphaperseii3000/google-antigravity-docs/llms.txt` (used for spec validation)
- Community reference: https://atamel.dev/posts/2025/11-25_customize_antigravity_rules_workflows/
- Workflow frontmatter spec: https://agentpedia.codes/blog/workflows
- Codelab: https://codelabs.developers.google.com/getting-started-google-antigravity
- ADR-0023 — Dart MCP server adoption (precedent for adding an MCP server)
- ADR-0024 — PostUse Riverpod codegen hook (Claude Code hook precedent that Antigravity rule 04 mirrors)
- ADR-0025 — `flutter-test-author` subagent (Claude Code subagent precedent that has no Antigravity skill equivalent yet — TDD discipline is manual in Antigravity per Rule 00 footer)
- ADR-0031 — `flutter-test-author` hardening (3-layer refusal defense — Claude-only enforcement)
- ADR-0035 — Spoke functional clone (referenced by Rule 03)
- ADR-0036 — `spoke-parity-checker` subagent (mirrored as `spoke-inspect` skill in `.agent/skills/`)
- ADR-0037 — Maestro MCP for Spoke inspection (`spoke-inspect` skill depends on this)
</content>
</invoke>