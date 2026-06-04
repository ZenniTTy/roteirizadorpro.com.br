# Área 5 (MS1–MS5) — Retrospective Audit

> **Date:** 2026-06-03 · **Scope:** Área 5 MS1–MS5 on `feat/m2-slice-2-area-5-route-details` · **Type:** read-only punch-list (no code edited)
> **Method:** 6 parallel auditors (Spoke-parity LIVE re-inspect, harness best-practices, hallucinations/silent-failures, ADR↔code drift, test quality, Flutter perf) → adversarial verification (30 raw → 21 confirmed, 9 dropped) → synthesis.
> **Verdict:** `minor-issues` — largely clean & well-engineered; defects concentrated and fixable.
> **Raw:** `/tmp/area5-audit-raw.json` (workflow `w39xs7ic8`).

## Headline

Área 5 is solid: 50+ confirmed good practices, all 158 in-scope tests passing, **zero crash / silent-failure paths on reachable code**. The real defects are concentrated: 1 must-fix (time-picker header copy), 5 should-fix (live-clock row, Concluído gating, invented hints, inert Pausa row, doc staleness), and 8 nits. None block the slice; several are user-visible Spoke-parity misses worth fixing before MS9 PR.

---

## MUST-FIX (1)

### M1 · Time-picker sheet titles diverge from Spoke `[PARITY-1+2]`
- **File:** `route_details_page.dart:124,165`
- **What:** We pass `'Definir horário de início'` / `'Definir horário de término'`. Live Spoke (`step2-time-iniciar.xml` / `step6-time-termino.xml`) reads **`'Definir primeiro horário'` / `'Definir último horário'`**. User-visible PT-BR on the most-used time surface.
- **Fix:** Line 124 → `'Definir primeiro horário'`; line 165 → `'Definir último horário'`. Widget unchanged. Update the 2 locking tests in `route_details_page_test.dart` (~756-757, 781-782). **Do NOT touch** the Destino ROW placeholder at line 152 (`'Definir horário de término'` — that one is correct Spoke).
- **Note:** ADR-0042 line 21 used the old string only illustratively; live XML overrides it.

---

## SHOULD-FIX (5)

### S1 · `'Iniciar agora mesmo'` row missing the live current clock `[PARITY-3]`
- **File:** `route_details_page.dart:81-83`
- **What:** When `timeStart == null` we show only the static label. Live Spoke renders `'Iniciar agora mesmo'` **+ a live wall-clock** (dimmer, e.g. `01:04`, ticking). The MS4 D4 fix (`23ff0ff`) correctly collapsed the *confirmed* state to a lone `HH:MM` but dropped the *unconfigured* live-clock half.
- **Fix:** When `timeStart == null`, render label + a dimmer sibling `Text` driven by `Timer.periodic(30s)` reading `TimeOfDay.now()` (dispose the timer). Update the locking widget test (`:177-183`). Confirmed branch stays as-is.

### S2 · `'Concluído'` button wrongly gated disabled-until-both-times-set `[PARITY-4]`
- **File:** `route_details_page.dart:37,54`
- **What:** We watch `isRouteConfigValidProvider` (false when either time null) and disable the button. `RouteConfig.empty()` ships both times null → **button disabled on first open**, breaking the most common path (accept `Iniciar agora mesmo` + `Ida e volta` defaults). Live Spoke keeps Concluído **always enabled** (`step1-detalhes.xml` Button `enabled='true'` with neither time set). Root cause: spec line 126 inferred a Material-3 disabled state, conflating solver-window validation (Q10 `endTime>startTime`) with UI affordance.
- **Fix:** Always enable + always pop (delete line 37, set `enabled: true` on line 54). **Keep** `isRouteConfigValidProvider` / `RouteConfig.isValid` in the domain for the Slice-3 solver — they just must not gate this screen. Revise the 2 widget tests (`:93`, `:106`) + spec line 126.

