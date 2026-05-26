# Spec — M2 Slice 2: Telas Core

> **Date:** 2026-05-13
> **Author:** Claude Code (with Eduardo)
> **Status:** Awaiting user review before invoking `writing-plans`
> **Branch:** `feat/m2-slice-2-telas-core` (off `develop` at `4189da3`)
> **Source of truth:** `docs/08-ROADMAP.md` "Slice 2 — Telas Core". This spec elaborates that section; if the two disagree, the ROADMAP wins and the contradiction is a bug to fix in the same PR.

---

## Context

M2 slice 1 shipped 2026-05-13 as `v1.0.0` — the APK is live, signed, and reachable on `roteirizadorpro.com.br`. The mobile app today has two real screens (Login + Register, 1:1 with `prototipo/screens-a.jsx`) and a home placeholder.

Slice 2 closes the gap between "auth works" and "the product is navigable": the 15 remaining prototype screens are implemented, every screen connects to real local state via Riverpod, captures (manual / voice / OCR / map-tap) produce real `Stop` entries, the optimize button calls a backend stub that echoes input order, and "Iniciar navegação" hands off to Google Maps (default) or Waze via deep link.

State stays in-memory plus `shared_preferences` for session restore — proper `routes` table persistence is slice 3's concern. The paywall section in Settings is stubbed (slice 4 owns it). The "home address" toggle is stubbed (slice 5 owns it). The optimize endpoint returns input order with zeroed metrics (slice 3 wires the real GraphHopper + nearest-neighbor + 2-opt solver).

This is the largest slice of M2 by LOC and by surface area. The goal is to ship the product **feel** end-to-end, then add real optimization, then add monetization.

## Decisions locked in this brainstorming session

