import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wizard_form_controller.g.dart';

enum WizardDateOption { today, tomorrow, custom }

class WizardFormState {
  final WizardDateOption dateOption;
  final DateTime? customDate;
  final bool reuseStops;
  final String? customName;

  const WizardFormState({
    this.dateOption = WizardDateOption.today,
    this.customDate,
    this.reuseStops = false,
    this.customName,
  });

  WizardFormState copyWith({
    WizardDateOption? dateOption,
    DateTime? customDate,
    bool? reuseStops,
    String? customName,
  }) {
    return WizardFormState(
      dateOption: dateOption ?? this.dateOption,
      customDate: customDate ?? this.customDate,
      reuseStops: reuseStops ?? this.reuseStops,
      customName: customName ?? this.customName,
    );
  }
}

@riverpod
class WizardFormController extends _$WizardFormController {
  @override
  WizardFormState build() {
    return const WizardFormState();
  }

  void updateDateOption(WizardDateOption option) {
    state = state.copyWith(
      dateOption: option,
      customDate: option != WizardDateOption.custom ? null : state.customDate,
    );
  }

  void updateCustomDate(DateTime date) {
    state = state.copyWith(
      customDate: date,
      dateOption: WizardDateOption.custom,
    );
  }

  void toggleReuseStops() {
    state = state.copyWith(reuseStops: !state.reuseStops);
  }

  void updateCustomName(String name) {
    state = state.copyWith(customName: name.isEmpty ? null : name);
  }
}