### S3 · Invented picker hints shipping under a false "Spoke parity" comment `[PICKER-HINTS]`
- **File:** `picker_mode.dart:39,54,7-12`
- **What:** Partida/Destino pickers code `'Buscar local de partida'` / `'Buscar local de destino'`, but every live Spoke capture shows the single shared placeholder `'Insira um endereço'`. The doc comment (lines 7-12) falsely asserts the Partida picker "uses a distinct search-field placeholder" — the strings are invented, not extracted, yet labelled Spoke parity. Per ADR-0035 we must NOT clone Circuit microcopy verbatim, so the fix is an **original** shared PT-BR hint, not Spoke's literal string.
- **Fix:** One original shared hint for both modes (e.g. `'Buscar endereço'`) on lines 39+54. Delete the inaccurate "distinct placeholder" sentence. Update `add_stop_page_test.dart:343-358` + cite the capture file the expected string came from.
- **Note:** de-duped from 3 separate findings (PARITY-5, PARITY-6, HALLUC-1). Functional pipeline identical → cosmetic rider impact.

### S4 · `'Adicionar pausa'` row is inert but renders a tap chevron (broken affordance) `[PARITY-8]`
- **File:** `route_details_page.dart:253-258`
- **What:** Row built `onTap: null` (no ripple) yet `route_config_row.dart:103-107` unconditionally draws a `chevronRight` — users tap expecting action. Spoke's Pausa row IS clickable (opens a break scheduler — inventory §10.4). The full scheduler is **MS6**.
- **Fix:** Interim — make the row tappable with a stub SnackBar (`'Pausa em breve'`) until MS6 wires the real scheduler. An inert chevron row is a broken affordance.

### S5 · Doc staleness: phantom `app_router.dart` + stale "scroll wheel" copy `[HARNESS-1 + DRIFT-1+2]`
- **Files:** `spec:105` (+ 7 plan refs), `spec:55-56,180`
- **What:** (a) Spec/plan reference `app_router.dart` which **does not exist** — the router is `app.dart` (`Provider<GoRouter>` L32). The plan self-corrects once (L253) but doesn't propagate. (b) Spec Goal #10 (L55) + Risks (L180) still describe a "scroll wheel" time picker + "flick velocity test" — obsolete after the numpad pivot (contradicts the spec's own Q3 + ADR-0042). A future MS6/7/8 worker is misled on both.
- **Fix:** Doc-only. `app_router.dart` → `app.dart` across spec+plan; rewrite Goal #10 to the 4×3 numpad + reframe Risks L180 to numpad layout/FAB-enable + delete "flick velocity test".

---

## NITS (8)

- **N1 `[HALLUC-3]`** `add_stop_page_test.dart:343-358` — placeholder assertion is tautological (asserts a literal the widget was coded with); collapses once S3 is fixed. Cite the capture file like `route_details_page_test.dart:167` does.
- **N2 `[HALLUC-4]`** `route_defaults.dart:64-66` — broad `catch (_)` → `empty()` logs nothing; a real helper bug degrades identically to corruption (silent FTUE re-show, no trail). Repository layer DOES `debugPrint`; this layer should too (or narrow to `FormatException`/`TypeError`). Local-storage, non-crashing — diagnostic-only.
- **N3 `[HALLUC-5+TEST-6]`** `route_defaults_controller.dart:38-43` — `merge()` pre-coalesces (`patch.x ?? current.x`), making the `_omit` sentinel's clear-branch unreachable through `merge()`; the clear-path is untested. Latent (merge has no lib call site until MS8). Document the additive-only constraint + add a cheap `copyWith(x: null)` clear test.
- **N4 `[HALLUC-7]`** `add_stop_page.dart:166-169` — `_popWithStartLocation` docstring claims a "textual-fields fallback" the code deliberately does NOT do (it throws + SnackBars, correctly). Stale docstring only; fix the comment.
- **N5 `[DRIFT-3]`** `route_details_page.dart:284-305` (+ test `:233-428`) — comments cite "divergence #2/#3/#4/#6" that exist in no ADR/spec/plan. Code is more specific than the governing docs. Either add a divergence table to ADR-0043 §Decision 3 (parent-row icons: RoundTrip=cornerUpLeft, SpecificAddress=mapPin, NoDestination=flag) or drop the unsourced `#N` numbering.
- **N6 `[TEST-2]`** `route_details_page_test.dart:93-128` — Concluído + close-X `context.pop()` never tap-exercised (only enabled/presence asserted). Zero-logic pops; covered by MS3 round-trips + MS9 E2E. Optional 2 tests.
- **N7 `[PERF-2]`** `route_details_page.dart:60` — `_saveAsDefault` `setState` lives at page root, rebuilding the whole subtree for a checkbox flip. Negligible (one-shot tap, const-heavy leaves). Optional: extract `_SalvarComoPadraoCheckbox` as its own StatefulWidget.
- **N8 (doc gap, from deferred-debt)** — implementation ships `'Salvar como padrão'` **unchecked**, silently overriding spec Q8 (`A — Replicar 1:1 true`) without an ADR. The unchecked default matches the only verifiable returning-user Spoke evidence, but the spec-override deserves a one-line note. Worth re-confirming against a fresh Spoke account before Slice 3.

