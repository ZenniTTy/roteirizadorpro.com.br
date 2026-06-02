import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Group label + a vertical stack of independent row cards.
///
/// Spoke renders sections as `[muted small label] + [independent bordered
/// card per row]` — there is NO shared section container with internal
/// dividers, and NO per-section checkbox. The "Salvar como padrão" choice
/// is a single screen-level control owned by [RouteDetailsPage].
class RouteDetailsSection extends StatelessWidget {
  const RouteDetailsSection({
    super.key,
    required this.title,
    required this.children,
  });

  /// Header label, e.g. "Partida", "Destino", "Pausa".
  final String title;

  /// Rows rendered below the header. Each child is expected to render its
  /// own bordered card (see [RouteConfigRow]); this widget supplies no
  /// shared frame.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
