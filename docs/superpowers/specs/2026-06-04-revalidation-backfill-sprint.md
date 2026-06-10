# Spec — Revalidation & Backfill Sprint (M1 + M2 built surface)

> **Date:** 2026-06-04
> **Author:** Claude Code (with Eduardo)
> **Status:** Draft — to be executed MS-by-MS in a separate session
> **Branch:** dedicated `chore/revalidation-backfill` off the current branch tip (do NOT mix with feature work)
> **Source of truth:** this spec + `docs/08-ROADMAP-v2.md` (built surface only) + `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` (the audit pattern this sprint generalizes).

---

## Context

Eduardo asked for an **isolated sprint that backfills everything and revalidates each previously-built point**, run MS-by-MS in a future session, fully following harness best practices, so development can resume from a clean, verified, fully-documented baseline.

This is a **revalidation/hardening sprint**, not feature work. It produces zero new product features. It re-runs the harness quality pipeline (Spoke parity live, tests, analyze, ADR consistency, docs) against the surface that **already exists**, and closes every documentation and consistency debt found.

### What actually exists today (measured 2026-06-04, not assumed)

**Mobile (`apps/mobile/lib/features/`):** only `auth`, `routes`, `route_config`. The roadmap's Áreas 6–12 are NOT built (still `[ ]`). So "revalidate M1+M2 inteiro" concretely = revalidate:
- **M1:** auth UI + the M1 foundation that shipped 2026-05-09.
- **Slice 1:** the distributable APK (`v1.0.0`, shipped 2026-05-13).
- **Slice 2 built areas:** Área 2/2.5/3 (`routes` feature — drawer, list, wizard, active-route sheet, map, reuse-stops), Área 4 (add-stop via text, in `routes`), Área 5 (`route_config` — Detalhes da rota + sub-pickers).
- **Backend (`apps/backend/src/`):** `auth`, `health`, `routes`, `config`, `plugins`.

**Measured baselines (the sprint must not regress below these):**
- Mobile: **249 tests pass**; `flutter analyze` = **23 pre-existing issues** (all in `routes`: `reuse_stops_page.dart`×11, `add_stop_map_page.dart`×5, `places_repository.dart`×4, `app_drawer.dart`×1, `drawer_header_card.dart`×1, `current_route_stops_provider_test.dart`×1).
- Backend: `bun run typecheck` (`tsc --noEmit`) **clean (exit 0)**.
- `integration_test/` directory: **ABSENT** — no on-device coverage of any nav flow.

### Documentation/consistency debts found (docs-lint 2026-06-04 + ADR scan)

1. **5 broken ADR references** — ADR-0007, 0021, 0027, 0028, 0029 are **cited in `docs/10-CHANGELOG.md` but have no file on disk** (deleted in the 2026-05-26 reset). Dead links.
2. **ADR-0000 is still the unfilled template** (`ADR-NNNN: <Title>`).
3. **Malformed ADR titles** — ADR-0018 (`## ADR-0018:` — double-hash inside the H1) and ADR-0040 (`ADR 0040:` — missing hyphen) break the title convention/parsers.
4. **CHANGELOG temporal gap** — jumps 2026-05-26 → 2026-06-04; ADRs 0031–0040 (Stripe 0030 partially, Spoke pivot 0035/0036/0037, dual-IDE 0038, Google Maps 0039/0040) and the sprints between have no Changelog entry.
5. **Unregistered ADRs in CHANGELOG** — 0035–0040 (recent, relevant) + foundational 0000–0012, 0018.
6. **23 analyzer issues** — real lint debt in the `routes` feature, never cleaned.

## Decisions locked

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Scope of "everything" | **Built surface only (M1 + Slice 1 + Slice 2 Áreas 2/2.5/3/4/5 + backend), NOT roadmap Áreas 6-12** | You can't revalidate what isn't built. Áreas 6-12 are `[ ]`. |
| Q2 | Does this sprint change product behavior? | **No — revalidation/hardening only** | New features go in their own slices. A regression-only sprint keeps risk bounded. |
| Q3 | Broken ADR refs (0007/0021/0027/0028/0029) — recreate or remove? | **Per-ADR decision at MS1: recover from git history if the decision still holds; otherwise remove the citation + note supersession** | Some were reset-deleted intentionally; blindly recreating would resurrect dead decisions. Git history is the source. |
| Q4 | Backfill foundational ADRs (0000-0012) into CHANGELOG? | **One consolidated "foundational ADRs" Changelog note, not 13 separate entries** | The Changelog is for "documentation milestones", not an ADR mirror. A single pointer entry restores discoverability without bloating. |
| Q5 | Fix the 23 analyzer issues? | **Yes — but READ each first; only fix true lint debt, never suppress** | Pre-existing lint in `routes` is exactly the kind of debt this sprint exists to clear. Surgical, per-file. |
| Q6 | Re-inspect Spoke live for already-built screens? | **Yes for every Spoke-aligned built screen, per the standing "live-inspect per feature" directive** | The MS4/MS5 mislabeled-baseline failures prove prior captures can't be trusted. This sprint re-establishes a clean, current baseline for each built screen. |
| Q7 | Author the missing `integration_test/`? | **Yes — at minimum the Área 5 5-route Android-back chain (the highest-value gap already tracked for MS9)** | Widget tests cannot catch GoRouter branch-stack / Android-back issues (`lesson_slice_checklist_integration_test_gate`). |
| Q8 | One branch or per-MS branches? | **One dedicated `chore/revalidation-backfill` branch; one commit (or more) per MS; PR at the end** | Keeps the revalidation isolated from feature branches; reviewable as a unit. |

## Goals (acceptance — testable)

