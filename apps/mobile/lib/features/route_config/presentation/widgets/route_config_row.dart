import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// One configurable row inside "Detalhes da rota" — Spoke-aligned layout:
/// a leading state-colored icon, a single-column primary label (whose text
/// IS the current value, not a static field name), an optional subtitle
/// directly below the label, and a trailing chevron.
///
/// State is encoded purely via [active] (icon colored `AppColors.primary`
/// when true, `AppColors.textMuted` when false). The widget is presentational
/// — it dispatches taps but holds no state.
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
    required this.leading,
    this.subtitle,
    this.active = true,
    this.onTap,
  });

  /// Short snake_case key (e.g. `partida_local`). Maestro id is
  /// `route_details_row_<semanticsKey>`.
  final String semanticsKey;

  /// Primary text. In Spoke this IS the current value
  /// (e.g. "Usar local atual", "Ida e volta"), not a static field name.
  final String label;

  /// Optional secondary line below [label] (Spoke uses this on "Ida e volta"
  /// to surface "Viagem de ida e volta a partir do local atual").
  final String? subtitle;

  /// Leading icon (Lucide). Color is derived from [active].
  final IconData leading;

  /// When `true`, leading icon renders in `AppColors.primary` (configured);
  /// when `false`, it renders muted (empty/inactive). Spoke encodes state
  /// via this exact dichotomy.
  final bool active;

  /// Optional tap handler. `null` makes the row inert (no ripple).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = active ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      identifier: 'route_details_row_$semanticsKey',
      button: true,
      child: Card.outlined(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(leading, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
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
      ),
    );
  }
}
