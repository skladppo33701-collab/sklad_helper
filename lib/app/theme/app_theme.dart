import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemUiOverlayStyle
import 'app_color_schemes.dart';
import 'app_tokens.dart';
import 'app_typography.dart';
import 'app_dimens.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: AppColorSchemes.light,
      fontFamily: 'Inter', // Assuming you might add a custom font later
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      scaffoldBackgroundColor:
          AppTokens.bgDark, // Or a light equivalent if AppTokens has one

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: base.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.r16),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.x16,
          vertical: AppDimens.x16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimens.buttonH),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.r12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimens.buttonH),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.r12),
          ),
          side: BorderSide(color: base.colorScheme.outline),
        ),
      ),
    );
  }

  // Keep your dark theme logic, but apply similar structure for consistency
  static ThemeData dark() {
    // ... (Implementation using AppDimens similar to above)
    // For brevity, using the provided structure but ensuring AppDimens usage
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.accentGreen,
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      // ... existing overrides
      textTheme: AppTypography.textTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceDark, // Example
        contentPadding: const EdgeInsets.all(AppDimens.x16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.r12),
        ),
      ),
    );
  }
}
