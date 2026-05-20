import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../stops/domain/stop.dart';
import '../../stops/presentation/shared/stops_async_view.dart';
import '../../stops/state/stops_controller.dart';

/// Native share-sheet bridge per prototipo/screens-b.jsx:394-451.
/// The prototype rendered WhatsApp + Copy-link + QR cards as separate
/// affordances; the implementation collapses those into Android's
/// built-in share sheet via `share_plus`, which already exposes the
/// same destinations (WhatsApp, Mensagens, Email, copy-to-clipboard)
/// without the per-channel UI code. Branded referral/QR code is
/// post-M2.
class ShareSheet extends ConsumerWidget {
  const ShareSheet({super.key, this.shareFn});

  /// Test injection point: production calls `Share.share`; tests pass a
  /// recording fake so they don't reach the platform channel.
  final Future<void> Function(String text, {String? subject})? shareFn;

  /// Pure-Dart formatter exposed so unit tests can verify the
  /// WhatsApp-friendly format without spinning up a widget tree.
  static String buildRouteText(List<Stop> stops) {
    final buffer = StringBuffer('Rota otimizada — Roteirizador Pro\n\n');
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      buffer.writeln('${i + 1}. ${s.label ?? "(sem rótulo)"}');
      if (s.isGeocoded) {
        buffer.writeln(
          '   ${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  Future<void> _share(String text) async {
    final fn = shareFn ??
        (text, {subject}) =>
            SharePlus.instance.share(ShareParams(text: text, subject: subject));
    await fn(text, subject: 'Rota Roteirizador Pro');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Indique o app')),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'ShareSheet',
          data: (context, stops) {
            final text = buildRouteText(stops);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            text,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/settings');
                            }
                          },
                          child: const Text('Voltar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: stops.isEmpty ? null : () => _share(text),
                          icon: const Icon(Icons.share),
                          label: const Text('Compartilhar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
