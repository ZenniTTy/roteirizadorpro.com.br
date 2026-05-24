# Session: GraphHopper heavy-data relocation off-repo

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 21
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: GraphHopper docker — relocate heavy data
- **Duration**: ~1h30m
- **Related ADRs**: ADR-0008 (referenced; new amendment deferred — see Open Questions)
- **Related TODO items**: new tech debt entry — see TODO.md "GraphHopper image pinning"

## Goal of the Session

Eduardo deleted the GraphHopper container from Docker Desktop and reorganized the host folder layout (parent now `ueslei-workana/` with `app-roteirizadorpro/` as one of several subdirs). Bring the local GraphHopper stack back up following best practices, with all heavy artifacts (PBFs ~919 MB, prepared CH graph cache ~43 MB) physically outside the git repo — only versioned config/scripts inside.

## What Was Done

- Audited the existing infra setup: `app-roteirizadorpro/infra/docker-compose.yml` (postgres + redis + graphhopper, `routing` profile), `infra/graphhopper/{config.yml,extract-sp.sh,benchmark.sh}`, and the in-repo `infra/graphhopper/data/{pbf,graph-cache}` already populated from session 06 (2026-05-08).
- Confirmed `.gitignore` already excludes `infra/graphhopper/data/pbf/*.osm.pbf` + `graph-cache/` — git was never the leakage; the goal was filesystem hygiene + cleaner repo boundary.
- Created host-only sidecar `ueslei-workana/roteirizadorpro-infra-data/` (not versioned). Layout:
  - `docker-compose.override.yml` — re-points the `graphhopper` service volume from the in-repo `./graphhopper/data` to `../../roteirizadorpro-infra-data/graphhopper` (path **relative to the base compose file**, matching Docker Compose merge semantics).
  - `sync-config.sh` — copies the canonical `infra/graphhopper/data/config.yml` from the repo to the runtime `./graphhopper/config.yml` (the override mount means the in-repo file is no longer visible to the container, so a runtime copy is required; we initially tried a symlink but reverted to a plain copy for cross-Docker-engine robustness).
  - `up.sh` — convenience wrapper around `docker compose -f <repo>/infra/docker-compose.yml -f <here>/docker-compose.override.yml --profile routing {up|down|logs|status}`.
  - `README.md` — documents the split local↔prod model and rebuild/extract instructions honoring `GH_DATA_DIR`.
