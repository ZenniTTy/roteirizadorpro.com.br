# DESIGN-PROMPT.md — Prototype Generation Prompt

Ready-to-use prompt for Claude Artifacts and Google Stitch to generate a complete UI prototype of Roteirizador Pro.

Copy the content inside the `---PROMPT START---` / `---PROMPT END---` markers and paste directly into the tool.

---PROMPT START---

## Project

Design a complete Android app prototype called **Roteirizador Pro** — a route planning app for Brazilian delivery riders (motoboys). The app is a functional fork of Spoke/Circuit Route Planner with a fully original visual identity.

---

## Visual Identity (mandatory — apply to every screen)

**Color palette:**
- Primary: `#6C3FC5` (deep purple) — use for all CTAs, FAB, active states, links
- Primary dark: `#4E2D91` — pressed/hover states
- Primary light: `#EDE7F6` — badge backgrounds, selected chips
- Accent: `#9B6DFF` — gradients, secondary highlights
- Background: `#FFFFFF` (pure white)
- Surface: `#F8F7FC` (off-white) — cards, inputs, bottom sheets
- Border: `#E8E4F0` — dividers, input borders
- Text primary: `#1A1A2E`
- Text secondary: `#6B6880`
- Success: `#22C55E`
- Error: `#EF4444`
- Warning: `#F59E0B`

**Typography:** Poppins (Google Fonts) throughout. SemiBold for headings and button labels, Regular for body, Medium for secondary labels.

**Border radius:** All corners rounded. Cards: 16dp. Buttons: 24dp (pill). Inputs: 12dp. Bottom sheets: 16dp top corners. FAB: circular.

**Shadows:** Subtle purple-tinted shadows only. Cards: `0 1dp 3dp rgba(108,63,197,0.08)`. Bottom sheets: `0 4dp 16dp rgba(108,63,197,0.12)`.

**Style:** Modern, clean, minimalist. White dominant. Purple accent only on interactive elements. Generous white space. No decorative elements.

**Icon library:** Lucide Icons style (outlined, 1.5dp stroke, 24dp).

---

## Screens to Design (12 screens)

Design ALL 12 screens below. Each screen must be a realistic Android mobile frame (390×844dp or similar).

---

### Screen 1 — Login

**Layout:**
- Top: App logo (purple circular icon with route lines) + "Roteirizador Pro" in Poppins SemiBold
- Tagline below logo: "Entregue mais. Chegue em casa cedo." in text-secondary
- Large white space below
- Input field: "E-mail" with surface background, rounded corners
- Input field: "Senha" with password toggle eye icon
- "Entrar" primary button (full width, purple, pill shape)
- Divider "ou" between button and Google option
- "Continuar com Google" outlined button
- Bottom text: "Não tem conta? Cadastre-se" in primary purple

**States to show:** Default state (empty fields).

---

### Screen 2 — Register

**Layout:**
- Back arrow top left
- Title: "Criar conta"
- Four inputs stacked: Nome completo, E-mail, Telefone (with +55 prefix), Senha
- "Criar conta" primary button full width
- Bottom text: "Já tem conta? Entrar"

---

### Screen 3 — Home / Empty State

**Layout:**
- Status bar
- Top bar: 
  - Left: "Rota de hoje" in heading-md
  - Right: Two small badges side by side:
    - ETA badge (greyed out): `--:--` in primary-light background, purple text, rounded
    - Subscriber counter badge: `[0]` in surface background, border, text-secondary
- Large centered illustration area: simple minimalist icon of a motorcycle + dashed route line (purple tones)
- Centered copy: "Nenhuma entrega ainda" heading, "Adicione sua primeira parada para começar" in text-secondary
- FAB bottom right: circular, purple gradient, white `+` icon, with subtle shadow

---

### Screen 4 — Home / Route List (with stops)

**Layout:**
- Top bar same as Screen 3 but with:
  - ETA badge active: `~14:30` in primary-light, purple text
  - Subscriber counter: `[47]`
  - Overflow menu icon (⠇) far right
