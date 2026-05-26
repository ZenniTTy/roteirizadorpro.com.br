# Session 2026-05-19-16 — harness-wave-c-mirror-canonical

## Metadata

- **Date**: 2026-05-19 (America/Sao_Paulo)
- **Sequence**: 16
- **Agent**: Claude Code (Opus 4.7, 1M context)
- **Human**: Eduardo
- **Topic**: harness-wave-c-mirror-canonical
- **Duration**: ~1h15m
- **Related ADRs**: ADR-0020 (new — amends ADR-0013), ADR-0018 (hook hardened), ADR-0013 (header form normalized)
- **Related TODO items**: harness modernization Wave C (corrective wave following sessions 14 + 15)

## Goal of the Session

Eduardo requested two sequential QA passes before any Wave C corrections shipped: (1) a general audit of the Wave A + Wave B arc for hallucinations or skipped steps, then (2) a deeper audit focused on the schema source-of-truth contract (ADR-0013) to detect ambiguities before they propagated. The general audit surfaced four real defects in Wave A artifacts; the schema-focused audit surfaced seven divergent forms of the `// Mirror of:` header across the codebase. This session landed the corrective Wave C: filed ADR-0020 normalizing the header grammar, aligned the two real DTOs and the reference template to the canonical form, swept five documentation files to the ASCII arrow, hardened the Wave A hook to the new regex, fixed the `/verify-slice` allowlist gap, and added a defensive xargs fix to the analyze hook.

## What Was Done

- **Two-stage QA audit.** First general (stack-coverage gaps, hook portability, settings.json validity, ADR cross-refs, TODO/INDEX consistency, naming/discoverability). Second schema-focused (every doc, ADR, template, DTO, hook, and template referencing the `// Mirror of:` header). Both audits used independent subagent dispatch to avoid trusting prior-session claims; findings were verified against real files line-by-line before action.
- **Schema-focused audit factual findings (verified line-by-line):**
  - Five documentation files used Unicode `→` (CLAUDE.md L123, 03-CONVENTIONS L38, 02-ARCHITECTURE L341 + L362, M2-SLICE-CHECKLIST L25, 08-ROADMAP L90).
  - The reference template `_template.dart` L8 (which ADR-0013 cites as canonical) used ASCII `->`.
  - `stop_dto.dart` L1 used ASCII `->` (compliant with template).
  - `auth_dtos.dart` L1 invented a seventh form: backticks around the path, no arrow, no schema name — silently invisible to `check-dto-mirror.sh`'s substring grep.
  - Slice-2 plan L946 (Task 8 worked example, already in git history) used ASCII `->`.
  - The canonical reference template at L19 used backticks in its own `///` example, contradicting itself.
