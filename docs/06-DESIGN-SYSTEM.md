# 06 — Design System

Design system for Roteirizador Pro. Original identity — does not copy any visual asset from Spoke/Circuit.

**Decided:** 2026-05-06
**Decided by:** Eduardo
**Last sync with prototype:** 2026-05-07

> **Canonical source:** `prototipo/tokens.js` is the source of truth for tokens. This document mirrors that file. If they disagree, `prototipo/tokens.js` wins; update this file.

---

## Brand

**App name:** Roteirizador Pro
**Tagline:** "Entregue mais. Chegue em casa cedo."
**Platform:** Android only (V1)
**Audience:** Brazilian motoboys — practical, fast, working-class

---

## Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#6C3FC5` | Primary actions, FAB, active states, links |
| `primary-dark` | `#4E2D91` | Pressed states, dark variant |
| `primary-light` | `#EDE7F6` | Backgrounds for chips, badges, selected items |
| `accent` | `#9B6DFF` | Secondary highlights, gradients |
| `neon` | `#C6FF3D` | "Live" cues, secondary accent (e.g., active subscriber counter pulse) |
| `neon-dark` | `#9BCC1F` | Pressed state for neon |
| `neon-light` | `#F1FFCC` | Neon background pads |
| `neon-ink` | `#3D5400` | Text on neon background |
| `background` | `#FFFFFF` | Screen background |
| `surface` | `#F8F7FC` | Cards, bottom sheets, input backgrounds |
| `border` | `#E8E4F0` | Dividers, input borders |
| `text-primary` | `#1A1A2E` | Headings, body copy |
| `text-secondary` | `#6B6880` | Subtitles, hints, secondary labels |
| `text-disabled` | `#B0ACC4` | Disabled states |
| `success` | `#22C55E` | Delivered status, checkmarks |
| `error` | `#EF4444` | Failed status, errors |
| `warning` | `#F59E0B` | Pending, warnings |
| `white` | `#FFFFFF` | Text on primary, icons on filled buttons |

**Gradient (optional use on hero areas):**
`linear-gradient(135deg, #6C3FC5 0%, #9B6DFF 100%)`

---

## Typography

**Font family:** Poppins (Google Fonts)

| Style | Weight | Size | Line height | Usage |
|---|---|---|---|---|
| `heading-xl` | SemiBold 600 | 24sp | 32sp | Screen titles |
| `heading-lg` | SemiBold 600 | 20sp | 28sp | Section headers |
| `heading-md` | Medium 500 | 16sp | 24sp | Card titles, modal headers |
| `body-lg` | Regular 400 | 16sp | 24sp | Body text, list items |
| `body-md` | Regular 400 | 14sp | 20sp | Secondary body, descriptions |
| `body-sm` | Regular 400 | 12sp | 16sp | Captions, hints, timestamps |
| `label-lg` | Medium 500 | 14sp | 20sp | Button labels, tab labels |
| `label-sm` | Medium 500 | 12sp | 16sp | Badges, chips, tags |
| `mono` | Regular 400 | 13sp | 18sp | Pix copy-paste code, address numbers |

---

## Spacing

Base unit: **4dp**

| Token | Value | Usage |
|---|---|---|
| `space-1` | 4dp | Icon padding, micro gaps |
| `space-2` | 8dp | Inner padding small |
| `space-3` | 12dp | Inner padding medium |
| `space-4` | 16dp | Standard padding, list item vertical |
| `space-5` | 20dp | Section padding |
| `space-6` | 24dp | Large section gap |
| `space-8` | 32dp | Screen horizontal padding |
| `space-12` | 48dp | Hero spacing |

---

## Border Radius

| Token | Value | Usage |
|---|---|---|
| `radius-sm` | 8dp | Chips, small badges |
| `radius-md` | 12dp | Input fields, cards |
| `radius-lg` | 16dp | Bottom sheets, modals, larger cards |
| `radius-xl` | 24dp | FAB, large buttons |
| `radius-full` | 999dp | Pill buttons, avatar, round badges |

**Philosophy:** All corners rounded. No sharp edges anywhere in the UI.

---

## Elevation / Shadows

Minimal shadow usage — clean, not Material 2 heavy.

| Level | Usage | Shadow |
|---|---|---|
| `elevation-0` | Flat surfaces | none |
| `elevation-1` | Cards in list | `0 1dp 3dp rgba(108,63,197,0.08)` |
| `elevation-2` | Bottom sheets, modals | `0 4dp 16dp rgba(108,63,197,0.12)` |
| `elevation-3` | FAB | `0 6dp 20dp rgba(108,63,197,0.20)` |

