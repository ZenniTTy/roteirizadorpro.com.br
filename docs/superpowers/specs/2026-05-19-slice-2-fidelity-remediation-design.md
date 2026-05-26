# Spec — M2 Slice 2 fidelity remediation (retroactive audit)

> **Date:** 2026-05-19
> **Author:** Claude Code (with Eduardo)
> **Status:** Approved
> **Branch:** `feat/m2-slice-2-telas-core` (no fork — continues current branch at `ea3fe57`; `origin/develop` base is `49f83ae`)
> **Source of truth:** `docs/08-ROADMAP.md` "Slice 2 — Telas Core" and ADR-0021 (this spec implements ADR-0021's Phase 1 + 2 + 3).

## Context

Slice 2 (Telas Core) reached a candidate `v1.1.0` release APK on 2026-05-19 after 16 sessions. A device-fidelity smoke test on a physical Galaxy A06 (Android 16) revealed four Criticals on the very first screen exercised (`ScreenAddStop`):

1. Wrong structure — full-screen Scaffold instead of bottom-sheet over blurred home.
2. Missing 3-method chips (Teclado / Voz / Câmera), making `voice_capture_page` and `ocr_capture_page` UI-dead-code despite being implemented.
3. Missing address autocomplete suggestions list.
4. Android back-button minimizes the app on `AddStop` (router-wide `context.go` instead of `push`).

The full-slice `prototype-fidelity-checker` audit and 91 widget tests had passed; these gaps surfaced only on device. The likelihood that the other 17 slice-1+2 screens have similar defects is high enough to justify a full retroactive audit before `develop` PR.

ADR-0021 codified the remediation process. This spec elaborates the **how** for one round of execution.

## Decisions locked

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Scope of the audit — only the 4 known Criticals (cheap), all 18 slice-1+2 screens (thorough), or all 18 plus retroactive session re-review (paranoid)? | **All 18 screens (L2)** | L1 is false confidence; L3 is overkill given sessions already documented. L2 closes the discovery loop and produces an authoritative catalog. |
| Q2 | Token-paid parallel dispatch (18 agents) or token-efficient sequential single-agent? | **Sequential single-agent** | User explicitly prioritized token economy. One agent loads `prototipo/` once and iterates 18 screens; wall-time is longer (~3–4h) but token cost is 3–5× lower. |
| Q3 | Branch strategy — fork remediation branch or continue current? | **Continue `feat/m2-slice-2-telas-core`** | Preserves linear slice-2 history; final PR still single `→ develop`. Forking would split history and require a second merge. |
| Q4 | ADR scope — one omnibus ADR-0021 covering the remediation, or one ADR per pattern fixed? | **One omnibus ADR-0021** | Patterns repeat across screens (back-nav, missing chips). One ADR captures the meta-decision; per-screen findings live in the catalog inside `TODO.md`, not in ADRs. |
| Q5 | What happens to Importants and Minors? | **Importants → fix in same microsprint if behavior-affecting; otherwise debt. Minors → debt only.** | Minors (e.g., 1-px spacing drifts) consume disproportionate time. The bar is "would a user notice or feel something is broken?" — yes → fix; no → debt. |

## Goals (acceptance for the remediation)

A real Galaxy A06 install of `v1.1.0` can, against production API:

1. Add a stop via **typing** (`ScreenAddStop` keyboard chip path).
2. Add a stop via **voice** (`ScreenAddStop` → `ScreenVoice` via chip — currently unreachable).
3. Add a stop via **photo / OCR** (`ScreenAddStop` → `ScreenOCR` via chip — currently unreachable).
4. Add a stop via **map tap** (`ScreenAddStop` → `ScreenAddStopsMap` — verify reachability).
5. Tap Android back from any non-root screen and **return to the previous screen** (not minimize the app).
6. Visually pass a side-by-side comparison against `prototipo/screens-*.jsx` for all 18 slice-1+2 screens — zero Criticals open, every Important either fixed or dated in `TODO.md`.

### Non-goals

- Re-audit of `ScreenPaywall` (slice 4 — not implemented yet).
- Refactor of harness skills/hooks/agents (orthogonal — covered by Wave A/B/C, already shipped).
- Re-audit of backend / landing / docs surfaces (not slice-2 product surface).
- Pixel-perfect 1-px spacing/typography matches that are not visible to a real user (these become slice-3 polish Minors).
- Address autocomplete with real geocoding (Critical C3 in `ScreenAddStop` — implemented as static placeholder; live Nominatim call lands in slice 3 per ADR-0018 cost ceiling).

## Architecture

No new files — this is a remediation. Touched surface (will be refined by the audit output):

```
apps/mobile/lib/
├── app.dart                        # router: context.go → context.push where appropriate
├── features/
│   ├── auth/presentation/          # ScreenLogin, ScreenRegister (audit)
│   ├── settings/presentation/      # ScreenSettings (audit)
│   ├── share/presentation/         # ScreenShare (audit)
│   └── stops/presentation/
│       ├── add_stop_page.dart      # MAJOR — sheet + chips + suggestions + back-nav
│       ├── add_stops_map_page.dart # audit
│       ├── edit_stop_page.dart     # audit
│       ├── home_empty_page.dart    # audit (HomeTopBar custom?)
│       ├── home_list_page.dart     # audit (HomeTopBar custom + chip ETA/count)
│       ├── home_page.dart          # routing shim; audit
│       ├── map_stops_page.dart     # audit
│       ├── navigate_page.dart      # audit
│       ├── ocr_capture_page.dart   # audit (reachability via ScreenAddStop chip)
│       ├── optimize_page.dart      # audit
│       ├── optimize_route_page.dart# audit (metrics row, neon CTA, etc.)
│       ├── reorder_page.dart       # audit
│       ├── route_complete_page.dart# audit (box-shadow 2-layer, gradient ring)
│       ├── stop_detail_page.dart   # audit
│       └── voice_capture_page.dart # audit (reachability via ScreenAddStop chip)
```

## Sub-slice plan

This remediation has **three phases**, executed strictly in order.

### Phase 1 — Catalog (read-only, ~3–4h)

One `prototype-fidelity-checker` agent run sequentially over all 18 screens. The agent:

- Loads `prototipo/tokens.js`, `prototipo/ui.jsx`, `prototipo/screens-{a,b,c,d,e}.jsx` once into context.
- For each screen: reads the matching Dart file + cross-references the `Screen*` function in the prototype.
- Outputs a catalog with one entry per finding: `{file, line, severity: Critical|Important|Minor, finding, prototype-cite, suggested-fix}`.
- Does **not** edit code.

The catalog is appended to `TODO.md` under a new H2 `## Slice 2 fidelity audit — findings (2026-05-19)`.

### Phase 2 — Microsprint correction loop (~2–3 days)

For each screen with ≥1 Critical, one microsprint runs the pipeline below. Microsprints are **strictly serial** — no two in flight at once — to keep `git log` linear and avoid cross-Critical interference.

```
PRE-FLIGHT
  controller reads:
    - prototype function (line range)
    - current Dart file
    - the catalog entry for this screen
  controller states delta in 1–3 bullets
  controller defines GO/NO-GO criteria

DISPATCH 1: prototype-fidelity-checker (single-screen, read-only)
  confirms catalog entry still valid; produces final delta spec

DISPATCH 2: implementer (Claude, isolated context)
  reads: spec from D1, current Dart file, prototype lines
  fixes ONLY the Criticals listed (no surrounding refactor — Karpathy §3 Surgical Changes)
  runs: flutter analyze [file], flutter test [related tests]
  output: candidate diff

DISPATCH 3: prototype-fidelity-checker (re-audit, single-screen)
  confirms Criticals closed + no regressions introduced

DISPATCH 4: pr-review-toolkit:code-reviewer
  reviews diff against Karpathy 4 + CLAUDE.md conventions + ADR-0010

COMMIT
  conventional commit (scope-enum compliant — `fix(mobile)`, `refactor(mobile)`)
  lefthook pre-commit (analyze + typecheck) gates
  stop-hooks signal (non-blocking)

CHECKPOINT
  update TODO.md (mark Critical closed)
  optionally rebuild APK if structural change (e.g., AddStop) — install on A06 — smoke test the changed screen
```

If D3 or D4 returns NO-GO, loop back to D2 with the feedback. Do not advance to the next microsprint until the current one commits.

### Phase 3 — Re-audit + device E2E (~4–8h)

- Final sequential `prototype-fidelity-checker` over all 18 screens (sanity — every Critical must now be closed).
- Rebuild release APK via `scripts/build-release-apk.sh`.
- Install on Galaxy A06 via Wi-Fi adb.
- Execute the 14-step golden-path E2E (Task 37 — was paused).
- Run `/verify-slice` skill (orchestrates the full slice-checklist gate per ADR-0018).
- Update `M2-SLICE-CHECKLIST.md` §Verification: add the new mandatory bullet "Device E2E golden-path on physical Android (not emulator) before tag" — this is the process fix ADR-0021 §Consequences mandates.

## Libraries

No new libraries. The remediation operates within the existing slice-2 dependency surface (Context7 validations of `flutter_map`, `speech_to_text`, `google_mlkit_text_recognition`, `url_launcher`, `share_plus`, `shared_preferences`, `permission_handler`, `image_picker` already on file in ADR-0015).

## ADRs filed

- **ADR-0021** — Slice 2 fidelity remediation (process meta-ADR; filed 2026-05-19 in this PR).
- No per-finding ADRs — patterns repeat across screens; one omnibus catalog in `TODO.md` is the right granularity.

## Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Audit catalog explodes to 50+ Criticals — remediation becomes a multi-week project | Medium | Hard cap: if audit returns >20 Criticals, escalate to Eduardo with a "ship partial v1.1.0-beta + remediate over 2 weeks" decision proposal before starting Phase 2. |
| `prototype-fidelity-checker` agent gives false positives (we touched something it doesn't recognize as compliant) | Low | Each Critical gets a human review before the microsprint runs (PRE-FLIGHT step). False positives become "agent calibration" notes, not microsprints. |
| Back-nav fix (`context.go` → `push`) breaks tests that asserted `context.go` semantics | Medium | The audit catalogs back-nav per screen; the fix touches the router AND any test that compiled around the old behavior. Standard test-update discipline. |
| Bottom-sheet refactor of `AddStop` regresses existing widget tests (which assert flat-screen structure) | Medium | Widget tests for `AddStopPage` get rewritten in the same commit. TDD discipline — failing test first, then fix. |
| Rebuild + reinstall cycle eats time | Low | Phase 2 doesn't require a rebuild per microsprint — only for structural changes (AddStop, HomeEmpty top bar). Pure widget tweaks land via `flutter run --hot-reload` on the existing release-apk install — wait, release APK doesn't accept hot reload. Rebuild is mandatory after every microsprint that changes the surfaced UI. **Mitigation accepted: budget ~5min per microsprint for rebuild + reinstall via Wi-Fi adb.** |

## Accessibility

The audit catalogs accessibility findings (missing `Semantics` wrappers, tap-target < 48dp, missing labels) at the Important severity tier — they are fixed in the same microsprint as the screen's Criticals if the screen has any, else they become slice-3 polish debt.

## Test strategy

- Widget tests already exist for 91 cases — broken tests are updated in the same commit that fixes the screen (no separate "fix tests" commits).
- No new test framework introduced.
- Phase 3 E2E is manual (human + adb screencap) — automated UI testing (`integration_test` package, Patrol, Maestro) is **explicitly post-M2**.

## Verification gates

Order (every gate must pass before promotion to `develop` PR):

1. Phase 1 catalog appended to `TODO.md`.
2. Every Critical row in the catalog ends with `→ FIXED (commit <sha>)`.
3. `flutter analyze --no-pub` — 0 issues.
4. `flutter test` — all green.
5. `bun run typecheck` (backend) — green (sanity; remediation shouldn't touch backend but verifies no contamination).
6. Phase 3 device E2E — 14 steps green, screenshots filed at `docs/sessions/2026-05-19-17-slice-2-fidelity-audit/` (or the dated equivalent).
7. `/verify-slice` skill — all sub-checks green.
8. `prototype-fidelity-checker` final sweep — zero Criticals.
9. Session log filed; `TODO.md` reflects post-remediation state; commit `docs(sessions): 2026-05-19-17-slice-2-fidelity-audit.md`.

## References

- ADR-0021 — this spec's enabling decision.
- ADR-0010 — prototype canonical.
- ADR-0015 — slice 2 plan and acceptance criteria.
- ADR-0019 — spec template (this file is the template applied).
- `docs/M2-SLICE-CHECKLIST.md` — universal gate list (gets one bullet added in Phase 3).
- `prototipo/screens-{a,b,c,d,e}.jsx` — the canon.
- `prototipo/tokens.js` — design tokens (Critical drift here propagates everywhere).
- `prototipo/ui.jsx` — shared UI primitives (Input, PrimaryButton, FAB, BottomNav, StopCard).
