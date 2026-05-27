# ADR-0010: Functional Fork Positioning (No Visual Asset Copy of Circuit)

- **Status:** Accepted (Amendment 1 applied 2026-05-27 — see §Amendments)
- **Date:** 2026-05-05
- **Deciders:** Eduardo, client

## Context

The accepted Workana proposal asks for an app that "clones the fluidity and UX of Circuit Route Planner." During scoping, the client said he wants the app to be "practically 100% identical, with different visual identity, copying 100% of the front." This phrasing has two valid interpretations — a functional one that is legally fine, and a literal one that would expose both Eduardo and the client to copyright and trade dress claims.

Circuit (https://getcircuit.com) is a UK/US company actively maintaining and marketing its product. Its visual assets, microcopy, illustrations, and marketing materials are protected by copyright. Trade dress doctrine (US) and combined visual identity (BR Lei 9.279/96) protect the *combined look-and-feel* of a product when it serves as a brand identifier.

Workana's terms of service prohibit deliverables that infringe third-party IP. A complaint could result in account termination for both contractor and client.

## Options Considered

### Option A — Visual identity copy ("100% identical")

- Pros: Maximum perceived similarity; minimum design work.
- Cons: Direct copyright violation of icons, illustrations, microcopy. Trade dress claim risk. Workana ToS violation. Client's marketing investment exposes them more (Facebook Ads make the clone discoverable to Circuit). High legal risk.

### Option B — Functional fork with original visual identity

- Pros: Replicates flows, behaviors, screen structure, interaction patterns — the things that make Circuit useful. Original colors, typography, icons, illustrations, microcopy. Legally defensible (functionality is not protected by copyright; trade dress requires distinctiveness AND consumer confusion, both of which are mitigated by clearly distinct visual identity). Industry-standard approach (Instagram→Snapchat, etc.). No Workana ToS issue.
- Cons: Requires actual design work (palette, typography, icon set) — not zero effort.

### Option C — White-label off-the-shelf route planner

- Pros: Lowest effort.
- Cons: Defeats the purpose of the contract; no differentiation.

### Option D — Purchase license / partner with Circuit

- Pros: Fully legal.
- Cons: Not realistic at our budget.

## Decision

**Functional fork with original visual identity.**

Replicate from Circuit:
- Screen structure (route list, optimize, navigate, settings).
- Navigation hierarchy.
- Interaction flows (drag-to-reorder, swipe-to-complete, bottom sheets, FAB).
- UX patterns (route timeline at top, inline ETAs).
- Behaviors (auto-save, undo, animation timing feel).

Do **not** replicate from Circuit:
- Icons, logos, mascots, illustrations.
- Color palette (neither exact nor near-exact combinations).
- Typography (font family choices).
- Microcopy (button labels, error messages, onboarding text).
- Marketing imagery (screenshots, photographs).
- Lottie animations or any vector art.
- App name (✅ already different — "Roteirizador Pro").

## Consequences

- Positive: Legally defensible; client's marketing can scale without IP risk; product is genuinely the client's own to commercialize, sell, or pitch to investors.
- Negative: Eduardo (or a designer) must produce an original visual identity — palette, typography, icon set, microcopy. Adds work.
- Neutral: Quality of UX clone is unaffected — the things users care about are functional.

## Implementation Notes

- Eduardo will produce wireframes from Circuit usage (low fidelity, structure only — no Circuit assets in the wireframes).
- A new visual identity will be defined: 2-3 palette directions, typography pair, icon set sourced from a permissive library (e.g., Lucide, Phosphor) or commissioned originals.
- All microcopy will be written from scratch in Brazilian Portuguese (final shipped product).
- ~~No Circuit screenshots, PSDs, SVGs, or design files may enter the repository at any time.~~ **Superseded by Amendment 1 (2026-05-27).** See §Amendments for revised rule on empirical evidence (hierarchy dumps, screenshots) commitable to repo for inventory/audit work.
- App icon will be a fresh design (logo work pending).

## References

- LGPD positioning (`docs/05-LGPD.md` — separate concern).
- Workana ToS: https://www.workana.com/legal/terms-of-service (clause prohibiting IP infringement).
- Trade dress (US): Two Pesos, Inc. v. Taco Cabana, Inc., 505 U.S. 763 (1992).
- BR: Lei 9.279/96 (Industrial Property Law).

## Amendments

### Amendment 1 (2026-05-27) — Empirical evidence (hierarchy dumps, screenshots) may enter the repo

The original Implementation Notes rule "No Circuit screenshots, PSDs, SVGs, or design files may enter the repository at any time" was too broad — it conflated **runtime inspection artifacts** (used internally to plan implementation) with **design source files** (Circuit's actual PSDs/SVGs that they ship). Inventory work via `spoke-parity-checker` produces hierarchy dumps and occasionally screenshots, and the original rule forced operational friction (cleanup loops, separate /tmp/ workflows, blocked PRs) without proportional legal benefit since the final shipped product still has original visual identity.

**Revised rule (replaces the stricken bullet in Implementation Notes):**

Hierarchy dumps (JSON/XML from `mcp__maestro__inspect_screen` / `adb shell uiautomator dump`) and screenshots from runtime inspection **MAY** enter the repository when they serve as **evidence supporting a structural decision** documented in `docs/inventory/` or `docs/decisions/`. Practical guidance:

- **Hierarchy dumps:** prefer commit when the dump is canonical evidence for a documented decision (e.g., `before/after` taps proving a hypothesis). Avoid commit of dumps from open-ended exploration — those still go to `/tmp/spoke-inspection/`.
- **Screenshots:** prefer textual description in the inventory whenever sufficient. Commit a screenshot only when text alone is insufficient to convey the structural finding (e.g., visual layout that defies description, OR resolving an ambiguity where prior interpretation was wrong).
- **Location:** `docs/inventory/dumps/` for structured assets; reference inline from the inventory entry with relative link.
- **Filename convention:** `<area>_<state>.{json,png}` (e.g., `hierarchy_after_coleta.json`, `screencap_instrucoes.png`).

**Still forbidden in the repo (unchanged from original ADR):**

- **Final shipped product assets from Circuit/Spoke:** icons, logos, mascots, illustrations, Lottie animations, vector art, font files, color extraction (palette files), tipographic samples — *all the things Circuit ships in their APK as their identity*.
- **Marketing imagery:** Circuit/Spoke screenshots from their own marketing site, blog, App Store/Play Store listings, or promotional materials (different from runtime inspection screenshots; this is their *product photography*).
- **Decompilation artifacts:** APK extraction, resource extraction, source code reverse-engineering output. Inspection stays bound to ADR-0036 (`spoke-parity-checker` accessibility-only approach) + ADR-0037 (Maestro MCP).

**Why this distinction is legally defensible:**

The combined-look-and-feel protection (US trade dress + BR Lei 9.279/96) applies when the *shipped product* uses someone else's visual identity in a way that creates consumer confusion. Internal inspection artifacts used for planning **never reach the end user** — they live in the repo as engineering documentation, equivalent to a developer taking notes from observing a competitor app. What matters is what RotPro **ships** to the Play Store / APK distribution: that side remains 100% original visual identity per the unchanged Decision section above.

**Impact on existing rules:**

- ADR-0036 (`spoke-parity-checker`): `/tmp/spoke-inspection/` remains the **default** for exploration work; commit-to-repo is the **exception** when artifact is documentary evidence.
- `.gitignore` `**/spoke-inspection/`: unchanged — `/tmp/` artifacts still gitignored by default.
- `.gitignore` `docs/inventory/dumps/`: **kept as gitignored entry intentionally** (per Eduardo 2026-05-27). This forces every commit into `docs/inventory/dumps/` to use `git add -f <path>` — the friction is the feature, not a bug. It signals: "I am making a conscious decision to add this empirical artifact to the repo, not committing it accidentally."

**Retroactive cleanup of PR #19/#20:** the JSON hierarchy dumps from the agent's drill of §13.C.1/C.2/C.3 (originally cleaned up to `/tmp/` per the old rule) are restored to `docs/inventory/dumps/` in the same commit that ships this Amendment. Screenshot stays out (textual description in §13.C.3 is sufficient).
