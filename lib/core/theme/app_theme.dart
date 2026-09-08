import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy).copyWith(
      primary: AppColors.navy,
      secondary: AppColors.blue,
      tertiary: AppColors.pink,
      onSurface: AppColors.text,
    ),
  );
}
