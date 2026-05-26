# Session 28 — Pivot residue cleanup (categories 1 + 2)

## Metadata

- **Date**: 2026-05-26 (America/Sao_Paulo)
- **Sequence**: 28
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Post-pivot doc/ADR cleanup before MS-A1
- **Duration**: ~1h30m
- **Related ADRs**: ADR-0035 (drives the pivot), ADR-0036 (introduced last session), no new ADR filed (textual amendments only)
- **Related TODO items**: TODO.md §"Prototype fidelity findings" banner replaced; ROADMAP v1 references updated across the active doc set.

## Goal of the Session

Eduardo asked to do a full sweep for pre-pivot residue (old binding language, stale "canonical UI" phrasing, references to the superseded `08-ROADMAP.md`, and ADR framings that no longer match the post-ADR-0035 source-of-truth hierarchy) before the first real microsprint MS-A1 starts. The pivot itself (sessions 27.A–27.D) covered the foundational ADRs + inventory + roadmap-v2 + subagent rescope, but several documents still had inertia from the old "prototype is canonical UI" stance. Goal: realign anything that could mislead a future agent into reverting to the old hierarchy.

## What Was Done

1. **Mapped cleanup targets** via grep — found 24+ remaining sites of "canonical UI", "prototype wins", "1:1 with prototip" language; 12+ stale `docs/08-ROADMAP.md` references; 4 ADRs that needed a "Post-ADR-0035 reading" note; the TODO fidelity-findings banner I wrote in session 27 that was now itself outdated (it said "until the inventory ships" — the inventory had already shipped).

2. **Archived `docs/08-ROADMAP.md` → `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md`** via `git mv`. Created a 12-line redirect stub at the original path so any agent grepping CLAUDE.md or other docs for `08-ROADMAP.md` still lands on a file that points to v2 + the archive. Updated the archive's banner from "SUPERSEDED" to "ARCHIVED HISTORICAL SNAPSHOT" with stronger language ("DO NOT use as the active plan") and a "how to read this file" guide.

