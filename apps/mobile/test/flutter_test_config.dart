// Global test configuration for `apps/mobile/test/**`.
// Wires the Alchemist golden-test runner (ADR-0029) — CI mode by default
// (Ahem font, platform-agnostic) so baselines are reproducible across macOS
// dev machines and Linux CI. Platform-specific golden runs are opt-in per
// test via `goldenTest(..., constraints: ...)`.

import 'dart:async';

import 'package:alchemist/alchemist.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      // Skip platform-tagged goldens by default; only run the CI-tagged ones.
      // Devs can override locally to regenerate platform baselines if needed.
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
