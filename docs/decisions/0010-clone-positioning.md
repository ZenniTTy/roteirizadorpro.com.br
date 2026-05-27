# ADR-0010: Functional Fork Positioning (Original Visual Identity in Shipped Product)

- **Status:** Accepted (Amendment 1 applied 2026-05-27; Amendment 2 applied 2026-05-27)
- **Date:** 2026-05-05
- **Deciders:** Eduardo, client

## Context

The accepted Workana proposal asks for an app that "clones the fluidity and UX of Circuit Route Planner." The client said he wants the app to be "practically 100% identical, with different visual identity, copying 100% of the front."

The product strategy is a **white-label of Spoke** (ex-Circuit Route Planner): replicate 100% of the functionality and screen structure using our stack (Flutter + Riverpod + GoRouter + SharedPrefsAsync on mobile; Fastify + TypeBox + Prisma 7 + PostgreSQL + GraphHopper on backend), then Eduardo applies the original visual identity (palette, typography, icon set, microcopy) at the end so the **shipped product** is clearly Roteirizador Pro, not Spoke.

What matters legally is what the **end user sees in the distributed APK**, not how Eduardo (or contracted agents) study Spoke internally to plan the implementation. The combined-look-and-feel protection (US trade dress + BR Lei 9.279/96) applies to the *shipped product* that creates consumer confusion — not to engineering documentation, inspection artifacts, or planning notes used internally.

## Options Considered

### Option A — Ship a literal copy of Spoke (icons, colors, microcopy verbatim)

- Pros: Maximum perceived similarity.
- Cons: Direct copyright + trade dress claim risk if Spoke notices the shipped product. Workana ToS exposure. Client's marketing (Facebook Ads) makes the clone discoverable.

### Option B — Ship a functional white-label with original visual identity

- Pros: Replicates flows, screens, behaviors — the things that make Spoke useful. Original visual identity in the shipped product (palette, typography, icons, microcopy) eliminates trade-dress claim risk because there's no consumer confusion. Industry-standard approach.
- Cons: Eduardo (or designer) must produce the original visual identity at the end of M2. Adds polish work.

### Option C — White-label off-the-shelf route planner

- Pros: Lowest effort.
- Cons: Defeats the purpose of the contract; no differentiation.

### Option D — Purchase license / partner with Circuit

- Pros: Fully legal regardless of approach.
- Cons: Not realistic at our budget.

## Decision

**Option B — functional white-label of Spoke with original visual identity in the shipped product.**

### What we replicate from Spoke (functional parity)

Replicate 100% of:
- Screen structure (route list, optimize, navigate, settings, etc.)
- Navigation hierarchy and flow
- Interaction patterns (drag-to-reorder, swipe, bottom sheets, FAB)
- UX patterns (route timeline, inline ETAs, status workflows)
- Behaviors (auto-save, undo, animation timing, optimistic UI)

### What the shipped APK does NOT contain from Spoke

The **distributed APK** is shipped with original visual identity. The shipped APK does NOT contain:
- Spoke's icons, logos, mascots, illustrations (we use Lucide icon set per ADR-0035 + commissioned originals)
- Spoke's color palette (we use prototype palette per ADR-0035)
- Spoke's typography choices (we use prototype typography pair per ADR-0035)
- Spoke's microcopy verbatim (all microcopy written in original PT-BR for Roteirizador Pro)
- Spoke's marketing imagery, Lottie animations, vector art

This applies to **what the end user installs**, not to engineering artifacts in the repo (see Amendment 1 below).

## Consequences

- Positive: Legally defensible — what users install is clearly Roteirizador Pro, not Spoke. Client's marketing scales without IP exposure on the shipped product. Product is genuinely the client's own to commercialize.
- Positive: Operationally simple — internal engineering work (inspection, audit, planning notes) is not constrained by shipped-product rules.
- Negative: Eduardo (or a designer) must produce the original visual identity at end of M2 polish phase. Adds work that happens after slice 2-7 functional implementation is done.
- Neutral: Quality of UX clone is unaffected — the things users care about are functional.

## Implementation Notes

- All microcopy in the **shipped APK** will be written from scratch in Brazilian Portuguese.
- Visual identity tokens (colors, spacing, radii, shadows, typography, icons Lucide) come from `prototipo/tokens.js` per ADR-0035 and are applied from commit 1 of each screen.
- App icon will be a fresh design.
- App name is already different ("Roteirizador Pro").
- Engineering artifacts in the repo (inspection dumps, screenshots, audit notes) are governed by Amendment 1 — see below.
- Internal inspection methodology is operator's choice — see Amendment 2 below.

