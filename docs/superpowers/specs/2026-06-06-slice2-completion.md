# Spec — Slice 2 Completion (Telas Core Spoke-aligned)

> **Date:** 2026-06-06
> **Author:** Claude Code (with Eduardo)
> **Status:** Draft — to be executed MS-by-MS (one area per microsprint) in separate sessions
> **Branch:** continue on `feat/m2-slice-2-area-5-route-details` to finish Área 5; then per-area branches OR a single `feat/m2-slice-2-spoke-clone` integration branch (decided at MS0).
> **Source of truth:** `docs/08-ROADMAP-v2.md` (Slice 2 section — the clean rewrite) + `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §10/§11/§12/§13. If this spec disagrees with the roadmap, the roadmap wins.

---

## Context

Slice 1 shipped (`v1.0.0`). Slice 2 (white-label functional clone of the **B2C Spoke Route Planner**) is ~55% done. Measured ground truth (code-read 2026-06-06):

- **Done:** Área 1 (Login/Register), Área 2 (drawer/lista/wizard/reuse), Área 4 (add-stop TEXT via **live** Google Places).
- **Partial:** Área 3 (~80% — map controls + Otimizar CTA + stop-card tap + kebab are `_comingSoon` stubs); Área 5 (MS1–MS5+MS-FIX done; MS6 Pausa, MS7 wire-rows, MS8 persistence+FTUE, MS9 integration_test+PR open on the current branch).
- **Not started:** Áreas 6, 7, 8, 9, 10, 11 + Área 1 auth-UI leftovers (forgot-password screen + Google button).

Eduardo's goal: **finish Slice 2 completely**, executed area-by-area in future sessions, with a strict per-area discipline he specified:

> For every area: (1) a minute analysis via WebSearch/Context7 of whether we're following the most modern best-practices compatible with our stack/architecture; THEN (2) a **fresh live Spoke dump mapping ONLY that area** and everything to be built, so there are no functional/UI divergences; (3) implement; (4) validate via the full harness pipeline; (5) at the end, leave everything in the harness updated per best-practices. Plus: explicitly document the bad-practices already committed that must never recur.

This spec encodes that discipline. The recurring failures it must prevent are real and costly — see §Bad practices (the never-again list), distilled from 33 deduped anti-patterns across memory + audits + sessions.

> **UPDATE 2026-06-09 (ADR-0045 — dump estático):** a complete static dump of Spoke v3.65.1 now exists at [`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`](../../inventory/spoke-dump-v3.65.1/MASTER-TABLE.md), resolving the 20 "Não drilled" gaps into structural FACT (fields, defaults, enums, verbatim PT-BR strings, code package). This **inverts Phase 2** for Áreas 6–11: the "fresh live Spoke dump" step (2) is now CONFIRMATION of the MASTER-TABLE hypotheses (where the row's `Precisa-runtime` field flags it), not greenfield discovery. Read the table FIRST, then confirm live. The cure for the ADR-0041/0042/0043/0044 stale-inference rework is now upfront, not per-area.

### Why this is a spec and not just "keep building"

Two consecutive microsprints (MS4 numpad, MS5 Destino) shipped wrong widget shapes from **stale Spoke baselines** — re-work across two ADRs. The cure is process: the per-area discipline below makes live-inspection + modern-stack verification a mechanical precondition, not a hope. The roadmap is the *what*; this spec+plan is the *how*, encoded so a future session can't skip the step that failed twice.

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Scope of "finish Slice 2" | **All remaining areas: finish Área 3 triggers + Área 5 MS6–MS9, then Áreas 6,7,8,9,10,11 + Área 1 auth-UI.** No depth-cutting to fit a single day. | Eduardo: "cobre tudo do Slice 2 completamente." Executed across sessions, one area per MS. |
| Q2 | Execution order | **Forced by dependency graph (NOT free):** finish Área 5 (MS6→MS9) + Área 3 triggers → Área 6 → Área 7 → Área 8 → Área 9. Áreas 1, 10, 11 are independent (10 before 11). | The critic confirmed 6/7/8/9 each hard-depend on a prior area's trigger; treating them greenfield repeats the MS5 scope-error. |
| Q3 | Per-area discipline | **Mandatory 5-phase pipeline per area:** (1) modern-stack research (Dart MCP→Context7→WebSearch — libraries ONLY, never Spoke behavior per ADR-0048); (2) **dump-first baseline** of ONLY that area (MASTER-TABLE+amendments → jadx deep-grep → runtime confirm SÓ do `Precisa-runtime`; rewritten 2026-06-11 per ADR-0045/0048/0049 — was "fresh LIVE dump"); (3) implement TDD; (4) harness validation gates; (5) harness-current at end. | The dump-first baseline per area is the direct cure for the MS4/MS5 stale-baseline failures AND the ADR-0041..0044 inference cycle. |
| Q4 | Areas with NO Spoke baseline | **Área 1 (auth leftovers) + Área 11 (notifications): NO `spoke-parity-checker` dispatch.** They have no Spoke equivalent — Área 1 keeps our existing screens (directive #8), Área 11 is derived from directive #9 + the Slice-3 FCM plan. Spec them as declared-inference, not parity. | Dispatching parity-checker on a non-existent baseline wastes a cycle and invites inventing "parity" (a logged anti-pattern). |
| Q5 | `integration_test/` (absent today) | **Hard per-area gate.** The FIRST authored test is `area5_route_details_flow_test.dart` (Área 5 MS9). Every subsequent area touching navigation adds its own `integration_test` task BEFORE its green commit. | Memory `lesson_slice_checklist_integration_test_gate`; widget tests can't catch GoRouter branch-stack/Android-back. Dir is absent despite 4+ nav-touching areas. |
| Q6 | 23 pre-existing analyze lints | **Dedicated burn-down MS before the slice PR** (read each, fix root cause, never `// ignore:`). The Slice-2 "Done" gate requires analyze clean. | The slice can't close its own gate (roadmap line) while 23 lints persist; deferring them indefinitely is the debt this sprint exists to avoid. |
| Q7 | Post-cutoff Flutter 3.44 APIs | **Embed the 3 breaking changes into the relevant area MS** + a standing "verify against Dart MCP, not memory" rule: `onReorderItem` (Á7), `RadioGroup<T>` (Á10/11), sealed `AsyncValue` switch (Á7/8/9). | An implementer with a Jan-2026 cutoff WILL emit the deprecated idioms; `riverpod_lint`/`flutter_lints` flag them mid-MS. Pre-empt at spec time. |
| Q8 | B2B-adjacent widgets (4 flags) | **Keep cut/postponed per inventory markers + §7.1:** Á7 "Compartilhar rota em tempo real" (customer live-tracking) + Á9 "Compartilhar cópia da rota"/"Transferir paradas" (peer transfer) = OUT/postponed; Á11 "Atualização de status" must be confirmed self-notification (B2C), not customer-notification (B2B). | The boundary doc (`2026-06-06-spoke-b2c-vs-b2b-boundary.md`) doesn't exist yet (it's a deliverable of the restructure sprint); until then, cut decisions use inventory markers. None of these blocks Slice 2 (all already out/postponed). |

