# Blueprint — Roteirizador Pro

> **Generated:** 2026-05-08
> **Source:** synthesized from 11 ADRs (`docs/decisions/0001-0010`) and project docs (`docs/01–10`). This is **not** a fresh stack-selection exercise — it is a contract document for the next two skills (`saas-project-scaffold`, `saas-project-foundation`) so they consume one canonical reference instead of 11 ADRs.
> **Authority:** ADRs win in any disagreement. If this Blueprint contradicts an ADR, the ADR is correct and this file is stale.

---

## 1. Project Summary

| Field | Value |
|---|---|
| Type | Mobile-first subscription SaaS (B2C) — Android route planner |
| Distribution | APK direct download from `roteirizadorpro.com.br` (no Play Store in V1) |
| Public | Independent Brazilian delivery riders (motoboys), Sudeste region |
| Pricing | Single tier: R$ 25,90 grants 30 days of access (no recurring billing — each renewal is a fresh manual Pix payment) |
| Payment | Pix only via Stripe + Stripe Connect 50/50 split (Separate Charges and Transfers) between two business partners — [ADR-0030](decisions/0030-stripe-pix-30-day-access-pass.md) |
| Positioning | Functional fork of Spoke/Circuit Route Planner with 100% original visual identity ([ADR-0010](decisions/0010-clone-positioning.md)) |
| Current milestone | **M1** (deadline 2026-05-26): server, GraphHopper SP-only, landing, backend auth API, Flutter Login + Register |
| Next milestone | M2 (post-M1, scope to reconfirm with client) — full feature set per [docs/04-FEATURES.md](04-FEATURES.md) |
| Constraints | LGPD compliance; no IP infringement of Circuit; per-route routing cost ≈ R$ 0; 1GB droplet on M1 (workaround agreed with client); 30-day milestone deadline |
| UI source of truth | [`prototipo/`](../prototipo/) — Claude Design prototype, client-approved 2026-05-07 |

---

## 2. Stack Decisions

| Layer | Choice | Version | Source ADR |
|---|---|---|---|
| Mobile runtime | Flutter | stable channel | [0002](decisions/0002-flutter-mobile.md) |
| Mobile state | Riverpod 3 (`@riverpod` codegen) | 3.0.2+ | [0005](decisions/0005-riverpod-3-state.md) |
| Backend runtime | Node.js | 20 LTS | [0003](decisions/0003-fastify-backend.md) |
| Backend framework | Fastify | v5 | [0003](decisions/0003-fastify-backend.md) |
| Backend type provider | TypeBox (`@sinclair/typebox`) | latest | [0006](decisions/0006-typebox-validation.md) |
| ORM | Prisma + `@prisma/adapter-pg` | 7.6+ | [0004](decisions/0004-prisma-7-orm.md) |
| Database | PostgreSQL | 16 | [0009](decisions/0009-postgresql-database.md) |
| Cache / pub-sub | Redis | 7 | [02-ARCHITECTURE.md](02-ARCHITECTURE.md) |
| Routing engine | GraphHopper self-hosted (motorcycle profile, CH) | latest official Docker image | [0008](decisions/0008-graphhopper-routing.md) |
| Payment gateway | Stripe Pix + Stripe Connect (Separate Charges and Transfers, official Node SDK) | latest | [0030](decisions/0030-stripe-pix-30-day-access-pass.md) (supersedes [0007](decisions/0007-efi-bank-payment.md)) |
| Landing | Next.js 14 (App Router) + Tailwind | 14.x | [0001](decisions/0001-monorepo-structure.md), [04-FEATURES.md F14](04-FEATURES.md) |
| Repo structure | Monorepo (`apps/{mobile,backend,landing,admin}`) | — | [0001](decisions/0001-monorepo-structure.md) |
| Server OS | Ubuntu | 24.04 | [07-INFRA.md](07-INFRA.md) |
| Container runtime | Docker + docker-compose | latest stable | [07-INFRA.md](07-INFRA.md) |
| Auth | JWT custom (RS256), bcrypt cost 12, refresh rotation | — | [04-FEATURES.md F01](04-FEATURES.md), [02-ARCHITECTURE.md](02-ARCHITECTURE.md) |
| Lint / format | ESLint + Prettier (TS); `dart format` (Flutter) | latest | [03-CONVENTIONS.md](03-CONVENTIONS.md) |
| Commit convention | Conventional Commits | — | [CONTRIBUTING.md](../CONTRIBUTING.md) |