| # | Question | Decision | Rationale |
|---|---|---|---|
| Q1 | Stop persistence in slice 2 | **In-memory (Riverpod) + `shared_preferences` for session restore.** Backend `routes` table waits for slice 3. | Avoids premature schema design for the `routes`/`route_stops` entities (their shape is owned by slice 3's solver). User keeps stops across kill/relaunch. Zero migration Prisma in slice 2 keeps the diff focused. |
| Q2 | Default external navigation provider | **Google Maps default + toggle in Settings to switch to Waze.** Waze opens parada-por-parada with explicit UX message; Google Maps opens multi-stop in one shot. Browser fallback if neither is installed. | Google Maps supports `waypoints=...` natively, Waze only supports 1 destination per `waze://` intent. Product sells "rota otimizada", so the default must respect that contract. ADR-0017 captures the design. |
| Q3 | Pricing BRL 25.90/route | **Locked through M2.** Revisit formally only after slice 7 admin surfaces real cohort data and we cross 50 paying users. | Per-transaction economics (~BRL 12.64 partner share post-Efí fees) is healthy. Pricing changes mid-M2 would invalidate the cost model and the Workana commitment. Data-driven re-evaluation later beats a guess now. |

## Goals (acceptance for slice 2)

A real Galaxy A06 install of `v1.1.0+2` can, against production API:

1. Sign in with the slice 1 auth flow.
2. Open the home screen — empty state matches `prototipo/screens-a.jsx → ScreenHomeEmpty`.
3. Add 5 stops via mixed methods: 2 by typing (`ScreenAddStop`), 1 by voice (`ScreenVoice` → `speech_to_text`), 1 by photo of an AWB label (`ScreenOCR` → `google_mlkit_text_recognition`), 1 by tap on map (`ScreenAddStopsMap` → `flutter_map` + OSM tiles).
4. Open `ScreenStopDetail` and edit one (`ScreenEditStop`).
5. Reorder the list (`ScreenReorder`).
6. View the full map of all stops (`ScreenMapStops`) with numbered markers in current order.
7. Tap "Otimizar rota" (`ScreenOptimize`) → backend `POST /routes/optimize` returns `{ optimizedOrder, totalDistanceM: 0, totalDurationS: 0 }` (input order, zero metrics).
8. See `ScreenOptimizeRoute` with markers reordered (visually equal in slice 2 because the mock echoes input).
9. Tap "Iniciar navegação" → Google Maps opens with all stops as multi-stop. Back to app.
10. Check off each stop in `ScreenNavigate` → `ScreenRouteComplete` summary screen.
11. Visit `ScreenSettings`, toggle nav provider to Waze, see paywall/home-address stubs as "em breve".
12. Tap `ScreenShare` → native Android share sheet with the route's stop list as WhatsApp-friendly text.
13. Force-close the app, reopen → all 5 stops restored from `shared_preferences`.
14. Sign out → return to login.

Non-goals (explicit, to keep scope tight):
- Real geocoding (slice 3, ADR-0018 — Nominatim policy).
- Real route polylines following streets (slice 3, ADR-0019 — GraphHopper-driven).
- Paywall + Pix (slice 4).
- Home-bias optimization (slice 5).
- LGPD endpoints (slice 6).
- Admin panel (slice 7).
- In-app turn-by-turn navigation (post-M2; would require Mapbox Navigation SDK).

## Architecture

### Mobile feature layout

```
apps/mobile/lib/features/
├── stops/                              # core of slice 2
│   ├── domain/
│   │   └── stop.dart                   # Pure Dart model: id, lat, lng, label?, source, createdAt
│   ├── data/
│   │   ├── dto/
│   │   │   └── stop_dto.dart           # Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema
│   │   └── repositories/
│   │       ├── stops_repository.dart                 # Interface
│   │       └── shared_prefs_stops_repository.dart    # impl (slice 2)
│   ├── state/
│   │   ├── stops_controller.dart       # @riverpod class StopsController extends _$StopsController
│   │   ├── stops_controller.g.dart
│   │   ├── optimize_controller.dart    # @riverpod class OptimizeController (calls POST /routes/optimize)
│   │   └── optimize_controller.g.dart
│   └── presentation/
│       ├── home_empty_page.dart        # ScreenHomeEmpty       (2a)
│       ├── home_list_page.dart         # ScreenHomeList        (2a)
│       ├── add_stop_page.dart          # ScreenAddStop         (2b)
│       ├── voice_capture_page.dart     # ScreenVoice           (2b)
│       ├── ocr_capture_page.dart       # ScreenOCR             (2b)
│       ├── add_stops_map_page.dart     # ScreenAddStopsMap     (2b)
│       ├── stop_detail_page.dart       # ScreenStopDetail      (2c)
│       ├── edit_stop_page.dart         # ScreenEditStop        (2c)
│       ├── reorder_page.dart           # ScreenReorder         (2c)
│       ├── map_stops_page.dart         # ScreenMapStops        (2c)
│       ├── optimize_page.dart          # ScreenOptimize        (2d)
│       ├── optimize_route_page.dart    # ScreenOptimizeRoute   (2d)
│       ├── navigate_page.dart          # ScreenNavigate        (2d)
│       ├── route_complete_page.dart    # ScreenRouteComplete   (2d)
│       └── shared/
│           ├── stop_list_item.dart
│           ├── stop_form.dart
│           └── map_attribution.dart    # RichAttributionWidget OSM per ADR-0016
├── settings/
│   └── presentation/
│       └── settings_page.dart          # ScreenSettings        (2e) — paywall + home address stubs
└── share/
    └── presentation/
        └── share_sheet.dart            # ScreenShare           (2e) via share_plus

apps/mobile/lib/core/services/
├── external_nav.dart                   # Google Maps + Waze deep link (ADR-0017)
├── permissions.dart                    # permission_handler wrapper (location/mic/camera)
└── id.dart                             # const uuid = Uuid(); String newId() => uuid.v4();
```

### Backend evolution

```
apps/backend/src/routes/
├── schemas.ts        # StopSchema (already exists, kept), OptimizeRequest unchanged,
│                     # OptimizeResponseSchema EVOLVED: { optimizedOrder: int[], totalDistanceM: number, totalDurationS: number }
└── routes.ts         # POST /routes/optimize: 501 → 200 mock returning input order, zeros
```

Slice 2 keeps the optimize logic **inline in `routes.ts`** (it's literally `return { optimizedOrder: stops.map((_, i) => i), totalDistanceM: 0, totalDurationS: 0 };`). The handler split into `handlers.ts` happens in slice 3 when the solver moves in.

### Architecture principles

1. **Repository interface + impl trocável.** `StopsRepository` is an abstract class with `Future<List<Stop>> load()` / `Future<void> save(List<Stop>)`. The slice 2 impl uses `shared_preferences`. The slice 3 impl will be `HttpStopsRepository` calling `GET/POST /routes` — the controller doesn't change.
2. **DTO ↔ domain separated.** `StopDto` mirrors TypeBox 1:1 (`lat`, `lng`, `label?`) with the `// Mirror of: …` header per ADR-0013. `Stop` is the richer Dart model (`id` UUID, `source` enum, `createdAt`) — fields that exist only on-device. `Stop.toDto()` discards local-only fields; `Stop.fromDto(dto)` injects a fresh UUID + `source: manual` if data comes from the wire (slice 3+).
3. **Schema source-of-truth (ADR-0013).** TypeBox in `apps/backend/src/routes/schemas.ts` evolves first, Dart DTO mirror follows in the same commit. The `OptimizeResponseSchema` change in 2a precedes any mobile consumer.
4. **Riverpod 3 codegen everywhere.** Every controller is `@riverpod class X extends _$X` (NotifierProvider equivalent). No legacy `StateNotifierProvider` syntax. Providers run through `build_runner` to generate `.g.dart` companions.
5. **DI via Riverpod overrides.** `stopsRepositoryProvider`, `externalNavProvider`, `permissionsProvider` all accept overrides for widget tests.
6. **No premature abstraction.** If a widget is used once, it stays inline. Only `stop_list_item`, `stop_form`, and `map_attribution` are extracted because they're genuinely reused across multiple screens.

## Data flow

### Stop model (domain)

```dart
enum StopSource { manual, voice, ocr, mapTap }

class Stop {
  final String id;            // UUID v4 — local-only in slice 2; persisted across kill in shared_preferences
  final double lat;
  final double lng;
  final String? label;
  final StopSource source;    // UX metadata (badge color); never sent on the wire in slice 2
  final DateTime createdAt;
  // toDto(), fromDto(), toJson(), fromJson(), copyWith() — manual until OpenAPI codegen post-M1 (ADR-0013)
}
```

### TypeBox schema evolution (slice 2 starts here)

```typescript
// apps/backend/src/routes/schemas.ts

export const StopSchema = Type.Object({
  lat: Type.Number({ minimum: -90, maximum: 90 }),
  lng: Type.Number({ minimum: -180, maximum: 180 }),
  label: Type.Optional(Type.String()),
});

export const OptimizeRequestSchema = Type.Object({
  stops: Type.Array(StopSchema, { minItems: 2, maxItems: 50 }),
  home: Type.Optional(StopSchema),
});

// CHANGED: 501 placeholder shape was { status: 'not_implemented', message: string }
// New 200 shape consumed by slice 2's mock and slice 3's real solver
export const OptimizeResponseSchema = Type.Object({
  optimizedOrder: Type.Array(Type.Integer({ minimum: 0 })),
  totalDistanceM: Type.Number(),
  totalDurationS: Type.Number(),
});
```

The Dart mirror at `apps/mobile/lib/features/stops/data/dto/stop_dto.dart` lands in the same commit, header: `// Mirror of: apps/backend/src/routes/schemas.ts -> StopSchema`.

### Optimize flow

1. User taps "Otimizar rota" on `ScreenOptimize`.
2. `OptimizeController.run()` reads `stopsControllerProvider.requireValue` → maps each `Stop` to a wire `StopDto` (discards `id`/`source`/`createdAt`).
3. POST `/routes/optimize` via the existing Dio + `AuthInterceptor` setup (token attached automatically; 401 triggers refresh).
4. Backend returns `{ optimizedOrder, totalDistanceM, totalDurationS }`.
5. `StopsController.applyOptimizedOrder(order)` permutes the in-memory list using `order` as indices into the current list. Persisted to `shared_preferences` post-permutation.
6. UI navigates to `ScreenOptimizeRoute` showing the permuted list + map.
7. "Iniciar navegação" reads the user's chosen nav provider from `shared_preferences` and hands off via `external_nav.openIn{GoogleMaps|Waze}(stops)`.

Because the wire response shape is the **final** shape (`optimizedOrder` + metrics), slice 3 replaces just the backend logic — frontend, DTO mirror, controller, and UI remain unchanged.

### Map configuration (`flutter_map` 8.x, slice 2b + 2c)

Every screen that renders the map (`ScreenAddStopsMap`, `ScreenMapStops`, `ScreenOptimizeRoute`) wires `FlutterMap` with the modern 8.x options. `MapOptions.center` was **removed** in 8.x in favor of `initialCenter`; using the old name will not compile. The recommended baseline:

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: const LatLng(-23.5505, -46.6333),       // São Paulo capital centroid
    initialZoom: 13,
    minZoom: 10,                                            // SP-capital region only
    maxZoom: 19,
    interactionOptions: const InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // disable rotation; matches prototype
    ),
    cameraConstraint: CameraConstraint.contain(
      bounds: LatLngBounds(
        const LatLng(-23.78, -46.83),                       // SW corner — matches the GraphHopper SP bbox
        const LatLng(-23.36, -46.40),                       // NE corner
      ),
    ),
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
      retinaMode: RetinaMode.isHighDensity(context),        // sharper on Galaxy A06 (xxhdpi)
      maxNativeZoom: 19,
    ),
    osmAttribution(),                                       // shared widget from map_attribution.dart
    MarkerLayer(/* numbered markers per stop */),
    if (showPolyline) PolylineLayer(/* straight lines in slice 2; GraphHopper polyline in slice 3 */),
  ],
)
```

Three modern-config callouts:

- **`cameraConstraint`** locks pan inside the GraphHopper SP bbox, so the user can't drag the map to Berlin and then complain we have no tiles there.
- **`retinaMode: RetinaMode.isHighDensity(context)`** asks OSM for `@2x` tiles when the device pixel ratio justifies it — Galaxy A06 is xxhdpi, so the user sees sharp tiles instead of blurry ones.
- **Rotation is disabled** because the prototype's map screens never rotate, and `flutter_map`'s rotation gesture would force us to rotate the marker icons too.

### Persistence (slice 2)

`SharedPrefsStopsRepository` writes a single key, JSON-encoded:

```json
{
  "_v": 1,
  "stops": [
    {"id":"uuid","lat":-23.55,"lng":-46.63,"label":"Av. Paulista","source":"mapTap","createdAt":"2026-05-13T..."}
  ]
}
```

The `_v: 1` prefix is forward-compat: slice 3's HTTP repo will migrate it (drain to backend on first hydrate, then remove the key). Writes are debounced 300 ms to avoid disk thrash during reorder drag.

The repository implementation MUST use the **`SharedPreferencesAsync`** API introduced in `shared_preferences` 2.3+, not the legacy `SharedPreferences.getInstance()`. `SharedPreferencesAsync` is the new modern API: fully async-first, isolate-safe, and avoids the main-thread block of the legacy synchronous getters. Reference: pub.dev `shared_preferences` README under "Migrating to SharedPreferencesAsync."

### Permission flow (slice 2b)

Three new runtime permissions land in this slice. The pattern is:

1. **Manifest declaration in `src/main/AndroidManifest.xml`** (Context7-validated: "it is generally sufficient to declare the required permissions in the main version" — this directly mirrors the slice 1 lesson captured in memory `flutter-android-release-internet-permission.md`).
2. **Runtime request via `permission_handler`** when the user first taps the feature.
3. **Rationale via `shouldShowRequestRationale`** (Android-only API): if returns true, show a friendly dialog explaining why we need the permission before re-requesting; if it permanently denies, link to app settings.

```xml
<!-- apps/mobile/android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />              <!-- exists since slice 1 hotfix -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />  <!-- geolocator -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />          <!-- speech_to_text -->
<uses-permission android:name="android.permission.CAMERA" />                <!-- google_mlkit_text_recognition (via image_picker) -->

