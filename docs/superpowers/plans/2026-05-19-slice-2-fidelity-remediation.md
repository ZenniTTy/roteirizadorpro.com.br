# Plan — M2 Slice 2 fidelity remediation

> **Date:** 2026-05-19
> **Author:** Claude Code (with Eduardo)
> **Status:** Approved
> **Spec:** `docs/superpowers/specs/2026-05-19-slice-2-fidelity-remediation-design.md`
> **ADR:** `docs/decisions/0021-slice-2-fidelity-remediation.md`
> **Branch:** `feat/m2-slice-2-telas-core`

This plan implements the spec above. Three phases, executed strictly in order. Microsprints inside Phase 2 are strictly serial.

---

## Phase 1 — Audit catalog (read-only)

**Goal:** produce an authoritative list of every Critical / Important / Minor fidelity divergence across all 18 slice-1+2 screens, appended to `TODO.md`.

**Duration estimate:** 3–4 hours wall-time, one sequential agent run.

### Task 1.1 — Pre-flight: confirm canonical sources are loadable

- [ ] Verify `prototipo/tokens.js`, `prototipo/ui.jsx`, `prototipo/screens-{a,b,c,d,e}.jsx` are all readable and parse (no syntax issues from in-flight edits).
- [ ] Verify all 18 Dart presentation files still compile (`flutter analyze --no-pub` clean before audit).
- [ ] Record the audit's starting SHA: `git rev-parse HEAD`.

### Task 1.2 — Dispatch `prototype-fidelity-checker` (sequential single-agent)

Prompt (verbatim — copy into the Agent dispatch):

```
You are the prototype-fidelity-checker for Roteirizador Pro. Audit ALL 18 slice-1+2 screens
of the Flutter mobile app against the canonical prototype at prototipo/.

Canonical sources (load once, keep in context):
- prototipo/tokens.js         — design tokens (colors, radii, shadows, font)
- prototipo/ui.jsx            — shared primitives (Input, PrimaryButton, FAB, BottomNav, StopCard, HomeTopBar, TopBar, FlexibleBottomSheet, Phone)
- prototipo/screens-a.jsx     — ScreenLogin, ScreenRegister, ScreenHomeEmpty, ScreenHomeList,
                                 ScreenAddStop, ScreenVoice
- prototipo/screens-b.jsx     — ScreenOCR, ScreenAddStopsMap, ScreenOptimize, ScreenOptimizeRoute,
                                 ScreenStopDetail, ScreenPaywall (SKIP — slice 4),
                                 ScreenNavigate
- prototipo/screens-c.jsx     — ScreenMapStops
- prototipo/screens-d.jsx     — ScreenSettings, ScreenVoice (continued), ScreenShare
- prototipo/screens-e.jsx     — ScreenEditStop, ScreenReorder, ScreenRouteComplete

Audit pairs (Dart file ↔ prototype function):
  1.  apps/mobile/lib/features/auth/presentation/login_page.dart           ↔ ScreenLogin
  2.  apps/mobile/lib/features/auth/presentation/register_page.dart        ↔ ScreenRegister
  3.  apps/mobile/lib/features/stops/presentation/home_empty_page.dart     ↔ ScreenHomeEmpty
  4.  apps/mobile/lib/features/stops/presentation/home_list_page.dart      ↔ ScreenHomeList
  5.  apps/mobile/lib/features/stops/presentation/stop_detail_page.dart    ↔ ScreenStopDetail
  6.  apps/mobile/lib/features/stops/presentation/edit_stop_page.dart      ↔ ScreenEditStop
  7.  apps/mobile/lib/features/stops/presentation/add_stop_page.dart       ↔ ScreenAddStop
  8.  apps/mobile/lib/features/stops/presentation/voice_capture_page.dart  ↔ ScreenVoice
  9.  apps/mobile/lib/features/stops/presentation/ocr_capture_page.dart    ↔ ScreenOCR
  10. apps/mobile/lib/features/stops/presentation/add_stops_map_page.dart  ↔ ScreenAddStopsMap
  11. apps/mobile/lib/features/stops/presentation/map_stops_page.dart      ↔ ScreenMapStops
  12. apps/mobile/lib/features/stops/presentation/optimize_page.dart       ↔ ScreenOptimize
  13. apps/mobile/lib/features/stops/presentation/optimize_route_page.dart ↔ ScreenOptimizeRoute
  14. apps/mobile/lib/features/stops/presentation/navigate_page.dart       ↔ ScreenNavigate
  15. apps/mobile/lib/features/stops/presentation/reorder_page.dart        ↔ ScreenReorder
  16. apps/mobile/lib/features/stops/presentation/route_complete_page.dart ↔ ScreenRouteComplete
  17. apps/mobile/lib/features/settings/presentation/settings_page.dart    ↔ ScreenSettings
  18. apps/mobile/lib/features/share/presentation/share_sheet.dart         ↔ ScreenShare

Also audit:
  - apps/mobile/lib/app.dart — router (Critical if `context.go` is used where push semantics
    are required — i.e., anywhere the prototype wires onBack: () => goto(parent)).
  - apps/mobile/lib/core/theme/app_theme.dart — token drift vs prototipo/tokens.js
    (Critical if any color/radius/shadow value diverges from the prototype's token).

Severity rubric:
  - Critical: user-visible structural/behavioral divergence (wrong widget type, missing core
    UI element, broken navigation). Blocks slice tag.
  - Important: visible but not blocking (wrong title, missing back-arrow on a screen the user
    can leave another way, accessibility miss). Fix in the same microsprint if behavior-affecting;
    else dated debt.
  - Minor: <2dp drift, single-pixel border, harmless extra padding. Always debt.

Output format (one big markdown block, copy-pasteable into TODO.md):

  ## Slice 2 fidelity audit — findings (2026-05-19)

  ### <pair number>. <Dart file> ↔ <Screen* function>
  Status: ✅ FIEL  |  🟡 IMPORTANT-ONLY  |  🔴 HAS CRITICAL

  - **C-N (Critical):** <one-line> — prototype: `prototipo/screens-X.jsx:LINE-LINE` —
    current: `apps/mobile/lib/.../FILE.dart:LINE-LINE` — fix: <brief proposed change>
  - **I-N (Important):** <…>
  - **M-N (Minor):** <…>

Do NOT edit any code. Read-only audit. End your turn with a summary count:
  "Audit complete: X Criticals across Y screens; Z Importants; W Minors."
```

