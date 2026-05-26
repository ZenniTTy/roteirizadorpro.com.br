# 02 — Architecture

> **Source-of-truth hierarchy (ADR-0035):** Spoke (ex-Circuit Route Planner) is canonical for behavior — screens, navigation, settings, gestures, flow ordering. The Claude Design prototype at `prototipo/` is canonical for visual identity only — tokens, colors, icon family, animations. Cliente Ueslei is final tiebreaker. The canonical Spoke↔RotPro screen catalogue lives in `docs/inventory/2026-05-26-spoke-vs-rotpro.md`; `docs/06-DESIGN-SYSTEM.md` mirrors `prototipo/tokens.js` (still the visual canonical).
> **Current scope:** M2 reset 2026-05-26. M1 ✅ shipped (auth + landing + GraphHopper SP + APK v1.0.0 em prod). Slice 1 do M2 ✅ shipped. Slice 2 em progresso pós-reset (`feat/m2-slice-2-spoke-clone` quando começar). Sections abaixo descrevem o estado-alvo do M2 completo; o que ainda não foi implementado pós-reset está marcado quando relevante.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Client — Flutter App (M2)                                       │
│ Riverpod 3, Dio HTTP, ML Kit OCR, speech_to_text, url_launcher  │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS / JWT
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ Backend — Fastify v5 + TypeScript (DigitalOcean droplet)        │
│ Auth, routes, subscription, webhook, stats, admin               │
└─────┬──────────────────┬─────────────────────────┬──────────────┘
      │                  │                         │
      ▼                  ▼                         ▼
┌────────────┐   ┌────────────┐         ┌──────────────────┐
│ PostgreSQL │   │ Redis      │         │ GraphHopper      │
│ Prisma 7   │   │ Cache      │         │ Sudeste BR       │
└────────────┘   └────────────┘         └──────────────────┘
      │                                          │
      ▼ webhook events
┌──────────────────┐                  ┌──────────────────┐
│ Stripe Pix       │                  │ Waze / Maps      │
│ Connect 50/50    │                  │ Deep link (M2)   │
│ + webhook (M2)   │                  │                  │
└──────────────────┘                  └──────────────────┘
                               ▲
                               │
                ┌──────────────┴──────────────┐
                │ Landing — Next.js on Vercel │
                │ roteirizadorpro.com.br      │
                └─────────────────────────────┘
```

## Components

### Mobile (Flutter — M1 partial, M2 full)

**M1 scope:** Login + Register screens (2 of 19). Backed by the M1 backend auth endpoints.
**M2 scope:** the remaining 17 prototype screens. Reconfirmed with client after M1.

- **Framework:** Flutter stable channel.
- **State management:** Riverpod 3 with `@riverpod` code generation (`riverpod_generator`).
- **HTTP client:** Dio with interceptors for JWT refresh.
- **Local storage:** `sqflite` (route history) + `flutter_secure_storage` (tokens).
- **OCR:** `google_mlkit_text_recognition` (offline, on-device).
- **Voice input:** `speech_to_text`.
- **Deep links:** `url_launcher` for Waze (`waze://?ll=...&navigate=yes`) and Google Maps (`google.navigation:q=lat,lng`).
- **QR code generation:** `qr_flutter` (share screen).
- **No WebSocket dep** — F11 (subscriber counter) was removed; slice 4 paywall uses polling (5 s) on `GET /subscription/status` instead of WS. If a future feature needs WS, the dep is added then with its own ADR.

### Backend (Fastify v5 + TypeScript)

- **Runtime:** Node.js 20 LTS.
- **Framework:** Fastify v5.
- **Validation / type provider:** TypeBox (`@sinclair/typebox`) — replaces JSON Schema, generates TypeScript types.
- **ORM:** Prisma 7 with `@prisma/adapter-pg` (driver adapter mandatory in v7).
- **Logging:** Pino (Fastify default), JSON structured to stdout.
- **Auth:** `@fastify/jwt` with RS256, separate keys for access (15 min) and refresh (7 days).
- **Security plugins:** `@fastify/helmet`, `@fastify/cors`, `@fastify/rate-limit`.
- **HTTP:** Fastify default (uWebSockets-style fast HTTP server).
- **Process manager:** Docker container with restart policy `unless-stopped`.

