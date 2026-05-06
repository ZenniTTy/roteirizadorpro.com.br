# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** Active milestone only. Completed items are moved to `## Done` at session end.
> **Last updated:** 2026-05-05

## Current Milestone: M1 — Infra, Landing, Backend Base

**Deadline:** 14 days from kickoff. **Payment:** R$ 2,000 via Workana escrow on approval.

**Approval criteria** (verbatim from accepted proposal):
- Site is live at `roteirizadorpro.com.br`.
- API responds correctly.
- Route calculation works within the promised time (<200ms).
- Client has full access to the server panel.

---

## Sprint 0 — Pre-requisites (blockers + minimal repo scaffolding)

### Blocked on client (must resolve before Sprint 1 starts)

- [ ] **[BLOCKER]** Client provisions DigitalOcean droplet in São Paulo region, Ubuntu 24.04. **Start with $6/month 1GB droplet** (card issue workaround agreed 2026-05-05). Resize to 8GB after M1 escrow release. Account must be in client's name.
- [ ] **[BLOCKER]** Client adds Eduardo's SSH public key to the droplet (Eduardo provides the key).
- [ ] **[BLOCKER]** Client confirms DNS provider for `roteirizadorpro.com.br` and grants DNS edit access (or commits to running DNS changes himself in real time).
- [ ] **[BLOCKER]** Client confirms target GitHub repo for handoff (or accepts current `ZenniTTy/-APP---Entrega-Smart` to transfer at end of M1).
- [ ] **[BLOCKER]** Client provides the contact channels to be displayed on the landing page (WhatsApp number? Email? Form?).
- [ ] **[BLOCKER]** Client provides the product copy for landing (description, benefits, FAQ items) — or approves the draft Eduardo writes.

### Eduardo (no external dependencies)

- [x] `.gitignore` (Node + Flutter + Mac + IDE + secrets).
- [x] `.editorconfig`.
- [x] `README.md` (root).
- [x] `SECURITY.md`.
- [x] `CODE_OF_CONDUCT.md`.
- [x] `.github/pull_request_template.md`.
- [x] `docs/01-PROJECT.md`.
- [x] `docs/02-ARCHITECTURE.md`.
- [x] `docs/04-ROADMAP-M1.md`.
- [x] `docs/04-ROADMAP-M2.md`.
- [x] `docs/06-DISASTER-RECOVERY.md`.
- [x] `docs/decisions/0000-template.md` and ADRs `0001` through `0010`.
- [x] Create empty folders for monorepo structure: `apps/backend/`, `apps/landing/`, `infra/`, `scripts/` (use `.gitkeep`).
- [x] `agents.md` and `docs/FEATURES.md`.
- [ ] Generate Eduardo's project-specific SSH keypair for client to add (or confirm reusing existing key).

---

## Sprint 1 — Server, GraphHopper, Landing (Days 1-7)

### Epic A — Server hardening (DigitalOcean)

**Success criterion:** Eduardo and client can SSH in; firewall blocks all but 22/80/443; fail2ban active; only SSH key auth.

- [ ] First SSH connection as root → create non-root user `roteirizador` with sudo.
- [ ] Disable root login over SSH (`PermitRootLogin no`).
- [ ] Disable password authentication (`PasswordAuthentication no`).
- [ ] Configure `ufw`: allow 22, 80, 443; deny everything else; enable.
- [ ] Install and configure `fail2ban` (default jail for SSH).
- [ ] Enable unattended-upgrades for security patches.
- [ ] Set hostname and timezone (`America/Sao_Paulo`).
- [ ] Install `htop`, `vim`, `git`, `curl`, `wget`, `tree`.
- [ ] Document the server access procedure in `docs/INSTALL.md`.

### Epic B — Container infrastructure

**Success criterion:** Docker + docker-compose installed; PostgreSQL and Redis running and accessible only on localhost.

- [ ] Install Docker Engine (official repo) and Docker Compose plugin.
- [ ] Add `roteirizador` user to `docker` group.
- [ ] Create `/opt/roteirizador/` directory tree (`/opt/roteirizador/{compose,data,backups,logs,certs}`).
- [ ] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`, `backend`, `nginx`.
- [ ] Bind PostgreSQL and Redis to `127.0.0.1` only (never expose externally).
- [ ] Set strong, randomly generated passwords for PostgreSQL (write to `.env`, never commit).
- [ ] Bring up `postgres` and `redis` services. Verify `docker ps` shows them healthy.

### Epic C — Nginx + HTTPS

**Success criterion:** `https://api.roteirizadorpro.com.br/health` returns 200 with valid Let's Encrypt certificate.

