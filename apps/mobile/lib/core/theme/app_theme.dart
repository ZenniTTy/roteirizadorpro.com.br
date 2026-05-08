import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF6C3FC5);
  static const Color primaryDark = Color(0xFF4E2D91);
  static const Color primaryLight = Color(0xFFEDE7F6);
  static const Color accent = Color(0xFF9B6DFF);
  static const Color neon = Color(0xFFC6FF3D);
  static const Color neonDark = Color(0xFF9BCC1F);
  static const Color neonLight = Color(0xFFF1FFCC);
  static const Color neonInk = Color(0xFF3D5400);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
    );
  }
}
