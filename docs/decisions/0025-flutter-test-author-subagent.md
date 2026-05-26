# ADR-0025: `flutter-test-author` subagent + mocktail as the mock library

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0018 (in-loop hooks), ADR-0023 (Dart MCP — the symbol-resolution backbone that makes test authoring trustworthy), ADR-0024 (Riverpod codegen hook — generated `.g.dart` consumed by the tests this subagent writes), ADR-0015 (M2 plan + libraries)
- **Sprint:** M2-AI Harness — Phase 3 (see `docs/sprints/2026-05-24-m2-ai-harness.md`)

## Context

Slice 2 of M2 ("Telas Core") is producing 15 screens, ~30 providers, and a growing repository / service surface. Test discipline so far has been informal: tests get written, but in burst, after the production code, and sometimes by the same agent that just authored the production code. The latter pattern is the textbook TDD failure mode — the test asserts the implementation's existing behavior instead of the spec's intended behavior, so bugs in implicit defaults pass silently.

The M2-AI sprint's diagnosis (research pass 2026-05-24) identified two complementary plays:

1. **A subagent dedicated to writing the failing test first** (this ADR).
2. **A mock library to make stubbing tractable** (also this ADR — the decision was deferred from the sprint draft until the actual `pubspec.yaml` was inspected).

The Dart MCP (ADR-0023) is the prerequisite: a test-authoring subagent that hallucinates Flutter / Riverpod API surface is worse than no subagent. With the MCP active, the subagent can call `mcp__dart__resolve_workspace_symbol` and `mcp__dart__signature_help` to confirm every imported symbol exists with the signature it expects, against the locally installed pub-cache.

## Decision 1 — Mock library

Inspection of `apps/mobile/pubspec.yaml` and the existing `test/` tree showed:

- No `mocktail`, no `mockito`, no `@GenerateMocks`.
- All 53 existing tests use **manual fakes** under `test/<feature>/_helpers/` (`FakeStopsRepository`, `FakeAppPermissions`, `FakeExternalNav`).
- The pattern works well for stable dependencies but becomes painful when a single test needs to vary the dependency's behavior across cases (`verify(...).called(2)`, `when(...).thenAnswer(...)`).

`pub_dev_search` for `mocktail` (run 2026-05-24 via Dart MCP `pub_dev_search`):

- `mocktail 1.0.5` — pub points 160/160, 1229 likes, 2.5M downloads, publisher `felangel.dev` (Felix Angelov, author of `bloc`, `bloc_test`, `hydrated_bloc`). MIT.
- No codegen, no `build_runner` integration, no source generation — Dart 3 sound null safety + extension methods + records do all the work that `@GenerateMocks` used to need.

**Decision:** adopt **`mocktail ^1.0.5`** as the dev_dep. Manual fakes remain the default — `mocktail` is reached for only when stubbing dynamism makes a fake unwieldy.

### Why not `mockito`

- Adds a fourth `build_runner` consumer (`mockito_codegen`) on top of `riverpod_generator` (already present), the ADR-0024 hook's autonomous trigger, and any future code generators. Each one slows the cold-start `build_runner build` and increases the chance of one generator's bug blocking the others.
- `mockito`'s `@GenerateMocks` requires editing the test file with an annotation, running codegen, then importing the generated `.mocks.dart` — three steps where mocktail needs one (`class MockX extends Mock implements X {}`).
- The fake-first culture in this repo doesn't need mockito's broader API surface.

### Why not "no library, manual fakes only"

Two real test categories already in the slice-2 backlog need dynamism that fakes do not provide cleanly:

- Voice/OCR services where the test wants to assert "the controller called `start()` exactly once after the user tapped the mic", not "the controller eventually produced state X".
- Repository tests where one test in a group needs the repo to succeed and the next needs it to throw a specific exception.

mocktail's `verify(() => svc.start()).called(1)` and `when(() => repo.fetch()).thenThrow(...)` are the right tool for those cases.

## Decision 2 — `flutter-test-author` subagent

Add `.claude/agents/flutter-test-author.md`, a project-scoped subagent (versioned with the repo, available to any contributor) that:

1. Reads the spec / acceptance criteria.
2. Authors the failing test FIRST, using existing fakes from `test/<feature>/_helpers/` when they fit.
3. Creates the minimum `lib/` stub needed for the test to compile (`throw UnimplementedError()` bodies only).
4. Runs `flutter test` against the new test file and confirms it fails on the assertion (not on import).
5. Hands off to the implementer / main agent with a summary (test path, failing assertion, required API surface).
6. **Refuses** to write the production logic itself — that bias is the whole problem TDD solves.

### Tool allowlist

```
Read, Grep, Glob, Edit, Write, Bash,
mcp__dart__resolve_workspace_symbol,
mcp__dart__hover,
mcp__dart__signature_help,
mcp__dart__analyze_files,
mcp__dart__run_tests
```

Note: `Bash` is unrestricted (no glob restriction like `Bash(flutter test:*)`) because the same agent needs `flutter pub get`, `dart format`, `chmod`, etc. during smoke setup. The discipline lives in the prompt body, not in shell glob restrictions — those bite faster than they protect.

### Model

`sonnet`. Test authoring needs careful spec reading + signature lookup, not exotic reasoning. Same model as `adr-guardian` and `prototype-fidelity-checker` for budget consistency.

## Options Considered

### Option A — No subagent; rely on the main agent + CLAUDE.md "Verify Your Work"

- Pros: zero new harness pieces.
- Cons: the main agent has already context-loaded the production-code mental model by the time tests are due, biasing every assertion. Verified empirically in slice-2 microsprints — same agent wrote stop, then wrote the test that asserted exactly what stop produces, missing several edge cases the spec implied but didn't enforce.
- **Rejected.**

