# ADR-0021: Slice 2 fidelity remediation — retroactive audit + microsprint correction loop

- **Status:** Accepted
- **Date:** 2026-05-19
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0010 (prototype canonical), ADR-0015 (M2 plan), ADR-0018 (harness auto-validation), ADR-0019 (spec-driven templates)

## Context

Slice 2 (Telas Core) was implemented across sessions 12–16 and reached a candidate `v1.1.0` release APK on 2026-05-19. The first end-to-end smoke test on a physical Galaxy A06 (Android 16) — performed in session 17 right before opening the `develop` PR — surfaced four immediate divergences from the canonical prototype (`prototipo/screens-*.jsx`, see ADR-0010):

1. `ScreenAddStop` is implemented as a full-screen scaffold instead of a bottom sheet over a blurred home (`prototipo/screens-a.jsx:288-360`).
2. The 3-method chips (Teclado / Voz / Câmera) are missing — making `voice_capture_page.dart` and `ocr_capture_page.dart` reachable only via deep-link, not from the UI (`prototipo/screens-a.jsx:316-344`).
3. The address autocomplete suggestions list is absent (`prototipo/screens-a.jsx:345-358`).
4. Android back-button on `AddStop` minimizes the app instead of returning to home (router uses `context.go` everywhere, never `push`).

These were not caught by:

