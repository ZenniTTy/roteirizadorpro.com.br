---
name: brainstorm-slice
description: Use when entering brainstorming for a new M2 slice or microsprint — BEFORE writing the spec, plan, or any code. Anchors brainstorm in Spoke (for slice-2 / slice-3) or in the original RotPro spec (for slices 4, 5, 7). Asks only the questions Spoke / the inventory do not already answer. Produces a brainstorm summary that hands off cleanly to spec writing (when a spec is warranted).
---

# brainstorm-slice

Anchor an M2 slice brainstorm in canonical sources before reaching for fresh UX questions. Mirrors the discipline of the Claude Code `superpowers:brainstorming` skill, scoped to Roteirizador Pro's source-of-truth hierarchy.

## When to use this skill

- Entering brainstorming for a new microsprint within M2 slice 2 (Telas Core), slice 3 (Real backend), slice 4 (Stripe paywall), slice 5 (sentido casa), or slice 7 (admin panel).
- The user says "let's brainstorm <flow>" / "como devo abordar <feature>" / "começar a slice X".
- BEFORE writing any spec, plan, or production code.

**Do NOT use this skill** for:
- Trivial single-file edits.
- Bug fixes (use `superpowers:debugging` in Claude, or just `/commit` if you've already located the cause).
- Refactors (no new behavior, no need to brainstorm).

## Process

### Step 1 — Classify the slice

Determine which canonical source governs:

| Slice | Behavior canonical | Visual canonical |
|---|---|---|
| 2 (Telas Core) | **Spoke** | `prototipo/` |
| 3 (Real backend) | **Spoke** (for API shapes RotPro must support) + RotPro original (for backend internals) | n/a |
| 4 (Stripe Pix paywall) | RotPro original (ADR-0030) | `prototipo/` |
| 5 (sentido casa) | RotPro original | `prototipo/` |
| 6 (LGPD) | RotPro original (legal) | n/a |
| 7 (admin panel) | RotPro original | n/a |

### Step 2 — Inspect the canonical source

**If Spoke is canonical for this slice** (i.e., slice 2 or the Spoke-facing parts of slice 3):
- Recommend running the `spoke-inspect` skill FIRST. Pass the equivalent Spoke flow.
- Read the matching section of `docs/inventory/2026-05-26-spoke-vs-rotpro.md`.
- Only after Spoke is inspected, ask the user the questions Spoke does NOT answer (per the three buckets in CLAUDE.md §"Spoke deep-dive default behavior"):
  - (a) Decisions Spoke doesn't cover (data migration paths, original RotPro features, scope cuts per inventory §7).
  - (b) Directives that override Spoke (cliente preference per inventory §7.1).
  - (c) A one-line confirmation that the device is connected and Spoke is logged-in (only if you're about to dispatch `spoke-inspect`).

**If RotPro original is canonical** (slices 4, 5, 6, 7):
- Read the corresponding ADRs (`docs/decisions/`) and business rules (`docs/BUSINESS-RULES.md`).
- Read any existing spec under `docs/superpowers/specs/` for this slice.
- Then ask UX/architecture questions normally — Spoke does not constrain these.

### Step 3 — Identify open questions

After consulting canonical sources, list the open questions explicitly. Each one falls into one of:

- **Stack-affecting** (new lib, version bump, schema change) → requires an ADR before brainstorm closes.
- **Business-rule-affecting** (pricing, paywall logic, user-facing constraints) → requires `docs/BUSINESS-RULES.md` update.
- **UX gap** (Spoke + inventory don't answer) → ask the user.
- **Visual identity gap** (`prototipo/` doesn't cover) → ask the user OR defer to slice polish phase.

### Step 4 — Ask one question at a time

Per the Karpathy principle (CLAUDE.md §"Think Before Coding"): one question per message, multiple-choice when possible. Do not batch.

### Step 5 — Hand off

Produce a brainstorm summary:

```markdown
# Brainstorm: <slice / microsprint name>

**Canonical sources consulted:**
- <Spoke inspection report path, if applicable>
- <Inventory section consulted>
- <ADRs / business rules consulted>

**Resolved questions:**
- <question> → <answer> (source: <Spoke | user | inventory | ADR-XXXX>)

**Open questions surfaced but not yet resolved:**
- <question> (waiting on: <user | ADR draft | inventory update>)

**Spec recommendation:**
- Post-reset, specs are optional (per CLAUDE.md). Recommendation:
  - [ ] **Spec warranted** — non-obvious architecture; write `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
  - [ ] **No spec** — Spoke + inventory are the spec; proceed to scaffolding via `/new-screen`.

**Next step:**
- <`/new-screen <name>` | "draft spec" | "draft ADR-XXXX first" | "wait for user decision on Q3">
```

## Strict boundaries

- **Do not write code.** This skill is brainstorm-only. The terminal step is the brainstorm summary or a hand-off to `/new-screen` / a spec draft.
- **Do not invent Spoke facts.** If Spoke isn't inspected, say so — don't paraphrase what you "remember" Spoke does. Run `spoke-inspect` or refuse to proceed.
- **Do not skip the three-bucket discipline** for slice 2 / slice 3. Asking the user UX questions Spoke already answers is the failure mode this skill exists to prevent.

## ADR references

- ADR-0035 (Spoke = behavior canonical)
- ADR-0036 (parity gate: upfront + D4)
- ADR-0030 (Stripe Pix paywall — for slice 4 only)
