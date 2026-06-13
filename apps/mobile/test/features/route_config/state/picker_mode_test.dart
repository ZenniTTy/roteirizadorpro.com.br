// Tests for PickerMode enum — pins the flag contract for every mode entry.
//
// Spec: docs/superpowers/plans/2026-06-11-area6-edit-stop-plan.md T17 (H10)
//
// NOTE: The `changeAddress` entry does NOT exist in lib/ yet — the implementer
// must add it to `picker_mode.dart` before running this file. Once it is added,
// the `changeAddress` group is a regression guard (green from first run, which
// is the correct outcome for pin tests on declared data — no logic lives in an
// enum entry, only constant values). The existing mode flags are asserted first
// to confirm the shared baseline has not regressed.

import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/route_config/state/picker_mode.dart';

void main() {
  // ── Regression: existing mode flags stay unchanged ────────────────────────

  group('PickerMode.addStop — flags (regression)', () {
    test('hintText', () {
      expect(PickerMode.addStop.hintText, 'Digite o endereço da parada');
    });
    test('resultsSectionHeader', () {
      expect(
        PickerMode.addStop.resultsSectionHeader,
        'Adicionar nova parada',
      );
    });
    test('showMethodButtonsOnEmpty == true', () {
      expect(PickerMode.addStop.showMethodButtonsOnEmpty, isTrue);
    });
    test('showMicrocopyOnEmpty == true', () {
      expect(PickerMode.addStop.showMicrocopyOnEmpty, isTrue);
    });
    test('showExistingStopsSection == true', () {
      expect(PickerMode.addStop.showExistingStopsSection, isTrue);
    });
    test('showChooseOnMapFooter == true', () {
      expect(PickerMode.addStop.showChooseOnMapFooter, isTrue);
    });
  });

  group('PickerMode.startLocation — flags (regression)', () {
    test('hintText', () {
      expect(PickerMode.startLocation.hintText, 'Buscar endereço');
    });
    test('resultsSectionHeader', () {
      expect(
        PickerMode.startLocation.resultsSectionHeader,
        'Escolha o novo endereço',
      );
    });
    test('showMethodButtonsOnEmpty == false', () {
      expect(PickerMode.startLocation.showMethodButtonsOnEmpty, isFalse);
    });
    test('showMicrocopyOnEmpty == false', () {
      expect(PickerMode.startLocation.showMicrocopyOnEmpty, isFalse);
    });
    test('showExistingStopsSection == false', () {
      expect(PickerMode.startLocation.showExistingStopsSection, isFalse);
    });
    test('showChooseOnMapFooter == false', () {
      expect(PickerMode.startLocation.showChooseOnMapFooter, isFalse);
    });
  });

  group('PickerMode.endLocation — flags (regression)', () {
    test('hintText', () {
      expect(PickerMode.endLocation.hintText, 'Buscar endereço');
    });
    test('resultsSectionHeader', () {
      expect(
        PickerMode.endLocation.resultsSectionHeader,
        'Escolha o novo endereço',
      );
    });
    test('showMethodButtonsOnEmpty == false', () {
      expect(PickerMode.endLocation.showMethodButtonsOnEmpty, isFalse);
    });
    test('showMicrocopyOnEmpty == false', () {
      expect(PickerMode.endLocation.showMicrocopyOnEmpty, isFalse);
    });
    test('showExistingStopsSection == false', () {
      expect(PickerMode.endLocation.showExistingStopsSection, isFalse);
    });
    test('showChooseOnMapFooter == false', () {
      expect(PickerMode.endLocation.showChooseOnMapFooter, isFalse);
    });
  });

  // ── T17 / H10: PickerMode.changeAddress — exact flag contract ────────────
  //
  // These tests pin the flags the implementer MUST assign when adding the
  // `changeAddress` entry to picker_mode.dart. They fail with a compile error
  // until the entry exists (compile-error-as-red is acceptable for pin tests
  // on data declarations — the implementer adds the entry AND the logic).

  group('PickerMode.changeAddress — flags (T17/H10 pin)', () {
    test('hintText == "Buscar endereço"', () {
      expect(PickerMode.changeAddress.hintText, 'Buscar endereço');
    });
    test('resultsSectionHeader == "Escolha o novo endereço"', () {
      expect(
        PickerMode.changeAddress.resultsSectionHeader,
        'Escolha o novo endereço',
      );
    });
    test('showMethodButtonsOnEmpty == false', () {
      expect(PickerMode.changeAddress.showMethodButtonsOnEmpty, isFalse);
    });
    test('showMicrocopyOnEmpty == false', () {
      expect(PickerMode.changeAddress.showMicrocopyOnEmpty, isFalse);
    });
    test('showExistingStopsSection == false (Section A omitida)', () {
      expect(PickerMode.changeAddress.showExistingStopsSection, isFalse);
    });
    test('showChooseOnMapFooter == false (sem map footer)', () {
      expect(PickerMode.changeAddress.showChooseOnMapFooter, isFalse);
    });
  });
}
