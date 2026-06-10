# Revalidation & Backfill Sprint — Implementation Plan

> **For agentic workers:** run this MS-by-MS in a dedicated session. This sprint is REVALIDATION/HARDENING — it produces zero new product features. Behavior is frozen (spec Q2). Each MS ends with its gates green + a checkpoint (push, update this plan's checkboxes) before the next.
>
> **Spec:** `docs/superpowers/specs/2026-06-04-revalidation-backfill-sprint.md`
> **Branch:** create `chore/revalidation-backfill` off the current branch tip. Do NOT mix with feature work.
> **Baselines to not regress:** 249 mobile tests · `flutter analyze` 23→0 · backend typecheck clean · `integration_test/` absent→present.

## Working directory
`/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/app-roteirizadorpro`

## Standing rules (every MS)
1. **Behavior frozen.** Only docs, lint debt, codegen freshness, tests, and CLEAR must-fixes in already-built code. Larger findings → tracked item, not scope creep.
2. **Live-inspect per feature** (memory `feedback_spoke_evidence_per_ms`): re-capture the actual Spoke widget live before asserting parity — never trust a `/tmp/spoke-*` file from a prior session.
3. **No analyzer suppressions.** Fix root cause; never `// ignore:`.
4. **TDD where a test changes.** Red→green; update locking tests in the same edit.
5. **`git diff HEAD --stat` after any agent/workflow dispatch** (memory `lesson_git_diff_head_before_commit_after_workflows`).
6. **No `.g.dart` committed** (ADR-0005). Codegen regenerated, not staged.
7. **Checkpoint per MS** (memory `lesson_checkpoint_discipline_between_microsprints`): gates green → push → tick this plan → session log if non-obvious.
8. **No `--no-verify`.** Conventional Commits, scoped.

---

## Phase 0 — Pre-flight (no commits)

- [ ] **0.1** `git status` clean; create `chore/revalidation-backfill` off current tip; confirm HEAD.
- [ ] **0.2** Confirm tooling: `flutter --version` ≥ 3.44, `bun --version` ≥ 1.3, `node` 20.x, `adb devices` shows `RQCW401G33T` (M54), `MAESTRO_CLI_NO_ANALYTICS=1 maestro --version` reachable, `/mcp` shows `dart` + `maestro` connected.
- [ ] **0.3** Re-read this plan + the spec + `docs/audits/2026-06-03-area5-ms1-ms5-retro-audit.md`.
- [ ] **0.4** Capture fresh baselines into the MS-E report scratch: `flutter test` count, `flutter analyze` issue list, `bun run typecheck`.

---

## BLOCK A — Documentation & ADR consistency (pure docs, mechanical)

### MS-A1 — Broken ADR references (0007/0021/0027/0028/0029)
**Files:** `docs/10-CHANGELOG.md`, possibly recreated `docs/decisions/00NN-*.md`.
- [ ] A1.1 For each of 0007, 0021, 0027, 0028, 0029: `git log --all --oneline -- 'docs/decisions/00NN-*.md'` to find the deleted file's last state.
- [ ] A1.2 Per ADR (spec Q3): if the decision STILL holds today → `git show <sha>:<path>` recover it (mark Status appropriately). If superseded/abandoned by the reset → remove the citation from the CHANGELOG and add a one-line "superseded by the 2026-05-26 reset" note where it was cited.
- [ ] A1.3 Verify no dangling ADR ref remains: `for n in 0007 0021 0027 0028 0029; do grep -q "ADR-$n" docs/10-CHANGELOG.md && ! ls docs/decisions/$n-*.md >/dev/null 2>&1 && echo "STILL DANGLING $n"; done` → empty.
- [ ] A1.4 Commit `docs(adr): resolve 5 dangling ADR references from the 2026-05-26 reset`.

### MS-A2 — Malformed ADR titles + template
**Files:** `docs/decisions/0000-*.md`, `0018-*.md`, `0040-*.md`.
- [ ] A2.1 ADR-0018: fix the H1 (currently `## ADR-0018:` inside the doc) to `# ADR-0018: <Title>`. Verify only the title line changes.
- [ ] A2.2 ADR-0040: fix `ADR 0040:` → `ADR-0040:` (hyphen) in the H1.
- [ ] A2.3 ADR-0000: either fill it as a real decision OR rename/mark it explicitly as the canonical template (decide with Eduardo if unclear; default = mark as template, since 0001+ are the real ADRs).
- [ ] A2.4 Sanity: every ADR has a well-formed H1: `for f in docs/decisions/0*.md; do head -1 "$f" | grep -qE '^# ADR-[0-9]{4}: ' || echo "BAD TITLE: $f"; done` → only 0000 (template) may remain, intentionally.
- [ ] A2.5 Commit `docs(adr): fix malformed ADR-0018/0040 titles + mark ADR-0000 template`.

### MS-A3 — CHANGELOG gap backfill (2026-05-26 → 2026-06-04) + foundational pointer
**Files:** `docs/10-CHANGELOG.md`.
- [ ] A3.1 Read ADRs 0035, 0036, 0037, 0038, 0039, 0040 (+ confirm 0030 Stripe coverage) to summarize each accurately (don't guess).
- [ ] A3.2 Add a `## 2026-05-27 — Spoke white-label pivot + Maps` entry (or appropriate dates) covering ADR-0035/0036/0037 (Spoke source-of-truth + parity gate + Maestro) and ADR-0038 (dual-IDE) + ADR-0039/0040 (Google Maps SDK + Places). Use real dates from each ADR's header.
- [ ] A3.3 Add ONE consolidated foundational-ADR note (spec Q4) pointing to `docs/decisions/` for ADR-0000–0012 + 0018 rather than 13 entries.
- [ ] A3.4 Verify CHANGELOG date order is descending + append-only (didn't rewrite past dated sections).
- [ ] A3.5 Commit `docs(changelog): backfill 2026-05-26→06-04 gap (ADR-0035..0040) + foundational pointer`.

### MS-A4 — Orphan/index sweep + cross-links
**Files:** `docs/*` indexes, `CLAUDE.md` references.
- [ ] A4.1 Every top-level `docs/*.md` + new subdir (`audits/`, `briefing/`, `handoffs/`) referenced from an authoritative file (CLAUDE.md References OR ROADMAP). Add pointers for any orphan (briefing/handoffs were 0-ref).
- [ ] A4.2 Run the cross-doc link check (resolve every relative `.md` link, per-file dir) — fix any genuinely broken link.
- [ ] A4.3 Commit `docs: index/orphan sweep + cross-link fixes`.

---

## BLOCK B — Static-quality revalidation

### MS-B1 — analyze → 0 (clear the 23 issues, no suppressions)
**Files:** `routes` feature: `reuse_stops_page.dart` (11), `add_stop_map_page.dart` (5), `places_repository.dart` (4), `app_drawer.dart` (1), `drawer_header_card.dart` (1), `test/.../current_route_stops_provider_test.dart` (1).
- [ ] B1.1 `flutter analyze` → capture the exact 23 with codes. READ each site.
- [ ] B1.2 Fix root cause per issue (trailing commas, deprecated APIs, unused, etc.). NO `// ignore:`. If an issue reveals a real bug, fix it + add a test.
- [ ] B1.3 `flutter analyze` → **0 issues**. `flutter test` still ≥ 249 (no regression from the fixes).
- [ ] B1.4 Commit `style(routes): clear 23 analyzer issues (no suppressions)` (or split by file if large).

### MS-B2 — Codegen freshness + backend typecheck
- [ ] B2.1 `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs` → `git status` shows NO `.g.dart` diff (they're gitignored; this proves they regenerate clean). If a regenerated file differs from what the code expects, investigate.
- [ ] B2.2 `cd apps/backend && bun run typecheck` → clean. If the schema/DTO mirror drifted (ADR-0013), fix + note.
- [ ] B2.3 `bun run lint` on landing if present; skip if N/A.
- [ ] B2.4 Commit only if something changed; otherwise record "codegen + typecheck clean, no diff" in the MS-E report.

---

## BLOCK C — Spoke parity revalidation (live, per built screen)

> For EACH built Spoke-aligned screen, dispatch `spoke-parity-checker` (Maestro MCP preferred) for a FRESH live capture + verdict. Save to `/tmp/spoke-reval-<area>-*.png`. Cite screenshot pixels for icon claims (`lesson_visual_screenshot_overrides_xml_inference_in_compose_apps`). Confirm M54 + Spoke logged-in before each dispatch.

### MS-C1 — Auth (Área 1) parity
- [ ] C1.1 Live-inspect Spoke auth/login; compare to `apps/mobile/lib/features/auth/`. Record verdict + any divergence.

### MS-C2 — Routes: drawer + list + wizard (Área 2/2.5)
- [ ] C2.1 Live-inspect Spoke drawer, route list, create-route wizard, reuse-stops; compare to `routes` feature. Verdict + divergences.

### MS-C3 — Active route: map + sheet (Área 3)
- [ ] C3.1 Live-inspect Spoke active-route map + bottom sheet (collapsed + expanded + stop cards + "Configuração de rota" rows); compare. Verdict + divergences.

### MS-C4 — Add stop via text (Área 4)
- [ ] C4.1 Live-inspect Spoke add-stop search/typeahead; compare. Verdict + divergences.

### MS-C5 — Detalhes da rota + sub-pickers (Área 5)
- [ ] C5.1 Live-inspect Spoke Detalhes shell + Partida + time picker + Destino sheet + Pausa; compare to `route_config`. (This re-confirms the MS-FIX parity fixes held.) Verdict + divergences.

> After C1-C5: any **must-fix in already-built code** → fix it now (TDD) with its own commit. Any **structural divergence** → file an ADR/tracked item, do NOT fix in this sprint (spec Q2/non-goals).

---

## BLOCK D — Test revalidation

### MS-D1 — Suite + coverage audit
- [ ] D1.1 `flutter test` full → green, count recorded. Spot-check for tautological tests in each built feature (the audit found none in route_config; verify auth + routes too).
- [ ] D1.2 List any built production path with NO test; add tests for clear gaps (behavior-frozen — assert current behavior).

### MS-D2 — Author the missing `integration_test/`
**Files:** CREATE `apps/mobile/integration_test/area5_route_details_flow_test.dart` (+ a `flutter_test_config.dart`/driver if the harness needs one).
- [ ] D2.1 Author the Área 5 5-route Android-back chain test (Detalhes → Partida → back; → time picker → confirm; → Destino sheet → card-2 → address search → back-to-details; → back to Área 3). This is the highest-value gap (tracked since MS5; `lesson_slice_checklist_integration_test_gate`).
- [ ] D2.2 Run on M54: `flutter test integration_test/area5_route_details_flow_test.dart -d RQCW401G33T`. Green.
- [ ] D2.3 (As time allows) add Área 2/3/4 nav-chain integration tests.
- [ ] D2.4 Commit `test(integration): Área 5 5-route Android-back chain on M54`.

---

## BLOCK E — Closure

### MS-E1 — Revalidation report + docs-lint + PR
**Files:** CREATE `docs/audits/2026-06-04-full-revalidation.md`; UPDATE `TODO.md`, `docs/sessions/0001-INDEX.md`, new session log.
- [ ] E1.1 Write `docs/audits/2026-06-04-full-revalidation.md`: per-area verdict table (auth/routes/route_config/backend/Slice1/M1) — clean / fixed-this-sprint / debt-deferred — mirroring the Área 5 audit shape. Include the final baselines (test count, analyze 0, typecheck clean).
- [ ] E1.2 Re-run `/docs-lint` → green (0 CRITICAL/IMPORTANT for built surface).
- [ ] E1.3 `/verify-slice` (or manual: analyze + test + `adr-guardian`) → GO.
- [ ] E1.4 Session log `docs/sessions/2026-06-XX-NN-revalidation-sprint.md` + INDEX line + TODO update.
- [ ] E1.5 `git push -u origin chore/revalidation-backfill`; open PR with body summarizing the revalidation (what was clean, what was fixed, what's tracked-deferred).

---

## Self-review

- **Scope:** built surface only (spec Q1) — no Áreas 6-12.
- **Behavior:** frozen (spec Q2) — only docs/lint/tests/codegen + clear must-fixes.
- **Sequencing:** A (docs) → B (static) → C (parity) → D (tests) → E (closure). A before C so ADR refs are clean before parity work cites them.
- **Each MS** is self-contained with gates + fits a single session slice; the spec is the durable cross-session anchor.
- **Estimate:** Block A ~3-4 MS docs, B ~2 MS, C ~5 MS (one per built area, live inspection is the time cost), D ~2 MS, E ~1 MS. ~13-14 microsprints total.

## Execution handoff

Run with `superpowers:executing-plans` or MS-by-MS manually. One MS = gates green + checkpoint before the next. Block C dispatches `spoke-parity-checker` per area (confirm M54 + Spoke login first). Block D needs the M54 connected. PR only at MS-E1. The plan checkboxes are the cross-session progress tracker — tick them as you go.
