# 08 — Roadmap v2 (post-pivot)

> **This file is the single source of truth for what we are building, in what order, and what "done" means for each step.** Active plan. When the answer to "should I do X now?" is ambiguous, this file wins. Conflicts with any other doc are resolved by editing this file *and* the other doc in the same commit.

> **Driver:** [ADR-0035](./decisions/0035-spoke-functional-clone-prototype-creative-reference.md) + [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./inventory/2026-05-26-spoke-vs-rotpro.md) §7 (LOCKED 2026-05-26 with Eduardo's 7 directives). The pre-pivot roadmap at [`docs/08-ROADMAP.md`](./08-ROADMAP.md) is SUPERSEDED and kept as historical snapshot only.

**Last updated:** 2026-05-26 (Session 27 — pivot Phase 3).

---

## Status snapshot

| Milestone | Scope summary | Value | Status |
|---|---|---|---|
| **M1** | DO droplet hardened + GraphHopper SP + landing + backend auth + Login/Register screens | BRL 2,000 | ✅ Delivered 2026-05-09 |
| **M2** | Distributable APK + remaining screens functionally replicating Spoke + real route optimization + Stripe Pix paywall + sentido casa + LGPD + admin panel + FCM push | BRL 2,000 | 🟡 In progress (slice 1 ✅; pivot 2026-05-26 expanded slices 2+3 per Eduardo's "replicate all functional" directive) |

Production endpoints (unchanged from v1):

- Landing + APK: `https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk` (when slice 2 ships).
- API: `https://api.roteirizadorpro.com.br/health`.

---

## What "M2 done" means (acceptance for the second BRL 2,000 escrow)

When all 7 slices below are green in production:

1. **APK live and downloadable** at `https://roteirizadorpro.com.br/roteirizador-pro-v<latest>.apk` — slice 1 (✅ shipped as v1.0.0; v1.1.0 ships with slice 2 close).
2. **Spoke functional parity** — every flow a delivery rider expects from Spoke is reachable in Roteirizador Pro with original visual identity per [ADR-0035](./decisions/0035-spoke-functional-clone-prototype-creative-reference.md). Per Eduardo's directive #6: zero mentions of "Spoke" or "Circuit" in UI copy. Per directive #1: replicate first, refine visual divergence later.
3. **`POST /routes/optimize` returns a real optimized route** in under 2 s for 20-stop inputs — slice 3.
4. **Paywall on "Iniciar Navegação"** dispatches Stripe Pix charge; webhook unlocks 30 days; 50/50 split via Stripe Connect — slice 4 (ADR-0030).
5. **"Sentido casa" toggle** in Settings biases route ending toward saved home — slice 5.
6. **LGPD endpoints** for export + delete + `/termos` + `/privacidade` pages — slice 6.
7. **Partner admin panel** with users / payments / metrics — slice 7.

The client signs off on a Loom video walking the seven items, then releases the escrow on Workana.

---

## Operating principles (read before any slice)

1. **Per directive #1 (replicate first, refine later):** when in doubt about a Spoke behavior, mirror it. Visual divergences (color, spacing, typography, decorative animation) come from `prototipo/` and Eduardo's preference. Behavioral divergences require explicit cliente sign-off per ADR-0035.
2. **Per directive #6:** copy is original PT-BR. NEVER copy verbatim microcopy from Spoke into UI strings, error messages, or onboarding text. ADR-0010 already forbids visual asset copy; this principle extends to text.
3. **Per directive #7:** Android only. Any code or doc proposing iOS support is rejected without ADR amendment of ADR-0014.
4. **Spoke deep-dive gate:** any microsprint touching an uninspected flow (see inventory §9) runs a ~30 min adb session BEFORE its `/new-spec`. The inventory document is amended in the same commit as the new spec.
5. **Slice 4/5/6/7 unaffected by pivot:** their content carries over from v1 essentially unchanged. Detail in their sections below.

---

## Source-of-truth hierarchy (per ADR-0035)

For every microsprint:

1. **Spoke** (`com.underwood.route_optimiser` on the licensed M54 install) — canonical for behavior, navigation, settings, gestures, flow ordering. Consult via `docs/inventory/2026-05-26-spoke-vs-rotpro.md` first; deep-dive if the flow isn't covered yet.
2. **`prototipo/`** — canonical for visual identity tokens only (`tokens.js`, `ui.jsx` components for spacing/shadows/radii reference, Lucide icon family per ADR-0032).
3. **Cliente Ueslei** — final tiebreaker.

---

## The seven slices

### Slice 1 — Distributable APK ✅ shipped 2026-05-13 as `v1.0.0`

Unchanged. Documented in ADR-0014 + session logs `2026-05-13-09` and `2026-05-13-10`.

No further work on this slice. APK rebuild as `v1.1.0` happens at slice-2 close (release task).

---

### Slice 2 — Spoke-aligned Telas Core (12-16 days)

**Goal:** every screen and flow that a Spoke user expects exists in Roteirizador Pro with original visual identity. Local state via Riverpod + `SharedPreferencesAsync` for session restore; full DB persistence lands in slice 3.

**Carry-over from v1 sub-slices 2a/2b/2c (DONE — keep):** stops controller + Stop domain model + DTO mirror + repository + Login/Register pages + `ScreenHomeEmpty` + `ScreenHomeList` (with all session-26 polish: Lucide FAB + grip handle + neon dot removed) + AddStopSheet (3 method buttons) + Voice page (pulse + amplitude + auto-restart) + OCR page + MapStops + AddStopsMap + Reorder + StopDetail + EditStop + Optimize (mock) + OptimizeRoute + Navigate + RouteComplete + ShareSheet (WhatsApp + link + QR) + SettingsPage (5-row stub). 173/173 tests green at last push (`5c104c7`).

**Microsprints (locked names: MS-A1..MS-A8 to mark the post-pivot recommencement):**

| Microsprint | Scope | Est. | Dependencies | Spoke deep-dive needed? |
|---|---|---|---|---|
| **MS-A1** | **Conceito de "Rota" como entidade.** New `Route` domain model + `RoutesController` + `SharedPrefsRoutesRepository` + screen `RoutesListPage` (replaces / wraps `HomeListPageOrEmpty` as new home) + screen `CreateRouteWizard` (nome opcional + data Hoje/Amanhã/Outra). Each `Stop` now belongs to a `Route`. Migration path: old global stops bag becomes "rota de hoje" automaticamente no primeiro boot pós-update. | 3-4 d | TODO.md slice-2a state | ❌ Spoke wizard inspecionado §6.2 |
| **MS-A2** | **Google Sign-In** + recuperação de senha (UI only — backend wires in MS-B2). Apple/Facebook explicitly excluded per directive #2. Login + Register screens get a third "Continuar com Google" button matching prototype `PrimaryButton`/`GhostButton` styling. | 1-2 d | nothing | ⚠️ Yes — Spoke login screen não inspecionado |
| **MS-A3** | **Stop model expansion.** Add `Stop.status` (enum `pending`/`delivered`/`failed`+`failureReason`) + `Stop.notes` + `Stop.podPhotoPath` (local until MS-B5 backend persistence) + `Stop.complement` (a2 line per inventory §3.4). Update DTO, controller, all consumers. `StopDetailPage` body expanded with Entregue/Falhou/Próxima action triplet + notes input + photo picker shell. | 2-3 d | MS-A1 | ❌ Inferred from inventory §3.4 |
| **MS-A4** | **Settings completas Spoke-aligned.** Add 8 new rows: Lado da parada, Tempo médio na parada, Tipo de veículo (Carro/Moto/Bicicleta/A pé), Evitar pedágios, Tema (Auto/Claro/Escuro), ID de parada (estilo display), Balão do modo de navegação, Versão do app exibida. SettingsPage restructured into 3 sections matching Spoke hierarchy: Preferências de rota / Preferências gerais / Conta. Theme toggle wires `MaterialApp.themeMode`. | 2-3 d | nothing | ✅ Spoke settings inspecionado §5 |
| **MS-A5** | **Copiar paradas (clipboard)** + **menu kebab da rota** com opções: Compartilhar cópia + Copiar paradas + Importar manifesto (stub, MS-B7) + Ler manifesto (stub, MS-B6) + Transferir paradas (stub, MS-B7). Implements `kebab → action sheet` pattern with Lucide icons. | 1 d | MS-A1 | ⚠️ Yes — Spoke kebab inspecionado parcialmente §6.4 |
| **MS-A6** | **Tela "Comparar planos" (pricing page)** — pré-req do slice 4 paywall. Mostra Plano Gratuito (current) vs Plano Pago R$ 25,90/30 dias com bullets de features. CTA "Assinar" stub que abre o flow do slice 4 (em MS-A6 ainda é placeholder; ativa quando slice 4 estiver pronta). | 1-2 d | MS-A4 (settings cita esta tela) | ⚠️ Yes — paywall Spoke não inspecionado |
| **MS-A7** | **Tela de preferências de notificação** — pré-req do FCM (MS-B8). Lista de toggles: "Lembrete de início de rota", "Atualização de status da rota", "Promoções". Persiste em SharedPrefs até MS-B8 plumb endpoint real. | 1 d | MS-A4 | ❌ Inferred (Spoke tem FCM por causa do MessagingService no manifest) |
| **MS-A8** | **Slice 2 release** — rebuild APK como `v1.1.0`, sweep visual de toda divergência pendente vs prototipo (per directive #1 "ajusta depois"), `prototype-fidelity-checker` (visual-only post-ADR-0035) sobre cada Dart file novo, `flutter-perf-auditor` sobre as 3 telas mais complexas (RoutesList, StopDetail expandida, MS-A4 settings), `flutter analyze` + `flutter test` clean, `aapt2 dump permissions`, `apksigner verify`, E2E M54, PR `feat/m2-slice-2-telas-core` → `develop` → tag `v1.1.0`. | 2 d | MS-A1..A7 | n/a (gate) |

**ADRs to file during slice 2:**
- ADR-0036: Route entity introduction (data model change; major impact)
- ADR-0037: Google Sign-In integration (auth provider choice + library — `google_sign_in` package; cite Context7)
- ADR-0038: Theme mode toggle (Material 3 dynamic theming + system follow)

**Carry-over verifications (M2-SLICE-CHECKLIST.md):**
- Curl smoke `POST /routes/optimize` (still mock 200; real solver in slice 3)
- `aapt2 dump permissions` lists existing + any new (FCM might add `POST_NOTIFICATIONS`)
- `apksigner verify` cert SHA-256 unchanged
- E2E real-device M54 — extended golden path covering new flows (Criar Rota wizard + Status por parada + Comparar Planos + Notification settings)

---

### Slice 3 — Real backend for Spoke parity (10-14 days)

**Goal:** all Slice 2 UI surfaces back-end-real. `POST /routes/optimize` returns optimized output under 2s; geocoding lives; status/notes/POD persist; push notifications send; history queries return.

**Microsprints:**

| Microsprint | Scope | Est. | Dependencies | Spoke deep-dive needed? |
|---|---|---|---|---|
| **MS-B1** | **GraphHopper tag pinning + amendment** to ADR-0008. Pin from `:latest` to stable tag (likely `:9.1`), re-validate `config.yml graph.encoded_values`, rebuild graph-cache, `benchmark.sh` p95 < 200ms. Carried tech debt from session 2026-05-24-21. | 1 d | nothing | n/a |
| **MS-B2** | **Backend auth additions.** Google Sign-In token verification endpoint (`POST /auth/google { idToken }`) returning JWT pair. Password reset flow (`POST /auth/forgot-password { email }` → email link → `POST /auth/reset-password { token, newPassword }`). Wire MS-A2 UI. | 2 d | MS-A2 (UI) | n/a |
| **MS-B3** | **Solver + Nominatim self-hosted.** File **ADR-0039** (solver design: nearest-neighbor + 2-opt) + **ADR-0040** (Nominatim self-hosted SP-Capital, ~4GB RAM ~R$ 120/mês per cost model). Implement `apps/backend/src/routes/solver.ts` (~150 LOC TS, no deps). `POST /geocode` backed by Nominatim. Distance matrix via `Promise.all` GraphHopper calls + Redis cache (5min TTL). Replace 501 → real `POST /routes/optimize`. | 3-4 d | MS-B1 | n/a |
| **MS-B4** | **Routes persistence (entity from MS-A1 goes to DB).** Prisma migration: `routes` + `route_stops` tables. Endpoints: `GET /routes` (list), `POST /routes` (create), `GET /routes/:id`, `PATCH /routes/:id`, `DELETE /routes/:id`. Mobile: swap `SharedPrefsRoutesRepository` (MS-A1) for `ApiRoutesRepository`. SharedPrefs becomes cache layer only. | 2 d | MS-A1 + MS-B3 | n/a |
| **MS-B5** | **Stop status + notes + POD persistence.** Prisma migration: add `status`, `failure_reason`, `notes`, `pod_photo_url` columns to `stops`. POD photo upload endpoint (`POST /stops/:id/pod-photo` multipart → S3-compatible storage; DO Spaces or similar). Mobile: photo picker writes to backend; thumbnail download for history. Reutilizar paradas: `GET /routes/:id/copy-stops-to/:targetRouteId`. | 2-3 d | MS-A3 + MS-B4 | ⚠️ Spoke POD UI não inspecionado |
| **MS-B6** | **OCR multi-stop (manifesto) + multi-address dictation.** Voice flow gains "fale vários endereços" CTA (per inventory §3.2#10b — Spoke trata como first-class). Voice transcript segmentação por pauseFor + pontuação; cada segmento vira geocoding call separado + confirmação inline. OCR gains "ler manifesto" entry: foto de lista impressa → ML Kit text recognition → linhas viram candidatos de paradas + UI de confirmação batch. | 2-3 d | MS-B3 (geocoding) | ⚠️ Spoke OCR full não inspecionado |
| **MS-B7** | **Importar manifesto (CSV/Excel) + Transferir paradas.** Importer: file picker → CSV/XLSX parser (`csv` + `excel` Dart packages — Context7 verify) → UI de mapeamento de colunas (endereço, complemento, observação) → batch geocoding → batch insert. Transferir paradas: source rota + target rota seletor. | 2-3 d | MS-B4 + MS-B6 | ⚠️ Spoke importer UI não inspecionado |
| **MS-B8** | **FCM push notifications.** Firebase setup (free tier 1M/msg). Backend: `firebase-admin` SDK + `POST /notifications/send` internal endpoint + cron triggers (lembrete início de rota X min antes do horário planejado). Mobile: `firebase_messaging` Flutter pkg, handler de notification → deep link pra tela relevante. Wire MS-A7 preferences. | 2 d | MS-A7 + MS-B4 | ❌ FCM é nosso — sem deep-dive |
| **MS-B9** | **Histórico de rotas + métricas básicas.** Endpoint `GET /routes/history?period=...` retorna lista paginada com totais (paradas, entregues, falhas, km, tempo). Tela mobile `RoutesHistoryPage` (acessível via tab Rota → "Histórico" ou direto da `RoutesListPage`). | 1-2 d | MS-B4 + MS-B5 | ⚠️ Spoke histórico não inspecionado |

**ADRs to file:** ADR-0008 amendment (MS-B1) + ADR-0036/0037/0038 (slice 2) + ADR-0039 solver + ADR-0040 Nominatim hosted + possivelmente ADR-0041 FCM setup + ADR-0042 importer parser strategy.

**Test plan:**
- Solver: synthetic SP-area test set de 5/10/20 stops; assert p95 < 2 s; assert improvement ≥ 20% vs input-order baseline
- POD: upload via mobile → download via admin (slice 7) → verifica integridade
- FCM: trigger sandbox notification → mobile recebe → tap deep links pra rota certa
- Importer: CSV de 50 stops → batch geocode → 95%+ resolvido

---

### Slice 4 — Stripe Pix paywall, 30-day access pass (4-6 days)

> Gateway + model: **ADR-0030** (supersedes ADR-0007). Operational rules in `docs/BUSINESS-RULES.md`.

**Unchanged from v1.** Conteúdo verbatim do roadmap original (carregado como histórico aqui pra completude da v2):

**Goal:** "Iniciar Navegação" → Pix QR → R$ 25,90 → webhook → 30 days unlock. 50/50 split via Stripe Connect (Separate Charges and Transfers).

**Prerequisites Eduardo collects before this slice:**
1. Stripe platform account com Pix payment method approved (Pix invite-only BR — confirmado 2026-05-24)
2. Two Connected Accounts (`STRIPE_CONNECTED_ACCOUNT_SOCIO_1`, `_2`)
3. Webhook endpoint configurado: `https://api.roteirizadorpro.com.br/webhooks/stripe` + `STRIPE_WEBHOOK_SECRET`
4. API keys `STRIPE_SECRET_KEY` (live + test)

**Implementation (per ADR-0030):**
- Backend `apps/backend/src/payments/` (stripe_client, schemas, handlers, webhook_handlers, routes)
- `POST /payments/pix-intent { userId }` → returns `next_action.pix_display_qr_code`
- `POST /webhooks/stripe` → validate signature → dedupe `stripeEventId` → 2× `stripe.transfers.create` (50/50) → upsert `subscription` (expires_at = now+30d) → 200
- Prisma migration `subscription` + `webhook_events` tables
- Daily cron 03:00 BRT flips expired subscriptions to inactive
- Mobile `apps/mobile/lib/features/payments/` (DTO, controller, `PaywallPage`) — `ScreenPaywall` mostra QR + Pix copy-and-paste; polls `GET /subscription/status` cada 5s
- "Iniciar Navegação" gate desbloqueia se `subscription.status='active'` && `expires_at > now()`
- "Comparar Planos" page (MS-A6 já criou a UI estática) ganha tap no CTA "Assinar" que dispatches pix-intent

**Forbidden** (BUSINESS-RULES.md §8): qualquer `DELETE /subscription`, `cancel`, `refund`, `stripe.subscriptions.*`, Stripe Billing, "cancelar assinatura" UI.

---

### Slice 5 — Sentido casa (1 day)

**Unchanged from v1.**

- 2 colunas no `users` (`home_lat`, `home_lng`)
- Toggle em SettingsPage (MS-A4 deixou o slot pronto) "Otimizar rota voltando pra casa"
- Branch no solver (slice 3 MS-B3): home como "stop N+1" com return leg gratuito; minimiza distância total com essa constraint
- Unit test do solver: home-bias on vs off, assert permutação termina no stop mais perto de (home_lat, home_lng)

---

### Slice 6 — LGPD (2-3 days)

**Unchanged from v1 + adição: Licenças OSS movida pra cá (gap §3.3#26 do inventário).**

**Goal:** legal compliance LGPD + Android Play Store ready (licenças).

- File ADR-0020 (LGPD compliance approach)
- `GET /me/export` → JSON dump auth-gated (email, name, phone, routes, payments) em `apps/backend/src/users/export_handlers.ts`
- `DELETE /me` → soft-delete (`deleted_at`), revoke refresh tokens, remove PII, anonimizar payments
- Landing `/termos` + `/privacidade` — static MDX em `apps/landing/src/app/(legal)/`
- Mobile: tela "Licenças OSS" em Settings (Conta) — usa `flutter_oss_licenses` package ou similar (Context7 verify) pra gerar lista automática
- Linkar `/termos` + `/privacidade` no Register screen + footer

---

### Slice 7 — Painel admin (3-5 days)

**Unchanged from v1.**

- File ADR-0021 (admin authorization model)
- Add `admin` role na User table (Prisma migration)
- Backend `apps/backend/src/admin/`: `GET /admin/users`, `/admin/payments`, `/admin/metrics`
- Frontend `apps/landing/src/app/(admin)/`: layout com auth guard + users/payments/metrics pages
- Metrics: DAU (count distinct users com rota nas últimas 24h), Receita 30 dias (R$ 25,90 × passes ativados), Paradas-dia (avg stops per active user per day)

---

## Total estimated work

| Slice | Estimate |
|---|---|
| 1 — APK | ✅ shipped |
| 2 — Spoke-aligned Telas Core | 12-16 d |
| 3 — Real backend | 10-14 d |
| 4 — Stripe Pix paywall | 4-6 d |
| 5 — Sentido casa | 1 d |
| 6 — LGPD + Licenças | 2-3 d |
| 7 — Painel admin | 3-5 d |
| **Total v2** | **32-45 dias úteis** (~6-9 semanas calendário) |

**Comparação:** v1 estimava 17-25 dias úteis pré-pivot. v2 é ~80-90% maior por causa da diretiva #1 (replicate everything). Eduardo aceitou explicitamente "documentar e seguir" sem cortes adicionais. Decisão de renegociar prazo Workana ou aceitar overrun fica com Eduardo, em conversa separada.

---

## Cost model (summary; full breakdown in [`M2-COST-MODEL.md`](./M2-COST-MODEL.md))

Cost ceiling unchanged: **≤ BRL 200/mês total de infra durante beta**.

Novo na v2:
- **FCM (push notifications):** gratuito até 1M msg/mês — fica sob o ceiling
- **Nominatim self-hosted SP-Capital:** ~R$ 120/mês na DO 4GB droplet upgrade (cabe no ceiling se mantermos GraphHopper na mesma droplet)
- **POD photo storage:** DO Spaces ~R$ 25/mês para 250GB+CDN — cabe

Cortados da v2:
- Intercom (~US$ 39/mês) — descartado per diretiva
- Sentry paid tier — usar free tier se ativarmos pós-M2

---

## Documentation map

- `CLAUDE.md` — operating manual (Karpathy 4 + stack lock + Context7 + ADR-0013 + ADR-0035 hierarchy)
- `docs/01-PROJECT.md` — vision/scope (post-pivot)
- `docs/02-ARCHITECTURE.md` — flows/schemas/contracts
- `docs/03-CONVENTIONS.md` — naming/style/layout
- `docs/04-FEATURES.md` — feature catalogue (canonical business rules)
- `docs/05-SCREENS.md` — screen catalogue (post-pivot — Spoke functional + prototipo visual)
- `docs/06-DESIGN-SYSTEM.md` — visual tokens (canonical from `prototipo/tokens.js`)
- `docs/07-INFRA.md` — infrastructure
- `docs/08-ROADMAP.md` — pre-pivot historical snapshot (SUPERSEDED)
- `docs/08-ROADMAP-v2.md` — **this file** (active)
- `docs/09-DISASTER-RECOVERY.md` — DR
- `docs/10-CHANGELOG.md` — changelog
- `docs/BUSINESS-RULES.md` — Stripe + Play Store operational rules
- `docs/M2-SLICE-CHECKLIST.md` — slice verification gates (updated per ADR-0035)
- `docs/M2-COST-MODEL.md` — cost ceiling
- `docs/inventory/2026-05-26-spoke-vs-rotpro.md` — Spoke functional reference (consult per microsprint)
- `docs/decisions/` — all ADRs (ADR-0035 is the pivot foundational; ADRs 0021/0032/0033/0034 reframed)
- `docs/sessions/` — session logs

---

## Read-first map for the next agent

When picking up work on this branch (`feat/m2-slice-2-telas-core` or successor):

1. `CLAUDE.md` (operating manual)
2. `docs/08-ROADMAP-v2.md` (this file)
3. `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §3 + §7 + §9 (active scope)
4. `docs/decisions/0035-spoke-functional-clone-prototype-creative-reference.md` (foundational pivot)
5. The most recent session log in `docs/sessions/`
6. The next-microsprint section above (MS-A1 is next if no microsprint is in flight)
7. `docs/M2-SLICE-CHECKLIST.md` for verification gates
8. The relevant Spoke flow inspection (if needed per microsprint deep-dive gate)