### Database (PostgreSQL 16)

- Single database for the application.
- Bound to `127.0.0.1` only — never exposed externally.
- Daily `pg_dump` backup at 03:00, 30-day rotation.
- Connection from backend via Prisma + driver adapter.

### Cache (Redis 7)

- Geocoding cache (key: `geocode:<sha256(address)>`, TTL 30 days).
- Route cache (key: `route:<sha256(stops_canonical)>`, TTL 7 days).
- Active subscriber counter (key: `stats:active_subscribers`, no TTL).
- Session store / refresh token denylist.
- Bound to `127.0.0.1` only.

### Routing engine (GraphHopper)

- Self-hosted Docker container.
- Profile: `motorcycle` (better fits motoboy reality than `car`).
- Contraction Hierarchies (CH) enabled for sub-200ms responses.
- PBF source: Geofabrik (`sudeste-latest.osm.pbf` or merged SP+RJ+MG+ES).
- Memory: ~4-6GB allocated to JVM heap (within 8GB droplet).
- Bound to `127.0.0.1:8989` — backend proxies it.

### Payment (Stripe Pix + Connect 50/50 split — M2)

> Gateway atual: **ADR-0030 (Stripe Pix)**. Operational rules + paywall UX live in `docs/BUSINESS-RULES.md`. (ADR-0007 anterior — Efí Bank — foi superseded por ADR-0030 e deletada no reset 2026-05-26; histórico no git log.)

- Authentication: Stripe API key (`STRIPE_SECRET_KEY`) + webhook signing secret (`STRIPE_WEBHOOK_SECRET`). **No mTLS, no `.p12` certificate.**
- SDK: official Stripe Node SDK (`stripe` npm package).
- Split model: **Stripe Connect — Separate Charges and Transfers**. Platform creates the `PaymentIntent`; on `payment_intent.succeeded` webhook the backend fires two `stripe.transfers.create` calls (one per Connected Account) for 50/50 split.
- Charge: single `PaymentIntent` with `amount=2590` (BRL cents), `currency=brl`, `payment_method_types=['pix']`, `metadata={userId}`. The `next_action.pix_display_qr_code` returns the QR + copy-and-paste code the mobile UI renders.
- Webhook: `POST /webhooks/stripe` validates the signature via `stripe.webhooks.constructEvent(payload, sig, secret)`, dedupes by `stripeEventId` in a `webhook_events` table (Prisma migration in slice 4), grants 30 days of access (`subscription.status='active'`, `expires_at=now+30d`).
- Renewal: each new payment is a fresh manual `PaymentIntent`. **No Stripe Billing, no Stripe Subscriptions API, no recurring schedule** — Pix Automático is invite-only in Brazil, and the product explicitly chose the manual-renewal UX. Daily cron at 03:00 BRT flips expired rows to `inactive`.

### Landing page (Next.js on Vercel)

- Framework: Next.js 14+ (App Router).
- Styling: Tailwind CSS.
- Hosting: Vercel free tier.
- Domain: apex `roteirizadorpro.com.br` + `www`.
- HTTPS: auto-provisioned by Vercel.
- Sections: Hero, product details, how it works, FAQ, contact buttons, APK download CTA.

### Infrastructure (DigitalOcean)

