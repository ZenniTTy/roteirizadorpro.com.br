# 04 — Features (Product Functionality Reference)

Complete specification of every feature in Roteirizador Pro. This is the authoritative reference for implementation. Any ambiguity in the brief is resolved here. Changes to this document require a commit with `docs(features): <what changed>`.

## Feature Map

> **Status legend.** ✅ shipped to production. 🟡 in flight (current slice). ⏳ planned for an upcoming slice. ⛔ explicitly out of scope for M2.
>
> **M2 slice mapping** ties each feature to the slice that owns it. See `docs/08-ROADMAP-v2.md` for the slice order, dependencies, and acceptance criteria (v1 archived 2026-05-26 to `docs/archive/` per ADR-0035 pivot).

| ID | Feature | Milestone | Status | Slice |
|---|---|---|---|---|
| F01 | User registration and login | M1 | ✅ | M1 / Phase 2 |
| F14 | Landing page | M1 | ✅ | M1 / Phase 2 |
| F15 | GraphHopper routing engine (SP capital) | M1 | ✅ | M1 / Phase 3 |
| F16 | Distributable Android APK | M2 | ✅ shipped 2026-05-13 as `v1.0.0` | **slice 1** |
| F05 | Stop list management | M2 | ⏳ | slice 2 |
| F02 | Manual address entry | M2 | ⏳ | slice 2 |
| F03 | Voice address entry (on-device, pt-BR) | M2 | ⏳ | slice 2 (UI shell) |
| F04 | OCR address entry (on-device ML Kit) | M2 | ⏳ | slice 2 (UI shell) |
| F12 | Referral / share screen | M2 | ⏳ | slice 2 (native share) |
| F08 | External navigation hand-off (Google Maps / Waze deep link) | M2 | ⏳ | slice 2 |
| F07 | Route optimization (real solver) | M2 | ⏳ | slice 3 |
| F17 | Geocoding (Nominatim, on-domain rate-limited) | M2 | ⏳ | slice 3 |
| F09 | Paywall on "Iniciar Navegação" — 30-day access pass | M2 | ⏳ | slice 4 |
| F10 | Stripe Pix payment with 50/50 auto-split (Stripe Connect) | M2 | ⏳ | slice 4 |
| F06 | Home point ("sentido casa") | M2 | ⏳ | slice 5 |
| F18 | LGPD export / delete endpoints + ToS + privacy pages | M2 | ⏳ | slice 6 |
| F13 | Partner admin panel | M2 | ⏳ | slice 7 |
| F11 | Real-time subscriber counter | M2 | ⛔ removed | The metric does not map cleanly to the current 30-day-access-pass model (re-confirmed 2026-05-24, ADR-0030). The admin panel (F13) surfaces DAU + payments-in-period instead. |

> The single source of truth for **execution order, deadlines, and slice-level acceptance** is `docs/08-ROADMAP-v2.md`. This document is the source of truth for **what each feature is supposed to do.** Changes to a feature's intent edit this file; changes to the order of work edit the roadmap.

---

## F01 — User Registration and Login

**Milestone:** M1 (backend only). M2 (mobile UI).

**Description:** Standard email/password authentication. JWT-based sessions.

**Registration flow:**
1. User submits email, password, name, phone.
2. Backend validates with TypeBox schema.
3. Password hashed with bcrypt (cost 12).
4. User row created in PostgreSQL.
5. Returns 201 with user payload (no token — requires explicit login).

**Login flow:**
1. User submits email + password.
2. Backend verifies password hash.
3. Issues JWT access token (15min, RS256) + refresh token (7 days).
4. Refresh token stored in `refresh_tokens` table.
5. Returns 200 with `{ access, refresh, user }`.

**Token refresh:**
1. Client sends expired access + valid refresh to `POST /auth/refresh`.
2. Backend validates refresh, issues new access token, rotates refresh.
3. Old refresh is immediately invalidated.

**Endpoints:** `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`.

