# INSTALL — Roteirizador Pro M1 Production Deploy

End-to-end runbook for taking the project from a fresh DigitalOcean droplet to a running M1 acceptance configuration. Targets the four Workana acceptance criteria:

1. Site live at `https://roteirizadorpro.com.br` (Vercel; covered in §6).
2. API responds at `https://api.roteirizadorpro.com.br` (this droplet; §1–§5).
3. Route p95 < 200 ms (§4 + benchmark).
4. Client has DO panel access (§7).

> **Prerequisites on your laptop**
> - Local stack running (`infra/docker-compose.yml --profile routing up -d`) — proves the stack works before deploying.
> - GraphHopper graph-cache built locally (see [`infra/README.md`](../infra/README.md)).
> - SSH keypair (`ssh-keygen -t ed25519 -f ~/.ssh/roteirizador_pro`) added to the DO account.
> - Dropletʼs IPv4 captured into [`docs/07-INFRA.md`](./07-INFRA.md).

---

## §1. Server bootstrap

The first SSH is as `root`. Drop in [`scripts/server-bootstrap.sh`](../scripts/server-bootstrap.sh) and run it with your public key as the argument. It is idempotent, so re-running for fixes is safe.

```bash
# From laptop:
scp scripts/server-bootstrap.sh root@<DROPLET_IP>:/tmp/
ssh root@<DROPLET_IP>

# On droplet, as root:
chmod +x /tmp/server-bootstrap.sh
/tmp/server-bootstrap.sh "$(cat ~/.ssh/authorized_keys 2>/dev/null || echo 'ssh-ed25519 AAAA... eduardo@ianelli.tech')"
```

The script:
- Creates the `roteirizador` sudo user with your SSH key authorized.
- Hardens SSH (no root login, no password auth) — only takes effect on the next reload, so close this root session and re-open as `roteirizador`.
- UFW: deny incoming except 22/80/443.
- fail2ban sshd jail (1h ban after 3 failures in 10m).
- Hostname `roteirizador-pro`, timezone `America/Sao_Paulo`, unattended-upgrades.
- Docker Engine (official Ubuntu repo) + Compose plugin.
- Lays down `/opt/roteirizador/{compose,data,backups,logs,certs}`.

Re-login as `roteirizador` — never as root again:

```bash
ssh roteirizador@<DROPLET_IP>
```

## §2. Repo + compose file + .env

```bash
# As roteirizador on the droplet:
git clone https://github.com/ZenniTTy/-APP---Entrega-Smart.git /opt/roteirizador/compose/repo
cp /opt/roteirizador/compose/repo/infra/docker-compose.yml /opt/roteirizador/compose/

# Create .env (chmod 600). Template + values: docs/07-INFRA.md "Production .env template".
nano /opt/roteirizador/compose/.env
chmod 600 /opt/roteirizador/compose/.env
```

Generate the JWT keypair on your laptop with [`scripts/generate-jwt-keys.sh`](../scripts/generate-jwt-keys.sh) and copy the two PEM lines into `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` in the .env.

## §3. Ship the GraphHopper graph cache

From your laptop (the graph was built here in Phase 2):

```bash
./scripts/rsync-graph-cache.sh roteirizador@<DROPLET_IP>
```

Pushes ~43 MB of `graph-cache/` and ~115 MB of the source PBF to `/opt/roteirizador/data/graphhopper/`. The droplet will load the prepared cache as-is — no rebuild (rebuild on 1 GB would OOM, see ADR-0008 amendment).

## §4. Bring up the stack

```bash
# As roteirizador on the droplet:
cd /opt/roteirizador/compose
docker compose --profile routing up -d
docker compose ps                       # all three services healthy
```

Verify each:

```bash
curl http://127.0.0.1:5432  &&: pg_isready  # backend will probe via /health/db
curl http://127.0.0.1:8989/health           # GraphHopper → "OK"
```

Run the benchmark — this is the **production p95 number** that satisfies acceptance criterion #3:

```bash
/opt/roteirizador/compose/repo/infra/graphhopper/benchmark.sh
```

