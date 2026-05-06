# 04 — Roadmap M1

**Milestone 1 — Infrastructure, Landing, Backend Base**

| Field | Value |
|---|---|
| Value | BRL 2,000 (Workana escrow) |
| Duration | 14 days |
| Start | After Sprint 0 blockers cleared (client provisions DO, shares SSH access, confirms domain DNS, confirms contact channels) |
| Deliverable | Production server with backend API + GraphHopper, public landing page, full code in client's GitHub, install manual, demo video |

## Scope (Verbatim From The Accepted Workana Proposal)

> What will be delivered in this phase (M1):
>
> 1. **Infrastructure and Server:** DigitalOcean (8GB RAM) Ubuntu 24.04, with firewall and full security under your titularity.
> 2. **Routing Engine:** GraphHopper installed with maps for the entire Sudeste (SP, RJ, MG, ES), guaranteeing fast responses (under 200ms).
> 3. **Digital Presence:** Landing page published on `roteirizadorpro.com.br` with HTTPS, product details, FAQ and contact buttons.
> 4. **System Base:** Backend API ready with user registration and login (JWT authentication).
> 5. **Code and Documentation:** Full source code delivered to your GitHub, install manual, and a demo video.

## Approval Criteria (Verbatim)

> To release the payment, **the site must be live**, **the API must respond correctly**, **route calculation must work within the promised time**, and **you (the client) must have full access to the server panel**.

These four criteria gate the escrow release. Every M1 task ladders up to satisfying them.

## Sprint Structure

### Sprint 0 — Pre-requisites (before Day 1)

External blockers must be resolved by the client before development starts. While the client clears these, Eduardo finalizes repo scaffolding (foundation files, ADRs, documentation skeleton, monorepo folder layout).

**Client deliverables:**

- DigitalOcean account active (client already has the account). Droplet provisioned in São Paulo region, Ubuntu 24.04. **See droplet size note below.**
- Eduardo's SSH public key added to the droplet.
- DNS access for `roteirizadorpro.com.br` (or a commitment to apply DNS changes in real time).
- Confirmation of the GitHub repo for handoff.
- Contact information to display on the landing page (WhatsApp, email, or form preference).
- Product copy approved (or accepted blind, with Eduardo writing a draft).

> **Droplet size note (updated 2026-05-05):** The client has a temporary card issue and cannot provision the $48/month 8GB droplet this week. Agreed path for M1 homologation: start with a **$6/month 1GB droplet**. GraphHopper is configured with **São Paulo state only** (fits in ~800MB JVM heap). After the client's card is resolved, a DigitalOcean resize to 8GB takes under 2 minutes with zero data loss — then the remaining Sudeste states (RJ, MG, ES) are imported. All four M1 approval criteria are fully demonstrable on the 1GB droplet with SP coverage. The 8GB droplet remains the final production target.

**Eduardo deliverables:**

- All foundation files, ADRs, and skeleton docs in the repo.
- Monorepo folder structure under `apps/`.
- Project SSH key generated and shared with client.

### Sprint 1 — Server, GraphHopper, Landing (Days 1–7)

**Day 1 — Server hardening**

- First SSH session as root, create `roteirizador` non-root user with sudo.
- Disable root SSH login. Disable password auth.
- Configure `ufw` (allow 22, 80, 443; deny rest). Enable.
- Install and configure `fail2ban`.
- Set hostname, timezone (`America/Sao_Paulo`).
- Enable unattended-upgrades.

**Day 2 — Container infrastructure**

- Install Docker Engine + Compose plugin (official repo).
- Create `/opt/roteirizador/{compose,data,backups,logs,certs}`.
- Author initial `infra/docker-compose.yml` with `postgres`, `redis`, `graphhopper`, `backend`, `nginx` services.
- Bring up Postgres and Redis. Bind to `127.0.0.1` only.
- Generate strong DB credentials, write to server `.env` (chmod 600).

**Day 3 — Nginx + HTTPS**

- Configure Nginx reverse proxy `api.roteirizadorpro.com.br` → backend.
- Create `A` record `api.roteirizadorpro.com.br` → droplet IP.
- Install Certbot, obtain Let's Encrypt cert.
- Configure auto-renew cron.
- Verify HTTPS round-trip with curl.

**Days 4–5 — GraphHopper**

- Download SP PBF only from Geofabrik (`sao-paulo-latest.osm.pbf`) — fits in 1GB droplet heap.
- Configure GraphHopper Docker container with motorcycle profile + CH. JVM heap: `-Xmx800m`.
- First-run graph import (15–30 minutes for SP only).
- Bind GraphHopper to `127.0.0.1:8989`.
- Author benchmark script: 100 randomized SP-area routes, p50/p95/p99.
- Run benchmark, document in `docs/BENCHMARKS.md`. p95 < 200ms required.
- Tune if needed (CH config, JVM heap).
- Note: after resize to 8GB (post-M1), reimport full Sudeste (SP+RJ+MG+ES) via `infra/graphhopper/reimport-sudeste.sh`.

**Days 6–7 — Landing page**

- Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind.
- Author sections: Hero, product details, how it works, FAQ, contact buttons.
- APK CTA placeholder (real link in M2).
- Define original visual identity (palette, typography) — record in ADR-0010.
- Connect Vercel to GitHub repo, configure auto-deploy on push to `develop`.
- Configure DNS: `roteirizadorpro.com.br` apex + `www` → Vercel.
- Verify HTTPS auto-provisioned by Vercel.
- Mobile viewport test.

