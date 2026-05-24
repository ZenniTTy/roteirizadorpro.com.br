# ADR-0029: Adopt `alchemist` for golden tests (pivot from `golden_toolkit`)

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0025 (`flutter-test-author` subagent — golden tests are the third test category it can author), ADR-0021 (device-fidelity gate — goldens are the static counterpart), ADR-0028 (rejected `mcp_flutter`; visual fidelity now leans on static checker + goldens + device-E2E)
- **Sprint:** M2-AI Harness — Phase 6 (see `SPRINT-M2-AI-HARNESS.md`)

## Context

Phase 6 of the M2-AI sprint adds golden-test regression coverage to catch visual drift on screens that have stabilized. The sprint draft named `golden_toolkit` (eBay). `WebFetch` confirmed it is **discontinued** (last release 3 years ago, marked discontinued on pub.dev). Adopting a discontinued package on a new project violates "boas práticas" — same reasoning that drives the ADR-0023 / ADR-0024 emphasis on current docs.

Searched for the modern replacement. `alchemist 0.14.0` (Betterment + Very Good Ventures, MIT, 237k downloads, pub points 160/160, last published 2 months ago) is the de-facto successor — explicitly inspired by `golden_toolkit`, same problem shape, active maintenance.

## Decision

**Adopt `alchemist ^0.14.0`** as the project's golden-test library, with one baseline today (`HomeEmptyPage`) and the rest opt-in per screen at slice close.

CI mode is the default — Ahem font, platform-agnostic — so the same baseline reproduces on macOS dev and Linux CI without font drift. Platform-specific goldens are disabled by default via `AlchemistConfig.platformGoldensConfig.enabled = false` in `test/flutter_test_config.dart`; opt-in per test when a real-font snapshot is needed.

| # | Option | Verdict |
|---|---|---|
| 1 | `golden_toolkit` (sprint's original choice) | Rejected — discontinued by eBay 3 years ago. |
| 2 | `alchemist` (Betterment) | **Accepted.** Active, MIT, 237k downloads, inspired by golden_toolkit, CI + platform modes built in. |
| 3 | Vanilla `flutter_test` `matchesGoldenFile` | Rejected — no font discipline, no CI/platform split, every test must hand-roll fixture sizing. |
| 4 | No goldens for M2; rely on device-E2E (ADR-0021) only | Rejected — device-E2E is necessary but slow; goldens catch the cheap regressions before device. |

## Implementation

- `apps/mobile/pubspec.yaml` — `alchemist: ^0.14.0` in `dev_dependencies`.
- `apps/mobile/test/flutter_test_config.dart` — new, wires `AlchemistConfig` (CI mode only by default).
- `apps/mobile/dart_test.yaml` — new, registers the `golden` tag so it can be included/excluded explicitly.
- `apps/mobile/.gitignore` — `test/**/failures/` (Alchemist's per-failure diff artifacts).
- `apps/mobile/test/features/stops/presentation/home_empty_page_golden_test.dart` — new, single scenario.
- `apps/mobile/test/features/stops/presentation/goldens/ci/home_empty_page.png` — new baseline (400×930, 10 KB).

`HomeEmptyPage` is a `Scaffold`, which asserts under Alchemist's default `OverflowBox` (infinite height). Solved by passing explicit `BoxConstraints.tightFor(width: 400, height: 900)` on the scenario — same 400×900 logical viewport used by the project's `test/_support/phone_surface.dart` helper.

## Consequences

- **Visual regression caught at `flutter test` time** for one canary screen now; expandable per slice at the slice author's discretion.
- **Baseline maintenance cost is real.** Each intentional UI change requires `flutter test --update-goldens` + diff review in the PR. Mitigated by CI mode (only re-render text drift surfaces as a diff, not every font glyph metric).
- **No hook.** Goldens stay manual per the slice checklist — making them a Stop/PostToolUse hook would multiply CI time without proportionate signal. The sprint plan explicitly called this out.

## Rollback

1. Delete `apps/mobile/test/flutter_test_config.dart` and `dart_test.yaml`.
2. Delete `apps/mobile/test/**/*_golden_test.dart` and the `goldens/` subfolders.
3. Remove `alchemist: ^0.14.0` from `apps/mobile/pubspec.yaml` dev_dependencies; `flutter pub get`.
4. Revert the `test/**/failures/` line in `apps/mobile/.gitignore`.
5. Remove the slice-checklist bullet.

Total revert: 5 file groups. No production-code touch.

## Verification (executed at adoption)

- `flutter test --update-goldens` produced `goldens/ci/home_empty_page.png` (400×930, 10 029 bytes). ✅
- Re-run without `--update-goldens` passes (baseline reproduces). ✅
- **Pixel-flip gate:** appended `!` to `'Nenhuma entrega ainda'` in the page → `flutter test` failed and wrote a diff PNG to `failures/`. ✅
- **Revert gate:** restored the original string → `flutter test` passes again. ✅
- Full suite: 165/165 (164 pre-existing + 1 new golden). ✅
- `flutter analyze --no-pub` clean (no issues introduced). ✅

## References

- pub.dev: `alchemist` 0.14.0 (Betterment + Very Good Ventures).
- pub.dev: `golden_toolkit` — discontinued; reason for the pivot.
- `apps/mobile/test/_support/phone_surface.dart` — 400×900 surface convention reused here.
- ADR-0025 — `flutter-test-author` subagent (golden tests are its third category, opt-in per screen).
- SPRINT-M2-AI-HARNESS.md §Fase 6 — task list this ADR codifies (with the golden_toolkit → alchemist pivot called out).
