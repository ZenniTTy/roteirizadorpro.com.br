# ADR-0036: Spoke functional parity gate — `spoke-parity-checker` subagent at D4 of every Spoke-aligned microsprint

- **Status:** Accepted
- **Date:** 2026-05-26
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Extends:** ADR-0035 (Spoke functional / prototype visual hierarchy)
- **Related ADRs:** ADR-0010 (functional fork positioning — legal boundary), ADR-0018 (in-loop auto-validation pattern), ADR-0021 (slice-2 fidelity remediation parent — workflow pattern), ADR-0027 (`flutter-perf-auditor` subagent — sibling visual/perf gate pattern), ADR-0029 (alchemist golden tests — sibling automated check pattern)

## Context

ADR-0035 (filed 2026-05-26) re-established the source-of-truth hierarchy: Spoke (ex-Circuit Route Planner) is canonical for behavior/flows/navigation/settings, the `prototipo/` is canonical for visual identity tokens only, cliente Ueslei is final tiebreaker. The same day, the `prototype-fidelity-checker` subagent was re-scoped to visual-only assertions per ADR-0035; structural and flow checks were explicitly removed from its responsibility.

This left a verification gap: **no automated or semi-automated gate exists for "did the implementation actually match Spoke's behavior."** The pre-pivot answer was the `prototype-fidelity-checker` flagging structural divergences against `prototipo/screens-*.jsx`. Post-pivot, that subagent only checks tokens; functional parity falls back to manual human review during slice sign-off.

Eduardo identified this as the most serious omission of the v2 roadmap: "como vai ser toda validação do que for feito, para saber se está idêntico? Acho que não temos nenhum gate." The roadmap-v2 instruction "Spoke deep-dive per microsprint before its `/new-spec`" is an UPFRONT gate (understand before coding), not a CLOSING gate (validate after coding). Without a closing gate, slice-2 will repeat the slice-1.5/MS-15a anti-pattern: green tests + green analyze + manual smoke that misses behavioral divergences because no one checked side-by-side.

The slice-2 audit cycle from session 26 (manual M54 smoke after MS-15a closed) already proved that **post-implementation device validation catches things upstream automated checks miss**. The decision is to formalize that pattern as a dedicated subagent so it lands consistently, with audit trail, and doesn't depend on Eduardo remembering to run it.

## Decision

**Create the `spoke-parity-checker` subagent** at `.claude/agents/spoke-parity-checker.md`. The subagent:

1. Operates as a **read-only D4 verification gate** for every microsprint in slice 2 (Spoke-aligned Telas Core, microsprints MS-A1..MS-A8) and slice 3 (Real backend for Spoke parity, MS-B1..MS-B9).
2. Inspects the reference Spoke instance (`com.underwood.route_optimiser` on Eduardo's M54, package licensed to Eduardo's account) at runtime via `adb shell uiautomator dump` + `adb exec-out screencap -p` for a named flow, then inspects the Roteirizador Pro equivalent flow the same way.
3. Produces a Markdown punch list categorized must-fix / should-fix / nit, plus a "Steps mapped" side-by-side table per flow.
4. Operates within the ADR-0010 legal boundary: structural functional observation only; no decompilation, no asset extraction, no reproduction of Spoke microcopy/icons/typography in reports or suggested code.
5. Consults `docs/inventory/2026-05-26-spoke-vs-rotpro.md` first as prior knowledge baseline, then re-inspects live. Proposes inventory amendments at the end of its run when it discovers Spoke behavior not yet covered.
6. Is dispatched per microsprint by the controlling agent at the D4 review stage (same trigger pattern as `prototype-fidelity-checker` and `flutter-perf-auditor`); is NOT a git pre-commit hook (too expensive per commit at ~5-10 min adb session per dispatch).