<queries>                                                                    <!-- Android 11+ package visibility -->
  <package android:name="com.google.android.apps.maps" />
  <package android:name="com.waze" />
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

### Modern Android opt-ins (slice 2a — applied before any new UI lands)

The mobile app's `targetSdk` is dynamic (`flutter.targetSdkVersion`), so it advances every time we bump the Flutter SDK pin. As of 2026 the Flutter team's `flutter.targetSdkVersion` ≥ 35 (Android 15), which means slice 2 must opt into the two behaviors Google now enforces:

1. **Edge-to-edge layout is mandatory on Android 15+.** Apps with `targetSdk ≥ 35` no longer get an opaque system-bar inset for free; we must render under the bars and respect inset padding via `SafeArea` everywhere. Slice 2a enables it once at app boot and audits every prototype screen for `SafeArea` usage:

   ```dart
   // apps/mobile/lib/main.dart
   import 'package:flutter/services.dart';

   void main() {
     WidgetsFlutterBinding.ensureInitialized();
     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
     // Optional but recommended: transparent system bars so our gradients show through.
     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
       statusBarColor: Colors.transparent,
       systemNavigationBarColor: Colors.transparent,
     ));
     runApp(const ProviderScope(child: RoteirizadorProApp()));
   }
   ```

   The audit deliverable in sub 2a is: every `Scaffold` body in the new screens lives inside a `SafeArea`. Existing slice-1 screens (`LoginPage`, `RegisterPage`, `HomePlaceholderPage`) get the same check in the same sub-slice — surgical change, single commit `feat(mobile): adopt android 15 edge-to-edge with safearea audit`.

