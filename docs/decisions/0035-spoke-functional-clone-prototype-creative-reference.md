# ADR-0035: Spoke is the functional/UX source of truth; the prototype is creative visual reference

- **Status:** Accepted
- **Date:** 2026-05-26
- **Deciders:** Eduardo (cliente Ueslei representative + product owner)
- **Extends:** ADR-0010 (functional fork positioning — remains foundational)
- **Reframed at filing time:** ADRs 0021/0032/0033/0034 (slice-2 microsprint-specific decisions whose framing dependia da premissa antiga "prototipo canonical UI"). Essas 4 ADRs foram **deletadas no reset 2026-05-26** (limpeza completa do bloat slice-2); histórico preservado no git log.
- **Related ADRs:** ADR-0010 (clone positioning — foundational)

## Context

ADR-0010 (2026-05-05) positioned the project as a **functional fork** of Spoke (formerly Circuit Route Planner). Original visual identity is mandatory for legal safety. The decision was clear: replicate flows, navigation, behaviors, gestures, and screen structure from Spoke; produce all colors, typography, icons, microcopy, and illustrations from scratch.

When the Claude Design prototype (`prototipo/`) was delivered and client-approved on 2026-05-07, the project's docs treated it as the **canonical UI source of truth**: README, CLAUDE.md, multiple ADRs, the M2-SLICE-CHECKLIST verification gate, the `prototype-fidelity-checker` subagent, and 12+ microsprint entries in TODO.md all asserted that "the prototype wins" and that screens "must match `prototipo/screens-*.jsx` 1:1 in visual identity, structure, and flows."

This drift introduced two compounding problems:

1. **Wrong layer of authority.** The prototype is a sketch of one designer's interpretation, not the user-facing behavior the cliente contracted. The actual UX guide is Spoke itself — the app real motoboys already use daily. When `prototipo/` and Spoke disagreed (which they did frequently — the prototype is incomplete on several flows and outright wrong on others), the canonical chain ran into Spoke, not back into the prototype.
2. **Mounting "accepted divergence" debt.** ADRs históricas (deletadas no reset 2026-05-26) eram forçadas porque manual smoke no Samsung M54 revelava que strict prototype adherence produzia UI pior do que cliente Ueslei esperava. Cada "divergence ADR" era sintoma da declaração errada de source-of-truth. Continuar nessa trajetória significava filar uma ADR dessas por microsprint indefinidamente.

During the MS-15a-followup session (2026-05-25), Eduardo articulated the correction: the prototype is a **creative reference for visual identity** (palette, typography, icons, animations, "creative touch") — not a binding specification for screens, gestures, or flows. The functional spec is Spoke, because Spoke is what end-users already know.

## Decision

**Re-establish the source-of-truth hierarchy with three explicit, ordered layers:**

1. **Spoke (Circuit Route Planner)** — canonical for behavior, navigation, settings inventory, feature presence, gestures, and flow ordering. When deciding what the app does or how a user moves through it, Spoke wins.
2. **`prototipo/` (Claude Design prototype)** — canonical for **visual identity only**: color tokens (`prototipo/tokens.js`), spacing scale, radii, shadows, typography pairing, icon family (Lucide), and any decorative or animation pattern that is the prototype's original creative contribution.
3. **Cliente Ueslei** — final tiebreaker on any conflict. Per ADR-0010, the cliente is the contracting authority and has standing to override either layer above.

This hierarchy **extends** ADR-0010 rather than superseding it: the "functional fork with original visual identity" stance is unchanged. ADR-0035 only specifies *where* the functional spec lives (Spoke, not the prototype) and *where* the visual identity lives (the prototype, not Spoke).

## Options Considered

### Option A — Keep `prototipo/` as canonical UI; absorb divergences via per-decision ADRs

Continue filing "divergence ADRs" each time a cliente preference or Spoke behavior conflicts with the prototype.

- Pros: No restructure cost; existing tooling (subagent, skills, hooks) keeps working.
- Cons: Symptom-driven; produces an unbounded series of "accepted divergence" ADRs; the prototype's gaps (missing flows, sketch-quality details) remain unresolved; future contributors keep tripping over the same wrong-layer assertion. Rejected.

### Option B — Declare Spoke as the sole canonical UI; relegate `prototipo/` to legacy artifact

Strip prototype references from the verification gates entirely.

- Pros: Single source of truth; no two-layer confusion.
- Cons: Throws away a real client-approved visual identity that took weeks to produce; visual tokens (`tokens.js`) are still the foundation of the implemented design system and rewriting that costs days of work for no benefit. Rejected.

### Option C — **Two-layer hierarchy: Spoke for behavior, prototipo for visual identity, cliente for tiebreak.**

This decision.

- Pros: Both source artifacts keep their value; each is canonical only for what it's genuinely authoritative on; future "divergence" cases resolve via the hierarchy without new ADRs (visual decisions go to the prototype, functional decisions go to Spoke, conflicts go to the cliente). Eliminates the wrong-layer category of error.
- Cons: Requires a one-time sweep of binding language across docs, ADRs, the subagent, and TODO.md (~24 sites). Adds a small ongoing cost: when a screen needs both visual and functional review, both sources are consulted. The cost is bounded and predictable.

### Option D — Reverse-engineer Spoke directly into the codebase (copy Spoke's icons/markup into the shipped APK)

