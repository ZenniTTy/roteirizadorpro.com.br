# ADR-0017: External Navigation Hand-off

- **Status:** Accepted
- **Date:** 2026-05-19 (amended same day — see "Amendment History" below)
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0010 (clone positioning), ADR-0035 (Spoke functional / prototype visual hierarchy), ADR-0015 (M2 plan + library choices), ADR-0016 (map and tile policy), ADR-0014 (Android release signing).

## Context

Slice 2's `ScreenNavigate` step needs to take an optimized route and start turn-by-turn navigation. In-app turn-by-turn would require Mapbox Navigation SDK or similar — paid, vendor-locked, and outside the M2 cost ceiling. The pragmatic path is **deep-link hand-off** to whichever external navigation app the user prefers.

The two realistic Brazilian options are Google Maps and Waze. Their deep-link contracts have very different shapes and limits — both confirmed against the official 2026 documentation:

- **Google Maps**: `https://www.google.com/maps/dir/?api=1` supports `origin` (optional — when omitted, the Google Maps app uses the device's current location), `destination`, `waypoints` (pipe-separated), and `travelmode`. **Hard cap: 9 waypoints maximum; 2,048 character URL limit.** Per Google for Developers, mobile *browsers* cap waypoints at 3, but the Google Maps Android app consumes the URL with the 9-waypoint cap. The implementation omits `origin` so the rider can fire "Iniciar navegação" from anywhere (depot, mid-route, parking) — that gives a per-URI cap of **10 stops** (9 waypoints + 1 destination, origin = current location). Setting `origin` explicitly would push the cap to 11 but force the rider to physically be at the first stop, which contradicts the real flow.
  Source: <https://developers.google.com/maps/documentation/urls/get-started>
- **Waze**: `waze://?ll=<lat>,<lng>&navigate=yes` takes a single destination per intent. There is no published multi-stop variant.
  Source: <https://developers.google.com/waze/deeplinks>

The prototype at `prototipo/screens-b.jsx:361` (client-approved 2026-05-07, ADR-0010 makes the prototype canonical) shows Waze as the default GPS provider in Settings. The original draft of this ADR proposed Google Maps as the default for "multi-stop promise"; that drift from the prototype was caught during validation and corrected — see Amendment History.

## Options Considered

### A — Waze default, Google Maps toggle (this ADR)

Default to Waze because (1) the client-approved prototype shows it, (2) Brazilian delivery riders skew toward Waze for traffic awareness, and (3) the Google Maps URL cap of 10 stops per URI would force a fallback flow anyway for the upper end of the spec's "up to 20 stops" target — Waze (parada-por-parada) is the only provider that handles arbitrary stop counts cleanly.

- **Pros:** matches the canonical prototype (ADR-0010); matches rider preference; handles 1–20 stops with one consistent mental model (one stop, then the next); the Google Maps cap stops mattering at the slice 3 spec ceiling.
- **Cons:** users with very small routes (≤10 stops) miss out on Google Maps' single-URL multi-stop UX unless they flip the toggle.

### B — Google Maps default, Waze toggle (rejected; was the original draft)

- **Pros:** single tap launches the whole route in one URL (when ≤10 stops).
- **Cons:** **contradicts the client-approved prototype's choice of default** (the prototype shows Waze as the default — under the legacy "prototype is canonical UI" stance this was a hard block; under ADR-0035 the prototype's visual identity wins but functional/preference defaults trace to Spoke + cliente, so this con is weaker today than at the time of the original decision); also forces a fallback path for any route >10 stops which is exactly the upper end of the spec. **Rejected** (decision stands — Waze default remains the choice via ADR-0017's amendment history, validated by cliente).

### C — Ask every time

Bottom sheet "Abrir em: [Google Maps] [Waze]" on every Iniciar navegação tap.

- **Pros:** zero assumption.
- **Cons:** extra tap on every trip. Friction adds up over a workday. **Rejected.**

## Decision

1. **Default external navigation provider is Waze.** One-stop-at-a-time via the `waze://?ll=…&navigate=yes` deep link, advanced via a "Próxima parada" CTA on `ScreenNavigate`.

2. **Settings exposes a `Aplicativo de navegação` toggle.** Two options: Waze (default) and Google Maps. The choice is persisted in `SharedPreferencesAsync` under the key `settings.nav_provider`. Default is `NavProvider.waze` when the key is absent.

3. **Google Maps path uses chunked multi-stop URIs.** When the user picks Google Maps and the route has more than 10 stops, the app sends the first 10 (9 waypoints + 1 destination, origin = device current location) and offers a SnackBar+CTA "Próxima parte da rota" that fires another Google Maps URI with the next batch. The chunk size of 10 comes from omitting the `origin` parameter (see Context above); the rationale is rider-flow flexibility, not Google Maps' raw API limit. Sub-10-stop routes use a single URI.

4. **Fallback when neither app is installed.** The Google Maps URI is a real `https://` URL, so the browser is the natural fallback (Android resolves the intent to a browser if no native handler is registered). Confirmed by the `<queries>` block from Task 17 (commit `bd10c9a`), which includes a generic `https` VIEW intent. The Waze URI uses the `waze://` scheme which has no browser fallback; if Waze is not installed and the user picked Waze, the app shows a SnackBar with a Play Store deep-link to Waze rather than failing silently.

5. **Android 11+ visibility.** The `<queries>` block in `apps/mobile/android/app/src/main/AndroidManifest.xml` lists `com.google.android.apps.maps`, `com.waze`, and the generic `https` VIEW intent so `canLaunchUrl()` returns true when the app is installed. Android 11 (API 30) introduced package-visibility restrictions: without the `<queries>` declaration, `canLaunchUrl()` returns `false` even when the target app is installed, because the calling app simply cannot see it. This block is the canonical fix per the Android docs.

6. **In-app turn-by-turn is explicitly out of M2 scope.** Would require a Mapbox Navigation SDK or similar paid product; revisit if the post-M2 economics justify the dependency.

## Consequences

- **Positive:** zero per-request cost; matches the canonical prototype; matches the dominant Brazilian rider preference; handles the full 1–20 stop range with one mental model; the migration to in-app turn-by-turn (if ever) is a clean replacement of `ExternalNav.openInWaze` / `ExternalNav.openInGoogleMaps`.
- **Negative:** users with small routes who would benefit from Google Maps' single-URI flow must flip the Settings toggle once.
- **Neutral:** if a third provider ever becomes the default in Brazil (e.g. an OpenStreetMap-based navigator gains traction), this ADR is the single place that changes.

## Implementation notes

`apps/mobile/lib/core/services/external_nav.dart` ships in Task 28 with:

```dart
enum NavProvider { waze, googleMaps }

/// Google Maps Maps-URLs caps waypoints at 9 per
/// https://developers.google.com/maps/documentation/urls/get-started.
/// With `origin` omitted (device current location), that allows 10 stops
/// per URI (9 waypoints + 1 destination). Routes longer than 10 are
/// chunked into multiple Google Maps URIs; the caller advances to the
/// next chunk when the rider taps "Próxima parte da rota".
const int kGoogleMapsMaxStopsPerUri = 10;

abstract class ExternalNav {
  /// Pure URI builders — no platform side effects, easy to unit-test.
  static Uri googleMapsUri(List<Stop> stops);
  static Uri wazeUri(Stop stop);

  /// Launchers (platform side effects). Implementations live behind a Riverpod
  /// provider so tests can substitute a Fake via override (same pattern as
  /// `permissions.dart` and `FakeAppPermissions`).
  Future<bool> openInGoogleMaps(List<Stop> stops);
  Future<bool> openInWaze(Stop stop);
}
```

The provider preference is read from `SharedPreferencesAsync` (`settings.nav_provider`); `ScreenSettings` writes it via a SegmentedButton in Task 33. The provider is exposed via a `@riverpod` codegen provider over a `_RealExternalNav` implementation, matching the architectural pattern established by `core/services/permissions.dart`.

## Amendment History

- **2026-05-19 (initial draft, superseded same day):** proposed Google Maps as the default. Rationale was "preserves the multi-stop promise out of the box."
- **2026-05-19 (intermediate, superseded same day):** corrected to Waze default after validation pass discovered the prototype/ADR drift and the Google Maps URL cap. Cap was recorded as 11 stops (1 origin + 9 waypoints + 1 destination) on the assumption that the rider was always physically at the first stop.
- **2026-05-19 (this version):** during Task 28 implementation, the cap was re-derived from the actual rider flow ("Iniciar navegação" fires from depot or anywhere mid-route, not always at the first stop). The implementation omits `origin` so the Google Maps app uses the device's current location; that drops the per-URI cap from 11 to 10 (9 waypoints + 1 destination). Decision §3 now reflects 10 instead of 11. The Decision section above is the version that ships.

## References

- ADR-0010 — Clone positioning + prototype as canonical UI source.
- ADR-0015 — M2 plan and library choices.
- ADR-0016 — Map and tile policy.
- Spec: `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` §External navigation.
- AndroidManifest `<queries>` block introduced in slice 2 sub 2b Task 17 (commit `bd10c9a`).
- Google for Developers — Maps URLs: <https://developers.google.com/maps/documentation/urls/get-started>.
- Google for Developers — Waze Deep Links: <https://developers.google.com/waze/deeplinks>.
- Android 11 package-visibility docs: <https://developer.android.com/training/package-visibility>.
- Prototype: `prototipo/screens-b.jsx:361` (default GPS provider in Settings).
