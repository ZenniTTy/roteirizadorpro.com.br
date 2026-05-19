# Spec — <slice or feature name>

> **Date:** YYYY-MM-DD
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans` | Approved | Superseded by `<other-spec.md>`
> **Branch:** `feat/<slug>` (off `develop` at `<base-sha>`)
> **Source of truth:** `docs/08-ROADMAP.md` "<roadmap section>". This spec elaborates that section; if the two disagree, the ROADMAP wins and the contradiction is a bug to fix in the same PR.

<!--
Reading order for the AUTHOR before filling this file:
  1. CLAUDE.md (the operating manual — Karpathy 4 principles, stack lock, Context7 rule, ADR-0013 contract)
  2. docs/08-ROADMAP.md (canonical scope; the slice's section in particular)
  3. docs/M2-SLICE-CHECKLIST.md (the gates this spec must satisfy)
  4. docs/M2-COST-MODEL.md (the cost ceiling all choices respect)
  5. docs/sessions/0001-INDEX.md (last 5 entries for in-flight context)
  6. The relevant prototipo/*.jsx files (UI source of truth — match 1:1)
  7. The two prior specs in docs/superpowers/specs/ — match their depth and tone

REQUIRED PROCESS before authoring §Context onward:
  Run `superpowers:brainstorming` with Eduardo to lock the decisions that go in §Decisions Locked.
  Slice 2's Q1/Q2/Q3 table is the model. Without a brainstorm, the spec drifts during implementation.
-->

---

## Context

<!--
1–3 paragraphs. Concrete: what shipped before this slice, what gap this slice closes, what stays out.
Name the dependencies (previous slice's artifacts, the prototype screens this slice touches,
the ADRs this slice's choices live under).
-->

## Decisions locked in this brainstorming session

<!--
The Q-table is the load-bearing part of a spec. Each row is ONE decision the brainstorm produced,
with rationale dense enough to be defended six months later. Slice 2 captured Q1 (persistence),
Q2 (default nav provider), Q3 (pricing). Aim for 3–6 questions; if you have more, some are
implementation details that belong in §Architecture instead.
-->

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | <question> | **<decision>** | <why this option given the constraints; what trade-off was accepted> |
| Q2 | <question> | **<decision>** | <…> |
| Q3 | <question> | **<decision>** | <…> |

## Goals (acceptance for this slice)

<!--
Numbered acceptance criteria written as observable user-facing outcomes ON A REAL DEVICE.
Slice 2's 14-step golden path is the model: each step is a UI action the human can perform
and a result the human can verify. Avoid implementation language here — "the app stores X in Y"
is not a Goal; "tap Settings, toggle Z, observe W" is.
-->

A real <device> install of `<version-bump>` can, against production API:

1. <observable action → observable result>.
2. <…>
3. <…>

### Non-goals (explicit, to keep scope tight)

<!--
Slice 2's non-goals list is the model — name each adjacent thing this slice does NOT do
and where it WILL live (slice 3, slice 5, post-M2). Explicit non-goals stop scope creep.
-->

- <thing this slice does NOT do> (<which slice or post-M2 owns it>).
- <…>

## Architecture

### <Layer or module> layout

<!--
For each layer this slice touches (mobile feature module, backend route module, infra, etc.),
draw the file tree of NEW + MODIFIED files. Slice 2 drew apps/mobile/lib/features/stops/
with domain/data/state/presentation sub-folders, naming every file. The reader should be able
to scaffold the empty files from this section alone.
-->

```
apps/<app>/<path>/
├── <new-file>
├── <new-file>
└── <new-folder>/
    ├── <new-file>
    └── <new-file>
