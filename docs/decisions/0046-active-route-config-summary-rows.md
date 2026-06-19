# ADR-0046: Active-route "Configuração de rota" summary = 2 rows that open the Detalhes page (not 3 inline rows that reopen sub-pickers)

- **Status:** Accepted
- **Date:** 2026-06-10
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0036 (parity gate), ADR-0037 (Maestro MCP), ADR-0045 (static dump baseline — dump-first), ADR-0042/0043/0044 (the Área-5 sub-pickers these rows lead into; same live-capture-beats-inference discipline)

## Context

MS-A5.7 ("wire Área 3 config rows") was the next step after the Pausa page (ADR-0044). The plan (`docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.7) and the roadmap (`docs/08-ROADMAP-v2.md:124`, `:147`) described the task as:

> *"the 3 inline config rows Início/Ida-e-volta/Pausa → clickable, reopen sub-pickers"* — making **three existing rows** in `route_shell_page.dart` tappable so each **reopens its sub-picker** (Partida / Destino / Pausa).

**Two structural facts contradict that premise** — one in our code, one in live Spoke. Both were established at the MS-A5.7 Phase-2 halt (dump-first per ADR-0045, then a fresh live dump to confirm dynamic behavior the static dump can't carry).

### Fact 1 — our code: the rows do not exist, and `RouteDetailsPage` is orphaned

`route_shell_page.dart` (the active-route screen the rider actually sees) has **no "Configuração de rota" section at all**. Its sheet body is: handle → search pill → empty-state → two big buttons ("Adicionar parada" / "Copiar paradas de uma rota anterior"). There are zero config rows to "make clickable." Separately, `RouteDetailsPage` (the full "Detalhes da rota" page built across MS1–MS6, ADR-0042/0043/0044) is registered at `routes/active/:routeId/details` in `app.dart` but **no production code pushes it** — it is reachable only from widget tests. The `app.dart:81-83` comment already anticipated this: *"opened from active-route sheet (Area 3, wired in MS7)"*. MS7 is where that entry point gets built.

### Fact 2 — live Spoke: the active-route summary is 2 rows that open the Detalhes page

Live capture on the Samsung M54 (`RQCW401G33T`) via Maestro MCP, 2026-06-10 (`/tmp/spoke-a57-config-rows-inspection/EVIDENCE.md`, viewport 1080×2400). The MASTER-TABLE (ADR-0045) does NOT cover this surface — its rows #12–#15 describe the `ui/setup` **page** (Detalhes da rota), not how the **active-route shell** re-surfaces the config. That gap is exactly what the live dump filled.

Spoke's active-route sheet (`rid="stepList"`, scrollable) hosts, above the stop list:

- A section header **"Configuração de rota"** (`[45,1616][408,1664]`).
- **Row 1 (Início)** — clickable `[0,1696][1080,1870]`: leading time badge **"1:18"**, title **"Iniciar no local atual"**, subtitle **"Use a posição do GPS ao otimizar"**, trailing **home icon** (blue, screenshot pixels).
- **Row 2 (Ida e volta)** — clickable `[0,1870][1080,2040]`: leading round-trip icon, title **"Ida e volta"**, subtitle **"Retorne ao ponto de partida"**, trailing **flag icon** (blue, screenshot pixels).
- **No Pausa row** in the summary — only **2 rows**, not 3.

Tapping either row pushes the **full "Detalhes da rota" page** (X close, body-level h1, Partida/Destino/Pausa sections, "Concluído" button + "Salvar como padrão" checkbox) — a 1:1 match to our existing `RouteDetailsPage`. The summary rows do **not** open the sub-pickers directly; they open the Detalhes page, and the Detalhes page's rows open the sub-pickers (already wired, ADR-0042/0043/0044).

A third detail: the summary rows use **different microcopy** than the Detalhes-page rows. Summary says *"Iniciar no local atual"* / *"Use a posição do GPS ao otimizar"*; the Detalhes Partida row says *"Usar local atual"* / *"Iniciar agora mesmo"*. They are distinct surfaces with distinct strings.

Per `feedback_spec_baseline_and_workflow_halt` (first-time architectural surprise = escalate before implementing), this was escalated to Eduardo **before any code was written**. Eduardo's decision (2026-06-10): **Match Spoke — build the 2-row summary; each row pushes the Detalhes page.**

## Decision

**1. MS-A5.7 creates the "Configuração de rota" section; it does not "make existing rows clickable."** `route_shell_page.dart`'s sheet body gains a new section (rendered when the sheet is medium+, alongside the existing empty-state / future stop list) containing a **"Configuração de rota"** header and **2 summary rows** built from the live `RouteConfig`:

- **Início row** — reads `routeConfigControllerProvider(routeId)`. Label = the start location (`"Iniciar no local atual"` when GPS/unset, else the chosen address). Subtitle = `"Use a posição do GPS ao otimizar"`. Trailing = the would-start time (the configured `timeStart`, else a live clock — same `LiveClockLabel` the Detalhes Partida row uses).
- **Ida-e-volta row** — label/subtitle/icon derived from `config.destination` (RoundTrip → "Ida e volta" / "Retorne ao ponto de partida").

**2. Both rows push the same Detalhes page.** `onTap` on either row → `context.push('/home/routes/active/$routeId/details')`. This is a navigation (no return value consumed — these rows mutate nothing themselves; the Detalhes page owns the mutations via its own sub-pickers). `lesson_showmodalbottomsheet_returns_intent_pattern` (returns-intent) does NOT apply here: there is no sheet and no popped result to act on — the Detalhes page writes to the shared `routeConfigControllerProvider` family directly, which the shell rows reactively re-read.

**3. `routeId` comes from the existing `activeRouteIdProvider`** (`String?`, `keepAlive`) — the same source `add_stop_page.dart:129` and `app_drawer.dart:54` already use. No new abstraction. When `activeRouteIdProvider` is `null` (no active route), the "Configuração de rota" section is **not rendered** — there is no route to configure. This keeps the existing `route_shell_page_test.dart` (which never sets an active id) green and matches the placeholder-state contract in `active_route_provider.dart`.

**4. Two rows, not three. No inline Pausa summary row.** Spoke's active-route summary shows only Início + Ida-e-volta. Pausa is reachable inside the Detalhes page ("Adicionar pausa", ADR-0044), not as a third summary row. Adding a third row would invent an affordance Spoke does not have.

**5. `Semantics(identifier:)` on each row.** Reuse `RouteConfigRow` (which already emits `route_details_row_<key>`). Keys `config_summary_inicio` and `config_summary_destino` so the future MS-A5.9 integration_test can target them without hitting inner TextViews (`lesson_maestro_flutter_listtile_tap_needs_semantics`).

## Consequences

- **Positive (parity + unblock):** Spoke 1:1 on the active-route config summary, and the previously-orphaned `RouteDetailsPage` finally has its production entry point. The whole Área-5 flow (shell → Detalhes → sub-pickers → back) becomes reachable end-to-end, which is the prerequisite for the MS-A5.9 integration_test.
- **Positive (no new state):** the summary rows are pure reads of the existing `routeConfigControllerProvider` family; the Detalhes page already owns all writes. No duplication, no sync risk.
- **Neutral (microcopy divergence is intentional):** the summary strings differ from the Detalhes strings because Spoke's do. This is faithful, not a bug — documented here so a later reviewer does not "fix" the summary to match the Detalhes wording.
- **Negative (plan/roadmap wording corrected):** the plan §MS-A5.7 and roadmap §Área 5 / §Área 3 said "3 rows → reopen sub-pickers"; both are corrected in the same commit set to "2 summary rows → push Detalhes page" (anti-pattern #22 — sweep the docs when a decision moves a shape).
- **Negative (nav touched → integration_test pressure):** these rows push a route, which per the plan's Phase-4 rule is an integration_test trigger. The first `integration_test/` is scheduled for MS-A5.9. Decision recorded in the MS (see session log): the shell→Detalhes nav is covered by a widget test using a mock navigator observer now; the device-run Android-back chain stays in MS-A5.9 where the full 5-route flow is authored, to avoid standing up `integration_test/` for a single push ahead of the slice's first real integration test.

## Alternatives considered

1. **Rows open the sub-pickers directly (the plan's literal wording).** Rejected — live Spoke opens the Detalhes page, not the sub-picker. Choosing this would be a structural divergence on the exact surface the 5-phase pipeline exists to keep faithful, and would leave `RouteDetailsPage` orphaned forever.
2. **Three rows including an inline Pausa summary.** Rejected — Spoke shows 2. A third row invents an affordance (anti-pattern #12).
3. **Defer the section to MS-A3** (which also rewrites the sheet body). Considered (offered to Eduardo as option 3) but not chosen — MS-A5.7 is the dependency-ordered step that unblocks the Área-5 integration_test (MS-A5.9); deferring would block MS-A5.9. MS-A3's later edits to the sheet (Otimizar CTA, kebab, stop-card tap) are additive to this section, not a conflicting rewrite.
4. **Mint a new `routeId` / active-route abstraction.** Rejected — `activeRouteIdProvider` already exists and is the established convention; reusing it is the surgical choice (Karpathy #3).

## References

- Plan: `docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.7 (corrected in the same commit set)
- Roadmap: `docs/08-ROADMAP-v2.md` §Área 5 MS7 + §Área 3 (corrected in the same commit set)
- Live Spoke baseline: `/tmp/spoke-a57-config-rows-inspection/EVIDENCE.md` (verbatim `inspect_screen` bounds + 2 screenshots, 2026-06-10)
- Static dump (does NOT cover this surface — the gap the live dump filled): `docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md` (Área funcional B = `ui/setup` page only)
- Reused row widget: `route_config_row.dart` (`RouteConfigRow` + `LiveClockLabel`)
- routeId source: `active_route_provider.dart` (`activeRouteIdProvider`)
- Detalhes page this opens: `route_details_page.dart` (`RouteDetailsPage`, route `routes/active/:routeId/details`)
- Memory: `feedback_spec_baseline_and_workflow_halt` (first-surprise escalation), `feedback_spoke_parity_zero_debt_per_ms`, `lesson_spoke_visual_inspection_before_coding`, `lesson_maestro_flutter_listtile_tap_needs_semantics`
