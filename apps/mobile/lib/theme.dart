import 'package:flutter/material.dart';

abstract final class MedicalBoxColors {
  static const ivory = Color(0xFFF8F3E9);
  static const paper = Color(0xFFFFFCF7);
  static const sky = Color(0xFFB9DDEA);
  static const skyDeep = Color(0xFF77B6D2);
  static const orange = Color(0xFFF15A38);
  static const ink = Color(0xFF1C2A31);
  static const muted = Color(0xFF6A757A);
  static const line = Color(0xFFE2DBCF);
}

ThemeData buildMedicalBoxTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: MedicalBoxColors.orange,
        brightness: Brightness.light,
        surface: MedicalBoxColors.paper,
      ).copyWith(
        primary: MedicalBoxColors.orange,
        secondary: MedicalBoxColors.skyDeep,
        surface: MedicalBoxColors.paper,
        onSurface: MedicalBoxColors.ink,
        outline: MedicalBoxColors.line,
      );
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MedicalBoxColors.ivory,
    useMaterial3: true,
    fontFamilyFallback: const [
      'Pretendard',
      'Apple SD Gothic Neo',
      'Noto Sans KR',
    ],
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        color: MedicalBoxColors.ink,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: MedicalBoxColors.ink,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: MedicalBoxColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    ),
    cardTheme: CardThemeData(
      color: MedicalBoxColors.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: MedicalBoxColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MedicalBoxColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MedicalBoxColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MedicalBoxColors.skyDeep, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
