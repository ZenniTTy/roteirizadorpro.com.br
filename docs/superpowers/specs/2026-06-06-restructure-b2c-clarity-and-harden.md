# Spec — Restructure: B2C clarity + harness hardening (keep-and-harden)

> **Date:** 2026-06-06
> **Author:** Claude Code (with Eduardo)
> **Status:** Draft — to be executed MS-by-MS in a separate session
> **Branch:** dedicated `chore/restructure-b2c-harden` off the current branch tip (do NOT mix with feature work)
> **Source of truth:** this spec + `docs/08-ROADMAP-v2.md` (the roadmap this restructure *clarifies*, not rewrites) + the official Spoke/Circuit B2C/B2B classification researched 2026-06-06 (cited in §Context).

> **Relationship to the revalidation sprint:** This is a SEPARATE, SMALLER sprint than `docs/superpowers/specs/2026-06-04-revalidation-backfill-sprint.md`. That one revalidates the *built surface* (analyze→0, tests, docs, Spoke baselines, integration_test). THIS one restructures *how future work is scoped and guarded* (B2C/B2B boundary doc, generalized clone workflow, live-inspect contract, two-track model, per-area gates). They are complementary and can run in either order; this spec assumes the revalidation sprint has NOT yet run and does not depend on it.

---

## Context

After Áreas 1–5 of Slice 2 shipped, two recurring failures cost real time:

1. **MS4 (numpad) + MS5 (Destino sheet)** — both implemented against a *prior-session Spoke baseline* that turned out wrong (MS4 captured a 0-byte PNG; MS5 captured a mislabeled screenshot — the time numpad instead of the Destino sheet). Root cause: **trusting a stale baseline instead of re-inspecting Spoke live at implementation time.** This was caught at Phase 1 both times, but only after the spec had already been written around the wrong widget.

2. **Scope ambiguity** — Eduardo correctly observed that "some things in the app serve companies / their employees (B2B), and we don't need to implement those." This is a real risk: the app we clone (Spoke, ex-Circuit) ships TWO products, and only one is ours.

Eduardo asked, as a senior dev would, to restructure everything-that-remains so the critical errors don't recur, so scope is clearer with more context, and so **validations happen at implementation time against Spoke — never following a previously-mapped baseline** — explicitly requesting an adversarial analysis ("don't agree just to agree"). An adversarial workflow analysis was run; it confirmed Eduardo is right on cutting B2B noise, keeping the admin panel, validating live, and clarifying the roadmap — and pushed back on one part: **deleting prior mapping docs is the wrong fix** (the 2026-05-26 reset already deleted ~150 files and the failures *still* happened; the root cause was the stale-baseline trust, not the existence of docs). Eduardo accepted **keep-and-harden** (surgical cleanup) over **delete-and-restart**.

### The B2C/B2B boundary — researched, not assumed (2026-06-06)

