# ADR-0044: Pausa = full-screen "Configure a pausa" page; BreakConfig is a time WINDOW + duration

- **Status:** Accepted
- **Date:** 2026-06-09
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0036 (parity gates), ADR-0037 (Maestro MCP), ADR-0042 (numpad — reused verbatim here for the time fields), ADR-0043 (Destino — the immediately prior inference-vs-measurement correction; same failure mode, same cure)

## Context

The Area-5 break scheduler (MS-A5.6) was the next step after Partida/Destino. The plan (`docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.6) and the inventory described the Pausa picker as a **bottom sheet** — *"tap 'Adicionar pausa' → capture the picker: horário field + duração options 15/30/60/custom"* — and the file was pre-named `break_scheduler_sheet.dart` with a "returns-intent" sheet contract. The domain shipped (in an earlier MS) a `BreakConfig { TimeOfDay startTime; int durationMinutes }` — a **single** break time.

**None of that was ever measured against live Spoke.** The inventory itself flags the gap explicitly: `docs/inventory/2026-05-26-spoke-vs-rotpro.md:1823` — *"Detalhes da rota — Adicionar pausa picker | Não drilled"*. The single-time `BreakConfig` shape and the "duration chips 15/30/60" assumption were inferences carried forward from the same un-drilled baseline — the identical failure mode ADR-0042 (numpad) and ADR-0043 (Destino) corrected on the two prior sub-pickers.

A fresh live inspection on the Samsung M54 (`RQCW401G33T`) via Maestro MCP on 2026-06-09 (`launchApp` → tap into "Detalhes da rota" → tap "Adicionar pausa" → `inspect_screen` + `take_screenshot` at every state) captured the real picker. The verbatim hierarchy + bounds + the screenshot-pixel icon claims are recorded at `/tmp/spoke-a56-pausa-inspection/EVIDENCE.md` (`inspect_screen` JSON quoted verbatim, viewport 1080×2400).

**What Spoke actually renders.** Tapping "Adicionar pausa" pushes a **full-screen page**, NOT a bottom sheet:

- Top-left is a **back arrow `←`** (a11y "Voltar"); the screen is a routed page popped by system Back. **No X, no drag handle, no scrim over a parent.**
- Title **"Configure a pausa"** (`[45,250][547,326]`) + subtitle **"Planeje suas pausas no Spoke para ter estimativas mais precisas de paradas e duração da rota."** (`[45,326][1035,520]`).
- Section 1 label **"Quando deseja fazer a pausa?"** (`[45,659][666,717]`), then **TWO time fields** forming a **window**: **"Entre 08:00"** (`[158,769][574,904]`, text "08:00") and **"E 15:00"** (`[619,769][1035,904]`, text "15:00"). The "Entre"/"E" labels are OutlinedTextField-style Compose decorations; a leading clock icon sits left of the pair (screenshot pixels).
- Section 2 label **"Qual será a duração da pausa?"** (`[45,967][680,1025]`), then a **full-width field** showing **"Padrão (30 min)"** (`[158,1077][1035,1212]`) with floating label "Duração da pausa" and a leading stopwatch icon (screenshot pixels).
- A full-width **"Adicionar pausa"** button pinned at the bottom (`[45,2062][1035,2220]`).

Tapping a **time field** opens `com.underwood.route_optimiser:id/bsp_time_picker` — the **identical numpad** used by the Partida/Destino rows (same `bsp_input_time` header, `bsp_text0..11` keys `1-9`/`:00`/`0`/`:30`, `bsp_ok_button` FAB, `bsp_backspace`). The "Entre" field's header copy is **"Definir primeiro horário"** — the same string our existing `_onTapPartidaInicio` already uses. Our `TimePickerSheet` (ADR-0042) is a faithful replica of this exact widget; the break time fields reuse it with no new code.

Tapping the **duration field** opens a Material `AlertDialog`: title **"Duração da pausa (minutos)"**, an `EditText` pre-filled with **"30"** (numeric keyboard), a **"Definir"** confirm button, and a **"Cancelar"** text button. The duration is therefore an **arbitrary integer of minutes (default 30)**, NOT a fixed enum of 15/30/60 chips. "Padrão (30 min)" is just how the default value 30 renders in the field.

**The domain↔Spoke mismatch this surfaced.** The shipped `BreakConfig` modelled a break as a single `startTime`. Spoke models it as a **time window** (`from`/`to`, default 08:00–15:00) plus a duration — semantically "take a 30-minute break sometime between 08:00 and 15:00", which the solver places. A single `startTime` cannot express that window. This is a structural state-model mismatch with a persistence ripple (`BreakConfig` is serialized into the `route_defaults_v1` SharedPreferences envelope), so per `feedback_spec_baseline_and_workflow_halt` Rule 3 (first-time architectural surprise = escalate, not implement-and-flag-later) it was escalated to Eduardo **before any code was written**. Eduardo's decision (2026-06-09): *"Siga o recomendado e as boas práticas igual o spoke."* — match Spoke fully (window model + ADR + full-screen page).

## Decision

**1. Widget shape: full-screen routed page, not a sheet.** MS-A5.6 implements the picker as a pushed `GoRoute` (`break-scheduler`) under the existing `routes/active/:routeId/details` route, mirroring the Partida `start-location` sub-route already registered in `app.dart`. The page (`break_scheduler_page.dart`, NOT `..._sheet.dart`) returns the chosen `BreakConfig` via `context.pop<BreakConfig>(result)`; backing out (system Back / `←`) pops `null` (cancel). The parent `RouteDetailsPage._onTapAdicionarPausa` awaits the result and, on non-null, calls `addBreak`. This replaces the interim `route_details_page.dart:290` "Pausa em breve" SnackBar.

**2. Domain aligned to Spoke's window model.** `BreakConfig` becomes:

| Old field | New field | Spoke source |
|---|---|---|
| `TimeOfDay startTime` | `TimeOfDay fromTime` | "Entre" field (default 08:00) |
| — | `TimeOfDay toTime` (new) | "E" field (default 15:00) |
| `int durationMinutes` | `int durationMinutes` (unchanged) | duration dialog (default 30) |

- Defaults the page seeds: `fromTime = 08:00`, `toTime = 15:00`, `durationMinutes = 30` — Spoke's verbatim defaults.
- The `route_config_controller` `addBreak`/`updateBreak`/`removeBreak` signatures are unchanged (they take/hold a `BreakConfig`); only the value's shape changes.
- `_pausaSection` in `route_details_page.dart` renders each existing break as the window range (e.g. `08:00–15:00 • 30min`) instead of the old single-time string.

**3. Persistence (`route_defaults_v1`) JSON arms change in the same commit.** The break entry JSON moves from `{startTime, durationMinutes}` to `{fromTime, toTime, durationMinutes}`. Since no production install has persisted a break yet (Area 5 is unshipped), no migration path is required: a legacy `{startTime,...}` entry encountered in a corrupted/hand-edited envelope fails `_breaksFromJson`'s shape check (`FormatException`), which `RouteDefaults.fromJson`'s caller already catches and degrades to `RouteDefaults.empty()` (bare-catch logged via `debugPrint`, anti-pattern #11 respected). The envelope `schemaVersion` stays `1` — the envelope contract (which top-level keys exist) is unchanged; only a nested sub-shape is corrected before it ever shipped.

**4. Duration is a free integer, not an enum.** The duration field opens a numeric-input `AlertDialog` (default 30), exactly like Spoke. No `ChoiceChip`/`SegmentedButton` set of 15/30/60 — that was an inference the live capture refuted. Phase-1 research (Dart MCP + Context7, 2026-06-09, `/tmp/spoke-a56-pausa-inspection/phase1-research-findings.json`) had surfaced the chip idioms but they do not apply once the measured UI is a free-text minutes input. Minutes are validated `> 0` on confirm (a zero/negative break is meaningless — the only affordance gate, mirroring the `RouteConfig.isValid` solver-window rule, not a Spoke-invisible disable).

## Consequences

- **Positive (parity):** Spoke 1:1 on the Pausa surface — full-screen page, back-arrow nav, "Configure a pausa" title + subtitle, the from/to window with the reused numpad, the minutes dialog, the pinned "Adicionar pausa" CTA, and the exact 08:00/15:00/30 defaults.
- **Positive (numpad reuse):** the two time fields reuse the shipped `TimePickerSheet` (ADR-0042) and its `_showTimePicker` launcher verbatim — zero new time-picker code, and the "Definir primeiro horário" header string already matches.
- **Positive (domain honesty):** the break domain now expresses what a rider can actually configure (a window, not a point), aligning the Slice-3 solver contract before the backend table is built.
- **Negative (test churn):** ~10 existing assertions across `route_config_test.dart`, `route_config_controller_test.dart`, `route_defaults_test.dart`, `route_defaults_controller_test.dart`, `route_defaults_repository_test.dart` reference `BreakConfig(startTime:...)` and must move to `fromTime/toTime`. In-scope for this MS (the change is what makes the domain correct), not deferred debt. `git diff` scope therefore legitimately includes `domain/route_config.dart`, `domain/route_defaults.dart`, the controller, the details page, `app.dart`, and their test files — wider than the plan's original MS-A5.6 file list.
- **Negative (file rename vs plan):** the plan named `break_scheduler_sheet.dart`; the shipped file is `break_scheduler_page.dart`. The plan + roadmap wording is corrected in the same commit set (anti-pattern #22 — sweep the docs when a decision moves a file/shape).

## Alternatives considered

1. **Keep the single-time `BreakConfig` + build a simpler one-time picker.** Rejected — directly contradicts ADR-0035 (Spoke canonical for behavior) and Eduardo's standing `feedback_spoke_parity_zero_debt_per_ms` directive. The live capture shows a window; a single time cannot represent it.
2. **Build a bottom sheet (keep the plan's name/surface) for speed.** Rejected by Eduardo (2026-06-09) — Spoke's Pausa picker is a routed full-screen page (back arrow + pinned CTA), not a modal. A sheet would be a structural divergence on the very surface the 5-phase pipeline exists to keep faithful.
3. **Duration as 15/30/60/custom chips (the plan's assumption).** Rejected — refuted by the live capture (a free-text minutes dialog). Shipping chips would invent a UI Spoke doesn't have.
4. **Defer the domain reconciliation to a later polish MS, ship the page against the old single-time type.** Rejected — explicit "defer to later MS" is exactly the anti-pattern `feedback_spoke_parity_zero_debt_per_ms` bans; the page cannot be Spoke-correct without the window, so half-shipping it is not an option.

## References

- Plan: `docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.6 (amended in the same commit set as this ADR)
- Spec: `docs/superpowers/specs/2026-06-06-slice2-completion.md` (the 5-phase pipeline whose Phase-2 halt this ADR is the product of)
- Live Spoke baseline: `/tmp/spoke-a56-pausa-inspection/EVIDENCE.md` (verbatim `inspect_screen` bounds + 3 states) + Maestro `take_screenshot` captures (2026-06-09)
- Phase-1 modern-stack research: `/tmp/spoke-a56-pausa-inspection/phase1-research-findings.json` (Dart MCP + Context7, Flutter 3.44.0)
- Reused numpad: [ADR-0042](./0042-time-picker-numpad-spoke-fidelity.md) (`bsp_time_picker` replica = `TimePickerSheet`)
- Same failure mode (un-drilled baseline corrected by live capture): [ADR-0043](./0043-destination-picker-sheet-three-state-domain.md)
- In-codebase routed-sub-picker precedent: `app.dart` `routes/active/:routeId/details/start-location`
- Inventory gap this closes: `docs/inventory/2026-05-26-spoke-vs-rotpro.md:1823` ("Adicionar pausa picker | Não drilled") — updated §16 in the same commit set
- Memory: `feedback_spoke_parity_zero_debt_per_ms`, `feedback_spec_baseline_and_workflow_halt`, `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`, `lesson_showmodalbottomsheet_returns_intent_pattern` (why a routed page is cleaner than a sheet here)
