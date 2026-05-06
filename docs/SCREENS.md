# SCREENS.md — Screen Map (Spoke/Circuit Reference)

Functional reference map of Spoke Route Planner (formerly Circuit) screens. Used as the blueprint for Roteirizador Pro's UX. Sourced from public documentation, App Store/Play Store listings, help center articles, and ScreensDesign analysis.

**Important:** We replicate flows, hierarchy, and UX patterns — NOT icons, colors, typography, or visual assets. See ADR-0010.

**Sources:**
- https://help.spoke.com (help center)
- https://spoke.com/route-planner/product-updates
- https://play.google.com/store/apps/details?id=com.underwood.route_optimiser
- https://screensdesign.com/showcase/circuit-route-planner
- https://kardinal.ai/circuit-app-for-route-planning-review-and-alternatives

---

## Navigation Structure

```
App
├── Onboarding (1 step — minimal, no forced tutorial)
│   └── Account creation / Login
│
├── Home — Route List (main screen)
│   ├── Empty state (no stops yet)
│   ├── Stops list (active route)
│   │   ├── Stop card (address, status, color tag, package count)
│   │   ├── Drag handle (reorder)
│   │   ├── Swipe left → Delete
│   │   └── Swipe right → Mark as Delivered / Failed
│   ├── Top bar
│   │   ├── ETA badge (estimated route end time)
│   │   └── Route name / date
│   ├── FAB (+) → Add Stop bottom sheet
│   └── "Optimize" button → triggers optimization
│
├── Add Stop (bottom sheet / modal)
│   ├── Address search field (keyboard input with autocomplete)
│   ├── Voice input button
│   ├── Camera / OCR button
│   ├── Long press on map to add stop
│   └── Stop detail fields (optional):
│       ├── Color tag (visual grouping)
│       ├── Stop type (Delivery / Pickup)
│       ├── Package count
│       ├── Package ID
│       └── Time window (paid feature)
│
├── Route Optimization (transitional screen)
│   ├── Loading steps shown transparently:
│   │   ├── "Analyzing your stops..."
│   │   ├── "Accounting for traffic..."
│   │   └── "Building the best route..."
│   └── Result → returns to Route List with optimized order
│
├── Stop Detail (tap a stop card)
│   ├── Full address
│   ├── Package details (count, ID, notes)
│   ├── Stop type badge (Delivery / Pickup)
│   ├── Time window (if set)
│   ├── Status: Pending / Delivered / Failed / Picked up
│   ├── "Navigate" button → opens external GPS
│   ├── "Mark as Delivered" button
│   ├── "Mark as Failed" button (with failure reason options)
│   └── Move stop options (Make next / Make first / Make last)
│
├── Navigation (external GPS)
│   ├── Opens Waze, Google Maps, Apple Maps, HERE WeGo
│   └── App stays in background; user returns after each stop
│
├── Load Vehicle (pre-route screen — paid)
│   ├── Maps packages to physical vehicle compartments
│   └── Helps driver retrieve packages faster at each stop
│
├── Settings
│   ├── Default GPS app (Waze / Google Maps / internal)
│   ├── Home address (start/end point for routing)
│   ├── Break scheduling (duration + time window)
│   ├── Stop duration (default time per stop)
│   ├── Dark / light mode (auto or manual)
│   └── Account / subscription
│
├── Subscription / Paywall (soft paywall)
│   ├── Accessible from main menu (not forced at onboarding)
│   ├── Single monthly plan
│   ├── 7-day free trial (Spoke's model — we use 0 trial)
│   ├── Key benefit highlighted: "Optimize up to 500 stops"
│   └── Social proof: scrolling user testimonials
│
└── Share / Transfer Stops
    ├── QR Code
    ├── Copy Link
    └── Share via OS share sheet
```

---

## Screen-by-Screen Detail

### S01 — Onboarding / Login

**Purpose:** Get the user into the app as fast as possible. Minimal friction.

**Elements:**
- App logo + tagline
- "Sign up with email" field
- "Continue with Google" button
- "Already have an account? Log in" link

**UX pattern:** 1-step onboarding. No feature tour forced on new users — they discover features by doing. The minimal onboarding is a deliberate Spoke design choice.

**Roteirizador Pro adaptation:** Same philosophy. Email/password + optional Google sign-in. No tutorial screens.

---

### S02 — Home / Route List (empty state)

**Purpose:** First screen after login. Guides user to add their first stop.

**Elements:**
- Top bar: route name or date, ETA badge (greyed out / empty)
- Large empty state illustration + copy: "Add your first stop to get started"
- FAB (+) button prominent at bottom right
- Bottom navigation (if applicable)

**UX pattern:** Empty state is welcoming, not confusing. Single clear CTA.

**Roteirizador Pro adaptation:** Same. Show house/flag icon in top area if home point is set.

---

### S03 — Home / Route List (with stops)

**Purpose:** Main working screen. The user spends most time here.

**Elements:**
- Top bar:
  - Route end time ETA badge (e.g., `~14:30`) — updates as stops are completed
  - Route name
  - Overflow menu (⠇): skip optimization, route settings
- Stop list (scrollable):
  - Each stop card shows: sequence number, address (formatted, two lines), status badge, color tag, package count
  - Drag handle on right for manual reorder
  - Swipe actions
- "Optimize route" button (prominent) — bottom of screen or inline with list
- FAB (+) to add more stops

**UX pattern:** List-centric. Map is secondary (not always visible). Stops are the primary object.

**Roteirizador Pro adaptation:** Add subscriber counter badge next to ETA badge (our addition, not in Spoke).

---

### S04 — Add Stop (bottom sheet)

**Purpose:** Fast stop entry. Multiple input methods in one place.

