# 08 — Roadmap (M1)

**Single focus: deliver M1.** M2 scope is deferred until after M1 acceptance and a fresh conversation with the client.

| Field | Value |
|---|---|
| Milestone | M1 |
| Value | BRL 2,000 (Workana escrow — already deposited by client) |
| Accepted on | 2026-04-26 |
| Deadline | 2026-05-26 (30 days from acceptance) |
| Server | DigitalOcean 1GB droplet, **client's account**, Eduardo has admin access |
| GraphHopper coverage | São Paulo state only (1GB workaround). Sudeste (SP+RJ+MG+ES) reimport is post-M1. |

## Acceptance criteria (verbatim from Workana)

To release the M1 escrow payment, all four must be true:

1. **The site is live** at `https://roteirizadorpro.com.br` with HTTPS.
2. **The API responds correctly** at `https://api.roteirizadorpro.com.br`.
3. **Route calculation works within the promised time** (p95 < 200ms).
4. **The client has full access to the server panel.**

Every M1 task ladders up to one of these four.

## Plan

### Phase 1 — Foundations

**Goal:** Each app skeleton is initialized and runs locally.

- Initialize `apps/mobile/` with `flutter create` (auth-only scope).
- Initialize `apps/backend/` with Node 20 + Fastify v5 + TypeBox + Prisma 7.
- Initialize `apps/landing/` with Next.js (App Router) + Tailwind.
- Author `infra/docker-compose.yml` for local dev: postgres, redis, graphhopper.
- Verify `docker compose up` brings up all three services healthy.

### Phase 2 — M1 features

**Goal:** Each contracted M1 feature works locally end-to-end.

- **Backend auth** (`POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`).
- **Backend healthchecks** (`GET /health`, `/health/db`, `/health/graphhopper`).
- **Backend placeholder route** (`POST /routes/optimize`) — proxies GraphHopper for the p95 benchmark.
- **Flutter auth screens** (Screens 01 Login + 02 Register from `prototipo/` — match 1:1).
- **Landing page sections** — Hero, product details, how it works, FAQ, contact buttons, APK download CTA placeholder, footer.
- **GraphHopper SP graph** — download SP-only PBF, motorcycle profile, CH enabled, JVM heap `-Xmx800m`, bound to `127.0.0.1:8989`.
- **Benchmark** — `infra/graphhopper/benchmark.sh` runs 100 randomized SP routes, p95 < 200ms confirmed and recorded in `docs/BENCHMARKS.md`.

### Phase 3 — M1 deploy

**Goal:** Production deployment is live, both endpoints respond from external network with HTTPS.

- Server hardening on DO 1GB (non-root user, ufw, fail2ban, unattended-upgrades, timezone).
- Docker Engine + Compose installed, project deployed to `/opt/roteirizador/`.
- Nginx reverse proxy configured for `api.roteirizadorpro.com.br`.
- Let's Encrypt cert provisioned, auto-renew configured.
- Vercel domain config: `roteirizadorpro.com.br` apex + `www`.
- Postgres backup cron at 03:00, 30-day rotation (`scripts/backup-postgres.sh`).
- Droplet snapshot taken (rollback baseline).

### Phase 4 — M1 acceptance

**Goal:** Client can sign off on all four acceptance criteria.

- Smoke test all 4 acceptance criteria from external network. Screenshots/curl logs.
- Author `docs/INSTALL.md` — full reproducible install walkthrough.
- Run benchmark on production, p95 < 200ms confirmed in `docs/BENCHMARKS.md`.
- Record demo video covering all four criteria (Loom).
- Tag `git tag -a v1.0-m1`, push tag.
- Notify client in Workana with demo link.

## Deliverables checklist (M1)

- [ ] DO 1GB droplet hardened, Eduardo has admin access on client's DO account.
- [ ] Docker, PostgreSQL, Redis running locally on the droplet, services bound to 127.0.0.1.
- [ ] Nginx reverse proxy with HTTPS for `api.roteirizadorpro.com.br`.
- [ ] GraphHopper SP graph built, p95 < 200ms confirmed.
- [ ] Landing live at `https://roteirizadorpro.com.br`, all sections present.
- [ ] Backend deployed: `/auth/*`, `/health/*`, `/routes/optimize`.
- [ ] Daily Postgres backup configured and verified.
- [ ] Droplet snapshot taken.
- [ ] `docs/INSTALL.md` complete.
- [ ] `docs/BENCHMARKS.md` with measured p95.
- [ ] Demo video recorded.
- [ ] All 4 acceptance criteria signed off by client in Workana.

## Risks (M1)

| Risk | Likelihood | Mitigation |
|---|---|---|
| GraphHopper p95 ≥ 200ms on 1GB droplet | Low | SP-only is the reduced configuration; tune CH config and JVM heap if needed before escalating. |
| DNS propagation delays | Medium | Use TTL 300s. Configure DNS early. |
| Vercel free tier limits | Very low | Static landing, well within limits. |
| Let's Encrypt rate-limit during testing | Low | Use `--staging` flag during testing. |
| Demo video reveals critical flaw at the end | Medium | Run a dry run 2 days before the deadline, not on the day of the demo. |

## Out of scope for M1

Anything in `docs/04-FEATURES.md` not flagged as M1 status — including OCR, voice, route optimization (real algorithm), payment, paywall, real-time subscriber counter, share/QR, admin panel, APK build, sentido casa, LGPD endpoints. These belong to M2 and are not planned in this document.

## After M1 acceptance — next steps

Once M1 escrow is released, reconfirm M2 scope and approach with the client. The original Workana M2 contract covers: APK build, Pix Split via Efí, paywall, sentido casa optimization, admin panel, all remaining 17 prototype screens. M2 planning happens in a fresh spec after that conversation.
