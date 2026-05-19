## ADR-0019: Spec-Driven Templates and `/new-spec` `/new-plan` Skills (Wave B)

- **Status:** Accepted
- **Date:** 2026-05-19
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0018 (Wave A — in-loop hooks), ADR-0012 (DX tooling boundary)

## Context

Slice 2 produced two artifacts that, in hindsight, set the bar for how this project does spec-driven work:

- `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` (479 lines, 17 H2 sections) — context, locked decisions in a Q-table, a numbered 14-step golden path as acceptance, an architecture section deep enough to design controllers from, an explicit non-goals list, a libraries table with Context7 IDs, a risks/mitigations table, an accessibility floor, a test strategy, and verification gates that map to `M2-SLICE-CHECKLIST.md`.
- `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md` (6,127 lines, 42 atomic tasks across 6 phases) — every task has a "Files" header, numbered Steps with bash blocks, explicit TDD pattern where logic warrants it, a self-review section that maps spec sections to tasks, and an execution hand-off offering subagent-driven or inline modes.

The first slice that needs a fresh spec/plan (slice 3, VRP real) is two slices away. By then this session's authors will be gone and the operating discipline that produced these artifacts will live only in the artifacts themselves. If the next session starts by opening an empty file and improvising, the form regresses. If it starts by copying a previous spec and pruning, the form drifts (irrelevant slice-2 sections get carried forward; slice-3-specific concerns get force-fit). Both are real risks the M2-SLICE-CHECKLIST already documents as "skipping the ritual is not an option."

The Tech Lead's Club spec-driven framing (Specify → Design → Tasks → Execute) is a useful structural reference, but the slice-2 artifacts went further: they were authored in a single pass with brainstorming, and the structure that emerged is project-specific (mentions ADR-0013 mirror contract, M2-SLICE-CHECKLIST gates, prototype 1:1 obligation, cost ceiling). Importing a generic TLC template would lose that calibration. The right move is to extract the templates from the artifacts that already work here.

A second gap surfaced during the audit: there is no entry point. A future agent reading `AGENTS.md` learns that `docs/superpowers/specs/` and `plans/` exist but not how to start a new one. The slash commands the project already has (`/commit`, `/session-end`, `/new-flutter-feature`) demonstrate the pattern: one slash command per recurring ritual, with the procedure in `SKILL.md` and the human-or-agent flow explicit.

This ADR settles both gaps in one move so they ship together with shared rationale.

## Options Considered

### Option A — Do nothing; rely on copying the slice-2 artifacts

- Pros: Zero new files. The slice-2 spec/plan are good enough to imitate.
- Cons: Imitation drifts. The first agent under deadline pressure will skip the brainstorming step that produced the locked-decisions table, will keep the slice-2 verification gates that don't apply to slice 3, and will miss the self-review pass that catches contradictions before implementation starts. The artifacts become more wrong with each copy. No entry point means the AGENTS.md ritual ("read this, then this, then act") has nothing to point to when scope is "start a new slice."

### Option B — Import the TLC spec-driven template verbatim

- Pros: External template gets external review and updates.
- Cons: The generic TLC template knows nothing about this project's ADR-0013 mirror contract, the prototype 1:1 rule, the M2-SLICE-CHECKLIST §Verification gates, or the cost ceiling. Bolting them on as post-processing erases the structural value of having a template. The slice-2 spec was richer than TLC's because it integrated those rules into the structure; a generic template would force every author to re-integrate manually.

### Option C — Extract templates from slice 2; add `/new-spec` and `/new-plan` skills (this ADR)

Two new template files under `docs/superpowers/`:

- `specs/0000-template.md` — captures the 17-section structure that worked: Context, Decisions Locked, Goals (acceptance), Non-Goals, Architecture, Data Flow, Sub-slice Plan (optional for non-slice features), Libraries (with Context7 IDs), ADRs Filed, Risks and Mitigations, Accessibility, Test Strategy, Verification Gates, References.
- `plans/0000-template.md` — captures the 42-task pattern: Goal, Architecture, Tech Stack, Spec back-reference, Branch, Plan Execution Rules (1–8), File Structure Created/Modified, Phase headers, Task template with Files header + numbered Steps + explicit TDD pattern + Commit block, Self-Review checklist, Execution Hand-off offering subagent-driven vs inline.

