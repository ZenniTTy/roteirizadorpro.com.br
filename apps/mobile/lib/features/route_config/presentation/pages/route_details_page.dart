import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';
import '../../state/route_config_controller.dart';
import '../widgets/route_config_row.dart';
import '../widgets/route_details_section.dart';
import '../widgets/time_picker_sheet.dart';

/// Full-screen "Detalhes da rota" — Spoke white-label layout.
///
/// Per Spoke (live inspection 2026-06-01): there is NO AppBar — the close X
/// floats top-left inside the scrollable content, the title is a body-level
/// h1, "Concluído" is a full-width filled button pinned at the bottom, and
/// the single "Salvar como padrão" checkbox sits below it.
class RouteDetailsPage extends ConsumerStatefulWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends ConsumerState<RouteDetailsPage> {
  /// Single global "Salvar como padrão" flag — Spoke uses one screen-level
  /// checkbox, NOT one per section. Default is UNCHECKED (per Spoke).
  bool _saveAsDefault = false;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(routeConfigControllerProvider(widget.routeId));
    final isValid = ref.watch(isRouteConfigValidProvider(widget.routeId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onClose: () => context.pop()),
              const SizedBox(height: 8),
              _partidaSection(config),
              _destinoSection(config),
              _pausaSection(config),
              const SizedBox(height: 24),
              _ConcluidoButton(
                enabled: isValid,
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 8),
              _SalvarComoPadraoCheckbox(
                value: _saveAsDefault,
                onChanged: (v) => setState(() => _saveAsDefault = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  RouteDetailsSection _partidaSection(RouteConfig config) {
    final hasCustomLocation = config.startLocation != null &&
        !config.startLocation!.isUserCurrentLocation;
    final localLabel =
        hasCustomLocation ? config.startLocation!.address : 'Usar local atual';
    final startConfigured = config.timeStart != null;
    // Spoke parity: when not yet configured the row reads the placeholder
    // 'Iniciar agora mesmo'; once a time is confirmed, the row collapses to
    // just 'HH:MM' (no prefix). Verified live via
    // /tmp/spoke-a5-inspection/ms4-live-detalhes-final.xml at bounds
    // [203,752][314,810] showing the lone TextView 'text="10:30"'.
    final inicioLabel = startConfigured
        ? _formatTimeOfDay(config.timeStart!.time)
        : 'Iniciar agora mesmo';

    return RouteDetailsSection(
      title: 'Partida',
      children: [
        RouteConfigRow(
          semanticsKey: 'partida_local',
          label: localLabel,
          leading: LucideIcons.locateFixed,
          active: true,
          onTap: _onTapPartidaLocal,
        ),
        RouteConfigRow(
          semanticsKey: 'partida_inicio',
          label: inicioLabel,
          leading: LucideIcons.clock,
          active: true,
          onTap: _onTapPartidaInicio,
        ),
      ],
    );
  }

  /// Push the Partida sub-picker (`AddStopPage` in `PickerMode.startLocation`)
  /// and, on success, write the selected [StartLocation] back into
  /// `routeConfigControllerProvider`. The Future resolves to `null` when the
  /// user dismisses the picker (X close / back), per the Spoke contract.
  Future<void> _onTapPartidaLocal() async {
    final result = await context.push<StartLocation>(
      '/home/routes/active/${widget.routeId}/details/start-location',
    );
    if (result == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setStartLocation(result);
  }

  /// Open the Spoke-fidelity numpad picker (ADR-0042) for the Partida-Início
  /// row and, on confirm, write the resulting [TimeOfDay] back through
  /// `routeConfigController.setTimeStart`. Sheet returns `null` on
  /// tap-outside / system back — that's a cancel, leave state untouched.
  Future<void> _onTapPartidaInicio() async {
    final picked = await _showTimePicker('Definir horário de início');
    if (picked == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setTimeStart(TimeStart(time: picked));
  }

  RouteDetailsSection _destinoSection(RouteConfig config) {
    // The Destino row is always rendered as "configured" (blue icon).
    // `RouteConfig.empty()` ships `destination: RoundTrip()` per Spoke parity,
    // so the row's primary text is "Ida e volta" out of the box. The null
    // branch in the `_destination*` helpers below is defense-in-depth for the
    // public `withDestination(null)` updater — it renders the same Spoke
    // default rather than blanking the row.
    return RouteDetailsSection(
      title: 'Destino',
      children: [
        RouteConfigRow(
          semanticsKey: 'destino',
          label: _destinationLabel(config.destination),
          subtitle: _destinationSubtitle(config.destination),
          leading: _destinationIcon(config.destination),
          active: true,
          onTap: null,
        ),
        RouteConfigRow(
          semanticsKey: 'destino_horario_termino',
          label: config.timeEnd == null
              ? 'Definir horário de término'
              : _formatTimeOfDay(config.timeEnd!.time),
          leading: LucideIcons.clock,
          active: config.timeEnd != null,
          onTap: _onTapDestinoHorarioTermino,
        ),
      ],
    );
  }

  /// Symmetric counterpart of [_onTapPartidaInicio] for the Destino-Término
  /// row — opens the same numpad sheet and writes [TimeEnd] on confirm.
  Future<void> _onTapDestinoHorarioTermino() async {
    final picked = await _showTimePicker('Definir horário de término');
    if (picked == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setTimeEnd(TimeEnd(time: picked));
  }

  /// Shared launcher for the [TimePickerSheet] modal so both time rows use
  /// identical config. Mirrors the [showModalBottomSheet] pattern used by
  /// `AppDrawer` (single precedent in this codebase for sheet-as-modal).
  /// Returns `null` on tap-outside / system back.
  Future<TimeOfDay?> _showTimePicker(String title) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: AppColors.bg,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => TimePickerSheet(title: title),
    );
  }

  RouteDetailsSection _pausaSection(RouteConfig config) {
    final rows = <Widget>[
      for (var i = 0; i < config.breaks.length; i++)
        RouteConfigRow(
          semanticsKey: 'pausa_$i',
          label:
              '${_formatTimeOfDay(config.breaks[i].startTime)} • ${config.breaks[i].durationMinutes}min',
          leading: LucideIcons.coffee,
          active: true,
          onTap: null,
        ),
      const RouteConfigRow(
        semanticsKey: 'adicionar_pausa',
        label: 'Adicionar pausa',
        leading: LucideIcons.coffee,
        active: false,
        onTap: null,
      ),
    ];

    return RouteDetailsSection(title: 'Pausa', children: rows);
  }

  /// Maps a [Destination] subtype to its primary display string.
  ///
  /// `RouteConfig.empty()` ships `destination: RoundTrip()`, so the default
  /// Destino label is "Ida e volta" via the [RoundTrip] arm. The `null` arm
  /// is defensive: [RouteConfig.withDestination] accepts `null` to clear, so
  /// the UI keeps rendering the Spoke default in that edge case rather than
  /// blanking the row. `BackToStart()` (a distinct, explicit choice from the
  /// picker) renders as "Voltar ao local de início".
  String _destinationLabel(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Ida e volta',
      BackToStart() => 'Voltar ao local de início',
      SpecificAddress(:final address) => address,
    };
  }

  /// Spoke shows a small subtitle under "Ida e volta" explaining the mode.
  /// Other destination variants have no subtitle.
  String? _destinationSubtitle(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Viagem de ida e volta a partir do local atual',
      _ => null,
    };
  }

  IconData _destinationIcon(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => LucideIcons.repeat,
      BackToStart() => LucideIcons.cornerDownLeft,
      SpecificAddress() => LucideIcons.mapPin,
    };
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'route_details_close',
          button: true,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.text),
            tooltip: 'Fechar',
            onPressed: onClose,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Detalhes da rota',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConcluidoButton extends StatelessWidget {
  const _ConcluidoButton({required this.enabled, required this.onPressed});
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_confirm',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.disabledBg,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.btn),
            ),
          ),
          onPressed: enabled ? onPressed : null,
          child: const Text(
            'Concluído',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _SalvarComoPadraoCheckbox extends StatelessWidget {
  const _SalvarComoPadraoCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_salvar_como_padrao',
      child: CheckboxListTile(
        value: value,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: AppColors.primary,
        title: const Text(
          'Salvar como padrão',
          style: TextStyle(fontSize: 14, color: AppColors.text),
        ),
      ),
    );
  }
}
