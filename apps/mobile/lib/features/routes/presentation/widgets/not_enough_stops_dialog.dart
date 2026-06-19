import 'package:flutter/material.dart';

/// G1 — paradas insuficientes para otimizar. Espelha o
/// `NotEnoughStops` do Spoke (título + corpo + único botão Ok,
/// `optimize_route_minimum_stops_body`). Distinto do erro de rede.
Future<void> showNotEnoughStopsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicione mais paradas'),
      content: const Text(
        'Ainda não dá para otimizar: a rota precisa de pelo menos uma entrega '
        'entre a partida e o destino. Inclua mais paradas e tente de novo.',
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