Not considered. The shipped APK uses original visual identity per ADR-0010 — Spoke icons/illustrations/palette/typography don't end up in what users install. Inspection methodology used to study Spoke is unrelated (operator's choice per ADR-0010 Amendment 2).

## Implementation summary

This ADR is **policy**. The execution sweep is documented in `plans/velvet-yawning-thacker.md` and lands as a single commit titled `docs(pivot): realign canonical UI authority — Spoke is functional, prototipo is creative (ADR-0035)`. The sweep covers:

- 5 primary binding sites: `README.md`, `CLAUDE.md` §"UI Source of Truth", `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/M2-SLICE-CHECKLIST.md`.
- Secondary sites: `docs/05-SCREENS.md` header, `docs/03-CONVENTIONS.md` tree comments, a SUPERSEDED banner on `docs/08-ROADMAP.md`.
- `.claude/agents/prototype-fidelity-checker.md` re-scoped to verify only visual tokens (colors, spacing, radii, shadows, typography, icon family). Structural and flow assertions are removed; those move to a future Spoke-functional-parity gate created during Fase 3 if the inventory shows it is needed.
- `TODO.md` slice-2 fidelity-finding entries re-categorized: visual gaps stay open until re-skinned; structural divergences close as non-issues under this ADR.

A separate phase produces a side-by-side inventory of Spoke vs. Roteirizador Pro (current implementation) at `docs/inventory/2026-05-26-spoke-vs-rotpro.md`, which then drives the rewrite of slices 2 and 3 in `docs/08-ROADMAP-v2.md`. Slices 1, 4, 5, 6, 7 are unaffected by this ADR (slice 1 already shipped; slices 4–7 are agnostic of UI source).

**Inspection of Spoke** defaults to runtime UI/UX observation on the cliente's licensed installation (Samsung M54 device, Eduardo's account): screen flows, navigation, settings inventory, gesture mapping. Inspection methodology is operator's choice per ADR-0010 Amendment 2 — runtime is the fast default, other methods (APK inspection, etc.) are allowed when more efficient. What matters legally is what the **shipped APK** contains (original visual identity per ADR-0010 Decision section), not how the engineering team studied Spoke.

## Consequences

- **Positive:** Future microsprints stop generating "accepted divergence" ADRs for the prototype-vs-real-app gap. New ADRs only fire when a genuine architectural decision is required. The two-layer hierarchy gives reviewers (human and subagent) a clear question to ask: "is this a behavioral choice (→ Spoke) or a visual choice (→ prototipo)?"
- **Positive:** ADRs 0033 and 0034 lose the "first formal prototype divergence" framing. They are reclassified as design decisions aligned with Spoke and cliente preference — no longer exceptional.
- **Negative:** One-time sweep of ~24 sites; some risk of grep-missed assertions surfacing in future sessions. Mitigated by the verification grep in the sweep commit (zero matches for residual "canonical UI" / "1:1 with prototip" phrases).
- **Negative:** Inspection of Spoke for UX parity introduces a documentation overhead (the inventory in Fase 2) that did not exist before. This is a one-time cost; the inventory is reusable for every subsequent slice that touches the same flows.
- **Neutral:** The prototype itself is unchanged. `prototipo/tokens.js`, `prototipo/ui.jsx`, the SVG icons, and the color palette remain the foundation of the design system. The change is only in the authority claim made about those artifacts.

## Rollback

If the Fase 2 inspection of Spoke reveals that it is fundamentally incompatible with our stack or scope (for example: the app's core flow depends on a feature we cannot replicate without breaching ADR-0010's "no visual asset copy" line), the rollback is:

1. Revert the single Fase 1 commit (`git revert <sha>`).
2. Mark this ADR as **Superseded** with a successor ADR documenting the discovered incompatibility.
3. Keep ADR-0010 unchanged (the functional-fork stance survives any failure of this specific hierarchy).

Total revert cost: ~1 day. The downstream ADRs (0033, 0034) do not need re-editing because their decisions are correct either way; only the framing in their headers changes.

## Verification

This ADR is verified by:

- **Inline at adoption (Fase 1 commit):** the verification greps listed in `plans/velvet-yawning-thacker.md` §"Verificação end-to-end" return zero hits for residual binding language. Single sweep commit lands.
- **Phase 2:** the inventory document at `docs/inventory/2026-05-26-spoke-vs-rotpro.md` exists, covers every Spoke activity reachable from Eduardo's account, and is approved by Eduardo before Fase 3 begins.
- **Phase 3:** `docs/08-ROADMAP-v2.md` rewrites slices 2 and 3 against the inventory, decomposed into microsprints per ADR-0019.
- **Per future microsprint:** the `prototype-fidelity-checker` subagent (post-rescope) returns visual-only findings; functional gaps are tracked by the inventory document, not by the subagent.

## References

- ADR-0010 — clone positioning (foundational; this ADR extends it).
- ADR-0019 — spec-driven workflow (microsprint decomposition pattern, unchanged).
- ADR-0021 — slice-2 fidelity remediation parent (reframed by this ADR; the remediation work was real and stays valid, just measured against a different yardstick from now on).
- ADR-0032, ADR-0033, ADR-0034 — visual decisions reframed by this ADR.
- `plans/velvet-yawning-thacker.md` — execution plan for the three-phase sweep.
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — Fase 2 output (created during this ADR's execution).
- `docs/08-ROADMAP-v2.md` — Fase 3 output.
