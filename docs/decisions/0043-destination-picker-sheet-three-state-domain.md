# ADR-0043: Destino picker = bottom sheet with 3 action cards; domain aligned to Spoke's 3 states

- **Status:** Accepted
- **Date:** 2026-06-03
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0010 (functional fork), ADR-0035 (Spoke white-label hierarchy), ADR-0036 (parity gates), ADR-0037 (Maestro MCP), ADR-0042 (numpad — same inference-vs-measurement failure mode this ADR also corrects)

## Context

The Area 5 spec (`docs/superpowers/specs/2026-06-02-area5-route-details.md`) locked MS5 ("Destino sub-tela") as a **full-screen page** (`DestinationPickerPage`) with **3 `RadioListTile`s** inside a Material 3 `RadioGroup<DestinationType>`, an `AppBar` with a leading **X** and a trailing **"Confirmar"** action, and a 3-option set of "Voltar ao local de início" / "Selecionar endereço" / "Ida e volta" (spec §Goals 12, MS5.1–MS5.2).

The spec cited `/tmp/spoke-a5-destino.png` as the baseline. **That file is mislabeled — it is a screenshot of the time-picker numpad, not the Destino screen.** The Destino claim was therefore an inference, not a measurement: the same failure mode ADR-0042 documented for the time picker, recurring on the very next sub-picker.

A live Spoke re-inspection on the Samsung M54 (`RQCW401G33T`) via Maestro MCP on 2026-06-03 (`inspect_screen` + `take_screenshot`) captured the real Destino picker. The structured hierarchy and screenshot are at `/tmp/spoke-a5-inspection/ms5-live-destino-hierarchy.json`, `ms5-live-destino-sheet.png`, `ms5-live-destino-clean.png`, and `ms5-live-endereco-search.png`. A second, independent stale capture (`/tmp/spoke-a5-idaevolta.xml`, 2026-06-02) corroborates the same strings — two captures agree.

**What Spoke actually renders:**

- A **bottom sheet** (`com.underwood.route_optimiser:id/design_bottom_sheet`, bounds `[0,1348][1080,2400]` on a 1080×2400 screen — bottom ~44%), with the parent "Detalhes da rota" visible through a scrim above it. **Not a full-screen page.**
- Header: title **"Destino"** (left) + a blue text button **"Concluído"** (right, `id/done`). **No "Confirmar". No X.** Dismissal is via tap-outside the scrim or the system Back button.
- Body: **3 tappable `CardView`s**, each with a leading icon + title + subtitle. **No `RadioListTile`, no radio circle, no trailing checkmark.**

| # | Title | Subtitle | Leading icon (screenshot pixels) |
|---|---|---|---|
| 1 | Voltar ao ponto de partida | Ida e volta (recomendado) | redirect/return arrow (`corner-up-left`-family) |
| 2 | Destino em outro endereço | Digite qualquer endereço | map-pin / location marker |
| 3 | Não usar destino | Não recomendado para transportadoras | X / close |

- Tapping option 2 ("Destino em outro endereço") routes to the **full-screen address search** ("Insira um endereço" search bar + scan + voice + X) — the same search pipeline as Add Stop. Confirmed live (`ms5-live-endereco-search.png`). This validates the spec's reuse intent (`AddStopPage(mode: endLocation)`), only the entry point differs (sheet card, not a routed page).

**The domain↔Spoke mismatch this surfaced.** MS1 (already shipped) modelled `Destination` as a sealed family of three types: `BackToStart`, `SpecificAddress`, `RoundTrip` — with `BackToStart` and `RoundTrip` as *distinct* types (a test even pins `RoundTrip != BackToStart`). But Spoke's UI exposes **one** "return to start" option ("Voltar ao ponto de partida" / "Ida e volta (recomendado)") — it does not distinguish "loop back" from "round trip". And Spoke has a **third state the domain lacks entirely: "Não usar destino"** (no destination). The domain's three types therefore did not map 1:1 onto Spoke's three options.

This is a structural decision with persistence ripple: `Destination` is serialized to the `route_defaults_v1` SharedPreferences JSON envelope (`{'type': 'backToStart' | 'specificAddress' | 'roundTrip'}`), whose field names are the forward-compat contract for the Slice 3 backend `RouteDefaults` table. Changing the domain changes the persisted shape and ~20 MS1 test assertions. Per `feedback_spec_baseline_and_workflow_halt` Rule 3 (first-time architectural surprise = escalate, not implement-and-flag-later), this was escalated to Eduardo before any code was written.

## Decision

