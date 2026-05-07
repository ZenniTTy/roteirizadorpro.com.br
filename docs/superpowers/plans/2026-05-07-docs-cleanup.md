# Docs Cleanup & M1 Realignment — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize `Roteirizador Pro` documentation so the repo is clean, M1-focused, prototype-aligned, and ready for `flutter create apps/mobile/` as the next concrete action.

**Architecture:** Pure documentation reorganization. No application code is written in this plan. Files are renamed (preserving git history), rewritten, created, deleted, and verified. Each phase is one or more focused commits.

**Tech Stack:** Markdown + git. No runtime, no test runner — verification via shell commands (`grep`, `test -f`, `git status`).

**Spec:** `docs/superpowers/specs/2026-05-07-docs-cleanup-design.md`

---

## Working directory

All commands assume `cwd` is the repo root:
`/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart`

The path contains spaces and brackets — always quote when needed.

---

## Phase 0 — Pre-flight

### Task 0.1: Verify clean tree, correct branch

**Files:**
- Read-only: working tree state

- [ ] **Step 1: Confirm we are on `develop` and tree is clean of unintended changes**

Run:
```bash
git status
```

Expected:
```
On branch develop
Your branch is up to date with 'origin/develop'.

Untracked files:
  ...
  logo.png
  prototipo/
```

The `logo.png` and `prototipo/` are expected untracked items — `logo.png` will be moved by Task 2.1; `prototipo/` is the canonical UI source and will be added to `.gitignore`-or-tracked decision in a later step (we will track it in this plan, since the user wants it referenced from docs).

If anything else appears modified (M) or other untracked files exist, stop and reconcile with the user before proceeding.

- [ ] **Step 2: Verify the spec is committed**

Run:
```bash
git log --oneline -5
```

Expected: top commit message contains `docs(spec): add M1-focused docs cleanup design spec`.

- [ ] **Step 3: Track the prototype directory**

The prototype is the canonical UI source — it must be tracked.

Run:
```bash
git add prototipo/
git commit -m "docs(prototype): track approved Claude Design prototype as canonical UI source"
```

Verify:
```bash
git ls-files prototipo/ | head -5
```

Expected: shows `prototipo/README.md`, `prototipo/Roteirizador Pro.html`, etc.

---

## Phase 1 — Renames (preserve git history)

### Task 1.1: Rename docs to contiguous numbering

**Files:**
- Rename: `docs/FEATURES.md` → `docs/04-FEATURES.md`
- Rename: `docs/SCREENS.md` → `docs/05-SCREENS.md`
- Rename: `docs/DESIGN-SYSTEM.md` → `docs/06-DESIGN-SYSTEM.md`
- Rename: `docs/INFRA-ACCESS.md` → `docs/07-INFRA.md`
- Rename: `docs/06-DISASTER-RECOVERY.md` → `docs/09-DISASTER-RECOVERY.md`

- [ ] **Step 1: Execute the renames via `git mv`**

Run:
```bash
git mv docs/FEATURES.md docs/04-FEATURES.md
git mv docs/SCREENS.md docs/05-SCREENS.md
git mv docs/DESIGN-SYSTEM.md docs/06-DESIGN-SYSTEM.md
git mv docs/INFRA-ACCESS.md docs/07-INFRA.md
git mv docs/06-DISASTER-RECOVERY.md docs/09-DISASTER-RECOVERY.md
```

- [ ] **Step 2: Verify renames landed**

Run:
```bash
ls docs/*.md
```

Expected output (in some order):
```
docs/01-PROJECT.md
docs/02-ARCHITECTURE.md
docs/03-CONVENTIONS.md
docs/04-FEATURES.md
docs/04-ROADMAP-M1.md
docs/04-ROADMAP-M2.md
docs/05-SCREENS.md
docs/06-DESIGN-SYSTEM.md
docs/07-INFRA.md
docs/09-DISASTER-RECOVERY.md
docs/DESIGN-PROMPT.md
```

(`04-ROADMAP-M1.md`, `04-ROADMAP-M2.md`, `DESIGN-PROMPT.md` are still present — they will be deleted in Phase 5.)

- [ ] **Step 3: Commit**

Run:
```bash
git commit -m "docs(structure): renumber and rename for contiguous order"
```

---

## Phase 2 — Move logo to landing assets

### Task 2.1: Move `logo.png` into `apps/landing/public/`

**Files:**
- Move: `logo.png` → `apps/landing/public/logo.png`
- Create directory: `apps/landing/public/`

- [ ] **Step 1: Ensure target directory exists**

Run:
```bash
mkdir -p apps/landing/public
```

- [ ] **Step 2: Move logo (use plain `mv` since `logo.png` is untracked)**

Run:
```bash
mv logo.png apps/landing/public/logo.png
```

- [ ] **Step 3: Stage and commit**

Run:
```bash
git add apps/landing/public/logo.png
git commit -m "chore(landing): move logo to landing public assets"
```

- [ ] **Step 4: Verify**

Run:
```bash
test -f apps/landing/public/logo.png && echo "OK" || echo "MISSING"
test ! -f logo.png && echo "OK (root logo gone)" || echo "STILL THERE"
```

Expected: both lines print `OK`.

---

## Phase 3 — Create new files

### Task 3.1: Create `docs/08-ROADMAP.md` (M1-only)

**Files:**
- Create: `docs/08-ROADMAP.md`

- [ ] **Step 1: Write the roadmap file**

Create `docs/08-ROADMAP.md` with this exact content:

````markdown
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
````

- [ ] **Step 2: Verify the file exists and has the expected sections**

Run:
```bash
test -f docs/08-ROADMAP.md && echo "OK"
grep -c "^## " docs/08-ROADMAP.md
```

Expected: `OK`, then a number ≥ 6 (sections: Acceptance criteria, Plan, Deliverables checklist, Risks, Out of scope, After M1).

### Task 3.2: Create `docs/10-CHANGELOG.md`

**Files:**
- Create: `docs/10-CHANGELOG.md`

- [ ] **Step 1: Write the changelog**

Create `docs/10-CHANGELOG.md` with this exact content:

````markdown
# 10 — Changelog (Documentation)

Tracks structural and scope changes to the documentation itself. Code changes go into git history; this file is for documentation reorganization milestones.

## 2026-05-07

- **Documentation reorganization:** removed redundant files (`agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`), unified roadmap into a single M1-focused `docs/08-ROADMAP.md`, renumbered docs to contiguous 01–10.
- **Prototype as canonical UI source:** `prototipo/` (Claude Design output, client-approved) is now referenced from `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md`. Tokens (including `neon`) and 19-screen list synced.
- **Roadmap focused on M1 only.** M2 scope deferred until post-M1 client conversation.
- **Server titularity clarified:** DigitalOcean account is the client's. Eduardo has admin access.
- **1GB droplet workaround documented as the M1 reality.** 8GB resize + Sudeste reimport is post-M1 work.
````

- [ ] **Step 2: Verify**

Run:
```bash
test -f docs/10-CHANGELOG.md && echo "OK"
```

Expected: `OK`.

### Task 3.3: Commit Phase 3

- [ ] **Step 1: Stage and commit**

Run:
```bash
git add docs/08-ROADMAP.md docs/10-CHANGELOG.md
git commit -m "docs(roadmap): add M1-focused roadmap and changelog"
```

---

## Phase 4 — Rewrites at new paths

### Task 4.1: Rewrite `docs/05-SCREENS.md` (19 prototype screens + Spoke mapping)

**Files:**
- Rewrite: `docs/05-SCREENS.md`

- [ ] **Step 1: Read the prototype source to confirm screen IDs**

Run:
```bash
grep "AB(" "prototipo/Roteirizador Pro.html" | head -25
```

Expected: lines like `{AB('login', '01 · Login', ScreenLogin)}` for all 19 screens.

- [ ] **Step 2: Replace `docs/05-SCREENS.md` with this content**

````markdown
# 05 — Screens

