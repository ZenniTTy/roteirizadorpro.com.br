import 'package:flutter/material.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/delivery_id_chip.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

/// Tela de pré-confirmação da rota otimizada (G4 — PRE-CONFIRM).
/// Mostra o resumo (RouteSummaryRow), a lista de paradas com chips de ID e
/// dois botões de ação: "Refinar" e "Confirmar".
class PreConfirmView extends StatelessWidget {
  const PreConfirmView({
    required this.stops,
    required this.durationMinutes,
    required this.distanceMeters,
    required this.onRefine,
    required this.onConfirm,
    required this.onStopTap,
    required this.onReoptimize,
    super.key,
  });

  final List<Stop> stops;
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
              icon: const Icon(Icons.more_vert),
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
            itemCount: stops.length,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return ListTile(
                // Key por id: ao "Inverter a ordem" a lista vem revertida; sem a
                // key o ListView reconcilia por índice e refaz subtrees em vez de
                // mover (perf-auditor should-fix Á7 PR-B1).
                key: ValueKey(stop.id),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [DeliveryIdChip(deliveryId: stop.deliveryId)],
                ),
                title: Text(stop.streetName),
                subtitle: Text(stop.fullAddress),
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
