# Session Log

> Copy this file when starting a new session log. Rename to `YYYY-MM-DD-NN-<topic>.md`.

## Metadata

- **Date**: 2026-05-27 (America/Sao_Paulo)
- **Sequence**: 02
- **Agent**: Antigravity
- **Human**: Eduardo
- **Topic**: Google Maps Migration & MCP Usage
- **Duration**: ~2h00m
- **Related ADRs**: ADR-0039
- **Related TODO items**: Slice 2 UI (Route Shell)

## Goal of the Session

Migrate the map provider from `flutter_map` to `google_maps_flutter` to ensure 100% Spoke parity, adjust UI layouts (BottomSheet safe area and floating controls), and document the importance of using MCP tools when stuck.

## What Was Done

- Audited the discrepancy between Spoke's map behavior and RotPro's `flutter_map` implementation.
- Created `ADR-0039` to formalize the adoption of the Google Maps SDK over OpenStreetMap.
- Removed `flutter_map` and `latlong2` dependencies and added `google_maps_flutter`.
- Modified `android/app/build.gradle.kts` and `AndroidManifest.xml` to load `MAPS_API_KEY` securely from `local.properties`.
- Rewrote `route_shell_page.dart` using the `GoogleMap` widget.
- Adjusted the `DraggableScrollableSheet` layout so that its `minChildSize` accounts for Android navigation bar padding, and anchored the map control buttons dynamically to stay above the sheet.
- Emphasized a general guideline: whenever the agent gets stuck, rely on MCP tools (like Chrome DevTools, Context7, and Web Search) to debug and find modern best practices.

## Decisions Made

1. Use `google_maps_flutter` (ADR-0039) — To guarantee 100% parity with Spoke and leverage its UI fluidity and points of interest logic.
2. Read API keys from `local.properties` via Gradle — Standard, safe mechanism that prevents committing keys to version control.
3. Fallback to MCP tools — Enforced a global memory rule that the agent should proactively consult MCP/context tools to unblock issues or learn best practices instead of guessing.

## Open Questions Left

- [ ] Will the iOS setup require a similar `local.properties` or `.env` injection for Google Maps?
- [ ] Implement the map layer toggle and recenter functionalities that are currently stubbed.

## Files Changed

**Created**:
- `docs/decisions/0039-google-maps-adoption.md`
- `apps/mobile/android/local.properties` (Modified by user/agent manually)

**Modified**:
- `pubspec.yaml`
- `apps/mobile/android/app/build.gradle.kts`
- `apps/mobile/android/app/src/main/AndroidManifest.xml`
- `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`
- `TODO.md`

## Hand-off Notes for Next Session

The app now uses Google Maps on Android and is installed on the user's M54 device. The UI should have the search bar correctly positioned above the Android navbar and the map control buttons correctly hovering above the sheet. 

**Next step**: Move forward with Slice 2 features (Add Stops using the 3 methods).

## Reference Material Used

- User guidance and manual Android M54 screen verifications.