```

### <Backend or contract> evolution

<!--
If this slice changes any TypeBox schema, Prisma model, or API contract, name the change here
AND remember the ADR-0013 mirror obligation: every TypeBox edit ships with its matching Dart DTO
in the same commit. The check-dto-mirror.sh hook (ADR-0018) will warn if you forget.
-->

### Architecture principles

<!--
2–5 principles that govern HOW this slice's code is shaped, not WHAT it does. Slice 2 listed
repository swap, DTO/domain split, schema source-of-truth, Riverpod 3 codegen, DI overrides,
no premature abstraction. These are the rules the plan's tasks fall under.
-->

1. <principle> — <one-line consequence>.
2. <…>

## Data flow

<!--
For each non-trivial flow, walk through: which UI surface triggers it → which controller →
which repository → which backend endpoint → which response shape → how state lands back.
Slice 2 did this for Stop model, TypeBox schema evolution, optimize flow, map config,
persistence (SharedPreferencesAsync envelope), permission flow, modern Android opt-ins,
external navigation.
-->

### <Flow name>

<!--
1–2 paragraphs OR a numbered sequence. Be precise about field names and types.
-->

## Sub-slice plan

<!--
If this slice has internal subdivisions (slice 2 had 2a/2b/2c/2d/2e), table them here.
For pure-feature specs without sub-slices, replace this table with a single "Implementation
phases" subsection.
-->

| Sub | Days | Scope | Verification |
|---|---|---|---|
| <2a — name> | <N> | <what lands in this sub> | <how the human verifies this sub before moving to next> |

**Post-sub-slices (≈ <N> day):**

- <release-and-PR steps that close the slice>

**Estimate:** <total> working days ≈ <calendar weeks>, matches the ROADMAP's "<X> estimated" target.

## Libraries

<!--
Every new external library this slice introduces. Stdlib + Flutter-team-maintained packages
are NOT new — they are exempt per CLAUDE.md "Context7 Mandatory". Anything else: Context7
ID and the date you queried it. Cost column matters for the M2-COST-MODEL.md ceiling.
-->

| Purpose | Package | Version target | Cost | Context7 ID (or stdlib rationale) |
|---|---|---|---|---|
| <purpose> | `<pkg>` | <semver> | <BRL/month or 0> | <`/org/repo` or "stdlib exception per CLAUDE.md"> |

<!--
If versions resolve only at install time (e.g. via `flutter pub add`), say so here AND
record the resolved versions in the corresponding ADR (or as an ADR amendment) in the
same commit that installs them.
-->

## ADRs filed during this slice

<!--
- ADR-NNNN — <title>. Filed in sub <X>.
- Decisions that do NOT need a new ADR (utility libs covered by an existing umbrella ADR)
  are listed here with the umbrella ADR's number for traceability.
-->

- **ADR-NNNN** — <title>.

## Risks and mitigations

<!--
Slice 2 listed permission UX confusion, OSM tile rate-limit, mock-endpoint contract drift,
shared_preferences schema drift, Waze single-stop limitation, missing-permission echo
(slice 1 lesson), SharedPreferencesAsync migration. Each row is a real concern with a
concrete mitigation, not a theoretical worry.
-->

| Risk | Mitigation |
|---|---|
| **<concrete risk>** | <concrete mitigation tied to a specific task or commit> |

## Accessibility (Karpathy 3 minimum — not optional)

<!--
Slice 2 enforced: Semantics labels on every primary CTA, tap targets ≥ 48×48 dp,
WCAG-AA contrast audit against prototipo/tokens.js. Every new screen this slice ships
must clear these three before the sub-slice closes. Adjust the minimum if the slice's
nature demands (e.g. a backend-only slice can drop this section with a one-line note).
-->

1. **Semantics labels on every primary CTA.** <which buttons, which labels>.
2. **Tap targets ≥ 48×48 dp.** <which widgets need padding wraps>.
3. **Color-contrast WCAG AA against `prototipo/tokens.js`.** <when the audit happens; where the table lives>.

## Test strategy

<!--
What gets a real test, what gets a smoke check, what stays manual. Be honest about
gaps (e.g. slice 2 declared "no backend unit-test framework today; revisit post-slice-3").
Tests-where-it-hurts principle: payment, route optimization, paywall, OCR, auth.
Not on getters.
-->

| Layer | Tool | What it covers in this slice |
|---|---|---|
| <layer> | <tool> | <coverage scope> |

**Tech debt explicit (added to `TODO.md` in the PR):**

- *<when>:* <what we deferred and why>.

## Verification gates (per `M2-SLICE-CHECKLIST.md`)

<!--
This is the cross-reference back to the universal checklist. Don't redefine gates here —
quote them as a closing checklist the slice must satisfy before opening its PR.
Slice 2 listed: flutter analyze + test, bun typecheck, backend curl smoke,
aapt2 dump permissions, apksigner verify, real-device E2E, prototype-fidelity-checker
subagent, adr-guardian subagent, PR body filled, Vercel preview SUCCESS, promotion PR
+ tag + production smoke, /session-end commit.
-->

To declare this slice done:

- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes (widget tests for each new screen + unit tests where logic warrants).
- [ ] `bun run typecheck` clean in the modified apps.
- [ ] Backend smoke (`curl -i`) captures pasted into the PR body for every new/changed endpoint.
- [ ] `aapt2 dump permissions <built APK>` confirms expected `android.permission.*` entries.
- [ ] `apksigner verify --verbose --print-certs` confirms v2 scheme + cert SHA-256 matches keystore.
- [ ] Real-device E2E: the N-step golden path from §Goals completes. Screenshot every screen.
- [ ] `prototype-fidelity-checker` subagent reports clean against every screen vs `prototipo/`.
- [ ] `adr-guardian` subagent reports clean against the PR diff.
- [ ] `/verify-slice` (ADR-0018) GO verdict.
- [ ] PR body filled per `M2-SLICE-CHECKLIST.md` template.
- [ ] Vercel preview SUCCESS before requesting review.
- [ ] Post-merge: promotion PR `develop` → `main`, tag `vX.Y.Z`, production `curl -sI` confirms.
- [ ] `/session-end` commits the session log + index + TODO + CHANGELOG in one shot.

## References

<!--
Every doc, ADR, prototype file, Context7 query, memory entry, and external source consulted.
Slice 2's references were exhaustive — match that bar. Future agents read this section to
rehydrate context.
-->

- `CLAUDE.md` — operating manual.
- `docs/08-ROADMAP.md` — the section this spec elaborates.
- `docs/M2-SLICE-CHECKLIST.md` — the gates this spec respects.
- `docs/M2-COST-MODEL.md` — the cost ceiling all choices respect.
- ADR-NNNN — <relevant ADRs>.
- `prototipo/screens-*.jsx` — canonical UI source for the screens in scope.
- Memory entry `<kebab-name>.md` — relevant prior-session lessons.
- Context7: `<library-id>` (queried YYYY-MM-DD for <topic>).
