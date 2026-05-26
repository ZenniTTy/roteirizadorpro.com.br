---
name: new-plan
description: Start a new implementation plan under docs/superpowers/plans/ from the canonical template (docs/superpowers/plans/0000-template.md) per the spec-driven workflow convention. Expects the matching spec at docs/superpowers/specs/<date>-<slug>-design.md to already exist and be approved. The skill scaffolds the header and back-reference, then stops so the human invokes superpowers:writing-plans to decompose the spec into atomic tasks. Argument is the kebab-case slug shared with the spec (e.g. "m2-slice-3-vrp-real"). Use after /new-spec finishes and the spec body is complete + approved.
disable-model-invocation: true
allowed-tools: Bash(cp:*), Bash(ls:*), Bash(date:*), Bash(git rev-parse:*), Bash(git status:*), Bash(git log:*), Bash(test:*), Bash(find:*)
---

# /new-plan — start a new implementation plan from the canonical template

Creates `docs/superpowers/plans/<YYYY-MM-DD>-<slug>.md` from the plan template authored under the spec-driven workflow convention. Like `/new-spec`, the skill is **deliberately incomplete**: it scaffolds the header + back-reference and stops, blocking task decomposition until the human runs `superpowers:writing-plans`.

## Inputs

- `$ARGUMENTS` — kebab-case slug for the slice or feature, **identical to the slug used in `/new-spec`**. Examples: `m2-slice-3-vrp-real`, `m2-slice-4-pix-paywall`.

If `$ARGUMENTS` is missing, **stop and ask**. Slugs are load-bearing.

## Workflow

### 1. Validate prerequisites

```bash
test -f "$CLAUDE_PROJECT_DIR/docs/superpowers/plans/0000-template.md" || {
  echo "FATAL: plan template missing at docs/superpowers/plans/0000-template.md"; exit 1;
}
```

### 2. Locate the matching spec

The spec filename follows `<YYYY-MM-DD>-<slug>-design.md` but the date can differ from today (the spec was authored on its own day). Find it by slug:

```bash
slug="<from $ARGUMENTS>"
matches="$(find "$CLAUDE_PROJECT_DIR/docs/superpowers/specs" -maxdepth 1 -type f -name "*-${slug}-design.md" | sort)"
```

Three possible outcomes:

- **No match:** STOP. Print: *"No spec found for slug '<slug>'. Run `/new-spec <slug>` first, complete the spec body, then re-run `/new-plan <slug>`."*
- **One match:** proceed. Capture the spec path for the plan's back-reference.
- **Multiple matches:** STOP. Print the matched paths and ask the human to disambiguate (or rename the slug). Plans must point to exactly one spec.

### 3. Check the spec is approved (best-effort)

Read the spec's header. The template has a Status line:

```
> **Status:** Awaiting user review before invoking `writing-plans` | Approved | Superseded …
```

If the Status is `Awaiting user review`, **warn the human**: *"Spec status is still 'Awaiting user review'. Authoring a plan against an unapproved spec risks rework. Continue anyway? (yes / no)"*

If the human says no, stop. Otherwise proceed but record the warning.

### 4. Check target does not exist

```bash
today="$(TZ=America/Sao_Paulo date +%Y-%m-%d)"
target="$CLAUDE_PROJECT_DIR/docs/superpowers/plans/${today}-${slug}.md"

test -e "$target" && {
  echo "FATAL: $target already exists — pick a different slug or amend the existing plan";
  exit 1;
}
```

### 5. Check branch state

```bash
git rev-parse --abbrev-ref HEAD
git status --short
```

Expected: the slice's branch already exists (`feat/<slug>`) per `M2-SLICE-CHECKLIST.md`. If on `develop` with a clean tree, that's also fine — the plan is being authored before branch creation. If the tree is dirty on a different branch, **stop and surface the discrepancy**.

### 6. Copy the template

```bash
cp "$CLAUDE_PROJECT_DIR/docs/superpowers/plans/0000-template.md" "$target"
ls -la "$target"
```

