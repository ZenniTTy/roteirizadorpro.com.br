import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/stop.dart';

/// Card-styled stop row matching `prototipo/screens-a.jsx:205-254`
/// (StopCard component): white background, `AppColors.border` outline,
/// `AppShadows.card`, `AppRadii.card`, a 32×32 primary index circle,
/// and a single-line address. Trailing slot is preserved for callers
/// like `ScreenReorder` that inject the drag handle there.
///
/// Status badge + complement second line (`prototipo a2` row) and
/// per-status circle fill (delivered → success, failed → error) are
/// data-model gaps tracked in TODO.md — the underlying `Stop` does
/// not yet carry `status` or `complement` fields, both arriving with
/// slice 3 (delivery tracking + Nominatim geocoding).
class StopListItem extends StatelessWidget {
  const StopListItem({
    super.key,
    required this.index,
    required this.stop,
    this.onTap,
    this.trailing,
  });

  final int index;
  final Stop stop;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final body = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _IndexCircle(index: index + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stop.label ??
                        '${stop.lat.toStringAsFixed(5)}, ${stop.lng.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: 'Parada ${index + 1}: ${stop.label ?? "sem rótulo"}',
      button: onTap != null,
      child: body,
    );
  }
}

class _IndexCircle extends StatelessWidget {
  const _IndexCircle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
