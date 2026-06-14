import 'package:flutter/material.dart';

/// Escolha retornada pelo [showRefineRouteSheet].
enum RefineRouteChoice { invert, manualOrder }

/// Abre a sheet de ajuste de rota (T7 — MS-A7 PR-B).
///
/// Título: "Ajustar a rota"
/// Itens:
///   - "Inverter a ordem" / "Percorre as paradas de trás pra frente"
///     → [RefineRouteChoice.invert]
///   - "Definir a ordem na mão" / "Você arrasta as paradas na sequência que quiser"
///     → [RefineRouteChoice.manualOrder]
///
/// Retorna [RefineRouteChoice] ou null (barrier dismiss).
Future<RefineRouteChoice?> showRefineRouteSheet(BuildContext context) {
  return showModalBottomSheet<RefineRouteChoice>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ajustar a rota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: const Text('Inverter a ordem'),
              subtitle: const Text('Percorre as paradas de trás pra frente'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(RefineRouteChoice.invert),
            ),
            ListTile(
              leading: const Icon(Icons.gesture),
              title: const Text('Definir a ordem na mão'),
              subtitle: const Text(
                'Você arrasta as paradas na sequência que quiser',
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(RefineRouteChoice.manualOrder),
            ),
          ],
        ),
      );
    },
  );
}