2. **Predictive Back opt-in on Android 14+.** Adding one attribute on `<application>` in `src/main/AndroidManifest.xml` lets the OS animate a back-gesture preview of the destination. Flutter 3.27+ supports this; slice 1 did not opt in. Slice 2a flips it on:

   ```xml
   <application
       android:label="Roteirizador Pro"
       android:icon="@mipmap/ic_launcher"
       android:enableOnBackInvokedCallback="true">  <!-- new in slice 2 -->
   ```

   No code change required besides the manifest line.

Both items are sub-2a deliverables (foundation work). They land before any new screen so we don't have to retrofit `SafeArea` across 15 widgets after the fact.

### External navigation (slice 2d → ADR-0017)

```dart
// core/services/external_nav.dart

enum NavProvider { googleMaps, waze }

class ExternalNav {
  /// Google Maps multi-stop: one URI opens the entire optimized route.
  Future<bool> openInGoogleMaps(List<Stop> stops) async {
    // https://www.google.com/maps/dir/?api=1&origin=...&destination=...&waypoints=...
    final origin = '${stops.first.lat},${stops.first.lng}';
    final destination = '${stops.last.lat},${stops.last.lng}';
    final waypoints = stops.sublist(1, stops.length - 1)
        .map((s) => '${s.lat},${s.lng}')
        .join('|');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin&destination=$destination'
      '${waypoints.isEmpty ? '' : '&waypoints=$waypoints'}'
      '&travelmode=driving',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Waze: one stop per intent. Opens the first, app pings user to return after.
  Future<bool> openInWaze(Stop stop) async {
    final uri = Uri.parse('waze://?ll=${stop.lat},${stop.lng}&navigate=yes');
    return launchUrl(uri);
  }
}
```

