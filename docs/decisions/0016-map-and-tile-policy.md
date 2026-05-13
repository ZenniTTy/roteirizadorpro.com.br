# ADR-0016: Map Library, Tile Source, and Heavy-Usage Migration

- **Status:** Accepted
- **Date:** 2026-05-13
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0015 (M2 plan + library choices), ADR-0008 (GraphHopper routing engine), `M2-COST-MODEL.md`.

## Context

Slice 2 introduces map screens (`ScreenAddStopsMap`, `ScreenMapStops`, `ScreenOptimizeRoute`, `ScreenNavigate`). The mobile app needs:

1. A widget that renders an interactive map with markers, polylines, and tap input.
2. A tile source the widget can load.

The cost ceiling in `M2-COST-MODEL.md` forces the choice toward free / low-cost options. The architectural constraint from ADR-0008 (self-host the routing engine to avoid per-request fees) extends naturally to tiles: pay-per-1000-tile-loads pricing from Google or Mapbox would make even a 100-user beta unsustainable.

## Options Considered

### Map widget

#### A — `flutter_map` 8.x (this ADR)

- Apache 2.0, vendor-free, Context7 score 91/100, supports any static raster tile URL, mature attribution widgets, mature plugin ecosystem.
- Used in production by many Brazilian Flutter apps.

#### B — `google_maps_flutter`

- Best-in-class UX; deep integration with Android Auto / iOS CarPlay.
- Forces Google's tile/SDK pricing; vendor lock-in. **Rejected** (cost).

#### C — `mapbox_maps_flutter`

- High-quality vector tiles; generous free tier.
- Vendor lock-in; migrating off Mapbox later is non-trivial; the free tier (200k loads/month) is bigger than we need today but the *cost trajectory* is the wrong shape. **Deferred** as the future heavy-usage migration target.

### Tile source

#### α — Public OSM tile server (`tile.openstreetmap.org`, this ADR)

- Free; reliable; community-maintained.
- Subject to the OpenStreetMap Foundation's [Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/): non-commercial / fair-use; valid `User-Agent`/`HTTP Referer`; explicit attribution; do not "heavy-use" (rule of thumb: ≤ a few thousand tile loads per device per day, ≤ 1M aggregate per app).
- Risk: if our usage grows past fair-use, OSM is within their rights to block our `User-Agent`.

#### β — Self-hosted tile server (`openmaptiles` + `tileserver-gl-light` on the droplet)

- Zero per-request cost; full control; no policy risk.
- Adds ~3 GB disk for SP-only tile set; ~5 GB for Sudeste; small CPU footprint (Nginx serves the pre-rendered PNGs).
- Migration cost is real: setting up `tileserver-gl-light`, configuring Nginx routes, updating the `urlTemplate` in `flutter_map`. ~1 day of work.

#### γ — Mapbox / MapTiler hosted vector tiles

- High quality, generous free tier (Mapbox: 200k loads/month free; MapTiler: 100k loads/month free).
- Future option but introduces a paid SaaS dependency.

#### δ — Stadia Maps / Thunderforest

- Niche providers with reasonable pricing. Not evaluated in depth because OSM-direct + self-host covers the M2 lifecycle.

## Decision

1. **Map widget: `flutter_map` 8.x.** Added to `pubspec.yaml` in slice 2.

2. **Tile source: public OSM tiles** at `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, with strict adherence to the OSMF Tile Usage Policy:

   - **`userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro'`** on every `TileLayer`. The `flutter_map` library appends this to the User-Agent string so OSM can identify and contact us if our traffic looks abusive.
   - **Attribution always visible**: `RichAttributionWidget` (or `SimpleAttributionWidget`) showing "OpenStreetMap contributors" with the right link to `https://www.openstreetmap.org/copyright`. **No map screen ships without it.** Prototype-fidelity checks include this as a hard requirement.
   - **In-app tile caching** via `flutter_map`'s default `NetworkTileProvider` (which respects HTTP cache headers) and an explicit `tileBounds` limited to São Paulo capital initially. We do not aggressively prefetch — only what the user actually pans through.
   - **No bulk-downloading** of tiles. The package's "FMTC" plugin (Flutter Map Tile Caching) is **not** added because it can mass-download a region in one operation, which is exactly what the OSM policy prohibits.
   - **No use of OSM tiles in unattended/server-side rendering** (e.g. screenshot generation for the admin panel). If the slice 7 admin needs a map preview, render client-side or use a self-hosted Nominatim/OSM stack.

