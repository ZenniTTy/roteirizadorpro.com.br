import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F7FC);
  static const Color border = Color(0xFFE8E4F0);
  static const Color text = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF6B6880);

  static const Color success = Color(0xFF22C55E);
  static const Color successBg = Color(0xFFE7F8EE);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF4E0);

  static const Color disabledBg = Color(0xFFD5D0E0);
}

class AppRadii {
  const AppRadii._();

  static const double card = 16;
  static const double btn = 24;
  static const double input = 12;
  static const double sheet = 20;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x146C3FC5), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A6C3FC5), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> primaryButton = [
    BoxShadow(color: Color(0x3D6C3FC5), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> inputFocus = [
    BoxShadow(color: Color(0x146C3FC5), blurRadius: 0, spreadRadius: 4),
  ];

  static const List<BoxShadow> logo = [
    BoxShadow(color: Color(0x4D6C3FC5), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x526C3FC5), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x2E6C3FC5), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Shadow for floating circular buttons + search pills hovering over a map.
  /// Mirrors `prototipo/screens-e.jsx:82-89` and `:215-218`: `0 4px 12px
  /// rgba(26,26,46,0.18)`. Used by map screens (MS-08, MS-09, MS-10, MS-11).
  static const List<BoxShadow> floatingCircle = [
    BoxShadow(
      color: Color(0x2E1A1A2E),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Upward shadow for bottom sheets that sit over a map or a darker
  /// canvas. Mirrors `prototipo/tokens.js:27` `sheetShadow`:
  /// `0 -8px 32px rgba(108,63,197,0.16)`. Used by OptimizeRoute (MS-10).
  /// MS-11 Reorder uses a 24-px blur variant defined inline at the call
  /// site because `screens-e.jsx:720` specifies that local override.
  static const List<BoxShadow> sheetTop = [
    BoxShadow(
      color: Color(0x296C3FC5),
      blurRadius: 32,
      offset: Offset(0, -8),
    ),
  ];
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}