**Rules:**
- Passwords must be at least 8 characters.
- Rate limit: 5 login attempts per 15 minutes per IP.
- Rate limit: 3 registrations per hour per IP.
- Duplicate email returns 409.

---

## F02 — Manual Address Entry

**Milestone:** M2.

**Description:** User types an address or CEP. App shows autocomplete suggestions, user selects, stop is added to the list.

**Flow:**
1. User taps "Add stop".
2. Text field with debounced autocomplete (300ms after last keystroke).
3. Autocomplete calls `POST /stops/geocode { address_raw }`.
4. Backend geocodes via Nominatim (self-hosted or public API — confirm in ADR).
5. User selects from dropdown → stop added with lat/lng.
6. Fallback: user confirms address without selecting autocomplete → backend attempts geocoding anyway.

**Rules:**
- Minimum 3 characters to trigger autocomplete.
- Show at most 5 suggestions.
- If geocoding fails (address not found), show error: prompt user to try a different format.

---

## F03 — Voice Address Entry

**Milestone:** M2.

**Description:** User speaks an address or CEP. App transcribes, resolves to coordinates, adds stop.

**Flow:**
1. User taps microphone icon.
2. App requests microphone permission if not granted.
3. `speech_to_text` package listens until silence or user taps stop.
4. Transcription is passed to the same geocoding flow as F02.
5. User confirms the resolved address before it is added.

**Rules:**
- Show the transcribed text for the user to review before geocoding.
- If transcription is empty or unintelligible, show friendly error and prompt to retry.
- Confirmation step is mandatory (no silent auto-add from voice).

---

## F04 — OCR Address Entry (Label Scanner)

**Milestone:** M2.

**Description:** User points camera at a delivery label. App extracts CEP or address using on-device OCR, resolves to coordinates, adds stop.

**Flow:**
1. User taps camera icon.
2. Camera opens (using `camera` or `image_picker` Flutter plugin).
3. Image passed to `google_mlkit_text_recognition` (offline, on-device).
4. Extracted text is scanned for CEP pattern (`\d{5}-?\d{3}`) and address patterns.
5. Best candidate is pre-filled in the address field.
6. User reviews and confirms before geocoding is triggered.

**Rules:**
- Image pre-processing: increase contrast and threshold before OCR to handle worn labels.
- If no CEP or recognizable address is found, show raw extracted text and let user edit.
- Confirmation step is mandatory.
- Privacy: images are processed on-device, never uploaded to the backend.

---

## F05 — Stop List Management

**Milestone:** M2.

**Description:** User manages a list of delivery stops within a route.

**Operations:**
- Add stop (via F02, F03, F04).
- Reorder stops via drag-to-reorder (`ReorderableListView`).
- Delete stop (swipe left → delete button, or long-press).
- Mark stop as delivered (swipe right → green checkmark). Delivered stops move to the bottom of the list or are visually crossed out.
- Edit stop address (tap to re-enter).

**Rules:**
- Maximum 25 stops per route in V1 (TSP performance cap — disclose in UI with "For larger routes, split into multiple trips").
- List persists locally (SQLite) so the user can close and reopen the app without losing data.
- Optimized order is displayed after F07 runs. The original order is preserved so the user can revert.

---

## F06 — Home Point ("Sentido Casa")

**Milestone:** M2.

**Description:** User saves their home address with a flag icon. The optimization algorithm uses this to ensure the last delivery stop is the one closest to home.

**Flow:**
1. User goes to Settings → Home.
2. Enters home address (same F02 geocoding flow).
3. Address saved in `users.home_address` (jsonb: `{ lat, lng, label }`).
4. Home point displayed on the route screen with a house/flag icon.
5. On optimization, home is passed as the fixed endpoint constraint.

**Rules:**
- Home point is optional — optimization still works without it (minimizes total distance with no endpoint constraint).
- User can update home address at any time.
- Resetting to no home point removes the endpoint constraint.

---

## F07 — Route Optimization

**Milestone:** M2. Endpoint placeholder in M1.

