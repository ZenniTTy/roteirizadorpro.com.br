# ADR-0028: Reject `mcp_flutter` for the M2 cycle; revisit if device-E2E cost grows

- **Status:** Accepted (rejection with documented rationale)
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0021 (device-fidelity gate that already addresses the gap mcp_flutter would close), ADR-0022 (integration_test gate for navigation), ADR-0023 (Dart MCP — the official baseline)
- **Sprint:** M2-AI Harness — Phase 5 (decision gate)

## Context

Phase 5 of the M2-AI sprint is a fork: adopt or reject [Arenukvern/mcp_flutter](https://github.com/Arenukvern/mcp_flutter) (v3.0.7, 2026-05-20, debug-only by design). Plugin would let the assistant request a visual + semantic snapshot of the running Flutter app instead of relying on `prototype-fidelity-checker` (static widget-tree audit) plus manual device screenshots.

## Decision

**Reject for the M2 cycle.** Revisit at slice 3+ entry if the manual device-E2E gate (ADR-0021) becomes the bottleneck.

## The four criteria (applied with evidence)

| # | Criterion | Evidence | Answer |
|---|---|---|---|
| 1 | > 10 visual iterations per screen in slice 2? | Session 13 shipped 7 screens in ~22 commits (≈ 3 iterations/screen). MS-01b had 3 failed PopScope attempts. Real pattern is 3–5, not 10+. | No |
| 2 | Static fidelity checker missing real drifts? | **Yes**. ADR-0021 documents 4 Criticals on a single screen that passed `prototype-fidelity-checker` clean but failed device-E2E. | Yes |
| 3 | Cost of `main.dart` instrumentation acceptable? | Plugin is debug-only by design — zero release impact. | Yes |
| 4 | APK release size risk? | Debug-only binary + codegen, not a Dart dep — release tree-shake removes everything. | No risk |

Criterion 2 alone is a strong adopt signal. The reject decision rests on the fact that **the gap criterion 2 names is already closed**: ADR-0021 added device-E2E + screenshot-per-step + integration_test (ADR-0022) as hard gates in `M2-SLICE-CHECKLIST.md`. Adopting `mcp_flutter` now duplicates that gate (MCP-mediated snapshot + manual device screenshot) without evidence that the manual gate is failing.

Criterion 1 is the real reopen trigger: if slice 3 starts averaging > 10 visual iterations per screen, the manual gate is no longer cheap and the MCP path wins.

## Consequences

- **No new dependency, no new MCP server, no main.dart change.** Branch stays clean.
- **Slice-2/3 visual fidelity continues to rely on ADR-0021 + ADR-0022 gates.** If they hold, decision was right.
- **Re-evaluation trigger documented** below — not "maybe someday" but a measurable condition.

## Rollback

This is a rejection. There is nothing to roll back. To reverse the decision, file a superseding ADR-NNNN naming this one, then follow Sub-fase 5a from `docs/sprints/2026-05-24-m2-ai-harness.md`.

## Re-evaluation trigger

Open a new ADR (revisit, not amend) if **either** is true at slice-N entry:

1. Average visual iterations per screen in the last shipped slice > 7 (measured by per-task commit count touching `.dart` files under `lib/features/<feature>/presentation/`).
2. Two consecutive device-E2E gates surface > 2 Criticals each on screens that `prototype-fidelity-checker` cleared.

## References

- `docs/sprints/2026-05-24-m2-ai-harness.md` §Fase 5 (decision criteria + adopt/reject sub-fases).
- ADR-0021 (device-fidelity remediation — the gate that closed criterion 2's gap).
- ADR-0022 (integration_test for navigation — closed the MS-01 back-nav regression).
- ADR-0023 (official Dart MCP — the baseline; this ADR does not affect it).
- Plugin source: github.com/Arenukvern/mcp_flutter v3.0.7 (2026-05-20).
