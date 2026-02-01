import 'package:flutter/material.dart';

class AppColors {
  // --- Light ---
  static const lightBackground = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1D1D1F);
  static const lightSecondaryText = Color(0xFF6E6E73);
  static const lightBorder = Color(0xFFE2E2E7);
  static const lightAccent = Color(0xFF0071EB);
  static const lightAccentContainer = Color(0xFFE8F1FE);

  // --- Dark ---
  static const darkBackground = Color(0xFF121214);
  static const darkSurface = Color(0xFF1E1E21);
  static const darkOnSurface = Color(0xFFF2F2F7);
  static const darkSecondaryText = Color(0xFF8E8E93);
  static const darkBorder = Color(0xFF2C2C2E);
  static const darkAccent = Color(0xFF0A84FF);
  static const darkAccentContainer = Color(0xFF1A2E4A);

  static const positiveColor = Color(0xFF34C759);
  static const negativeColor = Color(0xFFFF3B30);
  static const warningColor = Color(0xFFFF9F0A);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.lightAccent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.lightAccentContainer,
        onPrimaryContainer: AppColors.lightAccent,
        secondary: AppColors.lightSecondaryText,
        onSecondary: Colors.white,
        error: AppColors.negativeColor,
        onError: Colors.white,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightOnSurface,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        surfaceVariant: AppColors.lightBorder,
        onSurfaceVariant: AppColors.lightSecondaryText,
        outline: AppColors.lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.lightAccentContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.lightAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.lightSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.lightAccent,
              size: 22,
            );
          }
          return const IconThemeData(
            color: AppColors.lightSecondaryText,
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      textTheme: _buildTextTheme(
        AppColors.lightOnSurface,
        AppColors.lightSecondaryText,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkAccent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkAccentContainer,
        onPrimaryContainer: AppColors.darkAccent,
        secondary: AppColors.darkSecondaryText,
        onSecondary: Colors.white,
        error: AppColors.negativeColor,
        onError: Colors.white,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnSurface,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        surfaceVariant: AppColors.darkBorder,
        onSurfaceVariant: AppColors.darkSecondaryText,
        outline: AppColors.darkBorder,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkAccentContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.darkAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: AppColors.darkSecondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.darkAccent,
              size: 22,
            );
          }
          return const IconThemeData(
            color: AppColors.darkSecondaryText,
            size: 22,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),
      textTheme: _buildTextTheme(
        AppColors.darkOnSurface,
        AppColors.darkSecondaryText,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      bodyMedium: TextStyle(fontSize: 14, color: primary),
      bodySmall: TextStyle(fontSize: 12, color: secondary),
      labelSmall: TextStyle(fontSize: 11, color: secondary),
    );
  }
}
