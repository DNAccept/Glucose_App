import 'package:flutter/material.dart';
import 'glucose_class.dart';

/// Palette ported 1:1 from the HTML mockup's CSS custom properties so the
/// app's visual identity matches the approved design.
class AppColors {
  AppColors._();

  static const bg = Color(0xFFF6F7FB);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFECEFF4);
  static const accent = Color(0xFF1565C0);
  static const accentSoft = Color(0xFFE3ECFA);
  static const low = Color(0xFFE53935);
  static const normal = Color(0xFF2E7D32);
  static const high = Color(0xFFF9A825);

  static Color forClass(GlucoseClass cls) => switch (cls) {
        GlucoseClass.low => low,
        GlucoseClass.normal => normal,
        GlucoseClass.high => high,
      };
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.card,
      indicatorColor: AppColors.accentSoft,
      elevation: 0,
    ),
  );
}