- Stop list (show 5-6 stops):
  - Each card: white background, border, 16dp radius, 16dp padding
  - Card layout: 
    - Left: sequence number circle (purple filled, white number, 28dp)
    - Middle: address line 1 (bold, text-primary) + address line 2 (text-secondary, smaller)
    - Right: drag handle (6 dots, text-secondary) + status badge
  - Status badges: one "Pendente" (warning yellow), two "Entregue" (success green, slightly faded), rest "Pendente"
  - Gap between cards: 8dp
- "Otimizar rota" button: full width, purple, above FAB
- FAB: `+` for adding more stops

**Show swipe hint on one card:** left side revealing red delete button.

---

### Screen 5 — Add Stop (Bottom Sheet)

**Layout:**
- Dimmed overlay behind the sheet
- Bottom sheet rises from bottom, rounded top corners
- Handle bar at top center
- Title: "Adicionar parada"
- Search input field at top of sheet: "Digite o endereço ou CEP..." with search icon left
- Three input method buttons in a row below input:
  - "Teclado" (keyboard icon) — active/selected state in primary-light
  - "Voz" (mic icon) — default state
  - "Câmera" (camera icon) — default state
- Autocomplete dropdown (3-4 results below search):
  - Each result: map-pin icon + address text, divider between items
  - First result highlighted in primary-light
- "Adicionar parada" primary button at bottom of sheet

---

### Screen 6 — Voice Input

**Layout:**
- Full screen overlay (white background)
- Back arrow top left
- Title: "Falar endereço"
- Centered large animated mic indicator:
  - Circular pulse rings in primary-light expanding outward
  - Center circle in primary purple with white mic icon
- "Ouvindo..." label below in text-secondary
- Transcription text area (rounded card): shows live transcription in italic text-secondary
- Two buttons at bottom: "Parar" (outlined) | "Tentar novamente" (ghost)

---

### Screen 7 — OCR Scanner

**Layout:**
- Full camera viewfinder (dark background)
- Rectangular framing overlay in center: white/purple corner brackets, dashed border
- Label above frame: "Aponte para a etiqueta do pacote" in white
- Capture button: large circular white button at bottom center, purple camera icon
- Cancel button top left: white × icon

**Below the scanner (show a second state — result found):**
- White card slides up from bottom
- "Endereço encontrado:" label
- Extracted address displayed in heading-md purple
- "Confirmar" primary button + "Editar" ghost button

---

### Screen 8 — Route Optimization Loading

**Layout:**
- White background
- Centered vertically
- App logo small at top
- Animated route illustration: dots connecting into optimized path (purple animated)
- Three sequential status lines (show all three, with checkmarks on completed):
  - ✓ "Analisando suas paradas..." (checked, success green)
  - ✓ "Calculando tráfego..." (checked, success green)
  - ◉ "Encontrando o melhor caminho para casa..." (active, pulsing purple dot)
- Progress bar at bottom: purple fill, rounded, about 80% full

---

### Screen 9 — Stop Detail

**Layout:**
- Top bar: back arrow + "Parada 3 de 8"
- Map thumbnail (placeholder grey map with purple pin, 180dp height, rounded corners)
- Address card below map:
  - Full address in heading-md
  - "Entrega" badge (primary-light, purple text, rounded)
- Action buttons row (three equal buttons):
  - "Entregue" (success green, rounded, check icon)
  - "Falhou" (error red, rounded, x icon)
  - "Próxima" (outlined purple, arrow icon)
- "Iniciar Navegação" primary button full width, purple — **show LOCKED state with lock icon** (greyed out, 0.5 opacity)
- Small text below locked button: "Assine para navegar →" in primary purple, tappable
- Move options section: "Tornar próxima" | "Mover para o início" | "Mover para o final" as text rows with chevron right

---

### Screen 10 — Subscription / Paywall Modal