- **Architectural decision pre-execution.** Eduardo asked for the best-practice recommendation given the project's stack realities. Recommended Option C (`->` ASCII canonical + formal multi-DTO form) over the four alternatives, citing: code already uses `->`, `_template.dart` (cited reference) uses `->`, slice-2 plan in history uses `->`, ASCII avoids LC_ALL/UTF-8 grep gotchas, multi-DTO bundle reflects the real TypeBox export shape (`auth/schemas.ts` exports nine cohesive schemas), 1-file-per-DTO split would be discarded by post-M1 OpenAPI codegen anyway, Karpathy "no premature abstraction" applies.
- **Filed ADR-0020** documenting the four options considered (force `→`, force `->` with split, force `->` with multi-DTO recognition, defer to codegen) and the chosen Option C. Specified two normative L1 productions (single-DTO and multi-DTO), per-class `///` markers, optional parenthesized clarifying notes for composed schemas (`Type.Intersect`, aliases), exact regexes for tooling consumption, exhaustive worked examples, list of all files updated in the same commit set.
- **Caught and corrected own hallucination during ADR authoring.** Initial ADR-0020 cited the auth `<SchemaName>` example as `AuthUserSchema` and `AuthErrorSchema`. Checked the actual TypeBox file before editing the DTO and found the real exports are `UserSchema` and `ErrorResponseSchema` (the Dart class names are prefixed for clarity in mobile call sites, the TypeBox names are not). Amended ADR-0020 in place to reflect the real names and added a paragraph explaining the Dart-vs-TypeBox naming divergence.
- **Rewrote `auth_dtos.dart` L1 header to the multi-DTO production** carrying the nine TypeBox schema names verbatim. Replaced nine per-class `///` markers from the backticked variants to ASCII canonical form. Preserved two clarifying notes (`LoginResponseSchema (intersection of TokensSchema + { user })` and `RefreshResponseSchema (alias of TokensSchema)`) — discovered during validation that the strict per-class regex didn't match these; amended ADR-0020 to permit optional clarifying notes after the schema name, with tooling anchoring on the schema name only.
- **Updated `_template.dart`** convention block to cite both ADR-0013 and ADR-0020, name both productions, document the no-backticks rule. Removed backticks from the embedded `///` example. The class itself was already compliant.
- **Swept five documentation files** to ASCII `->` plus a one-line cross-reference to ADR-0020 in each.
- **Hardened the Wave A `check-dto-mirror.sh` hook** from substring grep (`grep -l "Mirror of: ${rel_schema}"`) to anchored regex (`grep -rlE "^// Mirror of: ${rel_schema} -> "`). Verified end-to-end: forged a transcript editing `auth/schemas.ts` and confirmed the hook now correctly identifies `auth_dtos.dart` as orphaned mirror (this would have been a silent pass before ADR-0020).
- **Added defensive `xargs -0` to `analyze-changed-dart.sh`** via `tr '\n' '\0' | xargs -0` pipeline. Effective Dart already prohibits whitespace in file names so no current file would trigger the original `xargs` whitespace splitting, but the fix is preemptive against future drift.
- **Fixed `/verify-slice` `allowed-tools` allowlist** to include `Agent`. The skill body has always promised to dispatch `prototype-fidelity-checker` and `adr-guardian` as parallel subagents but the original allowlist forgot the `Agent` tool, which would have blocked the dispatch on first real invocation.
- **Propagated ADR-0020 into the plan template** (`docs/superpowers/plans/0000-template.md` Rule 7) so every future plan authored via `/new-plan` carries the canonical grammar forward.
- **Added back-references** in ADR-0013 (head note + three inline mentions amended to ASCII) and ADR-0018 (implementation-notes line about `check-dto-mirror.sh` updated to name both productions and reference the anchored regex).
- **Pre-commit blocker handled with stash, not bypass.** The lefthook `mobile-analyze` job globs `apps/mobile/**/*.dart` and runs `flutter analyze` on the whole app (not just staged files) — by design, per ADR-0012. Three `info`-level issues in the pre-existing untracked `optimize_route_page.dart` (which is NOT this session's work and has been untracked since session 13's tip) caused the second Wave C commit to fail. Per CLAUDE.md "NEVER skip hooks unless the user explicitly asks", did NOT use `--no-verify`. Instead: stashed the untracked file with `git stash push --include-untracked`, landed the five Wave C commits cleanly, restored the stash. The file is back in working tree exactly as it was at session start.
- **Landed five Conventional Commits** all passing Lefthook + commitlint without `--no-verify`:
  - `8fb8c0d` — `docs(decisions): add adr-0020 mirror header canonical format`
  - `f6a6d5f` — `fix(auth): align auth_dtos and template to adr-0020 canonical header`
  - `f345ca9` — `docs(docs): sync five docs to adr-0020 ascii mirror header`
  - `f515b9e` — `feat(claude): harden wave-a hooks and skill per session-16 qa audit`
  - `4841241` — `docs(decisions): cross-link adr-0020 from adr-0013, adr-0018, plan template`

## Decisions Made

