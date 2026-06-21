import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/route_config/domain/route_config.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_config_labels.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_step_list.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

/// Tela de pré-confirmação da rota otimizada (G4 — PRE-CONFIRM).
/// Lista contínua fiel ao Spoke (Branch B, plana): linha de início → paradas
/// (número+ETA+chip) → linha de destino, no mesmo trilho. Mais o resumo
/// (RouteSummaryRow) e os botões "Refinar"/"Confirmar".
class PreConfirmView extends StatelessWidget {
  const PreConfirmView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.onRefine,
    required this.onConfirm,
    required this.onStopTap,
    required this.onReoptimize,
    this.startLocation,
    this.destination,
    super.key,
  });

  final List<Stop> stops;
  final StartLocation? startLocation;
  final Destination? destination;
  final int durationMinutes;
  final double distanceMeters;
  final VoidCallback onRefine;
  final VoidCallback onConfirm;
  final void Function(String stopId) onStopTap;
  final VoidCallback onReoptimize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            label: 'Opções da rota',
            button: true,
            child: IconButton(
              icon: const Icon(LucideIcons.moreVertical),
              onPressed: onReoptimize,
            ),
          ),
        ),
        RouteSummaryRow(
          durationMinutes: durationMinutes,
          stopsCount: stops.length,
          distanceMeters: distanceMeters,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            // [0] início → [1..n] paradas → [n+1] destino, todos no trilho
            // contínuo (Branch B plano, sem grupos).
            itemCount: stops.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return RouteStartStep(
                  lineOne: startLabel(startLocation, optimized: true),
                  lineTwo: startSubtitle(optimized: true),
                );
              }
              if (index == stops.length + 1) {
                return RouteEndStep(
                  lineOne: destinationLabel(destination),
                  lineTwo: destinationSubtitle(destination),
                );
              }
              final stop = stops[index - 1];
              // Otimizada: disco mostra número da parada + ETA ("Chegada"); o
              // chip de ID ("A1") vai no trailing (número e ID coexistem — o
              // formato Moderno do Spoke existe pra não confundi-los).
              return RouteStopStep(
                // Key por id: ao "Inverter a ordem" a lista vem revertida; sem a
                // key o ListView reconcilia por índice e refaz subtrees em vez de
                // mover (perf-auditor should-fix Á7 PR-B1).
                key: ValueKey(stop.id),
                position: stop.positionInRoute == null
                    ? null
                    : stop.positionInRoute! + 1,
                etaTime: stop.estimatedArrival == null
                    ? null
                    : formatEta(stop.estimatedArrival!),
                streetName: stop.streetName,
                fullAddress: stop.fullAddress,
                statusColor: AppColors.textMuted,
                // Trilho contínuo: início acima, destino abaixo → nenhum stop é
                // ponta (não cortar o trilho nas extremidades).
                trailing: DeliveryIdChip(deliveryId: stop.deliveryId),
                onTap: () => onStopTap(stop.id),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefine,
                    child: const Text('Refinar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onConfirm,
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