### Option B — Subagent that writes test + implementation together

The "feature-dev" pattern from one of the inspirations.

- Pros: faster perceived throughput.
- Cons: same bias problem as Option A, just at the subagent level. The point of separating concerns is to break the bias loop.
- **Rejected.**

### Option C (this ADR) — Subagent dedicated to writing the failing test, then handing off

- Pros: enforces the red gate mechanically. Different agent instance → fresh context, no production-code bias. The handoff summary forces the implementer to read the test's intent before writing code.
- Cons: extra dispatch cost per feature; the agent could itself hallucinate test setups if the MCP isn't trusted — mitigated by allowlisting the MCP tools and forbidding training-memory fallback in the prompt body.
- **Accepted.**

### Option D — Use one of the off-the-shelf community subagents (cleydson/flutter-claude-code, affaan-m/flutter-dart-code-review)

- Pros: existing prior art.
- Cons: those target Flutter generally, not this stack (Riverpod 3 codegen, ADR-0013 DTO mirror, ADR-0020 grammar, project's `_helpers/` fake convention). Adapting them to fit would have been most of the work anyway, and would carry forward decisions that don't match this repo. Used as **inspiration**, not source.
- **Rejected as source; adopted as inspiration.**

## Consequences

### Positive

- **Red-gate discipline becomes mechanical.** The implementer cannot bypass the failing test, because the implementer's turn opens with the test already failing.
- **Spec-grounded assertions.** The test author reads the spec, not the (yet-to-be-written) production code. The assertions express intent, not implementation.
- **Existing fakes get reused.** The agent's prompt explicitly tells it to check `test/<feature>/_helpers/` before forking — this codifies the DRY win the slice-2 work already proved (3 cross-cutting fake consolidations, −106 LOC).
- **MCP-grounded imports.** Every `flutter_test`, Riverpod, `flutter_map`, `mocktail` symbol the agent imports is validated against the local pub-cache via Dart MCP — no training-memory hallucination.
- **Mocktail unlocks two real test categories** (call counting + per-test exception throwing) without dragging in `build_runner`.

### Negative

- **Two-phase development.** A feature now requires at minimum two passes (test author → implementer). The throughput cost is real but the rework cost saved is larger — verified by slice-2 microsprints where tests-after-the-fact missed spec details that surfaced later in device smoke.
- **Mocktail tempts overuse.** Easy to reach for `MockRepo()` when a 5-line fake would have been clearer. Mitigation: the subagent's prompt lists the (narrow) criteria for reaching for mocktail.
- **Smoke-test validation requires session reload.** Subagent definitions, like MCP servers (ADR-0023), are loaded into Claude Code's agent registry at session start. The session that authors the subagent file cannot dispatch to it inline. Phase 3's verification is therefore split: inline checks now (frontmatter parses, mocktail resolves, full test suite still green), functional dispatch deferred to next session.

### Neutral

- The subagent operates only on `apps/mobile/`. Backend tests stay with Fastify's existing pattern; the slice-2 ADRs don't address backend test discipline (separate concern).

## Rollback

If the subagent proves more friction than help:

1. Delete `.claude/agents/flutter-test-author.md`.
2. Remove `mocktail: ^1.0.5` from `apps/mobile/pubspec.yaml` dev_dependencies.
3. Run `flutter pub get` to update the lockfile.
4. Revert any CLAUDE.md mention.

If only mocktail proves unwanted but the subagent stays, narrow step 2 to just the dep and edit the subagent's "When to reach for mocktail" section to "do not; manual fakes only".

Total revert: 4-file diff. The subagent is read-only as far as production code is concerned (it cannot bypass its own discipline), so even if left enabled in error there is no codebase damage.

## Verification

### Inline checks executed at adoption (Phase 3 commit)

- Frontmatter parses as valid YAML; `name`, `tools`, `model`, `description` all present. ✅
- All allowlisted `mcp__dart__*` tools exist in the Dart MCP's published surface area (cross-checked against the `dart mcp-server --help` output captured in Phase 1). ✅
- `apps/mobile/pubspec.yaml` resolves with `mocktail 1.0.5` (lockfile updated). ✅
- One-off sanity test (`MockFoo` + `when().thenAnswer()` + `verify().called(1)`) compiles, runs, passes. ✅
- Full test suite: `flutter test` 164/164 green; `flutter analyze --no-pub` clean. ✅ (no regression from the pubspec addition)

### Deferred to next session (session 23) — captured in `docs/sprints/2026-05-24-m2-ai-harness.md` §Fase 3

- Dispatch `flutter-test-author` against a trivial spec (a CounterController in `core/state/`); confirm it produces a red test, creates a `throw UnimplementedError()` stub, and outputs the handoff summary without writing the production logic.
- Dispatch a second time with an explicit "also implement the logic for me" prompt; confirm refusal with the rationale from the prompt body.

## References

- `docs/sprints/2026-05-24-m2-ai-harness.md` §Fase 3 — task list this ADR codifies.
- ADR-0023 — Dart MCP that grounds the agent's symbol lookups.
- ADR-0024 — Riverpod codegen hook that ensures `.g.dart` is fresh when the agent's tests import a `@riverpod` provider.
- ADR-0015 — locked stack (Flutter + Riverpod 3 codegen) the agent targets.
- ADR-0013 + ADR-0020 — DTO mirror convention the agent must respect when authoring tests that traverse the HTTP boundary.
- pub.dev `mocktail` 1.0.5 (publisher `felangel.dev`).
- Felix Angelov's `bloc_test` library — informed the "manual fake first, mock library for dynamism" boundary.
- Inspirations (not copied): `cleydson/flutter-claude-code` (Flutter-general subagent pack), `affaan-m/flutter-dart-code-review` (Flutter code review skill).