## Goals (acceptance for this slice)

A real Samsung M54 install of `v1.1.0`, against production API (paywall bypassed in Slice 2 per roadmap), can complete the full Spoke-equivalent rider flow:

1. **Auth:** open `/auth/forgot-password`, enter email, tap "Enviar link" (UI only — backend Slice 3); see "Continuar com Google" on login/register.
2. **Create + configure route:** create a route (Área 2 ✅), open Detalhes da rota, set Partida/Destino/Pausa (Área 5 complete), tap Concluído.
3. **Add + edit stops:** add a stop via text (Área 4 ✅), tap the stop card → edit-stop sheet (Área 6) opens, change color/packages/order/type/notes, tap Concluído.
4. **Optimize:** tap "Otimizar rota" (Área 3 trigger wired) → see the 3 FTUE modals once → PRE-CONFIRM state (map + polyline + summary + A1/A2 chips) → Confirmar → Ready-to-Run.
5. **Deliver:** tap "Iniciar rota" → Modo Delivery (Área 8): map follows, mark stops Entregue/Não entregue/Coletado with auto-advance, reach "Destino final".
6. **Complete:** see "Rota concluída!" (Área 9) with summary + "Copiar paradas para nova rota".
7. **Settings:** open Settings (Área 10), change nav app / vehicle / stop side, open Notificações (Área 11) and toggle the 3 switches, tap Sair.
8. **Quality:** `flutter analyze` clean (23 cleared); `flutter test` ≥ 249 (higher with new area tests); `apps/mobile/integration_test/` exists and the Área 5 5-route Android-back chain passes on M54; backend `bun run typecheck` clean.

