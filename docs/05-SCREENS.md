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
