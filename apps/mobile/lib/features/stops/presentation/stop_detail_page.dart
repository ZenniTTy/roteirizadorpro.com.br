import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stops_async_view.dart';

class StopDetailPage extends ConsumerWidget {
  const StopDetailPage({
    super.key,
    required this.id,
    this.onDeleted,
    this.onEditPressed,
  });

  final String id;

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home` if the page was deep-linked).
  final void Function(BuildContext context)? onDeleted;

  final void Function(BuildContext context)? onEditPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStops = ref.watch(stopsControllerProvider);

    final title = asyncStops.maybeWhen(
      data: (stops) {
        final index = stops.indexWhere((s) => s.id == id);
        if (index < 0) return 'Parada';
        return 'Parada ${index + 1} de ${stops.length}';
      },
      orElse: () => 'Parada',
    );

    final actions = asyncStops.maybeWhen(
      data: (stops) {
        final stop = stops.where((s) => s.id == id).firstOrNull;
        if (stop == null) return const <Widget>[];
        return <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () {
              (onEditPressed ??
                  (ctx) => ctx.push('/home/stops/${stop.id}/edit'))(context);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value != 'delete') return;
              await ref.read(stopsControllerProvider.notifier).remove(stop.id);
              if (!context.mounted) return;
              (onDeleted ??
                  (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Excluir parada'),
              ),
            ],
          ),
        ];
      },
      orElse: () => const <Widget>[],
    );

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: stopsAsyncView(
          asyncStops,
          screenTag: 'StopDetailPage',
          data: (context, stops) {
            final stop = stops.where((s) => s.id == id).firstOrNull;
            if (stop == null) {
              return const Center(child: Text('Parada não encontrada.'));
            }
            return _StopDetailBody(stop: stop);
          },
        ),
      ),
    );
  }
}

class _StopDetailBody extends StatelessWidget {
  const _StopDetailBody({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _MapSection(stop: stop),
          const SizedBox(height: 16),
          _AddressCard(stop: stop),
          const SizedBox(height: 16),
          const _ActionRow(),
          const SizedBox(height: 16),
          const _LockedNavSection(),
          const SizedBox(height: 16),
          const _MoveOptionsCard(),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.stop});
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final hasLocation = stop.isGeocoded;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: SizedBox(
        height: 180,
        child: hasLocation
            ? FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(stop.lat, stop.lng),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'br.com.roteirizadorpro.roteirizador_pro',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(stop.lat, stop.lng),
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              )
            : Container(
                color: AppColors.surface,
                alignment: Alignment.center,
                child: const Text(
                  'Localização ainda não disponível',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.stop});
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stop.label ?? 'Sem endereço',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _DeliveryBadge(),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _StatBlock(label: 'DISTÂNCIA', value: '—')),
              Expanded(child: _StatBlock(label: 'TEMPO', value: '—')),
              Expanded(child: _StatBlock(label: 'CONTATO', value: '—')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryBadge extends StatelessWidget {
  const _DeliveryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Entrega',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Entregue',
            icon: Icons.check,
            background: AppColors.success,
            foreground: Colors.white,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Falhou',
            icon: Icons.close,
            background: AppColors.error,
            foreground: Colors.white,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Próxima',
            icon: Icons.arrow_forward,
            background: AppColors.bg,
            foreground: AppColors.primary,
            borderColor: AppColors.primary,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.transparent;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.btn),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadii.btn),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedNavSection extends StatelessWidget {
  const _LockedNavSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RpButton(label: 'Iniciar navegação', locked: true),
        const SizedBox(height: 8),
        Center(
          // TODO(slice-4): push('/paywall') once the paywall route lands.
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Assine para navegar →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoveOptionsCard extends StatelessWidget {
  const _MoveOptionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      clipBehavior: Clip.antiAlias,
      // TODO(MS-13/14): wire onTap to stopsControllerProvider.reorder.
      child: const Column(
        children: [
          _MoveOptionRow(label: 'Tornar próxima'),
          _MoveOptionRow(label: 'Mover para o início'),
          _MoveOptionRow(label: 'Mover para o final', last: true),
        ],
      ),
    );
  }
}

class _MoveOptionRow extends StatelessWidget {
  const _MoveOptionRow({required this.label, this.last = false});

  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (!last) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