Record the result in [`docs/BENCHMARKS.md`](./BENCHMARKS.md) under the production droplet section. Threshold: **p95 < 200 ms**. If over, levers in order of cost: drop `curvature` from `graph.encoded_values`, bump `prepare.min_network_size`, shrink the bbox.

## §5. Backend (Fastify) as a systemd unit

Per ADR-0011: install Bun, runtime stays Node 20.

```bash
# As roteirizador on the droplet:
curl -fsSL https://bun.sh/install | bash
sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun

# Node 20 LTS via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install backend deps + run Prisma migrations
cd /opt/roteirizador/compose/repo/apps/backend
bun install --frozen-lockfile
bunx prisma migrate deploy            # apply migrations to production DB
bunx prisma generate                  # regenerate the client for this host

# Install the systemd unit
sudo cp /opt/roteirizador/compose/repo/infra/systemd/roteirizador-backend.service \
  /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now roteirizador-backend
sudo systemctl status roteirizador-backend     # active (running)

# Smoke test loopback
curl http://127.0.0.1:3000/health              # 200 OK
curl http://127.0.0.1:3000/health/db           # 200 OK
curl http://127.0.0.1:3000/health/graphhopper  # 200 OK (round-trip)
```

Logs: `sudo journalctl -u roteirizador-backend -f`.

## §6. Nginx reverse proxy + TLS (Certbot)

```bash
# As roteirizador on the droplet:
sudo apt-get install -y nginx certbot python3-certbot-nginx

# Drop in the site config
sudo cp /opt/roteirizador/compose/repo/infra/nginx/api.roteirizadorpro.com.br.conf \
  /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/api.roteirizadorpro.com.br.conf \
  /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Validate + reload
sudo nginx -t
sudo systemctl reload nginx

# Issue cert + auto-edit the config (HTTPS + redirect)
sudo certbot --nginx -d api.roteirizadorpro.com.br \
  --agree-tos --email eduardo@ianelli.tech --redirect

# Auto-renew sanity check
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

> The DNS A record for `api.roteirizadorpro.com.br` must already point at the droplet IP before running Certbot (LetʼEncrypt http-01 challenge resolves the A record). Set TTL 300 in advance so propagation is fast. See [`docs/07-INFRA.md`](./07-INFRA.md) §DNS.

External smoke test (from your laptop, not the droplet):

```bash
curl -i https://api.roteirizadorpro.com.br/health                      # 200 OK
curl -i https://api.roteirizadorpro.com.br/health/db                   # 200 OK
curl -i https://api.roteirizadorpro.com.br/health/graphhopper          # 200 OK
```

That satisfies acceptance criterion #2.

## §7. Postgres backup cron

```bash
# As roteirizador on the droplet:
crontab -e
```

Append:

```
0 3 * * * /opt/roteirizador/compose/repo/scripts/backup-postgres.sh >> /opt/roteirizador/logs/backup-postgres.log 2>&1
```

That runs daily at 03:00 (`America/Sao_Paulo` since hostnamectl was set in §1), dumps the DB, gzips it, drops anything older than 30 days. Verify by triggering once manually:

```bash
/opt/roteirizador/compose/repo/scripts/backup-postgres.sh
ls -lh /opt/roteirizador/backups/
```

Restore drill (recommended — at least once before the demo):

```bash
docker exec -i roteirizador-postgres psql -U roteirizador -d roteirizador < /tmp/dump.sql
```

## §8. Vercel landing (acceptance criterion #1)

The landing is deployed by Vercel from the `apps/landing/` directory. See [`docs/07-INFRA.md`](./07-INFRA.md) §Vercel for the full configuration; the short version:

1. Vercel project root directory = `apps/landing`.
2. Branch `develop` auto-deploys to a staging URL.
3. Branch `main` auto-deploys to production.
4. Domain config: `roteirizadorpro.com.br` apex + `www`.
5. DNS: `A @ → 76.76.21.21` (Vercelʼs apex IP), `CNAME www → cname.vercel-dns.com`.

External smoke test:

```bash
curl -I https://roteirizadorpro.com.br      # 200 OK, served by Vercel
curl -I https://www.roteirizadorpro.com.br  # 200 OK
```

## §9. DigitalOcean snapshot (rollback baseline)

```
Panel → Droplets → roteirizador-pro → Snapshots → Take snapshot
```

Name it `m1-acceptance-baseline-YYYY-MM-DD`. This is the rollback point if anything later goes wrong.

## §10. Acceptance verification

Run the full external smoke test and capture screenshots / curl logs for the demo video:

```bash
# Criterion 1 — site live
curl -I https://roteirizadorpro.com.br