3. **Migration trigger for self-hosted tiles:** if any of the following holds for two consecutive weeks, file an ADR and migrate to Option β:

   - The app's daily active users × estimated tile loads per session crosses **≥ 100k requests per day** across all installs.
   - We see HTTP 403 / 429 responses from the OSM tile server in the wild.
   - The OSMF operations team contacts us about traffic patterns.

   **Migration plan (Option β):**

   1. On the existing droplet (resize to 2 GB first), install Nginx + `tileserver-gl-light` + the `openmaptiles` data extract for São Paulo capital (~3 GB).
   2. Set up a route `https://tiles.roteirizadorpro.com.br/{z}/{x}/{y}.png` behind Cloudflare's free CDN for edge caching.
   3. Update the `urlTemplate` in `flutter_map` to point at our domain.
   4. Ship as a patch release of the mobile app; older installs continue to use public OSM tiles until users update.

4. **Heavy-usage trigger budget:** add a daily-rollup of map-tile requests to the slice 7 admin metrics page so we know in time if we're approaching the limit.

## Consequences

- **Positive:** 0 BRL/month tile cost during beta; vendor-free; the migration path is documented and pre-budgeted (~1 day of work); the admin page will surface the metric that triggers the migration so we never hit a hard wall.
- **Negative:** subject to OSM's acceptable-use policy; a sudden traffic spike could result in a temporary block. Mitigation: aggressive monitoring of the daily-rollup metric; cache more aggressively when we approach the threshold.
- **Neutral:** future re-evaluation of paid tiles (Mapbox, MapTiler) is open — if self-hosted tiles add operational burden we don't want, paid is the next stop.

## Implementation Notes

### `pubspec.yaml` (slice 2)

```yaml
dependencies:
  flutter_map: ^8.0.0
  latlong2: ^0.9.0          # transitive but pin explicitly
```

### Reusable widget (slice 2)

`apps/mobile/lib/features/stops/presentation/shared/map_attribution.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Always-visible OSM attribution for every map screen.
/// Required by ADR-0016 and the OSMF Tile Usage Policy.
RichAttributionWidget osmAttribution() => RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          'OpenStreetMap contributors',
          onTap: () => launchUrl(
            Uri.parse('https://www.openstreetmap.org/copyright'),
          ),
        ),
      ],
    );
```

(Note: `url_launcher` may already be transitively present; if not, slice 2 adds it.)

### Tile layer template

```dart
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'br.com.roteirizadorpro.roteirizador_pro',
  maxZoom: 19,
  minZoom: 10,                                  // SP capital region only
),
```

### What this rule rejects

- A `TileLayer` without `userAgentPackageName`.
- A map screen without an attribution widget.
- Use of the FMTC (Flutter Map Tile Caching) plugin's region-download feature.
- Any commercial-style heavy-prefetching pattern.
- Using OSM tiles in the slice 7 admin server-rendered metrics dashboards.

## References

- OpenStreetMap Foundation — *Tile Usage Policy* — `https://operations.osmfoundation.org/policies/tiles/`.
- Context7: `/fleaflet/flutter_map` queried 2026-05-13 — `TileLayer`, `RichAttributionWidget`, `userAgentPackageName` examples.
- ADR-0015 (M2 plan).
- `M2-COST-MODEL.md` — the cost target this ADR satisfies.
