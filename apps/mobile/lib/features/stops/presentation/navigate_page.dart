import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/external_nav.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stops_async_view.dart';

/// Post-handoff navigation checklist per slice 2 acceptable scope.
/// Prototype `prototipo/screens-e.jsx:300-468` shows a full turn-by-turn
/// mock (perspective map, instruction card, vehicle marker, speed gauge);
/// implementing that needs Mapbox Navigation SDK or similar paid product,
/// explicitly out-of-scope per ADR-0017 §6. This screen ships the
/// rider-facing essentials: a list of stops with done-checkboxes,
/// "Próxima parada" CTA that hands the next undone stop off to Waze
/// (Waze default per ADR-0017 amended this session), and "Concluir rota"
/// when every stop is checked.
class NavigatePage extends ConsumerStatefulWidget {
  const NavigatePage({super.key, this.onRouteCompleted});

  /// Callback injection for widget tests; production routes via GoRouter.
  final void Function(BuildContext context)? onRouteCompleted;

  @override
  ConsumerState<NavigatePage> createState() => _NavigatePageState();
}

class _NavigatePageState extends ConsumerState<NavigatePage> {
  final Set<String> _done = {};

  void _complete(BuildContext context) => (widget.onRouteCompleted ??
      (ctx) => ctx.go('/home/route-complete'))(context);

  Future<void> _openNext(Stop nextStop) async {
    final nav = ref.read(externalNavProvider);
    await nav.openInWaze(nextStop);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Em navegação')),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'NavigatePage',
          data: (context, stops) {
            if (stops.isEmpty) {
              return const Center(
                child: Text('Nenhuma parada para navegar.'),
              );
            }
            final nextUndone =
                stops.where((s) => !_done.contains(s.id)).firstOrNull;
            final allDone = _done.length == stops.length;

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final stop = stops[i];
                      final checked = _done.contains(stop.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _done.add(stop.id);
                          } else {
                            _done.remove(stop.id);
                          }
                        }),
                        title: Text(
                          stop.label ??
                              '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                          style: TextStyle(
                            decoration:
                                checked ? TextDecoration.lineThrough : null,
                            color: checked
                                ? Theme.of(context).disabledColor
                                : null,
                          ),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: checked
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Theme.of(context).colorScheme.primary,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: checked
                                  ? Theme.of(context).disabledColor
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: allDone
                        ? FilledButton.icon(
                            onPressed: () => _complete(context),
                            icon: const Icon(Icons.flag),
                            label: const Text('Concluir rota'),
                          )
                        : FilledButton.icon(
                            onPressed: nextUndone == null
                                ? null
                                : () => _openNext(nextUndone),
                            icon: const Icon(Icons.navigation),
                            label: const Text('Próxima parada'),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
