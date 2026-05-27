import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/application/wizard_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('WizardFormController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has today selected and reuseStops false', () {
      final state = container.read(wizardFormControllerProvider);
      
      expect(state.dateOption, WizardDateOption.today);
      expect(state.reuseStops, false);
      expect(state.customName, null);
      expect(state.customDate, null);
    });

    test('updateDateOption changes the date option', () {
      final controller = container.read(wizardFormControllerProvider.notifier);
      
      controller.updateDateOption(WizardDateOption.tomorrow);
      
      final state = container.read(wizardFormControllerProvider);
      expect(state.dateOption, WizardDateOption.tomorrow);
    });

    test('updateCustomDate sets custom date', () {
      final controller = container.read(wizardFormControllerProvider.notifier);
      final testDate = DateTime(2026, 5, 27);
      
      controller.updateCustomDate(testDate);
      
      final state = container.read(wizardFormControllerProvider);
      expect(state.customDate, testDate);
      expect(state.dateOption, WizardDateOption.custom);
    });

    test('toggleReuseStops flips the boolean', () {
      final controller = container.read(wizardFormControllerProvider.notifier);
      
      controller.toggleReuseStops();
      expect(container.read(wizardFormControllerProvider).reuseStops, true);
      
      controller.toggleReuseStops();
      expect(container.read(wizardFormControllerProvider).reuseStops, false);
    });
  });
}