Two new local skills:

- `/new-spec <slug>` — copies the spec template, fills the date/branch/spec-path header, runs the `superpowers:brainstorming` skill first (per the CLAUDE.md pre-flight ritual) before any spec content lands, and stops after the brainstorm captures decisions — the human reviews before spec body authoring begins.
- `/new-plan <spec-slug>` — reads the corresponding spec from `docs/superpowers/specs/<slug>.md`, copies the plan template, fills the back-reference, and prompts the author to invoke `superpowers:writing-plans` for the actual task decomposition.

Both skills are `disable-model-invocation: true` (human-triggered via `/`-command, never auto-fired) and have `allowed-tools:` allowlists scoped to the file operations they need.

- Pros: Templates are project-specific by construction (extracted from this project's best artifacts). The entry-point gap closes — `AGENTS.md` and `M2-SLICE-CHECKLIST.md` can now name `/new-spec` and `/new-plan` as the canonical starts. Skills enforce the brainstorming-first discipline that produced slice 2's Q1/Q2/Q3 locked decisions. The templates are versioned (file with frontmatter); evolution is explicit (`docs(decisions): amend adr-0019 — add §X to spec template`).
- Cons: Two more files in `docs/superpowers/` to keep current. Skills add procedural ceremony to a step the slice 2 author did fluidly without one; for solo-dev moments this can feel heavy. Mitigated by `disable-model-invocation: true` — the human chooses when to invoke; nothing auto-fires.

### Option D — Templates only, no skills

- Pros: Half the files; templates alone capture the structure.
- Cons: An entry point is what closes the discipline gap. A template no one invokes is a template no one knows exists. The slash commands are 80 lines each — they don't justify deferring them to a Wave C that may never come.

## Decision

Adopt **Option C** — extract templates from the slice-2 artifacts; add `/new-spec` and `/new-plan` skills.

Concrete deliverables:

| Artifact | Path | Source of structure |
|---|---|---|
| Spec template | `docs/superpowers/specs/0000-template.md` | Distilled from slice-2 spec — preserves the 17-section structure, including the M2-SLICE-CHECKLIST verification-gate cross-reference and the ADR-0013 mirror-contract reminder under Architecture. |
| Plan template | `docs/superpowers/plans/0000-template.md` | Distilled from slice-2 plan — preserves the Phase / Task / Step hierarchy, the TDD pattern, the Self-Review checklist, and the Execution Hand-off offering. |
| `/new-spec` skill | `.claude/skills/new-spec/SKILL.md` | Frontmatter `disable-model-invocation: true`, `allowed-tools` allowlist for `cp`, `ls`, `date`, `git rev-parse`. Workflow: validate slug → copy template → fill header → instruct human to invoke `superpowers:brainstorming` before authoring spec body. |
| `/new-plan` skill | `.claude/skills/new-plan/SKILL.md` | Same frontmatter pattern. Workflow: validate that `docs/superpowers/specs/<slug>.md` exists → copy plan template → fill back-reference + branch + spec path → instruct human to invoke `superpowers:writing-plans` for task decomposition. |

The templates are **opinionated**, not generic. They embed project rules where slice-2 embedded them:

- The spec template's Verification Gates section quotes `M2-SLICE-CHECKLIST.md §Verification` by reference.
- The plan template's "Plan execution rules" preserves all 8 numbered rules from slice 2 verbatim (one logical commit, TDD where useful, no `--no-verify`, Riverpod codegen, hot reload over restart, surgical edits, ADR-0013, push per sub-slice).
- The plan template's Task pattern includes the "Files" header + Steps with bash blocks + HEREDOC commit messages — the form the slice-2 plan executed against without friction.

Skills are **non-intrusive** beyond invocation: they create files and print next-step instructions; they do not author spec/plan content. The author (human or agent) brings the content via brainstorming and writing-plans.

`CLAUDE.md` gains a "Spec-Driven Workflow" subsection under "Project-Specific Critical Rules" listing the two skills as the canonical entry points; nothing else moves.

## Consequences

- **Positive:** The next slice's spec/plan starts from a structure proven against slice 2 instead of from a blank file or a copy. The brainstorming-first discipline is mechanized — `/new-spec` blocks before the body until the human runs `superpowers:brainstorming`, replicating how Q1/Q2/Q3 got locked in slice 2 before any architecture was committed. `AGENTS.md` and `M2-SLICE-CHECKLIST.md` now have concrete entry-point names to call out. ADR-0018's hooks and ADR-0019's templates compose: the hooks catch drift on each turn; the templates prevent drift in the artifact that orchestrates the slice.
- **Negative:** Two more files to maintain. If the slice-3 spec discovers the template needs amendment, that amendment travels in a new ADR (`docs(decisions): amend adr-0019 — …`). This is by design: the template is a contract, not a draft.
- **Neutral:** The slice-2 spec/plan stay as-is. They are not retrofitted to match the template — they ARE the template's reference implementation. If a future audit shows divergence between template and slice-2 source, the divergence is intentional unless the ADR amendment says otherwise.

## Implementation Notes

- The two skills use the same `next-session-id`-style helper pattern as `/session-end`: a small shell helper that resolves date + slug → final filename, so the skill itself stays declarative.
- The spec template includes commented placeholder text (HTML comments `<!-- ... -->`) explaining each section's purpose in 1–2 lines, so an author opening the file knows what to write. The comments are NOT instructions to the agent — they are author-facing reminders the agent erases as it fills the section. (Per CLAUDE.md "no comments in production code"; templates are documentation, not production code — the same rule does not apply.)
- The plan template includes the "Plan execution rules" verbatim from slice 2. When slice 3 or later evolves a rule (e.g. adding rule 9 for a new sub-slice push cadence), the template is amended via this ADR.
- Both skills validate inputs before doing anything destructive: `/new-spec my-feature` errors if `docs/superpowers/specs/<date>-my-feature-design.md` already exists; `/new-plan my-feature` errors if `<date>-my-feature-design.md` does NOT exist. No silent overwrite.
- The brainstorming gate is enforced by **instruction**, not by hook. The `/new-spec` skill prints "STOP. Before authoring §Context, run `superpowers:brainstorming` with Eduardo. Return only after Q1/Q2/Q3-style decisions are locked." The agent that ignores this is the same agent that ignores AGENTS.md — not a problem this layer can solve.

## Boundary: templates vs `M2-SLICE-CHECKLIST.md` vs ADRs (extends ADR-0012, ADR-0018)

| Document | Owns |
|---|---|
| `M2-SLICE-CHECKLIST.md` | The verification gates every slice must satisfy. Universal across slices. |
| `docs/superpowers/specs/<slug>.md` | The decisions a specific slice makes and why. One per slice. References the checklist; does not duplicate it. |
| `docs/superpowers/plans/<slug>.md` | The atomic tasks a specific slice executes to satisfy its spec. One per slice. References the spec; does not duplicate it. |
| `docs/decisions/NNNN-*.md` | Architecture decisions that outlive any single slice. Filed *during* a slice when the slice's choices touch the stack. |
| `docs/superpowers/specs/0000-template.md` (new) | The shape every future spec follows. Authoritative for structure; mute about content. |
| `docs/superpowers/plans/0000-template.md` (new) | The shape every future plan follows. Authoritative for structure; mute about content. |

No layer duplicates another. The checklist says what gates apply; the spec says how this slice meets them; the plan says which task lands each gate; the templates ensure spec and plan can be read in the same order across slices.

## References

- `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` — the source from which the spec template is distilled.
- `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md` — the source from which the plan template is distilled.
- ADR-0018 — Wave A in-loop validation hooks. This ADR is Wave B of the same harness modernization arc.
- ADR-0012 — Tooling boundary (Lefthook + Commitlint + Claude hooks). This ADR adds a third layer: spec/plan templates as authored-artifact contracts.
- `M2-SLICE-CHECKLIST.md` §Verification — the gates the spec template's "Verification Gates" section cross-references.
- `superpowers:brainstorming` (plugin skill) — the discipline `/new-spec` enforces before body authoring.
- `superpowers:writing-plans` (plugin skill) — the discipline `/new-plan` enforces during task decomposition.
- Tech Lead's Club "spec-driven 4 phases" framing — informed the boundary thinking but not the template content (which is project-extracted, per the Decision section's rationale).
