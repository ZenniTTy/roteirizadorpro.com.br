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

Brings up `postgres` and `redis`. GraphHopper is **not** started — it requires a PBF and a config file (Phase 2 work, see [docs/08-ROADMAP.md](../docs/08-ROADMAP.md) Phase 2).

## Routing profile (Phase 2)

GraphHopper requires three things in `infra/graphhopper/data/`:

1. `sao-paulo-latest.osm.pbf` (or `sudeste-latest.osm.pbf` post-M1) downloaded from [Geofabrik](https://download.geofabrik.de/south-america/brazil/sudeste.html).
2. `config.yml` enabling the motorcycle profile and contraction hierarchies.
3. The bind path matches the `--input` argument in `docker-compose.yml`.

Once those exist:

```bash
docker compose -f infra/docker-compose.yml --profile routing up -d
```

The first start performs the graph build (~30–90 minutes for SP, longer for full Sudeste) — the healthcheck has a 2-minute `start_period` to accommodate that, but expect repeated unhealthy reports until the graph is loaded. Subsequent starts reuse `graphhopper-cache` and come up in seconds.

## Credentials

Local dev: hard-coded `roteirizador` / `roteirizador` (loopback-bound, no remote exposure).

Production: replace with strong values via `/opt/roteirizador/compose/.env` (see [docs/07-INFRA.md](../docs/07-INFRA.md)).

## Volumes

- `postgres-data` — Docker named volume.
- `redis-data` — Docker named volume.
- `graphhopper-cache` — Docker named volume for the prepared graph (regenerated on PBF refresh).

The host bind `./graphhopper/data` exists so PBFs and `config.yml` can be edited without entering the container.
