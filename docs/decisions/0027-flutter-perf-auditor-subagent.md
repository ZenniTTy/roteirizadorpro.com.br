# ADR-0027: `flutter-perf-auditor` subagent — read-only perf punch-list reviewer

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0023 (Dart MCP — grounds the agent's symbol lookups), ADR-0025 (`flutter-test-author` — sibling subagent, same project-scope pattern), ADR-0018 (in-loop hooks — `flutter analyze` Stop hook is the auditor's input for §2), ADR-0016 (map + tile policy — informs the §6 cache check)
- **Sprint:** M2-AI Harness — Phase 4 (see `docs/sprints/2026-05-24-m2-ai-harness.md`)

## Context

Slice 2 (Telas Core) is shipping a map screen (`flutter_map` + OSM tiles), reorderable stop lists, voice/OCR capture surfaces, and a sharing sheet. Slice 3 (VRP real) will add GraphHopper matrix parsing and the home-bias optimization on top of it. Both surfaces are classic perf-regression territory: dynamic lists rendered with non-builder constructors, missing `const`, over-broad `ref.watch`, heavy work on the UI thread, tile re-downloads, repaint storms from marker layers.

`flutter analyze` catches some of this (`prefer_const_*` lints) but not the structural patterns: a `ListView(children: [...])` with a runtime-sized children list is valid Dart and analyzer-clean — it just rebuilds the entire viewport on every state change. Same for `ref.watch(provider)` when only one field is read. These need a reviewer who knows the Flutter perf playbook and reads code with that lens.

Three options:

1. **Defer to manual review at PR time** — high signal but slow, and the human reviewer's perf attention is finite.
2. **Codify the checklist into a lint package** — possible (`custom_lint` + `riverpod_lint` are already in dev_dependencies) but high friction: each rule is a Dart package, the rules need updating as Flutter evolves, and lint output doesn't categorize severity per project context.
3. **A read-only subagent** — fast to author, easy to update as new patterns appear, categorizes severity, and integrates with the existing slice checklist as a verification step.

Option 3 mirrors the pattern already in production for `prototype-fidelity-checker` (UI fidelity) and `adr-guardian` (ADR coverage): both are read-only subagents that produce punch lists. The auditor is the perf-axis equivalent.

## Decision

**Adopt the `flutter-perf-auditor` subagent.** Project-scoped, file at `.claude/agents/flutter-perf-auditor.md`. Read-only by tool allowlist: `Read, Grep, Glob, Bash, mcp__dart__resolve_workspace_symbol, mcp__dart__hover, mcp__dart__analyze_files`. No `Edit`, no `Write`, no `MultiEdit` — the contract is mechanically enforced by the allowlist, not just by the prompt body.

### Canonical checklist (9 items)

The agent body codifies these patterns in priority order:

1. `ListView` / `GridView` builder discipline.
2. Missing `const` constructors (cross-referenced against `flutter analyze` output).
3. `ref.watch` granularity (`.select` opportunities).
4. Heavy work on the UI thread (`jsonDecode`, matrix loops → `Isolate.run` / `compute`).
5. `RepaintBoundary` for high-churn subtrees.
6. Map tile caching (cross-referenced against ADR-0016).
7. Stable keys on reorderable / animated lists.
8. Image decoding cost (`cacheWidth` / `cacheHeight`).
9. Excessive `StatefulWidget` where `ConsumerWidget` would suffice.

Each item has: anti-pattern, fix, severity guidance, where-to-look hint. The agent quotes the offending snippet with file:line, classifies severity (must-fix / should-fix / nit), and produces a single Markdown report — no back-and-forth.

### Tool allowlist rationale