1. **ASCII `->` is canonical, not Unicode `→`.** Five docs migrate to `->`, two DTOs and one template stay on `->` (no code-side change for stop_dto.dart and _template.dart structure). Trade-off: docs lose visual intent of "mirror" but gain grep-friendly canonical form that aligns with shipped production code.
2. **Multi-DTO bundles are formally canonical, not exceptional.** The brace-list form (`-> {Schema1, Schema2, ...}`) is a first-class production in ADR-0020, not a tolerance. Justification: `auth_dtos.dart` ships in production with nine cohesive DTOs and its naming (`auth_dtos.dart` plural) is intentional; the source TypeBox file exports the same nine schemas in cohesive form.
3. **Optional clarifying notes after schema names.** Per-class `///` markers MAY carry parenthesized prose after the schema name to document composition (`Type.Intersect`, aliases). Tools anchor on the schema name only and ignore the note. This preserved meaningful documentation on `LoginResponseSchema` and `RefreshResponseSchema` without weakening tooling.
4. **ADR-0020 amends ADR-0013, does not supersede.** The architectural decision (TypeBox canonical, manual Dart mirror M1, codegen post-M1) is unchanged. Only the visible syntactic shape was normalized. Amendment preserves history per Michael Nygard ADR conventions.
5. **Stash the untracked file, do not use `--no-verify`.** When the lefthook `mobile-analyze` job blocked Wave C commits because of pre-existing issues in untracked code, the right move was to stash the orthogonal file and commit cleanly. Bypassing hooks is forbidden by CLAUDE.md and would have hidden the underlying signal that the untracked file has unfixed issues.
6. **Slice-2 historical artifacts not retrofitted.** Slice-2 plan and spec in `docs/superpowers/{specs,plans}/2026-05-13-m2-slice-2-telas-core*` already use ASCII `->`. Other session logs and commit history that reference `→` are NOT amended — historical accuracy beats retroactive cleanliness.

## Open Questions Left

- [ ] `apps/mobile/lib/features/stops/presentation/optimize_route_page.dart` (untracked since session 13) has 3 `prefer_const_constructors` + `unnecessary_brace_in_string_interps` info-level issues from `flutter analyze`. NOT Wave C scope. Will surface again when slice-2 sub-2d closes (Task 30 — ScreenOptimizeRoute) and either lands the file or removes it.
- [ ] First real exercise of the hardened `check-dto-mirror.sh` happens whenever the next backend schema edit lands. The new anchored regex is verified by synthetic transcript but not yet by production flow.
- [ ] First real exercise of `/verify-slice` with the `Agent` tool in allowlist remains slice-2 PR opening. The fix in this session removes the silent blocker but does not exercise the parallel dispatch.

## Files Changed

**Created**:
- `docs/decisions/0020-mirror-header-canonical-format.md`
- `docs/sessions/2026-05-19-16-harness-wave-c-mirror-canonical.md` (this file)

**Modified**:
- `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` — L1 header rewritten to multi-DTO production; nine `///` markers de-backticked.
- `apps/mobile/lib/features/auth/data/dto/_template.dart` — convention block expanded with both productions + ADR-0020 reference; embedded example de-backticked.
- `CLAUDE.md` — L123 `→` → `->` + multi-DTO mention + ADR-0020 reference.
- `docs/03-CONVENTIONS.md` — §8 `→` → `->` + multi-DTO mention.
- `docs/02-ARCHITECTURE.md` — L341 and L362 `→` → `->`.
- `docs/M2-SLICE-CHECKLIST.md` — L25 `→` → `->` + multi-DTO mention.
- `docs/08-ROADMAP.md` — L90 `→` → `->`.
- `docs/decisions/0013-api-contract-source-of-truth.md` — head note pointing to ADR-0020; L71 / L117 / L157 `→` → `->`.
- `docs/decisions/0018-harness-auto-validation.md` — implementation-notes line updated to name both productions and reference the anchored regex.
- `.claude/hooks/check-dto-mirror.sh` — substring grep → anchored regex.
- `.claude/hooks/analyze-changed-dart.sh` — `xargs` → `tr '\n' '\0' | xargs -0`.
- `.claude/skills/verify-slice/SKILL.md` — `allowed-tools` adds `Agent`.
- `docs/superpowers/plans/0000-template.md` — Rule 7 propagates canonical L1 grammar with both productions.
- `docs/sessions/0001-INDEX.md` (in this session-end commit)
- `TODO.md` (in this session-end commit)