### Non-goals (explicit, to keep scope tight)

- **Backend real** (solver, geocoding, persistence, FCM) — Slice 3. Slice 2 keeps stubs/mocks where the roadmap says.
- **Paywall** — Slice 4 (the "Navegar" trigger is wired as a checkpoint but bypassed in Slice 2).
- **Sentido casa / LGPD / Admin** — Slices 5/6/7.
- **OUT-OF-SCOPE M2 widgets:** Load vehicle, customer live-tracking, peer route/stop transfer (Á7/Á9 — kept cut).
- **OCR/Voz/tap-map multi-method** beyond the single-stop stubs the roadmap scopes.
- **Polish visual final** (microcopy PT-BR, decorative) — post-Slice-7.

## Architecture (sprint structure, not code)

No new module. One microsprint per area, each self-contained. The plan details each MS; the architecture here is the **per-area pipeline** every MS runs:

### The mandatory per-area pipeline (Eduardo's discipline, encoded)

```
Phase 1 — MODERN-STACK RESEARCH (before any code)
  Dart MCP (installed pkg symbols) → Context7 (/websites/flutter_dev, /rrousselgit/riverpod,
  /websites/pub_dev_google_maps_flutter) → WebSearch (post-cutoff release notes).
  Output: the current 3.44 idiom for each widget/pattern the area needs + cited source + gotcha.
  MUST catch the 3 post-cutoff breaking changes where applicable.

Phase 2 — DUMP-FIRST BASELINE (ONLY this area)  [SKIP for Áreas 1, 11 — no Spoke baseline]
  [REWRITTEN 2026-06-11 per ADR-0045/0048/0049 — was "fresh live Spoke dump"; the static
   deep-grep SUPERSEDES the live dump wherever it resolves the question (MS-A6 precedent).]
  (a) READ docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md rows + dated Amendments for the
      area; (b) for behavior/gating the table doesn't carry, GREP ~/spoke-dump/jadx-out
      (decompiled code answers click handlers, branches, defaults with file:line evidence)
      + res-decoded strings; (c) ONLY for items still flagged Precisa-runtime, dispatch
      spoke-parity-checker to runtime-confirm (M54 connected + Spoke logged in; Maestro MCP
      inspect_screen + take_screenshot; screenshot PIXELS cited for every icon claim — XML is
      blind to Compose icons). NEVER WebSearch for Spoke behavior (ADR-0048).
  Output: facts table with evidence (file:line or bounds), e.g. a *-design.md doc.
  If the dump/runtime contradicts the roadmap/inventory STRUCTURALLY → escalate to Eduardo
  (new ADR if it changes widget shape / nav model / state model) BEFORE implementing. This is
  the cure for MS4/MS5 AND the ADR-0041..0044 cycle. A prior /tmp capture is corroboration
  ONLY, never the primary truth.

Phase 3 — IMPLEMENT (TDD, Spoke-faithful, zero debt)
  flutter-test-author (optional) writes failing test first. Implement with the 3.44 idioms from
  Phase 1 + the Spoke shape from Phase 2. Every divergence → code change + paired test assertion.
  No silent onTap, AsyncValue 3-state, ListView.builder, no dead-end flow. Surgical scope:
  git diff shows ONLY the area's files + app.dart if nav touched.

Phase 4 — HARNESS VALIDATION GATES (before declaring the area done)
  flutter analyze clean (scope) · flutter test ≥ baseline · bun typecheck (if backend) ·
  integration_test/ on M54 if nav touched · spoke-parity-checker D4 (must-fix blocks) ·
  flutter-perf-auditor sweep · adr-guardian if stack touched · smoke E2E release on M54.
  Mechanical gate-check: All tests passed (exact count) + No issues found + git diff scope +
  no TODO/FIXME/// MS in diff + every divergence traced to code AND test.

Phase 5 — HARNESS CURRENT (end of area)
  Update TODO.md inline · roadmap status mark · CHANGELOG inline · session log if non-obvious ·
  git push · checkpoint (the 3 deterministic actions). Commit/push only when Eduardo asks.
```

