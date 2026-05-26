# Session 2026-05-08-06 — graphhopper-sp

## Metadata

- **Date**: 2026-05-08 (America/Sao_Paulo)
- **Sequence**: 06
- **Agent**: Claude Code (Opus 4.7, 1M ctx)
- **Human**: Eduardo
- **Topic**: GraphHopper SP graph + benchmark (M1 Phase 2 — closes the technical-risk track for acceptance criterion #3)
- **Duration**: ~1h45m
- **Related ADRs**: ADR-0008 (GraphHopper) — amended in this session
- **Related TODO items**: Phase 2 — GraphHopper SP graph, GraphHopper config, GraphHopper graph import, Benchmark script, Local benchmark run

## Goal of the Session

Stand up GraphHopper locally with a São Paulo graph and the motorcycle profile, then run the contracted p95 < 200ms benchmark to know whether the M1 acceptance criterion #3 is realistically achievable on the 1 GB droplet target.

## What Was Done

### Research first (per CLAUDE.md "Context7 mandatory")

Four assumptions in the original Phase 2 TODO + ADR-0008 were investigated and three turned out to be wrong:

- **Image:** `graphhopper/graphhopper` on Docker Hub returns 404. The de-facto canonical image is `israelhikingmap/graphhopper:latest` — community-maintained, nightly built from GraphHopper master via GitHub Actions, JRE 21, healthcheck baked in. Confirmed via the IsraelHikingMap GitHub Dockerfile (multi-stage Maven build + `eclipse-temurin:21.0.1_12-jre`, ENTRYPOINT `["./graphhopper.sh", "-c", "config-example.yml"]`, `RUN sed -i .../bind_host` to allow external connections).
- **PBF:** Geofabrik does not publish a state-level `sao-paulo-latest.osm.pbf`; only `sudeste-latest.osm.pbf` (~803 MB) is available. Confirmed across Geofabrik, BBBike pre-extracted mirror, and OSM-FR. Modern path: clip locally with `osmium-tool` (`osmosis` is no longer recommended).
- **Config syntax:** GraphHopper 8.x removed the legacy `vehicle: motorcycle` syntax; the modern equivalent is `custom_model_files: [motorcycle.json]` against the bundled JSON in the GraphHopper jar (`core/src/main/resources/com/graphhopper/custom_models/`). Two parameters that were optional pre-8.x are now required and surface as startup `IllegalArgumentException` if omitted: `graph.encoded_values` (full list per profile) and `import.osm.ignored_highways`.
- **Memory:** Building Sudeste on a 1 GB droplet would OOM; even capital SP is a stretch under `-Xmx800m`. Recommended pattern: build the graph cache on a developer laptop, rsync `graph-cache/` to the droplet so production never has to rebuild.

Aligned all four with Eduardo via AskUserQuestion before touching code (PBF source = osmium clip, bbox = capital SP, build location = local-then-ship, ADR strategy = amend 0008).

### Implementation

- **`infra/graphhopper/extract-sp.sh`** — idempotent script: downloads `sudeste-latest.osm.pbf` (~803 MB) from Geofabrik to `infra/graphhopper/data/pbf/` if absent, then `osmium extract --bbox -46.83,-23.78,-46.40,-23.36 --strategy smart` produces `sao-paulo-capital.osm.pbf` (~115 MB). Skips re-download / re-extract if outputs are newer than inputs. Surfaces missing `osmium` with a `brew install osmium-tool` hint.
- **`infra/graphhopper/data/config.yml`** — motorcycle profile via `custom_model_files: [motorcycle.json]`, CH enabled (`profiles_ch:`), `graph.encoded_values: car_access, track_type, road_class, road_environment, curvature, car_average_speed, surface, max_speed, ferry_speed`, `graph.urban_density.threads: 4`, `import.osm.ignored_highways: footway, cycleway, path, pedestrian, steps, bridleway`, server bound to `0.0.0.0:8989` inside the container (host port still bound to `127.0.0.1`).
- **`infra/docker-compose.yml`** — replaced the broken `command:` (its flags didn't match `graphhopper.sh`'s argv) with `entrypoint: ["./graphhopper.sh", "-c", "/data/config.yml"]`, dropped the named `graphhopper-cache` Docker volume (graph cache now lives on host filesystem at `infra/graphhopper/data/graph-cache/` — gitignored, ready to rsync to the droplet), switched the healthcheck from `wget --spider` to `curl -f` to match the in-image HEALTHCHECK, bumped `start_period` to 180 s.
- **`infra/graphhopper/benchmark.sh`** — pre-generates 100 random capital-SP coordinate pairs in a single awk pass, then loops curl `-w '%{http_code} %{time_total}'` sequentially with no warmup. Excludes non-200s from the latency stats but counts them. Computes p50/p95/p99/min/mean/max via sort + awk. Configurable via `BENCH_N`, `BENCH_HOST`, `BENCH_PROFILE`.
- **`.gitignore`** — added `infra/graphhopper/data/pbf/*.osm.pbf` and `infra/graphhopper/data/graph-cache/`.

### Iterative debugging during graph build

Two `IllegalArgumentException`s surfaced on the first two start attempts; both were "GraphHopper 8.x makes formerly-optional config required" footguns:

1. `Missing 'import.osm.ignored_highways'`. Added the line for motor-only profiles.
2. `Encoded values missing: road_environment`. The motorcycle.json header listed only the eight values I'd encoded; the engine's static analysis of the JSON expression tree pulls `road_environment` too. Added it.

After fix #2 the first build ran to completion: pass1+pass2 OSM read in 27 s (310,697 nodes, 412,806 edges), urban density calculation 9.2 s, location index 0.4 s, CH preparation completed within ~75 s of start. Memory peaked at ~408 MB (well under the `-Xmx800m` budget).

### Verification

- `curl http://127.0.0.1:8989/health` → `OK` (200).
- Manual route: Av. Paulista → Aeroporto de Congonhas → 9.95 km, ~15 min motorcycle ETA. Plausible.
- Benchmark on the laptop (n=100, sequential, no warmup, errors=0):

| metric | value |
|---|---|
| min | 9.5 ms |
| p50 | 18.2 ms |
| mean | 24.0 ms |
| **p95** | **64.2 ms** |
| p99 | 77.0 ms |
| max | 78.8 ms |

p95 = 64.2 ms, ~3.1× under the 200 ms threshold. **Local-only — droplet number in Phase 4 is the one that gates escrow.**

## Decisions Made

1. **Image: `israelhikingmap/graphhopper:latest`.** No alternative exists. Documented in ADR-0008 amendment.
2. **PBF: clip capital SP from `sudeste-latest.osm.pbf` via `osmium-tool`.** Reproducible, scriptable, one-line extraction. `osmosis` (originally referenced in ADR-0008) is no longer the modern OSM CLI.
3. **Bbox: capital São Paulo only (`-46.83,-23.78,-46.40,-23.36`).** Where motoboys actually operate; PBF size ~115 MB; CH preparation memory comfortably fits `-Xmx800m`. Post-M1 droplet resize → re-import full Sudeste.
4. **Build location: developer laptop, rsync `graph-cache/` to droplet during Phase 3.** Building on a 1 GB droplet would OOM during CH preparation. This is the GraphHopper-recommended pattern for low-memory deployments.
5. **`graph-cache/` lives on host filesystem (bind mount), not a named Docker volume.** Required for the rsync-to-droplet pattern; named volumes can't be `tar`'d cleanly without a sidecar container.
6. **Amend ADR-0008 in place rather than create ADR-0014.** The original decision (self-host GraphHopper for routing) is unchanged; only Implementation Notes were wrong. Added an "Amendment — 2026-05-08 (Phase 2 reality check)" section with Docker image / PBF source / M1 reduced configuration / config syntax updates.

## Open Questions Left

- [ ] **Phase 4: re-run benchmark on the droplet.** Local 64 ms × 2-3× droplet slowdown = 128-193 ms. That's at-or-near the 200 ms threshold. If we land over, levers in order of cost: drop `curvature` from `encoded_values` (smallest CH preparation cost), bump `prepare.min_network_size`, shrink the bbox. None of those is needed today.
- [ ] **Backend `/health/graphhopper` integration test.** Backend was not running this session, so we did not exercise the round-trip. Path was already validated in session 04 (returned 503 there because GH was down) — when backend is started against this running GraphHopper it'll return 200. Not blocking.
- [ ] **Document the rsync step in `docs/INSTALL.md`.** Phase 4 deliverable. Not in scope this session.

## Files Changed

**Created:**
- `infra/graphhopper/extract-sp.sh`
- `infra/graphhopper/benchmark.sh`
- `infra/graphhopper/data/config.yml`
- `docs/BENCHMARKS.md`
- `docs/sessions/2026-05-08-06-graphhopper-sp.md`

**Modified:**
- `infra/docker-compose.yml` (entrypoint override, dropped named volume + wget healthcheck, 180s start_period)
- `infra/README.md` (extract+build flow, ship-cache pattern, volumes section)
- `docs/decisions/0008-graphhopper-routing.md` (Implementation Notes superseded by Amendment 2026-05-08)
- `.gitignore` (PBFs + graph-cache)
- `TODO.md` (Phase 2 GH tasks marked done; reworded the PBF item to reflect "no SP-only mirror exists"; added Phase 3 ship-cache item)
- `docs/sessions/0001-INDEX.md` (this session)

## Commits Pushed

```
<hash>  feat(infra): graphhopper sp profile + extract + bench (m1 phase 2)
<hash>  docs(adr): amend 0008 — image, pbf path, m1 reduced configuration, 8.x config
<hash>  docs(sessions): record graphhopper sp shipping
```

## Hand-off Notes for Next Session

- **Branch:** `develop`. Working tree should be clean after the three commits.
- **GraphHopper local:** running on `http://127.0.0.1:8989` (motorcycle profile, capital SP, ~115 MB PBF, ~64 ms p95). To stop: `docker compose -f infra/docker-compose.yml --profile routing stop graphhopper`. To restart: `... up -d graphhopper`. Graph cache persists in `infra/graphhopper/data/graph-cache/` so restarts are instant.
- **Phase 2 status:** all backend + mobile + GraphHopper tracks done. Remaining Phase 2: landing page sections + visual identity — that's the only Phase 2 work left before Phase 3 (deploy).
- **Phase 3 starting point:** the rsync-graph-cache item is the new top of Phase 3 (preceding the SSH bootstrap), since the droplet config will assume the cache is already present.
- **Performance note (still relevant):** the host runs hot when emulator + Docker + IDE are all up. GraphHopper container idles at ~150 MB RAM, ~0% CPU between requests — not a notable load contributor.

## Reference Material Used

- Context7: `/graphhopper/graphhopper` — Docker self-host config, motorcycle profile, CH (consulted 2026-05-08).
- Web: `https://hub.docker.com/r/graphhopper/graphhopper` (404 — confirmed no official image).
- Web: `https://hub.docker.com/r/israelhikingmap/graphhopper` (latest tag, 144 MB, last updated ~11h ago).
- Web: `https://github.com/IsraelHikingMap/graphhopper-docker-image-push/blob/main/Dockerfile` (entrypoint, healthcheck, JAVA_OPTS default).
- Web: `https://download.geofabrik.de/south-america/brazil/sudeste.html` (no SP sub-region).
- Web: BBBike pre-extracted Brazil regions (no SP city extract).
- Web: `https://raw.githubusercontent.com/graphhopper/graphhopper/master/core/src/main/resources/com/graphhopper/custom_models/motorcycle.json` (encoded values needed by the bundled motorcycle.json).
- Forum: GraphHopper memory requirements thread (1 GB Sudeste = OOM).
- Existing project docs: ADR-0008 (pre-amendment), `infra/README.md`, `infra/docker-compose.yml`, sessions 04 + 05.
