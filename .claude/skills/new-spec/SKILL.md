---
name: new-spec
description: Start a new spec under docs/superpowers/specs/ from the canonical template (docs/superpowers/specs/0000-template.md). Enforces the brainstorming-first discipline — stops the agent after creating the file header so the human invokes superpowers:brainstorming to lock decisions before authoring §Context onward. Argument is the kebab-case slug for the slice/feature (e.g. "slice-4-stripe-pix-paywall"). Use when starting a new slice or feature that warrants a formal spec (post-reset 2026-05-26: specs são opcionais; use só pra trabalho onde Spoke não decide a arquitetura — slice 4 Stripe paywall, slice 7 admin panel). Pre-requisite: the slice/feature is named in `docs/08-ROADMAP-v2.md` and the user has approved working on it.
disable-model-invocation: true
allowed-tools: Bash(cp:*), Bash(ls:*), Bash(date:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git log:*), Bash(test:*)
---

# /new-spec — start a new spec from the canonical template

Creates `docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md` from the canonical template at `docs/superpowers/specs/0000-template.md`. The skill is **deliberately incomplete**: it scaffolds the header and stops, blocking spec body authoring until the human runs `superpowers:brainstorming`. This mechanizes the brainstorming-first discipline.

## Inputs

- `$ARGUMENTS` — kebab-case slug for the slice or feature. Examples: `m2-slice-3-vrp-real`, `m2-slice-4-pix-paywall`, `notifications-foundation`.

If `$ARGUMENTS` is missing, **stop and ask** the human for the slug. Don't infer from conversation — slugs are load-bearing identifiers that match plan filenames, branch names, and session log entries.

## Workflow

### 1. Validate inputs and environment

```bash
test -f "$CLAUDE_PROJECT_DIR/docs/superpowers/specs/0000-template.md" || {
  echo "FATAL: spec template missing at docs/superpowers/specs/0000-template.md"; exit 1;
}
```

Then resolve the date and check the target does not already exist:

```bash
today="$(TZ=America/Sao_Paulo date +%Y-%m-%d)"
slug="<from $ARGUMENTS>"
target="$CLAUDE_PROJECT_DIR/docs/superpowers/specs/${today}-${slug}-design.md"

test -e "$target" && {
  echo "FATAL: $target already exists — pick a different slug or amend the existing spec";
  exit 1;
}
```

If the slug looks suspect (contains spaces, uppercase, periods, or is shorter than 4 chars), **stop and confirm** with the human before continuing. Bad slugs propagate to branch names and plan filenames.

### 2. Check branch state

```bash
git rev-parse --abbrev-ref HEAD
git status --short
git log --oneline -3
```

The expectation per `M2-SLICE-CHECKLIST.md` Pre-flight: a clean working tree on `develop` (or the appropriate base branch), aligned with origin. If the tree is dirty or the branch is wrong, **stop and surface the discrepancy** — don't auto-clean.

### 3. Copy the template

```bash
cp "$CLAUDE_PROJECT_DIR/docs/superpowers/specs/0000-template.md" "$target"
ls -la "$target"
```

### 4. Fill the header (and ONLY the header)

Open `$target` and replace the four header lines:

- `Spec — <slice or feature name>` → `Spec — <human-readable name from slug>`
- `> **Date:** YYYY-MM-DD` → `> **Date:** <resolved $today>`
- `> **Status:** Awaiting user review …` (leave as-is; the human flips it after brainstorming + body)
- `> **Branch:** \`feat/<slug>\` (off \`develop\` at \`<base-sha>\`)` → fill the slug AND run `git rev-parse origin/develop` to capture the base sha
- `> **Source of truth:** docs/08-ROADMAP-v2.md "<roadmap section>"` → name the actual section heading from `docs/08-ROADMAP-v2.md` (the human confirms which one)

**Do NOT fill any other section.** The body is brainstorming output; this skill is a scaffold.

### 5. Print the brainstorming gate (the load-bearing step)

Print this to the human verbatim:

```
✅ Spec scaffold created: docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md

STOP. Do NOT author §Context onward yet — invoke `superpowers:brainstorming` first to lock decisions.

Next step (human-driven):
  Invoke `superpowers:brainstorming` with Eduardo to lock the Q1/Q2/Q3-style
  decisions that go in §Decisions Locked. Slice 2's three locked questions
  (persistence model, default external nav provider, pricing) are the model.

After the brainstorm, the human OR a fresh agent fills the body:
  §Context, §Decisions Locked, §Goals, §Non-goals, §Architecture, §Data flow,
  §Sub-slice plan, §Libraries (with Context7 IDs), §ADRs filed, §Risks,
  §Accessibility, §Test strategy, §Verification gates, §References.

When the spec is complete and approved, run `/new-plan <slug>` to scaffold
the implementation plan.
```

Then **exit**. Do not offer to fill the brainstorm output. Do not draft §Context. The human runs the brainstorming skill in a separate, deliberate step.

## Constraints

- **Never auto-fill body sections.** The template's HTML comments (`<!-- … -->`) explain each section to the human author; they are NOT prompts for the agent to satisfy.
- **Never invoke `superpowers:brainstorming` from inside this skill.** The brainstorm is a deliberate user-driven step in its own context window — wrapping it inside `/new-spec` collapses two distinct decisions into one.
- **Never `git add` or commit the new spec file.** The spec is committed when complete (header + full body + brainstorm-locked decisions). A spec commit with only a header is noise.
- **Never overwrite an existing spec.** If `$target` exists, refuse and ask the human to pick a different slug.

## Anti-patterns

- Inferring the slug from conversation context. Slugs are explicit; ask.
- Skipping the branch check ("we'll fix it later"). A spec authored on the wrong base diverges the plan from the branch.
- Filling `§Context` because "we already discussed it in this session." Conversation is not brainstorming — `superpowers:brainstorming` has structure this skill respects by NOT replacing it.
- Adding scope-enum entries to `commitlint.config.cjs` "while I'm here." If the slice introduces a new scope, that's a separate commit before the slice's first feature commit lands.

## What this skill is NOT

- Not a brainstorming skill — that's `superpowers:brainstorming`, in a separate, deliberate invocation.
- Not a planner — that's `/new-plan`, after the spec is approved.
- Not a branch creator. Branches are created when implementation starts, not when the spec is being authored.
- Not an ADR scaffold. ADRs file from `docs/decisions/0000-template.md` via the slice that needs them.

## References

- `docs/superpowers/specs/0000-template.md` — the canonical template this skill copies from.
- `docs/superpowers/specs/0000-template.md` — the template this skill copies.
- `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` — the reference implementation the template distills.
- `superpowers:brainstorming` (plugin skill) — the discipline this skill enforces before body authoring.
- `M2-SLICE-CHECKLIST.md` Pre-flight section — the universal checklist `/new-spec` operates under.