### Dependency graph (the order is not free)

```
Área 5 MS6→MS9  +  Área 3 triggers (Otimizar CTA / stop-card tap / kebab)
        │  must finish first — they are the triggers 6/7/9 depend on
        ▼
   Área 6 ─► Área 7 ─► Área 8 ─► Área 9   (delivery chain, strictly sequential)

   Área 1 (auth UI)  ─ independent, no Spoke baseline
   Área 10 ─► Área 11  (Notificações row lives inside Settings; no Spoke baseline for 11)
```

### Architecture principles

1. **Spoke shape over inferred shape.** Phase 2's live dump is the contract; the roadmap/inventory are paraphrase. If they conflict, the dump wins and the inventory is amended in the same commit.
2. **3.44 idioms over memory idioms.** Verify every widget API against Dart MCP; the installed toolchain is newer than the assistant's cutoff.
3. **Zero debt per area.** A divergence is fixed in its area's MS or escalated as BLOCKED — never deferred with a marker.
4. **Map + drag = Column, never Stack.** Every map-hosting screen (Á8) uses `Column { Expanded(map), sheet }`.
5. **Sheets that navigate return an intent.** `pop(enum)` + parent pushes (Flutter #155746).
6. **No Spoke baseline → no parity-checker** (Áreas 1, 11) — declared inference instead.

## Data flow

Per-area; detailed in the plan. The cross-cutting flows the sprint must respect:

- **Edit-stop (Á6):** tap stop card (Á3 trigger) → `DraggableScrollableSheet` over the shared `/home/routes/add-stop` route → Concluído pops + saves. "Mudar endereço" re-enters Á4 add-stop (inherits live Places key).
- **Optimize (Á7):** "Otimizar rota" (Á3) → AsyncNotifier `run()` → 3-state AsyncValue → FTUE flags in SharedPrefsAsync → Confirmar locks IDs (`Route.confirmedAt`) → "Iniciar rota" → Á8.
- **Delivery (Á8):** per-stop focus; status buttons → `AsyncValue.guard` mutation → auto-advance; "Navegar" → `url_launcher` geo: URI (paywall checkpoint, bypassed Slice 2).
- **Settings (Á10) → Notifications (Á11):** Settings ListView row → `/settings/notifications` → 3 toggles in SharedPrefsAsync.

## Sub-slice plan (one microsprint per area)

| MS | Area | Spoke baseline? | Key 3.44 idiom | integration_test? |
|---|---|---|---|---|
| MS-A5.6 ✅ | Área 5 Pausa (page, ADR-0044) | yes — live dump found window+page, NOT sheet/chips | reused numpad + minutes dialog | — |
| MS-A5.7 | Área 5 wire Á3 rows | yes (re-confirm rows) | — | yes (rows nav) |
| MS-A5.8 | Área 5 persistence+FTUE | yes (re-confirm Q8 default) | SharedPreferencesAsync | — |
| MS-A5.9 | Área 5 integration_test+D4+PR | D4 closing | — | **yes (5-route chain — FIRST authored)** |
| MS-A3 | Área 3 triggers (Otimizar/tap/kebab) | yes (re-confirm) | — | yes (nav) |
| MS-A6 | Área 6 Editar parada | yes (live dump, 14 fields) | showModalBottomSheet + SegmentedButton | yes (sheet nav) |
| MS-A7 | Área 7 Otimizar | yes (live dump 3 states + 3 FTUE) | onReorderItem + sealed AsyncValue | yes (state nav) |
| MS-A8 | Área 8 Modo Delivery | yes (live dump status states) | AsyncValue.guard + map-follow Column | yes (handoff nav) |
| MS-A9 | Área 9 Conclusão + core | yes (live dump completion) | onReorderItem (reorder) | yes (wizard reuse) |
| MS-A10 | Área 10 Settings | yes (live dump, pickers inferred) | RadioGroup<T> | yes (settings route) |
| MS-A11 | Área 11 Notifications | **NO** (original UI) | RadioGroup<T> / SwitchListTile | yes (route) |
| MS-A1 | Área 1 auth UI | **NO** (keep our screens) | — | yes (route) |
| MS-DEBT | 23 analyze lints burn-down | — | — | — |

**Post-area:** integration branch merge + slice PR `feat/m2-slice-2-spoke-clone` → tag `v1.1.0`.

## Libraries

No NEW runtime dependency expected — every area is buildable with the locked stack (Material 3 + Riverpod 3 + go_router + google_maps_flutter + url_launcher). If any area's live research surfaces a genuine need (e.g. a chip/wheel package), it requires an ADR per stack-lock and a Context7 query in that MS — do NOT add silently. Existing area-4 deps (speech_to_text, google_mlkit_text_recognition) belong to the OCR/Voz PRs, out of this sprint's core scope.

## ADRs filed during this sprint

- Only if a live Spoke dump surfaces a **structural surprise** (widget shape / nav model / state model / persistence model mismatch) — then a new ADR per the MS4/MS5 precedent (ADR-0042, ADR-0043). Expected: 0–2. Each area MS carries the instruction to file one on first structural surprise, not defer.
- No per-screen ADR otherwise (Spoke is the spec, per ADR-0035/0036).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Stale-baseline failure recurs (MS4/MS5)** | Phase 2 mandatory per area: fresh live dump of ONLY that area, screenshot pixels for icons, escalate structural surprise BEFORE implementing. Prior /tmp = corroboration only. |
| **Implementer emits deprecated 3.44 idioms** | Q7 embeds the 3 breaking changes per area + "verify against Dart MCP not memory"; `riverpod_lint`/`flutter_lints` catch at pre-commit. |
| **GoogleMap eats the drag (Á8)** | Principle #4: `Column { Expanded(map), sheet }`, never Stack. Logged lesson. |
| **Sheet navigation silently no-ops (Á6)** | Principle #5: return-intent pattern, `useRootNavigator:true`. Flutter #155746. |
| **Building 6/7/9 on un-wired Á3 triggers** | Order (Q2) finishes Á3 triggers + Á5 first; the plan gates 6/7/9 on them. |
| **integration_test slips again (deferred since MS5)** | Q5: Á5 MS9 authors the FIRST test as a hard gate; every nav-touching area MS includes its own. |
| **Slice can't close (23 lints)** | Q6: dedicated MS-DEBT before the slice PR. |
| **Inventing "parity" for Áreas 1/11** | Q4: no parity-checker for them; spec as declared inference; confirm Á11 "Atualização de status" semantics with Eduardo. |
| **Workflow auto-fixes destroy cross-scope code** | After any workflow: `git status` + `git diff HEAD --stat` BEFORE staging (logged lesson). |
| **Multi-session context loss** | Each MS self-contained with its own gates + handoff note; roadmap + this spec are the durable anchors. |

## Accessibility (Karpathy 3 minimum — per new screen)

Every new screen this sprint ships must clear, before its area closes:

1. **Semantics labels on every primary CTA + interactive icon** (also enables Maestro `tapOn:{id}` — the logged ListTile-tap fix). Á6 Concluído, Á7 Confirmar/Iniciar, Á8 status buttons, Á10 rows.
2. **Tap targets ≥ 48×48 dp** — segmented buttons, switches, icon buttons.
3. **WCAG-AA contrast against `prototipo/tokens.js`** — destructive red (Remover/Sair), status colors (pending/delivered/failed markers).

## Test strategy

| Layer | Tool | Coverage |
|---|---|---|
| Modern-stack | Dart MCP + Context7 | per-area idiom verification (Phase 1) |
| Spoke parity | `spoke-parity-checker` (dump-first; runtime só `Precisa-runtime`; D4 **dump-only** per ADR-0049, dispatched via `/verify-slice`) | upfront confirm + D4 closing (NOT Áreas 1/11) |
| Unit/widget | `flutter test` | each new widget/provider; assert Spoke shape + behavior (tap/callback/state), never tautological |
| Integration | `integration_test/` on M54 | every nav-touching area; Á5 5-route chain is the first |
| Perf | `flutter-perf-auditor` | per screen before PR (9-check) |
| Static | `flutter analyze` / `bun typecheck` | clean per area; 23 lints burned down in MS-DEBT |
| Smoke E2E | release build on M54 | golden path per area against prod API |

**Tech debt explicit (added to `TODO.md`):**

- *2026-06-06:* §13.C.4 (Refinar CTA) + §13.C.5 (peer-transfer semantics) remain PENDING — drilled opportunistically in Á7/Á9 MS; if live inspection is impractical, the documented fallback is chosen as an explicit scoped decision.
- *2026-06-06:* Á6 "Mudar endereço" inherits a live Google Places key requirement for its integration_test/smoke.

## Verification gates (per `M2-SLICE-CHECKLIST.md`, per area + slice close)

Per area: analyze clean (scope) · test ≥ baseline · integration_test on M54 if nav touched · spoke-parity D4 (must-fix blocks; NOT Á1/Á11) · perf-auditor · adr-guardian if stack touched · smoke E2E.

To close Slice 2:

- [ ] All Áreas 1–11 complete; roadmap marks each ✅.
- [ ] `flutter analyze` clean (23 cleared, none suppressed).
- [ ] `flutter test` ≥ 249 (+ new area tests).
- [ ] `apps/mobile/integration_test/` exists; Á5 5-route Android-back chain passes on M54.
- [ ] `bun run typecheck` clean.
- [ ] Smoke E2E golden path (§Goals 1–7) completes on M54 release build.
- [ ] `prototype-fidelity-checker` deferred to final polish (not now).
- [ ] PR `feat/m2-slice-2-spoke-clone` → tag `v1.1.0`.

## Bad practices — the NEVER-AGAIN list (distilled from 33 deduped anti-patterns)

These were already committed and cost real rework. The plan embeds the rule into the relevant area MS; here is the catalogue, ranked by recurrence + cost.

### Tier 1 — Spoke-baseline trust (the #1 recurring failure, 3 incidents)

1. **Never trust a prior-session Spoke baseline.** MS4 cited a 0-byte PNG (→ wheel_picker, ADR-0041 wrong); MS5 cited a mislabeled 119KB PNG (→ full-screen radio, wrong — was actually the numpad). Both passed a non-zero-byte check yet were wrong. **Rule:** re-inspect the named widget LIVE on M54 at implementation time; prior capture is corroboration only. Order: map → live-inspect → implement → validate. Structural contradiction → escalate (new ADR) before implementing.
2. **uiautomator/XML cannot confirm icon absence in a Compose app.** Spoke is Compose; ImageVectors emit no accessibility nodes. A D4 report inferred "icon-free" from XML → removed 4 leading icons → 3 divergences in PR #24. **Rule:** capture BOTH dump.xml AND screencap PNG; cite screenshot PIXELS for every icon claim. XML-only evidence is low-confidence; re-dispatch.
3. **Don't write a spec from inventory paraphrase without a live dump.** "Hamburger no header" + "drawer 90%" → built a Material Drawer; live Spoke was a floating IconButton + a ModalBottomSheet. Full RouteShellPage rework. **Rule:** "Inventário descreve, Spoke decide. Sem dump, sem spec."

### Tier 2 — This-stack nav/gesture silent failures

4. **Never overlay a draggable widget on GoogleMap in a Stack** — the PlatformView's EagerGestureRecognizer wins every drag arena (swipe does nothing). **Rule:** `Column { Expanded(GoogleMap), sheet }`; the map resizes (Á8).
5. **Never `context.push` from inside a `showModalBottomSheet` body** on a nested branch route — silent no-op (Flutter #155746). **Rule:** sheet pops an intent enum; parent pushes; `useRootNavigator:true` (Á6).
6. **snap-to-nearest on a non-equidistant multi-state sheet feels broken** (mid→expanded unreachable by flick). **Rule:** direction-based snap, threshold 50 px/s.
7. **Maestro `tapOn` by text hits the inner TextView, not the clickable ListTile parent** — logs "COMPLETED" but callback never fires. **Rule:** `Semantics(identifier:)` in production + `tapOn:{id}` in YAML, OR scope YAML to visibility-only.
8. **Android `back` is context-dependent** — chaining `hideKeyboard + back` closes the screen. **Rule:** one or the other, never both. Don't overload one gesture for two meanings.

### Tier 3 — Dart/Riverpod correctness footguns

9. **`copyWith(x: x ?? this.x)` on a nullable field silently preserves instead of clears.** **Rule:** build the entity manually or use an `_omit` sentinel; add a `copyWith(x:null)` clears-it test.
10. **Mutating a Riverpod notifier in build/initState throws (Riverpod 3).** **Rule:** hydrate inside `addPostFrameCallback` with a mounted guard; parameterize create/edit by GoRouter path param + nullable arg, not `extra`.
11. **Bare `catch(_)` that degrades to a default with no log** makes a real bug indistinguishable from corruption. **Rule:** at minimum `debugPrint` (or narrow the catch); test the sentinel clear-path so it doesn't rot.
12. **Don't infer a Material-3 disabled/affordance state Spoke doesn't have** — the "Concluído" button disabled itself on the happy path. **Rule:** affordance = what Spoke renders; keep validity providers in the domain for the solver but don't let them gate UI.

### Tier 4 — Workflow/process gates (controller-side; the subagent never sees memory)

13. **After ANY workflow / 3+ agent dispatches:** run `git status` + `git diff HEAD --stat` BEFORE staging — a reviewer subagent once staged a full MS3 reversion invisibly. Trigger: "Workflow returned" → those two commands next.
14. **Multi-phase workflows MUST gate phase N+1 on a `shouldHaltForEduardo` boolean** in phase N's schema — MS4's research said STOP and the implementer fired anyway. Auto-mode does not override a halt.
15. **2+ same-kind failures in one MS → STOP and escalate**, don't try a 3rd variant. A clarifying question is cheaper than an hour of loops.
16. **Never declare an MS done without the mechanical gate-check:** All tests passed (exact count) + No issues found (scope) + git diff scope-only + no TODO/FIXME/// MS in diff + every divergence → code AND test.
17. **A Workflow `filesToTouch` allowlist MUST include the route file (`app.dart`)** for any nav-touching feature — MS5 halted because it was omitted. Trace every navigation to its registration site.
18. **Omitting an `integration_test/` task for a nav-touching MS** — widget tests can't catch GoRouter branch-stack/Android-back. Grep the spec for nav expressions; if any, add the integration_test task.
19. **Skipping the inter-MS checkpoint** (push + TODO + session log) — run the 3 deterministic actions the moment both reviews pass.

### Tier 5 — Spec/doc hygiene + parity honesty

20. **Spoke wins over the spec.** If Spoke disagrees, Spoke is canonical and the spec is corrected in the SAME commit — no "implementei como o spec falou". Dispatch parity-checker every MS, not just D4. ZERO deferred divergences.
21. **Never invent microcopy and label it "Spoke parity."** Per ADR-0035 write ORIGINAL PT-BR; don't clone Circuit verbatim; tests cite the capture, not a literal the widget was just coded with.
22. **When an architectural decision changes (wheel→numpad) or a file moves (app_router→app.dart), sweep the WHOLE spec+plan+Goals+Risks in the same edit** — stale refs mislead the next MS. Run docs-lint.
23. **Don't reference numbered divergences (#N) in code unless that numbering is canonical in an ADR**; the table must mirror the code's #N exactly.
24. **Update docstrings in the same edit as the behavior change**; a docstring describing behavior the code doesn't have is a defect.
25. **TDD red-step stub bodies are ALWAYS `throw UnimplementedError()`** — even for trivial-constant spec values (the block-test-author-impl hook enforces).
26. **`flutter run --release` on a device REQUIRES `--dart-define`** (API_BASE_URL + APP_ENV) or it silently hits emulator loopback. Prefer `build-release-apk.sh`.
27. **Address matchers/regex must cover both `Av.` and `Avenida`, lowercase, and DOTALL `(?s)`** for Android content-desc.
28. **Maestro creds via `${MAESTRO_EMAIL}` env, never embedded** — embedded creds fail silently at the first post-login assertion.
29. **No throwaway capture harnesses / temp debug nav for per-MS pixel checks** — validate structural parity via upfront live inspection + widget-test assertions; reserve pixel side-by-side for the D4 Maestro YAML.
30. **prototipo/ is visual-only.** Never file a "deviation from prototype" ADR for a UX/structural choice (closed by ADR-0035); the prototype-fidelity-checker only checks visual tokens.

## References

- `docs/08-ROADMAP-v2.md` — Slice 2 section (clean rewrite 2026-06-06) — the canonical scope.
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — §10/§11/§12/§13 per area; §7.1 directives.
- `docs/M2-SLICE-CHECKLIST.md` — the gates this sprint's pipeline embeds.
- `CLAUDE.md` — operating manual, Karpathy 4, Context7/Dart-MCP precedence, harness pipeline.
- `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` — source of several Tier-5 anti-patterns.
- `docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md` — the complementary restructure (boundary doc, generalized workflow, contract).
- `.claude/workflows/area5-microsprint.js` (→ `spoke-microsprint.js` after restructure) — the halt-gated dispatch template each area MS can use.
- Memory: `feedback_spoke_evidence_per_ms`, `feedback_spoke_parity_zero_debt_per_ms`, `feedback_escalate_recurring_and_gate_check`, `feedback_spec_baseline_and_workflow_halt`, `lesson_slice_checklist_integration_test_gate`, `lesson_googlemap_eats_gestures_use_column`, `lesson_showmodalbottomsheet_returns_intent_pattern`, `lesson_direction_based_snap_for_sheet`, `lesson_copywith_nullable_field_pitfall`, `lesson_wizard_parameterized_by_gorouter_pathparam`, `lesson_maestro_flutter_listtile_tap_needs_semantics`, `lesson_uiautomator_blindspot_compose_imagevectors`, `lesson_git_diff_head_before_commit_after_workflows`, `project_spoke_b2c_vs_b2b_boundary`, `project_device_is_m54`.
- Context7 (queried 2026-06-06): `/websites/flutter_dev` (showModalBottomSheet, DraggableScrollableSheet, SegmentedButton, ReorderableListView onReorderItem, RadioGroup, Material 3 migration), `/rrousselgit/riverpod` v3.0.2 (AsyncNotifier, sealed AsyncValue, AsyncValue.guard), `/websites/pub_dev_google_maps_flutter` (animateCamera, live following).
- Toolchain verified: Flutter 3.44.0 / Dart 3.12.0 (post-cutoff; the 3 breaking changes are live).
