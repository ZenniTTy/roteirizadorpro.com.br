import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Section card used by `RouteDetailsPage` — a titled group of
/// [RouteConfigRow]s with a footer "Salvar como padrão para próximas
/// rotas" checkbox.
///
/// The checkbox value is owned by the caller (stateless from this
/// widget's POV); flip is dispatched via [onSaveAsDefaultChanged].
class RouteDetailsSection extends StatelessWidget {
  const RouteDetailsSection({
    super.key,
    required this.title,
    required this.children,
    required this.saveAsDefault,
    required this.onSaveAsDefaultChanged,
  });

  /// Header label, e.g. "Partida", "Destino", "Pausas".
  final String title;

  /// Rows rendered between the header and the checkbox.
  final List<Widget> children;

  /// Current state of the "Salvar como padrão" checkbox.
  final bool saveAsDefault;

  /// Fired when the checkbox is toggled by the user.
  final ValueChanged<bool> onSaveAsDefaultChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  children[i],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: InkWell(
              onTap: () => onSaveAsDefaultChanged(!saveAsDefault),
              child: Row(
                children: [
                  Checkbox(
                    value: saveAsDefault,
                    onChanged: (v) {
                      if (v != null) onSaveAsDefaultChanged(v);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Expanded(
                    child: Text(
                      'Salvar como padrão para próximas rotas',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
