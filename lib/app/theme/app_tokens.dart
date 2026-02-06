import 'package:flutter/material.dart';

/// Single source of truth tokens.
/// Change tokens here -> app UI updates everywhere.
class AppTokens {
  AppTokens._();

  // Brand
  static const Color seed = Color(0xFF006A6A); // fallback seed

  // Accent palette
  static const Color accentLime = Color(0xFFB7FF2A);
  static const Color accentGreen = Color(
    0xFFD4E157,
  ); // Updated to 2026 Acid Green
  static const Color accentRed = Color(0xFFFF453A);
  static const Color accentCyan = Color(0xFF64D2FF);
  static const Color accentAmber = Color(0xFFFFD60A);

  // Dark palette (target UI)
  static const Color bgDark = Color(0xFF0C0F10);
  static const Color bgOled = Color(
    0xFF050505,
  ); // Deepest Black for 2026 Planner
  static const Color surfaceDark = Color(0xFF141A1C);
  static const Color surfaceDark2 = Color(0xFF171E1F);
  static const Color outlineDark = Color(0xFF232B2C);

  static const Color textOnDark = Color(0xFFEAF0F0);
  static const Color textMutedOnDark = Color(0xFF98A2A3);

  // Spacing (8pt grid with a few extras)
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;

  // Radius
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r32 = 32;
  static const double r36 = 36;

  // Icon sizes
  static const double icon16 = 16;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon28 = 28;
  static const double icon32 = 32;

  // Motion
  static const Duration durFast = Duration(milliseconds: 150);
  static const Duration durNormal = Duration(milliseconds: 250);
  static const Duration durSlow = Duration(milliseconds: 350);

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  // Component metrics
  static const double appBarHeight = 56;
  static const double buttonHeight = 48;
  static const double fieldHeight = 52;

  // Gradient overlay (hero/schedule header)
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF1C4F2E), Colors.transparent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Optional: glow used for FAB / active elements in dark theme.
  static const Color glow = Color(0x803BFF7A); // 50% alpha
}