### Task 1.3 — Append catalog to `TODO.md` and commit

- [ ] Open `TODO.md`, find the section "Slice 2 — Telas Core (IN PROGRESS — sub 2a Foundation 10/16 tasks done)" (or current).
- [ ] Append a new H2 `## Slice 2 fidelity audit — findings (2026-05-19)` with the agent output verbatim.
- [ ] Stage `TODO.md`, `docs/decisions/0021-slice-2-fidelity-remediation.md`, `docs/superpowers/specs/2026-05-19-slice-2-fidelity-remediation-design.md`, `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md`.
- [ ] Commit: `docs(decisions): adr-0021 audit catalog`.
- [ ] Record post-audit SHA in this plan's `## Execution log` (added at the bottom).

### Task 1.4 — Triage decision gate

If audit returns **>20 Criticals**, stop and escalate to Eduardo with a partial-ship-vs-full-remediate decision before starting Phase 2 (spec §Risks Mitigation 1).

If **≤20 Criticals**, proceed to Phase 2.

---

## Phase 2 — Microsprint correction loop

**Goal:** every Critical from the Phase 1 catalog ends with `→ FIXED (commit <sha>)`.

**Duration estimate:** 2–3 days wall-time (depends on Critical count).

**Microsprint ordering:** by **blast radius** — fix the most foundational first.

1. `app.dart` router back-nav fixes (if Criticals there — affects every screen).
2. `core/theme/app_theme.dart` token drift (if any — affects every screen).
3. `prototipo/ui.jsx` shared primitives mapped to Dart widgets in `core/widgets/` (HomeTopBar, FAB, BottomNav, FlexibleBottomSheet) — fix these first because screens reuse them.
4. Then screen-by-screen, in the order discovered, lowest impact first → highest impact last. The high-impact ones (`AddStop`, `Optimize`, `Navigate`) get full attention without rushing.

### Task 2.N — Per-screen microsprint template

For each screen N in the prioritized order, execute the pipeline below. Mark this checklist for each microsprint in `TODO.md`'s findings catalog (one checkbox per Critical → fixed).

#### 2.N.1 — Pre-flight (controller, 5–10min)

