# Benchmarks

Routing latency measurements against the GraphHopper instance powering Roteirizador Pro.

The contracted M1 acceptance criterion (#3) is:

> **p95 < 200ms** measured against the production droplet on 100 randomized routes inside the operating bbox.

This file tracks every benchmark run we treat as evidence — local + production. Local runs are sanity checks; the production run on the droplet is the one that gates escrow release in Phase 4.

## How we measure

`infra/graphhopper/benchmark.sh` runs 100 single-shot `GET /route?point=...&point=...&profile=motorcycle` requests, sequentially, no warmup. Both endpoints are random points inside the capital São Paulo bbox `-46.83,-23.78,-46.40,-23.36`; GraphHopper snaps each to the nearest road. Failed requests (e.g. `PointNotFound` when both samples land in water mid-reservoir) are counted but excluded from the latency stats. Wall-clock latency comes from `curl -w '%{time_total}'`. `bash + awk` computes percentiles from the sorted times.

Override via env: `BENCH_N=NN`, `BENCH_HOST=...`, `BENCH_PROFILE=...`.

## Runs

### 2026-05-08 — local (developer laptop)

| Field | Value |
|---|---|
| Run | local sanity check |
| Hardware | MacBook Pro Intel i5 1038NG7 @ 2 GHz (4 cores), 16 GB RAM |
| OS | macOS 25.3.0 (Darwin) |
| Docker | Docker Desktop, JVM `-Xmx800m -Xms400m` (matches droplet target) |
| GraphHopper | 12.0 (built 2026-05-08), `israelhikingmap/graphhopper:latest` |
| Profile | `motorcycle` (custom_model_files motorcycle.json), CH enabled |
| Coverage | capital São Paulo (PBF: 115 MB after osmium clip from Sudeste) |
| Concurrency | sequential, no warmup |
| Sample | n=100, errors=1 (random sample landed mid-reservoir → `PointNotFound`, excluded from stats) |

```
min   = 0.0095s
p50   = 0.0178s
mean  = 0.0260s
p95   = 0.0580s
p99   = 0.0766s
max   = 0.2867s
```

**Result:** p95 = **58.0 ms**, ~3.4× under the 200 ms threshold. 99/100 requests resolved; the one failure was a random point that landed inside the Guarapiranga reservoir with no road within snap distance — counted but excluded from latency stats per the script's documented behavior.

The `max` of 287 ms is one outlier, likely a cold JIT path on the first long cross-city route; the p99 of 77 ms is the better signal of typical worst-case latency.

**Caveat — this is not the criterion-#3 measurement.** The contracted bench has to run on the production droplet (Ubuntu 24.04, 1 vCPU shared, 1 GB RAM) under the same JVM constraints. The droplet is CPU-shared and slower than the Mac per request; expected slowdown 2–3×. Even at 3× the local p95 (~193 ms) we'd still be within budget, but the droplet number is the only one that releases escrow.

### 2026-05-DD — production droplet (Phase 4)

> _To be filled once the droplet is provisioned in Phase 3 and the graph cache is rsync'd from the laptop. Same script, same N, same bbox. If p95 ≥ 200 ms we tune `prepare.min_network_size`, drop the `curvature` encoded value, or revisit the bbox._
