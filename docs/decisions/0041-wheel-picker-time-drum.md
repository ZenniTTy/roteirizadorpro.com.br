# ADR-0041: wheel_picker ^0.3.0 adopted for time picker drum widget

- **Status:** Superseded by [ADR-0042](./0042-time-picker-numpad-spoke-fidelity.md) on 2026-06-03
- **Date:** 2026-06-02
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0035 (Spoke white-label hierarchy), ADR-0036 (parity gates), ADR-0042 (supersedes this)

> **2026-06-03 amendment:** This ADR was based on an inferred Spoke baseline (the cited `/tmp/spoke-a5-iniciar-time.png` was a 0-byte truncated file at the time of writing, not actually inspected). A live re-inspection on 2026-06-03 (workflow `wrqvzoso8`, baselines at `/tmp/spoke-a5-inspection/step2..step9.png`) revealed Spoke uses a numeric keypad (`bsp_time_picker`), not a drum/wheel. See [ADR-0042](./0042-time-picker-numpad-spoke-fidelity.md) for the corrective decision and the inference-vs-measurement protocol amendment.

> Note: spec `docs/superpowers/specs/2026-06-02-area5-route-details.md` references this decision as "ADR-0040". ADR-0040 was already taken by `google_maps_webservice` / Places Autocomplete during Area 4 (filed earlier in Slice 2). This ADR is filed as 0041 to keep the numbering monotonic; the spec text is left as-is for archival fidelity but every commit/log from MS1 onward references 0041.

## Context

Slice 2 Area 5 (Detalhes da rota) requires a time picker for the "Início" and "Término" rows of the route configuration screen. Spoke (the canonical behavior source per ADR-0035) uses a **vertical drum scroll picker** for HH:MM selection — captured empirically during the 2026-06-01 inspection session (`/tmp/spoke-a5-iniciar-time.png`).

Material 3's stdlib time picker (`showTimePicker`) renders a circular dial. Adopting the dial would visibly deviate from Spoke's UX in a flow riders see on every route. Custom-rolling a drum widget would be ~300 LOC of `PageView`-based scroll-snapping logic plus haptics — non-trivial work for a foundational widget already solved by a well-maintained pub.dev package.

Context7 was queried 2026-06-01 (`/jaweii/flutter_wheel_picker`) and confirmed `^0.3.0` as the current published version.

## Decision

Adopt `wheel_picker ^0.3.0` from pub.dev as a runtime dependency of `apps/mobile`. The package will be wrapped in `lib/features/route_config/presentation/widgets/time_picker_sheet.dart` (MS4) to expose a `TimePickerSheet({initial, onChanged})` API that matches Spoke's drum behavior + adjacent `:00 / :30` minute chips.

Resolved version recorded in `apps/mobile/pubspec.lock`: **`0.3.0`** (sha256 `fd761fd895093791f808a8433a861179c7716cc02720cc984271fa79eced3a6a`).

## Consequences

- **Positive:** ~50 LOC wrapper instead of ~300 LOC custom widget; behavior matches Spoke drum + haptic feedback out-of-the-box; reduces MS4 implementation surface.
- **Positive (cost):** Package is pure Dart (no native plugin), adds no platform channels, no transitive deps to audit.
- **Negative (lock-in):** Future visual polish (typography, divider styling) is constrained to what `wheel_picker` exposes; if we need a deeper customisation later we re-evaluate.
- **Maintenance:** Package last updated 2024-04 (per pub.dev as of 2026-06-01); single maintainer (`jaweii`). Acceptable risk for an isolated widget — easy to fork/replace if abandoned.

## Alternatives considered

1. **Material 3 dial picker (`showTimePicker`)** — rejected. Deviates from Spoke UX; rider muscle memory expects drum scroll.
2. **Custom scroll wheel widget** — rejected. ~300 LOC of `PageView` + snap physics + haptics for behavior the package already ships; not Karpathy-simple.
3. **`flutter_picker` (alternative pub package)** — rejected. Larger API surface (multi-column, dialog presets) than we need; last updated 2023, lower-quality docs.

## References

- Spec: `docs/superpowers/specs/2026-06-02-area5-route-details.md` (Q3 + Libraries section)
- Spoke baseline: `/tmp/spoke-a5-iniciar-time.png` + sibling XML dump captured 2026-06-01
- Context7 query: `/jaweii/flutter_wheel_picker` (2026-06-01)
- pub.dev: <https://pub.dev/packages/wheel_picker>