When the user has Waze selected and the route has > 1 stop, `ScreenOptimizeRoute` shows a one-time toast: *"Waze não suporta múltiplas paradas; vamos abrir uma de cada vez"* and then opens stop 1; `ScreenNavigate` lets them tap "Próxima parada" to fire Waze again per stop.

## Sub-slice plan

The 5 sub-slices share one branch (`feat/m2-slice-2-telas-core`) and one PR. The subdivision is for sane commit boundaries. All five must be green before opening the PR.

| Sub | Days | Scope | Verification |
|---|---|---|---|
| **2a Foundation** | 2 | TypeBox evolves (`OptimizeResponseSchema`). `Stop` domain, `StopDto` mirror, `StopsRepository` + `SharedPrefsStopsRepository` (using `SharedPreferencesAsync`), `StopsController`. **Modern Android opt-ins applied to slice-1 + new screens:** edge-to-edge enabled in `main.dart` + `SafeArea` audit; `enableOnBackInvokedCallback="true"` in manifest. **`prototipo/tokens.js` WCAG-AA contrast audit captured as a markdown table.** `ScreenHomeEmpty` + `ScreenHomeList`. | `flutter analyze`, `flutter test` (widget tests for both screens + controller unit test + repository round-trip + `ExternalNav` URI builder fixtures), `bun run typecheck`. Manual: launch app on Galaxy A06, confirm status/nav bars render edge-to-edge with no clipped content. |
| **2b Captura** | 4 | `AndroidManifest.xml` updates (3 perms + `<queries>`). `permission_handler` wrapper. `ScreenAddStop` (manual), `ScreenVoice` (`speech_to_text`), `ScreenOCR` (`image_picker` + `google_mlkit_text_recognition`), `ScreenAddStopsMap` (`flutter_map` + OSM tiles per ADR-0016). | `aapt2 dump permissions` lists `INTERNET`, `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, `CAMERA`. Manual on Galaxy A06: each capture method produces a real Stop. |
| **2c Manipulação** | 3 | `ScreenStopDetail`, `ScreenEditStop`, `ScreenReorder` (`ReorderableListView`), `ScreenMapStops`. | Manual: 5 stops → edit one → reorder → map shows all 5 markers numbered. |
| **2d Otimização + Nav** | 3 | Backend `POST /routes/optimize` returns mock. **ADR-0017 filed.** `external_nav.dart`. `ScreenOptimize`, `ScreenOptimizeRoute`, `ScreenNavigate`, `ScreenRouteComplete`. | Backend smoke via `curl -i` against the dev server (`tsx watch src/index.ts`) — three captures pasted into the PR body: 200 with `optimizedOrder` for a valid auth+body, 401 without bearer, 400 (TypeBox validation) for missing fields. **No backend unit-test framework in the repo today; see "Test strategy" below.** Manual: 5 stops → optimize → Google Maps opens multi-stop → returns → marks complete. |
| **2e Periféricos** | 2 | `ScreenSettings` (nav-provider toggle wired; paywall + home-address stubbed). `ScreenShare` (`share_plus`). | Manual: toggle nav provider in Settings → next optimize handoff respects it. Share opens Android sheet with route text. |

**Post-2e (≈ 1 day):**

- `pubspec.yaml` → `1.1.0+2`.
- `bash apps/mobile/scripts/build-release-apk.sh`.
- `aapt2 dump permissions` final check.
- `apksigner verify` — cert SHA-256 matches keystore (`D9:C9:61:D6:A3:2A:0C:45:B6:11:E0:E1:2D:86:FA:7E:52:1C:D3:3C:88:83:3C:7C:5D:5A:B9:91:9F:E9:14:31`).
- Real-device E2E: complete the 14-step golden path from "Goals" above; screenshot each screen for the PR body.
- `prototype-fidelity-checker` subagent against every shipped screen.
- Republish `roteirizador-pro-v1.1.0.apk` in `apps/landing/public/` + refactor `apps/landing/src/app/page.tsx` CTAs to read from a single `APK_LATEST_VERSION` constant.
- PR `feat/m2-slice-2-telas-core` → `develop` with the full test plan and screenshots.
- After merge: promotion PR `develop` → `main`, tag `v1.1.0`, production smoke (`curl -sI https://roteirizadorpro.com.br/roteirizador-pro-v1.1.0.apk`).
- Session log (`/session-end`) updating `docs/sessions/0001-INDEX.md`, `TODO.md`, `docs/10-CHANGELOG.md` in one commit.

