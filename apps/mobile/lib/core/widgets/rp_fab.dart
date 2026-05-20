import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RpFab extends StatelessWidget {
  const RpFab({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.icon,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, AppColors.primary],
        ),
        boxShadow: AppShadows.fab,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon ?? Icons.add,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );

    final semantics = Semantics(button: true, child: button);
    final label = tooltip;
    if (label == null) return semantics;
    return Tooltip(message: label, child: semantics);
  }
}