The subagent's tool allowlist is `Read, Grep, Glob, Bash` — same as the other read-only sibling subagents, with Bash needed for adb commands. Edit/Write are intentionally excluded so the subagent cannot mutate code or the inventory directly (the controlling agent applies any inventory amendments based on the subagent's recommendation).

## Options Considered

### Option A — Manual Spoke deep-dive checklist embedded in each spec

Add a "Spoke parity checklist" section to every spec template (`docs/superpowers/specs/0000-template.md`) with N items specific to the microsprint, generated during brainstorming. Eduardo manually walks through each item on the M54 before opening the PR.

- Pros: zero new automation; uses existing spec discipline; minimal harness change.
- Cons: trivially skippable; Eduardo's time is the bottleneck; manual comparison misses things AI inspection catches (subtle navigation hierarchy, gesture mapping); checklist quality degrades across microsprints as the human author fatigues.
- Rejected.

### Option B — Inline inspection by the controlling agent at D4 (no dedicated subagent)

The controlling agent (whoever is running the microsprint) runs the adb inspections inline at D4 as a manual step, without a dedicated subagent. Effectively what session 26 already did for MS-15a-followup.

- Pros: zero new subagent files; uses tools already available.
- Cons: pollutes the controlling agent's context with adb output and screenshots, eating into the budget for other work; not isolated, so quality varies by what the controlling agent feels like checking; no audit trail in a consistent format.
- Rejected.

### Option C — **Dedicated `spoke-parity-checker` subagent dispatched at D4**

This decision. New subagent isolated from controlling agent context; consistent report format; explicit legal boundary in the prompt; pre-run prerequisite checks (M54 connected, both apps installed, Eduardo logged in); inventory consultation step before live inspection; verification step before reporting Must-fix.

- Pros: consistent gate per microsprint; report format trivial to compare across sprints (audit trail); subagent isolation keeps the controlling agent's context clean; ADR-0010 legal guardrails baked into the prompt body so future controlling agents inherit them automatically.
- Cons: one more subagent to maintain; per-dispatch cost ~20 min (adb dumps + screenshots + comparison + report write).
- Accepted.

### Option D — Automated golden flow tests (Espresso-style integration tests targeting both apps)

Write integration tests in a separate test harness (e.g. UIAutomator instrumentation) that drive both apps through the same flow and assert equivalence in dumped XML structure.

- Pros: fully automated; runs in CI; produces machine-checkable assertions.
- Cons: massive setup cost (UIAutomator harness, fixture generation, golden XML maintenance); fragile against Spoke updates (Spoke version bump = all goldens regenerated); requires Spoke license on CI device which is operationally awkward; the comparison itself needs intelligence (structural equivalence ≠ XML equality) which loops back to needing an LLM. Maybe right post-M2 if maintenance burden of Option C becomes excessive.
- Rejected for M2; revisit post-slice-7.

## Implementation summary

1. **New file** `.claude/agents/spoke-parity-checker.md` (already authored alongside this ADR, see §"Workflow" in the subagent file for the full operational contract).
2. **M2-SLICE-CHECKLIST.md** `§Verification` updated to list `spoke-parity-checker` as a HARD GATE for any microsprint touching Telas Core (slice 2) or Spoke-aligned backend behavior (slice 3). Slices 4 (Stripe paywall, original RotPro UX), 5 (sentido casa, original RotPro feature), 6 (LGPD, legal-only), and 7 (admin panel, original RotPro) are explicitly OUT of the gate's scope because they have no Spoke equivalent to compare against.
3. **`docs/08-ROADMAP-v2.md`** updated: each microsprint MS-A1..MS-A8 + MS-B1..MS-B9 lists `spoke-parity-checker` dispatch as a step in its D4 review. Microsprints whose flow is in inventory §9 "not inspected" carry an additional note that the subagent's first run on that flow will also amend the inventory.
4. **`.gitignore`** adds `/tmp/spoke-inspection/` and `/tmp/rotpro-inspection/` (no-op since `/tmp/` is OS-level temp, but the absolute-path pattern in scripts may surface inadvertent project-relative copies). Also adds `apps/mobile/integration_test/.spoke-cache/` and similar working dirs that the subagent might use in future for screenshot deltas.
5. **The subagent's prompt body** ends with a "When to abort vs report partial" section so failures (M54 disconnected, Spoke in unexpected state) yield clear partial reports rather than silent skips.

