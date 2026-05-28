# Session Log Template

## Metadata

- **Date**: 2026-05-28 (America/Sao_Paulo)
- **Sequence**: 03
- **Agent**: Google Antigravity
- **Human**: Eduardo
- **Topic**: UI Polish & Remember Me
- **Duration**: ~0h30m
- **Related ADRs**: none
- **Related TODO items**: 
  - [x] Validar UI via emulador / build local

## Goal of the Session

Fix the missing "Remember me" functionality logic, adjust the Map layout elements (BottomSheet bottom margin and floating icons), polish the Hamburger Menu UI (neon buttons/dividers), and ensure the final APK is rebuilt and installed locally so the user can see the correct changes.

## What Was Done

- Checked the login screen and recognized that the "Remember me" functionality was visually there but the state wasn't persisting when restarting the app due to `flutter_secure_storage` Android KeyStore behavior during reinstall.
- Applied `SharedPreferencesAsync` in `login_page.dart` to fix this persistency issue for the non-sensitive boolean and email credentials.
- Adjusted the `minHeightPx` and `buttonsBottom` clearances in `RouteShellPage` so the bottom sheet and floating icons don't overlap native Android system icons or each other.
- Altered the Drawer dividers opacity and applied the `AppColors.neon` gradient to the menu headers.
- Clarified the user on `RpButton(neon: true)` rendering the purple gradient by default, whilst the "Assinar" button is the one using the green neon gradient.
- Added strict rules to `.agent/knowledge/01-erros-cometidos.md` to ensure the Antigravity agent **always** rebuilds and installs the APK before concluding UI work.
- Ran Maestro (`validate_ui.yaml`) to automatically validate the login flow and visibility of the new components.
- Ran `flutter build apk --debug` and `adb install` to push the new APK version to the device.

## Decisions Made

1. Use `SharedPreferencesAsync` for simple interface states (like remember-me booleans and remembered emails). — Rationale: It survives app reinstallations much better on development workflows than `flutter_secure_storage`, which wipes with Android KeyStore resets.
2. Rebuild the APK mechanically via the agent. — Rationale: The user was validating the UI visually but seeing a stale cache because the `flutter run` / `hot restart` command was absent in the pipeline.

## Open Questions Left

- None.

## Files Changed

**Modified**:
- `apps/mobile/lib/features/routes/presentation/route_shell_page.dart`
- `apps/mobile/lib/features/routes/presentation/widgets/drawer_route_list.dart`
- `.agent/knowledge/01-erros-cometidos.md`

**Created**:
- `ROOT_PROMPT.md`

## Hand-off Notes for Next Session

The UI for the active route screen (Slice 2) is visually aligned and Maestro tests have passed. The next step from `TODO.md` is to "Implementar a próxima etapa da Slice 2 (adicionar parada, reordenar, navegar)".

## Reference Material Used

- `.agent/knowledge/01-erros-cometidos.md`
- `apps/mobile/scripts/validate_ui.yaml`