## References

- LGPD positioning (`docs/05-LGPD.md` — separate concern).
- Workana ToS: https://www.workana.com/legal/terms-of-service.
- Trade dress (US): Two Pesos, Inc. v. Taco Cabana, Inc., 505 U.S. 763 (1992) — applies to shipped product, not engineering process.
- BR: Lei 9.279/96 (Industrial Property Law) — same scope as US trade dress.
- ADR-0035 — Spoke functional clone + prototype creative reference (defines what tokens come from where).
- ADR-0036 — `spoke-parity-checker` subagent (inspection workflow).
- ADR-0037 — Maestro MCP for Spoke inspection (preferred inspection layer).

---

## Amendments

### Amendment 1 (2026-05-27) — Engineering artifacts may enter the repo freely

**Original ADR had:** "No Circuit screenshots, PSDs, SVGs, or design files may enter the repository at any time."

**Why amended:** the original rule was scoped too broadly — it conflated **engineering artifacts** (used internally to plan implementation: hierarchy dumps from `inspect_screen`, screenshots from `take_screenshot`, audit notes) with **shipped-product assets** (what users install). Trade dress protection applies to the latter, not the former. The original rule forced operational friction (cleanup loops, separate `/tmp/` workflows, blocked PRs) without proportional legal benefit because the shipped APK is what determines IP exposure.

**Revised rule:**

Engineering artifacts from Spoke inspection — hierarchy dumps (JSON/XML), screenshots, audit notes, inventory entries quoting structural details — **MAY enter the repository freely**. These artifacts support implementation planning and never reach the end user.

**Practical guidance (not enforced):**

- **Hierarchy dumps:** commit when canonical evidence for a documented decision (e.g., before/after taps proving a hypothesis). Open-ended exploration dumps can stay in `/tmp/` if you want, but committing them is also fine.
- **Screenshots:** prefer textual description when sufficient. Commit screenshots when text alone is insufficient (visual layout that defies description, or resolving an ambiguity).
- **Location convention:** `docs/inventory/dumps/` for structured assets. Reference inline from inventory entries with relative links.
- **Filename convention:** `<area>_<state>.{json,png}` (e.g., `hierarchy_after_coleta.json`, `screencap_instrucoes.png`).
- **`.gitignore`:** `docs/inventory/dumps/` is gitignored intentionally — forces `git add -f` for conscious commit decisions, not as a hard block.

**What this Amendment does NOT change:**

The **shipped APK** still must not contain Spoke's icons, logos, palette, typography, microcopy verbatim, marketing imagery, or vector art. That's the Decision section above — visual identity tokens come from `prototipo/tokens.js` per ADR-0035, not from Spoke. The Amendment only liberates the engineering repo, not the shipped product.

### Amendment 2 (2026-05-27) — Inspection methodology is operator's choice

**Original ADR had:** by precedent established in ADR-0036 + ADR-0037, only "runtime UI observation via accessibility framework" (Maestro MCP + `adb shell uiautomator dump`) was considered an acceptable inspection method. Decompilation, resource extraction, and source-code reverse-engineering were treated as forbidden.

**Why amended:** the operational restriction was conflated with legal restriction. The legal concern (trade dress in shipped product) doesn't depend on how Eduardo inspects Spoke internally. Operator may use whatever inspection method is most efficient — runtime inspection is the default because it's fast and well-tooled, but is not the only allowed method.

**Revised rule:**

Inspection methodology for Spoke parity work is the **operator's choice**. Default and recommended: Maestro MCP per ADR-0037 (fast, structured, already wired into the harness). Alternative methods (APK inspection, decompilation, resource extraction) are allowed when they serve to clarify ambiguity faster than runtime inspection.

**What still matters legally:**

What ends up in the **shipped APK**. Inspection methodology is engineering process, not product output. As long as the shipped product has original visual identity per the Decision section, the legal posture is unchanged regardless of how the engineering team studied Spoke.

**Practical guidance (not enforced):**

- Runtime inspection (Maestro MCP) remains the default because it's the fastest workflow and produces structured output the agent can paste verbatim into the inventory.
- When runtime inspection is insufficient (e.g., a flow gated by paywall, a state that's hard to trigger), other methods are fair game.
- Whatever method is used, the structural finding goes into `docs/inventory/` paraphrased — extraction methodology is just how you got there.

**What this Amendment does NOT change:**

- The **shipped APK** still must not contain Spoke's icons, logos, palette, typography, microcopy verbatim, marketing imagery, or vector art (per Decision section).
- Distribution channels (Workana ToS, Play Store policies) still apply to what we ship, not to internal process.
