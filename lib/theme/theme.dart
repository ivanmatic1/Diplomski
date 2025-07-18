import 'package:flutter/material.dart';

final Color primaryBlue = const Color(0xFF3B82F6);

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),
  cardColor: const Color(0xFFF3F4F6),
  colorScheme: ColorScheme.light(
    primary: primaryBlue,
    onPrimary: Colors.white,
    surface: const Color(0xFFF3F4F6),
    onSurface: const Color(0xFF111827),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF111827)),
    bodyMedium: TextStyle(color: Color(0xFF6B7280)),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1F2937),
  cardColor: const Color(0xFF374151),
  colorScheme: ColorScheme.dark(
    primary: primaryBlue,
    onPrimary: Colors.black,
    surface: const Color(0xFF374151),
    onSurface: const Color(0xFFF9FAFB),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFF9FAFB)),
    bodyMedium: TextStyle(color: Color(0xFF9CA3AF)),
  ),
);