**Estimate:** 14 working days (2 + 4 + 3 + 3 + 2) + 1 day release-and-PR ≈ **3 calendar weeks**, matches the ROADMAP's "2 weeks estimated" target with a margin for OS-permission UX iteration on real Android devices.

## Libraries

All slice 2 libraries below were validated via Context7 on 2026-05-13. The locked ones are already cited in ADR-0015 and ADR-0016; the new ones (introduced during this brainstorming) are validated in this spec.

| Purpose | Package | Version target | Cost | Context7 ID (or rationale) |
|---|---|---|---|---|
| Map widget | `flutter_map` | ^8.0.0 | 0 | `/fleaflet/flutter_map` (ADR-0015 + ADR-0016) |
| Map coords | `latlong2` | ^0.9.0 | 0 | transitive via flutter_map (ADR-0016) |
| User location | `geolocator` | ^14.0.0 | 0 | latest 2025 (ADR-0015) |
| Voice → text | `speech_to_text` | ^7.0.0 | 0 (on-device) | `/csdcorp/speech_to_text` (ADR-0015) |
| OCR | `google_mlkit_text_recognition` | ^0.x latest | 0 (on-device) | `/websites/pub_dev_google_mlkit_text_recognition` (ADR-0015) |
| Native share | `share_plus` | ^11.0.0 | 0 | well-established (ADR-0015) |
| **Camera/gallery image source for OCR** | `image_picker` | latest stable | 0 | Flutter-team-maintained (in `flutter/packages` monorepo) — stdlib exception per CLAUDE.md |
| **Runtime permissions** | `permission_handler` | latest stable | 0 | `/websites/pub_dev_permission_handler` — 227 snippets, score 86.4. Context7 validates `shouldShowRequestRationale` pattern + "declare in main AndroidManifest" guidance (matches our slice 1 lesson). |
| **Local persistence** | `shared_preferences` | latest stable | 0 | Flutter-team-maintained (in `flutter/packages`) — stdlib exception per CLAUDE.md |
| **Deep-link launcher** | `url_launcher` | latest stable | 0 | Flutter-team-maintained (in `flutter/packages`) — stdlib exception per CLAUDE.md |
| **UUID v4 for local IDs** | `uuid` | latest stable | 0 | `/websites/pub_dev_packages_uuid` — 647 snippets, score 80.4, RFC 4122 + RFC 9562 |

Exact version pins (caret semver) for the five new libs above are resolved during sub 2a by `flutter pub add <pkg>` against pub.dev; the resolver updates `pubspec.yaml` + `pubspec.lock` (both committed). The ADR-0015 table is amended in the same commit to record the resolved versions, so the lock stays authoritative.

## ADRs filed during this slice

- **ADR-0017** — External navigation hand-off (Google Maps default, Waze toggle, multi-stop semantics, fallback behavior, `<queries>` rationale). Filed in sub 2d.

