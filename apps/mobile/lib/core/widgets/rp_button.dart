import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RpButton extends StatelessWidget {
  const RpButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.full = true,
    this.neon = false,
    this.locked = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool full;
  final bool neon;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || locked;
    final gradient = neon && !disabled
        ? const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;
    final solidColor = disabled ? AppColors.disabledBg : AppColors.primary;

    final child = Container(
      height: 52,
      width: full ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? solidColor : null,
        borderRadius: BorderRadius.circular(AppRadii.btn),
        boxShadow: disabled ? null : AppShadows.primaryButton,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (locked) ...[
                const Icon(Icons.lock_outline, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              if (icon != null) ...[
                IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 18),
                  child: icon!,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (neon && !disabled)
            const Positioned(
              right: 14,
              child: _NeonDot(),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadii.btn),
          child: child,
        ),
      ),
    );
  }
}

class _NeonDot extends StatelessWidget {
  const _NeonDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.neon,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0xE6C6FF3D), blurRadius: 8),
        ],
      ),
    );
  }
}