**Layout:**
- Appears as bottom sheet over the Stop Detail (dimmed overlay)
- Handle bar at top
- Small lock icon in primary-light circle at top center of sheet
- Heading: "Desbloqueie a navegação" in heading-lg, centered
- Subtext: "Assine e comece a navegar agora" in text-secondary, centered
- Price block (centered, with subtle purple border card):
  - "R$ 25,90" in heading-xl, primary purple
  - "/mês via Pix" in body-sm text-secondary below
- Checkmark list (3 items):
  - ✓ Rotas ilimitadas
  - ✓ Otimização sentido casa
  - ✓ Suporte prioritário
- "Pagar com Pix" primary button full width, purple, Pix logo icon left

**Second state (after tapping "Pagar com Pix" — show as inset):**
- QR Code centered (white square with black QR pattern, purple border)
- "ou copie o código:" label
- Pix code in mono font in surface card with "Copiar" button right-aligned
- "Já paguei" ghost button below

---

### Screen 11 — Settings

**Layout:**
- Top bar: "Configurações" title
- Sections with group headers in label-sm text-secondary uppercase:

**NAVEGAÇÃO**
- "App de GPS padrão" row: label left, "Waze" with Waze color icon right + chevron

**ROTA**
- "Minha casa" row: label left, address text right + chevron (or "Não definida" in text-secondary)

**CONTA**
- "E-mail" row: email address right
- "Alterar senha" row
- "Minha assinatura" row: "Ativa até 05/06/2026" in success green right + chevron

**SOBRE O APP**
- "Versão" row: "1.0.0" right
- "Política de privacidade" row + chevron
- "Suporte" row + chevron

**Bottom (danger zone):**
- "Sair da conta" in error red, left-aligned, no chevron

---

### Screen 12 — Share / Referral

**Layout:**
- Top bar: back arrow + "Indique o app"
- Subtitle: "Passe o link para outro motoboy" in text-secondary
- Three action cards stacked (white, border, 16dp radius):

**Card 1 — WhatsApp:**
- WhatsApp green icon left
- "Compartilhar no WhatsApp" label in body-lg
- "Abre o WhatsApp com mensagem pronta" in body-sm text-secondary
- Chevron right

**Card 2 — Copiar link:**
- Link icon left (primary purple)
- "Copiar link de download" label
- "roteirizadorpro.com.br/download" in mono text-secondary
- Copy icon right (on tap shows "Copiado!" feedback)

**Card 3 — QR Code:**
- QR Code icon left (primary purple)
- "Mostrar QR Code" label
- "Outro motoboy escaneia direto" in text-secondary
- Chevron right

**Below the cards:** QR Code expanded (show it revealed, white card with black QR pattern and purple border, 200dp × 200dp centered)

---

## Global Components (show on a separate components page if possible)

- Primary button (default, pressed, disabled states)
- Stop card (pending, delivered, failed states)
- ETA badge + subscriber counter badge together
- Bottom navigation bar (2 tabs: Rota, Configurações — "Rota" active)
- Input field (default, focused, error states)
- Status badges (Pendente, Entregue, Falhou)

---

## Key UX Rules (maintain across all screens)

1. White background (#FFFFFF) on all screens — never grey background at screen level.
2. Purple (#6C3FC5) only on interactive elements. Static content is neutral.
3. Every screen has exactly one primary action (one purple filled button).
4. All corners are rounded — no sharp 90° corners anywhere.
5. Bottom sheets always have a handle bar and 16dp top radius.
6. FAB always purple gradient, bottom-right, 56dp × 56dp.
7. Typography is always Poppins. Never fall back to system font.
8. The "Iniciar Navegação" button is always shown in locked/greyed state unless subscription is active.
9. Status bar: white background, dark content (Android light theme).

---

## What NOT to include

- No maps rendered inside the app screens (only static placeholder thumbnails where needed)
- No bottom navigation on Login/Register/Onboarding screens
- No hamburger menu — navigation is minimal (bottom nav + back arrows)
- No notification banners or complex overlays beyond what is specified above
- Do not use any green as a primary/accent color — green is reserved for "Delivered" status only

---PROMPT END---
