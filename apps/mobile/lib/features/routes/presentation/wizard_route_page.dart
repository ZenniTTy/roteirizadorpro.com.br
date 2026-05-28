import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_input.dart';
import '../application/wizard_form_controller.dart';
import '../domain/route.dart' as domain;
import '../state/routes_provider.dart';

const _kWeekdaysShort = <String>[
  '',
  'seg',
  'ter',
  'qua',
  'qui',
  'sex',
  'sáb',
  'dom',
];
const _kMonthsShort = <String>[
  '',
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];
const _kWeekdays = <String>[
  '',
  'segunda-feira',
  'terça-feira',
  'quarta-feira',
  'quinta-feira',
  'sexta-feira',
  'sábado',
  'domingo',
];

String _formatDateShort(DateTime d) {
  return '${_kWeekdaysShort[d.weekday]}. ${d.day} de ${_kMonthsShort[d.month]}.';
}

/// Wizard for creating a new route OR editing an existing route's metadata.
///
/// `routeId == null` → create mode (back-arrow, title "Criar rota", Zona C
/// visible with reuseStops checkbox, CTA "Confirmar").
/// `routeId != null` → edit mode (X close, title "Editar rota", name field
/// pre-populated, Zona C hidden, CTA "Salvar alterações").
///
/// Spoke parity per inventário §6.2 (create) + §10.3 (edit).
class WizardRoutePage extends ConsumerStatefulWidget {
  const WizardRoutePage({super.key, this.routeId});

  /// When non-null, opens in edit mode parameterised by the target route.
  /// Resolves the Route in initState by reading `routesProvider`.
  final String? routeId;

  bool get isEdit => routeId != null;

  @override
  ConsumerState<WizardRoutePage> createState() => _WizardRoutePageState();
}

