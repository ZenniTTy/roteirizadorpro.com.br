# 04 — Roadmap M2

**Milestone 2 — Android APK, Pix Split, Full Product**

| Field | Value |
|---|---|
| Value | BRL 2,000 (Workana escrow) |
| Duration | 14 days |
| Start | After M1 escrow released **and** droplet resized to 8GB with full Sudeste (SP+RJ+MG+ES) GraphHopper graph rebuilt |
| Deliverable | Production-ready APK distributed via `roteirizadorpro.com.br/download`, payment integration with split, partner admin panel, all features from the original brief |

## Scope (From The Accepted Workana Proposal)

> What stays for Part 2 (M2): the Android application (APK), Mercado Pago payment integration [updated to Efí Bank], the "sentido casa" optimization algorithm, the partner revenue split system, and the admin panel.

Plus features the client added by message during the contract:

- Real-time active subscriber counter at the top of the app.
- Share/referral screen with three options: WhatsApp, Copy Link, QR Code.
- Distribution via APK direct download (Google Play deferred indefinitely).
- Payment gateway switched from Mercado Pago to **Efí Bank** (the client's chosen provider, with proper Pix Split support).

## Sprint Structure

### Sprint 3 — Mobile App Core (Days 1–7)

**Day 1 — Project setup**

- Initialize `apps/mobile/` with Flutter stable channel.
- Configure linter (`flutter_lints`), formatter, analysis options.
- Install core dependencies: `flutter_riverpod`, `riverpod_generator`, `riverpod_annotation`, `dio`, `flutter_secure_storage`, `sqflite`, `url_launcher`, `qr_flutter`, `web_socket_channel`, `google_mlkit_text_recognition`, `speech_to_text`, `permission_handler`.
- Set up code generation pipeline (`build_runner`).
- Configure environment switching (`API_BASE_URL` per build flavor).
- Author `apps/mobile/.env.example`.

**Days 2–3 — Authentication and shell**

- Build login + register screens.
- Wire to backend `/auth/*` endpoints from M1.
- Token storage in `flutter_secure_storage`.
- Dio interceptor for automatic refresh on 401.
- Navigation shell (bottom navigation: Routes, Settings).
- Riverpod providers for auth state.

**Days 4–5 — Stop entry**

- Stop list screen with drag-to-reorder (using `ReorderableListView`).
- Manual address entry with autocomplete (debounced calls to `/stops/geocode`).
- **Voice input** integration (`speech_to_text` + permissions handling).
- **OCR scanner** for delivery labels (`google_mlkit_text_recognition` + camera plugin). Regex extraction of CEP, fallback to free-form address parsing.
- Stop deletion / edit / mark-as-delivered.
- Local persistence via `sqflite`.

**Days 6–7 — Route optimization and external navigation**

- "Save home" feature (flag icon — user pins their residence).
- "Optimize route" button → calls backend `/routes/optimize` with `home` constraint.
- Route screen displays optimized order, total distance, ETA at top.
- "Iniciar Navegação" button → opens Waze (`waze://?ll=lat,lng&navigate=yes`) or Google Maps (`google.navigation:q=lat,lng`) via `url_launcher`. Fallback to map app picker.
- Mark-as-delivered swipe action on each stop.

### Sprint 4 — Pix Split, Paywall, Admin, Polish (Days 8–14)

**Days 8–9 — Backend Efí integration**

- Extend Prisma schema: `subscriptions`, `payments`, `webhook_events`.
- Implement Efí HTTPS client with mTLS (no SDK — direct calls via `undici` configured with the `.p12` cert).
- One-time setup: `POST /v2/gn/split/config` with 50/50 split between partner accounts. Persist `splitConfigId`.
- `POST /subscription/checkout` — creates Pix cobrança with split attached, returns QR + copy-paste.
- `POST /webhooks/efi/pix` — validates HMAC, marks subscription active, broadcasts via WebSocket.
- Idempotency: webhook events stored in `webhook_events`, duplicate `e2e_id` ignored.
- `GET /subscription/status` for paywall checks.
- Test end-to-end against Efí sandbox before production.

**Day 10 — App paywall**

- `SubscriptionStatusProvider` (Riverpod) polls `/subscription/status` and listens to WebSocket.
- "Iniciar Navegação" button enabled only when subscription is `active`.
- Subscription modal: shows BRL 25.90/month, "Pay with Pix" button.
- On checkout: display QR code + copy-paste, with "I paid" button that triggers a manual refresh.
- WebSocket auto-update when payment confirmed.

**Day 11 — Real-time subscriber counter and share screen**

- Backend: maintain `stats:active_subscribers` counter in Redis. INCR on activation, DECR on cancellation/expiration.
- WebSocket endpoint `/ws/stats` broadcasts on change. Fallback REST endpoint `GET /stats/active-subscribers`.
- App: display counter in a small badge at the top of the home screen (next to the route end-time badge).
- **Share screen** with three actions:
  - WhatsApp: `whatsapp://send?text=<message with download URL>`.
  - Copy Link: native clipboard.
  - QR Code: `qr_flutter` rendering of the download URL.

**Day 12 — Admin panel for partners**

- Initialize `apps/admin/` as Next.js (or extend the landing repo).
- Login (separate auth path: only the two partner emails are allowed).
- Dashboard: total active subscribers, MRR (BRL), recent transactions, user list with status.
- Read-only in V1; user actions deferred.
- Deploy to Vercel with subdomain `admin.roteirizadorpro.com.br`.

**Day 13 — APK build and distribution**

- Generate signing keystore (one-time, secure storage of the keystore is critical).
- Document keystore handoff to client (NEVER commit keystore — explain how to back it up).
- Configure `apps/mobile/android/app/build.gradle` for release build.
- Build signed APK: `flutter build apk --release --split-per-abi`.
- Upload APK files to landing page or to a static host (e.g., GitHub Releases or DO Spaces).
- Update landing page CTA to point to the real APK download URL.
- Test installation on at least 3 different Android devices/versions.

**Day 14 — Final verification and handoff**

- End-to-end flow test: install APK fresh → register → add stops → optimize → pay → navigation opens.
- Webhook test in production: real Pix payment from a test phone, confirm subscription activates within seconds.
- Screen recording of the full flow (Loom).
- Tag commit: `git tag -a v2.0-m2`. Push tag.
- Final docs: `docs/USER-GUIDE.md` (basic user manual for the rider), `docs/ADMIN-GUIDE.md` (for the partners).
- Workana approval submission with all evidence.

## Deliverables Checklist (Final)

- [ ] Signed Android APK distributed at `roteirizadorpro.com.br/download`.
- [ ] Login + register flow working against M1 backend.
- [ ] Stop entry: manual + voice + OCR all functional.
- [ ] "Sentido casa" optimization producing routes with last stop nearest to home.
- [ ] Waze and Google Maps deep links working.
- [ ] Efí Pix Split configured: 50/50 between partners, automatic at every payment.
- [ ] Webhook handler activating subscriptions in real time.
- [ ] Paywall blocking "Iniciar Navegação" without active subscription.
- [ ] Real-time subscriber counter visible at top of app.
- [ ] Share screen with WhatsApp + Copy Link + QR Code.
- [ ] Admin panel deployed at `admin.roteirizadorpro.com.br` with dashboard.
- [ ] Signing keystore handed off to client securely (with backup instructions).
- [ ] Loom video showing full end-to-end flow including a real payment.
- [ ] User guide and admin guide authored.

## Risks Tracked During M2

| Risk | Likelihood | Mitigation |
|---|---|---|
| Both partners' Efí accounts not yet approved when M2 starts | Medium | Block M2 start until both are confirmed; switch to sandbox-only development if needed |
| OCR fails on poor-quality labels | High | Always fall back to manual entry; preprocess image (contrast, threshold) before passing to ML Kit |
| Apple-style refusal of "unknown sources" APK install | Low (Android) | Provide a tutorial video on the landing page for first-time installers |
| Efí webhook delivery delays/failures | Low | Idempotent handler; "I paid" button triggers manual status refresh |
| TSP optimization too slow for large stop counts | Low | Cap UI at 25 stops per route; document the limit |
| Keystore loss after handoff | Medium | Document keystore backup procedure prominently; client signs that they received and backed it up |

## Out of Scope For M2

- iOS app.
- Play Store submission.
- Multi-language support (PT-BR only).
- Multi-tier pricing.
- Credit card fallback.
- Geographic expansion beyond Sudeste.
- Real-time GPS / dispatch features.
- Multi-rider team management.
- Refund flow (Efí Pix Split does not support refunds for split-routed cobranças — disclose in T&Cs).
- Cancellation flow with prorated refund (subscription auto-expires after 30 days, that is the cancellation mechanism).

## Post-M2 Opportunities (Not Contracted)

The client may want, after M2 ships, to commission additional work for:

- Play Store publication.
- Geographic expansion (NE, S regions).
- Multi-rider team plan (one subscription, multiple riders).
- iOS app.
- LGPD endpoints (export, delete) — actually we should include these in M2 if time allows; flagging here as compliance risk.
- Native dispute/support flow for failed deliveries.