The screen catalogue for Roteirizador Pro. **The canonical UI source is the approved Claude Design prototype** at `prototipo/`. This document mirrors the prototype's structure for code reference.

> Functional UX patterns are inspired by Spoke/Circuit Route Planner; visual identity is 100% original (see `docs/decisions/0010-clone-positioning.md`).

## Prototype screen map (19 screens)

Listed in the order they appear in `prototipo/Roteirizador Pro.html`. Each entry: section, screen ID, label, milestone scope.

### Section 01 — Authentication

| ID | Label | Milestone |
|---|---|---|
| `login` | 01 · Login | **M1** |
| `register` | 02 · Criar conta | **M1** |

### Section 02 — Route

| ID | Label | Milestone |
|---|---|---|
| `home-empty` | 03 · Home vazia | M2 |
| `home-list` | 04 · Lista de paradas | M2 |
| `map-stops` | 05 · Mapa da rota | M2 |
| `add-stops-map` | 06 · Adicionar pelo mapa | M2 |
| `add-stop` | 07 · Adicionar (busca) | M2 |
| `edit-stop` | 08 · Editar parada | M2 |

### Section 03 — Address capture

| ID | Label | Milestone |
|---|---|---|
| `voice` | 09 · Voz | M2 |
| `ocr` | 10 · Scanner OCR | M2 |
| `optimize-loading` | 11 · Otimizando rota | M2 |
| `optimize` | 12 · Rota otimizada | M2 |
| `reorder` | 13 · Reordenar (laço) | M2 |

### Section 04 — Delivery + subscription

| ID | Label | Milestone |
|---|---|---|
| `stop-detail` | 14 · Detalhe da parada | M2 |
| `navigate` | 15 · Navegação turn-by-turn | M2 |
| `route-complete` | 16 · Rota concluída | M2 |
| `paywall` | 17 · Paywall (Pix) | M2 |

### Section 05 — Account

| ID | Label | Milestone |
|---|---|---|
| `settings` | 18 · Configurações | M2 |
| `share` | 19 · Indique o app | M2 |

## M1 screen detail

Only the two M1 screens are detailed here. M2 screens are documented at "what they are" level above and will be specified per-screen in a future planning cycle when M2 work begins.

### 01 — Login (`login`)

**Purpose:** Get the user into the app with the minimum friction.

**Elements (per prototype):**
- Logo (purple circular, 72dp).
- App name "Roteirizador Pro" — Poppins SemiBold 26.
- Tagline "Entregue mais. Chegue em casa cedo." — text-secondary, 14sp.
- E-mail input (rounded, surface background).
- Password input with show/hide toggle (eye icon).
- "Esqueci minha senha" link (right-aligned, primary purple).
- Primary button "Entrar" (full width, pill).
- Divider with "ou" label.
- Ghost button "Continuar com Google" (with Google color logo SVG).
- Bottom link "Não tem conta? Cadastre-se" (primary purple).

**Gestures / interactions:**
- Eye toggle reveals/hides password.
- Tapping "Cadastre-se" navigates to Register screen.
- Tapping "Entrar" calls `POST /auth/login`. On success: store tokens, navigate to home (M2 — for M1 the success state is a placeholder navigation, since the home screens are M2 work).
- "Continuar com Google" is **out of scope for M1** — keeps the visual element but renders a non-functional button (or shows a "coming soon" snackbar).

**Mock vs real (M1):**
- Real: backend `/auth/login` endpoint working, JWT tokens, secure storage.
- Stubbed: Google OAuth (button visible, not wired).
- Stubbed: success destination — navigates to a placeholder route since home is M2.

### 02 — Register (`register`)

**Purpose:** Create a new account in under one minute.

**Elements (per prototype):**
- Top bar with back arrow + title "Criar conta".
- Subtitle "Comece a otimizar suas rotas em menos de 1 minuto."
- Inputs: Nome completo, E-mail, Telefone (`+55` prefix), Senha.
- Primary button "Criar conta" (full width).
- Terms acceptance line (Termos / Política de privacidade).
- Bottom link "Já tem conta? Entrar".

**Gestures / interactions:**
- Back arrow returns to Login.
- "Criar conta" calls `POST /auth/register`.
- Success → navigates to placeholder route (home screens are M2).
- Email/phone validation client-side.

**Mock vs real (M1):**
- Real: backend `/auth/register` endpoint working with TypeBox validation.
- Real: bcrypt cost 12 password hashing on backend.
- Stubbed: success destination — navigates to a placeholder route.

## Spoke/Circuit feature mapping (reference)

The functional behavior of the app — drag-to-reorder, swipe-to-complete, soft paywall on navigation, list-first UX — is inspired by Spoke/Circuit Route Planner. Visual identity is original. This table documents which Spoke screens we replicate and which we deliberately exclude.

### Replicated (M2 work)

| Spoke screen | Roteirizador Pro screen | Replication scope |
|---|---|---|
| Home / Route List | `home-empty`, `home-list`, `map-stops` | Full functional replication, original visuals |
| Add Stop bottom sheet | `add-stop`, `add-stops-map`, `edit-stop` | Same input methods (keyboard / voice / camera) |
| Voice Input | `voice` | Same review-before-confirm pattern |
| OCR / Camera Input | `ocr` | Same capture-review-confirm pattern |
| Route Optimization (loading) | `optimize-loading` | Same transparency-during-wait pattern, with our extra "sentido casa" step |
| Optimized Route | `optimize`, `reorder` | Same list view post-optimization |
| Stop Detail | `stop-detail` | Same action-forward pattern |
| Navigation handoff | `navigate` | Same external GPS handoff (Waze / Google Maps) |
| Subscription / Paywall | `paywall` | Same soft-paywall-at-moment-of-value pattern |
| Settings | `settings` | Same sectioned layout |
| Share / Referral | `share` | Spoke has share — we add WhatsApp + Copy Link + QR Code |

### Deliberately excluded (V1)

| Spoke screen | Reason |
|---|---|
| Load vehicle (package placement) | Not in client brief |
| Team dispatch / transfer stops | Solo driver app only |
| Package ID management | Not in client brief |
| Proof of delivery (photos) | Not in client brief |
| Time windows per stop | Not in client brief |
| Break scheduling | Not in client brief |
| Android Auto / CarPlay | Out of scope |
| Internal navigation (in-app maps) | We use deep link to external app |
| Stop color tagging | Not in client brief |

These can be added post-M2 if the client wishes.

## Key UX principles (carry into our app)

1. **List-first, not map-first.** The stop list is the primary view. The map is secondary.
2. **Transparency during wait.** Optimization shows progress steps, not a spinner.
3. **Review before confirm.** Voice and OCR always show result for user to review.
4. **Single primary action per screen.** Each screen has one dominant CTA button.
5. **Inline status updates.** Stop status changes happen in the list without navigation.
6. **Minimal onboarding.** No forced tutorial. Users learn by doing.
7. **Soft paywall at the moment of value.** Gate the action the user most wants, not the app entry.
````

- [ ] **Step 3: Verify**

Run:
```bash
grep -c "^### " docs/05-SCREENS.md
grep -c "^| \`" docs/05-SCREENS.md
```

Expected: 13+ subsections (5 sections + M1 subsections + Spoke replicated/excluded), and ≥ 19 screen-id rows.

### Task 4.2: Update `docs/06-DESIGN-SYSTEM.md` (add neon, sync with prototipo)

**Files:**
- Modify: `docs/06-DESIGN-SYSTEM.md`

- [ ] **Step 1: Read current state**

Run:
```bash
head -20 docs/06-DESIGN-SYSTEM.md
```

The current file already exists from the rename. We need to:
1. Add a callout that `prototipo/tokens.js` is canonical.
2. Add the `neon` color token family.
3. Confirm radii match prototype values (`rCard:16, rBtn:24, rInput:12, rSheet:20`).

- [ ] **Step 2: Apply Edit operations**

Add a callout right after the `**Decided by:** Eduardo` line:

Replace:
```
**Decided:** 2026-05-06
**Decided by:** Eduardo

---
```