class _WizardRoutePageState extends ConsumerState<WizardRoutePage> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Hydration runs after the first frame: Riverpod 3 best practice is to
    // avoid touching `state =` during build phases. addPostFrameCallback
    // schedules the mutation for after this build completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(wizardFormControllerProvider.notifier);
      final id = widget.routeId;
      if (id == null) {
        controller.reset();
        return;
      }
      final routes = ref.read(routesProvider);
      final route = routes.where((r) => r.id == id).firstOrNull;
      if (route == null) {
        // Route id from the URL doesn't match any route in state — likely
        // stale deep link. Fall back to reset + leave page on next pop.
        controller.reset();
        return;
      }
      controller.hydrateFromDate(date: route.date, name: route.name);
      // Spoke D4 must-fix #2 (2026-05-28): edit mode pre-populates the
      // field with the route's DISPLAY name (computed auto-name if
      // `route.name == null`). Before this fix, an auto-named route
      // would show the auto-name as a gray placeholder hint, leading the
      // user to think the field was empty. Now they see the actual
      // current name in dark editable text — Spoke parity §10.3.
      // Pre-populate with EXACTLY the same string the user saw on the
      // drawer row (Route.displayName() = name ?? weekday-pt-br). Earlier
      // version used `_computeAutoName` which always appended " Rota N",
      // causing a visible inconsistency between drawer ("sexta-feira") and
      // edit field ("sexta-feira Rota 1") — caught during Maestro smoke
      // test 2026-05-28. The save logic at `_confirm()` compares against
      // this same displayName to detect "user kept the original",
      // preserving the null-name semantics. `routes` list still read
      // above for the stale-deep-link guard.
      _nameController.text = route.displayName();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm(WizardFormState state, String autoName) {
    final customName = _nameController.text.trim();
    final selectedDate = _resolveDate(state);

    // Save logic (Maestro smoke test 2026-05-28 reconciliation):
    // - In CREATE the field is empty by default; the placeholder shows
    //   the predictive auto-name "weekday Rota N". If the user typed
    //   exactly that placeholder or left the field empty → save null
    //   so Route.displayName() takes over downstream.
    // - In EDIT the field is pre-populated with route.displayName() —
    //   the SAME string the user just saw on the drawer row. So the
    //   comparison must be against THAT string, not against the
    //   create-mode autoName ("weekday Rota N"), otherwise saving an
    //   unchanged auto-named route would freeze it as a custom name.
    if (widget.isEdit) {
      final route = ref
          .read(routesProvider)
          .where((r) => r.id == widget.routeId)
          .firstOrNull;
      final originalDisplayName = route?.displayName() ?? '';
      final isUsingOriginal =
          customName.isEmpty || customName == originalDisplayName;
      final nameForEdit = isUsingOriginal ? null : customName;
      ref.read(routesProvider.notifier).updateRouteMeta(
            widget.routeId!,
            name: nameForEdit,
            date: selectedDate,
          );
      _popOrHome();
      return;
    }

    final isUsingAutoName = customName.isEmpty || customName == autoName;
    final nameForCreate = isUsingAutoName ? null : customName;

    // Create mode: persist the new route in the in-memory provider and
    // navigate. `createRoute` returns the new id — Slice 2 just navigates
    // back to /home (shell), where the new route becomes selectable from
    // the drawer. Slice 3 will deep-link to `/home/routes/$newId/active`.
    final newId = ref.read(routesProvider.notifier).createRoute(
          name: nameForCreate,
          date: selectedDate,
        );

    if (state.reuseStops) {
      // Spoke §11.3: when reuseStops is checked, after create navigate to
      // the reuse-stops picker scoped to the new route. Slice 2 lands on
      // the same generic /home/routes/reuse-stops page (no per-route param
      // yet); the wiring of which route is being filled is owned by the
      // active-route provider in Slice 3.
      _popOrHome();
      // Schedule push to reuse-stops after the wizard pops so the back
      // stack is `home → reuse-stops` (not `home → create → reuse-stops`).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.push('/home/routes/reuse-stops');
      });
      return;
    }

    // Keep `newId` discoverable for future slice-3 active-route wiring —
    // not used directly yet, but logging it in debug avoids the unused
    // warning while making the create→navigate intention explicit.
    assert(newId.isNotEmpty);
    _popOrHome();
  }

  void _popOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  DateTime _resolveDate(WizardFormState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (state.dateOption) {
      case WizardDateOption.today:
        return today;
      case WizardDateOption.tomorrow:
        return today.add(const Duration(days: 1));
      case WizardDateOption.custom:
        return state.customDate ?? today;
    }
  }

  Future<void> _pickDate() async {
    final state = ref.read(wizardFormControllerProvider);
    final now = DateTime.now();
    final initialDate =
        state.customDate ?? DateTime(now.year, now.month, now.day);

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

    // Active date used for the auto-generated placeholder.
    var activeDate = today;
    if (state.dateOption == WizardDateOption.tomorrow) {
      activeDate = tomorrow;
    }
    if (state.dateOption == WizardDateOption.custom &&
        state.customDate != null) {
      activeDate = state.customDate!;
    }

    final routes = ref.watch(routesProvider);
    final autoName = _computeAutoName(routes, activeDate);

    final isEdit = widget.isEdit;
    final title = isEdit ? 'Editar rota' : 'Criar rota';
    final ctaLabel = isEdit ? 'Salvar alterações' : 'Confirmar';
    final leadingSemantics = isEdit ? 'Fechar' : 'Voltar';

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
                  // Spoke v3.65.1 D4 dispatch 2026-05-28: AMBOS create e
                  // edit usam X close (inventário §6.2 original dizia
                  // "back-arrow" pro create — fato incorreto, corrigido
                  // neste PR). A11y label diferencia intenção via tooltip
                  // ("Fechar" vs "Voltar") — Spoke usa "Voltar" em ambos
                  // modos; RotPro mantém distinção semântica.
                  icon: const Icon(LucideIcons.x, color: AppColors.text),
                  tooltip: leadingSemantics,
                  onPressed: _popOrHome,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
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
                      // Spoke D4 should-fix #5 (2026-05-28): em edit mode
                      // o controller já está pré-populado com o display
                      // name; mostrar o autoName como placeholder hint
                      // criaria duplicação visual confusa (mesmo texto
                      // como hint cinza E como texto real). Suprimir.
                      placeholder: isEdit ? null : autoName,
                      onChanged: controller.updateCustomName,
                    ),
                    const SizedBox(height: 32),
                    // Spoke D4 should-fix #3 (2026-05-28): "Data de
                    // partida" sugere ponto de saída físico (conceito da
                    // §10.4 Detalhes da rota — não implementado em slice
                    // 2). "Data da rota" evita ambiguidade.
                    const Text(
                      'Data da rota',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateRadio(
                      title: 'Ainda hoje',
                      subtitle: _formatDateShort(today),
                      selected: state.dateOption == WizardDateOption.today,
                      icon: LucideIcons.calendarClock,
                      onTap: () =>
                          controller.updateDateOption(WizardDateOption.today),
                    ),
                    _DateRadio(
                      title: 'Para amanhã',
                      subtitle: _formatDateShort(tomorrow),
                      selected: state.dateOption == WizardDateOption.tomorrow,
                      icon: LucideIcons.calendarDays,
                      onTap: () => controller
                          .updateDateOption(WizardDateOption.tomorrow),
                    ),
                    _DateRadio(
                      title: 'Escolher no calendário',
                      subtitle: state.customDate != null
                          ? _formatDateShort(state.customDate!)
                          : null,
                      selected: state.dateOption == WizardDateOption.custom,
                      icon: LucideIcons.calendarSearch,
                      onTap: _pickDate,
                      trailing: const Icon(
                        LucideIcons.chevronRight,
                        size: 24,
                        color: AppColors.textMuted,
                      ),
                    ),
                    // Zona C — atalhos (reutilizar paradas) só faz sentido
                    // no CREATE. Edit mode esconde (Spoke §10.3 explicita
                    // "Sem 'Zona C' no edit").
                    if (!isEdit) ...[
                      const SizedBox(height: 32),
                      const Row(
                        children: [
                          Text(
                            'Atalhos',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(width: 8),
                          Tooltip(
                            message:
                                'Carrega os endereços da sua última rota salva, ideal para entregadores com rotas fixas.',
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              LucideIcons.info,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ReuseStopsTile(
                        selected: state.reuseStops,
                        onToggle: controller.toggleReuseStops,
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: RpButton(
                label: ctaLabel,
                neon: true,
                onPressed: () => _confirm(state, autoName),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates the placeholder for the name field: `[weekday] Rota [N]`
  /// where N is `routesOnSameDate.length + 1`. When editing, we exclude
  /// the current route from the count so the placeholder stays stable.
  String _computeAutoName(
    List<domain.Route> routes,
    DateTime activeDate,
  ) {
    final editingId = widget.routeId;
    final sameDay = routes.where((r) {
      if (r.id == editingId) return false;
      return r.date.year == activeDate.year &&
          r.date.month == activeDate.month &&
          r.date.day == activeDate.day;
    }).length;
    return '${_kWeekdays[activeDate.weekday]} Rota ${sameDay + 1}';
  }
}

class _ReuseStopsTile extends StatelessWidget {
  const _ReuseStopsTile({
    required this.selected,
    required this.onToggle,
  });

  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonLight.withValues(alpha: 0.5)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.neonDark : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              LucideIcons.history,
              size: 24,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Aproveitar últimas paradas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ),
            Transform.scale(
              scale: 1.25,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.neon,
                checkColor: AppColors.neonInk,
                side: BorderSide(
                  color: selected
                      ? AppColors.neonDark
                      : AppColors.textMuted.withValues(alpha: 0.5),
                  width: 1.5,
                ),
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
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DateRadio({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonLight.withValues(alpha: 0.5)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.neonDark : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadii.input),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            trailing ??
                Transform.scale(
                  scale: 1.25,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    activeColor: AppColors.neon,
                    checkColor: AppColors.neonInk,
                    side: BorderSide(
                      color: selected
                          ? AppColors.neonDark
                          : AppColors.textMuted.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
