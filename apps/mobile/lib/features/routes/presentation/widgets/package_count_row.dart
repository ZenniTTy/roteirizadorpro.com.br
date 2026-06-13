import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import 'package_count_dialog.dart';

/// Row 'Pacotes' com stepper inline [− N +] clamp 1..9999 (F8/H3).
/// Tap no NÚMERO abre o PackageCountDialog. Cada mudança → onChanged (live F3).
///
/// H3: o botão '−' NUNCA é desabilitado; com count==1, tap chama onChanged(1)
/// (clamp — não 0). Nenhum estado `disabled` inventado.
///
/// Semantics identifiers:
///   'edit_stop_packages_minus'  → botão −
///   'edit_stop_packages_value'  → o número (abre dialog)
///   'edit_stop_packages_plus'   → botão +
class PackageCountRow extends StatelessWidget {
  const PackageCountRow({
    super.key,
    required this.count,
    required this.onChanged,
  });

  final int count;
  final ValueChanged<int> onChanged;

  Future<void> _openDialog(BuildContext context) async {
    final value = await PackageCountDialog.show(context, current: count);
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Row(
        children: [
          const Icon(
            LucideIcons.package,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Pacotes',
              style: TextStyle(fontSize: 15, color: AppColors.text),
            ),
          ),
          _StepperButton(
            semanticsId: 'edit_stop_packages_minus',
            icon: LucideIcons.minus,
            onTap: () => onChanged((count - 1).clamp(1, 9999)),
          ),
          Semantics(
            identifier: 'edit_stop_packages_value',
            button: true,
            child: InkWell(
              onTap: () => _openDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          _StepperButton(
            semanticsId: 'edit_stop_packages_plus',
            icon: LucideIcons.plus,
            onTap: () => onChanged((count + 1).clamp(1, 9999)),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.semanticsId,
    required this.icon,
    required this.onTap,
  });

  final String semanticsId;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
      ),
    );
  }
}