No ADR for `permission_handler`/`shared_preferences`/`url_launcher`/`uuid`/`image_picker` — these are utility additions covered by ADR-0015's "M2 library choices" umbrella; we add a one-line note to ADR-0015's table when the PR is opened, listing the actual versions resolved.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| **Permission UX confusion on Android 13/14.** Granular media permissions changed the model for some reads. | Sub 2b uses `shouldShowRequestRationale` to drive a friendly rationale dialog; if permanently denied, link via `openAppSettings()`. No silent failures. |
| **OSM tile rate-limit triggered during dev.** Heavy reload of `ScreenAddStopsMap` could exceed fair-use. | `flutter_map`'s default `NetworkTileProvider` respects HTTP cache headers (per ADR-0016); we set `minZoom: 10, maxZoom: 19` to São Paulo capital range; no FMTC pre-download. |
| **Mock optimize endpoint contract drifts before slice 3.** A slice 2 shape that slice 3 has to break is wasted work. | The `OptimizeResponseSchema` is designed against slice 3's real-solver output (`optimizedOrder` indices, `totalDistanceM`, `totalDurationS`). Slice 3 replaces only the body of the handler. |
| **`shared_preferences` schema drift on app upgrade.** A user with slice 2 data running slice 3 must not crash on hydrate. | `_v: 1` prefix in the persisted JSON. Slice 3's `HttpStopsRepository` reads `_v`, drains in-memory state to backend on first hydrate, then removes the key. |
| **Waze user with a 20-stop route is annoyed.** | One-time toast explaining the limitation; "Próxima parada" CTA in `ScreenNavigate` is one tap. Settings allows switch to Google Maps anytime. |
| **Permission missing from release APK (slice 1 echo).** | `aapt2 dump permissions` is mandatory before any `adb install` in sub 2b and again at slice close (M2-SLICE-CHECKLIST §Verification). |
| **`SharedPreferencesAsync` migration.** Mixing the legacy `SharedPreferences.getInstance()` and the new `SharedPreferencesAsync` in the same install breaks reads. | The repository uses only `SharedPreferencesAsync` from day one. No fallback path to the legacy API. Documented in §Persistence. |

## Accessibility (Karpathy 3 minimum — not optional)

The product's primary user is a delivery rider, often interacting while wearing a helmet, driving, or holding a phone in one hand. Accessibility isn't a polish step we defer — it's load-bearing UX. Slice 2 enforces three baseline rules. If a screen ships without them, the slice isn't done.

1. **Semantics labels on every primary CTA.** Buttons that drive the core flow (`Adicionar parada`, `Otimizar rota`, `Iniciar navegação`, `Próxima parada`, `Marcar concluída`, FAB on `ScreenHomeList`) wrap their visual content in `Semantics(label: 'Iniciar navegação', button: true, ...)` so TalkBack reads a sentence, not a glyph name. Icon-only buttons (back arrows, swipe-to-delete trash) get `Semantics.tooltip` too.

2. **Tap targets ≥ 48×48 dp.** Material 3 default `IconButton` is 48 dp; we keep it. Custom widgets (`stop_list_item.dart`'s reorder handle, `stop_form.dart`'s clear-input X) wrap in `SizedBox(width: 48, height: 48, child: ...)` even if the visible icon is smaller. The `prototype-fidelity-checker` agent already flags this when checking against `prototipo/tokens.js` — slice 2 doesn't downgrade what slice 1 set.

3. **Color-contrast WCAG AA against `prototipo/tokens.js`.** The prototype's palette was approved by the client; we audit each token pair we use (foreground × background) against the WCAG AA 4.5:1 ratio for normal text and 3:1 for large text / non-text UI. The audit is a one-off check in sub 2a using a tool like [contrast-grid](https://contrast-grid.eightshapes.com) or `flutter_a11y` — captured as a single markdown table in the PR body, not a recurring CI gate (overkill for M2). If a token pair fails AA, the spec amendment is to **tweak the token, not the screen** — the prototype-fidelity-checker agent enforces that change everywhere.

Not in scope for slice 2 (deferred): full screen-reader navigation order audit, dynamic-type scaling beyond Flutter defaults, voice-control labels for the captures flow. These are post-M2 unless a real user reports friction.

## Test strategy

Slice 2 inherits the testing posture of slice 1: there is **no backend unit-test framework** in the repo today (`apps/backend/package.json` has `tsx`, `typescript`, and `prisma`, but no `vitest`/`jest`/`tap`/`node:test` runner). Slice 1 backend was smoke-tested via 12 curl paths against the dev server.

We don't introduce a backend test framework in slice 2 for two reasons: (1) the `POST /routes/optimize` mock is a single `return { optimizedOrder: stops.map((_, i) => i), totalDistanceM: 0, totalDurationS: 0 };` — formal tests on something slice 3 will replace are low-leverage; (2) installing `vitest` mid-slice is scope creep that pulls a tooling-ADR conversation we don't want today.

**Slice 2 testing matrix:**