**Versions are pinned in the ADRs at decision time (2026-05-05). Re-validation against Context7 will happen at scaffold time, when libraries are actually installed — not now.**

---

## 3. Rejected Alternatives

For every opinionated layer, alternatives that were considered and rejected. Pulled from the "Options Considered" sections of each ADR.

| Layer | Rejected | Why rejected |
|---|---|---|
| Mobile | React Native (Expo) | Bridge model still costlier for animations after Fabric/TurboModules; OCR options community-maintained with breakage history; APK distribution outside Play Store costs more friction (EAS paid past free tier); larger binaries. ([ADR-0002](decisions/0002-flutter-mobile.md)) |
| State management | Bloc | Verbose events+states pattern; higher boilerplate than Riverpod for our scale. ([ADR-0005](decisions/0005-riverpod-3-state.md)) |
| State management | Provider (original) | BuildContext-tied; no compile-time safety; legacy by 2026. ([ADR-0005](decisions/0005-riverpod-3-state.md)) |
| State management | GetX | Mixes routing/DI/state in anti-pattern ways; community sentiment shifted away. ([ADR-0005](decisions/0005-riverpod-3-state.md)) |
| Backend | NestJS | Decorator/DI overhead overkill for ~20 endpoints; performance below Fastify. ([ADR-0003](decisions/0003-fastify-backend.md)) |
| Backend | Express | No TS-first design; no built-in validation; legacy by 2026. ([ADR-0003](decisions/0003-fastify-backend.md)) |
| Backend | Python + FastAPI | Asymmetry with Flutter; the chosen payment gateway (now Stripe per ADR-0030) has first-class SDKs in both ecosystems so no language-savings argument either way. ([ADR-0003](decisions/0003-fastify-backend.md)) |
| Validation | Hand-written JSON Schema | Verbose; types must be hand-maintained; drift risk. ([ADR-0006](decisions/0006-typebox-validation.md)) |
| Validation | Zod with adapter | Not natively built for Fastify; slower at runtime than TypeBox; doesn't compile to JSON Schema natively (loses Fastify's serialization optimization). ([ADR-0006](decisions/0006-typebox-validation.md)) |
| ORM | Drizzle | Less mature; SQL-first style adds friction for the 80% of CRUD work. ([ADR-0004](decisions/0004-prisma-7-orm.md)) |
| ORM | TypeORM | TypeScript types weaker than Prisma's; project momentum decreased. ([ADR-0004](decisions/0004-prisma-7-orm.md)) |
| ORM | Raw SQL via `pg` | No type safety; manual migrations; reimplements partial ORM. ([ADR-0004](decisions/0004-prisma-7-orm.md)) |
| Database | MySQL / MariaDB | JSON support weaker; Prisma support less polished. ([ADR-0009](decisions/0009-postgresql-database.md)) |
| Database | SQLite | Single-writer concurrency limit; not suitable for multi-tenant SaaS. ([ADR-0009](decisions/0009-postgresql-database.md)) |
| Database | MongoDB | Subscriptions and payments demand transactional integrity, awkward in document stores. ([ADR-0009](decisions/0009-postgresql-database.md)) |
| Routing | Google Maps Directions / Distance Matrix API | Cost-prohibitive at scale (thousands of requests per active user/month). ([ADR-0008](decisions/0008-graphhopper-routing.md)) |
| Routing | Mapbox | Same cost concern as Google. ([ADR-0008](decisions/0008-graphhopper-routing.md)) |
| Routing | OSRM | Lower-level config; less mature motorcycle profile; smaller community than GraphHopper. ([ADR-0008](decisions/0008-graphhopper-routing.md)) |
| Routing | Valhalla | Heavier resource requirements; slower for static routes than GraphHopper with CH. ([ADR-0008](decisions/0008-graphhopper-routing.md)) |
| Payment | Mercado Pago Marketplace | More complex integration; higher fees; client's prior experience less favorable. ([ADR-0007](decisions/0007-efi-bank-payment.md)) |
| Payment | Primepag | **Rejected by client** due to poor support response times. ([ADR-0007](decisions/0007-efi-bank-payment.md)) |
| Payment | Stripe / Asaas / others | No native Pix Split or higher fees or smaller BR footprint. ([ADR-0007](decisions/0007-efi-bank-payment.md)) |
| Repo | Polyrepo (one per app) | Cross-cutting changes require coordinated PRs; shared types must be a separately published package. ([ADR-0001](decisions/0001-monorepo-structure.md)) |
| Positioning | Visual identity copy of Circuit | Direct copyright violation; trade dress claim risk; Workana ToS violation; client's marketing investment exposes them more. ([ADR-0010](decisions/0010-clone-positioning.md)) |
| Positioning | White-label off-the-shelf route planner | Defeats purpose of contract; no differentiation. ([ADR-0010](decisions/0010-clone-positioning.md)) |

