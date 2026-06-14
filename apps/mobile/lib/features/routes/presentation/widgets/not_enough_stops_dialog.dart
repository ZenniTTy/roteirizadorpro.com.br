import 'package:flutter/material.dart';

/// G1 — paradas insuficientes para otimizar. ESTRUTURA espelha o
/// `NotEnoughStops` do Spoke (título + corpo + único botão Ok), mas o TEXTO é
/// microcopy PT-BR ORIGINAL (ADR-0010) — reformulado, NÃO verbatim da string
/// `optimize_route_minimum_stops_body` do Spoke. Distinto do erro de rede.
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
