import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/home_top_bar.dart';
import '../../../core/widgets/rp_button.dart';
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
          showMore: true,
          onMorePressed: () => _showMoreMenu(context, ref),
        ),
        orElse: () => const HomeTopBar(count: 0),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Adicionar parada',
        child: FloatingActionButton(
          onPressed: () => context.push('/home/stops/add'),
          child: const Icon(Icons.add),
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
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
      Offset.zero & overlay.size,
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
    if (confirmed == true) {
      await ref.read(stopsControllerProvider.notifier).clear();
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
