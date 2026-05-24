# Session 22c — M2-AI Phase 4: `flutter-perf-auditor` subagent

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 22c (third sub-session same day — after `22` Phase 2 and `22b` Phase 3)
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 4 — read-only perf auditor subagent
- **Duration**: ~25m
- **Related ADRs**: ADR-0027 (new), ADR-0023 (Dart MCP grounds the auditor's symbol lookups), ADR-0025 (sibling subagent, same project-scope pattern), ADR-0018 (analyze Stop hook feeds §2), ADR-0016 (tile policy informs §6)
- **Related TODO items**: Sprint M2-AI Phase 4

## Goal of the Session

Execute Phase 4 of the M2-AI sprint: a project-scoped read-only subagent that audits mobile-Dart code for performance anti-patterns and produces a categorized punch list (must-fix / should-fix / nit). Differs from `flutter-test-author` (Phase 3) in being strictly read-only — Edit/Write/MultiEdit are removed from the allowlist so the contract is mechanically enforced, not just prompt-enforced.

## What Was Done

- Read SPRINT-MD §Fase 4 (tasks, gate, risks, expected commit).
- Read `.claude/agents/prototype-fidelity-checker.md` as the canonical pattern for a read-only review subagent (Read/Grep/Glob/Bash, no Edit/Write).
- Quick survey of current slice-2 perf surface: `grep -rnE 'ListView\(|GridView\('` (1 hit in `settings_page.dart` — static chips, intentional), `ref.watch` count (17 occurrences across `lib/`), `Isolate.run|compute(` (zero — irrelevant until slice-3 GraphHopper matrix).
- Authored `.claude/agents/flutter-perf-auditor.md`:
  - Frontmatter: `tools` = Read, Grep, Glob, Bash, mcp__dart__resolve_workspace_symbol, mcp__dart__hover, mcp__dart__analyze_files. Explicitly excludes Edit, Write, MultiEdit.
  - Body: 9-item canonical checklist (ListView builder discipline, missing `const`, `ref.watch` granularity, UI-thread heavy work via `Isolate.run`/`compute`, `RepaintBoundary` for high-churn subtrees, map tile caching cross-referenced to ADR-0016, stable keys on reorderable lists, image decode cost, `StatefulWidget` overuse where `ConsumerWidget` would suffice). Each item: anti-pattern, fix, severity guidance, where-to-look hint.
  - Output format: single Markdown report with 4 always-present sections (Must-fix / Should-fix / Nits / Out of scope).
  - Workflow: 6 steps. "What you must not do" section explicitly forbids editing files, running tests, proposing implementation patterns beyond a one-phrase suggestion per item, flagging generated code (`*.g.dart` per ADR-0024), and consulting training memory for "what's fast in Flutter" (the checklist IS the source of truth).
- First inline frontmatter validation failed: YAML scanner choked on a colon inside the description (`"... Read-only. Triggers: user finishes ..."`) — colons in unquoted YAML strings are parsed as mapping separators. Fixed by rephrasing to "Trigger when the user finishes a screen, says...". Re-validated: parses clean.
- Programmatic verification of read-only contract: Python assertion that `Edit`, `Write`, `MultiEdit` do not appear in the `tools` string. Passed. ✅
- `flutter analyze --no-pub` re-run after the agent file landed: "No issues found! (ran in 8.9s)" — confirmed the agent definition (which lives outside `apps/mobile/`) cannot affect Dart analysis.
- Tried no functional smoke dispatch this session — same constraint as Phases 1 and 3: Claude Code builds the agent registry at session boot. Documented and deferred with the two exact dispatch prompts captured in ADR-0027 §Verification.
- Authored `docs/decisions/0027-flutter-perf-auditor-subagent.md` — 1 decision (adopt the read-only subagent), 4 options (manual review only / custom_lint package / read-only subagent / community subagent), consequences (positive/negative/neutral), rollback (3-file diff), verification split into "inline now" + "deferred to session 23".
- Updated `docs/M2-SLICE-CHECKLIST.md` §Verification — new bullet between `flutter test` and `bun typecheck` directing the human to dispatch the auditor on the slice's touched mobile files, resolve must-fix before merge, document deliberately-skipped should-fix in the slice doc.
- Updated `CLAUDE.md`:
  - "Last updated" footer extended to include Phase 4 + ADR-0027.
  - §"Verify Your Work" gained a 6th bullet directing mobile perf review through the auditor.
- Updated `docs/sprints/2026-05-24-m2-ai-harness.md` phase table (Phase 4 → ✅), Fase 4 status block, "Próxima sessão deve" extended to validate both Phase 3 and Phase 4 smoke dispatches post-reload and then move on to Phase 5.
- Updated `TODO.md` Phase 4 checkbox done with the inline validation summary.
- This session log + INDEX entry.

## Decisions Made

1. **Read-only contract enforced by allowlist, not just prompt** (codified in ADR-0027). The omission of `Edit`/`Write`/`MultiEdit` from `tools:` makes "do not edit code" mechanically impossible to violate, not merely strongly discouraged. Mirrors the `prototype-fidelity-checker` and `adr-guardian` pattern.
2. **9-item canonical checklist over generic Flutter perf guidance** — each item is anchored to a slice-2 / slice-3 risk surface and cross-referenced to the ADR that owns the related decision (ADR-0016 for tile cache; ADR-0024 for generated code skip). Generic "what's fast in Flutter" advice is explicitly forbidden in the agent body.
3. **`Bash` is unrestricted in the allowlist**, but the prompt body limits its use to `flutter analyze --no-pub` and `git diff --name-only main...HEAD`. Discipline lives in the prompt; the allowlist is a coarse-grain lock, not a fine-grain ACL. Same trade-off as ADR-0025.
4. **Smoke test deferred, not skipped** — captured as explicit next-session work in SPRINT-MD §"Próxima sessão deve" + ADR-0027 §Verification + this log. Same pattern Phases 1 and 3 used.
5. **Wedged the auditor into `M2-SLICE-CHECKLIST.md` §Verification at the slot between `flutter test` and `bun typecheck`** — keeps mobile-related checks contiguous before crossing into backend territory.

## Open Questions Left

- [ ] None blocking Phase 5. Session 23 should re-open Claude Code, validate Phases 3+4 smoke dispatches per the two ADRs' §Verification sections, then move on to Phase 5 (`mcp_flutter` adopt-or-reject gate).

## Files Changed

**Created**:
- `.claude/agents/flutter-perf-auditor.md`
- `docs/decisions/0027-flutter-perf-auditor-subagent.md`
- `docs/sessions/2026-05-24-22c-phase-4-flutter-perf-auditor.md` (this file)

**Modified**:
- `CLAUDE.md` — "Last updated" footer + §"Verify Your Work" 6th bullet.
- `docs/sprints/2026-05-24-m2-ai-harness.md` — phase table row + Fase 4 status block + "Próxima sessão deve".
- `TODO.md` — Phase 4 checkbox done.
- `docs/M2-SLICE-CHECKLIST.md` — §Verification gained the auditor bullet.
- `docs/sessions/0001-INDEX.md` — entry added at top.

## Cross-References

- ADR-0027 (new) — full decision rationale and 9-item checklist provenance.
- ADR-0023 — Dart MCP backs the auditor's symbol-lookup tools (subset of what `flutter-test-author` uses).
- ADR-0025 — `flutter-test-author` (sibling subagent, same scope pattern but writes/edits; auditor is its read-only mirror image).
- ADR-0018 — in-loop hooks. The auditor's §2 cross-references `analyze-changed-dart.sh`'s output but is itself triggered on demand at slice close, not per turn.
- ADR-0024 — Riverpod codegen hook. The auditor's "do not flag generated code" rule explicitly names this ADR.
- ADR-0016 — `flutter_map` + OSM tile policy. The §6 check defers to this ADR rather than blanket-flagging.
- SPRINT-MD §Fase 4 — task list this session executed against.
- SPRINT-MD §Fase 5 — next phase (gate-of-decision on `mcp_flutter`), gated on the deferred smoke tests passing.

## What did NOT happen, and why

- **Subagent dispatch for the bad-screen and clean-screen smoke tests.** Tried no inline dispatch (the Phase 3 attempt already proved Claude Code's agent registry doesn't hot-load). Two exact dispatch prompts are captured in ADR-0027 §Verification for session 23 to run after reload.
- **Editing any production Dart file.** The auditor is read-only; this session's work is harness-only. Slice-2 code is untouched.

## Practical impact (plain language)

Adicionei um segundo "ajudante" no harness, dessa vez focado em **performance** do app. A próxima sessão, depois de eu reabrir o Claude Code, ele aparece junto do "ajudante de testes" da Fase 3.

O que ele faz: lê o código de uma tela e devolve uma lista de problemas de desempenho separada em três níveis — "tem que arrumar antes do merge", "vale arrumar mas não trava", e "detalhe". Cobre as 9 coisas que mais quebram performance em apps Flutter (lista que renderiza tudo de uma vez em vez de só o que aparece na tela, falta de `const`, leitura de provider amplo demais, parsing pesado bloqueando a tela, mapa que re-baixa as tiles toda vez, etc.).

Diferença do "ajudante de testes": esse aqui é **read-only por contrato** — eu literalmente removi as ferramentas de edição da lista permitida dele. Mesmo se eu pedir "edita esse arquivo", ele não consegue. É só relatório.

Já adicionei como passo obrigatório no checklist de fechamento de slice (`M2-SLICE-CHECKLIST.md`). Quando você for fechar uma slice, agora a sequência é: `flutter analyze` → `flutter test` → **dispatch do auditor** → resto. Os must-fix do auditor precisam ser resolvidos antes do PR; os should-fix podem ser pulados se você documentar a razão.

O que ficou pendente: igual nas Fases 1 e 3, o smoke test funcional (testar o auditor numa tela ruim plantada + numa tela limpa pra confirmar zero falsos positivos) só roda depois do reload do Claude Code. Os dois prompts exatos estão no ADR-0027.