---

## Components

### Buttons

**Primary (filled):**
- Background: `primary` (#6C3FC5)
- Text: white, `label-lg`
- Border radius: `radius-xl` (24dp) — pill shape
- Height: 52dp
- Padding: 0 24dp

**Secondary (outlined):**
- Border: 1.5dp `primary`
- Text: `primary`, `label-lg`
- Border radius: `radius-xl`
- Height: 52dp

**Ghost (text only):**
- Text: `primary`, `label-lg`
- No border, no background
- Used for "Já paguei", "Cancelar"

**Destructive:**
- Background: `error` (#EF4444)
- Text: white
- Used for delete confirmations

**Disabled state:** All buttons — opacity 0.4, not clickable.

**Icon button:**
- Circular, 44dp × 44dp
- Background: `surface`
- Icon: `text-primary`

### FAB (Floating Action Button)

- Size: 56dp × 56dp
- Background: gradient `primary` → `accent`
- Icon: white, 24dp
- Border radius: `radius-full`
- Elevation: `elevation-3`
- Position: bottom-right, 20dp margin

### Input Fields

- Height: 52dp
- Background: `surface` (#F8F7FC)
- Border: 1dp `border` (#E8E4F0), focused → 2dp `primary`
- Border radius: `radius-md` (12dp)
- Label: `body-sm`, `text-secondary`, floats on focus
- Text: `body-lg`, `text-primary`
- Padding: 0 16dp

### Cards (Stop Cards)

- Background: white
- Border: 1dp `border`
- Border radius: `radius-lg` (16dp)
- Elevation: `elevation-1`
- Padding: 16dp
- Layout: sequence number | address block | status badge | drag handle

### Badges

**ETA badge:**
- Background: `primary-light` (#EDE7F6)
- Text: `primary`, `label-sm`, SemiBold
- Border radius: `radius-sm` (8dp)
- Padding: 4dp 8dp
- Example: `~14:30`

**Subscriber counter badge (adjacent to ETA):**
- Background: `surface`
- Border: 1dp `border`
- Text: `text-secondary`, `label-sm`
- Border radius: `radius-sm`
- Padding: 4dp 8dp
- Example: `[142]`

**Status badges on stop cards:**
- Pending: background `warning-light`, text `warning`
- Delivered: background `success-light`, text `success`
- Failed: background `error-light`, text `error`

### Bottom Sheets

- Background: white
- Border radius top: `radius-lg` (16dp)
- Handle bar: 4dp × 32dp, `border` color, centered, 8dp from top
- Elevation: `elevation-2`
- Padding: 24dp

### Navigation Bar (bottom)

- Background: white
- Border top: 1dp `border`
- Active icon + label: `primary`
- Inactive icon + label: `text-secondary`
- Height: 64dp

---

## Iconography

**Style:** Outlined, stroke weight 1.5dp, 24dp size.
**Library:** Lucide Icons (open source, MIT license — zero IP risk).

Key icons used:
- `+` / `plus` — add stop FAB
- `map-pin` — stop location
- `home` — home point
- `mic` — voice input
- `camera` — OCR input
- `navigation` — navigate button
- `check-circle` — delivered
- `x-circle` — failed
- `grip-vertical` — drag handle
- `settings` — settings tab
- `share-2` — share screen
- `qr-code` — QR code
- `lock` — paywall locked state
- `chevron-right` — list navigation

---

## Motion

- **Duration:** 200ms for micro-interactions (button press, badge update), 300ms for bottom sheets and modals.
- **Curve:** `easeInOutCubic` for entrances, `easeOutCubic` for exits.
- **Swipe actions:** Spring physics — feel physical.
- **Optimization loading steps:** Each step fades in sequentially, 400ms apart.
- **No decorative animations.** Motion serves function only. No looping animations on the main screen.

---

## Design Principles

1. **Clean over clever.** Every element earns its place. No decorative chrome.
2. **Purple signals action.** Only interactive elements use `primary` purple. Static content is neutral.
3. **White space is intentional.** Generous padding makes the app feel premium.
4. **Rounded is friendly.** Motoboys use this app under stress. Soft corners reduce visual tension.
5. **Single action per screen.** One primary button per view. Never compete for attention.
6. **Text is readable at speed.** Poppins Medium/SemiBold at adequate sizes — drivers glance, not read.
