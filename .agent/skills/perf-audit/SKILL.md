---
name: perf-audit
description: Use after implementing or modifying any Flutter screen in apps/mobile/lib/ (especially slice-2 Telas Core and slice-3 VRP work with lists, maps, or heavy parsing) and BEFORE opening the slice PR. Produces a categorized punch list (must-fix / should-fix / nit) across the 9 canonical Flutter performance checks. Read-only — never edits code. Mirrors the Claude Code flutter-perf-auditor subagent.
---

# perf-audit

Read-only performance audit of recently modified Flutter UI under `apps/mobile/lib/`. Produces a punch-list categorized by severity. The implementer fixes the issues in a follow-up turn — this skill never edits code.

## When to use this skill

- After finishing a screen and BEFORE running `/verify-slice` or opening a PR.
- When the user says "audit perf" / "perf check" / "perf review" / "is this fast enough".
- Proactively for any slice-2 / slice-3 work that touches lists, maps, image-heavy widgets, or data parsing.

**Do NOT use this skill** for backend, landing, infra, or for code that has not been recently modified — scope is recently changed Flutter UI only.

## Pre-flight

1. Identify the scope:
   ```bash
   git diff --name-only main...HEAD -- 'apps/mobile/lib/**/*.dart'
   ```
   These are the files in scope. Do not audit unchanged files.

2. Read each changed file.

3. For each `*.dart` file in scope, run through the 9-check list below.

## The 9 canonical checks

### 1. `ListView.builder` discipline
- Any list > 10 items must use `ListView.builder` (or `ListView.separated.builder`, `GridView.builder`, etc.) — never `ListView(children: [...])` with a hardcoded list.
- Lazy lists (`builder` constructors) build only visible items.

### 2. Missing `const`
- Every constructor that can be `const` must be `const`.
- `const` widgets are reused across builds — major hot-reload and rebuild savings.
- Look for `Widget build` returning non-`const` literal widgets that have no captured state.

### 3. `ref.watch` granularity (Riverpod)
- `ref.watch(...)` at the top of `build()` rebuilds the whole widget when the watched value changes.
- Prefer `ref.watch(...)` at the deepest leaf that uses the value.
- For derived state, prefer `ref.watch(provider.select((s) => s.field))` to avoid rebuilds on unrelated fields.

### 4. UI-thread heavy work
- `jsonDecode` of large payloads, image decoding from bytes, polyline simplification, or any synchronous CPU-bound work in `build()` or in a `setState` callback.
- Move to `compute(...)` (background isolate) or to a `FutureProvider` / `AsyncNotifier`.

### 5. `RepaintBoundary` placement
- Wrap subtrees that paint independently and frequently (animated maps, list cells with shadows, custom painters) with `RepaintBoundary`.
- Do NOT sprinkle `RepaintBoundary` everywhere — overuse adds GPU memory pressure.

### 6. Tile cache (`flutter_map` / Google Maps)
- Confirm tile caching is configured (`flutter_map` uses `cacheManager`; Google Maps uses platform-level cache automatically).
- Network round-trips per pan/zoom should be near-zero after warm-up.

### 7. List item keys
- `ValueKey` / `ObjectKey` on list children that can reorder or be removed.
- Missing keys cause Flutter to mistakenly reuse state across items (e.g., scroll position, animation state).

### 8. Image decoding
- `Image.network` / `Image.asset` should specify `cacheWidth` and `cacheHeight` when displayed smaller than source resolution.
- For lists of images, prefer `cached_network_image` (if already in `pubspec.yaml`) with explicit dimensions.

### 9. `StatefulWidget` overuse
- `StatefulWidget` only when the widget owns ephemeral local state (animation controllers, focus nodes, scroll controllers).
- For app-level state, prefer Riverpod (`@riverpod` provider + `ConsumerWidget`).

## Report format

```markdown
# Perf audit: <slice name>

**Scope:** <N> files (from `git diff --name-only main...HEAD`)
**Files audited:**
- apps/mobile/lib/features/<x>/...

## Findings

### Must-fix (blocks PR)
- [<file>:<line>] <issue> — <fix in 1 sentence>

### Should-fix (file as follow-up if not addressed this sprint)
- [<file>:<line>] <issue> — <fix in 1 sentence>

### Nit (defer to polish phase)
- [<file>:<line>] <issue> — <fix in 1 sentence>

## Coverage by check

1. ListView.builder discipline   : OK / N issues
2. Missing const                 : OK / N issues
3. ref.watch granularity         : OK / N issues
4. UI-thread heavy work          : OK / N issues
5. RepaintBoundary placement     : OK / N issues
6. Tile cache                    : OK / N/A (no map in scope) / N issues
7. List item keys                : OK / N/A (no list in scope) / N issues
8. Image decoding                : OK / N/A (no image in scope) / N issues
9. StatefulWidget overuse        : OK / N issues
```

## Strict boundaries

- **Read-only.** Do not edit any file under `apps/mobile/`.
- **Recently changed only.** Do not audit files that did not appear in `git diff --name-only main...HEAD`.
- **No benchmarks.** This skill is static review of code — it does not run `flutter run --profile` or capture timeline traces. Suggest those as next steps in the report if hot-path doubt remains.
- **No prescriptive fixes for nits.** Nits are flagged; the implementer decides whether to address them this sprint or defer.