With:
```
**Decided:** 2026-05-06
**Decided by:** Eduardo
**Last sync with prototype:** 2026-05-07

> **Canonical source:** `prototipo/tokens.js` is the source of truth for tokens. This document mirrors that file. If they disagree, `prototipo/tokens.js` wins; update this file.

---
```

Then in the **Color Palette** table, add these new rows after the `accent` row (right before `background`):

```
| `neon` | `#C6FF3D` | "Live" cues, secondary accent (e.g., active subscriber counter pulse) |
| `neon-dark` | `#9BCC1F` | Pressed state for neon |
| `neon-light` | `#F1FFCC` | Neon background pads |
| `neon-ink` | `#3D5400` | Text on neon background |
```

- [ ] **Step 3: Verify the neon tokens were added**

Run:
```bash
grep -c "neon" docs/06-DESIGN-SYSTEM.md
```

Expected: ≥ 4 (one row per neon token, plus mention in callout if any).

### Task 4.3: Update `docs/04-FEATURES.md` (status column, M1/M2 tagging)

**Files:**
- Modify: `docs/04-FEATURES.md`

- [ ] **Step 1: Update the Feature Map table**

Replace the entire `## Feature Map` section content:

Find:
```markdown
## Feature Map

| ID | Feature | Milestone | Status |
|---|---|---|---|
| F01 | User registration and login | M1 | Pending |
| F02 | Manual address entry | M2 | Pending |
| F03 | Voice address entry | M2 | Pending |
| F04 | OCR address entry | M2 | Pending |
| F05 | Stop list management | M2 | Pending |
| F06 | Home point ("sentido casa") | M2 | Pending |
| F07 | Route optimization | M2 | Pending |
| F08 | External navigation (Waze / Google Maps) | M2 | Pending |
| F09 | Subscription paywall | M2 | Pending |
| F10 | Pix payment with 50/50 auto-split | M2 | Pending |
| F11 | Real-time subscriber counter | M2 | Pending |
| F12 | Referral / share screen | M2 | Pending |
| F13 | Partner admin panel | M2 | Pending |
| F14 | Landing page | M1 | Pending |
| F15 | GraphHopper routing engine | M1 | Pending |
```

Replace with:
```markdown
## Feature Map

| ID | Feature | Milestone | M1 status |
|---|---|---|---|
| F01 | User registration and login | M1 | Pending |
| F14 | Landing page | M1 | Pending |
| F15 | GraphHopper routing engine | M1 | Pending |
| F02 | Manual address entry | M2 (post-M1, scope to reconfirm) | — |
| F03 | Voice address entry | M2 (post-M1) | — |
| F04 | OCR address entry | M2 (post-M1) | — |
| F05 | Stop list management | M2 (post-M1) | — |
| F06 | Home point ("sentido casa") | M2 (post-M1) | — |
| F07 | Route optimization | M2 (post-M1) | — |
| F08 | External navigation (Waze / Google Maps) | M2 (post-M1) | — |
| F09 | Subscription paywall | M2 (post-M1) | — |
| F10 | Pix payment with 50/50 auto-split | M2 (post-M1) | — |
| F11 | Real-time subscriber counter | M2 (post-M1) | — |
| F12 | Referral / share screen | M2 (post-M1) | — |
| F13 | Partner admin panel | M2 (post-M1) | — |

> M2 features are documented here as the canonical reference for what was contracted. M2 implementation planning happens after M1 acceptance, in a fresh spec/plan cycle.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep -c "M2 (post-M1" docs/04-FEATURES.md
```

Expected: ≥ 12 (one per M2 feature row, plus the explanatory note).

### Task 4.4: Rewrite `TODO.md` (M1 only)

**Files:**
- Rewrite: `TODO.md`

- [ ] **Step 1: Replace `TODO.md` with this content**

````markdown
# TODO

> **Owner:** Claude Code (read at session start, update at session end).
> **Scope:** M1 only. M2 work begins in a fresh planning cycle after M1 acceptance.
> **M1 deadline:** 2026-05-26.
> **Last updated:** 2026-05-07.

## M1 acceptance criteria (verbatim from Workana)

To release escrow, all four must be true:

1. Site live at `https://roteirizadorpro.com.br` with HTTPS.
2. API responds correctly at `https://api.roteirizadorpro.com.br`.
3. Route calculation p95 < 200ms.
4. Client has full access to the server panel.

Detailed plan: `docs/08-ROADMAP.md`.

---

## Phase 1 — Foundations

- [ ] Initialize `apps/mobile/` with `flutter create` (auth-only scope, package `br.com.roteirizadorpro`).
- [ ] Configure Flutter linter (`flutter_lints`), formatter, analysis options.
- [ ] Install Flutter deps: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `build_runner`, `dio`, `flutter_secure_storage`, `go_router`.
- [ ] Configure `--dart-define API_BASE_URL` and `apps/mobile/.env.example`.
- [ ] Initialize `apps/backend/`: Node 20, TypeScript strict, Fastify v5 + TypeBox.
- [ ] Initialize `apps/backend/` deps: `@fastify/jwt`, `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`, `@sinclair/typebox`, `@fastify/type-provider-typebox`, `pino`, `bcrypt`, `dotenv`.
- [ ] Initialize Prisma 7 + `@prisma/adapter-pg` with `prisma.config.ts`.
- [ ] Author `apps/backend/.env.example`.
- [ ] Initialize `apps/landing/` with Next.js 14 (App Router) + Tailwind.
- [ ] Author `infra/docker-compose.yml` with services: `postgres`, `redis`, `graphhopper`. Bind to 127.0.0.1.
- [ ] `docker compose up` brings up all three services healthy.

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

- (none yet)

---

## Done

- [x] **2026-05-05** — `CLAUDE.md` authored and rewritten (Karpathy + Anthropic primary sources).
- [x] **2026-05-05** — `CONTRIBUTING.md`, `docs/03-CONVENTIONS.md`, session log structure.
- [x] **2026-05-05** — `.gitignore`, `.editorconfig`, `README.md`.
- [x] **2026-05-05** — `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`.
- [x] **2026-05-05** — `docs/04-ROADMAP-M1.md`, `docs/04-ROADMAP-M2.md`, `docs/06-DISASTER-RECOVERY.md` (later replaced by `docs/08-ROADMAP.md` and `docs/09-DISASTER-RECOVERY.md`).
- [x] **2026-05-05** — ADRs 0001–0010 (all stack decisions documented).
- [x] **2026-05-05** — `docs/04-FEATURES.md`, `docs/05-SCREENS.md` (renumbered 2026-05-07).
- [x] **2026-05-05** — Monorepo skeleton (`apps/`, `infra/`, `scripts/`).
- [x] **2026-05-05** — `SECURITY.md`, `.github/pull_request_template.md`.
- [x] **2026-05-06** — `docs/DESIGN-SYSTEM.md` (renumbered to `06-DESIGN-SYSTEM.md` 2026-05-07), `docs/INFRA-ACCESS.md` (renumbered to `07-INFRA.md` 2026-05-07).
- [x] **2026-05-07** — Approved Claude Design prototype tracked in repo at `prototipo/`.
- [x] **2026-05-07** — Documentation reorganization: M1-focused, prototype-aligned, redundancy removed. See `docs/10-CHANGELOG.md`.
````

- [ ] **Step 2: Verify**

Run:
```bash
wc -l TODO.md
grep -c "^- \[ \]" TODO.md
grep -c "^- \[x\]" TODO.md
```

Expected: ≤ 110 lines, ~50 unchecked items, ~12 checked items.

### Task 4.5: Rewrite `CLAUDE.md` (lean, M1-focused)

**Files:**
- Rewrite: `CLAUDE.md`

- [ ] **Step 1: Replace `CLAUDE.md` with this content**

````markdown
# CLAUDE.md

Operating manual for AI agents acting on this repository (Claude Code, Cursor, Claude web). Read this in full before any action.