**Description:** Given a list of stops (and optionally a home point), the backend computes the optimal visitation order minimizing total distance/time, returning the last stop nearest to home.

**Algorithm:**
- For 1–15 stops: nearest-neighbor heuristic + 2-opt local search. Runs server-side in under 1 second.
- For 16–25 stops: GraphHopper Matrix API (distance matrix between all stop pairs) + nearest-neighbor + 2-opt.
- Home constraint: the optimization treats home as a fixed final destination. The algorithm finds the ordering of stops such that the route ends at the stop geographically nearest to home, and the overall path from that last stop to home is minimized.

**Endpoint:** `POST /routes/optimize { stops: [{lat, lng, address}], home: {lat, lng} | null }`.

**Response:** `{ ordered_stops, total_distance_m, total_duration_s, estimated_end_time }`.

**Rules:**
- GraphHopper is queried internally (never exposed externally).
- Redis caches responses keyed by canonical stop hash + home hash. TTL 7 days.
- If optimization fails (GraphHopper down), return the stops in the original user order with a warning.

**Display:**
- Optimized order shown in the stop list.
- Estimated end time shown in a badge at the top of the screen (same visual style as the "current time" badge from Circuit — using our own design).
- Active subscriber count badge shown adjacent (see F11).

---

## F08 — External Navigation (Waze / Google Maps)

**Milestone:** M2.

**Description:** User taps "Iniciar Navegação" for a stop. App opens Waze or Google Maps (whichever is installed) with that stop's coordinates as the destination.

**Flow:**
1. User taps "Iniciar Navegação" (requires active subscription — see F09).
2. App checks which navigation apps are installed.
3. If both are installed: show a bottom sheet asking "Open with Waze" or "Open with Google Maps".
4. If only one is installed: open it directly.
5. If neither is installed: open the coordinates in the default browser as a fallback.

**Deep link formats:**
- Waze: `waze://?ll={lat},{lng}&navigate=yes`
- Google Maps: `google.navigation:q={lat},{lng}`
- Browser fallback: `https://maps.google.com/?daddr={lat},{lng}`

**Rules:**
- Navigation opens for one stop at a time (the current stop in sequence).
- After marking a stop as delivered, the "Iniciar Navegação" button auto-advances to the next stop.

---

## F09 — Paywall on "Iniciar Navegação" (30-day access pass)

**Milestone:** M2 (slice 4). **Decision:** ADR-0030. **Operational rules:** `docs/BUSINESS-RULES.md`.

**Description:** The "Iniciar Navegação" button is locked behind an active access pass. Adding stops, optimizing, viewing the route, sharing, map view, and "sentido casa" stay free forever. Only this one button is gated.

**Behavior:**
- Free forever: registration, all stop-management features, route optimization, route view, sharing, map, sentido casa.
- Paid: one Pix payment of **R$ 25,90** grants **30 days** of access — "Iniciar Navegação" stays unlocked for the period and triggers the external nav handoff (Waze default, Google Maps fallback).
- When a user with no active pass taps "Iniciar Navegação": paywall modal appears.
- After payment confirmation via Stripe webhook: the modal closes and external nav fires within ~5 s (poll interval).
- When the 30-day period expires: the button locks again. The user pays again to renew — a fresh manual Pix payment, not a recurring charge.

**Access pass lifecycle:**
- Activation: backend receives `payment_intent.succeeded` from `POST /webhooks/stripe` → `subscription.status='active'`, `expires_at=now+30d`.
- Expiration: daily cron at 03:00 BRT flips rows with `expires_at<now()` to `status='inactive'`. Also checked at every `GET /subscription/status` call (so the next tap on "Iniciar Navegação" after expiry sees the paywall, even before the cron runs).
- Renewal: user taps "Iniciar Navegação" → paywall modal → new `PaymentIntent` → same flow.

