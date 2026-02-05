import 'package:flutter/material.dart';
import 'app_tokens.dart';

class AppColorSchemes {
  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: AppTokens.seed,
    brightness: Brightness.light,
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: AppTokens.seed,
    brightness: Brightness.dark,
  );
}