- The full-slice `prototype-fidelity-checker` audit run on 2026-05-19 against the static widget tree (it compares widget-to-widget but did not exercise navigation flow).
- The full-slice `adr-guardian` audit (it checks ADR compliance, not visual fidelity).
- The 91 widget tests (they test widgets in isolation; none assert end-to-end navigation or compose the bottom-sheet structure).
- The lefthook + Stop hooks (analyze + typecheck pass; they don't inspect UI structure).

The gap between "all gates green" and "device reveals four Criticals" indicates a **process bug**, not just a code bug: we shipped each task with widget-test + analyzer + fidelity-static gates, but we never gated against device-fidelity E2E. Worse, if four Criticals exist in the one screen we happened to open first, others likely exist across the remaining 17 screens.

This ADR codifies the **remediation process** so that:

1. We pause slice 2 promotion (`develop` → `main` → tag `v1.1.0`) until a full retroactive audit is complete.
2. We catalog every divergence (Critical / Important / Minor) across all 18 slice-1+2 screens.
3. We correct every Critical (Important and Minor become explicit, dated debt in `TODO.md`).
4. We add device-E2E as a hard gate in `M2-SLICE-CHECKLIST.md` for all future slices.

## Options Considered

### Option A — Ship `v1.1.0` as-is, document divergences as slice-3 polish debt

- Pros: fastest path to client delivery; zero rework cost today.
- Cons: voice and OCR are unreachable UI-dead-code, which violates the slice-2 acceptance criterion in `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md:35` ("Add 5 stops via mixed methods: 2 by typing, 1 by voice, 1 by photo, 1 by tap on map"). Client could legitimately reject the slice. **Rejected.**

### Option B — Fix only the 4 Criticals discovered in the first E2E step (token-cheap)

- Pros: small surface area; 4–8 hours of work; addresses what we know.
- Cons: false confidence. If one screen has 4 Criticals, the other 17 probably also have them. Shipping after fixing only the visible 4 just delays the next round of discovery. **Rejected.**

### Option C (this ADR) — Full retroactive audit + microsprint correction loop

Two-phase approach with explicit gates:

**Phase 1 — Audit (read-only):**
A single `prototype-fidelity-checker` agent (token-efficient — loads `prototipo/` into context once and iterates) sweeps all 18 slice-1+2 screens and outputs a catalog of Critical / Important / Minor divergences. No code changes.

**Phase 2 — Microsprint correction:**
For every screen with at least one Critical, one microsprint runs the full pipeline:

```
PRE-FLIGHT (controller)
  → read prototype lines + current implementation
  → state delta in 1–3 bullets
DISPATCH 1: prototype-fidelity-checker (single-screen, read-only)
  → confirms Criticals + line cites
DISPATCH 2: implementer (isolated context, fixes only Criticals)
  → runs `flutter analyze` + relevant `flutter test`
DISPATCH 3: prototype-fidelity-checker (re-audit, single-screen)
  → confirms Criticals closed, no new regressions
DISPATCH 4: pr-review-toolkit:code-reviewer
  → Karpathy 4 principles + repo conventions
COMMIT (lefthook + commitlint + stop-hooks gate the commit)
```

Importants and Minors that are not safety-critical become dated debt entries in `TODO.md` (slice-3 polish or later). Importants that touch shipping behavior (e.g., missing back-arrow on a top-level screen) escalate to Critical and get fixed in the same microsprint.

**Phase 3 — Re-audit + device E2E:**
Final paralleled `prototype-fidelity-checker` over all 18 screens + a 14-step golden-path E2E on the Galaxy A06 + `/verify-slice` skill before tagging `v1.1.0`.

- Pros: only fixes what is actually broken (skips screens that pass audit); leverages existing harness agents; produces a complete inventory of slice-2 fidelity; closes the process gap by adding device-E2E to the checklist for future slices.
- Cons: 2–4 days of wall-time before tag. Acceptable: M2 contract has no hard deadline, and shipping a broken-by-spec slice 2 would cost more in client trust than the delay.

## Decision

**Adopt Option C.** Branch remains `feat/m2-slice-2-telas-core` (no fork) to preserve continuous slice-2 history. Spec + plan files are created under `docs/superpowers/specs/2026-05-19-slice-2-fidelity-remediation.md` and `docs/superpowers/plans/2026-05-19-slice-2-fidelity-remediation.md` per ADR-0019 templates. Slice-2 promotion PR (`feat/m2-slice-2-telas-core` → `develop`) is blocked until Phase 3 passes.

## Consequences

- **Positive:** every slice-2 screen will be evidenced-fiel to `prototipo/`; future slices inherit the device-E2E gate; voice/OCR become reachable, satisfying slice-2 acceptance criterion §35; the audit-catalog itself becomes a reference for future fidelity discussions.
- **Negative:** slice-2 ship slips by 2–4 days from the 2026-05-19 originally-planned tag. Slices 3–7 timeline absorbs the slip; the 15-day allowance the client mentioned still fits.
- **Process change:** `docs/M2-SLICE-CHECKLIST.md` §Verification gets a new mandatory bullet — "Device E2E golden-path (physical Android, not emulator) before tag." This becomes a hard gate for slices 3 through 7.
- **Neutral:** `prototype-fidelity-checker` agent definition (`.claude/agents/prototype-fidelity-checker.md`) does not change — its limitation (static widget compare, no navigation-flow exercise) is now compensated by the device-E2E gate, not by changing the agent.

## Implementation Notes

The microsprint pipeline above is the canonical execution flow for this ADR. The controller is responsible for never running two microsprints in parallel — each one fully completes (including commit) before the next starts. This serializes the correction loop and keeps `git log` linear, which simplifies future code review.

Naming: commits in this remediation use scopes from `commitlint.config.cjs`:

- `fix(mobile): <screen> — <one-line>` for a Critical fix on one screen.
- `refactor(mobile): <area> — <one-line>` for restructuring that does not change behavior (e.g., back-nav `go → push`).
- `docs(decisions): adr-0021 audit findings` for the final catalog commit.

A `docs(sessions): 2026-05-19-17-slice-2-fidelity-audit.md` log will close the loop in the standard session-end commit.

## References

- ADR-0010 — Clone positioning + prototype canonical.
- ADR-0015 — M2 plan, library choices, slice-2 acceptance criterion (referenced via §35 of the slice-2 spec).
- ADR-0018 — Harness auto-validation; documents that Stop hooks are signal-only and do not gate.
- ADR-0019 — Spec-driven templates; this remediation's spec + plan files follow them.
- `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md:35` — the acceptance criterion this ADR enforces.
- `prototipo/screens-{a,b,c,d,e}.jsx` — the canonical source the audit compares against.
- Session log `docs/sessions/2026-05-19-17-slice-2-fidelity-audit.md` (filed at remediation close).