**Rules (full list in `docs/BUSINESS-RULES.md` §§7–10):**
- State is checked **server-side** on every "Iniciar Navegação" tap (`GET /subscription/status`). Local cache is UX-only — the server is the authority.
- **No trial period.**
- **No cancellation flow anywhere.** No cancel button, no `DELETE /subscription`, no `POST /subscription/cancel`. The only way to "cancel" is to not renew when 30 days expire. Deliberate product decision to prevent chargeback abuse.
- **No refund flow.** No `POST /payments/:id/refund` exists. Disclosed in the Terms of Service.
- The Settings screen shows access-pass status + expiry date — **read-only, no action button**.

---

## F10 — Stripe Pix Payment with 50/50 Auto-Split (Stripe Connect)

**Milestone:** M2 (slice 4). **Decision:** ADR-0030. **Operational rules:** `docs/BUSINESS-RULES.md`.

**Description:** User pays R$ 25,90 via Pix. The amount is split 50/50 between the two business partners using **Stripe Connect — Separate Charges and Transfers** (platform creates the `PaymentIntent`; the webhook handler fires two `stripe.transfers.create` calls to the Connected Account IDs of partner A and partner B).

**Payment flow:**
1. User taps "Pagar com Pix" in the paywall modal.
2. Backend calls Stripe: `stripe.paymentIntents.create({ amount: 2590, currency: 'brl', payment_method_types: ['pix'], metadata: { userId } })`.
3. Backend saves `Payment` row with `status='pending'`, `stripePaymentIntentId`.
4. Backend returns `next_action.pix_display_qr_code` (QR image data URI + copy-and-paste code).
5. App displays QR + "Copiar código Pix" button.
6. User pays in their bank app.
7. Stripe fires `payment_intent.succeeded` webhook to `POST /webhooks/stripe`.
8. Backend validates signature via `stripe.webhooks.constructEvent(payload, sig, secret)`, dedupes by `stripeEventId` in `webhook_events` (returns 200 if already processed), fires the two split transfers, sets `subscription.status='active'`, `expires_at=now+30d`.
9. App's `GET /subscription/status` poll (every 5 s) picks up `active` and unlocks "Iniciar Navegação".

**Connected Accounts (one-time setup):**
- Platform Stripe account (client) connects two Connected Accounts (partner A, partner B) via Stripe's Connect onboarding flow.
- `STRIPE_CONNECTED_ACCOUNT_SOCIO_1` and `STRIPE_CONNECTED_ACCOUNT_SOCIO_2` stored as env vars. **Never committed.**
- Stripe Pix is **invite-only in Brazil** — confirm Pix payment method is approved in the platform account dashboard before slice 4 ships (client confirmed already approved 2026-05-24, but verify at slice start).

**Rules:**
- Auth: API key (`STRIPE_SECRET_KEY`) — no mTLS, no `.p12` certificate.
- Webhook signing secret (`STRIPE_WEBHOOK_SECRET`) mandatory on every event.
- Webhook events stored in `webhook_events` for idempotency (duplicate `stripeEventId` is ignored, returns 200).
- Never return 4xx/5xx to Stripe — causes retry storm. Validation errors are still logged but return 200 with `processed=false` flag for ops investigation.
- If Stripe is down: show "Serviço de pagamento temporariamente indisponível. Tente novamente." Do not pre-create local payment rows speculatively.
- **No refund flow exists** — disclosed in Terms of Service.
- **No Stripe Subscriptions, no Stripe Billing.** Each renewal is a brand-new `PaymentIntent`.

**Fee breakdown:**
- R$ 25,90 × ~1,5% + R$ 0,40 = ~R$ 0,79 total fee per Pix.
- Net per partner: (R$ 25,90 − R$ 0,79) / 2 ≈ **R$ 12,56** each.

---

## F11 — Real-Time Active Subscriber Counter (⛔ REMOVED)

**Status:** removed during M2 scoping; re-confirmed removed at 2026-05-24 (ADR-0030) — the 30-day access pass model has no clean "active subscriber" semantic and the metric would mislead. Admin panel (F13) surfaces DAU + payments-in-period instead, which are the honest metrics for this billing model.

