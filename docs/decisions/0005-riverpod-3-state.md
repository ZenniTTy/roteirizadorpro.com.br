# ADR-0005: Use Riverpod 3 for Flutter State Management

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

Flutter offers many state management approaches. The mobile app needs to manage auth state, route data, real-time subscription status (via WebSocket), and async API calls. Single dev plus AI agents — DX matters more than absolute conformance to one paradigm.

## Options Considered

### Option A — Riverpod 3

- Pros: Compile-time safety (no runtime "provider not found" errors); `@riverpod` codegen unifies the API around classes/notifiers; AsyncNotifier and Notifier replace older Future/State providers; testable without mock framework; not tied to BuildContext.
- Cons: Codegen step (handled by `build_runner`); v3 is recent (released 2025) — some tutorials still target v2.

### Option B — Bloc

- Pros: Mature, opinionated, well-documented.
- Cons: More boilerplate; events + states pattern is verbose for simple state; learning curve higher.

### Option C — Provider (the original)

- Pros: Simple, official.
- Cons: BuildContext-tied; no compile-time safety; legacy by 2026 standards.

### Option D — GetX

- Pros: Minimal boilerplate.
- Cons: Mixes routing, DI, and state in ways many find anti-patterny; community sentiment has shifted away.

## Decision

Use **Riverpod 3** with `@riverpod` code generation (`riverpod_generator` + `riverpod_annotation`).

## Consequences

- Positive: Type-safe state graph; `Notifier`/`AsyncNotifier` API is concise; excellent AI-tooling friendliness (the codegen patterns are deterministic, easy for agents to write).
- Negative: Need `build_runner` watch during development; occasional codegen issues require rebuild.
- Neutral: We commit `*.g.dart` files? No — generated files are `.gitignore`d, regenerated on each build.

## Implementation Notes

- Use class-based `Notifier` and `AsyncNotifier` (the new v3 pattern), not the old function-based providers.
- `riverpod_generator` for boilerplate elimination.
- `flutter pub run build_runner watch --delete-conflicting-outputs` during dev.
- All providers live under `apps/mobile/lib/state/`.

## References

- Validation against Context7: `/rrousselgit/riverpod` (v3.0.2 confirmed at time of decision).
- `docs/02-ARCHITECTURE.md` (Mobile section).
