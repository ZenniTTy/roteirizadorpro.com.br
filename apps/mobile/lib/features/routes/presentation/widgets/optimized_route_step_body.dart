import 'package:flutter/material.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_config_labels.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_step_list.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

/// Lista contínua dos estados OTIMIZADOS (PRE-CONFIRM e Ready) — Branch B plano,
/// no MESMO trilho, fiel ao Spoke v3.65.1 (`SHELL OTIMIZADO` no design doc):
///
///   header (summary 2 linhas à ESQUERDA) → Sem pausa (RouteBreakStep) →
///   Ponto de partida (RouteStartStep) → paradas (RouteStopStep, número
///   zero-pad + ETA + trailing) → Destino (RouteEndStep).
///
/// A PAUSA VEM PRIMEIRO (antes do Início) — ordem do Branch B, ao contrário do
/// DRAFT. O [trailingBelowList] permite o Ready encaixar suas linhas extra
/// ("Compartilhar rota em tempo real" / "Carregar veículo") logo abaixo da
/// lista, dentro da mesma área rolável.
class OptimizedRouteStepBody extends StatelessWidget {
  const OptimizedRouteStepBody({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.stopTrailingBuilder,
    this.routeName,
    this.startLocation,
    this.destination,
    this.header,
    this.onStopTap,
    this.trailingBelowList,
    super.key,
  });

  final List<Stop> stops;
  final String? routeName;
  final StartLocation? startLocation;
  final Destination? destination;
  final int durationMinutes;
  final double distanceMeters;

  /// Trailing por parada (chip de ID "A1" — número e ID coexistem no Spoke).
  final Widget Function(Stop stop) stopTrailingBuilder;

  /// Override do header (o Ready troca o summary pelo banner "Otimização
  /// pendente" no skip-path). Quando null, usa o [_SummaryHeader] padrão.
  final Widget? header;

  /// Tap numa parada → editor (PRE-CONFIRM). Null no Ready (lista read-only).
  final void Function(String stopId)? onStopTap;

  /// Conteúdo extra abaixo da lista, na mesma área rolável (linhas do Ready).
  final Widget? trailingBelowList;

  @override
  Widget build(BuildContext context) {
    // Children planos do trilho: header + Pausa + Início + paradas + Destino
    // (+ extras do Ready). ListView (não builder) porque a contagem é pequena e
    // fixa por estado; o trilho contínuo precisa de isFirst/isLast por posição.
    final lastStopIndex = stops.length - 1;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        header ??
            _SummaryHeader(
              routeName: routeName,
              durationMinutes: durationMinutes,
              stopsCount: stops.length,
              distanceMeters: distanceMeters,
            ),
        // Pausa PRIMEIRO (Branch B): sem trilho acima (topo da lista), trilho
        // abaixo conecta ao Início.
        const RouteBreakStep(
          lineOne: 'Sem pausa',
          lineTwo: 'Toque para agendar uma pausa',
          hasLineAbove: false,
        ),
        RouteStartStep(
          lineOne: startLabel(startLocation, optimized: true),
          lineTwo: startSubtitle(optimized: true),
        ),
        for (var i = 0; i < stops.length; i++)
          RouteStopStep(
            // Key por id: ao "Inverter a ordem" a lista vem revertida; sem a key
            // o ListView reconcilia por índice e refaz subtrees em vez de mover.
            key: ValueKey(stops[i].id),
            position: stops[i].positionInRoute == null
                ? null
                : stops[i].positionInRoute! + 1,
            etaTime: stops[i].estimatedArrival == null
                ? null
                : formatEta(stops[i].estimatedArrival!),
            streetName: stops[i].streetName,
            fullAddress: stops[i].fullAddress,
            statusColor: AppColors.textMuted,
            // Trilho contínuo: Início acima, Destino abaixo → nenhum stop é
            // ponta. O destino fecha o trilho (isLast no RouteEndStep).
            isLast: i == lastStopIndex,
            trailing: stopTrailingBuilder(stops[i]),
            onTap: onStopTap == null ? null : () => onStopTap!(stops[i].id),
          ),
        RouteEndStep(
          lineOne: destinationLabel(destination),
          lineTwo: destinationSubtitle(destination),
        ),
        if (trailingBelowList != null) trailingBelowList!,
      ],
    );
  }
}

/// Header do summary otimizado — 2 linhas ALINHADAS À ESQUERDA (fiel ao Spoke):
/// linha 1 muted = "duração · N paradas · distância" (ou só "N paradas" quando
/// duração/distância são 0); linha 2 bold = nome da rota.
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.durationMinutes,
    required this.stopsCount,
    required this.distanceMeters,
    this.routeName,
  });

  final String? routeName;
  final int durationMinutes;
  final int stopsCount;
  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    final name = routeName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatOptimizedSummaryLine(
              durationMinutes: durationMinutes,
              stopsCount: stopsCount,
              distanceMeters: distanceMeters,
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (name != null && name.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
