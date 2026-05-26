# Session 22e — M2-AI Phase 6: golden tests (pivot to `alchemist`)

## Metadata

- **Date**: 2026-05-24
- **Sequence**: 22e
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Phase 6 — golden-test baseline, pivoted from `golden_toolkit` to `alchemist`
- **Duration**: ~40m
- **Related ADRs**: ADR-0029 (new — alchemist adoption + pivot), ADR-0025 (test-author subagent can author goldens as third category), ADR-0021 + ADR-0028 (visual-fidelity defense layers)

## Goal

Execute Phase 6 — add golden-test regression coverage to catch visual drift on stable screens. One canary baseline, validated by pixel-flip gate. ADR enxuto.

## What was done

1. **Library validation via Dart MCP + WebFetch.** Sprint spec named `golden_toolkit`. WebFetch on pub.dev confirmed **`golden_toolkit` is discontinued** (3 years stale, eBay archived). Searched alternatives via `mcp__dart__pub_dev_search`: `alchemist 0.14.0` (Betterment + Very Good Ventures, MIT, 237k downloads, pub points 160/160, 2 months since last publish) is the modern de-facto replacement, explicitly inspired by golden_toolkit.
2. **Pivoted.** Added `alchemist: ^0.14.0` to `apps/mobile/pubspec.yaml` dev_dependencies with a comment explaining the pivot. `flutter pub get` resolved cleanly (alchemist 0.14.0, sha256 pin).
3. **Validated API via Dart MCP** before writing test code (`mcp__dart__resolve_workspace_symbol` for `PlatformGoldensConfig`, `goldenTest`, `GoldenTestScenario`) — confirmed every imported symbol exists in 0.14.0.
4. **Created `apps/mobile/test/flutter_test_config.dart`** with `AlchemistConfig.runWithConfig` setting `platformGoldensConfig.enabled = false` — CI mode only by default, so baselines reproduce across macOS dev and Linux CI without font drift.
5. **Created `apps/mobile/dart_test.yaml`** to register the `golden` tag (silences the runner warning + enables `flutter test --tags golden` / `--exclude-tags golden`).
6. **Picked `HomeEmptyPage` as canary** — already used as the "clean screen" example in ADR-0027 (perf auditor) and has stable widget tests.
7. **First golden run failed** on `Scaffold` infinite-height assertion (Alchemist's default `OverflowBox` passes unbounded constraints). Fixed by explicit `BoxConstraints.tightFor(width: 400, height: 900)` on the scenario — same 400×900 phone surface the project's `test/_support/phone_surface.dart` uses.
8. **Baseline generated** with `flutter test --update-goldens`: `test/features/stops/presentation/goldens/ci/home_empty_page.png` (400×930, 10 029 bytes).
9. **Pixel-flip gate (the must-pass smoke):**
   - Backed up `home_empty_page.dart`, appended `!` to `'Nenhuma entrega ainda'`.
   - `flutter test` → **FAIL** with diff PNG written to `failures/`.
   - Restored original → `flutter test` → **PASS**.
   - Confirmed alchemist behaves correctly. Cleaned `failures/` (it's gitignored anyway).
10. **Added `test/**/failures/`** to `apps/mobile/.gitignore` — failure artifacts are regenerated on every diff and shouldn't pollute commits.
11. **Full validations:** `flutter analyze --no-pub` clean (8.5 s); `flutter test` 165/165 (164 pre-existing + 1 new golden).
12. **Wrote ADR-0029** under the enxuto pattern Eduardo asked for: ~75 lines (vs ~190 in ADRs 0024–0027). 4-row Options table. Decision in 1 sentence. Consequences in 3 bullets. Rollback in 5 short steps. Verification listing what was actually executed.
13. **Wired into the slice checklist** (`docs/M2-SLICE-CHECKLIST.md` §Verification) as the bullet right after the perf-auditor step. Phrased as "if the slice touches a screen with an existing baseline" — explicitly NOT a hook (per sprint decision, baseline maintenance > automation here).
14. **Updated CLAUDE.md, SPRINT-MD, TODO, INDEX.** All commit refs accurate (`(este commit)` placeholders avoided — lesson from session-22b audit).

## Decisions made

1. **Pivot from `golden_toolkit` to `alchemist`.** Boas-práticas — never adopt a discontinued library on a new project. Sprint spec was 6 months old; package state changed.
2. **CI mode default, platform mode opt-in.** Ahem font + platform-agnostic baselines mean the same PNG reproduces locally and on CI; teams that need real-font snapshots opt in per-test.
3. **Canary baseline = 1 screen, manual expansion.** Per sprint design: "Tentar adotar no meio do desenvolvimento gera baseline churn." `HomeEmptyPage` is the only screen mature enough to deserve a baseline today.
4. **No hook for goldens.** Sprint already called this out ("Decisão consciente: NÃO virar hook"). Confirmed — `flutter test --update-goldens` is a deliberate intentional-change moment, not something to auto-trigger.
5. **Explicit constraints on the scenario** (`BoxConstraints.tightFor(width: 400, height: 900)`) rather than fighting Alchemist's default `OverflowBox`. The 400×900 mirrors the project's existing phone-surface convention.

## What did NOT happen, and why

- **More than 1 baseline.** Sprint explicitly said "1 tela representativa, não as 15 de uma vez." Future screens get baselines at their slice-close, owned by the slice author. Karpathy §3 surgical.
- **Hook automation.** Anti-decision codified in both the sprint plan and this ADR.
- **Platform-specific baselines.** Disabled by default; opt-in per test if a real-font snapshot becomes necessary.

## Files changed

**Created:**
- `apps/mobile/dart_test.yaml`
- `apps/mobile/test/flutter_test_config.dart`
- `apps/mobile/test/features/stops/presentation/home_empty_page_golden_test.dart`
- `apps/mobile/test/features/stops/presentation/goldens/ci/home_empty_page.png` (baseline, 10 KB)
- `docs/decisions/0029-alchemist-golden-tests.md`
- `docs/sessions/2026-05-24-22e-phase-6-alchemist-goldens.md` (this file)

**Modified:**
- `apps/mobile/pubspec.yaml` — alchemist dev_dep added.
- `apps/mobile/pubspec.lock` — auto.
- `apps/mobile/.gitignore` — `test/**/failures/` line.
- `CLAUDE.md` — "Last updated" footer.
- `docs/sprints/2026-05-24-m2-ai-harness.md` — phase table + Fase 6 status block + "Próxima sessão deve" pointing at Fase 7.
- `TODO.md` — Phase 6 checkbox done.
- `docs/M2-SLICE-CHECKLIST.md` — §Verification got the golden bullet.
- `docs/sessions/0001-INDEX.md` — new entry at top.

## Practical impact (plain language)

Acabei de instalar uma rede de segurança visual no app. Tirei uma "foto de referência" da tela `HomeEmptyPage` (rota vazia, 400×930 pixels, 10 KB). Da próxima vez que alguém mexer nessa tela sem querer (mudar uma cor, deslocar um botão, alterar um espaçamento), o `flutter test` vai falhar e mostrar exatamente a diferença em forma de PNG.

Testei o gate funcionando: troquei "Nenhuma entrega ainda" por "Nenhuma entrega ainda!" → teste falhou e gerou um PNG do diff. Reverti → teste passou. Funciona como esperado.

Tive que fazer uma escolha técnica importante: a biblioteca que o sprint pedia (`golden_toolkit`) foi **descontinuada pelo eBay** há 3 anos. Adotar lib morta num projeto novo é o oposto de boas práticas. Pesquisei e pivotei para o `alchemist` (mesma ideia, autores diferentes, ativo, 237 mil downloads). Documentei o pivot no ADR-0029.

Outra escolha consciente: **não virei isso em hook automático**. Goldens são pra mudanças visuais intencionais — você roda `flutter test --update-goldens` quando quer atualizar, não toda hora. Hook automático aqui só geraria ruído.

Daqui pra frente, **uma tela = um baseline por slice**, no fechamento da slice. Não vou criar baselines pras outras 14 telas agora — o sprint explicitamente alertou que isso causa "baseline churn". Cada slice decide quais telas merecem foto.

**Estado da sprint:** 6 de 7 fases prontas. Falta só Fase 7 (consolidar docs + retrospectiva da sprint). Branch limpa, testes verdes, pipeline do harness rodou completo (adr-guardian na sequência).
