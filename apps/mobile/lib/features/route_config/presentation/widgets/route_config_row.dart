import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// One configurable row inside "Detalhes da rota" (label on the left, current
/// value on the right, chevron trailing). The widget is purely presentational
/// — it dispatches taps to the caller but holds no state.
///
/// `semanticsKey` becomes the Maestro identifier `route_details_row_<key>`,
/// per `lesson_maestro_flutter_listtile_tap_needs_semantics` — without an
/// explicit identifier, Maestro's text matcher hits inner TextView nodes and
/// the row's onTap never fires.
class RouteConfigRow extends StatelessWidget {
  const RouteConfigRow({
    super.key,
    required this.semanticsKey,
    required this.label,
    required this.trailingValue,
    this.onTap,
  });

  /// Short snake_case key (e.g. `partida_local`). Maestro id is
  /// `route_details_row_<semanticsKey>`.
  final String semanticsKey;

  /// Primary label, e.g. "Local de início".
  final String label;

  /// Current value rendered to the right of the label, e.g. "Usar local
  /// atual" or "08:00".
  final String trailingValue;

  /// Optional tap handler. `null` makes the row inert (no ripple).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_row_$semanticsKey',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 6,
                child: Text(
                  trailingValue,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