The subagent runs in foreground (not background) when dispatched at D4 because the controlling agent needs its findings to decide whether to proceed to PR or loop back for fixes. Background-mode would only make sense if the subagent's run took >30 min, which it shouldn't.

## Consequences

**Positive:**
- Slice 2 and slice 3 microsprints now have a closing gate that mechanically forces side-by-side validation. Eduardo's "como vai ser toda validação" question has a defensible answer for every microsprint going forward.
- The subagent's legal-boundary section in its prompt body inherits the ADR-0010 stance and propagates it to every future agent that dispatches it — no controlling agent can accidentally instruct it to copy Spoke microcopy because the refusal contract is in the subagent itself.
- Inventory `docs/inventory/2026-05-26-spoke-vs-rotpro.md` becomes auto-evolving: every parity check that hits a §9 "not inspected" flow amends the inventory in its report, so coverage grows over time.
- Audit trail: every microsprint PR will reference its parity report, so the cliente sign-off conversation has consistent evidence per slice.

**Negative:**
- ~20 min per dispatch × 17 microsprints across slices 2+3 = ~6 hours of subagent runtime budget over the v2 roadmap. Worth it but should be tracked.
- Requires the M54 connected, both apps installed, Eduardo logged in to Spoke. If those prereqs fail the gate degrades to manual checklist (Option A as fallback).
- The subagent's report quality depends on the inventory's quality. If the inventory has stale or inaccurate Spoke descriptions (e.g. Spoke version bumped and the flow changed), the subagent might miss real gaps. Mitigation: the subagent re-inspects live every run, so the inventory is reference-not-authority during execution.
- Adds one more subagent to maintain. If the agent registry binds at session boot (as ADR-0031 observed for `flutter-test-author`), Eduardo may need to restart Claude Code once after this commit lands before the subagent is dispatchable in the current session.

**Neutral:**
- Slices 4/5/6/7 are unaffected — they have no Spoke equivalent to compare against. The subagent is opt-out for those slices.
- The `prototype-fidelity-checker` (visual-only post-ADR-0035) and `flutter-perf-auditor` continue their existing roles. The three subagents are complementary, not overlapping: visual / performance / functional-parity respectively.

## Rollback

If `spoke-parity-checker` proves more friction than value during slice 2 execution:

1. Demote the subagent from HARD GATE to OPTIONAL in M2-SLICE-CHECKLIST.md.
2. Replace the per-microsprint gate with Option A (manual checklist per spec) plus an explicit Eduardo sign-off bullet at PR opening.
3. Mark this ADR Superseded with a successor ADR documenting the friction observed (specific examples) and the demotion rationale.

Rollback cost: ~15 min of doc edits; no code revert needed.

## Verification

This ADR is verified by:

- **Inline at adoption (this commit):** the subagent file at `.claude/agents/spoke-parity-checker.md` exists and validates against the standard frontmatter (name, description, tools allowlist, model). M2-SLICE-CHECKLIST.md cites the subagent in `§Verification`. ROADMAP-v2 cites the subagent in each slice-2 + slice-3 microsprint's D4 step.
- **First real dispatch (MS-A1 D4):** the subagent runs end-to-end on the Route entity flow, produces a punch list, the cliente Ueslei can read the report and validate the comparison was meaningful. If the first real dispatch reveals operational friction (slow, unclear output, false positives), file a follow-up ADR amending the workflow before MS-A2.
- **Steady state (slice-2 close, post-MS-A8):** retrospective on parity reports across the 8 microsprints; assess whether the gate caught real gaps that the test suite + visual checker would have missed; revisit Option D (automated UIAutomator) if maintenance burden of Option C grows beyond ~30 min average per dispatch.

