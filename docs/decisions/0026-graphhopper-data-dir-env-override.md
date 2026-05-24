# ADR-0026: Externalize GraphHopper data directory via `GH_DATA_DIR` env override

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo
- **Supersedes:** none
- **Related ADRs:** ADR-0008 (GraphHopper self-hosted routing — the original infra decision that this amends), ADR-0017 deferred TODO note in `infra/docker-compose.yml` about pinning the GraphHopper image
- **Sprint:** Filed during M2-AI Harness — Phase 3 to close an `adr-guardian` BLOCKING finding from commit `bff1b6c` (other session, GraphHopper data relocate)

## Context

Commit `bff1b6c` (`chore(infra): support relocating graphhopper data outside the repo`, authored 2026-05-24 in a different session) introduced two behavioral changes in `infra/`:

1. `infra/graphhopper/extract-sp.sh` now resolves `PBF_DIR` via `${GH_DATA_DIR:-$DIR/data}/pbf` instead of the previous hardcoded `$DIR/data/pbf`. If `GH_DATA_DIR` is unset, behavior matches the prior version (`$DIR/data` is the in-repo path); if set, the script reads/writes PBFs from the externalized location.
2. `infra/docker-compose.yml` got an inline `TODO(ADR)` comment block above the `image: israelhikingmap/graphhopper:latest` line describing the unresolved pinning gap (tried `:8.0@sha256` but the repo's `config.yml` uses `car_access`, a GH 9+ encoded value).

The motivating problem: GraphHopper's prepared graph-cache (~43 MB) plus the source PBFs (~919 MB) were sitting inside the repo tree. Both directories were already gitignored, so this was not git leakage — it was filesystem hygiene and a cleaner repo↔runtime boundary. The session-21 author moved the data to a host-only sidecar at `../roteirizadorpro-infra-data/` and wired the script + a separate `docker-compose.override.yml` (not versioned) to point at the new path. The base `docker-compose.yml` in this repo remains the single source of truth for production (the droplet uses it standalone, no override).

The session-21 commit body and the session log (`docs/sessions/2026-05-24-21-graphhopper-data-relocate-off-repo.md`) cover the rationale in depth. What was missing was an ADR — required by CLAUDE.md "Any change requires a new ADR" for any non-comment edit under `infra/**`. The Phase 3 `adr-guardian` sweep caught the gap. This ADR closes it retroactively.

## Decision

**Accept the `GH_DATA_DIR` env override** as the canonical mechanism for relocating GraphHopper data outside the repo on a per-host basis. The script `infra/graphhopper/extract-sp.sh` reads `GH_DATA_DIR`; when unset, it falls back to `$DIR/data` (the historic in-repo path). The `docker-compose.yml` remains untouched in its data-volume mapping — relocation is achieved by a host-only `docker-compose.override.yml` placed alongside the data sidecar, **not** versioned in this repo.

### Why an env var and not a config file change

- Production (DigitalOcean droplet, set up in session 8) provisioned the data inside the repo path; switching to a sidecar would require a migration. Defaulting `GH_DATA_DIR` to the in-repo path preserves prod and CI behavior unchanged.
- Local dev where disk hygiene matters more (Eduardo's laptop) opts in by exporting `GH_DATA_DIR` once in the shell or by using the sidecar's wrapper `up.sh`.
- Future bump: if the droplet ever migrates to a sidecar layout, set `GH_DATA_DIR` in the systemd unit's `Environment=` and re-run `extract-sp.sh`. No code change.

### Why the inline `TODO(ADR)` on the `:latest` tag stays as-is

The image-pinning problem (`:latest` is currently `12.0-SNAPSHOT`; pinning to `:8.0@sha256` failed because the repo's `config.yml` uses `car_access`, a GH 9+ encoded value) is a separate concern. It needs an **ADR-0008 amendment** that re-validates the full config compatibility against a specific pinned version. That work is sized for slice-3 entry (when VRP integration tests touch the routing surface), not this ADR. The TODO comment in `docker-compose.yml` carries the context forward; do not interpret silence as resolution.

## Consequences

### Positive

- **Repo working tree is ~1 GB lighter** when GH_DATA_DIR is used. Faster `git status`, `git clean`, IDE file watchers; fewer accidental commits of gitignored data.
- **Backwards-compatible default.** Production and CI keep working without any change.
- **Cleaner boundary.** "What's the canonical config?" → repo. "Where does the data live at runtime?" → host-specific, controlled by env. Symmetric with `.env` discipline (declared shape in `.env.example`, real values elsewhere).
- **Adoptable per environment.** Each dev opts in or out; production decides separately. No flag-day migration.

### Negative

- **Surface area for env-mismatch bugs.** A dev who exports `GH_DATA_DIR` once and forgets they did so could end up with two diverged graph-caches. Mitigation: the sidecar's `README.md` (host-only) documents the boot procedure; running `extract-sp.sh` always shows which directory it writes to in stdout.
- **The override compose file is not versioned.** A new contributor cloning the repo gets the in-repo default and won't know about the sidecar pattern unless they read this ADR or the session-21 log. Acceptable — the in-repo default works fully on its own; the sidecar is an optimization.
- **`TODO(ADR)` debt is real.** The `:latest` image pin gap remains open. ADR-0008 amendment at slice-3 entry is the canonical fix; this ADR does not block on it.

### Neutral

- The two-file Docker Compose merge semantics (base + override, override path is relative to the base) is straight from the official Docker docs. No surprises expected at runtime.

## Rollback

If the externalization causes more friction than it removes:

1. Revert `infra/graphhopper/extract-sp.sh` to the hardcoded `PBF_DIR="$DIR/data/pbf"`.
2. Delete the host-only sidecar (`rm -rf ../roteirizadorpro-infra-data/`).
3. Update this ADR's status to `Superseded by <date>` and explain.

Production is unaffected by either keep or revert because `GH_DATA_DIR` was always optional.

## Verification

### Already executed in session 21 (per `docs/sessions/2026-05-24-21-graphhopper-data-relocate-off-repo.md`)

- `extract-sp.sh` with `GH_DATA_DIR` unset → uses `$DIR/data/pbf` (parity with prior). ✅
- `extract-sp.sh` with `GH_DATA_DIR=../roteirizadorpro-infra-data/graphhopper` → writes to the sidecar. ✅
- Container healthy in ~13s on cache reuse.
- `benchmark.sh` N=100 → `p50=15.0ms p95=46.9ms p99=61.0ms max=299.5ms`, 0 errors → M2 acceptance criterion (p95 < 200 ms) met with ~4.3× headroom. ✅

### Inline checks at this ADR's commit (Phase 3 closure)

- `docker-compose.yml` `image: israelhikingmap/graphhopper:latest` line unchanged (only surrounding comments added).
- `extract-sp.sh` diff matches: `-PBF_DIR="$DIR/data/pbf"` → `+PBF_DIR="${GH_DATA_DIR:-$DIR/data}/pbf"`.
- `adr-guardian` re-run after this ADR ships should report the GH change as covered.

## References

- `docs/sessions/2026-05-24-21-graphhopper-data-relocate-off-repo.md` — the canonical session log with the full migration walkthrough, benchmarks, and the sidecar bootstrap procedure.
- Commit `bff1b6c` (`chore(infra): support relocating graphhopper data outside the repo`).
- ADR-0008 (GraphHopper self-hosted routing) — original infra decision being augmented (not superseded).
- Docker Compose override docs — used to validate the relative-path merge semantics.
- `infra/graphhopper/extract-sp.sh` — the canonical script that the env override lives in.
