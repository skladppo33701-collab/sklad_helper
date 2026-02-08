import 'package:flutter/material.dart';

class AppColorSchemes {
  // --- INDUSTRIAL DARK PALETTE (Основная) ---
  static const dark = ColorScheme(
    brightness: Brightness.dark,
    // Основной акцент (Неоновый Синий - Технологичность)
    primary: Color(0xFF29B6F6),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF004B73),
    onPrimaryContainer: Color(0xFFCBE6FF),

    // Вторичный акцент (Индустриальный Желтый - Внимание/Сканирование)
    secondary: Color(0xFFFFB74D),
    onSecondary: Color(0xFF4A2800),
    secondaryContainer: Color(0xFF6D4000),
    onSecondaryContainer: Color(0xFFFFDCC1),

    // Ошибки (Сигнальный Красный)
    error: Color(0xFFFF5252),
    onError: Color(0xFF690005),

    // Фоны (Глубокий матовый)
    surface: Color(0xFF1A1C1E), // Чуть светлее фона для карточек
    onSurface: Color(0xFFE2E2E6),

    // Самый задний фон (Почти черный)
    surfaceTint: Color(0xFF29B6F6),
    outline: Color(0xFF8C9199),
    outlineVariant: Color(0xFF42474E),
  );

  // --- LIGHT PALETTE (Резервная, чистая) ---
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006495),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCBE6FF),
    onPrimaryContainer: Color(0xFF001E30),

    secondary: Color(0xFF8D4F00),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFDCC1),
    onSecondaryContainer: Color(0xFF2D1600),

    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),

    surface: Color(0xFFFCFCFF),
    onSurface: Color(0xFF1A1C1E),

    outline: Color(0xFF72777F),
    outlineVariant: Color(0xFFC2C7CF),
  );
}
