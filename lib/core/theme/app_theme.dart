import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.teal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppTokens.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppTokens.navy,
        foregroundColor: AppTokens.white,
      ),
      cardTheme: CardThemeData(
        color: AppTokens.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTokens.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTokens.border),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppTokens.navy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppTokens.navy,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: AppTokens.secondaryText),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.teal,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101820),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: AppTokens.navy,
        foregroundColor: AppTokens.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF182534),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A3B4D)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2D3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3B4D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3B4D)),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: AppTokens.white,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppTokens.white,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: Color(0xFFD9E2EC)),
      ),
    );
  }
}