---

## GOOD PRACTICES CONFIRMED (the sequence did this RIGHT)

- **Slice structure 1:1 Spoke** — no AppBar, floating X top-left, body-level h1, full-width pinned Concluído, checkbox below; Partida/Destino/Pausa order + row structure all live-confirmed.
- **DestinationPickerSheet 1:1 Spoke** — 3 cards exact strings/subtitles/icons, "Destino" + blue "Concluído", no RadioListTile; verified across two captures.
- **TimePickerSheet faithful to ADR-0042** — 4×3 numpad, opens empty, :00/:30 gating, FAB enable rule, cross-field validation correctly delegated OUT to the provider.
- **card-2 returns-intent pattern** correctly dodges Flutter #155746 (sheet pops intent, parent pushes).
- **copyWith nullable pitfall avoided** — manual `with*` updaters + `_omit` sentinel; null-clear path tested.
- **Error surfacing exemplary** — throw + SnackBar on null place-details (no zero-pops), no force-unwraps, no reachable crash paths, no empty catches, no TODO/FIXME on Area-5 paths.
- **Clean ADR-backed stack cycle** — wheel_picker added then fully purged (pubspec + lock together), ADR-0041 Superseded, no residue.
- **Harness hygiene PASS** — zero `.g.dart` committed, 38 commits Conventional-clean, Riverpod codegen intact, JSON fields camelCase forward-compat for Slice-3.
- **Tests behavior-driven** — 158 real cases, taps target Semantics ids, icon claims cite screenshot pixels, corrupted-JSON degradation tested at both layers, autoDispose isolation asserted.
- **Zero-debt discipline visible** — ADRs document the inference-vs-measurement failure mode, file new ADRs vs deferring, MS5 scope honest (pre-declared MS1-domain touch).

## DEFERRED DEBT (legitimately tracked)

- **`integration_test/` absent** despite 4+ new GoRoutes + nested branch stack + 3 modal sheets → MS9 (TODO.md:55, spec Risks L178). **Action:** confirm MS9 actually authors `integration_test/area5_route_details_flow_test.dart` BEFORE the slice PR — the Android-back chain across 5 routes is the highest-value coverage. (de-dupes HARNESS-2 + TEST-1.)
- **Pause scheduler sheet** → MS6 (TODO.md:52). Interim inert-chevron (S4) should still be fixed now.
- **SharedPreferencesAsync persist + FTUE trigger** → MS8 (TODO.md:54). Infra built+tested; only screen-level trigger unwired.
- **`'Salvar como padrão'` checked-default** question → re-confirm vs fresh Spoke account before Slice 3 (current unchecked matches verifiable evidence; see N8).

## DROPPED (9 false positives / misreads — for transparency)

Adversarial verification killed 9 of 30 raw findings: e.g. the "Escolha o novo endereço" header is verbatim-correct Spoke (not invented); PARITY-7 checked-default rests on a single hedged inventory note; several HALLUC-5 citations of ADR-0043/spec lines were inaccurate. Full rationale in `/tmp/area5-audit-raw.json`.