- `Bash` is permitted (not glob-restricted) so the agent can run `flutter analyze --no-pub` for §2 cross-reference and use the `git diff --name-only main...HEAD` pattern shared with `prototype-fidelity-checker`. The prompt body explicitly forbids `flutter test`, `flutter run`, build_runner, Gradle, Pod — discipline lives in the prompt, same as ADR-0025.
- 3 Dart MCP tools (subset of `flutter-test-author`'s 5): only the read-only / introspection tools, no `run_tests` or `analyze_files` write-coupled paths. The agent looks up signatures; it does not exercise them.
- `model: sonnet` for budget consistency with the other 3 project-scope subagents.

## Options Considered

### Option A — Manual PR-time review only

- Pros: zero new infra.
- Cons: human reviewer attention is finite; the same anti-patterns recur (slice-2 microsprints found three `ListView(`-with-dynamic-children patterns mid-review); no severity classification.
- **Rejected.**

### Option B — Custom lint package (`custom_lint` plugin)

- Pros: lints fire at edit time; integrated into IDE + CI; can codify project-specific rules.
- Cons: each rule is a Dart package boilerplate; checklist updates require recompilation; lint output is line-by-line, not categorized for review purposes; cannot cross-reference ADR-0016's tile policy because lints don't read external docs. Worth revisiting in M3 once the perf surface is more settled, but premature now.
- **Rejected for this sprint; revisit candidate.**

### Option C (this ADR) — Read-only subagent with canonical checklist

- Pros: fast to author, easy to update (edit a Markdown file), severity categorization tuned to slice context, cross-references existing ADRs (0016 tile policy, 0024 generated-code exclusion), mirrors the proven `prototype-fidelity-checker` / `adr-guardian` shape.
- Cons: requires dispatch by the human or a wrapper skill (no auto-trigger like a hook). Mitigated by adding it to `docs/M2-SLICE-CHECKLIST.md` §Verification so slice closeouts always include it.
- **Accepted.**

### Option D — Adopt a community subagent (e.g., from `VoltAgent/awesome-claude-code-subagents`)

- Pros: leverage prior art.
- Cons: same problem as ADR-0025's Option D — those subagents target Flutter generally, not this stack's specifics (Riverpod 3 codegen, `flutter_map` + OSM, ADR-0016 cache policy). Adapting them is most of the work; carrying their unrelated decisions forward is technical debt.
- **Rejected as source; used as inspiration.**

## Consequences

### Positive

- **Perf review becomes mechanically checkable** at slice-close time. The checklist is in version control; updates travel with their PR.
- **Severity classification reduces alarm fatigue.** Auditor output is action-prioritized, not a flat list of every lint.
- **Cross-references existing decisions.** §6 (tile cache) explicitly points to ADR-0016 so the auditor doesn't blanket-flag a missing cache the team intentionally deferred.
- **Excludes generated code.** §"What you must not do" explicitly skips `*.g.dart` / `*.freezed.dart` — the Riverpod codegen output is owned by `riverpod_generator`, not by perf review.
- **MCP-grounded symbol lookup.** Like `flutter-test-author`, the auditor can confirm symbol existence against pub-cache instead of guessing from training memory.

### Negative

- **No auto-trigger.** Unlike the hooks (ADR-0018 + ADR-0024) which fire automatically, the auditor must be invoked. Mitigated by `M2-SLICE-CHECKLIST.md` §Verification listing it as a step.
- **Checklist drift risk.** Flutter evolves; what's "must-fix" today might be a non-issue once Flutter 4 lands. The prompt body explicitly invites the human to suggest checklist updates rather than silently expand scope — but the checklist still needs periodic curation.
- **Smoke-test validation requires session reload.** Same constraint as ADR-0023 and ADR-0025: Claude Code builds the agent registry at session boot. Inline checks (frontmatter parses, `flutter analyze` still clean post-add) are doable now; functional dispatch is deferred to session 23.

### Neutral

- The auditor's output is advisory. The implementer or the human decides which "should-fix" items to address pre-merge. The "must-fix" tier should be honored except with explicit written justification (logged in TODO or slice doc).

## Rollback

If the auditor proves noisy or low-value:

1. Delete `.claude/agents/flutter-perf-auditor.md`.
2. Remove the bullet from `docs/M2-SLICE-CHECKLIST.md` §Verification.
3. Remove the mention from `CLAUDE.md` §"Verify Your Work".

Total revert: 3-file diff, no codebase impact. The auditor is read-only — even if left enabled in error there is no risk to production code.

If the checklist needs heavy revision (e.g., a category produces > 20% false positives across two reviews), the right move is to edit the agent's Markdown, not to delete the agent. Track changes in the commit message.

## Verification

### Inline checks executed at adoption (Phase 4 commit)

- Frontmatter parses as valid YAML; `name`, `tools`, `model`, `description` extract cleanly via `yaml.safe_load`. ✅
- Tool allowlist verified to exclude `Edit`, `Write`, `MultiEdit` programmatically (read-only contract enforced by allowlist, not just prompt). ✅
- All 3 allowlisted `mcp__dart__*` tools exist in the Dart MCP's published surface (cross-checked against Phase 1's `dart mcp-server --help` capture). ✅
- `flutter analyze --no-pub` clean after the file lands (the agent file lives outside `apps/mobile/`, so it cannot affect Dart analysis — confirmed). ✅

### Deferred to next session (session 23) — captured in `docs/sprints/2026-05-24-m2-ai-harness.md` §Fase 4

Two smoke dispatches gating the gate-de-aceite:

1. **Bad-screen detection:** create a small temp Dart file with intentional violations of §1 (`ListView(children: ...)` with > 5 items), §2 (no `const` on a literal-args widget), §3 (`ref.watch(complexProvider)` when only one field is read). Dispatch the auditor against the file. Verify all 3 land in the punch list with correct severity. Delete the temp file after.
2. **Clean-screen no-false-positives:** dispatch the auditor against `apps/mobile/lib/features/stops/presentation/home_empty_page.dart` (small, static, prototype-faithful screen with no perf concerns). Verify the punch list is empty across must-fix and should-fix (nits acceptable if quoted accurately).

## References

- `docs/sprints/2026-05-24-m2-ai-harness.md` §Fase 4 — task list this ADR codifies.
- ADR-0023 — Dart MCP backing the agent's symbol-lookup tools.
- ADR-0025 — `flutter-test-author` (sibling subagent, same scope pattern).
- ADR-0018 — in-loop hooks. The auditor's §2 cross-references the `analyze-changed-dart.sh` Stop hook output but is itself separate (Stop hook runs every turn; auditor runs on demand at slice close).
- ADR-0024 — Riverpod codegen hook. Explicitly named in the agent's "What you must not do" so generated `.g.dart` files are skipped.
- ADR-0016 — `flutter_map` + OSM tile policy. The §6 check defers to this ADR's cache decision rather than blanket-flagging.
- Inspirations (not copied): `cleydson/flutter-claude-code` perf playbook, `VoltAgent/awesome-claude-code-subagents` Flutter section, official `docs.flutter.dev/perf/best-practices` (training-memory cross-check, not authoritative — checklist is the source of truth).