---

## 4. Prisma Schema Sketch

Models derived from entities documented in [04-FEATURES.md](04-FEATURES.md) and [02-ARCHITECTURE.md](02-ARCHITECTURE.md). Conventions applied:

- UUID primary keys: `@id @default(uuid())`
- `createdAt` / `updatedAt` mandatory on every model
- `onDelete` mapped explicitly on every relation
- snake_case database tables/columns via `@map` / `@@map`
- No comments in schema (matches [03-CONVENTIONS.md](03-CONVENTIONS.md): "no comments in production code")

### M1 scope (backend ships these)

```prisma
model User {
  id            String         @id @default(uuid())
  email         String         @unique
  passwordHash  String         @map("password_hash")
  name          String
  phone         String?
  homeAddress   Json?          @map("home_address")
  createdAt     DateTime       @default(now()) @map("created_at")
  updatedAt     DateTime       @updatedAt @map("updated_at")
  refreshTokens RefreshToken[]
  subscriptions Subscription[]
  routes        Route[]

  @@map("users")
}

model RefreshToken {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  tokenHash String   @unique @map("token_hash")
  expiresAt DateTime @map("expires_at")
  revokedAt DateTime? @map("revoked_at")
  createdAt DateTime @default(now()) @map("created_at")
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@map("refresh_tokens")
}
```

### M2 scope (sketched here, not implemented in M1)