### Sprint 2 — Backend, Documentation, Handoff (Days 8–14)

**Days 8–10 — Backend skeleton**

- Initialize `apps/backend/`: Node 20, TypeScript strict, Fastify v5, TypeBox.
- Install plugins: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `pino`, `bcrypt`, `dotenv`.
- Set up Prisma 7 with `@prisma/adapter-pg`. Author `prisma/schema.prisma` (users + refresh_tokens). Author `prisma.config.ts`.
- Run first migration locally.
- Author auth routes (`/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me`).
- Author healthchecks (`/health`, `/health/db`, `/health/graphhopper`).
- Author placeholder `POST /routes/optimize`.
- Configure Pino logging, rate limits.
- Author `apps/backend/.env.example`.

**Days 11–12 — Deployment and backups**

- Build backend Docker image. Add to `docker-compose.yml`. Deploy to DO.
- Verify all endpoints respond via HTTPS through Nginx.
- Author `scripts/backup-postgres.sh`. Configure cron at 03:00, 30-day rotation.
- Verify a backup actually contains data (test restore on throwaway DB).
- Take DigitalOcean droplet snapshot (rollback baseline).

**Day 13 — Documentation**

- Author `docs/INSTALL.md` — complete reproducible install walkthrough.
- Author `docs/SERVER-ACCESS.md` — how the client accesses DO panel and the server.
- Update `docs/02-ARCHITECTURE.md` with realized architecture (any divergence from design).
- Comment every variable in `.env.example`.

**Day 14 — Final verification and handoff**

- **Criterion 1**: visit `https://roteirizadorpro.com.br` from external network. Screenshot. Confirm HTTPS green padlock.
- **Criterion 2**: `curl https://api.roteirizadorpro.com.br/health` returns 200. Auth round-trip works.
- **Criterion 3**: production benchmark, p95 < 200ms, document in `docs/BENCHMARKS.md`.
- **Criterion 4**: client logs into DO panel, SSHes into droplet, lists running containers. Confirmed in writing.
- Record Loom demo video covering all four criteria.
- Tag commit: `git tag -a v1.0-m1`. Push tag.
- Transfer GitHub repo ownership to client.
- Notify client in Workana with Loom link, repo link, acceptance checklist.

## Deliverables Checklist (Final)

- [ ] DigitalOcean droplet hardened, accessible by client and Eduardo.
- [ ] Docker, PostgreSQL, Redis running, locked to localhost.
- [ ] Nginx reverse proxy with HTTPS for `api.roteirizadorpro.com.br`.
- [ ] GraphHopper container running, SP graph built (1GB droplet), p95 < 200ms confirmed.
- [ ] Landing page live at `https://roteirizadorpro.com.br` with HTTPS, all required sections.
- [ ] Backend API deployed: `/auth/*`, `/health/*`, placeholder `/routes/optimize`.
- [ ] Daily Postgres backup configured and verified.
- [ ] Droplet snapshot taken (rollback baseline).
- [ ] `docs/INSTALL.md` complete and tested.
- [ ] `docs/BENCHMARKS.md` with measured numbers.
- [ ] `docs/SERVER-ACCESS.md` for client onboarding.
- [ ] Loom video covering all four approval criteria.
- [ ] GitHub repo ownership transferred to client.
- [ ] Client signed off in Workana on all four approval criteria.

## Risks Tracked During M1

| Risk | Likelihood | Mitigation |
|---|---|---|
| Client delays provisioning DigitalOcean droplet | Low | Client already has the DO account. Temporary card issue resolved by starting with $6/month 1GB droplet — client can provision immediately |
| Client delays resize from 1GB to 8GB after M1 | Medium | M1 escrow is released on 1GB. Resize is a follow-up action before M2 starts; document as explicit pre-condition in M2 Sprint 0 |
| GraphHopper p95 ≥ 200ms after tuning | Low | M1 runs SP-only on 1GB droplet — this is already the reduced-coverage configuration. If p95 still fails, tune CH settings and JVM heap before escalating |
| DNS propagation delays | Medium | Use low TTL (300s) during M1; warn client to set DNS early |
| Vercel free tier limits hit | Very low | Static landing page; well within limits |
| Let's Encrypt rate-limit during testing | Low | Use `--staging` flag during testing, switch to production once verified |
| SSH access misconfigured, locking out client | Low | Confirm client SSH access works BEFORE locking down root login |
| Loom video reveals a critical flaw at the end | Medium | Run a full dry-run on day 13, not day 14 |

## Out of Scope For M1 (Explicit Non-Goals)

These items are explicitly **deferred to M2** to keep M1 focused:

- Android APK build.
- "Sentido casa" route optimization algorithm.
- Pix Split integration with Efí Bank.
- Webhook handler for payment confirmations.
- Subscription paywall.
- Active subscriber counter (real-time WebSocket).
- Share screen with WhatsApp + Copy Link + QR Code.
- OCR feature for label scanning.
- Voice input for addresses.
- Admin panel for partners.
- LGPD endpoints (data export, deletion).
- Privacy policy page on landing.
- CI/CD pipeline (linter + tests on PR).

If the client requests any of these during M1, the response is: "That's planned for M2; let's complete M1 first."
