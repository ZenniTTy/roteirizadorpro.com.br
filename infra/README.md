# infra — Local & Production Infrastructure

`docker-compose.yml` runs the backing services for Roteirizador Pro. Same Compose file is used locally (developer's Mac) and on the production droplet (`/opt/roteirizador/compose/`).

## Services

| Service | Port (host) | Profile | Healthcheck |
|---|---|---|---|
| `postgres` | 127.0.0.1:5432 | default | `pg_isready` |
| `redis` | 127.0.0.1:6379 | default | `redis-cli ping` |
| `graphhopper` | 127.0.0.1:8989 | `routing` | `GET /health` |

Every service is bound to `127.0.0.1` only. External traffic reaches the API through Nginx (production) or directly via `npm run dev` (local).

## Default profile (Phase 1)

```bash
docker compose -f infra/docker-compose.yml up -d
```

Brings up `postgres` and `redis`. GraphHopper is **not** started by default — it sits behind the `routing` profile (opt-in) so the daily backend dev loop doesn't pay the JVM startup + graph-load cost.

## Routing profile (Phase 2)

GraphHopper needs a São Paulo capital PBF and the bundled config.

### One-time bootstrap

```bash
brew install osmium-tool                 # OSM CLI for the bbox clip
infra/graphhopper/extract-sp.sh          # downloads sudeste-latest, clips capital SP
```

`extract-sp.sh` is idempotent:
- Downloads `sudeste-latest.osm.pbf` (~803 MB) into `infra/graphhopper/data/pbf/` if absent.
- Extracts the capital bbox `-46.83,-23.78,-46.40,-23.36` → `sao-paulo-capital.osm.pbf` (~115 MB) using `osmium extract --strategy smart`.

PBFs and the graph cache are gitignored (too large to version).

### Bring up GraphHopper

```bash
docker compose -f infra/docker-compose.yml --profile routing up -d graphhopper
docker logs -f roteirizador-graphhopper   # watch the build
```

First start performs the import + Contraction Hierarchies preparation (~3–5 minutes for capital SP on a developer laptop — much shorter than Sudeste-full would be). The healthcheck has `start_period: 180s` to ride this out. Subsequent starts reuse `infra/graphhopper/data/graph-cache/` and come up in seconds.

### Production deploy (Phase 3)

The 1 GB DigitalOcean droplet would OOM during the CH preparation. Build the graph **on the developer laptop**, then rsync the prepared cache to the droplet:

```bash
rsync -avz --delete \
  infra/graphhopper/data/graph-cache/ \
  roteirizador@<droplet>:/opt/roteirizador/compose/graphhopper/data/graph-cache/
```

The droplet then starts the same `docker compose` with the same image and config — it loads the cache, no rebuild. See ADR-0008 amendment for rationale.

### Smoke check

```bash
curl http://127.0.0.1:8989/health         # 200 OK once ready
infra/graphhopper/benchmark.sh            # 100 randomized routes, p50/p95/p99
```

## Credentials

Local dev: hard-coded `roteirizador` / `roteirizador` (loopback-bound, no remote exposure).

Production: replace with strong values via `/opt/roteirizador/compose/.env` (see [docs/07-INFRA.md](../docs/07-INFRA.md)).

## Volumes

- `postgres-data` — Docker named volume.
- `redis-data` — Docker named volume.
- GraphHopper graph + PBF + config live on the host filesystem at `infra/graphhopper/data/` (bind-mounted into the container as `/data`). This is intentional: the prepared `graph-cache/` needs to be rsync-able to the production droplet so the droplet doesn't have to rebuild from PBF (would OOM on 1 GB).