```prisma
model Subscription {
  id        String             @id @default(uuid())
  userId    String             @map("user_id")
  status    SubscriptionStatus
  startedAt DateTime           @map("started_at")
  expiresAt DateTime           @map("expires_at")
  createdAt DateTime           @default(now()) @map("created_at")
  updatedAt DateTime           @updatedAt @map("updated_at")
  user      User               @relation(fields: [userId], references: [id], onDelete: Cascade)
  payments  Payment[]

  @@index([userId, status])
  @@map("subscriptions")
}

enum SubscriptionStatus {
  active
  inactive
  pending
}

model Payment {
  id             String        @id @default(uuid())
  subscriptionId String        @map("subscription_id")
  txid           String        @unique
  amountCents    Int           @map("amount_cents")
  status         PaymentStatus
  e2eId          String?       @unique @map("e2e_id")
  paidAt         DateTime?     @map("paid_at")
  createdAt      DateTime      @default(now()) @map("created_at")
  updatedAt      DateTime      @updatedAt @map("updated_at")
  subscription   Subscription  @relation(fields: [subscriptionId], references: [id], onDelete: Restrict)

  @@map("payments")
}

enum PaymentStatus {
  pending
  paid
  expired
  failed
}

model Route {
  id              String   @id @default(uuid())
  userId          String   @map("user_id")
  totalDistanceM  Int?     @map("total_distance_m")
  totalDurationS  Int?     @map("total_duration_s")
  optimizedAt     DateTime? @map("optimized_at")
  createdAt       DateTime @default(now()) @map("created_at")
  updatedAt       DateTime @updatedAt @map("updated_at")
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  stops           Stop[]

  @@index([userId])
  @@map("routes")
}

model Stop {
  id          String   @id @default(uuid())
  routeId     String   @map("route_id")
  position    Int
  addressRaw  String   @map("address_raw")
  lat         Float
  lng         Float
  deliveredAt DateTime? @map("delivered_at")
  createdAt   DateTime @default(now()) @map("created_at")
  updatedAt   DateTime @updatedAt @map("updated_at")
  route       Route    @relation(fields: [routeId], references: [id], onDelete: Cascade)

  @@unique([routeId, position])
  @@map("stops")
}

model WebhookEvent {
  id          String   @id @default(uuid())
  source      String
  e2eId       String?  @unique @map("e2e_id")
  payload     Json
  receivedAt  DateTime @default(now()) @map("received_at")
  processedAt DateTime? @map("processed_at")

  @@index([source, receivedAt])
  @@map("webhook_events")
}
```

---

## 5. Monorepo Layout

Authoritative version: [03-CONVENTIONS.md](03-CONVENTIONS.md). Replicated here for the scaffold skill.

```
[APP] - Entrega Smart/
├── apps/
│   ├── mobile/        # Flutter app (Riverpod 3, @riverpod codegen)
│   ├── backend/       # Fastify v5 + Prisma 7 API
│   ├── landing/       # Next.js 14 + Tailwind on Vercel
│   └── admin/         # M2 only — partner dashboard (Next.js)
├── infra/             # docker-compose.yml, GraphHopper config, server provisioning
├── docs/              # canonical documentation (10 numbered + decisions/ + sessions/ + briefing/ + superpowers/)
├── prototipo/         # canonical for visual identity per ADR-0035 (tokens, colors, icons, animations) — referenced, never imported
└── scripts/           # repo-level utilities
```

Folders materialize incrementally. No empty placeholders. No `packages/` until a real shared-code need appears.

---

## 6. External Integrations

