import 'package:flutter/material.dart';

abstract final class MedicalBoxColors {
  static const canvas = Color(0xFFF4F4F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFFAFAF7);
  static const surfaceContainer = Color(0xFFEEEEEA);
  static const ink = Color(0xFF17191C);
  static const muted = Color(0xFF62676C);
  static const faint = Color(0xFF8A8F93);
  static const rail = Color(0xFFD6D7D2);
  static const railStrong = Color(0xFFA9ACA8);
  static const accent = Color(0xFFDF2C27);
  static const accentPressed = Color(0xFFB91F1B);
  static const accentSoft = Color(0xFFFFF0EE);
  static const official = Color(0xFF2F6B52);
  static const officialSoft = Color(0xFFEDF6F1);
  static const warning = Color(0xFFA84416);
  static const warningSoft = Color(0xFFFFF2E9);
  static const focus = Color(0xFF005FCC);
  static const disabled = Color(0xFFC6C8C5);

  // Compatibility aliases for screens that are being migrated incrementally.
  static const ivory = canvas;
  static const paper = surface;
  static const sky = surfaceContainer;
  static const skyDeep = official;
  static const orange = accent;
  static const line = rail;
}

abstract final class MedicalBoxSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x7 = 28.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const screen = 20.0;
  static const touchTarget = 48.0;
}

abstract final class MedicalBoxRadius {
  static const marker = 6.0;
  static const control = 8.0;
  static const group = 10.0;
  static const cabinet = 16.0;
}

ThemeData buildMedicalBoxTheme() {
  const colorScheme = ColorScheme.light(
    primary: MedicalBoxColors.accent,
    onPrimary: Colors.white,
    secondary: MedicalBoxColors.ink,
    onSecondary: Colors.white,
    tertiary: MedicalBoxColors.official,
    onTertiary: Colors.white,
    error: MedicalBoxColors.accent,
    onError: Colors.white,
    surface: MedicalBoxColors.surface,
    onSurface: MedicalBoxColors.ink,
    outline: MedicalBoxColors.railStrong,
    outlineVariant: MedicalBoxColors.rail,
  );

  const baseTextStyle = TextStyle(
    color: MedicalBoxColors.ink,
    fontFamily: 'Noto Sans KR',
    fontFamilyFallback: [
      'Apple SD Gothic Neo',
      'Pretendard',
      'Roboto',
      'sans-serif',
    ],
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MedicalBoxColors.canvas,
    useMaterial3: true,
    fontFamily: 'Noto Sans KR',
    fontFamilyFallback: const [
      'Apple SD Gothic Neo',
      'Pretendard',
      'Roboto',
      'sans-serif',
    ],
    textTheme: TextTheme(
      displaySmall: baseTextStyle.copyWith(
        fontSize: 30,
        height: 38 / 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: baseTextStyle.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseTextStyle.copyWith(
        fontSize: 19,
        height: 26 / 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: baseTextStyle.copyWith(
        fontSize: 19,
        height: 26 / 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextStyle.copyWith(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      bodyLarge: baseTextStyle.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: baseTextStyle.copyWith(fontSize: 14, height: 20 / 14),
      bodySmall: baseTextStyle.copyWith(
        color: MedicalBoxColors.muted,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: baseTextStyle.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextStyle.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextStyle.copyWith(
        color: MedicalBoxColors.muted,
        fontSize: 12,
        height: 17 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MedicalBoxColors.canvas,
      foregroundColor: MedicalBoxColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 56,
      titleTextStyle: TextStyle(
        color: MedicalBoxColors.ink,
        fontFamily: 'Noto Sans KR',
        fontFamilyFallback: ['Apple SD Gothic Neo', 'Pretendard', 'Roboto'],
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: MedicalBoxColors.rail,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: MedicalBoxColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.group),
        side: const BorderSide(color: MedicalBoxColors.rail),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MedicalBoxColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        borderSide: const BorderSide(color: MedicalBoxColors.railStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        borderSide: const BorderSide(color: MedicalBoxColors.railStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        borderSide: const BorderSide(color: MedicalBoxColors.focus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        borderSide: const BorderSide(color: MedicalBoxColors.accent),
      ),
      labelStyle: const TextStyle(
        color: MedicalBoxColors.muted,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20),
        ),
        backgroundColor: const WidgetStatePropertyAll(MedicalBoxColors.accent),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: const WidgetStatePropertyAll(
          MedicalBoxColors.accentPressed,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Noto Sans KR',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: MedicalBoxColors.ink,
        side: const BorderSide(color: MedicalBoxColors.railStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Noto Sans KR',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: MedicalBoxColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Noto Sans KR',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MedicalBoxRadius.control),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: MedicalBoxColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MedicalBoxRadius.control),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 72,
      backgroundColor: MedicalBoxColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Noto Sans KR',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(size: 22)),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : MedicalBoxColors.faint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? MedicalBoxColors.accent
            : MedicalBoxColors.surfaceContainer,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: MedicalBoxColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MedicalBoxRadius.cabinet),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MedicalBoxColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
  );
}
