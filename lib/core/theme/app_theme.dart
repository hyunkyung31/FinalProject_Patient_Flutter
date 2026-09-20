import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData resolve({required bool dark, required bool highContrast}) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: brightness,
          contrastLevel: highContrast ? 1 : 0,
        ).copyWith(
          primary: dark ? const Color(0xFF9AB9FF) : AppColors.navy,
          onPrimary: dark ? const Color(0xFF102447) : Colors.white,
          secondary: dark ? const Color(0xFF8FC5FF) : AppColors.blue,
          surface: dark ? const Color(0xFF131F33) : Colors.white,
          onSurface: dark ? const Color(0xFFE8EFFC) : AppColors.text,
          surfaceContainerHighest: dark
              ? const Color(0xFF1D2C45)
              : const Color(0xFFF1F5F9),
          onSurfaceVariant: dark
              ? const Color(0xFFB9C6DB)
              : AppColors.mutedText,
          outlineVariant: dark
              ? const Color(0xFF3A4D6B)
              : const Color(0xFFE2E8F0),
          secondaryContainer: dark
              ? const Color(0xFF203F70)
              : AppColors.lightBlue,
          onSecondaryContainer: dark ? const Color(0xFFDCEBFF) : AppColors.navy,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF0B1220)
          : AppColors.background,
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: scheme.onSurfaceVariant),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static final light = resolve(dark: false, highContrast: false);
  static final dark = resolve(dark: true, highContrast: false);
}