### 7. Fill the header + back-reference

Open `$target` and replace:

- `# <Slice or feature name> Implementation Plan` → `# <Human-readable name> Implementation Plan`
- `**Goal:** <one-paragraph restatement …>` → leave blank for `writing-plans` to fill
- `**Architecture:** <one-paragraph summary …>` → leave blank for `writing-plans` to fill
- `**Tech Stack:** <bulleted list …>` → leave blank for `writing-plans` to fill
- `**Spec:** docs/superpowers/specs/<YYYY-MM-DD>-<slug>-design.md` → fill with the actual spec path from step 2
- `**Branch:** feat/<slug> (off develop at <base-sha>, already created and pushed)` → fill slug + run `git rev-parse origin/develop` for the base-sha; note "already created and pushed" if applicable, else "to be created from develop"

**Do NOT fill the Phase/Task bodies.** Task decomposition is `superpowers:writing-plans`'s job.

### 8. Print the writing-plans gate

Print this to the human verbatim:

```
✅ Plan scaffold created: docs/superpowers/plans/<YYYY-MM-DD>-<slug>.md

STOP. Do NOT author Phase/Task bodies yet — invoke `superpowers:writing-plans` first.

Next step (human-driven):
  Invoke `superpowers:writing-plans` with the spec at:
    docs/superpowers/specs/<spec-filename>
  to decompose the spec into atomic tasks. Slice 2's plan (42 tasks across
  6 phases) is the depth target — each task is one logical commit, with
  numbered Steps, explicit TDD pattern where logic warrants, and a HEREDOC
  commit message block.

After the plan is complete and self-reviewed (see the §Self-review section),
proceed to execution via:
  - `superpowers:subagent-driven-development` (recommended for large plans), OR
  - `superpowers:executing-plans` (inline; higher token cost but no context handoff).

When the slice is done, `/verify-slice` gates the pre-PR run.
```

Then **exit**. Do not draft Task 0. Do not auto-invoke `writing-plans`.

## Constraints

- **Never author task bodies.** The template's HTML comments explain the task pattern; they are author-facing, not agent-facing.
- **Never invoke `superpowers:writing-plans` from inside this skill.** Writing-plans is a deliberate, separate invocation with its own context.
- **Never `git add` or commit.** The plan is committed when complete (header + full task decomposition + self-review). A partial-plan commit is noise.
- **Never overwrite an existing plan.** If `$target` exists, refuse.
- **Never proceed without a matching spec.** Authoring a plan against a non-existent or wrong spec produces wasted work; the back-reference is load-bearing.

## Anti-patterns

- "I'll just decompose Phase 1 quickly while I have the context." No — `superpowers:writing-plans` enforces the depth + self-review that produced slice 2's 6,127-line plan. Shortcutting it produces plans that look complete but fail at the Self-Review pass.
- Filling `Goal:` / `Architecture:` / `Tech Stack:` "from memory" instead of letting `writing-plans` extract them from the spec verbatim. Drift between spec and plan is the #1 failure mode of spec-driven workflows.
- Skipping the Status check on the spec. An "Awaiting user review" spec means the brainstorming-locked decisions are not yet ratified; the plan that derives from it inherits the unratified scope.

## What this skill is NOT

- Not a writer of plans. That's `superpowers:writing-plans`.
- Not a spec maker. That's `/new-spec` followed by `superpowers:brainstorming` and body authoring.
- Not a branch creator or PR opener. Both happen at deliberate, later steps.

## References

- `docs/superpowers/plans/0000-template.md` — the canonical template this skill copies from.
- `docs/superpowers/plans/0000-template.md` — the template this skill copies.
- `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md` — the reference implementation the template distills.
- `superpowers:writing-plans` (plugin skill) — the discipline this skill enforces before body authoring.
- `superpowers:subagent-driven-development` / `superpowers:executing-plans` — the two execution modes the plan's §Execution Handoff names.
- `/verify-slice` (ADR-0018) — the pre-PR gate run after plan execution completes.
