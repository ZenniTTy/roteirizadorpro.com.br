import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_input.dart';
import '../application/wizard_form_controller.dart';
import '../state/routes_provider.dart';

const _kWeekdaysShort = <String>['', 'seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
const _kMonthsShort = <String>['', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
const _kWeekdays = <String>['', 'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];

String _formatDateShort(DateTime d) {
  return '${_kWeekdaysShort[d.weekday]}. ${d.day} de ${_kMonthsShort[d.month]}.';
}

class WizardRoutePage extends ConsumerStatefulWidget {
  const WizardRoutePage({super.key});

  @override
  ConsumerState<WizardRoutePage> createState() => _WizardRoutePageState();
}

class _WizardRoutePageState extends ConsumerState<WizardRoutePage> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _confirm(WizardFormState state, String autoName) {
    final customName = _nameController.text.trim();
    final name = customName.isEmpty ? autoName : customName;
    
    DateTime selectedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (state.dateOption) {
      case WizardDateOption.today:
        selectedDate = today;
        break;
      case WizardDateOption.tomorrow:
        selectedDate = today.add(const Duration(days: 1));
        break;
      case WizardDateOption.custom:
        selectedDate = state.customDate ?? today;
        break;
    }

    if (state.reuseStops) {
      _showSnack('Reutilizar paradas será habilitado na Área 2.5');
      return;
    }

    // In a real app, we'd call routesProvider.notifier.createRoute(name: name, date: selectedDate)
    // For Slice 2, since Routes is just a seed list provider, we'll pretend it created
    // and just set an active mock route (or navigate).
    // Actually, routesProvider is NOT a notifier in Slice 2. So we can't add to it directly.
    // The spec says "Ao submeter... O GoRouter limpa a tela".
    // For now, just navigate back.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _pickDate() async {
    final state = ref.read(wizardFormControllerProvider);
    final now = DateTime.now();
    final initialDate = state.customDate ?? DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate.subtract(const Duration(days: 365)),
      lastDate: initialDate.add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      ref.read(wizardFormControllerProvider.notifier).updateCustomDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardFormControllerProvider);
    final controller = ref.read(wizardFormControllerProvider.notifier);
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Auto-generate name based on selected date
    DateTime activeDate = today;
    if (state.dateOption == WizardDateOption.tomorrow) activeDate = tomorrow;
    if (state.dateOption == WizardDateOption.custom && state.customDate != null) activeDate = state.customDate!;
    
    // Basic counting logic for the name: (in real app, read from routesProvider where date == activeDate)
    final routes = ref.watch(routesProvider);
    final routesOnDate = routes.where((r) => r.date.year == activeDate.year && r.date.month == activeDate.month && r.date.day == activeDate.day).length;
    final String autoName = '${_kWeekdays[activeDate.weekday]} Rota ${routesOnDate + 1}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Criar rota',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 32),
                    RpInput(
                      label: 'Nome da rota (opcional)',
                      controller: _nameController,
                      placeholder: autoName,
                      onChanged: controller.updateCustomName,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Selecione a data',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateRadio(
                      title: 'Hoje',
                      subtitle: _formatDateShort(today),
                      selected: state.dateOption == WizardDateOption.today,
                      onTap: () => controller.updateDateOption(WizardDateOption.today),
                    ),
                    _DateRadio(
                      title: 'Amanhã',
                      subtitle: _formatDateShort(tomorrow),
                      selected: state.dateOption == WizardDateOption.tomorrow,
                      onTap: () => controller.updateDateOption(WizardDateOption.tomorrow),
                    ),
                    _DateRadio(
                      title: 'Escolher data',
                      subtitle: state.customDate != null ? _formatDateShort(state.customDate!) : null,
                      selected: state.dateOption == WizardDateOption.custom,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Opções de início rápido',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Reutilizar paradas anteriores',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.text,
                        ),
                      ),
                      trailing: Checkbox(
                        value: state.reuseStops,
                        onChanged: (val) => controller.toggleReuseStops(),
                        activeColor: AppColors.primary,
                      ),
                      onTap: () => controller.toggleReuseStops(),
                    ),
                    const SizedBox(height: 48), // Bottom padding
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: RpButton(
                label: 'Confirmar',
                onPressed: () => _confirm(state, autoName),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRadio extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DateRadio({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.text,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