Eduardo's directive was explicit: **don't assume which features are B2B — consult Spoke's own docs via WebSearch and classify rigorously, then compare against what we've built.** Done. Findings from official Spoke/Circuit sources (`help.getcircuit.com`, `getcircuit.com`, `spoke.com`, Google Play listing, Routific's product review):

- **Circuit rebranded to "Spoke" in late 2025.** `help.getcircuit.com` now 301-redirects to `help.spoke.com`. "Circuit for Teams" became **"Spoke Dispatch"**. This closes the loop with our internal codename — the app we clone (`com.underwood.route_optimiser`) is the consumer **Spoke Route Planner**.
- **B2C — Spoke Route Planner (solo driver — what we clone).** Per the official help center and product pages, the solo app supports: route optimization, unlimited stops (paid), **per-stop delivery time windows**, **per-stop priority levels**, proof-of-delivery (photo + notes), package finder / package count, delivery vs pickup, rest breaks, custom per-stop duration, hands-free voice entry, in-app navigation handoff. Direct quote: *"Spoke Route Planner allows you to set delivery time windows and priority levels for specific stops."*
- **B2B — Spoke Dispatch (dispatcher/fleet — NOT ours).** Exclusive to the team product: **assigning stops to other drivers**, **live GPS tracking of a fleet**, **team/member management + permissions/roles**, **automatic customer notifications (ETA SMS)**, **recipient-facing tracking pages**, **driver-performance analytics dashboards**, **company billing per seat**, integrations (Shopify/Zapier), bulk spreadsheet dispatch-and-assign.

**The decisive correction this research produced:** my initial instinct (pre-research) flagged *per-stop time-window* and *per-stop priority* as "B2B leaks to cut." **The official docs prove both are B2C** — they are solo-driver features of the Route Planner. Cutting them would have *deleted legitimate consumer features* AND violated Eduardo's own locked directive #7.2 (which lists "Janela de horário por parada" under REPLICAR) and #13 ("everything Spoke has must exist in RotPro"). This is exactly the assume-don't-verify failure the restructure exists to prevent — caught here only because Eduardo insisted on research over palpite.

**Cross-reference against the built + planned surface (read-only audit 2026-06-06):** ZERO Spoke Dispatch (B2B) concepts exist in built code (`apps/mobile/lib/features/{auth,routes,route_config}`, `apps/backend/src/{auth,health,routes,config,plugins}`) — searches for `team/member/dispatch/fleet/assign-to-driver/role/organization/seat/recipient-notification` returned only false positives (`_rememberMe`, Riverpod `dispatch`, Prisma `SqlDriverAdapter`). ZERO in the active roadmap. The ONE genuine B2B feature in the inventory — **Maximum-stops-per-plan tier limit (§12.B.10)** — was **already cut** (ADR-0030 single-tier model). **Net: our scope is already clean of B2B. The work is not to cut features — it is to write down the boundary as a permanent guard so a future agent doesn't clone a Dispatch feature by accident.**

### What this restructure changes (and what it deliberately doesn't)

This produces **zero new product features**. It hardens process and documentation:

- A **canonical B2C/B2B boundary document** (the researched classification above), referenced by the roadmap, inventory, and the clone gate.
- A **generalized clone-microsprint workflow** (`area5-microsprint.js` → `spoke-microsprint.js`) usable for Áreas 6–9, with the live-inspect halt gates intact.
- A **live-inspect-per-feature contract** promoted from a memory note into the `spoke-parity-checker` agent definition + `M2-SLICE-CHECKLIST.md` (so it survives session resets).
- A **two-track work model** written into the roadmap: Spoke-clone areas (workflow-driven, Spoke is the spec) vs original-RotPro features (brainstorm→spec→plan, no Spoke equivalent).
- A **hard `integration_test/` per-area gate** for any area touching navigation.
- **Surgical cleanup**: confirm `/tmp/spoke-*` is purged (already empty post-restart) and add a guard so inspection captures never get versioned; fix one dangling memory pointer.
- **Thin specs going forward**: future Spoke-clone areas get short live-inspect-first stubs, NOT 200-line pre-written specs that bake in a stale baseline.

It does **not** delete the inventory, the built code, the ADRs, or the existing area specs/plans (those are history + the revalidation sprint's input).

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Delete prior mapping docs to "clean context", or keep them? | **Keep-and-harden (surgical).** Keep inventory, built code, ADRs, existing area specs/plans. Purge only ephemeral `/tmp/spoke-*` captures + add a guard. | The 2026-05-26 reset already deleted ~150 files and the MS4/MS5 failures STILL happened. Root cause = trusting a stale baseline, NOT doc existence. Deleting the inventory throws away the one durable parity catalogue and repeats the reset that didn't work. Adversarial analysis confirmed. |
| Q2 | Which features are B2B and should be cut? | **None to cut — researched, not assumed.** Per official Spoke docs: per-stop time-window + per-stop priority are **B2C** (Route Planner). The only B2B feature (max-stops-per-plan) was already cut. The B2B line is Spoke **Dispatch** (assign-to-driver, fleet tracking, team mgmt, customer notifs, analytics) — none of which exists in our scope. | Eduardo's directive: consult Spoke docs via WebSearch, classify rigorously, compare against built. The research reversed my pre-research palpite. Cutting time-window/priority would delete legitimate B2C features + violate locked directives #7.2 and #13. |
| Q3 | How to guard against B2B leakage going forward? | **Write a canonical B2C/B2B boundary doc** (`docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md`) with the researched classification + a one-line decision rule ("does this serve a dispatcher managing OTHER drivers, or a company admin? → B2B → do not clone"). Reference it from roadmap + clone gate. | A guard that survives session resets beats relying on an agent re-deriving the boundary each time. The doc IS the cut — it makes future cuts mechanical instead of palpite-driven. |
| Q4 | Painel admin — Spoke-clone or original feature? | **Original RotPro feature → Track 2 (brainstorm→spec→plan).** It's internal operational tooling for the 2 business partners (MRR, DAU, routes/stops processed) — NOT a screen in the rider's app, NOT a Spoke clone, NOT the B2B Dispatch dashboard (which is customer-facing fleet mgmt). Stays Slice 7, full spec/plan, no `spoke-parity-checker`. | Confirmed by Eduardo. Admin has no Spoke equivalent to inspect; treating it as a clone would be wrong. It is genuinely "necessary" per Eduardo and stays in scope as an original feature. |
| Q5 | Generalize `area5-microsprint.js` or keep area-specific? | **Generalize → `spoke-microsprint.js`.** Rename + parameterize the screenshot dir + area label; keep all halt gates (preflight byte-check, live-baseline architectural-surprise halt, BLOCKED_SPEC_OUTDATED). Re-register the skill. | The workflow is ALREADY 95% generic (everything comes from `args`). Only the name, the `area5` skill registration, and the hardcoded `/tmp/spoke-a5-inspection/` path are area-specific. Generalizing unlocks Áreas 6–9 reuse for ~30 min of work; leaving it area-named invites copy-paste drift. |
| Q6 | Pre-write full specs for Áreas 6–9 now, or thin stubs? | **Thin live-inspect-first stubs.** Each remaining Spoke-clone area gets a short stub that says "inspect Spoke live FIRST, the baseline IS the spec" — NOT a 200-line pre-written spec. Full detail is generated at implementation time from the live baseline. | Pre-writing a spec from a memory/inventory description is exactly what produced the MS4/MS5 stale-baseline failures. The inventory already describes each area; a second pre-written spec just doubles the staleness surface. The workflow's Phase 1 generates the real baseline. |
| Q7 | Make `integration_test/` a hard gate? | **Yes — hard per-area gate for any area touching navigation.** Add to `M2-SLICE-CHECKLIST.md` §Antes de PR: if the area added/changed a GoRouter route or Android-back behavior, an `integration_test/` test on the M54 is required before the area's work is declared done. | `lesson_slice_checklist_integration_test_gate` + the MS5 `app.dart` scope-error: widget tests can't catch GoRouter branch-stack / Android-back issues. The directory is currently ABSENT. Per-area is the right granularity (per-MS would be overkill; per-slice too late). |
| Q8 | Where does the live-inspect rule live so it survives resets? | **Promote from memory into the `spoke-parity-checker` agent contract + `M2-SLICE-CHECKLIST.md`.** Memory `feedback_spoke_evidence_per_ms` stays, but the binding rule moves into versioned files the harness loads every session. | Memory is recalled probabilistically and reflects when-written state; a contract clause in the agent definition + checklist is loaded deterministically. The rule that failed twice must be mechanically present, not recalled. |

## Goals (acceptance for this restructure)

At sprint end, on `chore/restructure-b2c-harden`:

1. **B2C/B2B boundary doc exists** at `docs/inventory/2026-06-06-spoke-b2c-vs-b2b-boundary.md` with: the Spoke→Spoke-Dispatch rebrand note, the per-feature classification table (B2C Route Planner vs B2B Dispatch, each row cited to an official source), the one-line decision rule, and an explicit "already-cut: max-stops-per-plan (ADR-0030)" + "verified-clean: time-window + priority are B2C" record. Linked from `docs/08-ROADMAP-v2.md` and from the inventory's §12 gap table.
2. **The roadmap's two ambiguous rows are annotated, not deleted** — `roadmap:132` (per-stop time-window) and `roadmap:253/259` (per-stop priority) each carry a one-line "(B2C — Spoke Route Planner; see boundary doc)" annotation so no future agent re-flags them as B2B. The schema `priority` column comment likewise.
3. **Generalized workflow exists** at `.claude/workflows/spoke-microsprint.js` — `area5-microsprint.js` renamed, screenshot dir parameterized via an `areaSlug` arg (default keeps `/tmp/spoke-a5-inspection` behavior for back-compat), `meta.name` updated, all five phases + every halt gate (preflight byte-check, architectural-surprise halt, BLOCKED_SPEC_OUTDATED, zero-debt defensive check) preserved verbatim. The old `area5-microsprint` skill registration is updated or aliased so `/area5-microsprint` still resolves OR is cleanly replaced by `/spoke-microsprint`.
4. **Live-inspect contract is in versioned files** — `.claude/agents/spoke-parity-checker.md` carries an explicit "live re-inspection per feature at implementation time; a prior-session baseline (even non-zero, even named correctly) is NOT trustworthy — re-capture before any spec is locked" clause; `M2-SLICE-CHECKLIST.md` §"Antes de qualquer trabalho num slice" carries the same rule as a checkbox.
5. **Two-track model is documented** in `docs/08-ROADMAP-v2.md` — a short "How remaining work is executed" section distinguishing Track 1 (Spoke-clone: Áreas 6–9 via `spoke-microsprint.js`, Spoke is the spec, thin stub only) from Track 2 (original RotPro: Slices 4 Stripe / 5 sentido-casa / 6 LGPD / 7 admin via brainstorm→spec→plan, no Spoke equivalent).
6. **`integration_test/` is a hard per-area gate** — `M2-SLICE-CHECKLIST.md` §"Antes de PR" requires an on-device `integration_test/` test for any area that touched navigation, with the M54 command.
7. **Thin stubs exist** for each remaining Spoke-clone area (Áreas 6–9 per the roadmap) under `docs/superpowers/specs/` — each a short live-inspect-first stub (NOT a full pre-written spec), tagged so the preflight `[INFERRED — VERIFY BEFORE LOCK]` gate fires until the live baseline is captured.
8. **`/tmp` is confirmed clean + guarded** — `/tmp/spoke-*` verified empty (already true post-restart); `.gitignore` confirmed to exclude any accidental `spoke-*` capture path under the repo; no inspection artifact is versioned.
9. **Dangling memory pointer fixed** — the ADR-0042 / memory reference to `feedback_spec_drafting_requires_live_widget_baseline.md` (a file that was never created) is corrected to point at the real `feedback_spoke_evidence_per_ms.md`, or the missing memory is created.
10. **No product behavior changed** — `flutter analyze` no worse than the measured 23 pre-existing issues (this sprint touches docs + workflow + agent defs + .gitignore, NOT `lib/`); `flutter test` ≥ 249 unchanged; `bun run typecheck` clean. A diff that touches any `apps/*/lib/` or `apps/*/src/` file is out of scope and a bug.

### Non-goals (explicit, to keep scope tight)

- **Cutting any product feature.** The research proved nothing needs cutting. (If a future live inspection of Áreas 6–9 surfaces a genuine Dispatch feature, the boundary doc tells the agent to skip it — that's the guard working, not this sprint cutting.)
- **Building Áreas 6–9 or Slices 4–7.** This sprint produces the stubs + the rails; the build happens in their own sessions.
- **Revalidating the built surface** (analyze→0, fresh Spoke baselines per built screen, the Área 5 integration_test). That's the *separate* `2026-06-04-revalidation-backfill-sprint`.
- **Touching any `lib/` or backend `src/` file.** This is a docs + harness sprint. Code changes are out of scope by construction.
- **Rewriting the inventory or the roadmap wholesale.** Surgical annotations only (the two B2C rows + the two-track section + the boundary-doc links).
- **Deleting the existing area specs/plans.** They are history and the revalidation sprint's input.

## Architecture (sprint structure, not code)

No new module. Organized as microsprints (detail in the plan), ordered so each MS is independently committable and the lowest-risk/most-foundational work lands first:

- **MS1 — B2C/B2B boundary doc** (the researched classification; the keystone — everything else references it).
- **MS2 — Roadmap annotations + two-track model** (annotate the 2 B2C rows; add the two-track execution section; link the boundary doc).
- **MS3 — Generalize the workflow** (`area5-microsprint.js` → `spoke-microsprint.js`; re-register skill; preserve all gates).
- **MS4 — Live-inspect contract + integration_test gate** (promote the rule into `spoke-parity-checker.md` + `M2-SLICE-CHECKLIST.md`; add the per-area integration_test gate).
- **MS5 — Thin stubs for Áreas 6–9** (live-inspect-first stub per remaining clone area, `[INFERRED]`-tagged).
- **MS6 — Cleanup + closure** (confirm `/tmp` clean + `.gitignore` guard; fix the dangling memory pointer; final analyze/test/typecheck no-regression sweep; restructure report).

MS ordering: 1 → 2 → 3 → 4 → 5 → 6. MS1 first because the boundary doc is referenced by 2, 4, 5. MS3 (workflow) and MS4 (contract) are independent of each other and could swap.

### Architecture principles

1. **Docs + harness only — never `lib/`.** Every MS's diff stays inside `docs/`, `.claude/`, `.gitignore`, and memory. A touched source file is a scope violation.
2. **Annotate, don't delete.** History (inventory, ADRs, prior specs) is preserved; the restructure adds guards and clarity on top.
3. **Guards live in versioned, deterministically-loaded files.** Rules that must survive session resets go into agent contracts + the checklist, not (only) memory.
4. **The boundary is researched + cited, never asserted.** Every B2C/B2B classification row traces to an official Spoke source.

## Data flow

Not applicable — no runtime data flow changes. The "flow" this sprint shapes is the *authoring* flow for future areas:

### Future Spoke-clone area authoring flow (Track 1, post-restructure)

1. Agent enters an Área 6–9 microsprint → opens the thin stub (which says "the baseline IS the spec; inspect live first").
2. Confirms M54 connected + Spoke logged in.
3. Invokes `spoke-microsprint.js` with `areaSlug` + the live baseline files → Phase 0 preflight byte-checks the baseline (halts if the stub still has `[INFERRED]` markers and no real capture).
4. Phase 1 captures the LIVE baseline (the contract, now in the agent def) → halts to Eduardo on any architectural surprise.
5. Phases 2–4 research → implement (BLOCKED_SPEC_OUTDATED if baseline contradicts stub) → dual review.
6. Before declaring the area done: if navigation changed, the `integration_test/` gate (now in the checklist) requires an on-device test.

### Future original-feature authoring flow (Track 2, post-restructure)

1. Agent enters Slice 4/5/6/7 → there is NO Spoke equivalent, so NO `spoke-parity-checker`, NO live inspect.
2. Run `superpowers:brainstorming` → write a full spec → write a full plan → execute. (The normal heavyweight path, because the architecture is genuinely undecided — unlike clone areas where Spoke decides.)

## Libraries

None. This sprint introduces no runtime dependency. (Workflow JS uses only the Workflow DevKit primitives already available; no `package.json` change.)

## ADRs filed during this restructure

- **ADR-NNNN — Spoke Route Planner (B2C) vs Spoke Dispatch (B2B) scope boundary.** Records the researched classification + the decision rule + the "already-clean" verification, so the boundary is a versioned decision, not just an inventory doc. Filed in MS1. (Number assigned at authoring time — next free after the current max; the plan's MS1 reads the directory to pick it.)

No other ADR needed — the workflow generalization, contract promotion, and gate additions are process refinements under existing ADR-0036 (spoke-parity gate) and ADR-0018 (in-loop validation), cross-referenced rather than re-decided.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **The "restructure" balloons into rewriting the roadmap/inventory** | Q1 locks keep-and-harden; §Non-goals forbids wholesale rewrites; principle #1 forbids `lib/` edits. MS2 is *annotations* (2 rows + 1 section), not a rewrite. |
| **Generalizing the workflow breaks the working area5 gates** | MS3 preserves every halt gate verbatim (the plan diffs them line-for-line); `areaSlug` defaults to back-compat behavior; a dry-run validation (`Workflow` syntax check) before committing. |
| **A future agent still trusts a stale baseline despite the contract** | The contract is belt-and-suspenders: agent-def clause + checklist checkbox + the workflow's Phase 0 `[INFERRED]` byte-check that HALTS. Three independent guards, two of them mechanical. |
| **B2C/B2B boundary doc itself becomes stale (Spoke ships a new product)** | The doc carries its research date + source URLs; the live-inspect contract means any area touching an ambiguous feature re-checks against live Spoke anyway. |
| **Thin stubs get mistaken for "no spec needed → skip live inspect"** | Each stub leads with "the baseline IS the spec — inspect live FIRST" and carries an active `[INFERRED]` marker that makes the workflow preflight HALT until a real baseline replaces it. |
| **Skill re-registration breaks `/area5-microsprint` mid-flight** | MS3 either aliases the old name or updates every caller; the plan greps for `area5-microsprint` references before renaming and updates them in the same commit. |
| **Multi-session execution loses context** | Each MS is self-contained with its own gates + a handoff note; this spec is the durable anchor; MS1 (boundary doc) lands first so the rest has a stable reference. |

## Accessibility (Karpathy 3 minimum)

Not applicable — this sprint ships no UI. Documentation tables use proper Markdown headers for screen-reader navigability; that's the only a11y surface and it's inherent to the format.

## Test strategy

| Layer | Tool | What it covers in this sprint |
|---|---|---|
| Docs | `/docs-lint` + manual link check | boundary doc linked correctly; no broken cross-refs introduced; roadmap annotations well-formed |
| Workflow | `Workflow` syntax validation (dry parse) + a no-op invocation guard | `spoke-microsprint.js` parses; required-args validation still fires; halt-gate logic intact |
| Static (regression guard) | `flutter analyze`, `flutter test`, `bun run typecheck` | proves NO code regressed — analyze ≤ 23 pre-existing, test ≥ 249, typecheck clean (since no `lib/`/`src/` touched, these must be unchanged) |
| Scope | `git diff --stat` | every commit's diff stays inside `docs/`, `.claude/`, `.gitignore`, memory |

**Tech debt explicit (added to `TODO.md` in the PR):**

- *2026-06-06:* The thin stubs for Áreas 6–9 carry `[INFERRED]` markers by design — they are deliberately incomplete until each area's live baseline is captured. This is not debt to "fix"; it's the guard. Noted so a future docs-lint doesn't flag them as unfinished.

## Verification gates (per `M2-SLICE-CHECKLIST.md`, adapted for a docs/harness sprint)

To declare this restructure done, on `chore/restructure-b2c-harden`:

- [ ] B2C/B2B boundary doc exists, every classification row cited to an official source, linked from roadmap + inventory.
- [ ] Roadmap rows `:132` and `:253/259` annotated B2C; two-track execution section added; boundary doc linked.
- [ ] `.claude/workflows/spoke-microsprint.js` exists with all gates preserved; skill registration resolved; `Workflow` parse-validates.
- [ ] `spoke-parity-checker.md` + `M2-SLICE-CHECKLIST.md` carry the live-inspect-per-feature contract.
- [ ] `M2-SLICE-CHECKLIST.md` carries the `integration_test/` per-area gate.
- [ ] Thin `[INFERRED]`-tagged stubs exist for Áreas 6–9.
- [ ] `/tmp/spoke-*` confirmed empty; `.gitignore` guards inspection captures.
- [ ] Dangling memory pointer (`feedback_spec_drafting_requires_live_widget_baseline.md`) fixed.
- [ ] `flutter analyze` ≤ 23 pre-existing issues (no new); `flutter test` ≥ 249; `bun run typecheck` clean.
- [ ] `git diff main...HEAD --stat` shows NO `apps/*/lib/` or `apps/*/src/` file.
- [ ] `/docs-lint` green for the touched docs.
- [ ] `adr-guardian` clean on the new ADR; restructure report written; PR opened (only at sprint end, not before).

## References

- `CLAUDE.md` — operating manual + Karpathy 4 + source-of-truth hierarchy (ADR-0035).
- `docs/08-ROADMAP-v2.md` — the roadmap this restructure clarifies (rows `:132`, `:253`, `:259`).
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — §7.1 (13 locked directives, esp. #7.2 + #13), §12 gap table (B.7/B.7b/B.10).
- `docs/M2-SLICE-CHECKLIST.md` — the gates this sprint extends.
- `.claude/workflows/area5-microsprint.js` — the workflow being generalized.
- `.claude/agents/spoke-parity-checker.md` — the agent gaining the live-inspect contract.
- `docs/superpowers/specs/2026-06-04-revalidation-backfill-sprint.md` — the complementary sprint (built-surface revalidation).
- `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` — the audit whose findings motivated this restructure.
- ADR-0030 — single-tier Stripe Pix model (the cut that already removed the one B2B feature).
- ADR-0035 / ADR-0036 — Spoke white-label + spoke-parity gate (the umbrella this restructure refines).
- Memory: `feedback_spoke_evidence_per_ms` (live-inspect per feature), `feedback_spoke_parity_zero_debt_per_ms`, `feedback_escalate_recurring_and_gate_check`, `feedback_spec_baseline_and_workflow_halt`, `lesson_slice_checklist_integration_test_gate`, `lesson_spoke_visual_inspection_before_coding`, `project_pivot_2026_05_26_spoke_functional_clone`, `project_device_is_m54`.
- Official Spoke/Circuit sources (researched 2026-06-06):
  - help.getcircuit.com/en/articles/7262745 — "Difference between Circuit for Teams and Circuit Route Planner" (301→help.spoke.com; Teams = dispatcher/business, Route Planner = solo).
  - getcircuit.com/teams — Spoke Dispatch (B2B: live tracking, assign stops, analytics, customer notifications, Shopify/Zapier).
  - spoke.com/route-planner + Google Play `com.underwood.route_optimiser` — Spoke Route Planner (B2C: time windows + priority + POD + package finder + breaks + voice).
  - routific.com/blog/circuit-for-teams-route-planner-review-and-alternatives — third-party confirmation of the Teams=Dispatch rebrand + dispatcher feature set.
