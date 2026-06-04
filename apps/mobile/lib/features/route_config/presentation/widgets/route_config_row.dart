import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// A dimmer, right-aligned live wall-clock (`HH:MM`, 24h) that ticks itself.
///
/// Spoke renders this beside "Iniciar agora mesmo" on the unconfigured
/// Partida-Início row (live capture 2026-06-03, /tmp/spoke-a5-msfix/EVIDENCE.md
/// §S1: the row shows two siblings "Iniciar agora mesmo" + "23:36" tracking
/// the system clock). The widget owns its [Timer] and cancels it in [dispose]
/// so it never leaks. [clock] is injectable so widget tests pin a fixed time
/// instead of depending on real wall-time.
class LiveClockLabel extends StatefulWidget {
  const LiveClockLabel({super.key, this.clock = TimeOfDay.now});

  /// Returns the current time. Defaults to [TimeOfDay.now]; tests inject a
  /// fixed value for determinism.
  final TimeOfDay Function() clock;

  @override
  State<LiveClockLabel> createState() => _LiveClockLabelState();
}

class _LiveClockLabelState extends State<LiveClockLabel> {
  late TimeOfDay _now = widget.clock();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 30s cadence is enough for a minute-granular HH:MM display and keeps the
    // rebuild rate trivial. Reading the injected clock keeps tests deterministic.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = widget.clock());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    return Text(
      '$hh:$mm',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      ),
    );
  }
}

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
    this.trailingValue,
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

  /// Optional trailing widget rendered between the label column and the
  /// chevron (dimmer, right-aligned). Spoke uses this on the unconfigured
  /// "Iniciar agora mesmo" row to show the live wall-clock alongside the
  /// label (see [LiveClockLabel] below in this file). Kept as a `Widget` slot
  /// so the row stays presentational — the live-clock lifecycle (its [Timer])
  /// lives inside [LiveClockLabel], not here.
  final Widget? trailingValue;

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
                if (trailingValue != null) ...[
                  const SizedBox(width: 8),
                  trailingValue!,
                ],
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
