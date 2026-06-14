import 'package:flutter/material.dart';

/// Confirmação de remoção diferida de parada (T9).
///
/// Retorna `true` se o usuário confirmar a remoção, `false` se cancelar e
/// `null` se o diálogo for dispensado por gesto (toque fora / botão voltar).
Future<bool?> showConfirmDeferredRemovalDialog(
  BuildContext context, {
  required String stopLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remover esta parada?'),
      content: Text(
        'A parada $stopLabel fica na lista por enquanto e sai da rota '
        'na próxima vez que você otimizar.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}
