# ADR-0047: Route-defaults persistence wires "Salvar como padrão"; the FTUE auto-show is CUT (the dump proves Spoke has no first-route gate)

- **Status:** Accepted
- **Date:** 2026-06-10
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0043 (Destino + the "Salvar como padrão" checkbox, default UNCHECKED), ADR-0044 (break window persistence shape), ADR-0045 (static dump baseline — the source that resolved this), ADR-0046 (the active-route config summary that reaches this page)

## Context

MS-A5.8 ("persistence + FTUE") was the next Área-5 step after the config summary (ADR-0046). The plan (`docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.8) and roadmap §13.C.2 framed it as **two** parts:

1. **Persistence** — wire the "Salvar como padrão" checkbox so a route config is saved into the `route_defaults_v1` `SharedPreferencesAsync` envelope, and seed a returning user's Detalhes da rota from it.
2. **FTUE auto-show** — show "Detalhes da rota" automatically the **first** time (gated on a `firstRoute` flag), then skip it on subsequent routes (roadmap §13.C.2: *"Detalhes da rota é FTUE one-time… RotPro pode pular a tela no wizard com defaults sensatos"*).

The persistence triad (`route_defaults.dart` domain + `route_defaults_controller.dart` + `route_defaults_repository.dart`) was **already fully built and tested** in an earlier MS — including a `firstRoute` flag and a `markFirstRouteComplete()` method — but **completely unwired**: no production code called `routeDefaultsControllerProvider`, `merge()`, or `markFirstRouteComplete()`, and `RouteDetailsPage._saveAsDefault` was local-only (`setState`, never persisted). So MS-A5.8's real work was wiring, not building.

### Two facts surfaced before implementing

**Fact 1 — the FTUE auto-show has no host flow in our code.** Nothing in production navigates *to* `RouteDetailsPage` except the ADR-0046 config-summary rows (explicit user taps, not an auto-show). The route-creation wizard does not push Detalhes. So "show Detalhes once on the first route" had no trigger point to hang off — building one would be inventing a flow.

**Fact 2 — Q8 "Salvar como padrão" default is UNCHECKED.** Live-confirmed on the Samsung M54 (`RQCW401G33T`) via Maestro on 2026-06-10 (screenshot pixels: the bottom checkbox renders as an empty square). This matches ADR-0043 and our current `_saveAsDefault = false`. No divergence.

### The dump resolved the FTUE question decisively (dump-first, ADR-0045)

Rather than guess at the FTUE behavior via runtime (which would create test routes on Eduardo's licensed Spoke account), the static dump (`~/spoke-dump/jadx-out`, 53k decompiled `.java` + `docs/inventory/spoke-dump-v3.65.1/`) answered it at the code level:

- **No first-route gate exists.** `grep` for `isFirstRoute|firstRoute|hasSeenSetup|shouldShowSetup|hasCompletedSetup` across `RouteSetupViewModel`/`RouteSetupFragment`/`RouteSetupScreenKt` returns **nothing**. Spoke does not gate the Route Setup / Detalhes screen behind a "first time only" flag.
- **`ui/onboarding` is a user survey**, not a route-setup FTUE (`OnboardingSurveyFragment`, `OnboardingSurveyOption`) — unrelated to Detalhes da rota.
- **Detalhes is reached on demand.** `route_setup_header` = "Configuração de rota" (the ADR-0046 summary header), and `route_offering_..._subtitle` = "Confira os detalhes da rota no menu" confirm Detalhes is opened via the menu / config summary, not force-shown once.
- **`RouteSetupViewModel.setSaveAsDefault(Z)V`** exists (string `save_as_default_action` = "Salvar como padrão") — confirming the checkbox persists the route config as the default on save, exactly as Part 1 intends.

**Conclusion:** the "FTUE one-time auto-show" the plan/roadmap assumed is an **inference Spoke does not implement** — the same un-drilled-baseline failure mode ADR-0042/0043/0044/0046 each corrected, caught here by the dump before any code. Eduardo's standing directive (match Spoke; `feedback_spoke_parity_zero_debt_per_ms`) applies: **cut the auto-show.**

## Decision

**1. MS-A5.8 ships Part 1 (persistence) only; Part 2 (FTUE auto-show) is CUT.** The dump proves Spoke has no first-route gate, so building a wizard→Detalhes auto-show would invent a flow Spoke lacks (anti-pattern #12). Detalhes is reachable on demand via the ADR-0046 config summary, which is the faithful behavior.

**2. "Salvar como padrão" is wired (best-effort persistence).** On "Concluído", if `_saveAsDefault` is checked, the current `RouteConfig` is mapped to a `RouteDefaults` patch (`RouteDefaults.fromConfig`) and persisted via `RouteDefaultsController.merge` (which preserves the envelope's `firstRoute`/`schemaVersion`). The save is **best-effort**: a persistence failure surfaces a SnackBar + log and the page **always pops** — Concluído is never gated (Spoke parity; silent-failure-hunter Finding 1).

**3. Detalhes seeds from saved defaults on open.** `RouteDetailsPage.initState` schedules a one-shot post-frame seed: it reads the persisted envelope and, if non-empty, seeds the `RouteConfigController` via the new `seed()` method (`RouteDefaults.toConfig()`, which maps a null destination back to the Spoke `RoundTrip` default). A read failure degrades to the unseeded `RouteConfig.empty()` the page already shows (logged, not swallowed). The `_seeded` one-shot flag is committed only **after** a successful applied read, so a transient first-read failure does not permanently foreclose seeding (silent-failure-hunter Finding 2).

**4. The `firstRoute` flag stays in the envelope, dormant.** `firstRoute` + `markFirstRouteComplete()` remain in `RouteDefaults`/the controller (forward-compat, already tested) but are **not wired to any auto-show** — there is no Spoke behavior for them to drive today. Removing them would be a larger change to working tested code for no parity benefit (Karpathy #3, surgical). Kept dormant, documented here so a later reviewer does not "wire the FTUE" expecting Spoke parity.

**5. The `RouteConfig`↔`RouteDefaults` mapping lives on `RouteDefaults`.** `RouteDefaults.fromConfig(config)` and `RouteDefaults.toConfig()` both live in `route_defaults.dart` (the higher-level type that already imports `route_config.dart`); putting `fromDefaults` on `RouteConfig` would be a circular import.

## Consequences

- **Positive (parity + zero invented flow):** "Salvar como padrão" now behaves like Spoke's `setSaveAsDefault` (dump-confirmed); a returning user's saved config pre-fills Detalhes; no FTUE auto-show is invented where Spoke has none.
- **Positive (resilience):** both the read (seed) and write (save) paths degrade gracefully — the screen never crashes or dead-ends on a storage failure, and the failures are observable (logged; the write failure also SnackBars).
- **Positive (dump-first proven again):** the FTUE question was answered by decompiled code in minutes, avoiding test-route pollution on the licensed Spoke account — a concrete win for the dump-first method and the motivation for formalizing it as a harness gate (separate change).
- **Neutral (dormant flag):** `firstRoute`/`markFirstRouteComplete()` stay unused. Their existing tests remain green (they test controller mechanics, not a UI auto-show). Documented as dormant to prevent a future "wire the FTUE" regression.
- **Negative (plan/roadmap wording corrected):** the plan §MS-A5.8 and roadmap §13.C.2 said "FTUE one-time"; both are corrected in the same commit set to "no FTUE gate — Detalhes is on-demand" (anti-pattern #22).

## Alternatives considered

1. **Build the FTUE auto-show now (the plan's Part 2).** Rejected — the dump proves Spoke has no first-route gate; building one inverts the white-label contract and is the exact inference failure mode the dump-first method exists to kill.
2. **Inspect route creation live on Spoke to confirm.** Considered (offered to Eduardo) but unnecessary once the dump answered it at the code level, and it would have created test routes on the licensed account. Eduardo's steer: "temos o dump completo no nosso repo, isso não ajuda em nada?" — it did; the dump was authoritative.
3. **Remove the dormant `firstRoute` machinery.** Rejected — larger change to working tested code for no parity benefit; kept dormant + documented (Karpathy #3).
4. **Block "Concluído" until the save succeeds.** Rejected — Spoke never gates Concluído (ADR-0043 §S2); saving is a best-effort side-effect, so a save failure must not trap the user (silent-failure-hunter Finding 1).

## References

- Plan: `docs/superpowers/plans/2026-06-06-slice2-completion.md` §MS-A5.8 (corrected in the same commit set)
- Roadmap: `docs/08-ROADMAP-v2.md` Área 5 MS8 + §13.C.2 (corrected in the same commit set)
- Static dump (authoritative for the FTUE answer): `~/spoke-dump/jadx-out/sources/com/circuit/p016ui/setup/*` (no first-route gate) + `docs/inventory/spoke-dump-v3.65.1/strings-pt-rBR.xml` (`save_as_default_action`, `route_setup_header`, `route_offering_..._subtitle`)
- Live Q8 confirmation: Maestro screenshot 2026-06-10 (M54 `RQCW401G33T`), "Salvar como padrão" checkbox UNCHECKED
- Persistence triad: `route_defaults.dart`, `route_defaults_controller.dart`, `route_defaults_repository.dart`
- Wiring: `route_details_page.dart` (`initState`/`_seedFromDefaults`/`_onConcluido`), `route_config_controller.dart` (`seed`)
- Review: silent-failure-hunter Findings 1 (best-effort write) + 2 (`_seeded` after success) — both fixed + tested
- Memory: `feedback_spoke_parity_zero_debt_per_ms`, `lesson_master_table_covers_setup_not_active_shell` (and its inverse: the dump's *code* DOES cover setup-screen gating logic), `feedback_spec_baseline_and_workflow_halt`
