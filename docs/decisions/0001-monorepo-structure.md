# ADR-0001: Adopt Monorepo Structure

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

The project ships an Android app, a backend API, a landing page, and (in M2) an admin panel. These artifacts share types (DTOs, route schemas), evolve together, and are owned by a single developer plus AI agents. Coordinating four separate Git repos creates friction at every change that crosses a boundary.

## Options Considered

### Option A — Monorepo (single repo, multiple apps under `apps/`)

- Pros: One PR can touch backend + landing; shared types / schemas easy; simpler onboarding; one CI config.
- Cons: Larger repo; need conventions to keep apps independent.

### Option B — Polyrepo (one repo per app)

- Pros: Cleaner per-app isolation; each repo can have its own owner.
- Cons: Cross-cutting changes require coordinated PRs; shared types must be a separately published package; quadruples ownership transfer work at handoff.

## Decision

Use a **monorepo**. Apps live under `apps/{backend,landing,mobile,admin}`. Shared code (if any) lives under `packages/` and is created only when an actual sharing need appears (no speculative packages).

## Consequences

- Positive: Single ownership transfer at end of M1; one CLAUDE.md governs everything; easier for AI agents.
- Negative: Need `.gitignore` rules robust enough for both Node and Flutter ecosystems.
- Neutral: No build-tool monorepo orchestrator (Turborepo, Nx) in V1 — added only if it earns its keep.

## Implementation Notes

- Folder structure documented in `docs/03-CONVENTIONS.md`.
- Each app has its own `package.json` / `pubspec.yaml` and own `.env.example`.

## References

- `docs/03-CONVENTIONS.md` (Directory Layout section)
