import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';
import '../../state/route_config_controller.dart';
import '../widgets/route_config_row.dart';
import '../widgets/route_details_section.dart';

/// Full-screen "Detalhes da rota" — Spoke white-label layout (MS2).
///
/// Visual shell only: each row's onTap is a debugPrint stub (MS3–MS8 wire
/// the real sub-pickers). "Concluído" is enabled iff
/// [isRouteConfigValidProvider] is true; in MS2 it pops with no
/// side-effects — MS8 wires the real save + the "Salvar como padrão"
/// persistence.
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
    final startSuffix = startConfigured
        ? _formatTimeOfDay(config.timeStart!.time)
        : _formatTimeOfDay(TimeOfDay.now());

    return RouteDetailsSection(
      title: 'Partida',
      children: [
        RouteConfigRow(
          semanticsKey: 'partida_local',
          label: localLabel,
          leading: LucideIcons.locateFixed,
          active: true,
          onTap: () => debugPrint('[MS2] partida_local tap (wires MS3)'),
        ),
        RouteConfigRow(
          semanticsKey: 'partida_inicio',
          label: 'Iniciar agora mesmo  $startSuffix',
          leading: LucideIcons.clock,
          active: true,
          onTap: () => debugPrint('[MS2] partida_inicio tap (wires MS4)'),
        ),
      ],
    );
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
          onTap: () => debugPrint('[MS2] destino tap (wires MS5)'),
        ),
        RouteConfigRow(
          semanticsKey: 'destino_horario_termino',
          label: config.timeEnd == null
              ? 'Definir horário de término'
              : _formatTimeOfDay(config.timeEnd!.time),
          leading: LucideIcons.clock,
          active: config.timeEnd != null,
          onTap: () =>
              debugPrint('[MS2] destino_horario_termino tap (wires MS5)'),
        ),
      ],
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
          onTap: () => debugPrint('[MS2] pausa_$i tap (wires MS6)'),
        ),
      RouteConfigRow(
        semanticsKey: 'adicionar_pausa',
        label: 'Adicionar pausa',
        leading: LucideIcons.coffee,
        active: false,
        onTap: () => debugPrint('[MS2] adicionar_pausa tap (wires MS6)'),
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
