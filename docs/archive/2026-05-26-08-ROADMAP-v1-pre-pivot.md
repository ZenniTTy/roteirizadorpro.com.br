# 08 — Roadmap (v1 — ARCHIVED 2026-05-26)

> 🛑 **ARCHIVED HISTORICAL SNAPSHOT — DO NOT USE AS THE ACTIVE PLAN.**
>
> This file was the active M2 roadmap from M1 delivery (2026-05-09) through 2026-05-26, when the **functional-clone pivot** ([ADR-0035](../decisions/0035-spoke-functional-clone-prototype-creative-reference.md)) replaced it with [`docs/08-ROADMAP-v2.md`](../08-ROADMAP-v2.md).
>
> **What changed in v2 vs v1:** slices 1, 4, 5, 6, 7 carry over essentially unchanged. Slices 2 and 3 were rewritten from scratch based on the [Spoke-vs-RotPro inventory](../inventory/2026-05-26-spoke-vs-rotpro.md) because the v1 versions were authored under the now-superseded premise that the `prototipo/` mockup was the canonical UI source for behavior + structure + flows. Post-pivot, Spoke is canonical for behavior; the prototype is canonical for visual identity only.
>
> **How to read this file:** as a snapshot of project state on 2026-05-23 / MS-14. The Status, Slice 2 microsprints (MS-01..MS-14), and "13/16 fidelity microsprints" counters are frozen at that date. Anything below this banner about slices 2 or 3 is no longer authoritative.
>
> **For the live plan, read [`docs/08-ROADMAP-v2.md`](../08-ROADMAP-v2.md).**
>
> Below this banner is the original v1 content, preserved verbatim for historical reference (sentences about it being the "single source of truth" applied at the time and no longer apply).

---

**Last updated:** 2026-05-26 (ARCHIVED banner added — see ADR-0035 pivot). Previous: 2026-05-24 (session 22f — M2-AI harness sprint shipped on parallel branch; slice 2 status snapshot refreshed).

## Status snapshot