- [ ] Install Nginx as Docker container (or system package — decide via ADR-0011 if needed).
- [ ] Create Nginx config: reverse proxy `api.roteirizadorpro.com.br` → `localhost:3000` (backend container).
- [ ] DNS: create `A` record `api.roteirizadorpro.com.br` → droplet IP.
- [ ] Install Certbot, obtain Let's Encrypt cert for `api.roteirizadorpro.com.br`.
- [ ] Configure auto-renew cron (`certbot renew --quiet`).
- [ ] Verify HTTPS works end-to-end with `curl -I https://api.roteirizadorpro.com.br/health`.

### Epic D — GraphHopper

**Success criterion:** Synthetic benchmark of 100 randomized SP-area routes returns p95 < 200ms.

- [ ] Download Geofabrik PBFs: SP, RJ, MG, ES (latest).
- [ ] Merge PBFs using `osmosis` or download a pre-merged Sudeste extract if available.
- [ ] Author `infra/graphhopper/config.yml` with `motorcycle` profile and CH (Contraction Hierarchies) enabled.
- [ ] Configure GraphHopper Docker service in `docker-compose.yml` with persistent volume for the graph cache.
- [ ] First run: import PBFs and build the graph (will take 30–90 minutes; document the duration).
- [ ] Verify GraphHopper responds at `http://localhost:8989/route?point=...&point=...`.
- [ ] **Bind GraphHopper to localhost only** — never expose externally; backend proxies it.
- [ ] Author `infra/graphhopper/benchmark.sh` script: 100 randomized routes, output p50/p95/p99.
- [ ] Run benchmark, document the result in `docs/BENCHMARKS.md`.
- [ ] If p95 ≥ 200ms: tune CH config / increase JVM heap. Re-benchmark.

### Epic E — Landing page (Vercel)

**Success criterion:** `https://roteirizadorpro.com.br` is live, HTTPS valid, contains all required content.