3. **Updated 5 doc-level v1 → v2 references**: CLAUDE.md (4 sites including the §"The single source of truth for M2 is..." line and the §Onboarding Ritual reading list), `docs/01-PROJECT.md` (1 site), `README.md` (2 sites — narrative + tree comment), `docs/M2-SLICE-CHECKLIST.md` (4 sites — pre-flight read list, PR body template, post-merge ✅ marker, glossary), `docs/04-FEATURES.md` (2 sites — feature-map header note + bottom-of-section authority note), `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (2 sites — §8 next-steps step 2 marked Concluído + §References split into ATIVO/ARQUIVADO).

4. **Audited `.claude/agents/prototype-fidelity-checker.md`** for residual "structure must match" / "flows must match" language. **No edits needed** — the subagent's prompt body is already correctly scoped to visual identity only (the rescope I did in session 27 was complete; it has a "you do not verify" list + an "Items not in scope" report section).

5. **Audited `docs/05-SCREENS.md`** — fixed the §"Slice mapping" header note to point to v2 with explicit MS-A1..MS-A8 / MS-B1..MS-B9 mapping pointer, and reframed the §"Spoke/Circuit feature mapping (reference)" intro to acknowledge that the **inventory** (`docs/inventory/2026-05-26-spoke-vs-rotpro.md` §3 + §7) is the authoritative scope source and that this section's tables are a high-level summary.

6. **Reclassified TODO.md §"Prototype fidelity findings"** banner — replaced the session-27 banner (which said "leave entries as-is until the inventory ships") with a stronger one that recognises the inventory has shipped, frames the list as FROZEN HISTORY, explains what replaces it for going-forward work (visual-token gaps → rescoped `prototype-fidelity-checker` at D4; functional gaps → `spoke-parity-checker` at D4; structural gaps not in Spoke → close as non-issue), and gives a concrete decision rule for each remaining `[ ]` item.

7. **Added "Post-ADR-0035 reading" sections to 4 ADRs**:
   - **ADR-0017** (External nav) — reframes "Waze default" as a functional/preference decision that today traces to Spoke + cliente, not to the prototype as canonical UI.
   - **ADR-0021** (Slice-2 fidelity remediation) — reframes the four Criticals as workflow-pattern history; clarifies that the workflow itself (audit → microsprint correction → device-E2E gate) is preserved and reused, but the target of "fidelity" is now two-layered.
   - **ADR-0033** (Drop neon dot) — removes the "deviation from prototype" framing; the prototype is canonical only for visual identity *tokens*, not decorative accents on `PrimaryButton`.
   - **ADR-0034** (Voice single CTA) — same pattern; the prototype's two-button footer was always a sketch (already noted in the original §Context), and single-CTA design aligns with Spoke + cliente.

8. **Updated v1 references inside ADRs** — ADR-0015 (4 sites — the foundational M2 plan ADR; needed careful wording because it predates the pivot), ADR-0020 (2 sites — `08-ROADMAP.md L90` worked example annotated with archive path + v2 forward-port), ADR-0030 (3 sites — Stripe Pix references slice 4 docs), ADR-0002 (1 site — Flutter keystore reference).

9. **Final grep verification** — `grep -rnIE "canonical UI" docs/ README.md CLAUDE.md TODO.md .claude/agents/` produces only legitimate matches: ADR-0032/0033/0034 §Context historical quotes (describing what the prototype said at the time the ADR was filed), the new "Post-ADR-0035 reading" sections (which use the phrase forward-referentially), and ADR-0035 itself (which defines the term). `grep -rnIE "08-ROADMAP\.md"` excluding archive/sessions/superpowers/sprints/changelog/Blueprint/0010 returns 0 stale references in active docs.

## Decisions Made

1. **Archive v1 rather than delete its body** — the v1 file is a snapshot of project state at MS-14; deleting it would lose context that's useful when reading sessions 12-16. The redirect stub at the original path gives both audiences (legacy refs + new readers) a clean path.
2. **Add "Post-ADR-0035 reading" prose-style appendices** instead of rewriting ADR bodies — preserves the paper trail of the original decision while making it readable under the new hierarchy. Future agents see what was decided AND how to interpret it today.
3. **Keep §Context historical quotes intact** in ADRs 0032/0033/0034 (the lines that say "The canonical UI source `prototipo/...` defined ...") — these describe state-of-the-world at the time the ADR was filed and rewriting them would distort history. The "Post-ADR-0035 reading" appendix and the existing "Reframed by" line at the top of each handle the reframing.
4. **Skip Blueprint.md and 04-FEATURES.md's M1-era Blueprint** — Blueprint is a historical M1 planning doc (frozen since M1 shipped); rewriting its 08-ROADMAP refs would be revisionist. Same logic skips `docs/superpowers/specs/*` and `docs/superpowers/plans/*` files for pre-pivot artifacts (they're spec/plan archives, not active docs).
5. **No new ADR for this cleanup** — purely textual amendments to existing decisions. ADR-0035 itself anticipated this sweep in its §Consequences list.

## Open Questions Left

- [ ] None — the cleanup completed within scope and the user is now ready to give GO on MS-A1 (Rota como entidade).

## Files Changed

**Created**:
- `docs/sessions/2026-05-26-28-pivot-residue-cleanup.md` (this log)
- `docs/archive/2026-05-26-08-ROADMAP-v1-pre-pivot.md` (via git mv from `docs/08-ROADMAP.md`)
- `docs/08-ROADMAP.md` (new redirect stub replacing the archived file)

**Modified**:
- `CLAUDE.md` (4 v1 → v2 reference updates)
- `README.md` (2 sites)
- `docs/01-PROJECT.md` (1 site)
- `docs/04-FEATURES.md` (2 sites)
- `docs/05-SCREENS.md` (2 sites — slice mapping note + Spoke/Circuit feature mapping intro)
- `docs/M2-SLICE-CHECKLIST.md` (4 sites)
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` (2 sites — §8 + §References)
- `docs/decisions/0002-flutter-mobile.md` (1 site)
- `docs/decisions/0015-m2-plan-and-libraries.md` (4 sites — foundational M2 ADR)
- `docs/decisions/0017-external-navigation-handoff.md` (+ Post-ADR-0035 reading section)
- `docs/decisions/0020-mirror-header-canonical-format.md` (2 sites)
- `docs/decisions/0021-slice-2-fidelity-remediation.md` (+ Post-ADR-0035 reading section)
- `docs/decisions/0030-stripe-pix-30-day-access-pass.md` (3 sites)
- `docs/decisions/0033-drop-primary-button-neon-dot.md` (+ Post-ADR-0035 reading section)
- `docs/decisions/0034-voice-page-single-cta.md` (+ Post-ADR-0035 reading section)
- `TODO.md` (§"Prototype fidelity findings" banner replaced)

## Verification Performed

- `grep -rnIE "canonical UI" docs/ README.md CLAUDE.md TODO.md .claude/agents/` → only ADR §Context historical quotes + new "Post-ADR-0035 reading" sections + ADR-0035 itself remain. No stale binding language in active docs.
- `grep -rnIE "08-ROADMAP\.md"` excluding archive/sessions/superpowers/sprints/changelog/Blueprint/decisions/0010 → 0 stale references in active doc paths.
- `git diff --stat HEAD` post-cleanup → 16 files changed.
- No code touched (zero `apps/mobile/lib/**`, `apps/backend/src/**`, `apps/landing/src/**` edits) — pure documentation cleanup.
- adr-guardian dispatch **not run** — no stack-affecting files touched (no package.json / pubspec.yaml / prisma / docker-compose / infra/ edits); textual ADR amendments don't trigger the gate per the subagent's frontmatter.
- `flutter analyze` / `flutter test` / `bun typecheck` **not run** — no code edits.

## Next Steps

1. Push this cleanup commit + session log together.
2. **Wait for Eduardo's GO on MS-A1** (Conceito de "Rota" como entidade, first microsprint of slice 2 in ROADMAP-v2).
3. When GO arrives → invoke `superpowers:brainstorming` to lock the 3-4 critical decisions for MS-A1 before writing the spec.

## Related Logs

- [2026-05-26-27 — spoke-functional-pivot](./2026-05-26-27-spoke-functional-pivot.md) — the foundational pivot session this cleanup follows up on.
</content>
</invoke>