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
    super.key,
  });

  final List<Stop> stops;
  final int durationMinutes;
  final double distanceMeters;
  final VoidCallback onRefine;
  final VoidCallback onConfirm;
  final void Function(String stopId) onStopTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