| Milestone | Scope summary | Value | Status |
|---|---|---|---|
| **M1** | DO droplet hardened + GraphHopper SP-only + landing live + backend auth + Flutter Login/Register screens | BRL 2,000 | ✅ **Delivered 2026-05-09** (escrow release pending the client's written confirmation on Workana) |
| **M2** | Distributable APK + remaining 15 Flutter screens + real route optimization + Pix Split paywall + home-bias optimization + LGPD endpoints + admin panel | BRL 2,000 | 🟡 **In progress.** Slice 1 ✅ shipped 2026-05-13 as `v1.0.0`. Slice 2 in progress: 13/16 fidelity microsprints done as of 2026-05-23 (MS-14); 7 Criticals remain (MS-15 AddStop, MS-16 Voice, Navigate C-1 ADR-0017-scoped). On parallel branch `feat/m2-ai-harness` the **M2-AI Harness sprint shipped 2026-05-24 (ADRs 0023–0029)** — PR #8 against `feat/m2-slice-2-telas-core` ready to merge before slice 2 resumes. Slices 3–7 unchanged. |

Production endpoints:

- Landing + APK: `https://roteirizadorpro.com.br/roteirizador-pro-v1.0.0.apk` (HTTP 200, signed v2 APK, Content-Type `application/vnd.android.package-archive`).
- API: `https://api.roteirizadorpro.com.br/health` (uptime monitored daily backup at 03:00 BRT).

## Operating principles (read before any slice)

1. **Slice-by-slice, never all at once.** Each slice ends with a PR `feat/m2-slice-N-<topic>` → `develop` → merge → PR `develop` → `main` → merge → tag `vX.Y.Z` → screenshot/curl validation in production. Never compress this cycle to move faster — that's how slice 1 took two failed PRs (PR #4 missed the session-end commit, PR #5 patched it after the fact). Use the checklist in [`M2-SLICE-CHECKLIST.md`](./M2-SLICE-CHECKLIST.md) for every single slice.
2. **Karpathy's four principles always apply** — think before coding, simplicity first, surgical changes, goal-driven execution. See `CLAUDE.md` for the full text.
3. **Context7 mandatory** before installing any external library (within the cutoff window of LLM training data, which is January 2026 for the current agent). Stdlib + decade-old APIs are exempt. **All M2 library choices in this file were validated against Context7 on 2026-05-13.**
4. **Schema source-of-truth (ADR-0013):** Prisma → TypeBox → Dart DTO mirror. A change to the API contract and the change to its Dart mirror land in the same commit.
5. **No stack change without an ADR.** The current stack is locked from ADR-0001 through ADR-0014. New libraries adopted for M2 require an ADR in the same PR.
6. **Cost minimization is a non-negotiable success criterion of M2.** See [`M2-COST-MODEL.md`](./M2-COST-MODEL.md) — the operational target is **under BRL 200/month total infrastructure** while M2 is in beta (under 100 paying users). Every architectural choice below was made against that ceiling.
7. **Verify before claim done.** Provide curl output, a screenshot, or a logcat capture for every "this works" assertion. Anthropic best practices: "this is the single highest-leverage thing you can do." Slice 1 lost ~45 minutes diagnosing a missing `INTERNET` permission because no one had run `aapt2 dump permissions` on the published APK — the verification step that would have caught it in 5 seconds.

## What "M2 done" means (acceptance for the second BRL 2,000 escrow)

When all 7 slices below are green in production:

1. **APK live and downloadable** at `https://roteirizadorpro.com.br/roteirizador-pro-v<latest>.apk` — done in slice 1.
2. **The 15 remaining prototype screens** match the canonical `prototipo/` 1:1 in visual identity, structure, and flows — slice 2.
3. **`POST /routes/optimize` returns a real optimized route** (not the 501 placeholder) computed against the SP graph in under 2 s for 20-stop inputs — slice 3.
4. **Paywall on "Iniciar Navegação"** dispatches a Stripe Pix charge, the webhook unlocks the button for 30 days after confirmation, the 50/50 split lands in the two partner accounts via Stripe Connect — slice 4 (ADR-0030).
5. **"Sentido casa" toggle** in Settings biases route ending toward the rider's saved home — slice 5.
6. **LGPD endpoints** for export + delete + the `/termos` and `/privacidade` pages on the landing — slice 6.
7. **Partner admin panel** lets the two business partners see users, payments, and basic KPIs (DAU / receita-30-dias / paradas-dia) — slice 7.

The client signs off on a Loom video walking the seven items, then releases the escrow on Workana.

---

## The seven slices

Order is locked. Each slice ships independently to production. Estimates are conservative; refine after each merge.

### Slice 1 — Distributable APK (✅ shipped 2026-05-13, `v1.0.0`)

Already in production. Documented in:

- ADR-0014 (Android Release Signing and APK Distribution).
- `docs/sessions/2026-05-13-09-m2-slice-1-apk.md` + `2026-05-13-10-slice-1-validation-and-pr.md`.
- Memory entry `flutter-android-release-internet-permission.md` (project-scoped feedback memory).

No further work on this slice.

### Slice 2 — Telas Core (next; 2 weeks estimated)

**Goal:** every screen from the `prototipo/` not yet implemented is live in the app, navigable, and visually 1:1 with the prototype. State is local (Riverpod), persistence is in-memory for the slice (proper DB persistence happens when slice 3 lands the routes API).

**Read first:** [`M2-SLICE-CHECKLIST.md`](./M2-SLICE-CHECKLIST.md), then this section, then `prototipo/screens-a.jsx` through `screens-e.jsx`.

**Sub-order** (sub-slices, all in the same `feat/m2-slice-2-telas-core` branch — one PR for the whole slice; the sub-order is for sane commit boundaries):

| Sub | Screens / scope | New deps | Estimated |
|---|---|---|---|
| 2a — Foundation | `ScreenHomeEmpty`, `ScreenHomeList`, Riverpod `stopsControllerProvider` (`@riverpod class StopsController`), DTO `Stop` mirroring a TypeBox schema (even though the backend doesn't have it yet, define the schema now in `apps/backend/src/routes/schemas.ts` so the mirror is real). | none | 2 days |
| 2b — Captura | `ScreenAddStop` (text search), `ScreenVoice` (UI shell + `speech_to_text`), `ScreenOCR` (UI shell + `google_mlkit_text_recognition`), `ScreenAddStopsMap` (tap-to-add on `flutter_map`). | `speech_to_text`, `google_mlkit_text_recognition`, `flutter_map`, `latlong2`, `geolocator` | 4 days |
| 2c — Manipulação | `ScreenStopDetail`, `ScreenEditStop`, `ScreenReorder` (drag-to-reorder with `ReorderableListView`), `ScreenMapStops` (full-screen map view). | none beyond 2b | 3 days |
| 2d — Otimização (mock) e navegação | `ScreenOptimize` (calls a **mocked** `POST /routes/optimize` that returns the stops in input order; the real solver lands in slice 3), `ScreenOptimizeRoute`, `ScreenNavigate` (turn-by-turn UI shell; deep-links to Google Maps / Waze if the user has them — see ADR-0017 below), `ScreenRouteComplete`. | none beyond 2b | 3 days |
| 2e — Periféricos | `ScreenSettings` (settings page structure; the paywall section is stubbed since slice 4 owns it), `ScreenShare` (native `Share.share()` with a WhatsApp-friendly text). | `share_plus` | 2 days |

**Critical library choices** (validated via Context7 on 2026-05-13):

- **Map:** `flutter_map` 8.x (Apache 2.0; non-commercial; 91/100 Context7 score) with the public OSM tile server `https://tile.openstreetmap.org/{z}/{x}/{y}.png`. **Set `userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro'`** per the OSM tile usage policy. Add a `RichAttributionWidget` with "OpenStreetMap contributors" on every screen with a map. **Bake an in-app raster tile cache** via the `NetworkTileProvider` + the package's built-in HTTP cache so we do not hammer the public tile server. If our tile-request rate exceeds the OSMF threshold (commonly cited as "more than a few thousand tiles per device per day, or more than a million total per app"), the migration is documented in **ADR-0016** below — move tiles to a self-hosted `openmaptiles` + a small Nginx on the same droplet. Not slice 2 work; only the trigger condition is captured.
- **Voice (slice 2 stub):** `speech_to_text` 7.x (csdcorp; Context7 score 94/100, 217 snippets). On-device, supports pt-BR. For slice 2 it produces the recognized text; mapping text → coordinates happens through the same `POST /routes/optimize` call or a future `/geocode` endpoint (deferred to slice 3 if it doesn't already exist).
- **OCR (slice 2 stub):** `google_mlkit_text_recognition` 0.x (Context7 89/100, 154 snippets). On-device Latin script. The "tirar foto da etiqueta da AWB" flow runs OCR, the user confirms the extracted address, then it goes through the same geocoding path as the voice flow.
- **Position:** `geolocator` 14.x for the user's current location on the map.
- **Reorder:** `ReorderableListView` is in the Flutter SDK; no extra dep.
- **Share:** `share_plus` 11.x (cross-platform wrapper for native share sheets).

**Files that will be created (slice 2 file map):**

```
apps/mobile/lib/features/stops/
├── data/
│   ├── dto/
│   │   └── stop_dto.dart                        # Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema
│   └── repositories/
│       └── stops_repository.dart                # In-memory list backed by Riverpod state for slice 2
├── domain/
│   └── stop.dart                                # Pure Dart model (no JSON concerns)
├── state/
│   ├── stops_controller.dart                    # @riverpod class StopsController
│   └── stops_controller.g.dart                  # gen
└── presentation/
    ├── home_empty_page.dart                     # ScreenHomeEmpty
    ├── home_list_page.dart                      # ScreenHomeList
    ├── add_stop_page.dart                       # ScreenAddStop
    ├── voice_capture_page.dart                  # ScreenVoice (uses speech_to_text)
    ├── ocr_capture_page.dart                    # ScreenOCR (uses google_mlkit_text_recognition)
    ├── add_stops_map_page.dart                  # ScreenAddStopsMap
    ├── stop_detail_page.dart                    # ScreenStopDetail
    ├── edit_stop_page.dart                      # ScreenEditStop
    ├── reorder_page.dart                        # ScreenReorder
    ├── map_stops_page.dart                      # ScreenMapStops
    ├── optimize_page.dart                       # ScreenOptimize
    ├── optimize_route_page.dart                 # ScreenOptimizeRoute
    ├── navigate_page.dart                       # ScreenNavigate
    ├── route_complete_page.dart                 # ScreenRouteComplete
    └── shared/
        ├── stop_list_item.dart                  # reusable widget
        ├── stop_form.dart
        └── map_attribution.dart                 # RichAttributionWidget with OSM credit

apps/mobile/lib/features/settings/
└── presentation/
    └── settings_page.dart                       # ScreenSettings (paywall placeholder for slice 4)

apps/mobile/lib/features/share/
└── presentation/
    └── share_sheet.dart                         # ScreenShare (uses share_plus)

apps/backend/src/routes/
├── schemas.ts                                   # TypeBox: StopSchema, OptimizeRequestSchema, OptimizeResponseSchema
├── handlers.ts                                  # Slice 2: optimize returns input order; slice 3 replaces with real solver
└── routes.ts                                    # Register POST /routes/optimize (auth-gated)
```

**Test plan (slice 2):**

- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes; widget test for each new screen renders without throwing.
- [ ] Backend: `bun run typecheck` clean; integration smoke test for `POST /routes/optimize` returning input order.
- [ ] Manual: on the Galaxy A06 install, every prototype screen accessible from the home/menu, each visually 1:1 with the corresponding `prototipo/screens-*.jsx` (run `prototype-fidelity-checker` agent).
- [ ] `aapt2 dump permissions <new APK>` confirms `android.permission.{INTERNET, ACCESS_FINE_LOCATION, RECORD_AUDIO, CAMERA}` — the last three are added in slice 2 for `geolocator`, `speech_to_text`, and `google_mlkit_text_recognition`. **The INTERNET-permission gotcha from slice 1 stays in memory as a feedback rule; pre-check `aapt2 dump permissions` BEFORE adb-installing the new APK.**
- [ ] Release APK is `1.0.1+2` (semver patch since no API change; build code +1). Updated via `apps/mobile/pubspec.yaml` and a fresh `bash apps/mobile/scripts/build-release-apk.sh`.
- [ ] Real-device round-trip: create a route with 5 stops via mixed entry (voice + map + text), reorder one, see the map render all 5 markers, hit Optimize, see the (input-ordered) result, then Iniciar navegação opens the navigate screen (no paywall yet — that's slice 4).

**Post-merge:**

- [ ] PR `develop` → `main`, then tag `v1.0.1` after merge.
- [ ] Republish the APK in `apps/landing/public/` with the new filename `roteirizador-pro-v1.0.1.apk`. Update the four CTAs in `apps/landing/src/app/page.tsx` (or refactor them to read from a single `APK_LATEST_VERSION` constant in a tiny helper module — recommended).
- [ ] Smoke-test from a browser: download the new APK from the apex.

**New ADRs:**

- ADR-0016 — Map and tile strategy (`flutter_map` + OSM public tiles + heavy-usage migration plan to self-hosted MapTiler).
- ADR-0017 — External navigation hand-off (Google Maps / Waze deep links vs in-app turn-by-turn). The slice 2 shell uses a deep-link approach: tapping Iniciar navegação opens Google Maps with the optimized route waypoints — real in-app turn-by-turn is **post-M2** and would require Mapbox Navigation SDK or similar.

### Slice 3 — Real route optimization (3-5 days)

**Goal:** `POST /routes/optimize` returns an actually optimized route in under 2 seconds for inputs of up to 20 stops.

**Approach** (validated against Context7 — no good off-the-shelf VRP solver for Node exists, so we implement the right thing for our scale):

1. **Geocode** the user's stops if they came in as text (use Nominatim hosted at `https://nominatim.openstreetmap.org` with the same usage-policy rules: `User-Agent` header set to `roteirizadorpro/1.0`, max 1 req/sec; for slice 3 this is fine since we only geocode at route-creation time, not per-user-action — see ADR-0018).
2. **Build the distance matrix** by calling our self-hosted GraphHopper at `127.0.0.1:8989/route` for each pair of stops (n² calls; for n=20 that's 400 routes, each ~40 ms on our droplet → ~16 s sequential, ~2 s with `Promise.all` batching). The GraphHopper Matrix API is in the paid GraphHopper Directions cloud product; for self-hosted GraphHopper Community Edition we synthesize the matrix from individual route calls. **This is documented in ADR-0019.**
3. **Solve the TSP** (or VRP with a single vehicle and the rider's start point) using nearest-neighbor + 2-opt, implemented in `apps/backend/src/routes/solver.ts` (~150 LOC of clean TypeScript, no dependencies). For inputs ≤ 20 this is within 5% of optimal in ~50 ms.
4. **Cache** the matrix per (user, sorted-stop-ids hash) in Redis with a 5-minute TTL so repeated Optimize taps don't re-compute.

**Why not Google OR-Tools or jsprit:** OR-Tools is C++ with awkward Node bindings (`node-or-tools` is unmaintained as of 2025), jsprit is Java and would require a JVM. Our scale doesn't justify the operational complexity.

**Why not the paid GraphHopper Directions API:** ~€199/month minimum and we're trying to keep total infra under BRL 200/month.

**Slice 3 follow-up feature — Voice multi-address dictation (requested 2026-05-25 by Eduardo, MS-15a-followup smoke):** `VoiceCapturePage` today captures ONE address per session. The rider should be able to dictate multiple addresses in one mic session ("Rua A, Avenida B, Rua C") and create multiple `Stop` rows at once. Depends on real geocoding (Nominatim — this slice's prereq), so it lands AFTER the rest of slice 3 is functional. Requires a segmentation strategy (pause-based vs LLM-based — ADR at implementation time) plus a confirmation UI per geocoded segment. Estimated +1 day on top of slice 3.

**Test plan:** synthetic SP-area test set of 5, 10, 20 stops; assert p95 latency < 2 s; assert improvement ≥ 20% vs input-order baseline on randomized inputs.

**New ADR:** ADR-0019 (route-optimization architecture).

### Slice 4 — Stripe Pix paywall, 30-day access pass (4-6 days)

> Gateway + model: **ADR-0030** (supersedes ADR-0007). Operational rules in `docs/BUSINESS-RULES.md`.

**Goal:** the user can tap "Iniciar Navegação" → see a Pix QR code → pay R$ 25,90 → the Stripe webhook fires → the app unlocks navigation for **30 days**. The amount is automatically split 50/50 between the two partners via Stripe Connect (Separate Charges and Transfers) at the moment the webhook handler runs.

**Prerequisites Eduardo must collect before this slice can start:**

1. **Stripe platform account** with Pix payment method approved (Pix is invite-only in Brazil — client confirmed approved 2026-05-24; **re-verify in Dashboard → Settings → Payment Methods at slice start**).
2. **Two Stripe Connect Connected Accounts** (partner A, partner B) onboarded via Stripe's Connect flow. The `acct_…` IDs go into env as `STRIPE_CONNECTED_ACCOUNT_SOCIO_1` and `STRIPE_CONNECTED_ACCOUNT_SOCIO_2`.
3. **Stripe webhook endpoint** configured in the Stripe dashboard pointing at `https://api.roteirizadorpro.com.br/webhooks/stripe` with the webhook signing secret captured as `STRIPE_WEBHOOK_SECRET`.
4. **API key** (`STRIPE_SECRET_KEY=sk_live_...` for prod; `sk_test_...` for sandbox).

No mTLS, no `.p12` certificate.

**Implementation outline** (per ADR-0030):

- Official Stripe Node SDK (`stripe` npm package).
- `POST /payments/pix-intent { userId }` creates a `PaymentIntent` (`amount=2590`, `currency='brl'`, `payment_method_types=['pix']`, `metadata={userId}`) and returns `next_action.pix_display_qr_code`.
- `POST /webhooks/stripe` validates the signature via `stripe.webhooks.constructEvent(payload, sig, secret)`, dedupes by `stripeEventId` in `webhook_events` (Prisma migration in this slice), fires two `stripe.transfers.create` calls (50/50 split), upserts `subscription` with `status='active'`, `expires_at=now+30d`, returns 200.
- Daily cron at 03:00 BRT flips `subscription` rows where `expires_at<now()` to `status='inactive'`.
- Mobile: `ScreenPaywall` (`prototipo/screens-b.jsx` → `ScreenPaywall`) shows the QR + the copy-and-paste Pix code; polls `GET /subscription/status` every 5 s until `active` or the user closes the modal.

**Cost note:** Stripe Pix charges ~1,5% + R$ 0,40 per transaction. On R$ 25,90 that's ~R$ 0,79 per payment (~3,05% effective). Documented in `M2-COST-MODEL.md`.

**Files added in this slice:**

```
apps/backend/src/payments/
├── stripe_client.ts        # Stripe SDK setup, helpers
├── schemas.ts              # TypeBox for the Pix flow
├── handlers.ts             # POST /payments/pix-intent, GET /subscription/status
├── webhook_handlers.ts     # POST /webhooks/stripe with signature validation
└── routes.ts

apps/backend/prisma/migrations/<date>_subscriptions_and_webhooks/
└── migration.sql           # subscription + webhook_events tables

apps/mobile/lib/features/payments/
├── data/dto/payment_dto.dart
├── state/payment_controller.dart
└── presentation/paywall_page.dart   # ScreenPaywall
```

**ADRs:** ADR-0030 already covers the architecture decision; no new ADR needed unless the implementation deviates from it (e.g. if Stripe Pix approval is revoked and a different gateway is chosen — that would be a new ADR superseding 0030).

**Forbidden in this slice (per `BUSINESS-RULES.md` §8 — non-negotiable):** any `DELETE /subscription`, `POST /subscription/cancel`, `POST /payments/:id/refund`, any call to `stripe.subscriptions.*`, any Stripe Billing setup, any "cancel" / "manage subscription" button anywhere in the app.

### Slice 5 — Sentido casa (1 day)

**Goal:** in Settings, the rider sets a "home address." When toggled, the route optimization in slice 3 returns the path that ends nearest to that point.

**Implementation:** one column on the `users` table (`home_lat`, `home_lng`), one toggle in Settings, one branch in the solver in slice 3. The optimizer treats home as a virtual "stop N+1" with a free return leg, and picks the permutation that minimizes total distance with that constraint.

**Test plan:** unit test the solver with home-bias on vs off, assert the chosen permutation ends at the stop nearest to `(home_lat, home_lng)`.

### Slice 6 — LGPD (2-3 days)

**Goal:** legal compliance with Brazilian LGPD.

- `GET /me/export` → returns a JSON dump of the user's stored personal data (email, name, phone, routes, payments). Auth-gated. Documented in the LGPD record.
- `DELETE /me` → soft-deletes the user (sets `deleted_at`), revokes all refresh tokens, removes PII from the row, keeps audit-relevant fields (payments) anonymized. Documented as the LGPD-required "direito ao esquecimento."
- Landing pages `/termos` and `/privacidade` — static MDX in `apps/landing/src/app/(legal)/`. Linked from the Register screen and the footer.

**Files:**

```
apps/backend/src/users/
├── export_handlers.ts
└── deletion_handlers.ts

apps/landing/src/app/(legal)/
├── termos/page.tsx
└── privacidade/page.tsx
```

**ADR:** ADR-0020 (LGPD compliance approach).

### Slice 7 — Painel admin (3-5 days)

**Goal:** the two partners can log in to a web admin and see who's signed up, who's paid, and basic ops metrics.

**Approach:** add an `admin` page set to the existing landing (`apps/landing/src/app/(admin)/`), protected by an `admin` role on the User table. Three pages: Users, Payments, Metrics. Server-rendered with Next.js, data fetched server-side via the backend API using a JWT signed for the admin user. No new backend service.

**Metrics (slice 7):**

- DAU (daily active users — count of distinct users with a route in the last 24h).
- Receita 30 dias (R$ 25,90 × passes de acesso ativados no período — não é "MRR" clássico porque não há cobrança recorrente; cada renovação é manual).
- Paradas-dia (average stops per active user per day).

**Files:**

```
apps/landing/src/app/(admin)/
├── layout.tsx              # Auth guard
├── users/page.tsx
├── payments/page.tsx
└── metrics/page.tsx

apps/backend/src/admin/
├── handlers.ts             # GET /admin/users, /admin/payments, /admin/metrics
└── routes.ts
```

**ADR:** ADR-0021 (admin authorization model).

---

## Cost model (summary; full breakdown in [`M2-COST-MODEL.md`](./M2-COST-MODEL.md))

| Component | Monthly cost (BRL, beta — under 100 users) |
|---|---|
| DigitalOcean droplet 1 GB (current; resize to 2 GB after slice 2 if needed, 4 GB after slice 3 if matrix-eval p95 > 2 s) | 32 (USD 6, current) → 64 (USD 12, 2 GB) |
| `roteirizadorpro.com.br` domain renewal (per year ÷ 12) | 4 |
| Vercel (landing + admin, free tier) | 0 |
| OSM tile usage (free public tiles, within usage policy) | 0 |
| Nominatim geocoding (free public API, within policy) | 0 |
| Stripe Pix fees (~1,5% + R$ 0,40 per charge) | variable, per-transaction (not infra) |
| Backups (pg_dump local, no external blob in M2) | 0 |
| **Total infra (beta)** | **~BRL 36-68 / month** |

When slice 4 has ≥ 50 paying users (~R$ 1,3k receita/30 dias), revisit:

- Migrate tiles to self-hosted MapTiler or paid Mapbox if OSM usage policy gets close to the limit.
- Bump droplet to 4 GB so GraphHopper can hold the full Sudeste graph, expanding the addressable market beyond São Paulo capital.

All cost-impact decisions go into ADRs.

---

## Documentation map (where to look when)

This is the cross-reference table. Use it to find authoritative answers fast.

| Question | Source of truth |
|---|---|
| "What are we building, in what order?" | This file (`docs/08-ROADMAP.md`). |
| "What's the slice-execution checklist?" | `docs/M2-SLICE-CHECKLIST.md`. |
| "What's the cost target?" | `docs/M2-COST-MODEL.md`. |
| "How should the stack look?" | The 14 ADRs in `docs/decisions/`. |
| "Which screens exist?" | `prototipo/` first; `docs/05-SCREENS.md` as a mirror. |
| "Which features have been contracted?" | `docs/04-FEATURES.md`. |
| "How is the backend wired?" | `docs/02-ARCHITECTURE.md` + the schemas in `apps/backend/src/<feature>/schemas.ts`. |
| "What's the agent's operating manual?" | `CLAUDE.md` (root). |
| "What happened in past sessions?" | `docs/sessions/0001-INDEX.md` first; click into the dated log files. |
| "What's the current state of the to-do list?" | `TODO.md` (root) — header date tells you which slice. |

## Read-first map for the next agent

If you are an AI agent picking up the next slice (likely slice 2), read in this exact order:

1. `CLAUDE.md` — operating manual.
2. `docs/08-ROADMAP.md` (this file).
3. `docs/M2-SLICE-CHECKLIST.md`.
4. `docs/M2-COST-MODEL.md`.
5. `TODO.md` — current slice-by-slice state.
6. `docs/sessions/0001-INDEX.md` — last 5 entries minimum.
7. The slice's section above (e.g. "Slice 2 — Telas Core").
8. The `prototipo/screens-*.jsx` files matching the slice screens.
9. The relevant ADRs (cross-referenced inside each slice section).

If any of these contradicts what you read in the others, **this file (`08-ROADMAP.md`) wins**, and the contradiction is a bug to fix in the same PR you open.