| Integration | Purpose | Milestone | Auth method | Detailed in |
|---|---|---|---|---|
| Stripe Pix + Stripe Connect | 30-day access pass payment + 50/50 auto-split (Separate Charges and Transfers) | M2 | API key (`STRIPE_SECRET_KEY`) + webhook signing secret (`STRIPE_WEBHOOK_SECRET`) | [ADR-0030](decisions/0030-stripe-pix-30-day-access-pass.md) |
| GraphHopper (self-hosted Docker) | Route optimization | M1 (infra) / M2 (full usage) | localhost-only, no external auth | [ADR-0008](decisions/0008-graphhopper-routing.md) |
| Geofabrik PBF | OpenStreetMap data source for GraphHopper | M1 (SP-only) / post-M1 (full Sudeste) | none (public download) | [07-INFRA.md](07-INFRA.md) |
| Vercel | Landing page hosting + DNS | M1 | Vercel CLI / dashboard | [07-INFRA.md](07-INFRA.md) |
| DigitalOcean | API + DB + GraphHopper droplet (client's account, Eduardo admin) | M1 (1GB) / post-M1 (8GB resize) | SSH + DO API | [07-INFRA.md](07-INFRA.md) |
| Nominatim | Geocoding (self-hosted or public — to confirm in ADR) | M2 | TBD | [04-FEATURES.md F02](04-FEATURES.md) |
| Waze deep-link | External navigation | M2 | none (intent-based) | [04-FEATURES.md F08](04-FEATURES.md) |
| Google Maps deep-link | External navigation | M2 | none (intent-based) | [04-FEATURES.md F08](04-FEATURES.md) |

**SDKs:** Stripe ships an official Node SDK (`stripe` npm package); the backend uses it directly per ADR-0030.

---

## 7. Docs Plan

The doc structure is **already complete** for M1. The scaffold skill should not regenerate these.

### Sempre (already exist)

| File | Purpose |
|---|---|
| [01-PROJECT.md](01-PROJECT.md) | Project vision, scope, milestones, stakeholders |
| [02-ARCHITECTURE.md](02-ARCHITECTURE.md) | Architecture, flows, schemas, contracts |
| [03-CONVENTIONS.md](03-CONVENTIONS.md) | Naming, code style, directory layout, testing convention |
| [04-FEATURES.md](04-FEATURES.md) | Features (canonical business rules, F01–F15) |
| [05-SCREENS.md](05-SCREENS.md) | Screens (prototype catalogue) |
| [06-DESIGN-SYSTEM.md](06-DESIGN-SYSTEM.md) | Design system (mirrors `prototipo/tokens.js`) |
| [07-INFRA.md](07-INFRA.md) | Infrastructure (DigitalOcean, Vercel, domains, secrets policy) |
| [08-ROADMAP.md](08-ROADMAP.md) | M1 roadmap and acceptance criteria |
| [09-DISASTER-RECOVERY.md](09-DISASTER-RECOVERY.md) | Backup, restore, incident response |
| [10-CHANGELOG.md](10-CHANGELOG.md) | Documentation changelog |

### Conditional (NOT to be created until justified)

| File | Trigger to create |
|---|---|
| `Integrations.md` (per skill 3 default) | Skipped — `07-INFRA.md` and per-feature sections in `04-FEATURES.md` already cover integrations. |
| `LGPD.md` | Post-M1, when LGPD endpoints are scoped (data export, deletion). |
| `Observability.md` | Post-M1, when Sentry / monitoring is added. |
| `Internationalization.md` | Never — pt-BR only is locked in [01-PROJECT.md](01-PROJECT.md) "Out of Scope". |

---

## 8. `.claude/` Plan

This project does **not** have a project-local `.claude/` directory. Reasons:

1. The user has global skills in `~/.claude/skills/` (including the three `saas-project-*` skills that produced this Blueprint).
2. The repo's [CLAUDE.md](../CLAUDE.md) is the operating manual for any agent — a project-local `.claude/skills/` would duplicate without adding signal.
3. Karpathy "Simplicity First" — adding a `.claude/` folder for one project before a concrete need exists is speculative.

**Trigger to create `.claude/skills/`:** if during M1 we identify a recurring agent task that the global skills don't cover (e.g., "scaffold-fastify-route", "add-prisma-model-with-migration"). Until then, no `.claude/`.

**Skills referenced (global, not in repo):**
- `superpowers:brainstorming` — design phase
- `superpowers:writing-plans` — plan phase
- `superpowers:using-superpowers` — meta-skill (always loaded)
- `saas-project-blueprint` (this) — already produced its output
- `saas-project-scaffold` — next phase (generates monorepo + stack)
- `saas-project-foundation` — third phase (AGENTS.md + docs/ + .claude/) — **likely skipped or heavily adapted** because docs/ is already complete

---

## 9. Commit Scopes

Conventional Commits scopes derived from the entities, integrations, and apps. Scope chooses one closest to the change. See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full Git workflow.

| Scope | Used for changes in |
|---|---|
| `mobile` | `apps/mobile/**` |
| `backend` | `apps/backend/**` |
| `landing` | `apps/landing/**` |
| `infra` | `infra/**`, server provisioning, Docker, GraphHopper |
| `auth` | JWT, bcrypt, refresh tokens, registration, login |
| `routes` | Route entity, route optimization endpoints |
| `stops` | Stop entity, stop-list logic |
| `subscriptions` | Subscription entity and lifecycle |
| `payments` | Stripe integration, webhooks, Stripe Connect 50/50 split (ADR-0030) |
| `geocoding` | Address resolution, Nominatim |
| `graphhopper` | Routing engine integration, motorcycle profile |
| `paywall` | Subscription gate on "Iniciar Navegação" |
| `ocr` | Label scanner |
| `voice` | Voice input |
| `prototipo` | UI prototype changes (canonical reference only) |
| `docs` | Anything under `docs/` |
| `decisions` | New ADR or amendment to an existing ADR |
| `sessions` | New session log under `docs/sessions/` |
| `claude` | Edits to [CLAUDE.md](../CLAUDE.md) (per CLAUDE.md self-modification rule) |
| `deps` | Dependency upgrades |
| `chore` | Repo housekeeping that doesn't fit a feature scope |

---

## 10. Open Questions

| # | Question | Owner | Resolution trigger |
|---|---|---|---|
| 1 | M2 scope reconfirmation with client | Eduardo | After M1 acceptance (post-2026-05-26) |
| 2 | Droplet IPv4 (production) | Eduardo | At server provisioning (Phase 1 of [TODO.md](../TODO.md)) |
| 3 | Vercel project name + staging URL | Eduardo | At landing page deploy (Phase 3 of [08-ROADMAP.md](08-ROADMAP.md)) |
| 4 | Nominatim — self-hosted vs public API for geocoding | Eduardo | Before F02 implementation (M2) — needs a new ADR |
| 5 | OCR strategy verification — confirm `google_mlkit_text_recognition` works offline on the Android versions targeted | Eduardo | M2 spike before F04 implementation |
| 6 | WebSocket auth strategy — JWT in query string vs subprotocol | Eduardo | Only relevant if a future feature reintroduces WebSocket — F11 was removed (see `04-FEATURES.md`); slice 4 paywall uses polling, not WS |
| 7 | Both Stripe Connected Accounts onboarded for the two partners + Pix payment method approved in the platform account (invite-only in BR) — ✅ confirmed 2026-05-24, reconfirm at slice 4 start | Client | Before slice 4 starts — gating dependency (ADR-0030) |
| 8 | Domain DNS — current registrar and where to point it (Vercel vs DO)? | Eduardo + client | At Phase 3 of [08-ROADMAP.md](08-ROADMAP.md) |

---

## Self-Review

- ✅ Briefing original logged at [`briefing/original-briefing.md`](briefing/original-briefing.md) (no fabricated content; points to canonical sources).
- ✅ Context7 was consulted at ADR-creation time (2026-05-05); will be re-consulted at scaffold time when libraries are actually installed.
- ✅ Confirmation per opinionated layer is recorded in each ADR's "Decision" section (user-approved at original ADR commit).
- ✅ All 10 sections present.
- ✅ Rejected alternatives ≥ 1 per opinionated layer (Mobile, State, Backend, Validation, ORM, Database, Routing, Payment, Repo, Positioning).
- ✅ Prisma schema sketch follows conventions (UUID, timestamps, explicit `onDelete`).
- ✅ Monorepo layout matches [03-CONVENTIONS.md](03-CONVENTIONS.md).
- ✅ Integrations listed with purpose and milestone.
- ✅ Docs plan is anti-YAGNI (no speculative new docs).
- ✅ Open questions ≥ 1 captured.
- ✅ No code written outside `docs/`.
- ✅ No new libraries installed.

**Next step per skill chain:** `saas-project-scaffold` would run next. Note: this project's scaffold pre-dates the skill — `apps/`, `infra/`, `prototipo/`, `scripts/` already exist as folders. The scaffold skill, if invoked, must be told **not to regenerate** existing structure and instead to fill gaps (e.g., `apps/mobile/` Flutter init for Phase 1 of [TODO.md](../TODO.md)).