- [ ] Re-read prototype function for screen N (line range from catalog).
- [ ] Re-read current Dart file.
- [ ] Re-read the catalog entry's Criticals only (Importants noted but not fixed unless behavior-affecting).
- [ ] State the delta in 1–3 bullets in the microsprint commit-message draft.
- [ ] Confirm GO/NO-GO criteria: every Critical line must close, no widget test failures introduced.

#### 2.N.2 — DISPATCH 1: prototype-fidelity-checker (single-screen, read-only)

Prompt template:

```
Re-audit ONE screen: <prototype-function> ↔ <Dart file>.
Confirm the Criticals listed below are still present and produce a final delta spec
(the exact widget tree changes needed to close them):

  <paste the catalog entries for this screen>

Read-only. Do NOT edit code. Output the delta spec as a numbered list:
  1. <change> (prototype: line, current: line)
  2. <…>
```

#### 2.N.3 — DISPATCH 2: implementer (Claude, isolated context)

Prompt template:

```
Implement these fixes in <Dart file>. Read these references first:
  - <Dart file> (current)
  - <prototype-function in prototipo/screens-X.jsx> (lines L–L)
  - prototipo/tokens.js (for any color/radius/shadow used)
  - prototipo/ui.jsx (for any shared primitive used)

Karpathy §3 (Surgical Changes) is the hard rule — fix ONLY these Criticals:

  <paste the delta spec from D1>

Do not refactor adjacent code. Do not "improve" comments. Do not introduce abstractions.

Test discipline (Karpathy §4):
  - Run `flutter analyze --no-pub <Dart file>` — must be 0 issues.
  - Run `flutter test test/path-to-test-of-this-screen` — must be all green
    (rewrite assertions if structure changed; do NOT skip tests).

Output: the diff. Do not commit yet.
```

#### 2.N.4 — DISPATCH 3: prototype-fidelity-checker (re-audit, single-screen)

Prompt: identical to D1 with the new Dart file content. Must return ✅ FIEL or HAS NEW CRITICALS. If new Criticals: loop back to D2 with feedback.

#### 2.N.5 — DISPATCH 4: pr-review-toolkit:code-reviewer

Prompt template:

```
Review this diff against:
  - Karpathy 4 principles (Think Before, Simplicity First, Surgical Changes, Goal-Driven)
  - CLAUDE.md conventions (especially ADR-0013 mirror contract if DTOs touched —
    likely not since this is UI remediation)
  - ADR-0010 (prototype canonical)
  - Repo style: no comments unless WHY is non-obvious; no over-abstraction;
    no unused imports; no half-finished implementations.

Severity:
  - Important: blocks merge.
  - Suggestion: optional improvement, dated debt if not addressed now.

Diff:
  <paste the diff from D2>
```

If Important issues raised: loop back to D2 with feedback. Else proceed.

#### 2.N.6 — Commit

- [ ] Run lefthook pre-commit manually first to catch issues early: `bun run lint` (or equivalent).
- [ ] Stage only the files touched by this microsprint.
- [ ] Commit message format:
  ```
  fix(mobile): <screen> — <one-line summary>

  Closes catalog Criticals: C-N1, C-N2.

  Prototype: prototipo/screens-X.jsx:LINE-LINE.
  Verified by prototype-fidelity-checker (re-audit) and pr-review-toolkit:code-reviewer.
  ```
- [ ] `git commit` — lefthook + commitlint enforce; stop-hooks are signal-only.

#### 2.N.7 — Checkpoint

- [ ] Update `TODO.md` catalog: each closed Critical gets `→ FIXED (commit <sha>)` appended.
- [ ] If the microsprint touched a structural element (sheet, navigation, bottom nav, top bar) → rebuild APK via `scripts/build-release-apk.sh` and reinstall on A06 to smoke-test the changed screen. Otherwise (pure widget tweak), defer the rebuild to the end of Phase 2.
- [ ] Tick the microsprint's checkbox here in this plan file.

---

## Phase 3 — Re-audit + device E2E

**Goal:** prove every Critical closed, every gate passes, the slice is ready for tag `v1.1.0`.

**Duration estimate:** 4–8h.

### Task 3.1 — Final fidelity sweep

- [ ] Dispatch `prototype-fidelity-checker` over all 18 screens **sequentially** (same prompt format as Phase 1).
- [ ] Expected output: "Audit complete: 0 Criticals across 0 screens; ..." (Importants/Minors may remain as documented debt).
- [ ] If any Critical resurfaces, return to Phase 2 with a new microsprint.