- [ ] Create Eduardo's Vercel account (or reuse existing).
- [ ] Initialize `apps/landing/` as Next.js 14+ project (App Router).
- [ ] Install Tailwind CSS for styling.
- [ ] Author landing sections (per proposal): Hero, Product details, How it works, FAQ, Contact buttons, Footer with privacy policy link (placeholder for M2).
- [ ] Add APK download CTA — placeholder during M1, real link in M2.
- [ ] Original visual identity: pick palette + typography that are clearly NOT Circuit's (record choices in ADR-0010).
- [ ] Connect Vercel to GitHub repo, configure auto-deploy on push to `develop`.
- [ ] DNS: configure `roteirizadorpro.com.br` apex + `www` to point at Vercel (CNAME `cname.vercel-dns.com` or A records per Vercel's instructions).
- [ ] Verify HTTPS auto-provisioned by Vercel.
- [ ] Test on mobile viewport (most users will visit from phones).
- [ ] **Migration plan:** Vercel project transfer to client at end of M1 (document ownership transfer steps in `docs/INSTALL.md`).

---

## Sprint 2 — Backend, Documentation, Handoff (Days 8-14)

### Epic F — Backend skeleton (Fastify + Prisma + TypeBox)

**Success criterion:** Backend deployed on DO server; `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/me` all return correct responses; `/health/*` endpoints green.

- [ ] Initialize `apps/backend/` with `npm init` + TypeScript strict.
- [ ] Install Fastify v5, `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `pino`, `bcrypt`, `dotenv`.
- [ ] Configure `tsconfig.json` with strict mode, path aliases.
- [ ] Initialize Prisma 7 with `@prisma/adapter-pg` driver adapter.
- [ ] Author `prisma/schema.prisma` with `users` and `refresh_tokens` models.
- [ ] Author `prisma.config.ts`.
- [ ] Run first migration on local PostgreSQL; verify generated client output path.
- [ ] Author `src/server.ts` with Fastify instance, plugins, error handlers.
- [ ] Author auth routes:
  - [ ] `POST /auth/register` — validates with TypeBox, hashes password (bcrypt cost 12), creates user.
  - [ ] `POST /auth/login` — verifies password, issues JWT access (15min) + refresh (7d).
  - [ ] `POST /auth/refresh` — exchanges refresh for new access token.
  - [ ] `GET /auth/me` — returns authenticated user payload (requires JWT).
- [ ] Author healthcheck endpoints:
  - [ ] `GET /health` — process is alive.
  - [ ] `GET /health/db` — Postgres reachable.
  - [ ] `GET /health/graphhopper` — GraphHopper container reachable.
- [ ] Author placeholder `POST /routes/optimize` — proxies to local GraphHopper, returns optimized order. (Full feature in M2.)
- [ ] Configure Pino structured logging (JSON to stdout).
- [ ] Configure rate limiting on `/auth/*` (5 attempts / 15min for login, 3/h for register).
- [ ] Author `apps/backend/.env.example` with every variable documented.
- [ ] Build Docker image for backend; add `backend` service to `infra/docker-compose.yml`.
- [ ] Deploy to DO server, verify all endpoints respond via HTTPS through Nginx.

### Epic G — Backup and rollback safety

**Success criterion:** Daily Postgres backup runs and is verified; rollback from snapshot is documented.

- [ ] Author `scripts/backup-postgres.sh` — `pg_dump` daily at 03:00 to `/opt/roteirizador/backups/`.
- [ ] Configure cron for the backup script with a 30-day retention rotation.
- [ ] Verify a backup actually contains data (do a test restore on a throwaway database).
- [ ] **Take a DigitalOcean snapshot** of the droplet before final handoff (rollback baseline).
- [ ] Document the rollback procedure in `docs/06-DISASTER-RECOVERY.md`.

### Epic H — Documentation deliverables

**Success criterion:** A new operator can follow the install manual and reproduce the environment from scratch.

- [ ] Author `docs/INSTALL.md` — full installation walkthrough: DO provisioning steps, SSH setup, Docker install, services bring-up, GraphHopper PBF import, DNS configuration, Vercel deploy, troubleshooting.
- [ ] Author `docs/BENCHMARKS.md` — GraphHopper performance results.
- [ ] Author `docs/SERVER-ACCESS.md` — how the client accesses the DO panel and the server (SSH instructions, partner credentials policy).
- [ ] Document every `.env` variable in `apps/backend/.env.example` with comments.
- [ ] Update `docs/02-ARCHITECTURE.md` with the realized architecture (in case anything diverged from the design).

### Epic I — Final verification (M1 acceptance test)

**Success criterion:** All four approval criteria from the proposal demonstrably pass.

- [ ] **Criterion 1: Site is live.** Visit `https://roteirizadorpro.com.br` from an external network, screenshot, confirm HTTPS green padlock.
- [ ] **Criterion 2: API responds correctly.** `curl https://api.roteirizadorpro.com.br/health` returns 200; `POST /auth/register` + `POST /auth/login` + `GET /auth/me` round-trip works.
- [ ] **Criterion 3: Route calculation within promise.** Run benchmark script against the production GraphHopper, p95 < 200ms documented in `docs/BENCHMARKS.md`.
- [ ] **Criterion 4: Client has full access.** Client logs into DigitalOcean panel, SSHes into droplet, lists running containers. Eduardo observes the session (screenshare or screencap from client), confirms in writing.
- [ ] Record Loom demo video covering the four criteria above (one shot, no edits).
- [ ] Tag the commit: `git tag -a v1.0-m1 -m 'Milestone 1 delivery'`.
- [ ] Push tag.
- [ ] Transfer GitHub repo ownership to client (Settings → Transfer ownership).
- [ ] Notify client in Workana with the Loom link, repo link, and acceptance checklist signed off.

---

## Discovered while working

(New tasks found during execution land here, then get scheduled into a sprint.)

- (none yet)

---

## Backlog (M2 — for reference, not active)

Full M2 plan in `docs/04-ROADMAP-M2.md`.

- Mobile app (Flutter): Login, route list, map, OCR, voice input.
- "Sentido casa" optimization algorithm (TSP with fixed endpoint).
- Efí Bank Pix Split integration (cobrança, webhook, paywall enforcement).
- Active subscriber counter (real-time, WebSocket).
- Share screen (WhatsApp + Copy Link + QR Code).
- Admin panel for partners.
- LGPD-required endpoints (export, delete) and privacy policy publication.

---

## Done

(Items moved here at session end with completion date.)

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten to align with Karpathy's four principles and Anthropic's official Claude Code best practices.
- [x] **2026-05-05** — Repo conventions, contribution guide, LGPD compliance map, session log structure created and committed.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md` authored.
