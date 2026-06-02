import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';
import '../../state/route_config_controller.dart';
import '../widgets/route_config_row.dart';
import '../widgets/route_details_section.dart';

/// Full-screen "Detalhes da rota" — shell only (MS2). Wires no real
/// sub-pickers yet (MS3–MS8 do that); each row's onTap is a debugPrint
/// stub so manual exploration still confirms the wiring is intact.
///
/// Concluído is enabled iff [isRouteConfigValidProvider] is true. In MS2
/// it pops the page with no side-effects — MS8 wires the real save.
///
/// "Salvar como padrão para próximas rotas" checkbox state is local to
/// the page (per-section). MS8 wires it to RouteDefaults persistence.
class RouteDetailsPage extends ConsumerStatefulWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends ConsumerState<RouteDetailsPage> {
  bool _savePartidaAsDefault = true;
  bool _saveDestinoAsDefault = true;
  bool _savePausasAsDefault = true;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(routeConfigControllerProvider(widget.routeId));
    final isValid = ref.watch(isRouteConfigValidProvider(widget.routeId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.text),
          tooltip: 'Fechar',
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Detalhes da rota',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          Semantics(
            identifier: 'route_details_confirm',
            button: true,
            child: TextButton(
              onPressed: isValid ? () => context.pop() : null,
              child: Text(
                'Concluído',
                style: TextStyle(
                  color: isValid ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _partidaSection(config),
            _destinoSection(config),
            _pausasSection(config),
          ],
        ),
      ),
    );
  }

  RouteDetailsSection _partidaSection(RouteConfig config) {
    final localValue = config.startLocation == null
        ? 'Usar local atual'
        : config.startLocation!.address;
    final timeValue = config.timeStart == null
        ? '08:00'
        : _formatTimeOfDay(config.timeStart!.time);

    return RouteDetailsSection(
      title: 'Partida',
      saveAsDefault: _savePartidaAsDefault,
      onSaveAsDefaultChanged: (v) => setState(() => _savePartidaAsDefault = v),
      children: [
        RouteConfigRow(
          semanticsKey: 'partida_local',
          label: 'Local de início',
          trailingValue: localValue,
          onTap: () => debugPrint('[MS2] partida_local tap (wires MS3)'),
        ),
        RouteConfigRow(
          semanticsKey: 'partida_inicio',
          label: 'Início',
          trailingValue: timeValue,
          onTap: () => debugPrint('[MS2] partida_inicio tap (wires MS4)'),
        ),
      ],
    );
  }

  RouteDetailsSection _destinoSection(RouteConfig config) {
    return RouteDetailsSection(
      title: 'Destino',
      saveAsDefault: _saveDestinoAsDefault,
      onSaveAsDefaultChanged: (v) => setState(() => _saveDestinoAsDefault = v),
      children: [
        RouteConfigRow(
          semanticsKey: 'destino',
          label: 'Destino',
          trailingValue: _destinationLabel(config.destination),
          onTap: () => debugPrint('[MS2] destino tap (wires MS5)'),
        ),
      ],
    );
  }

  RouteDetailsSection _pausasSection(RouteConfig config) {
    final rows = <Widget>[
      for (var i = 0; i < config.breaks.length; i++)
        RouteConfigRow(
          semanticsKey: 'pausa_$i',
          label: 'Pausa ${i + 1}',
          trailingValue:
              '${_formatTimeOfDay(config.breaks[i].startTime)} • ${config.breaks[i].durationMinutes}min',
          onTap: () => debugPrint('[MS2] pausa_$i tap (wires MS6)'),
        ),
      _AdicionarPausaRow(
        onTap: () => debugPrint('[MS2] adicionar_pausa tap (wires MS6)'),
      ),
    ];

    return RouteDetailsSection(
      title: 'Pausas',
      saveAsDefault: _savePausasAsDefault,
      onSaveAsDefaultChanged: (v) => setState(() => _savePausasAsDefault = v),
      children: rows,
    );
  }

  /// Maps a [Destination] subtype to its display string. `null` and
  /// `BackToStart` both render "Voltar ao local de início" per spec §Goals 5.
  String _destinationLabel(Destination? destination) {
    return switch (destination) {
      null || BackToStart() => 'Voltar ao local de início',
      RoundTrip() => 'Ida e volta',
      SpecificAddress(:final address) => address,
    };
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

/// CTA row used at the bottom of the Pausas section. Distinct visual from
/// [RouteConfigRow] — leading "+" icon, primary color, no trailing
/// chevron — so it reads as an action rather than a status row.
class _AdicionarPausaRow extends StatelessWidget {
  const _AdicionarPausaRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_row_adicionar_pausa',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '+ Adicionar pausa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