## Amendment History

### 2026-05-26 (same day, before first MS-A1 dispatch): upfront usage made the default

**Trigger:** during MS-A1 brainstorming, Eduardo asked "não seria mais fácil você já simplesmente extrair o visual da Spoke no meu APP que já está conectado e depois codar ele na Roteirizador?" — pointing out that asking him UI/UX questions Spoke already answers structurally is friction, and that the inspection should be the default behavior rather than something I offer.

**Original framing (rejected as too narrow):** the subagent was scoped only to D4 closing verification. The ROADMAP-v2 mention of "Spoke deep-dive per microsprint before its `/new-spec`" was advisory rather than mandated, and was being executed as an inline ad-hoc step by the controlling agent rather than via the subagent.

**Amendment:** the subagent is now dispatched at **two points** in every Spoke-equivalent microsprint:

1. **UPFRONT during brainstorming** — before the spec is written. Builds a structural baseline so the spec author knows what Spoke does (number of steps, what UI primitives Spoke uses, what state transitions exist) and so UI/UX questions to Eduardo are limited to (a) decisions Spoke doesn't cover, (b) directives that override Spoke, (c) one-line device-readiness confirmation. At the upfront dispatch the RotPro side of the comparison may be empty/stub because no code has been written yet — that is expected; the report focuses on Spoke's structural facts.
2. **CLOSING at D4** — unchanged from the original ADR. Verifies the implementation matches the upfront baseline.

**Why two dispatches not one:** the upfront baseline informs design choices that can't be re-done at D4 (e.g. data model shape, navigation hierarchy); the D4 dispatch verifies the implementation actually delivered those choices and catches regressions introduced during implementation. The two dispatches are roughly the same cost (~10-20 min adb session each); the upfront cost is recovered by skipping 4-5 UI/UX questions in brainstorming that would have taken 10-15 min of back-and-forth with Eduardo per microsprint.

**Implementation:**
- `.claude/agents/spoke-parity-checker.md` frontmatter `description` updated to document both dispatch points.
- `CLAUDE.md` §"Source-of-truth hierarchy" gained a new §§"Spoke deep-dive default behavior" subsection codifying the rule for future controlling agents.
- `docs/M2-SLICE-CHECKLIST.md` §"Pre-flight" gained a new checkbox for the upfront dispatch (the existing D4 HARD GATE checkbox in §Verification is unchanged).

**Cost re-estimate post-amendment:** ~20 min × 2 dispatches × 17 microsprints = ~11 hours subagent runtime over the v2 roadmap (up from ~6 hours). Still worth the savings on Eduardo's brainstorming time (~10-15 min × 17 = ~3 hours of human time saved) plus the higher-quality specs that result from having Spoke's structural facts on the table before deciding scope.

**Out of scope for this amendment:** slices 4/5/6/7 remain opt-out exactly as the original ADR specifies. The two-dispatch pattern only applies where there's a Spoke flow to compare against.

## References

- ADR-0035 — Spoke functional / prototype visual hierarchy (this gate's prerequisite).
- ADR-0010 — Functional fork positioning (legal boundary the subagent inherits).
- ADR-0027 — `flutter-perf-auditor` subagent (sibling pattern: read-only D4 gate with categorized punch list).
- ADR-0029 — `alchemist` golden tests (sibling pattern: automated visual delta check).
- ADR-0018 — In-loop auto-validation (workflow pattern this gate extends to a slower, manual-trigger cadence).
- `.claude/agents/spoke-parity-checker.md` — the subagent file.
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — baseline the subagent consults.
- `docs/M2-SLICE-CHECKLIST.md` §"Verification" (updated in same commit).
- `docs/08-ROADMAP-v2.md` slices 2 + 3 (updated in same commit).
