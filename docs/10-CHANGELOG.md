# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

## 2026-06-11 — Área 3 MS-A3 (gatilhos: controles de mapa reais + Copiar paradas)

Code change (MS-A3) with its documentation. **No new ADR** — no stack change (`geolocator`/`google_maps_flutter`/`permission_handler`/`shared_preferences` já estavam no `pubspec`, sem bump de versão; o `adr-guardian` não aplica).

**O que mudou (dump-first, ADR-0045):** baseline 100% do código decompilado do Spoke (`EditRouteFragment`, `MapController`, `MapToolbarControlsController` em `~/spoke-dump/jadx-out`) — sem runtime/poluir conta licenciada.
- **Layer toggle** (`Alternar modo de mapa`) — `MapTypeClick` do Spoke → `MapType` 2-estados (normal↔satélite) persistido em `MapPrefsRepository` (`SharedPreferencesAsync`, key `map_type_v1`) + toast PT-BR original (não verbatim Circuit, ADR-0035). `MapTypeLongClick` é dev-tool interno do Spoke — NÃO replicado.
- **Recenter** (`Alternar para o mapa`) — `ReCenterButtonClick` → `MapControllerMode.FollowMyLocation` via `LocationService` (wrapper `geolocator`, sealed `LocationResult` ready/denied/unavailable, injeção de callbacks p/ testabilidade) + fallback gracioso sem permissão (toast, nunca crash — espelha `EditRouteViewModel.m9428W`). Race-fix: contador pending-move no `MapControlsController` consome o `onCameraMoveStarted` da própria animação, então o recenter não derruba o follow que acabou de ligar (ordem-independente de quando `animateCamera` resolve).
- **"Copiar paradas de uma rota anterior"** — empty-state secondary CTA agora faz `push('/home/routes/reuse-stops')` (rota já existia; matou um `_comingSoon`).
- **Achado dump-first corrigido no inventário:** §6.2bis dizia "controles visíveis só com sheet collapsed" (inferência de 1 snapshot). O código prova visibilidade por **flow ativo** (`MapToolbarControlsController` é uma `Stack<Flow>`), NÃO por altura do sheet → os controles ficam sempre visíveis no flow base = match-Spoke já correto (nenhuma mudança de código; teste de regressão adicionado).

**Fora deste MS (decisão registrada):** os 3 gatilhos restantes (CTA Otimizar→A7, tap stop-card→A6, kebab→A9) apontam pra telas ainda não construídas → cada um vira a 1ª task do MS da sua área (não wirar contra placeholder "em breve" — proibido per plano da sprint).

