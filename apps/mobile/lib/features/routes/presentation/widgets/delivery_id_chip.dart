import 'package:flutter/material.dart';

/// Chip do identificador de parada ("A1".."AN" no formato Moderno, ou "1".."N"
/// no Clássico — o texto vem pronto do solver em `stop.deliveryId`). Quando a
/// parada ainda não foi numerada (`deliveryId == null`), mostra "—". Cor/estilo
/// herdam o tema (tokens do prototipo); o visual final é o polish.
class DeliveryIdChip extends StatelessWidget {
  const DeliveryIdChip({required this.deliveryId, super.key});

  final String? deliveryId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        deliveryId ?? '—',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
