# ADR-0017: External Navigation Hand-off

- **Status:** Accepted
- **Date:** 2026-05-19
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0015 (M2 plan + library choices), ADR-0016 (map and tile policy), ADR-0014 (Android release signing).

## Context

Slice 2's `ScreenNavigate` step needs to take an optimized route and start turn-by-turn navigation. In-app turn-by-turn would require Mapbox Navigation SDK or similar — paid, vendor-locked, and outside the M2 cost ceiling. The pragmatic path is **deep-link hand-off** to whichever external navigation app the user prefers.

The two realistic Brazilian options are Google Maps and Waze. They have very different deep-link contracts:

- **Google Maps**: `https://www.google.com/maps/dir/?api=1` supports `origin`, `destination`, and `waypoints` (pipe-separated). One URL opens the entire multi-stop route.
- **Waze**: `waze://?ll=<lat>,<lng>&navigate=yes` takes a single destination per intent. There is no published multi-stop variant.

This ADR captures the decision and the consequences for the slice 2 UX.

## Options Considered

### A — Google Maps default, Waze toggle (this ADR)

Default the user to Google Maps because it preserves the product promise ("nós otimizamos sua rota inteira"). A toggle in Settings switches to Waze, but a one-time warning explains that Waze is opened one stop at a time.

- **Pros:** preserves the multi-stop promise out of the box; respects user choice in Settings; falls back to a browser if neither app is installed (`https://www.google.com/maps/dir/...` opens any browser).
- **Cons:** Brazilian delivery riders skew toward Waze for traffic awareness; this design forces a Settings change to use it.

### B — Waze default, Google Maps toggle

- **Pros:** matches the prevailing rider preference in Brazil.
- **Cons:** breaks the multi-stop promise on first use. Users who picked the product *because* of route optimization see a single-stop hand-off and feel cheated. **Rejected.**

### C — Ask every time

Bottom sheet "Abrir em: [Google Maps] [Waze]" on every Iniciar navegação tap.

- **Pros:** zero assumption.
- **Cons:** extra tap on every trip. Friction adds up over a workday. **Rejected.**

## Decision

1. **Default external navigation provider is Google Maps.** Multi-stop hand-off via the `dir/?api=1` URL with `origin`, `destination`, and `waypoints`.

2. **Settings exposes a `Aplicativo de navegação` toggle.** Two options: Google Maps (default) and Waze. The choice is persisted in `SharedPreferencesAsync` under the key `settings.nav_provider`.

3. **Waze is opened one stop at a time.** When the user selects Waze in Settings and the route has > 1 stop, `ScreenOptimizeRoute` shows a one-time toast: *"Waze não suporta múltiplas paradas; vamos abrir uma de cada vez."* `ScreenNavigate` then exposes a "Próxima parada" CTA that fires Waze for the next index.

4. **Fallback when neither app is installed.** The Google Maps URI is a real `https://` URL, so the browser is the natural fallback (Android resolves the intent to a browser if no native handler is registered). Confirmed by the `<queries>` block from Task 17 (commit `bd10c9a`), which includes a generic `https` VIEW intent.

5. **Android 11+ visibility.** The `<queries>` block in `apps/mobile/android/app/src/main/AndroidManifest.xml` lists `com.google.android.apps.maps`, `com.waze`, and the generic `https` VIEW intent so `canLaunchUrl()` returns true when the app is installed. Android 11 (API 30) introduced package-visibility restrictions: without the `<queries>` declaration, `canLaunchUrl()` returns `false` even when the target app is installed, because the calling app simply cannot see it. This block is the canonical fix per the Android docs.

6. **In-app turn-by-turn is explicitly out of M2 scope.** Would require a Mapbox Navigation SDK or similar paid product; revisit if the post-M2 economics justify the dependency.

## Consequences

- **Positive:** zero per-request cost; respects user preference; preserves the multi-stop promise by default; the migration to in-app turn-by-turn (if ever) is a clean replacement of `ExternalNav.openInGoogleMaps`.
- **Negative:** Waze users see a slightly worse UX than Google Maps users; mitigated by the explicit one-time message.
- **Neutral:** if a third provider ever becomes the default in Brazil (e.g. an OpenStreetMap-based navigator gains traction), this ADR is the single place that changes.

## Implementation notes

`apps/mobile/lib/core/services/external_nav.dart` ships in Task 28 with:

```dart
enum NavProvider { googleMaps, waze }

class ExternalNav {
  static Uri googleMapsUri(List<Stop> stops);
  static Uri wazeUri(Stop stop);

  Future<bool> openInGoogleMaps(List<Stop> stops);
  Future<bool> openInWaze(Stop stop);
}
```

The provider preference is read from `SharedPreferencesAsync` (`settings.nav_provider`); `ScreenSettings` writes it via a SegmentedButton in Task 33.

## References

- ADR-0015 — M2 plan and library choices.
- ADR-0016 — Map and tile policy.
- Spec: `docs/superpowers/specs/2026-05-13-m2-slice-2-telas-core-design.md` §External navigation.
- AndroidManifest `<queries>` block introduced in slice 2 sub 2b Task 17 (commit `bd10c9a`).
- Android 11 package-visibility docs: <https://developer.android.com/training/package-visibility>.
