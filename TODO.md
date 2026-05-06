# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** Active milestone only. Completed items are moved to `## Done` at session end.
> **Last updated:** 2026-05-06
>
> **Development order (decided 2026-05-06):**
> 1. Mobile app frontend (Flutter) — local, no server dependency
> 2. Backend + GraphHopper — local Docker stack
> 3. Landing page — Vercel deploy
> 4. Server deploy — only when client provisions DO droplet

## Current Milestone: M1 — Infra, Landing, Backend Base

**Payment:** R$ 2,000 via Workana escrow on approval.

**Approval criteria** (verbatim from accepted proposal):
- Site is live at `roteirizadorpro.com.br`.
- API responds correctly.
- Route calculation works within the promised time (<200ms).
- Client has full access to the server panel.

---

## Phase 0 — Blockers (client-side, parallel to all phases below)

These do not block local development. They block the final server deploy only.

- [ ] **[BLOCKER — server only]** Client provisions $6/month 1GB DigitalOcean droplet, São Paulo region, Ubuntu 24.04. Account in client's name.
- [ ] **[BLOCKER — server only]** Client adds Eduardo's SSH public key to the droplet.
- [ ] **[BLOCKER — server only]** Client confirms DNS access for `roteirizadorpro.com.br`.
- [ ] **[BLOCKER — landing]** Client provides contact channels for landing page (WhatsApp number? Email?).
- [ ] **[BLOCKER — landing]** Client approves product copy for landing (or approves Eduardo's draft).
- [ ] **[BLOCKER — handoff]** Client confirms target GitHub repo for ownership transfer at end of M1.
- [ ] Generate Eduardo's SSH keypair and share public key with client.

---

## Phase 1 — Mobile App Frontend (Flutter) — LOCAL

> No server needed. Runs against mock/local backend.
> Start here.

### Setup

**Success criterion:** `flutter run` launches the app on a device/emulator with no errors.

- [ ] Initialize `apps/mobile/` with `flutter create` (stable channel, package name `br.com.roteirizadorpro`).
- [ ] Configure `analysis_options.yaml` with `flutter_lints`.
- [ ] Install core deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `dio`, `flutter_secure_storage`, `sqflite`, `url_launcher`, `permission_handler`.
- [ ] Configure `build_runner` pipeline. Verify `dart run build_runner build` runs clean.
- [ ] Set up flavor/env config: `API_BASE_URL` via `--dart-define` (local = `http://10.0.2.2:3000`, prod = `https://api.roteirizadorpro.com.br`).
- [ ] Author `apps/mobile/.env.example`.
- [ ] Remove boilerplate counter app. Blank `MaterialApp` as starting point.

### Navigation shell

**Success criterion:** Bottom nav renders with 3 tabs; routes switch without error.

- [ ] Install `go_router`.
- [ ] Define routes: `/login`, `/register`, `/home` (route list), `/settings`.
- [ ] Bottom navigation bar with tabs: Routes, Settings.
- [ ] Auth guard: redirect to `/login` if no valid token in secure storage.

### Auth screens (F01)

**Success criterion:** Login and register screens render and wire to Riverpod providers. API calls fail gracefully (backend not running yet is OK).

- [ ] Login screen: email + password fields, "Sign in" button, link to register.
- [ ] Register screen: name, email, phone, password fields, "Create account" button.
- [ ] `AuthNotifier` (Riverpod `AsyncNotifier`) with `login()`, `register()`, `logout()`, `refreshToken()` methods.
- [ ] Dio client with base URL from env, `Authorization: Bearer` interceptor, auto-refresh on 401.
- [ ] Token read/write from `flutter_secure_storage`.
- [ ] Error handling: show `SnackBar` on 4xx/5xx.

### Stop list screen (F05)

**Success criterion:** User can add, reorder, delete, and mark stops as delivered on a mock list.

- [ ] Stop list screen with `ReorderableListView`.
- [ ] `StopsNotifier` (Riverpod) managing list state in memory.
- [ ] "Add stop" FAB → opens bottom sheet with input options (manual, voice, OCR).
- [ ] Swipe left → delete (with undo snackbar).
- [ ] Swipe right → mark as delivered (green checkmark, moves to bottom).
- [ ] Long press → edit address.
- [ ] Empty state illustration and copy ("No stops yet. Add your first delivery.").

### Manual address entry (F02)

**Success criterion:** User types an address, sees autocomplete dropdown, selects, stop is added to list.

- [ ] Text field with 300ms debounce.
- [ ] Calls `POST /stops/geocode` (mocked for now — returns hardcoded SP coordinates).
- [ ] Dropdown with max 5 results.
- [ ] On selection: stop added to `StopsNotifier`.
- [ ] Fallback: confirm button if no autocomplete selected.

### Voice address entry (F03)

**Success criterion:** User taps mic, speaks, transcription appears for review, confirmed stop added.

- [ ] Install `speech_to_text`.
- [ ] Mic button in the "add stop" bottom sheet.
- [ ] Permission request flow (microphone).
- [ ] Transcription displayed for user review before geocoding.
- [ ] Passes transcription through same geocoding flow as F02.
- [ ] Error state: "Could not understand. Try again."

### OCR address entry (F04)

**Success criterion:** User opens camera, captures label, CEP/address extracted, shown for review.

- [ ] Install `google_mlkit_text_recognition`, `image_picker` (or `camera`).
- [ ] Camera button in the "add stop" bottom sheet.
- [ ] Permission request flow (camera).
- [ ] Image captured → passed to ML Kit on-device OCR.
- [ ] Regex extraction: CEP pattern `\d{5}-?\d{3}`.
- [ ] Pre-fill address field with extracted text for user review.
- [ ] Fallback: if nothing found, show raw OCR output for manual edit.

### Home point screen (F06)

**Success criterion:** User sets home address in Settings; house icon visible on route screen.

- [ ] Settings screen with "My home" field.
- [ ] Same geocoding flow as F02 for address resolution.
- [ ] Persisted in SQLite and synced to backend `PATCH /user/home` (mocked for now).
- [ ] House icon displayed on route screen when home is set.

### Route screen + optimization UI (F07 UI only)

**Success criterion:** "Optimize" button triggers a loading state and renders a mock ordered list with ETA badge.

- [ ] "Optimize route" button on route screen.
- [ ] Calls `POST /routes/optimize` (mocked — returns stops in reverse order as dummy result).
- [ ] Loading indicator during optimization.
- [ ] ETA badge at top of screen (e.g., `[~14:30]`) — use mock duration for now.
- [ ] Subscriber counter badge adjacent to ETA badge (hardcoded `[0]` for now — real in M2).
- [ ] Optimized order rendered in stop list.
- [ ] "Revert to original order" option.

### External navigation (F08)

**Success criterion:** Tapping "Iniciar Navegação" opens Waze or Google Maps with correct coordinates.

- [ ] "Iniciar Navegação" button on each stop card (disabled state when no subscription — grey, shows lock icon).
- [ ] On tap: check which apps are installed (`url_launcher` `canLaunchUrl`).
- [ ] If both: bottom sheet "Open with Waze" / "Open with Google Maps".
- [ ] If one: open directly.
- [ ] If none: browser fallback `https://maps.google.com/?daddr=lat,lng`.
- [ ] Paywall: button tap when inactive subscription → navigates to subscription modal (stubbed for now).

### Share screen (F12)

**Success criterion:** Share screen renders all three share methods and each executes without error.

- [ ] Install `qr_flutter`, `share_plus` (or manual clipboard via `Clipboard.setData`).
- [ ] Share screen accessible from Settings or via FAB on home.
- [ ] WhatsApp button: `whatsapp://send?text=...` with download URL.
- [ ] Copy Link button: copies `https://roteirizadorpro.com.br/download` to clipboard, shows "Copied!" feedback.
- [ ] QR Code: `QrImageView` rendering the download URL.

---

## Phase 2 — Backend + GraphHopper — LOCAL DOCKER

> No production server needed. Runs via `docker compose up` locally.
> Start after Phase 1 navigation shell is working (parallel is fine).

### Local stack setup

**Success criterion:** `docker compose up` brings up all services; backend responds at `http://localhost:3000/health`.

- [ ] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`, `backend`.
- [ ] Postgres 16 + Redis 7 bound to `127.0.0.1` only.
- [ ] GraphHopper: SP-only PBF, motorcycle profile, CH enabled, `-Xmx800m` heap.
- [ ] Backend service with volume mount to `apps/backend/` for local dev.
- [ ] Author `apps/backend/.env.example` with all variables.
- [ ] `docker compose up` → all four services healthy.

### GraphHopper local

**Success criterion:** `curl "http://localhost:8989/route?point=-23.55,-46.63&point=-23.56,-46.64&profile=motorcycle"` returns a valid route.

- [ ] Download `sao-paulo-latest.osm.pbf` from Geofabrik to `infra/graphhopper/data/`.
- [ ] Author `infra/graphhopper/config.yml` (motorcycle profile, CH, correct data path).
- [ ] First-run graph import (document duration in `docs/BENCHMARKS.md`).
- [ ] Verify route endpoint responds.
- [ ] Author `infra/graphhopper/benchmark.sh`: 100 randomized SP routes, output p50/p95/p99.
- [ ] Run benchmark locally, document result.
- [ ] Author `infra/graphhopper/reimport-sudeste.sh` — script to reimport full Sudeste after server resize to 8GB.

### Backend skeleton

**Success criterion:** All auth endpoints and healthchecks pass locally.

- [ ] Initialize `apps/backend/`: `npm init`, TypeScript strict, Fastify v5 + TypeBox.
- [ ] Install: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `@fastify/type-provider-typebox`, `pino`, `bcrypt`, `dotenv`.
- [ ] `tsconfig.json`: strict mode, path aliases (`@/` → `src/`).
- [ ] Initialize Prisma 7 + `@prisma/adapter-pg`. Author `prisma/schema.prisma` (`users`, `refresh_tokens`). Author `prisma.config.ts`.
- [ ] Run first migration against local Postgres. Verify generated client output.
- [ ] `src/server.ts`: Fastify instance, all plugins registered, graceful shutdown.
- [ ] Auth routes: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`.
- [ ] Healthchecks: `GET /health`, `GET /health/db`, `GET /health/graphhopper`.
- [ ] Placeholder `POST /routes/optimize` — proxies to GraphHopper, returns ordered stops.
- [ ] Pino JSON logging. Rate limits on `/auth/*`.
- [ ] Full round-trip test: register → login → me → refresh → logout.

### Docker image

**Success criterion:** `docker compose up --build` starts backend from image with no errors.

- [ ] Author `apps/backend/Dockerfile` (multi-stage: build + runtime).
- [ ] Add `backend` service to `docker-compose.yml`.
- [ ] Verify image builds and service is healthy.
- [ ] Author `scripts/backup-postgres.sh` (pg_dump + 30-day rotation).

---

## Phase 3 — Landing Page — VERCEL

> No production server needed. Deploy to Vercel staging immediately.
> Start after Phase 2 backend skeleton is working (parallel is fine once confirmed).
> Blocked on client contact info and copy approval.

### Setup and deploy

**Success criterion:** Landing is live on Vercel at a staging URL, accessible from external network with HTTPS.

- [ ] Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind CSS.
- [ ] Connect to GitHub repo in Vercel (Eduardo's account). Auto-deploy on push to `develop`.
- [ ] Verify staging URL works with HTTPS.

### Content

**Success criterion:** All required sections present and mobile viewport correct.

- [ ] Hero section: app name, tagline, primary CTA ("Download APK" — placeholder).
- [ ] Product details: what the app does, key features.
- [ ] How it works: 3-step explainer (add stops → optimize → navigate).
- [ ] FAQ: at least 5 questions (how to install APK, subscription, supported phones, etc.).
- [ ] Contact buttons: (pending client confirmation of channels).
- [ ] Footer: copyright, privacy policy link (placeholder).
- [ ] APK download CTA: placeholder button ("Coming soon") — live link added in M2.
- [ ] Original visual identity applied (palette + typography — not Circuit's).
- [ ] Mobile viewport test on 3 screen sizes.

### DNS + domain

**Success criterion:** `https://roteirizadorpro.com.br` resolves to Vercel with valid HTTPS.

- [ ] Configure `roteirizadorpro.com.br` apex + `www` → Vercel (CNAME or A records).
- [ ] HTTPS auto-provisioned by Vercel. Verify green padlock.
- [ ] Document Vercel ownership transfer steps in `docs/INSTALL.md`.

---

## Phase 4 — Server Deploy — WAITING ON CLIENT DROPLET

> Blocked entirely on client provisioning the DigitalOcean droplet.
> When droplet is ready: everything from Phases 1-3 is already built and tested. This phase is just "ship it".

### Server hardening

- [ ] First SSH as root → create `roteirizador` non-root user with sudo.
- [ ] Disable root SSH login, disable password auth.
- [ ] `ufw`: allow 22, 80, 443. Enable.
- [ ] `fail2ban` default SSH jail.
- [ ] Unattended-upgrades, hostname, timezone (`America/Sao_Paulo`).

### Deploy stack

- [ ] Install Docker Engine + Compose.
- [ ] `git clone` repo to `/opt/roteirizador/`.
- [ ] Copy `.env` to server (`chmod 600`). Never commit.
- [ ] `docker compose up -d`. All services healthy.
- [ ] Nginx + Certbot: HTTPS for `api.roteirizadorpro.com.br`.
- [ ] Cron: `scripts/backup-postgres.sh` at 03:00.

### Final verification (M1 acceptance)

- [ ] **Criterion 1:** `https://roteirizadorpro.com.br` live, HTTPS green. Screenshot.
- [ ] **Criterion 2:** `curl https://api.roteirizadorpro.com.br/health` → 200. Auth round-trip works.
- [ ] **Criterion 3:** Run `infra/graphhopper/benchmark.sh` on server. p95 < 200ms. Document in `docs/BENCHMARKS.md`.
- [ ] **Criterion 4:** Client logs into DO panel, SSHes in, lists running containers. Confirmed in writing.
- [ ] Take DigitalOcean droplet snapshot (rollback baseline).
- [ ] Record Loom video covering all four criteria.
- [ ] Tag: `git tag -a v1.0-m1`. Push.
- [ ] Transfer GitHub repo ownership to client.
- [ ] Notify client in Workana with Loom link + acceptance checklist.

---

## Discovered while working

- (none yet)

---

## Backlog (M2 — not active)

Full plan in `docs/04-ROADMAP-M2.md`.

- "Sentido casa" TSP optimization (real algorithm, not mock).
- Efi Bank Pix Split (cobrança, webhook, subscription activation).
- Paywall enforcement (real subscription check, not stubbed).
- Real-time subscriber counter (WebSocket + Redis).
- Admin panel for partners.
- Resize DO droplet to 8GB + reimport full Sudeste PBFs.

---

## Done

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten (Karpathy + Anthropic primary sources).
- [x] **2026-05-05** — `CONTRIBUTING.md`, `docs/03-CONVENTIONS.md`, session log structure.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md`.
- [x] **2026-05-05** — `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`.
- [x] **2026-05-05** — `docs/04-ROADMAP-M1.md`, `docs/04-ROADMAP-M2.md`, `docs/06-DISASTER-RECOVERY.md`.
- [x] **2026-05-05** — ADRs 0001–0010 (all stack decisions documented).
- [x] **2026-05-05** — `agents.md`, `docs/FEATURES.md` (all 15 features specified).
- [x] **2026-05-05** — Monorepo skeleton (`apps/`, `infra/`, `scripts/`).
- [x] **2026-05-05** — `SECURITY.md`, `CODE_OF_CONDUCT.md`, `.github/pull_request_template.md`.
- [x] **2026-05-06** — `docs/04-ROADMAP-M1.md` updated for 1GB droplet workaround.
- [x] **2026-05-06** — TODO.md restructured: local-first development order (mobile → backend → landing → server).