**Deleted**: none.

## Commits Pushed

```
8fb8c0d docs(decisions): add adr-0020 mirror header canonical format
f6a6d5f fix(auth): align auth_dtos and template to adr-0020 canonical header
f345ca9 docs(docs): sync five docs to adr-0020 ascii mirror header
f515b9e feat(claude): harden wave-a hooks and skill per session-16 qa audit
4841241 docs(decisions): cross-link adr-0020 from adr-0013, adr-0018, plan template
<this commit> docs(sessions): harness-wave-c-mirror-canonical
```

Note: committed locally on `feat/m2-slice-2-telas-core` but **not pushed** during the session per the session-end protocol's default. Push happens deliberately by the human or in the slice-2 PR open step.

## Hand-off Notes for Next Session

- **Branch state**: `feat/m2-slice-2-telas-core` advanced from session 15's tip (`fecbd7e docs(sessions): harness-wave-b`) by 6 commits — five Wave C feature/doc commits + this session-end. Slice-2 product surface remains untouched from session 13's `7437917`; all three harness waves are orthogonal additions.
- **Harness modernization arc COMPLETE (Waves A + B + C).** No further harness work planned. Future amendments travel as `docs(decisions): amend adr-NNNN — …` commits triggered by real-use feedback.
- **All three Stop-hooks now behave correctly** against the canonical contract. `check-dto-mirror.sh` will catch both single-DTO and multi-DTO mirror drift; `warn-adr-drift.sh` continues to flag stack-affecting edits without ADR; `analyze-changed-dart.sh` is defensive against future whitespace in dart paths.
- **`/verify-slice` is callable end-to-end now** — the `Agent` tool addition removes the only known blocker. First real exercise is the slice-2 PR open.
- **Two real DTOs comply with ADR-0020**: `stop_dto.dart` (single-DTO, was already canonical) and `auth_dtos.dart` (multi-DTO, fixed this session). Any new DTO created by `/new-flutter-feature` or by hand must use one of the two productions; the hook will enforce immediately.
- **Slice-2 work itself remains the active product track.** Per `TODO.md`, sub 2d (Optimization + Nav, Tasks 26-32) and sub 2e (Periféricos, Tasks 33-34) remain pending. The 3 analyzer infos in `optimize_route_page.dart` will block any future Wave-A `analyze-changed-dart.sh` run that touches mobile/lib until that file is either landed (Task 30) or removed.

## Reference Material Used

- ADR-0013 (TypeBox as API source of truth) — the document this session amends.
- ADR-0018 (Wave A in-loop hooks) — the document whose hook this session hardens.
- ADR-0019 (Wave B spec/plan templates) — referenced for the plan-template propagation in Wave C.
- ADR-0020 (this session) — the new normative grammar.
- `apps/mobile/lib/features/auth/data/dto/auth_dtos.dart` — the divergent DTO this session aligns.
- `apps/mobile/lib/features/auth/data/dto/_template.dart` — the reference template clarified.
- `apps/mobile/lib/features/stops/data/dto/stop_dto.dart` — the already-canonical DTO used as ground-truth example.
- `apps/backend/src/auth/schemas.ts` — the TypeBox source enumerating the nine schemas mirrored by `auth_dtos.dart`.
- Independent subagent dispatched twice for QA (general + schema-focused) before Wave C was authored — both audits cited line-by-line evidence.
- CLAUDE.md "Git Protocol" — the rule that forbade `--no-verify` and shaped the stash-not-bypass decision.
- M2-SLICE-CHECKLIST.md "When something goes wrong" — guidance against destructive shortcuts.
