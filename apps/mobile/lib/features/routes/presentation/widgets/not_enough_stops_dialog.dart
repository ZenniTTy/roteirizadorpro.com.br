import 'package:flutter/material.dart';

/// G1 — paradas insuficientes para otimizar. Microcopy PT-BR original
/// (ADR-0010), estrutura espelha `OptimiseNotEnoughStopsDialog` do Spoke
/// (título + corpo + único botão Ok). Distinto do erro de rede.
Future<void> showNotEnoughStopsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicione mais paradas'),
      content: const Text(
        'Para otimizar a rota, adicione pelo menos uma parada além do ponto '
        'de partida e do destino.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ok'),
        ),
      ],
    ),
  );
}