- Moved `pbf/` and `graph-cache/` out of the repo into the new sidecar. Verified `find infra/graphhopper -type f -size +1M` returns empty.
- Updated `infra/graphhopper/extract-sp.sh` to honor `GH_DATA_DIR` env var (default falls back to the in-repo path → preserves CI/production parity since the base compose's relative mount is unchanged).
- Added a `TODO(ADR)` inline comment to `infra/docker-compose.yml` next to `image: israelhikingmap/graphhopper:latest`, documenting the failed pin attempt and the path forward (see Decisions §3).
- Validated with Context7 + WebSearch (Docker best practices, GraphHopper docker tagging, Compose merge path semantics) before each non-trivial change.
- Brought the stack up via `bash up.sh`. Container healthy in ~13s (cache reuse).
- Ran `infra/graphhopper/benchmark.sh` (N=100, motorcycle profile, capital SP bbox, sequential, no warmup). Result: `p50=15.0ms p95=46.9ms p99=61.0ms max=299.5ms`, 0 errors. M2 acceptance criterion (p95 < 200 ms) met with ~4.3× headroom.
- Verified loopback binding (`127.0.0.1`-only) survived the override merge; `restart=unless-stopped` and `JAVA_OPTS=-Xmx800m -Xms400m` confirmed via `docker inspect`.

## Decisions Made

1. **Two-file Compose pattern over single-file env-var indirection.** Picked "base compose unchanged + host-only override" over editing the base compose to read `GH_DATA_DIR`. Rationale: keeps local↔production parity at the base-compose level (the droplet uses the base alone, no override), so no ADR amendment is required for the relocation itself.
2. **Plain `cp` over symlink for runtime config.yml.** Docker Desktop on macOS does resolve symlinks inside bind-mounts host-side, but a regular file is bulletproof across Docker engine upgrades. The `sync-config.sh` wrapper makes the copy explicit and idempotent.
3. **Reverted attempt to pin `israelhikingmap/graphhopper:8.0@sha256:b7178b…`.** Docker best practice is to pin tag + digest; tried it, but the existing `config.yml` declares `car_access` (introduced in GH 9+), and `:8.0` only ships up to v3 encoded values → container crash-looped with `IllegalArgumentException: DefaultEncodedValueFactory cannot find EncodedValue car_access`. Current `:latest` is `12.0-SNAPSHOT` (also not ideal). Correct path requires an ADR-0008 amendment choosing a stable tag (`:9.1` likely) and re-validating the config — deferred to M2 slice 3 (Routing real). Recorded as tech debt with an inline `TODO(ADR)` comment so future readers know `:latest` is intentional-but-temporary.
4. **`extract-sp.sh` honors `GH_DATA_DIR`; default = in-repo.** Keeps the CI/droplet path working without changes (they don't set the env var) while letting local devs target the external dir with `GH_DATA_DIR=… bash extract-sp.sh`.

## Open Questions Left

- [ ] ADR-0008 amendment: choose a stable GraphHopper image tag (likely `:9.1` or whatever shipped GH version supports `car_access`) and update `config.yml` if encoded-value names shifted. Defer to slice 3.
- [ ] Should `roteirizadorpro-infra-data/` be documented in the root `README.md` / `docs/07-INFRA.md` as the recommended local layout? Today it's documented only inside the external dir's own `README.md`.

## Files Changed

**Created** (outside repo — NOT versioned):
- `/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/roteirizadorpro-infra-data/README.md`
- `/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/roteirizadorpro-infra-data/docker-compose.override.yml`
- `/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/roteirizadorpro-infra-data/sync-config.sh`
- `/Users/eduardorodrigues/Documents/Projetos/Clientes/ueslei-workana/roteirizadorpro-infra-data/up.sh`

**Modified** (versioned):
- `infra/docker-compose.yml` (inline TODO comment on the `image:` line)
- `infra/graphhopper/extract-sp.sh` (honors `GH_DATA_DIR`)

**Moved** (out of the repo, no git impact — both were already gitignored):
- `infra/graphhopper/data/pbf/` → `../roteirizadorpro-infra-data/graphhopper/pbf/`
- `infra/graphhopper/data/graph-cache/` → `../roteirizadorpro-infra-data/graphhopper/graph-cache/`

**Deleted** (versioned):
- `CONTINUATION-PROMPT.md` (stale carry-over from `feat/m2-slice-2-telas-core` tip — obsolete branch context, see plans/2026-05-24-ai-harness-upgrade.md which already noted this file as pre-existing-untracked-to-leave-alone)

## Commits Pushed

(Filled in by the commit step at the end of this session.)

## Hand-off Notes for Next Session

- Branch: `feat/m2-ai-harness` (still the M2-AI sprint branch). Eduardo plans to open PR → `develop` next.
- The two `infra/*` modifications and the `CONTINUATION-PROMPT.md` deletion that the M2-AI plan called "pre-existing untracked carry-over, leave alone" are now resolved (committed and deleted respectively, on explicit instruction from Eduardo).
- To bring the stack up after a fresh clone of a sibling dev's machine: the dev needs to **create their own** `roteirizadorpro-infra-data/` sidecar — it is intentionally host-only. The procedure to bootstrap is in that dir's `README.md`, but that README is also host-only, so the bootstrap instructions are NOT discoverable from the repo alone. **Mitigation candidate (deferred):** add a `docs/07-INFRA.md` section "Local-only override pattern" pointing future devs to recreate the sidecar from scratch.
- Tech debt registered in `TODO.md`: GraphHopper image pinning (slice 3).

## Reference Material Used

- WebSearch: "GraphHopper docker production best practices image tag version pinning 2026" (Docker Hub tagging norms, IsraelHikingMap image catalog)
- WebSearch: "docker compose override file best practices absolute paths multiple files 2026" (confirmed paths resolve relative to base compose, not override)
- WebSearch: "site:hub.docker.com israelhikingmap/graphhopper tags" (catalog: 1.0, 3.0, 3.2, 4.0-pre2, 5.0, 7.0, 7.0-pre1, 8.0, 9.1; `:latest` = 12.0-SNAPSHOT)
- Docker Compose docs: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/
- Re-read: `infra/README.md`, `infra/docker-compose.yml`, `infra/graphhopper/{config.yml,extract-sp.sh,benchmark.sh}`, `.gitignore`, `docs/sessions/2026-05-08-06-graphhopper-sp.md`
- Verified container internals with `docker run --rm --entrypoint /bin/sh israelhikingmap/graphhopper@sha256:f87e58…` → confirmed `graphhopper-web-12.0-SNAPSHOT.jar`