# Criterion 2 — API responds
curl    https://api.roteirizadorpro.com.br/health
curl    https://api.roteirizadorpro.com.br/health/db
curl    https://api.roteirizadorpro.com.br/health/graphhopper

# Auth round-trip (creates a user; clean up afterwards)
EMAIL="acceptance-$(date +%s)@test.local"
curl -X POST https://api.roteirizadorpro.com.br/auth/register \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"abcdefgh\",\"name\":\"Acceptance\"}"
curl -X POST https://api.roteirizadorpro.com.br/auth/login \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"abcdefgh\"}"

# Criterion 3 — p95 < 200 ms
BENCH_HOST=https://api.roteirizadorpro.com.br /opt/roteirizador/compose/repo/infra/graphhopper/benchmark.sh
# Note: benchmark.sh hits /route directly, which goes through Nginx but
# bypasses the backend. For the criterion we measure GraphHopper end-to-end
# via the loopback bench on the droplet — record both.

# Criterion 4 — DO panel access (manual check by the client)
```

Tag the release:

```bash
cd /path/to/repo  # on laptop
git tag -a v1.0-m1 -m "M1 acceptance"
git push origin v1.0-m1
```

Notify the client in Workana with a Loom video covering all four criteria.

---

## Quick reference — directory layout on the droplet

```
/opt/roteirizador/
├── compose/
│   ├── docker-compose.yml      ← copied from repo, lives next to .env
│   ├── .env                    ← chmod 600, never in git
│   └── repo/                   ← git clone of the repo (read-only operationally)
│       └── apps/backend/       ← bun install + tsx happens here
├── data/
│   ├── postgres/               ← unused (named volume)
│   ├── redis/                  ← unused (named volume)
│   └── graphhopper/
│       ├── pbf/                ← rsync'd from laptop
│       └── graph-cache/        ← rsync'd from laptop
├── backups/                    ← pg_dump cron output
├── logs/                       ← journald complements this; pg_dump logs land here
└── certs/                      ← Let's Encrypt for the API domain (Certbot). Stripe needs no cert (API key + webhook secret only per ADR-0030).
```

## Quick reference — services on the droplet

| Service | Started by | How to inspect |
|---|---|---|
| `postgres` | docker compose | `docker logs roteirizador-postgres -f` |
| `redis` | docker compose | `docker logs roteirizador-redis -f` |
| `graphhopper` | docker compose (profile `routing`) | `docker logs roteirizador-graphhopper -f` |
| `roteirizador-backend` (Fastify) | systemd | `sudo journalctl -u roteirizador-backend -f` |
| `nginx` | systemd | `sudo journalctl -u nginx -f` |
| `fail2ban` | systemd | `sudo fail2ban-client status sshd` |
| `cron` (backups) | systemd | `tail -f /opt/roteirizador/logs/backup-postgres.log` |

## Quick reference — common operations

```bash
# Tail backend logs
sudo journalctl -u roteirizador-backend -f

# Restart backend after a deploy (git pull + bun install + tsc)
cd /opt/roteirizador/compose/repo
git pull origin main
cd apps/backend && bun install --frozen-lockfile
sudo systemctl restart roteirizador-backend

# Restart only one Docker service
docker compose -f /opt/roteirizador/compose/docker-compose.yml restart graphhopper

# Manual backup
/opt/roteirizador/compose/repo/scripts/backup-postgres.sh

# Manual restore
gunzip -c /opt/roteirizador/backups/roteirizador-2026-MM-DDT....sql.gz \
  | docker exec -i roteirizador-postgres psql -U roteirizador -d roteirizador

# Renew TLS now (Certbot's timer renews automatically)
sudo certbot renew

# fail2ban — list banned IPs
sudo fail2ban-client status sshd
```
