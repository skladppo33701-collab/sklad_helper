import 'package:flutter/material.dart';

/// Single source of truth tokens.
/// Change tokens here -> app UI updates everywhere.
class AppTokens {
  // Brand
  static const Color seed = Color(0xFF006A6A); // change later if you want
  // Accent (neon lime)
  static const Color accent = Color(0xFFB7FF2A);

  // Dark palette
  static const Color bgDark = Color(0xFF0B0E0F);
  static const Color surfaceDark = Color(0xFF121718);
  static const Color surfaceDark2 = Color(0xFF171E1F);
  static const Color outlineDark = Color(0xFF232B2C);

  static const Color textOnDark = Color(0xFFEAF0F0);
  static const Color textMutedOnDark = Color(0xFF98A2A3);
  // Spacing (8pt grid with a few extras)
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
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

  // Icon sizes
  static const double icon16 = 16;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon28 = 28;

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
}
