# Spec — M2-AI Harness Upgrade

> **Date:** 2026-05-24
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans`
> **Branch:** `feat/m2-ai-harness` (off `feat/m2-slice-2-telas-core` at `7808911`)
> **Source of truth:** `SPRINT-M2-AI-HARNESS.md` (this sprint's canonical playbook in the repo root). This spec elaborates Phases 0–7 of that document; if the two disagree, the SPRINT-MD wins and the contradiction is a bug to fix in the same PR.

> **NOTE:** This spec is **orthogonal to M2 slice 2**. It does not deliver product surface — it upgrades the AI development harness (subagents, hooks, MCP servers) so that slice 2 (Telas Core) and every subsequent slice ship faster and with fewer hallucinated APIs. Slice 2 work continues unblocked on its own branch.

---

## Context

The Roteirizador Pro harness is already strong (CLAUDE.md, ADRs 0001–0020, slice checklist, three Stop-hooks for in-loop validation, spec-driven workflow via `superpowers:`, lefthook + commitlint + Conventional Commits, two subagents `prototype-fidelity-checker` and `adr-guardian`). But a research pass on 2026-05-24 (WebSearch + Context7 over `/websites/flutter_dev` + direct fetches of `docs.flutter.dev/ai/*`) surfaced four canonical pieces from the Flutter team itself that we don't yet use:

1. **Dart & Flutter MCP server (official)** — exposes the Dart analyzer, symbol resolver, pub.dev search, test runner, formatter, and **agentic hot reload** to any MCP-compatible AI client. Requires Dart ≥ 3.9. This is the single biggest anti-hallucination win available — instead of "remembering" Flutter/Riverpod/flutter_map APIs, the agent queries the local analyzer.
2. **AI Rules for Flutter** (`docs.flutter.dev/ai/ai-rules`, updated 2026-01-05) — canonical guidance on widget composition, `ListView.builder`, `Isolate.run`, null-safety pitfalls. We already encode some of this in CLAUDE.md; the rest is worth cherry-picking.
3. **Agent Skills doc** (`docs.flutter.dev/ai/agent-skills`) — cements the vocabulary we already use (Rules vs Skills vs MCP vs Subagents).
4. **`mcp_flutter` (community, Arenukvern)** — closed-loop visual + semantic snapshot of a running Flutter app. Evaluated in Phase 5 of this sprint.

The gap this spec closes: a structured, ADR-backed adoption path for items 1–4 plus two specialized subagents (`flutter-test-author`, `flutter-perf-auditor`) and one new PostToolUse hook (`riverpod-codegen-runner`). The slice 2 (Telas Core) work that depends on Riverpod codegen and `flutter_map` will be the first beneficiary.

What stays out: any change to product code under `apps/mobile/lib/features/` (sprint is harness-only), any change to the spec-driven workflow itself (`superpowers:` stays as-is — competing systems like `flow-next` and `cc-sdd` were evaluated and explicitly rejected in the research pass).

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Adopt the official Dart & Flutter MCP server now or wait until post-slice-2? | **Adopt now (Phase 1 of sprint)** | Highest ROI of any harness change. Cuts hallucination cost on every subsequent fase. Reversible (remove from `.claude/settings.json`). Slice 2's `flutter_map` work specifically benefits — agent will resolve real `MapController` API instead of guessing. |
| Q2 | Implement Riverpod codegen as a **Stop** hook (end of turn, like the existing three) or a **PostToolUse** hook (right after the edit)? | **PostToolUse with `Edit\|Write` matcher** | PostToolUse runs sooner — `.g.dart` files exist before the next agent action that might depend on them. Stop hooks would leave a window where Claude reads stale generated code. Trade-off accepted: slightly more invocations, mitigated by the in-script grep filter for `@riverpod` / `part '.g.dart'`. |
| Q3 | Mock library for `flutter-test-author` subagent: `mocktail` (no codegen) or `mockito @GenerateMocks` (codegen)? | **Defer to Phase 3** — inspect `apps/mobile/pubspec.yaml` at execution time. If neither is present, default to **`mocktail`** to avoid yet another `build_runner` invocation. The chosen library is locked in ADR-0023. | The repo may already have one; honor existing convention. If green-field, `mocktail` minimizes codegen load (we already have Riverpod codegen + planned `riverpod-codegen-runner` hook). |
| Q4 | `mcp_flutter` (visual snapshot, community plugin) — adopt or reject? | **Decision deferred to Phase 5 of sprint** (gate-of-decision sub-fase 5.0). Both outcomes produce ADR-0025. | Real decision data won't exist until slice 2 surfaces whether `prototype-fidelity-checker` + manual screenshots are sufficient. Premature commitment risks instrumenting `main.dart` for no benefit. |
| Q5 | Should the sprint block on slice 2, or run in parallel? | **Run in parallel on a separate branch (`feat/m2-ai-harness`)** | Slice 2 is the actual M2 deliverable; this sprint is leverage. Branch isolation lets us merge harness improvements without coupling to slice 2's release tag. |
| Q6 | Filename convention for spec/plan: `NNNN-<slug>` (numeric, as SPRINT-MD initially drafted) or `YYYY-MM-DD-<slug>` (date, as project convention)? | **`YYYY-MM-DD-<slug>` — match existing project convention** | Inspection of `docs/superpowers/specs/` and `plans/` shows all four prior artifacts use the date convention. Consistency beats the numeric scheme I proposed. SPRINT-MD will be amended in Phase 0 to match. |

## Goals (acceptance for this sprint)

A fresh Claude Code session opened on `feat/m2-ai-harness` after sprint completion can:

1. Run `/mcp` and observe `dart` MCP server connected ✅.
2. Ask "resolve symbol `MapController` from `flutter_map`" and receive real method list with source path pointing to the local `.pub-cache/` (not training data).
3. Edit any file containing `@riverpod` under `apps/mobile/lib/` and observe the `riverpod-codegen-runner` hook regenerate matching `.g.dart` files within ~120 s, with a single log line.
4. Invoke the `flutter-test-author` subagent against a new provider and observe it write a failing test **before** any `lib/` edit.
5. Invoke the `flutter-perf-auditor` subagent against any slice-2 screen and observe a punch-list of `must-fix` / `should-fix` / `nit` items (or "no issues found" if clean).
6. Read ADR-0025 and find a clear adopt-or-reject verdict on `mcp_flutter` with rationale.
7. (If Phase 6 ran) `flutter test` against a 1-pixel-changed widget under golden coverage fails with a clear pixel-diff message; reverting passes.
8. Read `CLAUDE.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, and `docs/10-CHANGELOG.md` and find the sprint reflected coherently — no doc drift.

### Non-goals (explicit, to keep scope tight)

- No new product feature for end users (slice 2 owns that, on its own branch).
- No change to the `superpowers:` spec-driven workflow itself (templates, brainstorming, writing-plans — stay as-is; `flow-next` / `cc-sdd` rejected on research pass).
- No edits to `apps/mobile/lib/features/` (sprint touches only `.claude/`, `docs/`, `apps/mobile/test/` for the golden baseline, and `apps/mobile/pubspec.yaml` for `golden_toolkit` dev-dep).
- No change to existing ADRs 0001–0020 (additive only).
- No new MCP server beyond `dart_mcp_server` (and conditionally `mcp_flutter` if Phase 5 adopts).

## Architecture

### Harness file layout (NEW + MODIFIED)

```
.claude/
├── settings.json                              [MODIFY] — add mcpServers.dart, hooks.PostToolUse
├── hooks/
│   └── run-riverpod-codegen.sh                [NEW]    — Phase 2
└── agents/
    ├── flutter-test-author.md                 [NEW]    — Phase 3
    └── flutter-perf-auditor.md                [NEW]    — Phase 4

docs/
├── decisions/
│   ├── 0021-dart-flutter-mcp-server.md        [NEW]    — Phase 1
│   ├── 0022-riverpod-codegen-hook.md          [NEW]    — Phase 2
│   ├── 0023-flutter-test-author-subagent.md   [NEW]    — Phase 3
│   ├── 0024-flutter-perf-auditor-subagent.md  [NEW]    — Phase 4
│   ├── 0025-mcp-flutter-decision.md           [NEW]    — Phase 5 (adopt OR reject)
│   └── 0026-golden-toolkit-adoption.md        [NEW]    — Phase 6 (if executed)
├── superpowers/
│   ├── specs/2026-05-24-ai-harness-upgrade-design.md  [NEW] — THIS FILE
│   └── plans/2026-05-24-ai-harness-upgrade.md         [NEW] — companion plan
├── sessions/
│   ├── 2026-05-24-19-ai-harness-kickoff.md    [NEW]    — Phase 0
│   ├── 2026-05-XX-NN-…                        [NEW]    — one per executed Phase 1..6
│   ├── 2026-05-XX-NN-ai-harness-complete.md   [NEW]    — Phase 7 retro
│   └── 0001-INDEX.md                          [MODIFY] — append all new entries
├── 02-ARCHITECTURE.md                         [MODIFY] — Phase 7 (Dart MCP topology note)
├── 03-CONVENTIONS.md                          [MODIFY] — Phase 7 (TDD via subagent)
├── 10-CHANGELOG.md                            [MODIFY] — Phase 7 (sprint entry)
└── M2-SLICE-CHECKLIST.md                      [MODIFY] — Phase 4 (add perf-auditor); Phase 6 (add goldens step)

apps/mobile/
├── pubspec.yaml                               [MODIFY] — Phase 6 (golden_toolkit dev-dep)
├── test/
│   ├── flutter_test_config.dart               [NEW]    — Phase 6 (loadAppFonts)
│   └── features/.../*_golden_test.dart        [NEW]    — Phase 6 (one baseline)
└── test/.../*.png                             [NEW]    — Phase 6 (baseline image)

CLAUDE.md                                      [MODIFY] — Phases 1, 2, 3, 7
SPRINT-M2-AI-HARNESS.md                        [MODIFY] — Phase 0 (filename convention fix); Phase 7 (status final)
TODO.md                                        [MODIFY] — Phase 0 (sprint tracking entry); Phase 7 (mark done)
```

### Backend / contract evolution

**None.** This sprint does not touch `apps/backend/`, Prisma, TypeBox schemas, or any DTO mirror. ADR-0013 contract is irrelevant here.

### Architecture principles

1. **Additive over destructive.** Every artifact this sprint introduces is reversible (remove file, revert ADR). No existing harness behavior is removed.
2. **One phase = one PR-eligible commit set.** Phases 0–7 each end in a logical commit; the sprint can pause between any two phases without leaving the harness inconsistent.
3. **ADR per decision, before commit.** No phase commits without its ADR (except Phase 0 and Phase 7, which are pure scaffolding/docs).
4. **MCP-first after Phase 1.** Once the Dart MCP server is up, prefer `resolve_symbol` over `Read`ing pub-cache files when investigating Flutter/Dart APIs. Validates the Phase 1 investment.
5. **No coupling to slice 2 product code.** Sprint branch never touches `apps/mobile/lib/features/` (except Phase 6 reading from one stable screen for the golden baseline).

## Data flow

### Phase 1 — agent resolves a Dart symbol via MCP

1. Agent asks: "what methods does `MapController` from `flutter_map` expose?"
2. Claude routes the query to the `dart` MCP server (visible in `/mcp` list).
3. `dart_mcp_server` invokes the local Dart analyzer against the project's `.pub-cache/`.
4. Result returns: method list + source path (e.g. `~/.pub-cache/hosted/pub.dev/flutter_map-X.Y.Z/lib/src/map/controller.dart`).
5. Agent uses the **real** API in its edit, no hallucination, no Context7 round-trip needed.

### Phase 2 — riverpod codegen hook fires

1. Agent calls `Edit` on `apps/mobile/lib/features/stops/state/stops_controller.dart` (contains `@riverpod`).
2. Claude Code triggers `PostToolUse` matchers; `Edit|Write` matches.
3. Hook script `.claude/hooks/run-riverpod-codegen.sh` runs.
4. Script greps the edited file for `@riverpod` or `part '*.g.dart'` — matches.
5. Script runs `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs` (timeout 120s).
6. Output: `[codegen] regenerated N .g.dart files` (or `[codegen] no @riverpod changes detected` for non-matching edits).
7. Next agent turn reads fresh `.g.dart` if needed.

### Phase 3 — TDD flow via `flutter-test-author`

1. Agent invokes `Task(subagent_type=flutter-test-author, prompt="add test coverage for new XController")`.
2. Subagent reads relevant files, writes a **red** test in `apps/mobile/test/...`.
3. Subagent runs `flutter test path/to/new_test.dart` — confirms red.
4. Subagent returns to main agent: "test is red, ready for implementation".
5. Main agent (or human) implements the controller; subagent re-runs test; green.

## Sub-slice plan

| Phase | Hours | Scope | Verification |
|---|---|---|---|
| 0 — Pre-flight | 0.5 | Branch + spec + plan + TODO + session log | All four files exist; ADR drift hook silent (no ADR-triggering files touched) |
| 1 — Dart MCP server | 1–2 | Install + settings.json + smoke test + ADR-0021 + CLAUDE.md update | `/mcp` lists `dart` ✅; symbol-resolve smoke test returns real source path |
| 2 — Riverpod codegen hook | 1 | `.claude/hooks/run-riverpod-codegen.sh` + settings.json + ADR-0022 + CLAUDE.md | Edit `@riverpod` file → `.g.dart` regenerated; edit non-`@riverpod` Dart → no codegen |
| 3 — `flutter-test-author` subagent | 2 | `.claude/agents/flutter-test-author.md` + ADR-0023 (with mock-lib decision) + CLAUDE.md | TDD smoke test: red → impl → green; subagent refuses `lib/` edit without red test |
| 4 — `flutter-perf-auditor` subagent | 1.5 | `.claude/agents/flutter-perf-auditor.md` + ADR-0024 + M2-SLICE-CHECKLIST update | Planted-bad-tela smoke test flags 3 issues; clean tela returns no findings |
| 5 — `mcp_flutter` decision | 0.5–2 | ADR-0025 (adopt OR reject); if adopt: pubspec + main.dart guard + settings.json + smoke | Adopt path: snapshot works in debug, release build clean. Reject path: ADR rationale clear. |
| 6 — Golden tests | 2 | `golden_toolkit` dev-dep + `flutter_test_config.dart` + 1 baseline + ADR-0026 + checklist update | 1-pixel change fails; revert passes; baseline `.png` committed |
| 7 — Docs consolidate + retro | 0.75 | CLAUDE.md, 02/03/10 docs, sessions index, retro session log, SPRINT-MD final status | All doc cross-references coherent; CHANGELOG entry dated |

**Estimate:** 9.25–11.75 working hours. Calendar pace at human's discretion — sprint does not block slice 2.

## Libraries

| Purpose | Package | Version target | Cost | Context7 ID (or rationale) |
|---|---|---|---|---|
| Dart analyzer + symbol resolver + agentic hot reload (MCP server) | `dart_mcp_server` (Dart global) | latest as of 2026-05-24, pinned in ADR-0021 | 0 (local process) | Official Flutter team — `docs.flutter.dev/ai/mcp-server` (fetched 2026-05-24). Context7 query not applicable for CLI tooling distributed via `dart pub global`. |
| Visual + semantic snapshot of running Flutter app (Phase 5, conditional) | `mcp_flutter` (community, Arenukvern) | latest, pinned in ADR-0025 if adopted | 0 (local process) | Community — `github.com/Arenukvern/mcp_flutter`. Context7 ID to be resolved at Phase 5 execution if adopted. |
| Golden tests for widget regression (Phase 6) | `golden_toolkit` | resolved at install time, recorded in ADR-0026 | 0 (dev-only) | Pub.dev — query Context7 at Phase 6 for current version + breaking-changes window. |
| Mock library for `flutter-test-author` (Phase 3, decision pending) | `mocktail` OR `mockito` | TBD in Phase 3 | 0 (dev-only) | Both Flutter-team-friendly; ADR-0023 will record the choice + Context7 query timestamp. |

No new runtime dependency. No backend dependency. Cost ceiling per `docs/M2-COST-MODEL.md` is unaffected.

## ADRs filed during this sprint

- **ADR-0021** — Adopt official Dart & Flutter MCP server. Filed in Phase 1.
- **ADR-0022** — PostToolUse hook for Riverpod codegen. Filed in Phase 2.
- **ADR-0023** — `flutter-test-author` subagent + mock-library choice. Filed in Phase 3.
- **ADR-0024** — `flutter-perf-auditor` subagent. Filed in Phase 4.
- **ADR-0025** — `mcp_flutter` adoption decision (adopt OR reject). Filed in Phase 5.
- **ADR-0026** — `golden_toolkit` adoption. Filed in Phase 6 (if Phase 6 executes).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Dart MCP server version churns rapidly (early-stage tooling)** | Pin exact version in ADR-0021; document `dart pub global activate dart_mcp_server` as the re-activation step on bump. |
| **`riverpod-codegen-runner` hook runs `build_runner` too often, slowing turn time** | Grep filter for `@riverpod` / `part '*.g.dart'` before invoking; timeout 120s; one invocation per turn (PostToolUse aggregates). |
| **`flutter-test-author` subagent writes tests using imagined APIs** | Mitigated by Phase 1 (Dart MCP up first); subagent description explicitly instructs MCP-first symbol resolution. |
| **`flutter-perf-auditor` produces false positives that erode trust** | Punch-list categorized by severity (must / should / nit); subagent has read-only tools (cannot "fix" speculatively). |
| **`mcp_flutter` instrumentation leaks to release APK** | `kDebugMode` guard in `main.dart` + manual `flutter build apk --release` verification in Phase 5a smoke. |
| **Golden tests churn baselines on every CI run (font rendering across OS)** | Phase 6 starts with **one** baseline only; `loadAppFonts()` in test config; explicit ADR-0026 note on OS-divergence risk. |
| **Sprint scope creep — temptation to refactor adjacent CLAUDE.md sections** | Karpathy §3 (Surgical Changes) enforced via Phase-bounded ADRs; any "while I'm here" idea goes to TODO.md, not into a sprint commit. |
| **Filename convention drift (numeric vs date)** | Already caught and locked in Q6; SPRINT-MD amended in Phase 0. |

## Accessibility (Karpathy 3 minimum — N/A for harness sprint)

This sprint ships no UI. Accessibility section is **explicitly waived** with this one-line note. The downstream consumers (slice 2+ product code) remain subject to the universal accessibility minimum in their own specs.

## Test strategy

| Layer | Tool | What it covers in this sprint |
|---|---|---|
| Hook script (Phase 2) | Manual smoke (run hook, observe `.g.dart` regeneration) | Trigger fires only on relevant edits; no codegen on non-matching edits |
| Subagent behavior (Phase 3) | Manual smoke (TDD round-trip on a trivial new provider) | Red-first discipline; refusal to edit `lib/` without red test |
| Subagent behavior (Phase 4) | Manual smoke (planted bad tela + clean tela) | Detects 3 planted issues; no false positives on clean tela |
| MCP server (Phase 1, 5) | Manual smoke (`/mcp` + symbol resolve) | Server connected; queries return real source paths |
| Golden tests (Phase 6) | `flutter test` (canonical) | 1-pixel change fails; revert passes |
| Doc coherence (Phase 7) | `docs-lint` skill if available, else manual grep | No dangling cross-references; `Last updated` bumped |

**Tech debt explicit (added to `TODO.md` in the kickoff commit):**

- *2026-05-24:* Phase 5 `mcp_flutter` decision deferred until execution time; outcome (adopt or reject) determines whether ADR-0025 ships an installation or a rejection rationale.
- *2026-05-24:* Phase 6 starts with **one** golden baseline only; expanding to all slice-2 screens is post-sprint work and lives outside this spec.

## Verification gates (per `M2-SLICE-CHECKLIST.md` + sprint-specific)

This sprint does not ship a slice in the M2 sense (no APK, no E2E golden path on a real device, no backend smoke). The relevant gates are:

- [ ] `flutter analyze` clean in `apps/mobile/` after every phase that touches `apps/mobile/`.
- [ ] `flutter test` clean after Phase 6 (or unchanged after Phases 0–5 since no code is edited).
- [ ] `bun run typecheck` clean — unchanged, but verify before final commit (no backend touched, but sanity check).
- [ ] `apps/landing/` lint clean — unchanged (landing untouched).
- [ ] `adr-guardian` subagent reports clean against the PR diff (one ADR per phase, no orphan stack-affecting files).
- [ ] `prototype-fidelity-checker` not applicable (no UI changes).
- [ ] In-loop hooks silent on Phases 0, 1, 3, 4, 5, 7 (no Dart edits); active on Phase 2 (testing the new hook) and Phase 6 (golden test files).
- [ ] Each phase has its companion ADR committed in the **same** commit as the implementation.
- [ ] `CLAUDE.md` `Last updated` bumped in any phase that edits it.
- [ ] Final retrospective session log committed in Phase 7.
- [ ] `docs/sessions/0001-INDEX.md` appended per session.

## References

- `SPRINT-M2-AI-HARNESS.md` — sprint canonical playbook (created 2026-05-24, repo root).
- `CLAUDE.md` — operating manual; sections "Stack — Locked Versions", "Context7 Mandatory", "In-Loop Auto-Validation", "Verify Your Work".
- `docs/08-ROADMAP.md` — M2 canonical sequence (this sprint is orthogonal; does not appear as a slice).
- `docs/M2-SLICE-CHECKLIST.md` — gate definitions inherited where applicable.
- `docs/M2-COST-MODEL.md` — cost ceiling (unaffected by this sprint; all new tooling local + dev-only).
- ADR-0011 — Bun-as-package-manager (relevant to Dart MCP install since Bun is unrelated; noting that Dart tooling stays in `dart pub`).
- ADR-0012 — Lefthook + Conventional Commits (this sprint's commits must conform).
- ADR-0013 — Schema source of truth (untouched; sprint doesn't change schemas).
- ADR-0018 — In-loop auto-validation hooks (this sprint adds a 4th hook; ADR-0022 extends the family).
- ADR-0019 — Spec-driven workflow via `superpowers:` (this spec follows the canonical pattern).
- `docs/superpowers/specs/0000-template.md` — template followed by this spec.
- `docs/superpowers/plans/0000-template.md` — template for the companion plan.
- **Official Flutter docs** (fetched via WebSearch + Context7 `/websites/flutter_dev` on 2026-05-24):
  - `docs.flutter.dev/ai/ai-rules` (updated 2026-01-05)
  - `docs.flutter.dev/ai/mcp-server`
  - `docs.flutter.dev/ai/agent-skills`
  - `docs.flutter.dev/ai/coding-assistants`
  - `docs.flutter.dev/ai/create-with-ai`
- **Community references** (cherry-pick inspiration, not copy):
  - `github.com/cleydson/flutter-claude-code`
  - `github.com/evanca/flutter-ai-rules`
  - `github.com/VoltAgent/awesome-claude-code-subagents`
  - `github.com/affaan-m/everything-claude-code` (skill `flutter-dart-code-review`)
  - `github.com/Arenukvern/mcp_flutter` (Phase 5 candidate)
- **Anthropic canonical docs**:
  - `code.claude.com/docs/en/best-practices`
  - `code.claude.com/docs/en/sub-agents`
  - `code.claude.com/docs/en/skills`
  - `code.claude.com/docs/en/hooks-guide`
- **Rejected after evaluation** (kept here for traceability):
  - `github.com/gmickel/flow-next` — overlaps with our `superpowers:` SDD; no replacement value.
  - `github.com/gotalab/cc-sdd` — same reason.
