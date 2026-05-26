# Session 22b — M2-AI Phase 3: `flutter-test-author` subagent + mocktail

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 22b (second sub-session same day, after Phase 2 closed in `22`)
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 3 — TDD-first subagent + mock library decision
- **Duration**: ~30m
- **Related ADRs**: ADR-0025 (new — flutter-test-author + mocktail), ADR-0026 (new — written this session as housekeeping after `adr-guardian` flagged the uncovered `GH_DATA_DIR` change from commit `bff1b6c`; planned slots shifted: perf 0026→0027, mcp_flutter 0027→0028, golden 0028→0029), ADR-0023 (Dart MCP grounds the agent's symbol lookups), ADR-0024 (codegen hook keeps `.g.dart` fresh for the tests this agent writes)
- **Related TODO items**: Sprint M2-AI Phase 3

## Goal of the Session

Execute Phase 3 of the M2-AI Harness sprint: a project-scoped subagent that enforces test-first discipline for mobile work by writing the failing test first, creating a `throw UnimplementedError()` stub so the test fails on the assertion (not on import), and refusing to author the production logic itself. Pair this with a mock-library decision so the subagent has a concrete tool to recommend when fakes alone are awkward.

## What Was Done

- Read SPRINT-MD §Fase 3 (decision pending, gates, risks, expected commit message).
- Resolved Q3 from the spec (mock library) by inspection:
  - `apps/mobile/pubspec.yaml` has neither `mocktail` nor `mockito` in dev_dependencies.
  - `apps/mobile/test/**/*` greps for `import 'package:mocktail` and `import 'package:mockito` both return zero — all 53 pre-existing tests use manual fakes under `test/<feature>/_helpers/`.
  - Ran `mcp__dart__pub_dev_search "mocktail"` → mocktail 1.0.5, pub points 160/160, 1229 likes, 2.5M downloads, publisher `felangel.dev` (Felix Angelov, author of bloc). MIT.
  - Decision: `mocktail ^1.0.5` — no codegen, complements the manual-fake culture by being reached for only when stubbing dynamism is needed.
- Added `mocktail: ^1.0.5` to `apps/mobile/pubspec.yaml` dev_dependencies with a clarifying comment.
- Ran `flutter pub get` → resolved cleanly (`pubspec.lock` shows `mocktail 1.0.5`, SHA pinned).
- Read `.claude/agents/adr-guardian.md` and the head of `prototype-fidelity-checker.md` to lock the project's subagent frontmatter conventions (`name`, `description`, `tools`, `model`).
- Authored `.claude/agents/flutter-test-author.md`:
  - Frontmatter: `tools` = `Read, Grep, Glob, Edit, Write, Bash` + 5 Dart MCP tools (`resolve_workspace_symbol`, `hover`, `signature_help`, `analyze_files`, `run_tests`). Model `sonnet`.
  - Body: 5-step Discipline (read spec → write failing test → confirm red for right reason → hand off summary → refuse implementation), 3 test categories (provider with `ProviderContainer` + `overrideWithValue`, widget with `ProviderScope`, repo/service), criteria for reaching for mocktail vs manual fake, anti-patterns list, verification gate before declaring red.
- Tried to dispatch the subagent for the functional smoke test (TDD on a trivial `CounterController` spec) — Claude Code returned `Agent type 'flutter-test-author' not found`. Same constraint as ADR-0023's MCP servers: agent registry is built at session start; the session that authors the agent file cannot dispatch to it inline. Documented and deferred.
- Ran inline validations:
  - YAML frontmatter parses cleanly (Python `yaml.safe_load`) — name, tools, model, description all extracted as expected. ✅
  - Sanity test for mocktail itself: created `test/_mocktail_sanity_test.dart` with `MockFoo extends Mock implements Foo`, `when(() => foo.bar()).thenAnswer(...)`, `verify(...).called(1)` — passed. Removed after. ✅
  - Full suite: `flutter test` 164/164 green; `flutter analyze --no-pub` clean. ✅ (no regression from pubspec change)
- Authored `docs/decisions/0025-flutter-test-author-subagent.md` — 2 decisions (mocktail + subagent), 4 options considered for the subagent, consequences (positive/negative/neutral), rollback, verification split into "inline now" + "deferred to session 23".
- Updated `CLAUDE.md`:
  - "Last updated" footer extended to include Phase 3 + ADR-0025.
  - §"Verify Your Work" gained a fifth bullet explicitly directing mobile TDD through `flutter-test-author`, with the mocktail decision called out.
- Updated `docs/sprints/2026-05-24-m2-ai-harness.md` phase table (Phase 3 → ✅) and Fase 3 status block (with the deferred-smoke explanation).
- Updated `TODO.md` Phase 3 checkbox done with the inline validation summary.
- This session log.

## Decisions Made

1. **Mock library = `mocktail ^1.0.5`** (codified in ADR-0025). Rejected mockito (extra `build_runner` consumer, three-step `@GenerateMocks` workflow). Rejected "manual fakes only" (two real slice-2 backlog cases need call counting / per-test exception throwing that fakes don't express cleanly). Default remains manual fakes; mocktail is the escape hatch.
2. **Subagent dedicated to writing the failing test, refusing to implement** (Option C in the ADR). Rejected Option A (rely on main agent — empirically biased), Option B (subagent that does test + impl — same bias), Option D (off-the-shelf community subagents — wrong stack assumptions).
3. **No glob restriction on Bash in the tools allowlist.** Discipline lives in the prompt body, not shell globs. Restrictions like `Bash(flutter test:*)` would block legitimate `flutter pub get`, `dart format`, `chmod` during smoke setup.
4. **Smoke test deferred, not skipped.** Captured as explicit next-session work item in SPRINT-MD §Fase 3 + ADR-0025 §Verification + this log. Same pattern Phase 1 used for the `/mcp` listing verification.
5. **Close `adr-guardian` BLOCKING finding by filing ADR-0026 in this same commit**, rather than deferring to a separate "housekeeping" PR. Reasoning: a single PR that closes the gap is cleaner than two PRs (one that creates the gap retroactively, one that closes it); and the sprint's planned ADR numbers shift +1 anyway (now 0027/0028/0029 for perf/mcp_flutter/golden — already swept across SPRINT-MD, plan, spec, TODO, session-19).

## Open Questions Left

- [ ] None blocking Phase 4. Session 23 should re-open Claude Code, run `/agents` (or attempt a dispatch), confirm `flutter-test-author` appears, then run the two smoke dispatches called out in ADR-0025 §Verification before starting Phase 4 (`flutter-perf-auditor`).

## Files Changed

**Created**:
- `.claude/agents/flutter-test-author.md`
- `docs/decisions/0025-flutter-test-author-subagent.md`
- `docs/decisions/0026-graphhopper-data-dir-env-override.md` — closes `adr-guardian` BLOCKING finding (commit `bff1b6c` changed `infra/graphhopper/extract-sp.sh` adding `GH_DATA_DIR` env override; per CLAUDE.md "Any change requires a new ADR" infra changes need an ADR; the session-21 commit body documented the rationale but didn't file the ADR. This session closes the gap.)
- `docs/sessions/2026-05-24-22b-phase-3-flutter-test-author.md` (this file)

**Modified**:
- `apps/mobile/pubspec.yaml` — `mocktail: ^1.0.5` under `dev_dependencies` with a clarifying comment.
- `apps/mobile/pubspec.lock` — auto, from `flutter pub get`.
- `CLAUDE.md` — "Last updated" footer + §"Verify Your Work" extension.
- `docs/sprints/2026-05-24-m2-ai-harness.md` — phase table row + Fase 3 status block.
- `TODO.md` — Phase 3 checkbox done.
- `docs/sessions/0001-INDEX.md` — entry added at top.

## Cross-References

- ADR-0025 (new) — full decision rationale.
- ADR-0023 — Dart MCP. The subagent's `mcp__dart__*` tool allowlist depends on the MCP server being registered + connected.
- ADR-0024 — Riverpod codegen hook. The subagent's provider-test category assumes the `.g.dart` files exist; the hook keeps them fresh as the implementer adds `@riverpod` annotations after the test goes red.
- ADR-0018 — In-loop hooks. The subagent's `analyze_files` MCP tool calls flutter analyze inline; the Stop hook still runs at turn end for cross-validation.
- ADR-0015 — locked stack. The subagent targets Riverpod 3 codegen specifically, not Bloc / GetX / vanilla setState.
- SPRINT-MD §Fase 3 — task list this session executed against.
- SPRINT-MD §Fase 4 — next phase (`flutter-perf-auditor` subagent), gated on Phase 3's deferred smoke test passing in session 23.

## What did NOT happen, and why

- **Subagent dispatch for the TDD smoke test.** Tried inline; Claude Code's agent registry doesn't pick up newly-authored agent files within the same session. This is the same constraint that gated Phase 1's `/mcp` verification — session start builds the registry, runtime additions are not hot-loaded. Deferred to session 23 with the exact two prompts captured in ADR-0025 §Verification.

## Practical impact (plain language)

Acabei de adicionar um "ajudante de testes" no harness. Da próxima vez que eu pedir pra implementar uma feature nova no app, esse ajudante pode ser chamado primeiro: ele lê o que a feature precisa fazer, escreve o teste que falha, e só depois eu (ou outro agente) escrevo o código pra fazer o teste passar. Isso impede o vício típico de "escrever teste depois que o código já existe" — que sempre acaba testando o que o código faz, não o que ele deveria fazer.

Junto, instalei o `mocktail`, uma bibliotequinha pra quando o teste precisa fingir que um serviço externo respondeu de uma jeito específico (ex: "fingir que a API caiu pra ver se o app trata o erro direito"). Antes a gente fazia tudo manualmente; agora a gente pode usar mocktail quando manual fica chato.

Tem uma sutileza: o "ajudante" só vai aparecer na lista de subagents na PRÓXIMA sessão. O Claude Code carrega os agents quando você abre, então o que eu acabei de criar só ficará disponível depois de você reabrir. Validei tudo o que dá pra validar agora (164/164 testes passam, mocktail funciona, frontmatter do agent é válido). Risco baixo — se algo der ruim, é 4 linhas pra desfazer.
