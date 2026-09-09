import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'app_color_theme.dart';

abstract class AppTheme {
  static const String fontFamily = 'Inter';

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColorTheme.dark.background,
      extensions: const [AppColorTheme.dark],
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColorTheme.dark.surface,
        error: AppColors.alarmColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorTheme.dark.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorTheme.dark.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColorTheme.dark.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColorTheme.dark.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColorTheme.dark.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColorTheme.dark.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorTheme.dark.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorTheme.dark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorTheme.dark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.alarmColor),
        ),
        labelStyle: TextStyle(color: AppColorTheme.dark.textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppColorTheme.dark.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: AppColorTheme.dark.textHint, fontSize: 14),
        prefixIconColor: AppColorTheme.dark.textSecondary,
        suffixIconColor: AppColorTheme.dark.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColorTheme.dark.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColorTheme.dark.border,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColorTheme.dark.divider,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.24),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColorTheme.dark.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColorTheme.dark.textPrimary
                : AppColorTheme.dark.textSecondary,
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorTheme.dark.cardLight,
        contentTextStyle: TextStyle(color: AppColorTheme.dark.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColorTheme.dark.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColorTheme.dark.textPrimary),
        bodyMedium: TextStyle(color: AppColorTheme.dark.textSecondary),
        bodySmall: TextStyle(color: AppColorTheme.dark.textHint),
        labelLarge: TextStyle(color: AppColorTheme.dark.textPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColorTheme.dark.textSecondary),
        labelSmall: TextStyle(color: AppColorTheme.dark.textHint),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColorTheme.light.background,
      extensions: const [AppColorTheme.light],
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColorTheme.light.surface,
        error: AppColors.alarmColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorTheme.light.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorTheme.light.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColorTheme.light.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColorTheme.light.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColorTheme.light.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColorTheme.light.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorTheme.light.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorTheme.light.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColorTheme.light.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.alarmColor),
        ),
        labelStyle: TextStyle(color: AppColorTheme.light.textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: AppColorTheme.light.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: AppColorTheme.light.textHint, fontSize: 14),
        prefixIconColor: AppColorTheme.light.textSecondary,
        suffixIconColor: AppColorTheme.light.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontFamily),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColorTheme.light.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColorTheme.light.border,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColorTheme.light.divider,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColorTheme.light.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColorTheme.light.textPrimary
                : AppColorTheme.light.textSecondary,
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorTheme.light.surface,
        contentTextStyle: TextStyle(color: AppColorTheme.light.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColorTheme.light.textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColorTheme.light.textPrimary),
        bodyMedium: TextStyle(color: AppColorTheme.light.textSecondary),
        bodySmall: TextStyle(color: AppColorTheme.light.textHint),
        labelLarge: TextStyle(color: AppColorTheme.light.textPrimary, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: AppColorTheme.light.textSecondary),
        labelSmall: TextStyle(color: AppColorTheme.light.textHint),
      ),
    );
  }
}
