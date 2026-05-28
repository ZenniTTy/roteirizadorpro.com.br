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

  /// Reseta o form aos defaults (estado limpo).
  /// Chamado no initState do wizard pra evitar carregar state stale entre
  /// aberturas consecutivas (controller é keep-alive padrão Riverpod).
  void reset() {
    state = const WizardFormState();
  }

  /// Hidrata o form com o estado de uma rota existente (modo edit).
  /// `date` é mapeada pra `WizardDateOption.today`/`tomorrow` se coincidir;
  /// caso contrário, vai pra `custom` com `customDate = date`.
  /// `name` vai pro `customName` (null se rota usa o nome auto-gerado).
  void hydrateFromDate({required DateTime date, String? name}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sameDay = DateTime(date.year, date.month, date.day);

    final WizardDateOption option;
    DateTime? customDate;
    if (sameDay == today) {
      option = WizardDateOption.today;
    } else if (sameDay == tomorrow) {
      option = WizardDateOption.tomorrow;
    } else {
      option = WizardDateOption.custom;
      customDate = sameDay;
    }

    state = WizardFormState(
      dateOption: option,
      customDate: customDate,
      reuseStops: false,
      customName: name,
    );
  }
}
