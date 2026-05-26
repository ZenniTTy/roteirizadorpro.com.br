// Baseline golden test for `HomeEmptyPage` (ADR-0029).
// Runs in Alchemist CI mode by default — Ahem font, platform-agnostic — so
// the same baseline reproduces on macOS dev and Linux CI without font drift.
//
// To regenerate after an intentional visual change:
//   cd apps/mobile && flutter test --update-goldens \
//     test/features/stops/presentation/home_empty_page_golden_test.dart

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roteirizador_pro/features/stops/presentation/home_empty_page.dart';

void main() {
  group('HomeEmptyPage golden', () {
    goldenTest(
      'renders the empty-state layout',
      fileName: 'home_empty_page',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'no stops',
            // 400x900 mirrors the project's `phoneSurface` widget-test convention
            // (test/_support/phone_surface.dart) — close to the prototype's 390-wide
            // design canvas. Bounded constraints are required because the page is a
            // Scaffold; Alchemist's default OverflowBox would otherwise pass infinite
            // height and the Scaffold layout would assert.
            constraints: const BoxConstraints.tightFor(width: 400, height: 900),
            child: const MaterialApp(home: HomeEmptyPage()),
          ),
        ],
      ),
    );
  });
}
