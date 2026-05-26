import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    this.eta,
    required this.count,
    this.showMore = false,
    this.onMorePressed,
  });

  final String? eta;
  final int count;
  final bool showMore;
  final VoidCallback? onMorePressed;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final hasEta = eta != null;
    final etaText = eta ?? '--:--';

    return Material(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Rota de hoje',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _EtaChip(text: etaText, active: hasEta),
              const SizedBox(width: 8),
              _CountChip(count: count),
              if (showMore) ...[
                const SizedBox(width: 8),
                _MoreButton(onPressed: onMorePressed),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EtaChip extends StatelessWidget {
  const _EtaChip({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.primaryLight : const Color(0xFFF1EFF7);
    final fg = active ? AppColors.primary : const Color(0xFFA09DB0);
    return Semantics(
      label: 'ETA $text',
      container: true,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_outlined, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: count == 1 ? '1 parada' : '$count paradas',
      container: true,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.more_vert, size: 20, color: AppColors.text),
        padding: EdgeInsets.zero,
        tooltip: 'Mais opções',
        splashRadius: 18,
      ),
    );
  }
}
