import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/home_top_bar.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_fab.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/home_bottom_nav.dart';
import 'shared/stop_list_item.dart';
import 'shared/stops_async_view.dart';

class HomeListPage extends ConsumerWidget {
  const HomeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);

    return Scaffold(
      appBar: asyncStops.maybeWhen(
        data: (stops) => HomeTopBar(
          count: stops.length,
          // Hide the more-menu when there are no stops: the only menu
          // item is "Limpar rota", which would be a destructive prompt
          // for a no-op on an empty list.
          showMore: stops.isNotEmpty,
          onMorePressed: () => _showMoreMenu(context, ref),
        ),
        orElse: () => const HomeTopBar(count: 0),
      ),
      // Push FAB above the "Otimizar rota" pinned button (~72px tall:
      // 8+12 padding + 52 button height). Without this lift the FAB
      // overlaps the CTA — flagged on MS-15a-followup M54 smoke (gap #3).
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: RpFab(
          tooltip: 'Adicionar parada',
          onPressed: () => context.push('/home/stops/add'),
        ),
      ),
      bottomNavigationBar: HomeBottomNav(
        navigationShell: StatefulNavigationShell.maybeOf(context)?.widget,
      ),
      body: SafeArea(
        child: stopsAsyncView(
          asyncStops,
          screenTag: 'HomeListPage',
          data: (context, stops) {
            if (stops.isEmpty) {
              return const Center(
                child: Text('Nenhuma parada ainda. Toque em Adicionar.'),
              );
            }
            // Per prototipo/screens-a.jsx:257-275: list of cards with an
            // 8-px gap and an "Otimizar rota" PrimaryButton (neon) pinned
            // in a white container above the BottomNav.
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (rowContext, index) => _StopRow(
                      index: index,
                      stop: stops[index],
                      onRemove: () => ref
                          .read(stopsControllerProvider.notifier)
                          .remove(stops[index].id),
                      onTap: () =>
                          rowContext.push('/home/stops/${stops[index].id}'),
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: RpButton(
                    label: 'Otimizar rota',
                    icon: const Icon(Icons.auto_awesome),
                    neon: true,
                    onPressed: stops.length < 2
                        ? null
                        : () => context.push('/home/optimize'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showMoreMenu(BuildContext context, WidgetRef ref) async {
    // Anchor + overlay can be null while the route is mid-pop or the
    // overlay hasn't attached yet. Bail quietly instead of crashing on
    // `!` cast — the user just sees no menu, which is the safer fallback.
    final buttonRO = context.findRenderObject();
    final overlayState = Navigator.of(context).overlay;
    if (buttonRO is! RenderBox || overlayState == null) return;
    final overlayRO = overlayState.context.findRenderObject();
    if (overlayRO is! RenderBox) return;
    final position = RelativeRect.fromRect(
      buttonRO.localToGlobal(Offset.zero, ancestor: overlayRO) & buttonRO.size,
      Offset.zero & overlayRO.size,
    );
    final selection = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem(value: 'clear', child: Text('Limpar rota')),
      ],
    );
    if (selection != 'clear') return;
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpar rota?'),
        content: const Text('Todas as paradas desta rota serão removidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      await ref.read(stopsControllerProvider.notifier).clear();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível limpar a rota. Tente novamente.'),
        ),
      );
    }
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.index,
    required this.stop,
    required this.onRemove,
    required this.onTap,
  });

  final int index;
  final Stop stop;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(stop.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Excluir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: StopListItem(index: index, stop: stop, onTap: onTap),
    );
  }
}
