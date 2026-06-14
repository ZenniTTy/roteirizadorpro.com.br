import 'package:flutter/material.dart';

/// CTA sticky "Otimizar rota" (rodapé do shell, §10.5). `enabled` é falso
/// abaixo do mínimo de paradas (G1) — o botão fica desabilitado em vez de
/// rodar o solver sobre lista degenerada. Otimização é GRÁTIS (sem paywall;
/// o paywall só dispara em "Navegar" na Área 8).
class OptimizeCta extends StatelessWidget {
  const OptimizeCta({
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.refresh),
        label: const Text('Otimizar rota'),
      ),
    );
  }
}