At sprint end, on `chore/revalidation-backfill`:

1. `docs/10-CHANGELOG.md` has **no dangling ADR reference** (every cited ADR exists OR the citation is removed with a supersession note).
2. Every ADR file has a **well-formed H1 title** (`# ADR-NNNN: <Title>`); ADR-0000 is either a filled decision or explicitly marked as the template.
3. `docs/10-CHANGELOG.md` covers the **2026-05-26 → 2026-06-04 gap** (ADRs 0031-0040 + the Spoke pivot + Google Maps) and carries a consolidated foundational-ADR pointer.
4. `flutter analyze` = **0 issues** across the whole mobile project (the 23 cleared, none suppressed).
5. `flutter test` ≥ **249** (no regression; new tests from revalidation push it higher).
6. Backend `bun run typecheck` clean.
7. Every **built Spoke-aligned screen** has a **fresh live Spoke baseline** captured this sprint (saved under `/tmp/spoke-reval-*` + referenced) and a recorded parity verdict.
8. `apps/mobile/integration_test/` exists with at least the **Área 5 5-route Android-back chain** test passing on the M54.
9. A **revalidation report** (`docs/audits/2026-06-04-full-revalidation.md`) summarizes per-area verdicts (clean / fixed / debt-deferred) — the same punch-list shape as the Área 5 audit.
10. `/docs-lint` re-run is **green** (0 CRITICAL / 0 IMPORTANT) for the built surface.

### Non-goals

- Building any roadmap Área 6-12 feature (those are future slices).
- Backend feature work (Slice 3) — only typecheck/contract revalidation of what exists.
- Backfilling Changelog entries for slices that predate the M2 reset beyond the one consolidated foundational note.
- Changing any product behavior. If revalidation surfaces a Spoke divergence, it's filed (ADR/punch-list) and fixed ONLY if it's a clear must-fix in already-built code; larger divergences become tracked items, not scope creep.
- Re-inspecting/validating screens that aren't built yet.

## Architecture (sprint structure, not code)

This sprint has **no new module**. It is organized as blocks of microsprints (detail in the plan):

- **Block A — Documentation & ADR consistency** (pure docs, mechanical, lowest risk).
- **Block B — Static-quality revalidation** (analyze→0, typecheck, codegen freshness).
- **Block C — Spoke parity revalidation** (live re-inspection of each built screen, per directive).
- **Block D — Test revalidation** (suite green + author the missing `integration_test/`).
- **Block E — Closure** (revalidation report + docs-lint green + PR).

Block ordering: A → B → C → D → E. A and B are independent and could swap, but A first keeps the ADR references clean before anything cites them.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| "Revalidate everything" balloons into rewriting working code | Q2 locks behavior-frozen; only lint debt + clear must-fixes touched. Larger findings → tracked, not fixed. |
| Recreating a reset-deleted ADR resurrects a dead decision | Q3: per-ADR git-history check; recover only if the decision still holds. |
| Suppressing analyzer issues to hit "0" | Q5: read each, fix root cause, never `// ignore:`. Reviewer checks for suppressions. |
| Spoke re-inspection finds a big divergence in already-shipped code | File it (punch-list/ADR); fix only clear must-fixes; defer structural ones with a tracked item — don't let it derail the sprint. |
| `integration_test` flakiness on device | Scope to the deterministic nav-stack assertions; use Semantics identifiers (already in place); run on M54 per `project_device_is_m54`. |
| Multi-session execution loses context | Each MS in the plan is self-contained with its own gates + a handoff note; this spec is the durable anchor. |

## Test strategy

| Layer | Tool | Coverage |
|---|---|---|
| Docs | `/docs-lint` + ADR scan | broken refs, orphans, malformed titles, CHANGELOG gaps |
| Static | `flutter analyze`, `bun run typecheck` | 0 issues mobile, clean backend |
| Codegen | `dart run build_runner build` | `.g.dart` freshness for every `@riverpod` |
| Spoke parity | Maestro MCP live (`inspect_screen` + `take_screenshot`) | fresh baseline per built screen + verdict |
| Unit/widget | `flutter test` | ≥ 249, no regression |
| Integration | `integration_test/` on M54 | Área 5 5-route Android-back chain (+ others as time allows) |

## Verification gates (sprint-level, mirrored per-MS in the plan)

- [ ] `flutter analyze` 0 issues (whole project).
- [ ] `flutter test` ≥ 249.
- [ ] `bun run typecheck` clean.
- [ ] `dart run build_runner build` produces no diff (codegen fresh).
- [ ] No dangling ADR refs; all ADR titles well-formed.
- [ ] CHANGELOG gap closed + foundational pointer.
- [ ] Fresh Spoke baseline + verdict per built screen.
- [ ] `integration_test/` Área 5 chain passes on M54.
- [ ] `docs/audits/2026-06-04-full-revalidation.md` written.
- [ ] `/docs-lint` green for built surface.
- [ ] `adr-guardian` + 2 reviewers (or `/verify-slice`) clean before PR.

## References

- `CLAUDE.md` — operating manual + Karpathy 4 + source-of-truth hierarchy.
- `docs/08-ROADMAP-v2.md` — built vs unbuilt surface.
- `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md` — the audit pattern this sprint generalizes.
- `docs/M2-SLICE-CHECKLIST.md` — per-MS verification discipline.
- Memory: `feedback_spoke_evidence_per_ms` (live-inspect per feature),
  `feedback_spoke_parity_zero_debt_per_ms`,
  `feedback_escalate_recurring_and_gate_check`,
  `lesson_slice_checklist_integration_test_gate`,
  `lesson_checkpoint_discipline_between_microsprints`,
  `project_device_is_m54`.