**Elements:**
- Search field with autocomplete dropdown (max 5 results)
- Input method toggle row: Keyboard | Voice | Camera
- Optional fields (expandable): color, stop type, package count, package ID, time window
- "Add stop" confirm button
- Map long-press also triggers this sheet with pre-filled coordinates

**UX pattern:** Bottom sheet (not full screen). Dismissible. Stays anchored to bottom while list scrolls.

**Roteirizador Pro adaptation:** Same. Our OCR is triggered from the Camera option. No time windows in V1.

---

### S05 — Voice Input (within Add Stop)

**Purpose:** Hands-free address entry.

**Elements:**
- Animated mic indicator (listening state)
- Live transcription text appearing as user speaks
- "Stop listening" button
- Transcribed result shown for review before geocoding
- "Try again" option

**UX pattern:** Always shows transcription for review — never silently adds a stop.

---

### S06 — OCR / Camera Input (within Add Stop)

**Purpose:** Scan delivery label to extract address.

**Elements:**
- Camera viewfinder full screen
- Framing overlay (guide rectangle for label)
- Capture button
- Extracted text shown after capture
- CEP / address field pre-filled for review
- "Edit" option before confirming

**UX pattern:** Capture → show result → user confirms. Never auto-adds without review.

---

### S07 — Route Optimization (loading screen)

**Purpose:** Build trust while algorithm runs. Not just a spinner.

**Elements:**
- Sequential status messages:
  1. "Analyzing your stops..."
  2. "Accounting for traffic..."
  3. "Building the best route..."
- Progress indicator (dots or progress bar)
- Estimated time (usually 2-5 seconds for ≤25 stops)

**UX pattern:** Transparency during wait builds trust. Users see the app is "thinking", not frozen.

**Roteirizador Pro adaptation:** Add step: "Finding the best path home..." (sentido casa feature).

---

### S08 — Stop Detail

**Purpose:** See and manage a single stop in detail.

**Elements:**
- Full address (formatted)
- Map thumbnail showing stop location
- Status buttons: "Delivered" / "Failed" / "Picked up"
- "Navigate" primary CTA button (opens GPS app)
- Package details: count, ID, notes
- Stop type badge (Delivery / Pickup)
- Move options: "Make next" / "Make first" / "Make last"
- Edit address option
- Delete stop option

**UX pattern:** Action-forward. Primary action (Navigate) is always the biggest button.

---

### S09 — Navigation Handoff

**Purpose:** Seamless transition to external GPS.

**Elements:**
- If multiple GPS apps installed: bottom sheet "Navigate with..." (Waze / Google Maps)
- If one GPS app installed: opens directly
- If none: browser fallback

**UX pattern:** No internal map view in the handoff — user goes to their preferred GPS.

**Roteirizador Pro adaptation:** Same flow. Waze and Google Maps are the two options (no Apple Maps — Android only).

---

### S10 — Subscription / Paywall

**Purpose:** Convert free users without hard blocking core functionality.

**Spoke model:** Soft paywall — user can try core features, paywall appears when limits are hit (>10 stops) or from menu.

**Roteirizador Pro model:** Different — "Iniciar Navegação" is the gate. User can add stops and optimize freely, but navigation is locked.

**Elements:**
- Clear value prop headline: "Entregue mais, termine mais cedo"
- Price: R$ 25,90/mês
- Payment method: Pix only
- "Pagar com Pix" primary CTA button
- After tap: Pix QR Code + copy-paste code + "Já paguei" button
- Social proof (optional): subscriber count or testimonial

**UX pattern:** The paywall appears exactly when the user wants to navigate — maximum motivation moment.

---

### S11 — Settings

**Purpose:** Configure the app to match user preferences.

**Sections:**
- **Navigation:** Default GPS app (Waze / Google Maps)
- **Home point:** Save home address (sentido casa feature)
- **Account:** Email, change password, logout
- **Subscription:** Status, manage, cancel
- **About:** Version, privacy policy link, contact/support

**UX pattern:** Standard settings screen. No visual complexity. Grouped sections.

---

### S12 — Share / Referral (our addition — not in Spoke)

**Purpose:** Let motoboys pass the app link to each other on the street.

**Elements:**
- Screen title: "Indique o app"
- WhatsApp button: opens WhatsApp with pre-filled message
- Copy link button: copies download URL + "Copiado!" feedback
- QR Code: `QrImageView` of the download URL — scannable directly

**UX pattern:** Three options at equal weight. No complicated referral flow.

---

## Screens Spoke Has That We Deliberately Exclude (V1)

| Spoke Screen | Reason Excluded |
|---|---|
| Load vehicle (package placement map) | Complexity not in client brief |
| Team dispatch / transfer stops to driver | Solo driver app only |
| Package ID management | Not in client brief |
| Proof of delivery (photos) | Not in client brief |
| Time windows per stop | Not in client brief |
| Break scheduling | Not in client brief |
| Android Auto / CarPlay | Out of scope |
| Internal navigation (Google Maps in-app) | We use deep link to external app |
| Stop color tagging | Not in client brief |

These can be added post-M2 as premium features if the client wishes.

---

## Key UX Principles Observed in Spoke (Carry Into Our App)

1. **List-first, not map-first.** The stop list is the primary view. The map is secondary.
2. **Transparency during wait.** Optimization shows progress steps, not a spinner.
3. **Review before confirm.** Voice and OCR always show result for user to review.
4. **Single primary action per screen.** Each screen has one dominant CTA button.
5. **Inline status updates.** Stop status changes happen in the list without navigation.
6. **Minimal onboarding.** No forced tutorial. Users learn by doing.
7. **Soft paywall at the moment of value.** Gate the action the user most wants, not the app entry.
