# ADR-0002: Use Flutter for Mobile (over React Native)

- **Status:** Accepted
- **Date:** 2026-05-05
- **Deciders:** Eduardo

## Context

The accepted Workana proposal lists "experience with Flutter or React Native" — both are on the table. The product is Android-only initially, distributed as APK direct download (no Play Store), and must clone Circuit Route Planner's UX fluidity. Critical features include OCR (label scanning), voice input, drag-to-reorder lists, and external deep links to Waze and Google Maps.

## Options Considered

### Option A — Flutter

- Pros: Skia/Impeller GPU rendering — closer to native fluidity than RN's bridge model; mature OCR via `google_mlkit_text_recognition` (Google-maintained, offline); single command APK build (`flutter build apk --release`); smaller APK size (~15-25MB) vs RN's typical 25-40MB; null safety enforced at language level.
- Cons: Dart is a less common language than JavaScript/TypeScript; smaller pool of devs vs RN.

### Option B — React Native (Expo)

- Pros: Larger dev pool; closer to web stack; Expo simplifies builds.
- Cons: Bridge model still costlier for complex animations after Fabric/TurboModules; OCR options are community-maintained with breakage history; APK distribution outside Play Store requires EAS (paid past free tier) or Gradle config; larger binaries.

## Decision

Use **Flutter** with stable channel.

The deciding factors are (1) APK build simplicity for direct distribution — exactly our model, (2) mature offline OCR for the label-scanning feature which is critical, and (3) closer-to-native fluidity for cloning Circuit's UX feel. Dev pool concerns are mitigated by AI-assisted development.

## Consequences

- Positive: Easy APK distribution outside Play Store; mature OCR; closer-to-native UX feel; null safety on by default.
- Negative: Dart is a small additional learning curve; harder to find external maintainers if needed (mitigated by handing off to client with thorough docs).
- Neutral: We will use Riverpod 3 for state management (see ADR-0005).

## Implementation Notes

- Stable channel only.
- Build APK with `flutter build apk --release --split-per-abi` to reduce per-device download size.
- Signing keystore is created once and backed up by the client (see M2 deliverables in `docs/04-ROADMAP-M2.md`).

## References

- `docs/04-ROADMAP-M2.md`