**Docs swept (mesmo commit set, anti-pattern #22):** roadmap Área 3 → ~90% (tabela + seção); TODO.md Area 3; inventário §6.2bis corrigido.

**Verification:** `flutter analyze` clean em escopo (23 lints pré-existentes = MS-DEBT, intocados); `flutter test` **308** host (baseline 284 no fecho da Á5, +24: 10 controller + 6 location service + 8 widget); smoke E2E no M54 (`RQCW401G33T`). 2 reviewers adversariais (perf-auditor + code-reviewer): 1 Important (race no follow-flag) + 1 should-fix (RepaintBoundary dos controles) — **ambos corrigidos no MS com teste**, zero deferido (per `feedback_spoke_parity_zero_debt_per_ms`).

## 2026-06-10 — Área 5 MS9 (integration_test + D4 + editar/remover pausa): ADR-0049 — **Área 5 fechada**

Code change (MS-A5.9) with its documentation. Closes Área 5. Code lives in git; this entry records the docs + the ADR.

**New ADR:**
- **ADR-0049** ([break edit/remove + "Salvar como padrão" always-visible](decisions/0049-break-edit-remove-and-save-default-always-visible.md)) — the D4 parity check (run **dump-only**, Eduardo's steer to avoid licensed-account pollution) surfaced two gaps. **GAP-1:** an existing break's row was non-navigable (`onTap: null`) — but the dump proves Spoke reopens it in edit mode with a remove action (`BreakSetupArgs.AddBreak`/`EditBreak`/`UpdateBreak` sealed class + verbatim PT-BR `break_screen_remove_button`="Remover pausa", `remove_break_confirmation_dialog_title`/`_description`). Wired: tapping a break row pushes the page with the `BreakConfig` as `extra` → pre-filled + "Remover pausa"; the page returns a sealed `BreakSchedulerResult` (`BreakSaved`/`BreakRemoved`); `_onTapEditarPausa` does an exhaustive `switch` → `updateBreak`/`removeBreak`/no-op; remove requires a confirmation dialog. Microcopy stays original PT-BR (ADR-0035). **GAP-2:** "Salvar como padrão" is always visible (no first-route gate — same dump finding as ADR-0047). **First integration_test of the app** (`area5_route_details_flow_test.dart`): the sub-picker back-stack chain (Detalhes → Partida/Destino/Pausa, system Android-back popping exactly one level) + add+edit break, **VERDE on the M54** (`RQCW401G33T`). Two test-only fixes (no production change): a 400ms pop-transition settle before the edit tap, and the test `_router()` builder now reads `state.extra` (the production `app.dart` was always correct).

**Docs swept (same commit set, anti-pattern #22):** roadmap Área 5 → ✅ (status table + execution-order line + MS9 row); Slice-2 plan §MS-A5.9 checked; TODO.md MS9 ✅.

**Verification:** `flutter analyze` clean in scope (23 pre-existing lints = MS-DEBT, untouched); `flutter test` **284** host (baseline 281 at MS8 close, +3 edit/remove widget tests); `integration_test/area5_route_details_flow_test.dart` VERDE on M54 (run b7xqgulv8, "All tests passed!"). D4 parity dump-only (GAP-1/GAP-2 resolved in-MS, zero deferred divergence per `feedback_spoke_parity_zero_debt_per_ms`).

## 2026-06-10 — Área 5 MS8 (route-defaults persistence, FTUE-cut): ADR-0047

Code change (MS-A5.8) with its documentation. Code lives in git; this entry records the docs + the ADR.

**New ADR:**
- **ADR-0047** ([route-defaults persistence + no FTUE gate](decisions/0047-route-defaults-persistence-no-ftue-gate.md)) — wires the "Salvar como padrão" checkbox (`merge()` the current config on Concluído, best-effort: failure SnackBars + always pops) and seeds Detalhes from the saved `route_defaults_v1` envelope on open. **CUTS the FTUE auto-show** the plan/roadmap assumed: the static dump (ADR-0045) proves Spoke has **no first-route gate** (`grep firstRoute|isFirst|hasSeenSetup` across `RouteSetupViewModel`/`Fragment`/`ScreenKt` = empty; `ui/onboarding` is a survey; Detalhes is on-demand). Q8 "Salvar como padrão" UNCHECKED confirmed by live pixels. The dormant `firstRoute` flag stays (forward-compat). **Dump-first win:** the FTUE question was answered by decompiled code, avoiding test-route pollution on the licensed Spoke account — Eduardo's prompt ("temos o dump completo, isso não ajuda?") was right.

**Docs swept (same commit set, anti-pattern #22):** roadmap Área 5 MS8 ✅ + status table + execution-order line + §13.C.2 re-resolved (FTUE one-time → no gate, on-demand) + bloqueios table; Slice-2 plan §MS-A5.8 (struck-through FTUE Part-2); TODO.md MS8 ✅.

**Verification:** `flutter analyze` clean in scope (23 pre-existing lints = MS-DEBT); `flutter test` 281 (baseline 263 at session start, +18 across MS7+MS8); silent-failure-hunter 2 CRITICAL findings (best-effort write + `_seeded`-after-success) fixed + pinned by tests. integration_test deferred to MS-A5.9.

## 2026-06-10 — Área 5 MS7 (active-route config summary): ADR-0046

Code change (MS-A5.7) with its documentation. Code lives in git; this entry records the docs + the ADR.

**New ADR:**
- **ADR-0046** ([active-route "Configuração de rota" summary rows](decisions/0046-active-route-config-summary-rows.md)) — the plan's MS-A5.7 premise (*"3 inline config rows → reopen sub-pickers"*) was refuted by code + live Spoke on three counts: (1) `route_shell_page.dart` had **no** config rows to make clickable; (2) Spoke's active-route sheet shows a **2-row** "Configuração de rota" summary (Início + Ida-e-volta, **no Pausa**); (3) tapping a row opens the **full "Detalhes da rota" page** (`RouteDetailsPage`, previously orphaned — no production push), not the sub-pickers directly. The summary uses microcopy distinct from the Detalhes-page rows. `routeId` sourced from the existing `activeRouteIdProvider`. Phase-2 live-dump halt → escalated → Eduardo chose match-Spoke. Same dump-first discipline as ADR-0044.

**Docs swept (same commit set, anti-pattern #22):** roadmap Área 5 MS7 ✅ + status table + execution-order line + Área 3 "rows de config inline" wording corrected (they were created here, not pre-existing); Slice-2 plan §MS-A5.7 (premise correction, struck-through original); TODO.md MS7 ✅.

**Verification:** `flutter analyze` clean in scope (23 pre-existing lints untouched = MS-DEBT); `flutter test` 272 (baseline 263, +9); `flutter-perf-auditor` 0 must-fix, 2 should-fix applied (`.select` watch granularity + RepaintBoundary). integration_test deferred to MS-A5.9 (decision recorded in the ADR).

## 2026-06-10 — Spoke static dump baseline (ADR-0045) + harness dump-first sweep

The recurring "baseline inferido" failure mode (ADR-0041/0042/0043/0044 — four route-config sub-pickers shipped/nearly-shipped the wrong widget from a stale or never-drilled Spoke baseline) is structurally closed by a **complete static dump of Spoke v3.65.1**.

**New ADR:**
- **ADR-0045** ([Spoke static dump baseline](decisions/0045-spoke-static-dump-baseline.md)) — `adb pull` the 4 splits → APKEditor 1.4.9 merge → apktool 3.0.2 (resources) + jadx 1.5.5 (`--deobf`, code). Inverts the method: dump = **what exists** (frozen fact), runtime = **how it behaves** (live confirm, only where flagged). 20 "Não drilled" inventory gaps become facts.

**New artifacts (light, in repo under `docs/inventory/spoke-dump-v3.65.1/`):**
- `MASTER-TABLE.md` — string→resource→screen→data-model for the 20 screens (17 high / 3 medium / 1 low confidence), with defaults/enums/verbatim PT-BR strings + a `Precisa-runtime` field per row.
- `strings-pt-rBR.xml` (2.404 PT-BR texts) + `strings-default.xml` + `AndroidManifest.xml` + `ui-screen-tree.txt` (full nav tree) + `README.md` (regeneration command + caveats).
- Heavy artifacts (merged APK ~106 MB, 53k decompiled `.java`) stay at `~/spoke-dump` outside git; `.gitignore` blocks them.

**Findings beyond the inventory:** `break_detail_sheet` (Pausa behavior during delivery, beyond ADR-0044); exact order + subtitles of the 3 Destino options (corroborates ADR-0043); Partida/Início/Término at high confidence with code line refs (Área 5 unblocked); §13.C.5 PENDING resolved (Compartilhar/Transferir são peer-transfer B2B — cut confirmed by the dump text).

**Harness dump-first sweep (verified by a 40-agent adversarial audit, workflow `w9685qno1`):** updated `CLAUDE.md` (header date, Recent-ADRs 0041–0045, Onboarding step 8a, Source-of-truth hierarchy + Spoke deep-dive dump-first, References), this CHANGELOG, `docs/08-ROADMAP-v2.md`, `docs/M2-SLICE-CHECKLIST.md`, the Slice-2 sprint plan+spec (Phase 2 = consult MASTER-TABLE then confirm), `.claude/agents/spoke-parity-checker.md` (Step 1 reads the dump first), and the inventory banner. So the next agent following the Onboarding Ritual discovers the dump and uses it dump-first.

## 2026-06-09 — Área 5 MS6 (Pausa): ADR-0044 + break scheduler page

Code change (MS-A5.6) with its documentation. Code lives in git; this entry records the docs + the ADR.

**New ADR:**
- **ADR-0044** ([break scheduler page + window domain](decisions/0044-break-scheduler-window-domain-and-page.md)) — Spoke's "Adicionar pausa" is a **full-screen "Configure a pausa" page** (NOT a sheet), and a break is a **time window** (`fromTime`/`toTime`, default 08:00–15:00) + **free integer minutes** (numeric dialog, default 30, NOT 15/30/60 chips). `BreakConfig` realigned from single `startTime` to the window shape; `route_defaults_v1` JSON arms updated (`startTime`→`fromTime`/`toTime`). Time fields reuse the ADR-0042 numpad. Same un-drilled-baseline failure mode as ADR-0042/0043 — the picker was marked "Não drilled" in inventory §16 (now drilled). Phase-2 live-dump halt → escalated → Eduardo chose match-Spoke.

**Docs swept (same commit set, anti-pattern #22):** roadmap MS6 ✅ + Área 5 status; Slice-2 plan §MS-A5.6 (sheet→page, chips→minutes dialog) + execution-order line; Slice-2 spec sub-slice table; old 2026-06-02 spec Q7 marked REFUTADO; inventory §16 marked DRILLED; TODO.md MS6 ✅.

**Verification:** `flutter analyze` clean in scope (23 pre-existing lints untouched = MS-DEBT); `flutter test` 261 (baseline 249, +12).

## 2026-06-06 — ROADMAP-v2 clean rewrite + Slice-2 sprint + 2 pending sprints + harness drift sweep

Major documentation realignment to a single source of truth, plus a verified harness-drift cleanup.

**Roadmap:** `docs/08-ROADMAP-v2.md` fully rewritten (407→~290 lines) and synced to real code — Áreas 1–4 done, 3+5 partial, 6–11 not started; Á5 Destino is the ADR-0043 3-card sheet; "Salvar como padrão" UNCHECKED; Á4 uses live Google Places. Adds dependency-forced execution order, B2C/B2B boundary, and the 3 post-cutoff Flutter 3.44 breaking changes.

**New sprints authored (NOT yet executed):**
- `docs/superpowers/{specs,plans}/2026-06-06-slice2-completion.md` — finishes Slice 2 area-by-area via a mandatory 5-phase per-area pipeline (modern-stack research → fresh live Spoke dump → implement → validate → harness-current) + a 30-item NEVER-AGAIN bad-practices catalogue.
- `docs/superpowers/{specs,plans}/2026-06-06-restructure-b2c-clarity-and-harden.md` — B2C/B2B boundary doc + ADR-0044 + generalize `area5-microsprint.js`→`spoke-microsprint.js` + live-inspect contract.
- `docs/superpowers/{specs,plans}/2026-06-04-revalidation-backfill-sprint.md` — revalidate the built surface (analyze→0, fresh baselines, integration_test).

**Harness drift sweep (verified by a 5-agent adversarial workflow):** 34 confirmed drifts fixed across README, CLAUDE.md, TODO.md, M2-SLICE-CHECKLIST.md, BUSINESS-RULES.md, the verify-slice skill, the old Á5 spec/plan (superseded-banner + MS5 marked done + checkbox/Concluído facts), the inventory (checkbox UNCHECKED), and 4 harness files referencing dead MCP tool names (`inspect_view_hierarchy`/`tap_on`/`back`/`launch_app` → `inspect_screen`+`run`; `resolve_workspace_symbol`/`hover`/`signature_help`/`run_tests` → `lsp`). The 3 subagent `tools:` frontmatter lines need a separate human-authorized edit (auto-mode permission guard).

> **Known gap (still not backfilled):** ADRs **0031–0040** have no Changelog entry (owned by the unrun revalidation-backfill sprint).

## 2026-06-04 — Área 5 (Detalhes da rota) docs: ADRs 0041–0043 + audit + spec/plan

Documentation artifacts produced across the Área 5 microsprints (MS1–MS5 + MS-FIX) on `feat/m2-slice-2-area-5-route-details`. Code lives in git; this entry records the docs.

**New ADRs:**
- **ADR-0041** ([wheel_picker time drum](decisions/0041-wheel-picker-time-drum.md)) — adopted `wheel_picker` for the time picker. **Superseded by ADR-0042** the same area after live Spoke re-inspection.
- **ADR-0042** ([time picker = numpad](decisions/0042-time-picker-numpad-spoke-fidelity.md)) — Spoke's time picker is a 4×3 numeric keypad, not a wheel; custom widget, no external dep. Documents the inference-vs-measurement failure mode (baseline was 0 bytes) + a spec-drafting protocol amendment.
- **ADR-0043** ([Destino picker = bottom sheet + 3-state domain](decisions/0043-destination-picker-sheet-three-state-domain.md)) — Destino is a bottom sheet with 3 action cards, not a full-screen RadioListTile page; `Destination` family realigned to `RoundTrip`/`SpecificAddress`/`NoDestination` (`BackToStart` removed). Same mislabeled-baseline failure mode as ADR-0042. §Decision 3 carries the canonical row↔sheet `#N` divergence table; §Decision 4 records the deliberate "Salvar como padrão" unchecked override of spec Q8.

**New audit doc:** `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` — read-only retrospective audit of MS1–MS5 (6 dimensions, adversarial-verified 30→21 findings, verdict `minor-issues`). First entry under the new `docs/audits/` directory.

**Spec/plan:** `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q3 numpad rewrite, Q6/Q11 Destino sheet, Goal #10 + Risks numpad, app_router→app.dart) + `docs/superpowers/plans/2026-06-02-area5-route-details.md` (Phase 4/5 rewrites) + new MS-FIX plan `docs/superpowers/plans/2026-06-03-area5-msfix-audit-remediation.md`.

**Process:** memory directive "fresh live Spoke inspection per feature — never trust a prior-session baseline" locked after the MS4/MS5 mislabeled-baseline failures.

> **Known gap (not backfilled):** this Changelog jumps 2026-05-26 → 2026-06-04; ADRs **0031–0040** (Stripe, Maestro, and other sprints between the M2 reset and Área 5) have no Changelog entry. Pre-existing; decide whether to backfill before M2 closes.

## 2026-05-26 — M2 reset to baseline (white-label Spoke restart)

Após 30 dias de slice-2 acumular entropia (16 microsprints + 43 session logs + 37 ADRs + 12 specs/plans + 522 LOC TODO), Eduardo redirecionou: **estratégia M2 = white-label do Spoke** (replicar 100% funcional/estrutural com nossa stack; polish visual no final). Branch `chore/m2-reset-to-zero` executou limpeza completa:

**Código apagado (apps/mobile/lib/):**
- `features/{stops,settings,share}/` — 31 files
- `core/services/external_nav.{dart,g.dart}` — único consumer era stops/
- `apps/mobile/test/{features,_support,core}/` + `integration_test/` — 37 test files
- `apps/mobile/lib/app.dart` reescrita minimal: rotas /login, /register, /home placeholder

**Mantido (intocado):**
- `features/auth/` (Login + Register)
- `core/{theme,widgets,env,network,providers,services/id,permissions}/` (design system reaproveitável)
- `apps/backend/src/` inteiro
- `prototipo/` inteiro

**Docs apagados:**
- 12 ADRs slice-2-específicas (0007, 0017, 0019, 0020, 0021, 0027, 0028, 0029, 0031, 0032, 0033, 0034) — keepers: 25 ADRs (foundational + harness + 0030 Stripe + 0035 pivot + 0036 parity gate)
- 10 specs/plans em `docs/superpowers/` (mantém só `0000-template.md` em cada)
- `docs/08-ROADMAP.md` (stub redirect — obsoleto), `docs/05-SCREENS.md` (inventory é canônico)

**Docs reescritos:**
- `TODO.md`: 522 → 26 linhas
- `docs/08-ROADMAP-v2.md`: 267 → 101 linhas (sem microsprints A/B; checklist de telas Spoke a replicar)
- `docs/M2-SLICE-CHECKLIST.md`: 137 → 64 linhas (sem ADR por slice, sem session log por commit)
- `docs/sessions/0001-INDEX.md`: zerado com nota apontando pro archive

**Arquivado:**
- 36 session logs (2026-05-*) → `docs/archive/sessions-pre-cleanup-2026-05-26/`

Plano detalhado da limpeza preservado em `~/.claude/plans/velvet-yawning-thacker.md`.

## 2026-05-24 — Pix gateway migration: Efí Bank → Stripe + 30-day access pass model (ADR-0030)

Client decision late on 2026-05-24, after slice-2 fidelity work resumed: migrate the slice-4 Pix gateway from **Efí Bank** to **Stripe** and revert the brief 2026-05-10 "pay-per-route" model to a **30-day access pass** charged manually (R$ 25,90 grants 30 days; no Stripe Subscriptions, no automatic renewal — Pix Automático is invite-only in BR).

- **Filed [ADR-0030](decisions/0030-stripe-pix-30-day-access-pass.md)** — supersedes [ADR-0007](decisions/0007-efi-bank-payment.md). 4-row options table, decision in 1 sentence, consequences in 3 bullets, rollback, sandbox verification checklist.
- **ADR-0007 marked Superseded** with a header banner pointing at ADR-0030; body preserved as historical context.
- **`docs/BUSINESS-RULES.md`** got `Status: Accepted` + ADR cross-ref + clarification that "R$ 25,90 por mês" is **not** recurring billing; it's R$ 25,90 to start a fresh 30-day pass that the user actively renews via a new Pix payment.
- **Six canonical docs reconciled in this same PR** (CLAUDE.md, 01-PROJECT, 02-ARCHITECTURE Flow 3 + payment subsystem + DB schema, 04-FEATURES F09/F10, 08-ROADMAP §"Slice 4" + KPIs + cost line, M2-COST-MODEL fees + unit economics).
- **Hot-path docs swept** (README.md, PROJECT-CONTEXT.md, AGENTS.md, TODO.md slice-4 entry, SECURITY.md, Blueprint.md, 03-CONVENTIONS.md env-var example, 07-INFRA.md secrets inventory, 09-DISASTER-RECOVERY.md Scenario 6 outage + Scenario 7 secret-rotation, INSTALL.md `certs/` note). All references to Efí/mTLS/`.p12`/HMAC removed from active surface area; only intentional "ADR-0007 (Efí Bank) superseded by ADR-0030" cross-refs remain.
- **Untouched by design (historical immutability):** session logs (sessions 01–22f), `docs/briefing/original-briefing.md`, `docs/superpowers/specs/` and `plans/` older than this entry, ADR-0003 (its Efí mention was true at decision time — 2026-05-05), ADR-0007 body. ADR-0015's `Related ADRs` line got a `superseded by ADR-0030` annotation but body is untouched.
- **adr-guardian sweep:** GREEN, zero BLOCKING — no `pubspec.yaml` / `package.json` / `infra/` / `prisma/` touched (slice 4 will introduce Stripe deps + schema migration when it starts).

## 2026-05-24 — M2-AI harness sprint (sessions 19–22f)

Seven-phase sprint on `feat/m2-ai-harness` (orthogonal to slice 2) that adopts the official Flutter team's AI tooling onto the existing harness without disturbing product code. PR #8 against `feat/m2-slice-2-telas-core`.

- **ADR-0023** — official Dart & Flutter MCP server adopted via `.mcp.json` + `enabledMcpjsonServers` allowlist (Phase 1).
- **ADR-0024** — PostToolUse hook auto-regenerates Riverpod `.g.dart` after `@riverpod` edits, with 90 s lock-file debounce; sits next to `format-dart.sh` (Phase 2).
- **ADR-0025** — `flutter-test-author` subagent enforces test-first TDD for `apps/mobile/lib/`; refuses to write production code itself. `mocktail ^1.0.5` added as dev_dep, manual fakes remain the default (Phase 3).
- **ADR-0026** — `GH_DATA_DIR` env override in `infra/graphhopper/extract-sp.sh` (housekeeping; closed an `adr-guardian` BLOCKING finding from commit `bff1b6c` filed in another session).
- **ADR-0027** — `flutter-perf-auditor` read-only subagent, 9-item canonical perf checklist; Edit/Write/MultiEdit excluded from the allowlist so the read-only contract is mechanical, not just prompt-enforced. Wired into `M2-SLICE-CHECKLIST.md` §Verification (Phase 4).
- **ADR-0028** — `mcp_flutter` (Arenukvern) **rejected** for M2 with a documented re-evaluation trigger (iterations > 7/screen OR 2 consecutive device-E2E gates with > 2 Criticals each cleared by the static checker). Plugin is healthy (v3.0.7, debug-only) but the gap it would close is already covered by ADR-0021's device-E2E gate + ADR-0022's integration_test gate (Phase 5).
- **ADR-0029** — `alchemist ^0.14.0` (Betterment + VGV) adopted for golden tests after WebFetch confirmed `golden_toolkit` is discontinued by eBay. One canary baseline (`HomeEmptyPage`, 400×930 PNG) in CI mode. NOT a hook (Phase 6).
- **Docs updated:** `CLAUDE.md` ("Last updated" + 2 new Executable Commands rows + §"Context7 Mandatory" 3-tier precedence + §"In-Loop Auto-Validation" 4-hook split + §"Verify Your Work" 2 new bullets), `docs/03-CONVENTIONS.md` §Testing (2 bullets on TDD subagent + goldens), `docs/M2-SLICE-CHECKLIST.md` §Verification (perf-auditor + goldens bullets). `docs/02-ARCHITECTURE.md` unchanged — product topology unaffected by harness tooling.
- **Deferred to next session:** functional smoke dispatches of `flutter-test-author` and `flutter-perf-auditor` — Claude Code's agent registry only loads at session boot. Exact dispatch prompts captured in ADR-0025 §Verification and ADR-0027 §Verification.
- **In-loop validation:** every phase ran the in-loop hooks (`analyze-changed-dart.sh`, `check-dto-mirror.sh`, `warn-adr-drift.sh`) at turn end; `adr-guardian` dispatched at each phase boundary (caught and closed the ADR-0026 gap from commit `bff1b6c`); lefthook + commitlint passed on every commit without `--no-verify`.

## 2026-05-19 — slice 2 sub-2a remainder + sub-2b + sub-2c (session 13)

- **Sub 2a (Foundation) closed**: `StopsController` Riverpod 3 codegen with the 7 mutations the slice consumes (`add`, `remove`, `updateStop`, `reorder`, `applyOptimizedOrder`, `clear`, `build`-hydrate). `StopListItem` shared widget, `ScreenHomeEmpty`, `ScreenHomeList` with `HomeListPageOrEmpty` dispatcher + GoRouter wiring, `ScreenAddStop` with shared `StopForm` (address-only per prototype; Nominatim arrives in slice 3).
- **Sub 2b (Captura) closed**: `AndroidManifest.xml` declares `ACCESS_FINE_LOCATION` + `RECORD_AUDIO` + `CAMERA` in `src/main/` + `<queries>` block for Android 11+ package visibility (`com.google.android.apps.maps`, `com.waze`, https VIEW). `core/services/permissions.dart` `AppPermissions` wrapper with `@riverpod` codegen provider. `ScreenVoice` (`speech_to_text` pt-BR), `ScreenOCR` (`image_picker` → `google_mlkit_text_recognition`), `ScreenAddStopsMap` (`flutter_map` tap-to-add with real lat/lng).
- **Sub 2c (Manipulação) closed**: `ScreenStopDetail` (introduced `Stop.isGeocoded` getter), `ScreenEditStop` (reuses `StopForm`; reconciled the Riverpod 3 `update→updateStop` drift), `ScreenReorder` (`ReorderableListView.builder` + `ReorderableDragStartListener` + `StopListItem` reuse), `ScreenMapStops` (`flutter_map` + OSM tiles per ADR-0016, `Stop.isGeocoded` filter consumes the Null Island contract).
- **Cross-cutting DRY refactors**: shared `FakeStopsRepository` (eliminates 6-copy fake proliferation, net −106 LOC), shared `stopsAsyncView` for loading + error boilerplate across 5 screens (net −21 LOC + standardized error copy), pre-emptive `FakeAppPermissions` extraction before sub-2b screens spawned the 3rd / 4th copies.
- **Dead code purge**: removed M1's `apps/mobile/lib/features/home/presentation/home_placeholder_page.dart` (unreachable since Task 14 rebound `/home` to `HomeListPageOrEmpty`).
- **`Stop` domain extension**: added `bool get isGeocoded => lat != 0 || lng != 0;` to close the Null Island contract between `ScreenAddStop` / `ScreenVoice` / `ScreenOCR` (which mint stops with `lat=0, lng=0` until slice 3 geocodes) and `ScreenMapStops` / `external_nav` (must filter ungeocoded stops to avoid pinning markers / routing the rider to the Atlantic).
- **ADR-0015 amended** in session 12 to record the resolved pubspec.yaml caret-semver pins; `adr-guardian` confirmed no stack drift in the slice diff.
- **Prototype fidelity audit landed** (`prototype-fidelity-checker` subagent): 3 Critical + 4 Important divergences cataloged in `TODO.md` as slice-2-PR blockers (HomeEmpty FAB + "Como funciona?" pill, BottomNav across home family, StopListItem subtitle semantics, AddStop bottom-sheet presentation, Voice mic button visual, OCR dark viewfinder, StopDetail "Parada N de M" title).
- **Test suite grew from 26 to 53 tests**, full `flutter analyze` 0 issues, `bun run typecheck` clean. 22 commits on `feat/m2-slice-2-telas-core` pushed to origin between `e18f257` and the session-end audit-closure pack.

## 2026-05-13 — M2 roadmap made canonical (session 11)

- **`docs/08-ROADMAP.md` rewritten** as the single source of truth for M2: 7 locked slices (APK ✅, Telas Core, VRP, Pix, sentido casa, LGPD, admin), per-slice scope and acceptance criteria, library choices validated via Context7, read-first map for future agents.
- **New: `docs/M2-SLICE-CHECKLIST.md`** — the rigid execution checklist used by every slice from slice 2 onward. Captures the verification steps (`aapt2 dump permissions`, `apksigner verify`, etc.) we lost time on during slice 1.
- **New: `docs/M2-COST-MODEL.md`** — the single source of truth for monthly infrastructure cost (target: ≤ BRL 200/month while in beta), per-transaction unit economics, and the explicit list of services we said no to and why.
- **New ADR-0015** — M2 plan and library choices: locks slice order, codifies `08-ROADMAP.md` as the source of truth, pins the slice 2 libraries (`flutter_map` 8.x, `speech_to_text` 7.x, `google_mlkit_text_recognition` 0.x, `geolocator` 14.x, `share_plus` 11.x).
- **New ADR-0016** — Map library + tile policy: `flutter_map` with public OSM tiles, OSMF acceptable-use compliance, documented migration trigger to self-hosted tiles.
- **Pricing model update propagated**: M2 moved from monthly subscription (BRL 25.90/month, original brief) to **pay-per-route** (BRL 25.90 per "Iniciar navegação," confirmed with client 2026-05-10). Reflected in `01-PROJECT.md`, `02-ARCHITECTURE.md` Flow 3, `04-FEATURES.md` F09/F10, `08-ROADMAP.md`.
- **Status corrected**: M1 marked closed in `01-PROJECT.md` and `04-FEATURES.md` (delivered 2026-05-09); slice 1 of M2 marked shipped (released as `v1.0.0` on 2026-05-13).

## 2026-05-13 — slice 1 (APK distribution)

- **New ADR-0014** ([Android release signing](decisions/0014-android-release-signing.md)) — keystore custody, distribution channel via Vercel public dir, single universal APK, signing config in Gradle. Includes "Sharp edges learned during slice 1" subsection capturing the INTERNET-permission gotcha.

## 2026-05-08

- **Schema source of truth codified** ([ADR-0013](decisions/0013-api-contract-source-of-truth.md)): Prisma owns the DB, TypeBox owns the HTTP contract, Dart DTOs mirror TypeBox 1:1 via a `// Mirror of:` header. Rule added to `CLAUDE.md`, new "API Contracts & Type Safety" section in `02-ARCHITECTURE.md`, new §8 in `03-CONVENTIONS.md`. Reference template at `apps/mobile/lib/features/auth/data/dto/_template.dart`. OpenAPI export + codegen deferred to post-M1.

## 2026-05-07

- **Documentation reorganization:** removed redundant files (`agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`), unified roadmap into a single M1-focused `docs/08-ROADMAP.md`, renumbered docs to contiguous 01–10.
- **Prototype as canonical UI source:** `prototipo/` (Claude Design output, client-approved) is now referenced from `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md`. Tokens (including `neon`) and 19-screen list synced.
- **Roadmap focused on M1 only.** M2 scope deferred until post-M1 client conversation.
- **Server titularity clarified:** DigitalOcean account is the client's. Eduardo has admin access.
- **1GB droplet workaround documented as the M1 reality.** 8GB resize + Sudeste reimport is post-M1 work.