**1. Widget shape: bottom sheet, not page.** MS5 implements the Destino picker as a `showModalBottomSheet<Destination>` modal, mirroring the existing `_showTimePicker` launcher in `route_details_page.dart` (the established in-codebase precedent: `isScrollControlled: true`, `useSafeArea: true`, `useRootNavigator: true`, `backgroundColor: AppColors.bg`, `barrierColor: Colors.black54`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)))`). No `GoRoute` is added for the Destino sheet. The sheet body is a `Column`: header row (`Text('Destino')` + `Spacer` + `TextButton('Concluído')`), a `Divider`, then 3 tappable cards (leading icon + title + subtitle). Dismiss = tap-outside / system Back → pops `null`. Selecting a card pops the chosen `Destination`.

**2. Domain aligned to Spoke's 3 states.** The `Destination` sealed family becomes exactly the three states Spoke exposes:

| Domain type | Sheet card title | Sheet subtitle | Icon |
|---|---|---|---|
| `RoundTrip` | Voltar ao ponto de partida | Ida e volta (recomendado) | `LucideIcons.cornerUpLeft` |
| `SpecificAddress` | Destino em outro endereço | Digite qualquer endereço | `LucideIcons.mapPin` |
| `NoDestination` (new) | Não usar destino | Não recomendado para transportadoras | `LucideIcons.x` |

- **`BackToStart` is removed.** Spoke does not distinguish "loop back" from "round trip"; the single "Voltar ao ponto de partida" option is modelled by `RoundTrip` (which is already `RouteConfig.empty()`'s default — Spoke's brand-new-route default).
- **`NoDestination` is added** for the "Não usar destino" state.
- JSON envelope type tags become `'roundTrip' | 'specificAddress' | 'noDestination'`. The `'backToStart'` tag is removed. Since no production install has yet persisted a `route_defaults_v1` envelope (Area 5 is unshipped), no migration path is required; a `'backToStart'` tag encountered in a corrupted/hand-edited envelope falls through the existing `_ => throw FormatException('unknown destination type')` arm, which `RouteDefaults.fromJson`'s caller already catches and degrades to `RouteDefaults.empty()`.

**3. Parent "Detalhes da rota" Destino row copy is unchanged.** The parent row keeps its own Spoke strings ("Ida e volta" / "Viagem de ida e volta a partir do local atual"), which differ from the sheet's option-1 copy ("Voltar ao ponto de partida" / "Ida e volta (recomendado)"). Both are Spoke facts captured live — Spoke renders the same logical `RoundTrip` state with different copy in the row vs the picker. The implementer must preserve both verbatim; they are not a contradiction to reconcile.

## Consequences

- **Positive (parity):** Spoke 1:1 on the Destino surface — sheet container, card affordance, 3 exact option strings, "Concluído" button, dismiss semantics, and the address-search reuse path.
- **Positive (domain honesty):** the sealed family now maps 1:1 onto the states a rider can actually pick. No dead `BackToStart` type lingering with no UI entry point.
- **Positive (simplicity, Karpathy 2):** no `GoRoute`, no `RadioGroup`, no external package. Reuses the proven `showModalBottomSheet` launcher pattern already in the file.
- **Negative (MS1 churn):** ~20 MS1 test assertions referencing `BackToStart` and the `RoundTrip != BackToStart` distinction must be updated/removed, and the `route_defaults.dart` JSON arms change. This is in-scope for MS5 (the change is what makes the domain correct), not deferred debt. `git diff` scope for MS5 therefore legitimately includes `domain/route_config.dart`, `domain/route_defaults.dart`, and their MS1 test files — wider than the spec's original MS5 file list.
- **Negative (scope creep vs original spec):** MS5 now touches MS1's domain. Justified: the domain was built from the same mislabeled baseline; correcting it here, with the picker that exercises it, keeps the change atomic and tested.

## Alternatives considered

1. **Keep the full-screen page + RadioListTile design from the spec.** Rejected — directly contradicts ADR-0035 (Spoke canonical for behavior) and Eduardo's standing `feedback_spoke_parity_zero_debt_per_ms` directive. Two independent captures show Spoke is a sheet with cards.
2. **Keep both `BackToStart` and `RoundTrip`, only add `NoDestination`.** Rejected by Eduardo (2026-06-03). It preserves a domain type (`BackToStart`) with no Spoke UI entry point — a "why does this exist?" smell and a latent divergence. Aligning fully to Spoke's 3 states is cleaner and removes the dead type now rather than carrying it into Slice 3's backend schema.
3. **Defer the domain reconciliation to a later polish MS, ship the picker against the existing 3 types.** Rejected — explicit "defer to later MS" is exactly the anti-pattern `feedback_spoke_parity_zero_debt_per_ms` bans. The picker cannot be Spoke-correct without the `NoDestination` state, so half-shipping it is not an option.

## References

- Spec: `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q6 row + §Goals 12 + MS5 — amended in the same commit set as this ADR)
- Plan: `docs/superpowers/plans/2026-06-02-area5-route-details.md` (Phase 5 — amended in the same commit set)
- Live Spoke baseline (sheet + cards): `/tmp/spoke-a5-inspection/ms5-live-destino-sheet.png`, `ms5-live-destino-clean.png`, `ms5-live-endereco-search.png`, `ms5-live-destino-hierarchy.json` — captured 2026-06-03 via Maestro MCP
- Corroborating stale capture: `/tmp/spoke-a5-idaevolta.xml` (2026-06-02) — same 3 strings + subtitles + header
- Same failure mode: [ADR-0042](./0042-time-picker-numpad-spoke-fidelity.md) §Context (spec drafted from inference, live inspection corrects)
- In-codebase sheet precedent: `route_details_page.dart` `_showTimePicker` launcher
- Memory: `feedback_spoke_parity_zero_debt_per_ms`, `feedback_spec_baseline_and_workflow_halt`, `lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`, `lesson_uiautomator_blindspot_compose_imagevectors`