> **Last updated:** 2026-05-07
> **Maintainer:** Eduardo Rodrigues — `eduardo@ianelli.tech`

## What This Project Is

**Roteirizador Pro** is an Android route-planning app for delivery riders, distributed as APK at `roteirizadorpro.com.br`. It is a **functional fork** of [Spoke/Circuit Route Planner](https://getcircuit.com): we replicate flows, behaviors, screen structure, and UX patterns — we do **not** replicate icons, colors, typography, illustrations, microcopy, or any other Circuit-specific visual asset. Identity is 100% original.

This positioning is non-negotiable. See `docs/decisions/0010-clone-positioning.md`.

## Current Focus: M1

The current milestone is **M1, deadline 2026-05-26**. Do not plan or build M2 work in this cycle. M2 scope will be reconfirmed with the client after M1 acceptance.

M1 plan: `docs/08-ROADMAP.md`.

## Onboarding Ritual

When you start a session in this repo, read in this order:

1. `README.md` — what the project is.
2. This file (`CLAUDE.md`) — how to operate.
3. `TODO.md` — current open M1 tasks.
4. `docs/08-ROADMAP.md` — M1 plan and acceptance criteria.
5. `docs/sessions/0001-INDEX.md` — last 3 session logs at minimum.

Skipping this ritual is not an option, even if the human seems eager to jump to code. **Five minutes of reading saves five hours of rework.**

## UI Source of Truth

The Claude Design prototype at `prototipo/` is the **canonical UI source** — client-approved on 2026-05-07. Visual identity, screens, gestures, and flows must match it 1:1 in implementation. The prototype's `tokens.js` is canonical for design tokens. `docs/05-SCREENS.md` and `docs/06-DESIGN-SYSTEM.md` mirror it; if they disagree with the prototype, the prototype wins.

## Karpathy's Four Principles (canonical)

These four principles are the canonical guidance for LLM coding behavior, originally compiled at [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) from Andrej Karpathy's observations. They apply to every action you take in this repo.

### 1. Think Before Coding

> Don't assume. Don't hide confusion. Surface tradeoffs.

Before implementing: state assumptions explicitly; if multiple interpretations exist, present them; if a simpler approach exists, say so; if anything is unclear, stop and ask.

### 2. Simplicity First

> Minimum code that solves the problem. Nothing speculative.

No features beyond what was asked. No abstractions for single-use code. No "flexibility" that wasn't requested. No error handling for impossible scenarios. If you write 200 lines and it could be 50, rewrite it.

### 3. Surgical Changes

> Touch only what you must. Clean up only your own mess.

Don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken. Match existing style even if you'd write it differently. Mention unrelated dead code — don't delete it. **Every changed line should trace directly to the user's request.**

### 4. Goal-Driven Execution

> Define success criteria. Loop until verified.

Transform "add validation" → "write tests for invalid inputs, then make them pass." Transform "fix the bug" → "write a test that reproduces it, then make it pass." Strong success criteria let you loop independently; weak criteria require constant clarification.

## Project-Specific Critical Rules

These rules can't be inferred from code. They are enforced by you, the agent.

### Stack — Locked Versions

| Layer | Tech | Notes |
|---|---|---|
| Mobile | Flutter + Riverpod 3 (`@riverpod` codegen) | |
| Backend | Node.js 20 LTS + Fastify v5 + TypeBox | TypeBox is the type provider |
| ORM | Prisma 7 + `@prisma/adapter-pg` | Driver adapters mandatory |
| DB / Cache | PostgreSQL 16 / Redis 7 | |
| Routing | GraphHopper self-hosted | SP-only on M1 (1GB droplet); Sudeste post-M1 |
| Server | Ubuntu 24.04 on DigitalOcean (client's account) | 1GB on M1; resize to 8GB post-M1 escrow |
| Landing | Next.js 14 + Tailwind on Vercel | |

Any change requires a new ADR.

### Context7 Mandatory

Before proposing OR installing any external library/framework, query Context7 (`resolve-library-id` then `query-docs`). Training-data knowledge has a cutoff; Context7 has current docs. **No exceptions for libraries within reach of the cutoff date.** Stdlib and well-established APIs (HTTP, SQL) are exempt.

### Verify Your Work

Per Anthropic's official guidance, this is the single highest-leverage thing you can do.

- Provide tests, scripts, or screenshots that let you check yourself.
- Address root causes, not symptoms.
- If you can't verify it, don't ship it.

### Filesystem Protocol

Read first, edit second. Never edit a file without reading the current version. After editing critical files (schema, env, route registrations), re-read to confirm the change landed.

### Git Protocol (essentials)

- `git status` before any Git action.
- Conventional Commits — one logical change per commit.
- Never `git push --force` to `develop` or `main`.

Full Git workflow lives in `CONTRIBUTING.md`.

### Secrets

`.env*` (except `.env.example`) is gitignored. Never commit secrets — not even as placeholders. If a secret leaks, rotate it immediately and scrub history with `git filter-repo`.

## Session End Protocol

At the end of any meaningful session:

1. Update `TODO.md` (mark completed `[x]`, add discovered tasks `[ ]`).
2. Create `docs/sessions/YYYY-MM-DD-NN-<topic>.md` from the template at `0000-template.md`.
3. Append the new session to `docs/sessions/0001-INDEX.md`.
4. Commit all three together with `docs(sessions): <session topic>`.

## When You Disagree With This File

This file is itself versioned. If a rule here is wrong or outdated:

1. Raise it with the human owner.
2. If approved, edit this file with `docs(claude): <what changed>` and bump the date at the top.
3. If the change affects an ADR, update the ADR in the same commit set.

**Self-modification by an AI without human approval is forbidden.**

## References (deeper context, on demand)

The detail lives elsewhere. Read these only when the topic is relevant to your current task:

- Project vision, scope, milestones → `docs/01-PROJECT.md`
- Architecture, flows, schemas, contracts → `docs/02-ARCHITECTURE.md`
- Naming, code style, directory layout → `docs/03-CONVENTIONS.md`
- Features (canonical business rules) → `docs/04-FEATURES.md`
- Screens (prototype catalogue) → `docs/05-SCREENS.md`
- Design system → `docs/06-DESIGN-SYSTEM.md`
- Infrastructure → `docs/07-INFRA.md`
- M1 roadmap → `docs/08-ROADMAP.md`
- Disaster recovery → `docs/09-DISASTER-RECOVERY.md`
- Documentation changelog → `docs/10-CHANGELOG.md`
- All decisions and their rationale → `docs/decisions/`
- Git workflow detail → `CONTRIBUTING.md`
- Security policy → `SECURITY.md`

## Source Attribution

The four principles section above is drawn from:

- Andrej Karpathy — public observations on LLM coding behavior (March 2025 thread).
- Forrest Chang's `forrestchang/andrej-karpathy-skills` repository, which codified them as a CLAUDE.md.
- Anthropic's official "Best practices for Claude Code" — https://code.claude.com/docs/en/best-practices.

When in doubt, the source documents win over our interpretation.
````

- [ ] **Step 2: Verify**

Run:
```bash
grep -c "M2" CLAUDE.md
grep "Current Focus" CLAUDE.md
grep "osascript" CLAUDE.md && echo "STILL MENTIONS OSASCRIPT" || echo "OK"
```

Expected: M2 mentions only in "Current Focus: M1" framing context (≤ 3); "Current Focus" section present; osascript not mentioned.

### Task 4.6: Update `docs/01-PROJECT.md` (30 days, 1GB workaround, prototype canonical)

**Files:**
- Modify: `docs/01-PROJECT.md`

- [ ] **Step 1: Update the Milestones table**

Find:
```markdown
| Milestone | Scope summary | Value | Duration |
|---|---|---|---|
| **M1** | Server (DigitalOcean), GraphHopper, landing page, backend auth API, repo handoff | BRL 2,000 | 14 days |
| **M2** | Android APK with all features (OCR, voice, "sentido casa" optimization, paywall, Pix Split, partner dashboard, share/QR) | BRL 2,000 | 14 days |
```

Replace with:
```markdown
| Milestone | Scope summary | Value | Duration |
|---|---|---|---|
| **M1** | Server (DigitalOcean 1GB workaround), GraphHopper SP-only, landing page, backend auth API + healthchecks, Login + Register screens in Flutter | BRL 2,000 | 30 days (accepted 2026-04-26, deadline 2026-05-26) |
| **M2 (post-M1)** | Scope to be reconfirmed with client after M1 acceptance. Original Workana M2: Android APK, OCR, voice, "sentido casa" optimization, paywall, Pix Split via Efí Bank, partner dashboard, share/QR. | BRL 2,000 | TBD |
```

- [ ] **Step 2: Update the Constraints section**

Find:
```markdown
- **Time:** 14 days per milestone.
- **Budget:** BRL 4,000 total (paid via Workana escrow, milestone-based).
- **Operational cost target:** Per-subscription routing cost must be effectively zero (hence GraphHopper self-hosted, not Google Maps API).
- **Distribution:** APK direct download. Play Store is out of scope.
- **Geography:** V1 covers Sudeste Brazil (São Paulo, Rio de Janeiro, Minas Gerais, Espírito Santo). Other regions added later by re-importing PBFs.
- **Legal:** Must comply with LGPD (Brazilian data protection law). Must not infringe Circuit's IP.
```

Replace with:
```markdown
- **Time:** 30 days per milestone. M1 deadline: 2026-05-26.
- **Budget:** BRL 4,000 total (paid via Workana escrow, milestone-based). M1 escrow already deposited.
- **Operational cost target:** Per-subscription routing cost must be effectively zero (hence GraphHopper self-hosted, not Google Maps API).
- **Distribution:** APK direct download. Play Store is out of scope.
- **Geography:** V1 covers Sudeste Brazil. M1 ships with São Paulo state only on a 1GB droplet (workaround agreed with the client because of his temporary card limitation). Resize to 8GB + reimport of full Sudeste (SP+RJ+MG+ES) is post-M1.
- **Server titularity:** DigitalOcean account is the client's. Eduardo has admin access.
- **UI source of truth:** the approved prototype at `prototipo/` is canonical for visual identity, screens, gestures, and flows.
- **Legal:** Must comply with LGPD (Brazilian data protection law). Must not infringe Circuit's IP.
```

- [ ] **Step 3: Update the Out of Scope (V1) section**

Find:
```markdown
## Out of Scope (V1)

These are explicit non-goals for the BRL 4,000 contract:

- iOS app.
- Play Store publication.
- Multi-language support (PT-BR only).
- Multi-tier pricing (single tier only).
- Credit card payments (Pix only).
- Geographic coverage beyond Sudeste.
- Real-time GPS tracking / dispatch features.
- Multi-rider team management.
```

Replace with:
```markdown
## Out of Scope

### For the BRL 4,000 contract overall

- iOS app.
- Play Store publication.
- Multi-language support (PT-BR only).
- Multi-tier pricing (single tier only).
- Credit card payments (Pix only).
- Geographic coverage beyond Sudeste.
- Real-time GPS tracking / dispatch features.
- Multi-rider team management.

### For M1 specifically (deferred to M2 / post-M1)

- All M2 features (F02–F13 in `docs/04-FEATURES.md`): OCR, voice, route optimization (real algorithm), paywall, Pix Split, real-time subscriber counter, share/QR, admin panel, APK build, sentido casa.
- 17 of the 19 prototype screens — only Login (01) and Register (02) are in M1.
- LGPD endpoints (data export, deletion).
- Privacy policy page on landing.
- CI/CD pipeline (linter + tests on PR).
```

- [ ] **Step 4: Verify**

Run:
```bash
grep "30 days" docs/01-PROJECT.md
grep "1GB" docs/01-PROJECT.md
grep "client's account" docs/01-PROJECT.md
grep "prototipo" docs/01-PROJECT.md
```

Expected: each command returns at least one match.

### Task 4.7: Update `docs/02-ARCHITECTURE.md` (M1/M2 split + prototype callout)

**Files:**
- Modify: `docs/02-ARCHITECTURE.md`

- [ ] **Step 1: Add a callout at the top, right after `# 02 — Architecture`**

Find:
```markdown
# 02 — Architecture

## Overview
```

Replace with:
```markdown
# 02 — Architecture

> **UI source of truth:** the approved Claude Design prototype at `prototipo/` is canonical for screens, visual identity, gestures, and flows. `docs/05-SCREENS.md` mirrors the prototype's structure; `docs/06-DESIGN-SYSTEM.md` mirrors `prototipo/tokens.js`.
> **Current scope:** M1. Sections describing M2 endpoints, payment flow, and webhooks are **reference-only** for post-M1 work.

## Overview
```

- [ ] **Step 2: Update the "M2 endpoints (preview)" header**

Find:
```markdown
### M2 endpoints (preview)
```

Replace with:
```markdown
### M2 endpoints (post-M1, reference-only)

> Not implemented in M1. Listed here for reference; scope reconfirmed with client after M1 acceptance.
```

- [ ] **Step 3: Update the Mobile component description**

Find:
```markdown
### Mobile (Flutter — M2)
```

Replace with:
```markdown
### Mobile (Flutter — M1 partial, M2 full)

**M1 scope:** Login + Register screens (2 of 19). Backed by the M1 backend auth endpoints.
**M2 scope:** the remaining 17 prototype screens. Reconfirmed with client after M1.
```

- [ ] **Step 4: Verify**

Run:
```bash
grep "UI source of truth" docs/02-ARCHITECTURE.md
grep "post-M1, reference-only" docs/02-ARCHITECTURE.md
```

Expected: both grep commands return a match.

### Task 4.8: Update `docs/03-CONVENTIONS.md` (prototipo/ in directory layout)

**Files:**
- Modify: `docs/03-CONVENTIONS.md`

- [ ] **Step 1: Update the directory layout block**

Find:
```markdown
[APP] - Entrega Smart/
├── apps/
│   ├── mobile/        # Flutter app
│   ├── backend/       # Fastify API
│   ├── landing/       # roteirizadorpro.com.br
│   └── admin/         # Partners' admin panel
├── packages/          # shared libs, if any (only when needed — YAGNI)
├── infra/             # docker-compose, server provisioning, GraphHopper
├── docs/              # documentation (this folder)
└── scripts/           # repo-level utility scripts
```

Replace with:
```markdown
[APP] - Entrega Smart/
├── apps/
│   ├── mobile/        # Flutter app
│   ├── backend/       # Fastify API
│   └── landing/       # roteirizadorpro.com.br
├── infra/             # docker-compose, server provisioning, GraphHopper
├── docs/              # documentation (this folder)
├── prototipo/         # canonical UI source (Claude Design prototype, client-approved) — referenced, never imported
└── scripts/           # repo-level utility scripts
```

- [ ] **Step 2: Verify**

Run:
```bash
grep "prototipo/" docs/03-CONVENTIONS.md
grep "admin/" docs/03-CONVENTIONS.md && echo "STILL MENTIONS admin" || echo "OK"
```

Expected: prototipo/ matched; admin/ not matched (or only in unrelated context).

### Task 4.9: Update `docs/07-INFRA.md` (provisioned status, no transfer mechanics)

**Files:**
- Modify: `docs/07-INFRA.md`

- [ ] **Step 1: Update the DigitalOcean header section**

Find:
```markdown
## DigitalOcean

**Account status:** Active. Eduardo has owner-level access.
**Droplet status:** Not yet created. Must be provisioned before Sprint 1 begins.
```

Replace with:
```markdown
## DigitalOcean

**Account status:** Active. **Account is the client's.** Eduardo has admin access (granted via DO Team).
**Droplet status:** Provisioned. 1GB plan (workaround agreed with client because of his temporary card limitation). Resize to 8GB is post-M1.
**Droplet IPv4:** `<TO BE FILLED — Eduardo updates here once SSH'd in>`
**Hostname:** `roteirizador-pro`
**Region:** São Paulo (preferred) or NYC3 (fallback)
```

- [ ] **Step 2: Remove the "Droplet to provision" subsection — it is no longer applicable**

Find:
```markdown
### Droplet to provision (Sprint 0 action)
```

Delete the entire `### Droplet to provision` subsection through to (but not including) the next `###`. (The first-login sequence section that comes next is preserved.)

- [ ] **Step 3: Remove "Ownership transfer" subsection from Vercel**

Find:
```markdown
### Ownership transfer (end of M1)

At handoff, transfer the Vercel project to the client:

1. Vercel → Project → Settings → Transfer Project.
2. Enter client's Vercel account email.
3. Client accepts the transfer invitation.
4. Eduardo remains as a team member (collaborator) if ongoing support is agreed.
```

Delete the entire `### Ownership transfer (end of M1)` subsection (including its bullet list).

- [ ] **Step 4: Update the Secrets Inventory section header**

Find:
```markdown
## Secrets Inventory
```

Replace with:
```markdown
## Secrets Inventory (M1)

> Only M1-relevant secrets are listed. M2 secrets (Efí `.p12`, Efí client secrets, HMAC) come during M2 work.
```

And in that table, **delete** these rows (M2-only):
```
| Efi Bank `.p12` certificate | `/opt/roteirizador/certs/efi-prod.p12` | Eduardo + client |
| Efi Client ID | `.env` on server | Eduardo + client |
| Efi Client Secret | `.env` on server | Eduardo + client |
| Efi webhook HMAC secret | `.env` on server | Eduardo + client |
```

- [ ] **Step 5: Remove "What to Do Next → At M1 handoff" section**

Find:
```markdown
### At M1 handoff

- [ ] Confirm client has DigitalOcean owner access.
- [ ] Transfer Vercel project to client.
- [ ] Transfer GitHub repo to client.
- [ ] Record Loom video covering the four M1 approval criteria.
```

Delete the entire `### At M1 handoff` subsection.

- [ ] **Step 6: Verify**

Run:
```bash
grep -i "transfer" docs/07-INFRA.md && echo "STILL MENTIONS TRANSFER" || echo "OK"
grep "client's" docs/07-INFRA.md
grep "1GB" docs/07-INFRA.md
```

Expected: no `transfer` matches; "client's" matched; 1GB matched.

### Task 4.10: Update `docs/09-DISASTER-RECOVERY.md` (link fixes)

**Files:**
- Modify: `docs/09-DISASTER-RECOVERY.md`

- [ ] **Step 1: Fix internal links if any reference old paths**

Run:
```bash
grep -n "06-DISASTER\|FEATURES\.md\|SCREENS\.md\|DESIGN-SYSTEM\.md\|INFRA-ACCESS\|DESIGN-PROMPT\|ROADMAP-M" docs/09-DISASTER-RECOVERY.md
```

For each match, update the path to its new location:
- `docs/04-ROADMAP-M1.md`, `docs/04-ROADMAP-M2.md` → `docs/08-ROADMAP.md`
- `docs/06-DISASTER-RECOVERY.md` → `docs/09-DISASTER-RECOVERY.md`
- `docs/FEATURES.md` → `docs/04-FEATURES.md`
- `docs/SCREENS.md` → `docs/05-SCREENS.md`
- `docs/DESIGN-SYSTEM.md` → `docs/06-DESIGN-SYSTEM.md`
- `docs/INFRA-ACCESS.md` → `docs/07-INFRA.md`
- `docs/DESIGN-PROMPT.md` → DELETE the reference (file is being deleted)

If no matches, no edits needed.

- [ ] **Step 2: Verify**

Run:
```bash
grep -n "06-DISASTER\|FEATURES\.md\|SCREENS\.md\|DESIGN-SYSTEM\.md\|INFRA-ACCESS\|DESIGN-PROMPT\|ROADMAP-M" docs/09-DISASTER-RECOVERY.md && echo "STALE PATHS REMAIN" || echo "OK"
```

Expected: `OK`.

### Task 4.11: Update `README.md`

**Files:**
- Rewrite: `README.md`

- [ ] **Step 1: Replace `README.md` with this content**

````markdown
# Roteirizador Pro

Android route-planning app for delivery riders, distributed as APK from `roteirizadorpro.com.br`. Functional fork of [Spoke/Circuit Route Planner](https://getcircuit.com) with original visual identity, self-hosted infrastructure, and a planned 50/50 partner revenue split via Pix.

## Status

🟡 **In active development — Milestone 1**

| Milestone | Scope | Status |
|---|---|---|
| **M1** (BRL 2,000 / 30 days, deadline 2026-05-26) | Server (DO 1GB), landing page, backend auth API + healthchecks, GraphHopper SP graph, Login + Register Flutter screens | In progress |
| **M2** (BRL 2,000) | Post-M1 — scope to be reconfirmed with client. Original brief: Android APK, OCR/voice/optimization, Pix Split, paywall, admin panel | Not started |

Detailed roadmap: [`docs/08-ROADMAP.md`](./docs/08-ROADMAP.md).

## Architecture (one-liner)

Flutter app → Fastify API on DigitalOcean → GraphHopper (self-hosted) + PostgreSQL + Redis → Efí Bank Pix for subscriptions (M2).

Detail: [`docs/02-ARCHITECTURE.md`](./docs/02-ARCHITECTURE.md).

## UI source of truth

The Claude Design prototype at [`prototipo/`](./prototipo/) is the **canonical UI source** — client-approved 2026-05-07. Visual identity, screens, gestures, and flows must match it 1:1.

Documentation: [`docs/05-SCREENS.md`](./docs/05-SCREENS.md), [`docs/06-DESIGN-SYSTEM.md`](./docs/06-DESIGN-SYSTEM.md).

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile | Flutter + Riverpod 3 |
| Backend | Node.js 20 + Fastify v5 + TypeBox |
| ORM / DB | Prisma 7 + PostgreSQL 16 |
| Cache | Redis 7 |
| Routing engine | GraphHopper (self-hosted, motorcycle profile) |
| Payments (M2) | Efí Bank API Pix v2 (mTLS, Split) |
| Landing | Next.js 14 on Vercel |
| Server | Ubuntu 24.04 on DigitalOcean (client's account) |

Locked versions and rationale: [`docs/decisions/`](./docs/decisions/).

## Repository Structure

```
.
├── CLAUDE.md                # Operating manual for AI agents (READ FIRST)
├── CONTRIBUTING.md          # Git workflow, commit format, branching
├── README.md                # You are here
├── SECURITY.md              # Security policy
├── TODO.md                  # Active M1 task list
├── apps/
│   ├── backend/             # Fastify API
│   ├── landing/             # Next.js landing page
│   └── mobile/              # Flutter app (auth screens for M1)
├── infra/                   # docker-compose, server provisioning
├── prototipo/               # Canonical UI source (Claude Design)
├── docs/
│   ├── 01-PROJECT.md
│   ├── 02-ARCHITECTURE.md
│   ├── 03-CONVENTIONS.md
│   ├── 04-FEATURES.md
│   ├── 05-SCREENS.md
│   ├── 06-DESIGN-SYSTEM.md
│   ├── 07-INFRA.md
│   ├── 08-ROADMAP.md
│   ├── 09-DISASTER-RECOVERY.md
│   ├── 10-CHANGELOG.md
│   ├── decisions/           # ADRs
│   ├── sessions/            # AI session logs
│   └── superpowers/         # Specs and plans
└── scripts/                 # Repo-level utilities
```

## For AI Agents

If you are an AI agent (Claude Code, Cursor, Claude web), **start by reading [`CLAUDE.md`](./CLAUDE.md) in full**. It is the operating manual for this repository.

## For Humans

- Project owner: Eduardo Rodrigues — `eduardo@ianelli.tech`
- Workana proposal: M1 + M2 = BRL 4,000 (escrow, milestone-based)

## License

Proprietary. All rights reserved by the project owner and the client.
````

- [ ] **Step 2: Verify**

Run:
```bash
grep "prototipo" README.md
grep "08-ROADMAP" README.md
grep "transfer\|handoff" README.md && echo "STILL MENTIONS TRANSFER/HANDOFF" || echo "OK"
```

Expected: prototipo and 08-ROADMAP both match; no transfer/handoff matches.

### Task 4.12: Update `CONTRIBUTING.md`

**Files:**
- Modify: `CONTRIBUTING.md`

- [ ] **Step 1: Delete the "Mac Workflow (osascript)" section entirely**

Find:
```markdown
## Mac Workflow (osascript)

All Git operations on the Mac are executed by AI agents via the `Control your Mac:osascript` tool. Never paste shell commands for the human to run manually.

```applescript
do shell script "cd '/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart' && git status"
```

The repo path contains spaces and brackets. Always single-quote the path inside `do shell script`.
```

Delete this section completely (including the heading and code block).

- [ ] **Step 2: Verify**

Run:
```bash
grep -i "osascript" CONTRIBUTING.md && echo "STILL MENTIONS OSASCRIPT" || echo "OK"
grep -i "transfer\|handoff" CONTRIBUTING.md && echo "STILL MENTIONS TRANSFER/HANDOFF" || echo "OK"
```

Expected: both print `OK`.

### Task 4.13: Update `SECURITY.md` link

**Files:**
- Modify: `SECURITY.md`

- [ ] **Step 1: Fix the disaster-recovery link**

Find:
```
docs/06-DISASTER-RECOVERY.md
```

Replace with:
```
docs/09-DISASTER-RECOVERY.md
```

- [ ] **Step 2: Verify**

Run:
```bash
grep "09-DISASTER" SECURITY.md
grep "06-DISASTER" SECURITY.md && echo "STALE LINK" || echo "OK"
```

Expected: 09-DISASTER matched; 06-DISASTER not matched.

### Task 4.14: Commit Phase 4

- [ ] **Step 1: Stage and commit**

Run:
```bash
git add docs/05-SCREENS.md docs/06-DESIGN-SYSTEM.md docs/04-FEATURES.md TODO.md CLAUDE.md docs/01-PROJECT.md docs/02-ARCHITECTURE.md docs/03-CONVENTIONS.md docs/07-INFRA.md docs/09-DISASTER-RECOVERY.md README.md CONTRIBUTING.md SECURITY.md
git commit -m "docs(rewrite): align with approved prototype and M1 focus"
```

---

## Phase 5 — Delete obsolete files

### Task 5.1: Delete obsolete docs and folders

**Files to delete:**
- `agents.md`
- `CODE_OF_CONDUCT.md`
- `docs/DESIGN-PROMPT.md`
- `docs/04-ROADMAP-M1.md`
- `docs/04-ROADMAP-M2.md`
- `apps/admin/` (entire folder)

- [ ] **Step 1: Remove with `git rm`**

Run:
```bash
git rm agents.md CODE_OF_CONDUCT.md docs/DESIGN-PROMPT.md docs/04-ROADMAP-M1.md docs/04-ROADMAP-M2.md
git rm -r apps/admin/
```

- [ ] **Step 2: Verify**

Run:
```bash
test ! -f agents.md && echo "OK"
test ! -f CODE_OF_CONDUCT.md && echo "OK"
test ! -f docs/DESIGN-PROMPT.md && echo "OK"
test ! -f docs/04-ROADMAP-M1.md && echo "OK"
test ! -f docs/04-ROADMAP-M2.md && echo "OK"
test ! -d apps/admin && echo "OK"
```

Expected: 6 lines of `OK`.

- [ ] **Step 3: Commit**

Run:
```bash
git commit -m "docs(cleanup): remove obsolete files (agents.md, design-prompt, code-of-conduct, old roadmaps)"
```

---

## Phase 6 — Session log

### Task 6.1: Write session log

**Files:**
- Create: `docs/sessions/2026-05-07-04-docs-cleanup.md`

- [ ] **Step 1: Write the session log**

Create `docs/sessions/2026-05-07-04-docs-cleanup.md` with this content:

````markdown
# Session 2026-05-07-04 — docs-cleanup

## Metadata

- **Date**: 2026-05-07 (America/Sao_Paulo)
- **Sequence**: 04
- **Agent**: Claude Code
- **Human**: Eduardo
- **Topic**: Documentation reorganization and M1 alignment
- **Duration**: ~3h
- **Related ADRs**: none new (deferred)
- **Related TODO items**: M1 entire scope (this session unblocks it)

## Goal of the Session

Realign the entire documentation with three goals:
1. Remove ambiguities, duplications, and obsolete content from the docs.
2. Make the approved Claude Design prototype (`prototipo/`) the canonical UI source.
3. Focus the roadmap on M1 (deadline 2026-05-26) so the next concrete action is `flutter create apps/mobile/`.

## What Was Done

- Audited all 30 docs/markdown files in the repo. Identified ambiguities and outdated references.
- Wrote a design spec at `docs/superpowers/specs/2026-05-07-docs-cleanup-design.md` and got user approval.
- Wrote an implementation plan at `docs/superpowers/plans/2026-05-07-docs-cleanup.md`.
- Tracked the approved prototype in git (`prototipo/`).
- Renamed docs to contiguous numbering (`FEATURES.md` → `04-FEATURES.md`, etc.).
- Moved `logo.png` into `apps/landing/public/`.
- Created `docs/08-ROADMAP.md` (M1-focused) and `docs/10-CHANGELOG.md`.
- Rewrote `docs/05-SCREENS.md` to match the 19 prototype screens with M1/M2 tagging.
- Updated `docs/06-DESIGN-SYSTEM.md` with the `neon` token family from `prototipo/tokens.js`.
- Updated `docs/04-FEATURES.md` status column to mark M1 vs M2 (post-M1).
- Rewrote `TODO.md` as M1-only with 4 phases (Foundations, Features, Deploy, Acceptance).
- Rewrote `CLAUDE.md` to add a "Current Focus: M1" framing, drop osascript noise, and point to the new docs structure.
- Updated `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, `docs/07-INFRA.md`, `docs/09-DISASTER-RECOVERY.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`.
- Deleted obsolete files: `agents.md`, `CODE_OF_CONDUCT.md`, `docs/DESIGN-PROMPT.md`, `docs/04-ROADMAP-M1.md`, `docs/04-ROADMAP-M2.md`, `apps/admin/`.

## Decisions Made

1. **M2 scope deferred until post-M1** — no ADR yet because the conversation with the client hasn't happened. ADR-0011 will be added when M2 scope is reconfirmed.
2. **Prototype is canonical** for visual identity, screens, gestures, flows. `prototipo/tokens.js` wins over `docs/06-DESIGN-SYSTEM.md` if they disagree.
3. **DO server titularity stays with the client** — Eduardo has admin access. Documentation no longer references "transfer" or "handoff" mechanics; those interactions stay outside docs.
4. **1GB droplet workaround is the M1 reality**, not a footnote. Resize + Sudeste reimport is post-M1.

## Open Questions Left

- [ ] Droplet IPv4 — Eduardo to fill in `docs/07-INFRA.md` once SSH'd in.
- [ ] Vercel project name and staging URL — Eduardo to fill in `docs/07-INFRA.md`.
- [ ] M2 scope conversation with client — happens after M1 acceptance.

## Files Changed

**Created**:
- `docs/superpowers/specs/2026-05-07-docs-cleanup-design.md`
- `docs/superpowers/plans/2026-05-07-docs-cleanup.md`
- `docs/08-ROADMAP.md`
- `docs/10-CHANGELOG.md`
- `docs/sessions/2026-05-07-04-docs-cleanup.md` (this file)

**Renamed**:
- `docs/FEATURES.md` → `docs/04-FEATURES.md`
- `docs/SCREENS.md` → `docs/05-SCREENS.md`
- `docs/DESIGN-SYSTEM.md` → `docs/06-DESIGN-SYSTEM.md`
- `docs/INFRA-ACCESS.md` → `docs/07-INFRA.md`
- `docs/06-DISASTER-RECOVERY.md` → `docs/09-DISASTER-RECOVERY.md`

**Modified**:
- `CLAUDE.md`, `TODO.md`, `README.md`, `CONTRIBUTING.md`, `SECURITY.md`
- `docs/01-PROJECT.md`, `docs/02-ARCHITECTURE.md`, `docs/03-CONVENTIONS.md`, `docs/04-FEATURES.md`, `docs/05-SCREENS.md`, `docs/06-DESIGN-SYSTEM.md`, `docs/07-INFRA.md`, `docs/09-DISASTER-RECOVERY.md`

**Moved**:
- `logo.png` → `apps/landing/public/logo.png`

**Deleted**:
- `agents.md`
- `CODE_OF_CONDUCT.md`
- `docs/DESIGN-PROMPT.md`
- `docs/04-ROADMAP-M1.md`
- `docs/04-ROADMAP-M2.md`
- `apps/admin/`

**Tracked (was untracked)**:
- `prototipo/` (entire directory)

## Commits Pushed

To be filled by executor at end of session.

## Hand-off Notes for Next Session

Next concrete action: **`flutter create apps/mobile/`** — the first task in `TODO.md` Phase 1. The repo is now clean and aligned for M1 development. Read `CLAUDE.md`, `TODO.md`, and `docs/08-ROADMAP.md` before starting.

## Reference Material Used

- The approved prototype: `prototipo/` (reviewed `Roteirizador Pro.html`, `tokens.js`, `screens-a.jsx` to extract the 19 screens and the design tokens).
- Workana proposal text and client conversation (provided by user during session) — confirmed scope: 30 days for M1, 1GB droplet workaround, server titularity with client, payment gateway switched to Efí Bank.
````

- [ ] **Step 2: Verify**

Run:
```bash
test -f docs/sessions/2026-05-07-04-docs-cleanup.md && echo "OK"
grep -c "^## " docs/sessions/2026-05-07-04-docs-cleanup.md
```

Expected: `OK`, then a number ≥ 8 (sections: Metadata, Goal, What Was Done, Decisions Made, Open Questions, Files Changed, Commits Pushed, Hand-off Notes, Reference Material).

### Task 6.2: Update session index

**Files:**
- Modify: `docs/sessions/0001-INDEX.md`

- [ ] **Step 1: Append entry**

Find:
```markdown
## Sessions

- [2026-05-05-03 — documentation-backbone](./2026-05-05-03-documentation-backbone.md) — Authored full documentation backbone: foundation files, README, TODO, SECURITY, CODE_OF_CONDUCT, PR template, ten ADRs, and 01-PROJECT / 02-ARCHITECTURE / 04-ROADMAP-M1 / 04-ROADMAP-M2 / 06-DISASTER-RECOVERY docs.
```

Replace with:
```markdown
## Sessions

- [2026-05-07-04 — docs-cleanup](./2026-05-07-04-docs-cleanup.md) — Realigned the docs with the approved Claude Design prototype, focused the roadmap on M1 (deadline 2026-05-26), removed redundant/obsolete files, renumbered to contiguous order, established prototype as canonical UI source.
- [2026-05-05-03 — documentation-backbone](./2026-05-05-03-documentation-backbone.md) — Authored full documentation backbone: foundation files, README, TODO, SECURITY, CODE_OF_CONDUCT, PR template, ten ADRs, and 01-PROJECT / 02-ARCHITECTURE / 04-ROADMAP-M1 / 04-ROADMAP-M2 / 06-DISASTER-RECOVERY docs.
```

- [ ] **Step 2: Verify**

Run:
```bash
grep "2026-05-07-04" docs/sessions/0001-INDEX.md
```

Expected: matches the new entry.

### Task 6.3: Commit Phase 6

- [ ] **Step 1: Stage and commit**

Run:
```bash
git add docs/sessions/2026-05-07-04-docs-cleanup.md docs/sessions/0001-INDEX.md docs/superpowers/plans/2026-05-07-docs-cleanup.md
git commit -m "docs(sessions): add 2026-05-07-04 docs cleanup"
```

---

## Phase 7 — Final verification

### Task 7.1: Run all spec verification checks

**Files:**
- Read-only verification

- [ ] **Step 1: No dangling references**

Run:
```bash
grep -rn "docs/06-DISASTER\|docs/FEATURES\.md\|docs/SCREENS\.md\|docs/DESIGN-SYSTEM\.md\|docs/INFRA-ACCESS\|docs/DESIGN-PROMPT\|docs/04-ROADMAP-M\|agents\.md\|CODE_OF_CONDUCT" --include='*.md' .
```

Expected: zero matches (or only matches in changelog/sessions describing the deletion as historical, which is OK).

- [ ] **Step 2: No "transfer" / "handoff" references in M1 docs**

Run:
```bash
grep -rn "transfer\|handoff" --include='*.md' README.md CLAUDE.md CONTRIBUTING.md docs/01-PROJECT.md docs/07-INFRA.md docs/08-ROADMAP.md
```

Expected: zero matches except possibly the historical mention in `docs/04-FEATURES.md` (M2 reference content) or `docs/sessions/`.

- [ ] **Step 3: Prototype tokens vs design system tokens**

Run:
```bash
grep "primary:" prototipo/tokens.js
grep "primary" docs/06-DESIGN-SYSTEM.md | head -5
grep "neon" docs/06-DESIGN-SYSTEM.md | head -5
```

Expected: matching `#6C3FC5` for primary; neon entries `#C6FF3D`, `#9BCC1F`, `#F1FFCC`, `#3D5400`.

- [ ] **Step 4: Prototype screen IDs vs SCREENS.md**

Run:
```bash
grep "AB('" "prototipo/Roteirizador Pro.html" | wc -l
grep -c "^| \`[a-z]" docs/05-SCREENS.md
```

Expected: 19 from prototype, ≥ 19 from SCREENS.md (one row per screen).

- [ ] **Step 5: TODO.md has only M1 work**

Run:
```bash
grep -i "M2\|front-only\|mock" TODO.md && echo "MAY HAVE M2 PLANNING" || echo "OK"
```

Expected: matches only in framing context (e.g., "M2 work begins in a fresh planning cycle"). No actual planned tasks for M2.

- [ ] **Step 6: README.md repository structure matches reality**

Run:
```bash
ls docs/*.md | sort
```

Expected:
```
docs/01-PROJECT.md
docs/02-ARCHITECTURE.md
docs/03-CONVENTIONS.md
docs/04-FEATURES.md
docs/05-SCREENS.md
docs/06-DESIGN-SYSTEM.md
docs/07-INFRA.md
docs/08-ROADMAP.md
docs/09-DISASTER-RECOVERY.md
docs/10-CHANGELOG.md
```

Compare to README "Repository Structure" — must match exactly.

- [ ] **Step 7: Git tree is clean**

Run:
```bash
git status
```

Expected: `nothing to commit, working tree clean`.

- [ ] **Step 8: Final commit log**

Run:
```bash
git log --oneline -10
```

Expected: shows the cleanup commits in order:
```
docs(sessions): add 2026-05-07-04 docs cleanup
docs(cleanup): remove obsolete files (agents.md, design-prompt, code-of-conduct, old roadmaps)
docs(rewrite): align with approved prototype and M1 focus
docs(roadmap): add M1-focused roadmap and changelog
chore(landing): move logo to landing public assets
docs(structure): renumber and rename for contiguous order
docs(prototype): track approved Claude Design prototype as canonical UI source
docs(spec): add M1-focused docs cleanup design spec
... earlier commits ...
```

---

## End-of-plan summary

After completing all phases:
- Total commits: ~7 themed commits.
- Files created: ~5.
- Files renamed: 5.
- Files modified: ~13.
- Files deleted: 5.
- Folders deleted: 1 (`apps/admin/`).
- Logo moved: 1.

The repo is now M1-focused, prototype-aligned, and ready for `flutter create apps/mobile/`.