| Layer | Tool | What it covers in slice 2 |
|---|---|---|
| Backend type safety | `tsc --noEmit` (`bun run typecheck`) | Every TypeBox schema change typechecks; Static<typeof X> resolves; no `any` snuck in. |
| Backend behavior | `curl -i` against `tsx watch src/index.ts` | Three captures in the PR body: 200 (valid request returns `optimizedOrder` echoing input order + zeroed metrics), 401 (no bearer), 400 (TypeBox-rejected body). |
| Mobile static analysis | `flutter analyze` | Zero warnings/errors. |
| Mobile unit | `flutter test` | `StopsController.applyOptimizedOrder` round-trip permutation. `SharedPrefsStopsRepository` save/load round-trip with `_v: 1` envelope. `ExternalNav` URI builder fixtures (Google Maps multi-stop, Waze single-stop). |
| Mobile widget | `flutter test` | One widget test per new screen, asserting it renders the prototype-correct elements without throwing. |
| Mobile E2E | Manual on Galaxy A06 (real device, production API) | The 14-step golden path from §Goals. Screenshot per screen for the PR body. |
| UI fidelity | `prototype-fidelity-checker` subagent | Every shipped screen vs `prototipo/screens-*.jsx`. |
| ADR coverage | `adr-guardian` subagent | ADR-0017 present + format compliant; no stack drift without ADR. |
| APK integrity | `aapt2 dump permissions` + `apksigner verify --verbose --print-certs` | All 4 permissions present in release APK; cert SHA-256 matches keystore. |

**Tech debt explicit (added to `TODO.md` in the PR):**

- *Post-slice-3:* evaluate `bun test` (zero-install via Bun's built-in runner) for the real solver in `apps/backend/src/routes/solver.ts`. Formal tests on a deterministic solver have long-term value — slice 3 is the right time.
- *Post-M2:* consider Flutter's `integration_test` package for a headless E2E suite to complement the manual real-device run.

## Verification gates (per M2-SLICE-CHECKLIST.md)

Pre-flight: ✅ (this spec).
Branch: ✅ `feat/m2-slice-2-telas-core` off `develop`.
Context7 re-validation: ✅ (libraries above).

To declare slice 2 done:

- [ ] `flutter analyze` clean.
- [ ] `flutter test` passes (widget tests for each new screen + unit test for `StopsController.applyOptimizedOrder` + `SharedPrefsStopsRepository` round-trip).
- [ ] `bun run typecheck` clean in `apps/backend/`.
- [ ] Backend smoke for `POST /routes/optimize` — three `curl -i` captures (200 / 401 / 400) pasted into the PR body. (No unit-test framework lives in `apps/backend/` today; see "Test strategy" below.)
- [ ] `aapt2 dump permissions roteirizador-pro-v1.1.0.apk` lists `INTERNET`, `ACCESS_FINE_LOCATION`, `RECORD_AUDIO`, `CAMERA`.
- [ ] `apksigner verify --verbose --print-certs` confirms v2 scheme + matching cert SHA-256.
- [ ] Real-device E2E on Galaxy A06: the 14-step golden path completes. Screenshot every screen.
- [ ] `prototype-fidelity-checker` subagent reports clean against every screen vs `prototipo/`.
- [ ] `adr-guardian` subagent reports clean against the PR diff (ADR-0017 present).
- [ ] PR body filled per M2-SLICE-CHECKLIST template (summary, test plan, related ADRs, screenshots).
- [ ] Vercel preview SUCCESS before requesting review.
- [ ] Post-merge: promotion PR `develop` → `main`, tag `v1.1.0`, production `curl -sI` confirms the new APK 200.
- [ ] `/session-end` commits the session log + index + TODO + CHANGELOG in one shot.

## References

- `CLAUDE.md` — operating manual (Karpathy 4 principles, stack lock, schema source-of-truth).
- `docs/08-ROADMAP.md` "Slice 2 — Telas Core" — the canonical scope this spec elaborates.
- `docs/M2-SLICE-CHECKLIST.md` — the per-slice execution gates this spec respects.
- `docs/M2-COST-MODEL.md` — the cost ceiling all library choices in this spec respect (0 BRL incremental).
- ADR-0013 — schema source-of-truth (TypeBox → Dart DTO mirror).
- ADR-0015 — M2 plan and library choices (the lock this spec extends).
- ADR-0016 — Map and tile policy (OSM, attribution, migration trigger).
- ADR-0017 — *To be filed during sub 2d.* External navigation hand-off.
- `prototipo/screens-a.jsx`, `screens-b.jsx`, `screens-d.jsx`, `screens-e.jsx` — canonical UI source for the 15 screens in scope.
- Memory entry `flutter-android-release-internet-permission.md` — the slice 1 lesson that drives the manifest pattern in sub 2b.
- Context7: `/websites/pub_dev_permission_handler` (queried 2026-05-13 for runtime permissions + Android setup).
- Context7: `/websites/pub_dev_packages_uuid` (queried 2026-05-13 for v4 generator + RFC 9562 compliance).
- Slice 1 ADRs and session logs (`docs/decisions/0014-*.md`, `docs/sessions/2026-05-13-09-*.md`, `…-10-*.md`).