The historical visual + technical spec (badge on home screen, WebSocket-backed Redis counter) was never implemented and is intentionally **not preserved** here — re-introducing the feature would need a new spec anyway, sized to whatever the future metric is.

---

## F12 — Referral / Share Screen

**Milestone:** M2.

**Description:** A share screen that lets riders send the app download link to each other — designed for the street scenario where motoboys share the link without exchanging contacts.

**Three share methods:**
1. **WhatsApp:** Tapping the button opens WhatsApp with a pre-filled message containing the APK download URL. Uses `whatsapp://send?text=<message>`.
2. **Copy Link:** Copies the APK download URL to the device clipboard.
3. **QR Code:** Generates a QR code on-screen (`qr_flutter`) containing the APK download URL. Another rider can scan it directly.

**Rules:**
- The download URL is `https://roteirizadorpro.com.br/download`.
- The WhatsApp pre-filled message is in Portuguese: "Baixei esse app de roteirização, tá muito bom pra motoboy: https://roteirizadorpro.com.br/download"
- QR Code is generated client-side (no backend call needed).
- No referral tracking or affiliate codes in V1.

---

## F13 — Partner Admin Panel

**Milestone:** M2.

**Description:** A simple web dashboard for the two business partners to monitor subscription metrics. Read-only in V1.

**Access:**
- URL: `https://admin.roteirizadorpro.com.br`.
- Login restricted to the two partner emails.
- Same JWT auth system as the main API, but partner role checked.

**Dashboard content:**
- Total active subscribers (live, from Redis counter).
- MRR (monthly recurring revenue) in BRL.
- Recent transactions list (date, amount, status).
- User list with subscription status and activation date.

**Rules:**
- No user management actions in V1 (no banning, no manual subscription changes).
- No financial operations (no refund triggers in V1).
- Accessible only via HTTPS.

---

## F14 — Landing Page

**Milestone:** M1.

**Description:** Public marketing and distribution page for Roteirizador Pro.

**URL:** `https://roteirizadorpro.com.br`

**Required sections (verbatim from Workana proposal):**
1. **Hero:** app name, tagline, primary CTA ("Download APK").
2. **Product details:** what the app does, key features (route optimization, OCR, voice, "sentido casa").
3. **How it works:** 3-step or similar simple explainer.
4. **FAQ:** common questions (how to install APK outside Play Store, how subscription works, supported phones, etc.).
5. **Contact / Support buttons:** WhatsApp Business and/or email (channels confirmed by client before M1 starts).
6. **Footer:** copyright, privacy policy link (placeholder in M1, real page in M2).

**APK download CTA:** placeholder button in M1 (gray / "coming soon"). Live link in M2.

**Visual identity:** must be completely original (per ADR-0010). Not Circuit's colors, fonts, or icons.

**Technical:**
- Next.js 14 (App Router) + Tailwind CSS.
- Deployed on Vercel (Eduardo's account, transferred to client at M1 handoff).
- Apex domain `roteirizadorpro.com.br` + `www` via Vercel DNS config.
- HTTPS via Vercel auto-provisioning.
- Mobile-first design (primary audience visits from phones).

---

## F15 — GraphHopper Routing Engine

**Milestone:** M1 (infrastructure). M2 (full usage via API).

**Description:** Self-hosted routing engine that powers all route calculation. Zero per-request cost.

**Coverage:** Sudeste Brasil — SP, RJ, MG, ES.

**Profile:** `motorcycle` (aligns with motoboy use case better than `car`).

**Performance target:** p95 response time under 200ms on production server (M1 acceptance criterion).

**Technical:**
- Docker container, `graphhopper/graphhopper` official image.
- Contraction Hierarchies (CH) enabled for fast queries.
- Bound to `127.0.0.1:8989` — never exposed externally.
- Backend is the only consumer.
- Redis caches repeated route queries (same stop set → same result).

**Expansion path:** adding new regions = download new PBFs + rebuild graph. Downtime ~1 hour. No code change needed.
