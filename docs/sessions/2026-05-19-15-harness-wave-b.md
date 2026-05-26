# Session 2026-05-19-15 — harness-wave-b

## Metadata

- **Date**: 2026-05-19 (America/Sao_Paulo)
- **Sequence**: 15
- **Agent**: Claude Code (Opus 4.7, 1M context)
- **Human**: Eduardo
- **Topic**: harness-wave-b
- **Duration**: ~1h
- **Related ADRs**: ADR-0019 (new), ADR-0018 (composes with), ADR-0012 (extends)
- **Related TODO items**: harness modernization Wave B (the second half of session 14's two-wave plan)

## Goal of the Session

Land Wave B of the harness modernization arc started in session 14: extract canonical spec and plan templates from the slice-2 artifacts, add `/new-spec` and `/new-plan` skills that enforce brainstorming-first and writing-plans-first discipline, and wire ADR-0019 into the operating manual. Wave A landed Stop-hooks (intra-turn signal); Wave B lands templates and entry-point skills (artifact-level discipline). The two waves compose: hooks catch drift at turn boundaries; templates prevent drift in the artifact that orchestrates the slice.

## What Was Done

- **Audited the slice-2 spec and plan structure** by H2 counts and section names before extracting. Spec is 479 lines × 13 H2 sections (Context, Decisions Locked, Goals with Non-goals nested, Architecture, Data flow, Sub-slice plan, Libraries, ADRs filed, Risks and Mitigations, Accessibility, Test strategy, Verification gates, References). Plan is 6,127 lines × 8 Plan Execution Rules × 6 Phases × 42 atomic Tasks.
- **Filed ADR-0019** (`docs/decisions/0019-spec-driven-templates.md`) documenting the four options considered (do-nothing, import TLC generic template, extract from slice-2 + add skills, templates-only-no-skills), the chosen Option C, and the boundary it extends from ADR-0012 + ADR-0018.
- **Authored `docs/superpowers/specs/0000-template.md`** preserving slice-2's 13-H2 structure, with HTML-comment author guidance under each section explaining what the section captures and how slice 2 filled it. The template embeds project rules at the structural level: §Architecture has the ADR-0013 mirror-contract reminder; §Verification Gates cross-references `M2-SLICE-CHECKLIST.md` rather than duplicating gates.
- **Authored `docs/superpowers/plans/0000-template.md`** preserving slice-2's Phase/Task/Step hierarchy verbatim where the rule is structural (the 8 Plan Execution Rules, the File Structure block, the Task template with Files header + numbered Steps + HEREDOC commit message, the Self-Review checklist mapping spec sections to tasks, the Execution Handoff offering subagent-driven vs inline modes).
- **Authored `.claude/skills/new-spec/SKILL.md`** with frontmatter matching the project pattern (`disable-model-invocation: true`, `allowed-tools` allowlist scoped to `cp`, `ls`, `date`, `git rev-parse`, `git status`, `git log`, `test`). Workflow: validate slug → validate template exists → resolve today's date in America/Sao_Paulo → check target does not exist → check branch state → copy template → fill ONLY the header (4 lines) → STOP and print the brainstorming gate. The skill never authors body content.
- **Authored `.claude/skills/new-plan/SKILL.md`** with the same frontmatter pattern. Workflow: validate slug → find the matching spec by glob (`*-${slug}-design.md`) → handle no-match / multi-match cases explicitly → check spec Status line (warn if "Awaiting user review") → check target does not exist → check branch state → copy template → fill header + back-reference → STOP and print the writing-plans gate.
- **Wired ADR-0019 into `CLAUDE.md`** with a new "Spec-Driven Workflow (ADR-0019)" subsection under "Project-Specific Critical Rules", listing both templates and both skills, with the discipline statement: "Skipping these and copying a previous spec/plan invariably introduces drift. Use the skills."
- **Self-audit caught a hallucinated number.** During post-write validation I noticed I claimed "17-section structure" in ADR-0019 (3 places) and CLAUDE.md (1 place). Verified via `grep -c '^## '` that the actual count is 13. Corrected all four occurrences. The slice-2-source claim in ADR-0019 was the same wrong "17" — fixed to "13 H2 sections". The CLAUDE.md was fixed in the same wave; the ADR was fixed via a follow-up commit (`708902b`) because the original commit (`ac63773`) had already landed and per CLAUDE.md "NEVER amend an existing commit unless the user explicitly says amend."
- **Scope precedent miss caught by commitlint.** First attempt to commit the templates used scope `superpowers` which is not in `commitlint.config.cjs scope-enum`. The hook rejected. Checked precedent: previous `docs/superpowers/` commits used `stops` (slice-tied) or `plan`/`spec` (early M1, since removed from enum). For project-meta templates the honest fit is `docs`. Re-committed as `docs(docs): ...` — slightly awkward type-scope echo but accurate.
- **Functional smoke-test before commit**: ran `cp` of both templates to `/tmp/` to confirm template integrity, ran `find docs/superpowers/specs -name '*-m2-slice-2-telas-core-design.md'` to confirm `/new-plan`'s spec-lookup logic finds the existing slice-2 spec, ran the same find against a non-existent slug to confirm it returns 0 matches (skill would stop with an error).
- **Pre-stop sanity check**: verified that after Wave B's edits, all three Wave-A hooks will be silent on this turn's `Stop` event — no `apps/mobile/lib/**/*.dart` edits (the untracked `optimize_route_page.dart` is pre-existing and Wave-A's transcript-only signal correctly ignores untracked files), no `apps/backend/src/**/schemas.ts` edits, no stack-affecting manifests edited (and ADR-0019 is in the working tree anyway).
- **Landed five Conventional Commits**, all passing Lefthook + commitlint without `--no-verify`:
  - `ac63773` — `docs(decisions): add adr-0019 spec-driven templates`
  - `708902b` — `docs(decisions): correct adr-0019 section count from 17 to 13`
  - `9dcd6c5` — `docs(docs): add spec and plan templates extracted from slice 2`
  - `0532736` — `feat(claude): add new-spec and new-plan skills`
  - `a21fc90` — `docs(claude): wire adr-0019 spec-driven workflow into operating manual`

## Decisions Made

1. **Extract templates from slice 2, do not import a generic TLC template.** Slice 2's structure is project-calibrated — it embeds ADR-0013 mirror contracts, M2-SLICE-CHECKLIST gates, prototype-1:1 obligation, cost-ceiling discipline. A generic template would erase that calibration. Documented as Option B (rejected) in ADR-0019.
2. **Skills scaffold the header and STOP.** They never author body content. The discipline that produced slice 2's Q1/Q2/Q3 locked decisions is `superpowers:brainstorming` — wrapping that inside `/new-spec` collapses two distinct decisions. Documented in ADR-0019 §Implementation Notes and enforced by the skill's printed gate.
3. **HTML comments in templates are author-facing, not agent-facing.** The "no comments in production code" rule from CLAUDE.md does not apply to documentation templates. The comments are reading-order guidance and section-purpose explanations that the author erases as they fill the section.
4. **Correct hallucinations via a new commit, never amend.** When self-audit caught "17 H2" vs actual "13 H2", the wrong number had already shipped in commit `ac63773`. Per CLAUDE.md Git Protocol ("NEVER amend an existing commit unless the user explicitly says amend"), the fix landed as a separate `docs(decisions): correct adr-0019 …` commit. Honest history beats clean history when self-correction is the lesson.
5. **Scope for project-meta docs is `docs`.** Templates and ADRs live under `docs/`; they don't tie to a single domain entity. The slight echo of `docs(docs):` is accepted over inventing a new scope or stretching `claude` (which is for `.claude/` config edits).

## Open Questions Left

- [ ] First real exercise of `/new-spec` and `/new-plan` happens at slice 3 (VRP real). If the skills are too rigid or too permissive, fix in a Wave-B amendment ADR.
- [ ] The plan template's "Plan Execution Rules" embeds rule 8 ("Push after each completed sub-slice") which is slice-shaped. For a non-sliced feature spec/plan pair (single-PR, no sub-slices), rule 8 should be amended. Defer to first non-slice feature need.
- [ ] Should `/new-spec` auto-create the feature branch (`feat/<slug>` off `develop`)? Currently it expects the human or a separate step. Adding branch creation would centralize the ritual; not adding it preserves the human-decides discipline. Leaving as-is until friction surfaces.

## Files Changed

**Created**:
- `docs/decisions/0019-spec-driven-templates.md`
- `docs/superpowers/specs/0000-template.md`
- `docs/superpowers/plans/0000-template.md`
- `.claude/skills/new-spec/SKILL.md`
- `.claude/skills/new-plan/SKILL.md`
- `docs/sessions/2026-05-19-15-harness-wave-b.md` (this file)

**Modified**:
- `CLAUDE.md` — added "Spec-Driven Workflow (ADR-0019)" subsection.
- `docs/sessions/0001-INDEX.md` (in this session-end commit)
- `TODO.md` (in this session-end commit)

**Deleted**: none.

## Commits Pushed

```
ac63773 docs(decisions): add adr-0019 spec-driven templates
708902b docs(decisions): correct adr-0019 section count from 17 to 13
9dcd6c5 docs(docs): add spec and plan templates extracted from slice 2
0532736 feat(claude): add new-spec and new-plan skills
a21fc90 docs(claude): wire adr-0019 spec-driven workflow into operating manual
<this commit> docs(sessions): harness-wave-b
```

Note: these were committed locally on `feat/m2-slice-2-telas-core` but **not pushed** during the session per the session-end protocol's default. Push happens deliberately by the human or in the slice-2 PR open step.

## Hand-off Notes for Next Session

- **Branch state**: `feat/m2-slice-2-telas-core` advanced from session 14's tip (`4abaacf docs(sessions): harness-wave-a`) by 6 commits — five feature/doc commits + this session-end. The slice-2 product surface is still untouched from session-13's `7437917`; both harness waves are orthogonal.
- **Wave A + Wave B together close the harness modernization arc Eduardo opened on 2026-05-19.** No further waves planned at this time.
- **`/new-spec` and `/new-plan` are callable** but not yet exercised end-to-end against a real new slice. First exercise will be slice 3 (VRP real). If the skills feel rigid or miss a step, amend ADR-0019 with a follow-up commit (`docs(decisions): amend adr-0019 — …`).
- **Hallucination-detection ritual is now codified in this session log.** Future template-extraction sessions should grep `^## ` and `^[1-9]\. \*\*` on both source and template before claiming structural counts in ADRs.
- **Slice-2 work remains the active product track.** Per `TODO.md`, sub 2d (Optimization + Nav, Tasks 26-32) and sub 2e (Periféricos, Tasks 33-34) remain pending. The untracked `optimize_route_page.dart` flagged by Wave-A's analyzer hook belongs to Task 30 (ScreenOptimizeRoute) and resolves when that task lands.

## Reference Material Used

- ADR-0012 (Lefthook + Commitlint + Commitizen tooling boundary) — Wave B extends this boundary at the artifact-template layer.
- ADR-0018 (Wave A in-loop hooks) — composes with Wave B; documented as Related in ADR-0019.
- `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` — the spec template's reference implementation.
- `docs/superpowers/plans/2026-05-13-m2-slice-2-telas-core.md` — the plan template's reference implementation.
- `docs/M2-SLICE-CHECKLIST.md` — referenced from the spec template's §Verification Gates.
- Existing project skills (`/commit`, `/session-end`, `/new-flutter-feature`) — read for frontmatter pattern (`disable-model-invocation: true`, `allowed-tools` allowlist).
- Anthropic Claude Code skills documentation — frontmatter conventions for slash-command skills.
- `superpowers:brainstorming` and `superpowers:writing-plans` (plugin skills) — the disciplines `/new-spec` and `/new-plan` enforce at their gates.
