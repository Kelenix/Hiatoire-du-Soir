import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thème unique de l'app (`docs/design/design-system.md` §1 et §2).
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.violet,
    onPrimary: Colors.white,
    secondary: AppColors.lavender,
    tertiary: AppColors.gold,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.cardBorder,
    error: AppColors.error,
  );
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.night,
    fontFamily: _inter,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      titleTextStyle: _style(_nunito, 20, 800),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      titleTextStyle: _style(_nunito, 20, 800),
      contentTextStyle: _style(_inter, 16, 400, lineHeight: 24, color: AppColors.textSecondary),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.lavender, textStyle: _style(_nunito, 15, 700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: _style(_inter, 15, 400, color: AppColors.textSecondary),
      enabledBorder: _inputBorder(AppColors.cardBorder),
      disabledBorder: _inputBorder(AppColors.cardBorder),
      focusedBorder: _inputBorder(AppColors.lavender),
      errorBorder: _inputBorder(AppColors.error),
      focusedErrorBorder: _inputBorder(AppColors.error),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.violet,
      side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: _style(_nunito, 15, 700),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: _style(_inter, 15, 400),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: TextTheme(
      displayLarge: _style(_nunito, 34, 900, lineHeight: 40),
      headlineMedium: _style(_nunito, 26, 800, lineHeight: 32),
      titleMedium: _style(_nunito, 18, 700, lineHeight: 24),
      labelLarge: _style(_nunito, 15, 600, lineHeight: 20),
      bodyLarge: _style(_inter, 16, 400, lineHeight: 24),
      bodySmall: _style(_inter, 13, 400, lineHeight: 18, color: AppColors.textSecondary),
      labelSmall: _style(_inter, 12, 500, color: AppColors.slogan, letterSpacing: 4),
    ),
  );
}

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: BorderSide(color: color, width: 1.5),
);

const _nunito = 'Nunito';
const _inter = 'Inter';

/// Texte d'une histoire : Inter crème, interligne large (design system §2). Taille réglable à l'Inc-4.
final storyTextStyle = _style(_inter, 20, 400, lineHeight: 32, color: AppColors.cream);

/// Les polices intégrées sont variables : la graisse passe aussi par l'axe `wght`.
TextStyle _style(
  String family,
  double size,
  int weight, {
  double? lineHeight,
  Color color = AppColors.textPrimary,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    height: lineHeight == null ? null : lineHeight / size,
    color: color,
    letterSpacing: letterSpacing,
  );
}
