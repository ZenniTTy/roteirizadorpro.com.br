# 05 — Screens

The screen catalogue for Roteirizador Pro. Two source-of-truth layers per **ADR-0035**:

- **Behavior, gestures, flow, settings inventory** → trace to Spoke (ex-Circuit Route Planner) via `docs/inventory/2026-05-26-spoke-vs-rotpro.md`.
- **Visual identity** (colors, spacing, radii, shadows, typography, icon family, animations) → trace to `prototipo/` (Claude Design prototype, client-approved 2026-05-07).
- **Tiebreaker** → cliente Ueslei.

The screen list below is a working catalogue. Entries that match a Spoke screen mark "Spoke-aligned" (functional parity expected); entries that are original to Roteirizador Pro (`ScreenShare`, Pix paywall) mark "RotPro-original" (we own the flow). Visual identity for every screen comes from the prototype regardless.

> Per `docs/decisions/0010-clone-positioning.md`: replicate Spoke's functionality, never its visual assets.

## Prototype screen map (19 screens)

Listed in the order they appear in `prototipo/Roteirizador Pro.html`. Each entry: section, screen ID, label, milestone scope, **M2 slice that ships it**, and prototype source file (`prototipo/screens-{a,b,d,e}.jsx`).

> Slice mapping is the single source of truth for "when does this screen ship?". Order of work lives in `docs/08-ROADMAP-v2.md` (v1 archived 2026-05-26 to `docs/archive/` per ADR-0035). The slice/sub columns below reflect the pre-pivot decomposition; under the v2 plan slice 2 microsprints are MS-A1..MS-A8 and slice 3 microsprints are MS-B1..MS-B9 — check the v2 roadmap for which microsprint ships which screen post-pivot.

### Section 01 — Authentication

| ID | Label | Milestone | Slice | Prototype source | Status |
|---|---|---|---|---|---|
| `login` | 01 · Login | M1 | — | `screens-a.jsx → ScreenLogin` | ✅ shipped |
| `register` | 02 · Criar conta | M1 | — | `screens-a.jsx → ScreenRegister` | ✅ shipped |

### Section 02 — Route

| ID | Label | Milestone | Slice | Prototype source | Status |
|---|---|---|---|---|---|
| `home-empty` | 03 · Home vazia | M2 | slice 2 / sub 2a | `screens-a.jsx → ScreenHomeEmpty` | ⏳ |
| `home-list` | 04 · Lista de paradas | M2 | slice 2 / sub 2a | `screens-a.jsx → ScreenHomeList` | ⏳ |
| `map-stops` | 05 · Mapa da rota | M2 | slice 2 / sub 2c | `screens-d.jsx → ScreenMapStops` | ⏳ |
| `add-stops-map` | 06 · Adicionar pelo mapa | M2 | slice 2 / sub 2b | `screens-e.jsx → ScreenAddStopsMap` | ⏳ |
| `add-stop` | 07 · Adicionar (busca) | M2 | slice 2 / sub 2b | `screens-a.jsx → ScreenAddStop` | ⏳ |
| `edit-stop` | 08 · Editar parada | M2 | slice 2 / sub 2c | `screens-e.jsx → ScreenEditStop` | ⏳ |

### Section 03 — Address capture

| ID | Label | Milestone | Slice | Prototype source | Status |
|---|---|---|---|---|---|
| `voice` | 09 · Voz | M2 | slice 2 / sub 2b | `screens-a.jsx → ScreenVoice` | ⏳ |
| `ocr` | 10 · Scanner OCR | M2 | slice 2 / sub 2b | `screens-b.jsx → ScreenOCR` | ⏳ |
| `optimize-loading` | 11 · Otimizando rota | M2 | slice 2 / sub 2d (shell) → slice 3 (real solver) | `screens-b.jsx → ScreenOptimize` | ⏳ |
| `optimize` | 12 · Rota otimizada | M2 | slice 2 / sub 2d | `screens-e.jsx → ScreenOptimizeRoute` | ⏳ |
| `reorder` | 13 · Reordenar (laço) | M2 | slice 2 / sub 2c | `screens-e.jsx → ScreenReorder` | ⏳ |

### Section 04 — Delivery + subscription

| ID | Label | Milestone | Slice | Prototype source | Status |
|---|---|---|---|---|---|
| `stop-detail` | 14 · Detalhe da parada | M2 | slice 2 / sub 2c | `screens-b.jsx → ScreenStopDetail` | ⏳ |
| `navigate` | 15 · Navegação turn-by-turn | M2 | slice 2 / sub 2d (shell) → slice 4 (paywall gate) | `screens-e.jsx → ScreenNavigate` | ⏳ |
| `route-complete` | 16 · Rota concluída | M2 | slice 2 / sub 2d | `screens-e.jsx → ScreenRouteComplete` | ⏳ |
| `paywall` | 17 · Paywall (Pix) | M2 | slice 4 | `screens-b.jsx → ScreenPaywall` | ⏳ |

### Section 05 — Account

| ID | Label | Milestone | Slice | Prototype source | Status |
|---|---|---|---|---|---|
| `settings` | 18 · Configurações | M2 | slice 2 / sub 2e (structure) → slice 4 (paywall block) → slice 5 (home address) | `screens-b.jsx → ScreenSettings` | ⏳ |
| `share` | 19 · Indique o app | M2 | slice 2 / sub 2e | `screens-b.jsx → ScreenShare` | ⏳ |

## M1 screen detail

The two M1 screens are detailed here. M2 screens are documented at "what they are" level above; each slice's PR carries the precise interaction spec for the screens it ships, cross-referenced back to this catalogue.

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

The functional behavior of the app — drag-to-reorder, swipe-to-complete, soft paywall on navigation, list-first UX — is **fully replicated from Spoke/Circuit Route Planner** per ADR-0010 (functional fork) and ADR-0035 (Spoke is canonical for behavior). Visual identity is original (from `prototipo/`). This table is a high-level summary; the **authoritative scope decisions** (what we replicate, adapt, postpone, or discard) live in `docs/inventory/2026-05-26-spoke-vs-rotpro.md` §3 (43 gap items) + §7 (LOCKED decisions per cliente's 7 directives). If this table conflicts with the inventory, the inventory wins — edit both in the same commit.

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
