// lib/core/theme/theme.dart

import 'package:flutter/material.dart';

import 'styles.dart';

class AppTheme {
  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Poppins',

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      // ========================================================
      // CARD
      // ========================================================
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.danger),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,

          side: const BorderSide(color: AppColors.primary),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      // ========================================================
      // SWITCH
      // ========================================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // CHECKBOX
      // ========================================================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // RADIO
      // ========================================================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // DROPDOWN
      // ========================================================
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(),
        ),
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      // ========================================================
      // LIST TILE
      // ========================================================
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),

      // ========================================================
      // TEXT THEME
      // ========================================================
      textTheme: const TextTheme(
        headlineSmall: AppTextStyles.heading,

        titleLarge: AppTextStyles.title,

        bodyLarge: AppTextStyles.body,

        bodyMedium: AppTextStyles.bodySecondary,

        bodySmall: AppTextStyles.small,
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.darkBackground,

      fontFamily: 'Poppins',

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),

      // ========================================================
      // CARD
      // ========================================================
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.danger),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),

        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      // ========================================================
      // ELEVATED BUTTON
      // ========================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,

          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,

          side: const BorderSide(color: AppColors.primary),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),

      // ========================================================
      // SWITCH
      // ========================================================
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // CHECKBOX
      // ========================================================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // RADIO
      // ========================================================
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
      ),

      // ========================================================
      // DROPDOWN
      // ========================================================
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          border: OutlineInputBorder(),
        ),
      ),

      // ========================================================
      // SNACKBAR
      // ========================================================
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      // ========================================================
      // LIST TILE
      // ========================================================
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: Colors.white,
      ),

      // ========================================================
      // TEXT THEME
      // ========================================================
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),

        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),

        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          color: Colors.white,
        ),

        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.darkTextSecondary,
        ),

        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
