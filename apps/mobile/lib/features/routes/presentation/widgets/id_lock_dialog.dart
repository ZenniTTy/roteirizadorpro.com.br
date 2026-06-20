import 'package:flutter/material.dart';

/// FTUE one-shot mostrado ao confirmar a rota (A7-D6): avisa que, após a
/// confirmação, o código de cada parada fica fixo. Microcopy ORIGINAL fiel ao
/// significado de `package_identification_lock_dialog_*` do Spoke (ADR-0035).
///
/// Retorna `true` se o usuário tocar "Continuar" (segue a confirmação),
/// `false`/`null` se cancelar ou dispensar por gesto.
Future<bool?> showIdLockDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('A numeração vai travar'),
      content: const Text(
        'Depois que você confirmar, o código de cada parada (A1, A2, A3…) não '
        'muda mais — nem se você editar ou reordenar a rota.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
