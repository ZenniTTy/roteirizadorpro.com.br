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

- PBF source: Geofabrik (https://download.geofabrik.de/south-america/brazil/sudeste.html). Use the merged Sudeste extract or download SP+RJ+MG+ES individually and merge with `osmosis`.
- Container: official `graphhopper/graphhopper` Docker image.
- Mount points: PBF files at `/data/pbf/`, graph cache at `/data/graph-cache/`.
- `config.yml` enables `motorcycle` profile with `prepare.ch.weightings: fastest`.
- JVM heap: `-Xmx5g` to keep below total RAM headroom for OS + other containers.
- Bound to `127.0.0.1:8989` only — never exposed to the internet. Backend proxies it internally.
- Healthcheck: `curl http://localhost:8989/health`.
- Benchmark target (M1 acceptance criterion): p95 < 200ms on 100 randomized SP-area routes.

## References

- Validation against Context7: `/graphhopper/graphhopper` (526 snippets, benchmark score 92.7).
- Workana proposal — explicitly required.
