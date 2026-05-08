# ADR-0008: Self-Host GraphHopper for Routing

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo, client

## Context

The accepted Workana proposal explicitly identifies GraphHopper self-hosted as the "pulo do gato" — the strategic differentiator. The economic argument: per-route consultation cost must be effectively zero to make BRL 25.90/month subscriptions profitable after gateway fees. Google Maps Distance Matrix API and similar paid services would erode the margin on every request.

The product targets the Sudeste region of Brazil initially: SP, RJ, MG, ES.

## Options Considered

### Option A — GraphHopper self-hosted

- Pros: Zero per-request cost; fast (sub-200ms with CH); supports motorcycle profile (matches motoboy reality better than `car`); Apache 2.0 licensed; OpenStreetMap data.
- Cons: Requires server resources (RAM-heavy: 4-6GB JVM heap for Sudeste); ~30-90min initial graph build; need to refresh PBFs periodically; we operate the engine.

### Option B — Google Maps Directions / Distance Matrix API

- Pros: Best-in-class data; zero ops.
- Cons: Cost-prohibitive at scale (thousands of requests per active user per month).

### Option C — Mapbox

- Pros: Cleaner API than Google.
- Cons: Same cost concern as Google.

### Option D — OSRM (OpenStreetMap Routing Machine)

- Pros: Also self-hosted, also fast.
- Cons: Lower-level config; less mature motorcycle profile support; smaller community than GraphHopper.

### Option E — Valhalla

- Pros: Modern, dynamic-friendly.
- Cons: Heavier resource requirements; slower for static routes than GraphHopper with CH.

## Decision

**GraphHopper self-hosted** on the DigitalOcean droplet, with `motorcycle` profile and Contraction Hierarchies enabled.

## Consequences

- Positive: Zero per-request marginal cost; full control; fast.
- Negative: Operational responsibility (ours to keep running); RAM-heavy (~50% of the 8GB droplet); PBF refreshes are manual.
- Neutral: Geographic expansion = new PBFs + graph rebuild downtime. Plan for ~1 hour rebuild per major region added.

## Implementation Notes

> See **Amendment (2026-05-08)** below — the implementation specifics were
> revised once Phase 2 actually built the graph. The original assumptions
> (official Docker image, SP-state PBF on Geofabrik, single 8 GB droplet
> sizing, pre-8.x config syntax) did not survive contact with reality.

- PBF source: Geofabrik (https://download.geofabrik.de/south-america/brazil/sudeste.html). Use the merged Sudeste extract or download SP+RJ+MG+ES individually and merge with `osmosis`.
- Container: official `graphhopper/graphhopper` Docker image.
- Mount points: PBF files at `/data/pbf/`, graph cache at `/data/graph-cache/`.
- `config.yml` enables `motorcycle` profile with `prepare.ch.weightings: fastest`.
- JVM heap: `-Xmx5g` to keep below total RAM headroom for OS + other containers.
- Bound to `127.0.0.1:8989` only — never exposed to the internet. Backend proxies it internally.
- Healthcheck: `curl http://localhost:8989/health`.
- Benchmark target (M1 acceptance criterion): p95 < 200ms on 100 randomized SP-area routes.

## Amendment — 2026-05-08 (Phase 2 reality check)

When Phase 2 actually wired GraphHopper end-to-end, four assumptions in the original Implementation Notes proved wrong. These supersede the bullets above; the original is preserved for the audit trail.

### Docker image

There is **no `graphhopper/graphhopper` image on Docker Hub** — the URL returns 404. The de-facto canonical image is `israelhikingmap/graphhopper:latest`: a community-maintained build that pulls GraphHopper master nightly via GitHub Actions, JRE 21, healthcheck and `bind_host` rewrites already baked in. We use it.

### PBF source

There is **no `sao-paulo-latest.osm.pbf` published anywhere** (Geofabrik, BBBike pre-extracted, OSM-FR all confirmed). The reproducible path is to download `sudeste-latest.osm.pbf` (~803 MB) once and clip the desired bbox locally with `osmium-tool` — committed at `infra/graphhopper/extract-sp.sh`. `osmosis` is no longer the recommended tool; `osmium-tool` is the modern OSM CLI.

### M1 reduced configuration (1 GB droplet)

The original `-Xmx5g` assumed an 8 GB droplet. **M1 ships on a 1 GB droplet** (escrow constraint — droplet resize happens post-M1 acceptance). For M1:

- Bbox: capital São Paulo only (`-46.83,-23.78,-46.40,-23.36`) — ~115 MB extracted PBF.
- Heap: `-Xmx800m -Xms400m` (set via `JAVA_OPTS` in `infra/docker-compose.yml`).
- Build location: **build the graph cache on the developer laptop**, then rsync `infra/graphhopper/data/graph-cache/` to the droplet during Phase 3 deploy. Building on a 1 GB droplet would OOM during CH preparation. This is the GraphHopper-recommended pattern for low-memory deployments.

Post-M1 path: resize droplet to 8 GB → swap PBF to full Sudeste → bump heap → rebuild graph in place.

### Config syntax (GraphHopper 8.x+)

The legacy `vehicle: motorcycle` syntax is gone. Modern config uses `custom_model_files: [motorcycle.json]` (the JSON file ships inside the GraphHopper jar at `core/src/main/resources/com/graphhopper/custom_models/`). Two parameters that were optional pre-8.x are now required and surface as startup `IllegalArgumentException` if omitted:

- `graph.encoded_values` — must explicitly list every encoded value the custom_model uses (for motorcycle: `car_access, track_type, road_class, road_environment, curvature, car_average_speed, surface, max_speed, ferry_speed`).
- `import.osm.ignored_highways` — for motor profiles set to `footway, cycleway, path, pedestrian, steps, bridleway`.

Compose invocation overrides `entrypoint: ["./graphhopper.sh", "-c", "/data/config.yml"]` (the image's default ENTRYPOINT bakes its own config-example.yml, so we override at the entrypoint level rather than appending to args).

## References

- Validation against Context7: `/graphhopper/graphhopper` (526 snippets, benchmark score 92.7).
- Workana proposal — explicitly required.
- Phase 2 session log: `docs/sessions/2026-05-08-06-graphhopper-sp.md`.
