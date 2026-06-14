import 'package:flutter/material.dart';

/// Enum de retorno do diálogo de educação sobre numeração de paradas (T6).
enum IdEducationChoice { acknowledge, configure }

/// Abre o diálogo "Como a numeração funciona" e devolve a escolha do usuário.
Future<IdEducationChoice?> showIdEducationDialog(BuildContext context) {
  return showDialog<IdEducationChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Como a numeração funciona'),
      content: const Text(
        'Cada parada ganha um código (A1, A2, A3…) que segue a ordem da '
        'rota. Se você reordenar ou otimizar de novo, os códigos se ajustam '
        'sozinhos.',
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(IdEducationChoice.configure),
          child: const Text('Ajustar formato'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(IdEducationChoice.acknowledge),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
