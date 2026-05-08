import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RpGhostButton extends StatelessWidget {
  const RpGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.full = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 52,
      width: full ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        child: child,
      ),
    );
  }
}
