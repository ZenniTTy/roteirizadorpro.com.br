import 'package:flutter/material.dart';

/// Guard de saída quando a rota está em edição pós-otimização (A7-D7): avisa
/// que sair descarta as alterações e volta à última versão otimizada. Microcopy
/// ORIGINAL fiel ao significado de `discard_changes_dialog_*` do Spoke (ADR-0035).
///
/// Retorna `true` se o usuário tocar "Descartar" (descarta as edições),
/// `false`/`null` se escolher "Continuar editando" ou dispensar por gesto.
Future<bool?> showDiscardChangesDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Descartar as alterações?'),
      content: const Text(
        'Suas alterações não salvas serão perdidas e a rota volta para a '
        'última versão otimizada.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Continuar editando'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
}