- Droplet: 8GB RAM / 4 vCPU / Ubuntu 24.04 / São Paulo region (NYC3 fallback if SP unavailable).
- Managed by client (server titularity is the client's, per the Workana proposal).
- Eduardo accesses via SSH key.
- Firewall (`ufw`): allow 22, 80, 443. Deny everything else.
- `fail2ban` enabled. SSH key-only authentication.
- Nginx as reverse proxy for `api.roteirizadorpro.com.br` → backend container.

## Critical Flows

### Flow 1 — Authentication (M1)

```
1. User submits POST /auth/register {email, password, name, phone}
   ↓
2. Backend validates with TypeBox, hashes password (bcrypt cost 12)
   ↓
3. Backend creates user row in PostgreSQL via Prisma
   ↓
4. Returns 201 with user payload (no token yet — login required)
   ↓
5. User submits POST /auth/login {email, password}
   ↓
6. Backend verifies password, signs JWT access (15min) + refresh (7d)
   ↓
7. Returns 200 {access, refresh, user}
   ↓
8. Mobile app stores tokens in flutter_secure_storage
   ↓
9. Subsequent requests include Authorization: Bearer <access>
   ↓
10. On 401 (token expired), app calls POST /auth/refresh and retries
```

### Flow 2 — Route optimization with "sentido casa" (M2)

```
1. User adds stops (typing / voice / OCR) → backend geocodes via Nominatim
   ↓
2. User taps "Optimize route"
   ↓
3. App POSTs /routes/optimize { stops: [...], home: {lat, lng} }
   ↓
4. Backend solves TSP with constraint:
   - Last stop = nearest to home
   - For ≤ 15 stops: nearest-neighbor + 2-opt heuristic (sub-second)
   - For > 15 stops: GraphHopper Matrix API
   ↓
5. Backend returns ordered stops + polyline + ETA
   ↓
6. App displays route + estimated end time at top
```

### Flow 3 — Stripe Pix paywall, 30-day access pass (M2 / slice 4)

> **Pricing model — current state.** Adding stops, optimizing the route, viewing the result, sharing, map view, and "sentido casa" are **free forever**. The paywall fires on "Iniciar Navegação": one Pix charge of **R$ 25,90** grants **30 days** of access (the button stays unlocked for that period; external nav to Waze/Google Maps fires immediately). When 30 days expire, the user pays again — a fresh manual Pix payment, not a recurring charge. 50/50 split via Stripe Connect (Separate Charges and Transfers). Full rules in `docs/BUSINESS-RULES.md`. Per ADR-0030.

```
 1. User finishes adding stops and taps "Otimizar rota"
    ↓
 2. App POSTs /routes/optimize (slice 3 — see Flow 2). Free.
    ↓
 3. App renders ScreenOptimizeRoute. User reviews the result. Free.
    ↓
 4. User taps "Iniciar Navegação"
    ↓
 5. App calls GET /subscription/status (server-authoritative — never trust local cache)
    ↓
    ├── status='active' → step 11 (skip paywall)
    └── status='inactive' → step 6
    ↓
 6. App calls POST /payments/pix-intent { userId }
    ↓
 7. Backend creates Stripe PaymentIntent (amount=2590, currency=brl,
    payment_method_types=['pix'], metadata={userId})
    + saves Payment row with status='pending'
    + returns next_action.pix_display_qr_code (QR image data URI + copy-and-paste code)
    ↓
 8. App renders ScreenPaywall: QR + "Copiar código Pix" + polling GET /subscription/status every 5 s
    ↓
 9. User pays in their bank app.
    ↓
10. Stripe webhooks POST /webhooks/stripe (event: payment_intent.succeeded)
    ↓
    a. Backend validates signature via stripe.webhooks.constructEvent(payload, sig, secret)
    b. Dedupes by stripeEventId in webhook_events table (return 200 if already processed)
    c. Fires two stripe.transfers.create — one per Connected Account, 50/50
    d. Creates/updates subscription row: status='active', expires_at=now+30d
    e. Returns 200 (never 4xx/5xx — Stripe retries indefinitely)
    ↓
11. App's poll picks up status='active' on next tick (default 5 s)
    ↓
12. App navigates to external nav handoff (Waze / Google Maps). Button stays unlocked for 30 days.
```

Polling instead of WebSocket: Stripe webhooks land within 1–3 s of payment in practice; a 5 s client poll keeps the slice 4 implementation simpler and the mobile network footprint smaller. Move to SSE if user friction becomes visible.

Renewal: when `expires_at` passes (checked by daily cron at 03:00 BRT and at every `GET /subscription/status` call), the row flips to `status='inactive'`. The next tap on "Iniciar Navegação" re-enters this flow at step 6. There is **no cancel endpoint, no refund endpoint, no Stripe Subscriptions API call anywhere in the codebase** — `BUSINESS-RULES.md` §8 lists these as inviolable.

### Flow 4 — Map screens, tile fetching, and OSM compliance (M2 / slice 2)

```
1. App opens a screen with a map (AddStopsMap, MapStops, OptimizeRoute, Navigate)
   ↓
2. flutter_map renders a TileLayer with urlTemplate
   = https://tile.openstreetmap.org/{z}/{x}/{y}.png and userAgentPackageName
   = 'br.com.roteirizadorpro.roteirizador_pro' (mandatory; see ADR-0016).
   ↓
3. Each visible tile (n ≈ 6-30 depending on screen size and zoom) is GET'd from
   the OSM tile server. Cached by the OS HTTP cache and re-used for subsequent
   visits within the TTL.
   ↓
4. Attribution widget shows "OpenStreetMap contributors" at all times.
   ↓
5. The slice 7 admin metrics page rolls up daily tile-request count from app
   analytics so we know in time if we approach the OSMF acceptable-use limit
   (see ADR-0016 for the migration trigger to self-hosted tiles).
```

### Flow 5 — Geocoding (M2 / slice 3)

```
1. User types an address in ScreenAddStop or transcribes one via ScreenVoice
   ↓
2. App POSTs /geocode { query: "<text>" } to the backend
   ↓
3. Backend (rate-limited to 1 req/s/user) calls Nominatim:
   GET https://nominatim.openstreetmap.org/search?q=<query>&format=json&limit=5
   with User-Agent: 'roteirizadorpro/1.0 contact: eduardo@ianelli.tech'
   ↓
4. Backend caches the top result in Redis with a 24-hour TTL keyed by the
   normalized query string. Returns { lat, lng, display_name, confidence }.
   ↓
5. App lets the user accept or pick from alternatives.
```

> If Nominatim usage starts hitting the OSMF rate threshold the migration is the same as for tiles: self-host Nominatim on the droplet (heavier: ~30 GB disk for SP), or move to LocationIQ. Captured in ADR-0018 (filed when slice 3 starts).

### Flow 6 — External navigation hand-off (M2 / slice 2)

```
1. From ScreenOptimizeRoute, user taps "Abrir no Google Maps" or "Abrir no Waze"
   ↓
2. App builds a deep link with the optimized route as waypoints:
   - Google Maps: https://www.google.com/maps/dir/?api=1
                 &origin=<lat,lng>
                 &waypoints=<lat,lng>|<lat,lng>|...
                 &destination=<lat,lng>
                 &travelmode=driving
   - Waze: waze://?ll=<lat,lng>&navigate=yes (single destination only; for
     multi-stop the app loops, opening Waze for the next stop on each "Cheguei").
   ↓
3. url_launcher dispatches to the OS, the rider's preferred nav app opens.
```

In-app turn-by-turn (Mapbox Navigation SDK or equivalent) is **post-M2** — too expensive both in licensing and in mobile-team effort relative to the value (~95 % of motoboys already have Google Maps or Waze installed). External nav handoff via `url_launcher` (Waze deeplink + Google Maps fallback) é a abordagem confirmada.

## Data Model (initial — evolves with implementation)

```
users
├── id              uuid PK
├── email           text UNIQUE NOT NULL
├── password_hash   text NOT NULL
├── name            text NOT NULL
├── phone           text
├── home_address    jsonb           # {lat, lng, label}
├── created_at      timestamptz
└── updated_at      timestamptz

refresh_tokens
├── id              uuid PK
├── user_id         uuid FK → users.id (CASCADE)
├── token_hash      text UNIQUE
├── expires_at      timestamptz
├── revoked_at      timestamptz
└── created_at      timestamptz

subscriptions (M2)             # Naming kept for continuity; semantically a "30-day access pass" per ADR-0030.
├── id              uuid PK
├── user_id         uuid FK → users.id (CASCADE)
├── status          text             # active | inactive  (no canceled — see BUSINESS-RULES.md §8)
├── activated_at    timestamptz
├── expires_at      timestamptz      # activated_at + 30 days
└── stripe_subscription_metadata jsonb  # nullable; reserved for future audit trail

payments (M2)
├── id                       uuid PK
├── user_id                  uuid FK → users.id
├── subscription_id          uuid FK → subscriptions.id
├── stripe_payment_intent_id text UNIQUE
├── stripe_event_id          text             # the payment_intent.succeeded event id (idempotency key)
├── amount_cents             int              # 2590
├── currency                 text             # 'brl'
├── status                   text             # pending | paid | failed | expired  (no refunded — see BUSINESS-RULES.md §8)
├── qr_code_url              text             # next_action.pix_display_qr_code.image_url_png
├── pix_copia_cola           text             # next_action.pix_display_qr_code.data
├── paid_at                  timestamptz
└── created_at               timestamptz

webhook_events (M2)            # Idempotency table for Stripe webhook (ADR-0030)
├── id                uuid PK
├── stripe_event_id  text UNIQUE     # dedupe key
├── event_type       text             # 'payment_intent.succeeded', etc.
├── processed        boolean
├── payload          jsonb            # full event for audit / debugging
└── received_at      timestamptz

routes (M2)
├── id              uuid PK
├── user_id         uuid FK → users.id (CASCADE)
├── name            text
├── optimized_order jsonb            # [stop_id, ...]
├── total_distance_m  int
├── total_duration_s  int
├── ended_at_estimate timestamptz
└── created_at      timestamptz

stops (M2)
├── id              uuid PK
├── route_id        uuid FK → routes.id (CASCADE)
├── address_raw     text
├── address_formatted text
├── lat             double precision
├── lng             double precision
├── delivered_at    timestamptz
├── position        int
└── source          text             # manual | voice | ocr

webhook_events (M2)
├── id              uuid PK
├── provider        text             # efi
├── event_type      text
├── payload         jsonb
├── processed       boolean
└── received_at     timestamptz
```

## API Contracts & Type Safety

The stack has three places where data shape is defined: the database (Prisma), the HTTP API (TypeBox), and the mobile client (Dart). To prevent drift and entropy, exactly one of these is canonical for each layer. Codified in **ADR-0013**.

| Layer | Source of truth | Lives at | Consumes |
|---|---|---|---|
| Database | Prisma `schema.prisma` | `apps/backend/prisma/schema.prisma` | backend only — never crosses the wire |
| HTTP API | TypeBox schemas | `apps/backend/src/<feature>/schemas.ts` | backend handlers (via `Static<typeof Schema>`) and Dart DTOs (via mirror) |
| Mobile | Dart DTOs (manual mirror of TypeBox; codegen deferido) | `apps/mobile/lib/features/<feature>/data/dto/<name>_dto.dart` | mobile presentation layer |

### Rules

1. **Prisma types stay backend-internal.** A handler that returns `prisma.user.findUnique(...)` directly is a bug — `password_hash`, internal columns, and future migrations must not leak. Always whitelist via a TypeBox response schema.
2. **TypeBox schemas are the API contract.** Every request body, query string, params, and every response status code is declared with a TypeBox schema. Schemas live in `apps/backend/src/<feature>/schemas.ts`, separate from route handlers, so they can be imported by tests and (futuro, quando justificar) by an OpenAPI exporter. Handler types come from `Static<typeof Schema>`.
3. **Mobile DTOs mirror TypeBox 1:1.** Each DTO file carries `// Mirror of: apps/backend/src/<feature>/schemas.ts -> <SchemaName>` (single-DTO) or `... -> {Schema1, Schema2, ...}` (multi-DTO) as its L1 header. ASCII `->` only, no backticks. Field names and types match exactly — no renaming. `fromJson` / `toJson` are explicit.
4. **One PR changes both sides.** A change to a TypeBox schema and the change to its Dart mirror travel in the same commit. Code review enforces this until codegen lands.

### Example

```ts
// apps/backend/src/auth/schemas.ts
import { Type, Static } from '@sinclair/typebox'

export const UserSchema = Type.Object({
  id: Type.String({ format: 'uuid' }),
  email: Type.String({ format: 'email' }),
  name: Type.String(),
  phone: Type.Union([Type.String(), Type.Null()]),
  createdAt: Type.String({ format: 'date-time' })
})
export type User = Static<typeof UserSchema>
```

```dart
// apps/mobile/lib/features/auth/data/dto/auth_user_dto.dart
// Mirror of: apps/backend/src/auth/schemas.ts -> UserSchema
class AuthUserDto {
  const AuthUserDto({
    required this.id, required this.email, required this.name,
    required this.phone, required this.createdAt,
  });
  final String id;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;
  // fromJson / toJson elided — see _template.dart in the same folder.
}
```

A copy-paste reference is at `apps/mobile/lib/features/auth/data/dto/_template.dart`.

### Post-M1

Once M2 endpoints are designed, replace the manual mirror with codegen: `@fastify/swagger` exports OpenAPI from the TypeBox schemas, a Dart OpenAPI generator regenerates DTOs in CI. The `// Mirror of:` comments become docstrings on generated files. See ADR-0013 for the full rationale.

## API Contracts (initial — full OpenAPI spec lives next to backend code)

### M1 endpoints

```
POST   /auth/register   { email, password, name, phone }    → 201 { user }
POST   /auth/login      { email, password }                 → 200 { access, refresh, user }
POST   /auth/refresh    { refresh }                         → 200 { access }
GET    /auth/me                                             → 200 { user }
GET    /health                                              → 200 { status }
GET    /health/db                                           → 200 { status }
GET    /health/graphhopper                                  → 200 { status }
POST   /routes/optimize { stops[], home }                   → 200 { ordered_stops, polyline, eta }
                                                              # placeholder in M1, full in M2
```

### M2 endpoints (escopo-alvo, implementação em slice 3)

> Não implementados ainda. Lista do estado-alvo do backend M2 que será materializada na slice 3 (real backend for Spoke parity). Slice 2 (frontend telas core) usa apenas auth + o mock 200 de `/routes/optimize` que já existe.

```
PATCH  /user/home                  { lat, lng, label }
POST   /stops/geocode              { address_raw }                     → { lat, lng, formatted }
POST   /stops/ocr                  { image_base64 }                    → { extracted_address }
POST   /routes                     { name, stops[] }                   → { route }
GET    /routes                                                         → [route]
GET    /routes/:id                                                     → { route, stops[] }
DELETE /routes/:id
PATCH  /stops/:id/delivered
GET    /subscription/status                                            → { active, expires_at }
POST   /payments/pix-intent                                            → { qr_code, pix_copia_cola, payment_intent_id }
POST   /webhooks/stripe            (Stripe-signature-validated)
# F11 (subscriber counter) removed — see docs/04-FEATURES.md F11.
# Admin metrics (DAU, payments in period) live under F13 in slice 7.
GET    /admin/dashboard            (partner-only)                      → { mrr, active_users, transactions }
GET    /user/me/export             (LGPD Art. 18)                      → { full user payload as JSON }
DELETE /user/me                    (LGPD Art. 18 right to deletion)
```

## Operational Strategies

### Caching

- Redis as the only cache. No process-level cache.
- Geocoding TTL: 30 days (addresses don't move).
- Route TTL: 7 days (same set of stops → same optimization).
- Active subscriber counter: no TTL, updated on subscription state change.

### Rate Limiting

Per IP and per authenticated user:

- `POST /auth/login`: 5 / 15 min.
- `POST /auth/register`: 3 / hour.
- `POST /routes/optimize`: 30 / hour (free tier — paid users uncapped).
- `POST /stops/geocode`: 100 / hour.
- `POST /stops/ocr`: 60 / hour (more costly).

### Observability

- **Logs:** Pino JSON to stdout → captured by Docker → forwarded to DigitalOcean monitoring during M1; consider Better Stack or Grafana Loki later.
- **Errors:** Sentry (free tier) for both backend and Flutter app. Track DSN in `.env`.
- **Healthchecks:** Internal (`/health/*`) for liveness and dependency probes. External monitoring optional in M1.

### Security

- HTTPS enforced. All HTTP redirects to HTTPS.
- Helmet security headers on every Fastify response.
- CORS restricted to the app and admin panel origins.
- JWT keys (RS256) stored as files, paths in `.env`.
- Bcrypt cost factor 12 for password hashing.
- Webhook signatures validated (`stripe.webhooks.constructEvent` — ADR-0030).
- Secrets never in Git. `.env` files in `.gitignore`. Rotate immediately if leaked.
- `fail2ban` and `ufw` on the server.

### Backup and Recovery

- Postgres: daily `pg_dump` to `/opt/roteirizador/backups/`, 30-day rotation.
- GraphHopper graphs: weekly snapshot (regenerable from PBFs, not critical).
- DigitalOcean droplet snapshot before any major deploy.
- Recovery objectives: RTO 4h, RPO 24h.
- Full procedure in `docs/09-DISASTER-RECOVERY.md`.
