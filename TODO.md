# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** M1 only. M2 work begins in a fresh planning cycle after M1 acceptance.
> **M1 deadline:** 2026-05-26.
> **Last updated:** 2026-05-08.

## M1 acceptance criteria (verbatim from Workana)

To release escrow, all four must be true:

1. Site live at `https://roteirizadorpro.com.br` with HTTPS.
2. API responds correctly at `https://api.roteirizadorpro.com.br`.
3. Route calculation p95 < 200ms.
4. Client has full access to the server panel.

Detailed plan: `docs/08-ROADMAP.md`.

---

## Phase 1 — Foundations

- [x] Initialize `apps/mobile/` (source files authored 2026-05-08; `flutter create` deferred to first run on a machine with Flutter SDK — see `apps/mobile/README.md`).
- [x] Configure Flutter linter (`flutter_lints`), formatter, analysis options.
- [x] Install Flutter deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `dio`, `flutter_secure_storage`, `go_router` (declared in `pubspec.yaml`; `pub get` runs at first bootstrap).
- [x] Configure `--dart-define API_BASE_URL` and `apps/mobile/.env.example`.
- [x] Initialize `apps/backend/`: Node 20, TypeScript strict, Fastify v5 + TypeBox.
- [x] Initialize `apps/backend/` deps: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `@fastify/type-provider-typebox`, `pino`, `bcrypt`, `dotenv`.
- [x] Initialize Prisma 7 + `@prisma/adapter-pg` with `prisma.config.ts`.
- [x] Author `apps/backend/.env.example`.
- [x] Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind.
- [x] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`. Bind to 127.0.0.1. (GraphHopper sits behind the `routing` profile — opt-in until the SP PBF lands in Phase 2.)
- [x] `docker compose up` brings up postgres + redis healthy locally.

## Phase 2 — M1 features

- [ ] **Backend auth**: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`. JWT RS256, 15min access + 7d refresh, refresh rotation.
- [ ] **Backend healthchecks**: `GET /health`, `/health/db`, `/health/graphhopper`.
- [ ] **Backend `POST /routes/optimize`** placeholder — proxies GraphHopper for benchmark only.
- [ ] **Backend logging**: Pino JSON to stdout. Rate limits on `/auth/*`.
- [ ] **Flutter Login screen** (Screen 01 from `prototipo/`) — match prototype 1:1.
- [ ] **Flutter Register screen** (Screen 02 from `prototipo/`) — match prototype 1:1.
- [ ] **Flutter Dio client** with base URL from env, Bearer interceptor, auto-refresh on 401.
- [ ] **Flutter token storage** in `flutter_secure_storage`.
- [ ] **Flutter auth notifier** (Riverpod `AsyncNotifier`).
- [ ] **Landing sections**: Hero, product details, how it works, FAQ, contact buttons, footer, APK CTA placeholder.
- [ ] **Landing visual identity** applied (palette + Poppins, original — not Circuit's).
- [ ] **GraphHopper SP graph**: download `sao-paulo-latest.osm.pbf` from Geofabrik to `infra/graphhopper/data/`.
- [ ] **GraphHopper config**: `infra/graphhopper/config.yml` (motorcycle profile, CH, JVM `-Xmx800m`).
- [ ] **GraphHopper graph import** locally — verify `curl http://localhost:8989/route?point=...&profile=motorcycle` works.
- [ ] **Benchmark script** `infra/graphhopper/benchmark.sh` — 100 randomized SP routes, p50/p95/p99.
- [ ] **Local benchmark run** — record result in `docs/BENCHMARKS.md`.

## Phase 3 — M1 deploy

- [ ] First SSH to DO 1GB droplet — create `roteirizador` non-root user with sudo.
- [ ] Disable root SSH login + password auth.
- [ ] `ufw`: allow 22, 80, 443. Enable. Install `fail2ban`.
- [ ] Install Docker Engine + Compose (official Ubuntu repo).
- [ ] Set hostname `roteirizador-pro`, timezone `America/Sao_Paulo`, unattended-upgrades.
- [ ] Create `/opt/roteirizador/{compose,data/postgres,data/redis,data/graphhopper/{pbf,graph-cache},backups,logs,certs}`.
- [ ] `git clone` repo to `/opt/roteirizador/`. Copy `.env` (chmod 600).
- [ ] Build and run `docker compose up -d`. All services healthy.
- [ ] Configure Nginx + Certbot for `api.roteirizadorpro.com.br`. Verify HTTPS.
- [ ] DNS: `A` record `api.roteirizadorpro.com.br` → droplet IP. TTL 300.
- [ ] Configure Vercel: connect to repo, root dir `apps/landing`, auto-deploy on `develop`.
- [ ] DNS: `A` record `@` → Vercel `76.76.21.21`, `CNAME www` → `cname.vercel-dns.com`. Verify HTTPS green.
- [ ] `scripts/backup-postgres.sh` (pg_dump + 30-day rotation). Cron at 03:00.
- [ ] Verify backup restore on a throwaway DB.
- [ ] Take DigitalOcean droplet snapshot (rollback baseline).

## Phase 4 — M1 acceptance

- [ ] **Criterion 1:** visit `https://roteirizadorpro.com.br` from external network. Screenshot. HTTPS green.
- [ ] **Criterion 2:** `curl https://api.roteirizadorpro.com.br/health` → 200. Auth round-trip works (register → login → me → refresh).
- [ ] **Criterion 3:** production benchmark, p95 < 200ms, document in `docs/BENCHMARKS.md`.
- [ ] **Criterion 4:** client confirms (in writing on Workana) that he has DO panel access and can list running containers.
- [ ] Author `docs/INSTALL.md` — full reproducible install walkthrough.
- [ ] Record demo video covering all four criteria (Loom).
- [ ] Tag `git tag -a v1.0-m1`. Push tag.
- [ ] Notify client in Workana with demo video link + acceptance checklist.

## Discovered while working

- [ ] Install Android Studio + Android SDK to enable `flutter run` on emulator and `flutter build apk` for distribution. `flutter doctor` currently flags this as the only blocker for full-stack mobile development; analyze + test work without it.
- [ ] Local dev currently runs Node v24 — runtime is locked to Node 20 LTS by ADR-0003. `.nvmrc` declares 20; run `nvm use` (or install nvm) before `bun run dev` / `bun run build` going forward.
- [ ] Re-evaluate TS 5 → 6 bump after M1 ships (TS 6.0 just released; deferred to avoid new strictness errors during Phase 2).
- [ ] Re-evaluate Tailwind 3 → 4 and React 18 → 19 after M1 ships (both require new ADRs because they propagate breaking changes).

---

## Done

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten (Karpathy + Anthropic primary sources).
- [x] **2026-05-05** — `CONTRIBUTING.md`, `docs/03-CONVENTIONS.md`, session log structure.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md`.
- [x] **2026-05-05** — `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`.
- [x] **2026-05-05** — Roadmap docs (later replaced by `docs/08-ROADMAP.md`), `docs/09-DISASTER-RECOVERY.md`.
- [x] **2026-05-05** — ADRs 0001–0010 (all stack decisions documented).
- [x] **2026-05-05** — `docs/04-FEATURES.md`, `docs/05-SCREENS.md`.
- [x] **2026-05-05** — Monorepo skeleton (`apps/`, `infra/`, `scripts/`).
- [x] **2026-05-05** — `SECURITY.md`, `.github/pull_request_template.md`.
- [x] **2026-05-06** — `docs/06-DESIGN-SYSTEM.md`, `docs/07-INFRA.md`.
- [x] **2026-05-07** — Approved Claude Design prototype tracked in repo at `prototipo/`.
- [x] **2026-05-07** — Documentation reorganization: M1-focused, prototype-aligned, redundancy removed. See `docs/10-CHANGELOG.md`.
- [x] **2026-05-08** — Phase 1 Foundations complete: backend (Fastify v5 + TypeBox + Prisma 7), landing (Next.js 14 + Tailwind), mobile (Flutter source skeleton), `infra/docker-compose.yml` with postgres + redis healthy locally and graphhopper opt-in via `routing` profile.
- [x] **2026-05-08** — Migrated to Bun as package manager (Node 20 LTS stays the runtime). Bumped six compatible major deps in backend (`@fastify/jwt` 10, `@fastify/type-provider-typebox` 6, `bcrypt` 6, `pino` 10, `pino-pretty` 13, `dotenv` 17). See ADR-0011.
- [x] **2026-05-08** — Installed Flutter SDK 3.41.9 via `brew install --cask flutter`, ran `flutter create --platforms=android --org br.com.roteirizadorpro --project-name roteirizador_pro --no-pub .` in `apps/mobile/`, resolved deps with `flutter pub get`, verified with `flutter analyze` (clean) and `flutter test` (1/1 passing).
