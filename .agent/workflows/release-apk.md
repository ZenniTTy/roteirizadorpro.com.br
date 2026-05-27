---
description: Cut a signed release APK using the canonical slice-1 build script and verify Android permissions on the output. Reads but never edits signing material.
---

# /release-apk

Cut a new signed release APK for distribution at `roteirizadorpro.com.br`. Mirrors the slice-1 ritual (ADR-0014).

## Pre-flight

1. Confirm working tree is clean:
   ```bash
   git status
   ```
   If dirty, ask the operator whether to commit first or stash.

2. Confirm we are on a release-cut branch (e.g., `main` or a `release/v*` branch). Refuse to cut from a feature branch unless the operator explicitly overrides.

3. Confirm the version bump is intentional:
   - Read `apps/mobile/pubspec.yaml` `version:` line.
   - Compare with the previous APK at `apps/landing/public/*.apk` (filename usually carries the version).
   - If the version is unchanged, ask the operator whether to bump.

4. **Never edit `apps/mobile/android/key.properties` or any `.jks` / `.p12` file.** If signing material is missing, surface it and stop. The operator must restore from their secure store.

## Build

Run the canonical script:

```bash
bash apps/mobile/scripts/build-release-apk.sh
```

This script already wires:
- `--dart-define=API_BASE_URL=https://api.roteirizadorpro.com.br`
- `--dart-define=APP_ENV=production`
- Signing via `key.properties`

If the script fails, surface the error and stop. Do not try to "fix" signing or build config — those are infrastructure decisions that require an ADR.

## Verify permissions

Per slice-1 lesson:

```bash
aapt2 dump permissions <path-to-apk>
```

Expected permissions (no more, no less):
- `INTERNET`
- `ACCESS_NETWORK_STATE`
- `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` (if slice 5 sentido-casa has shipped)
- `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION` (if applicable)

If new permissions appear that aren't justified by a shipped slice, surface this to the operator BEFORE distributing.

## Report

Print:
- APK path: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk` (or wherever the script writes it).
- APK size in MB.
- `aapt2 dump permissions` output.
- SHA-256 of the APK (`shasum -a 256 <apk-path>`).
- Suggested next step: copy to `apps/landing/public/` with versioned filename, update download link in landing.

## Never

- Edit signing material (`*.jks`, `*.p12`, `key.properties`).
- Build with `flutter run --release` on the M54 instead of using the canonical script (it sidesteps signing).
- Skip the `aapt2 dump permissions` check.
- Commit the APK to `apps/mobile/build/` (gitignored). The version that gets distributed is the one committed under `apps/landing/public/*.apk`.