### Task 3.2 — Final build + install

- [ ] `bash apps/mobile/scripts/build-release-apk.sh` — full clean rebuild.
- [ ] `aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk` — must list INTERNET + ACCESS_FINE_LOCATION + RECORD_AUDIO + CAMERA.
- [ ] `apksigner verify --print-certs` — cert SHA-256 must match `D9:C9:61:D6:…:14:31` (ADR-0014).
- [ ] `adb -s <A06> uninstall br.com.roteirizadorpro.roteirizador_pro && adb -s <A06> install build/app/outputs/flutter-apk/app-release.apk`.

### Task 3.3 — Device E2E 14-step golden path

Execute on the Galaxy A06 (Android 16). Screenshot each step into `docs/sessions/2026-05-19-17-slice-2-fidelity-audit/`. Steps:

1. Open app → ScreenHomeEmpty.
2. Tap FAB → ScreenAddStop (bottom sheet over blurred home).
3. Add stop via Teclado chip + type address.
4. Tap chip "Voz" → ScreenVoice → speak address (Brazilian pt-BR locale; mic permission prompt).
5. Tap chip "Câmera" → ScreenOCR → photograph an address label.
6. Add a 4th stop via map tap → ScreenAddStopsMap.
7. Return to ScreenHomeList (now showing 4 stops with index circles).
8. Tap a stop → ScreenStopDetail (title shows "Parada N de 4").
9. Tap "Editar" → ScreenEditStop → change label → save → return to ScreenStopDetail.
10. Long-press to reorder → ScreenReorder → drag stop 4 to position 2 → save.
11. Tap "Otimizar rota" → ScreenOptimize (auto-fires) → ScreenOptimizeRoute (map + metrics).
12. Tap "Iniciar rota" → opens Waze (default) → return to app via task switcher → ScreenNavigate.
13. Tick all stops as concluded → ScreenRouteComplete (2-layer box-shadow card).
14. Open ScreenSettings → toggle nav provider to Google Maps → verify persistence (kill app, reopen, toggle still on Maps). Tap "Indicações" → ScreenShare → tap "Compartilhar" → verify native share sheet opens.

Every step must visually match the prototype's corresponding `Screen*` function. Screenshots vs prototype thumbnails side-by-side.

### Task 3.4 — `/verify-slice` skill

- [ ] Run `/verify-slice` from Claude Code.
- [ ] Expected: all sub-checks green (flutter analyze, flutter test, bun typecheck, prototype-fidelity-checker, adr-guardian).

### Task 3.5 — Process fix: update `M2-SLICE-CHECKLIST.md`

- [ ] Add a new mandatory bullet under §Verification:
  > **Device E2E golden-path on physical Android (not emulator) before tag.** Capture screenshots into the session-log directory. Validate every UI step matches the prototype's corresponding `Screen*` function.
- [ ] Commit: `docs(checklist): add device-e2e gate (adr-0021)`.

### Task 3.6 — Session-end commit

- [ ] Write `docs/sessions/2026-05-19-17-slice-2-fidelity-audit.md` from the template.
- [ ] Update `docs/sessions/0001-INDEX.md`.
- [ ] Update `TODO.md` reflecting the post-remediation state (every Critical closed, debt items dated).
- [ ] Commit: `docs(sessions): 2026-05-19-17-slice-2-fidelity-audit`.

### Task 3.7 — Promote slice

- [ ] Open PR `feat/m2-slice-2-telas-core` → `develop`.
- [ ] After CI green + ADR-0021 referenced in PR body, merge.
- [ ] Open PR `develop` → `main`.
- [ ] After merge, tag `v1.1.0` and republish APK (Task 38 from the old plan resumes here).

---

## Execution log

(Filled in as phases complete.)

- **2026-05-19 23:XX** — Phase 0 (spec/plan/ADR) committed at SHA `<…>`.
- **2026-05-19 23:XX** — Phase 1 audit catalog committed at SHA `<…>`. Found `<X>` Criticals across `<Y>` screens; `<Z>` Importants; `<W>` Minors.
- **2026-05-XX HH:MM** — Phase 2 complete; last microsprint commit `<…>`.
- **2026-05-XX HH:MM** — Phase 3 complete; v1.1.0 tagged.
