import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════
// Fuel Pit — Palette de cores (Tailwind-inspired)
// ══════════════════════════════════════════════════

// Primary: Sky Blue (energia, confiança, combustível)
const fuelPitPrimary = Color(0xFF0EA5E9); // sky-500
const fuelPitPrimaryDark = Color(0xFF0284C7); // sky-600
const fuelPitPrimaryLight = Color(0xFF38BDF8); // sky-400

// Secondary: Amber (energia, calor, destaque)
const fuelPitSecondary = Color(0xFFF59E0B); // amber-500
const fuelPitSecondaryDark = Color(0xFFD97706); // amber-600
const fuelPitSecondaryLight = Color(0xFFFBBF24); // amber-400

// Tertiary: Emerald (eco, sustentabilidade, sucesso)
const fuelPitTertiary = Color(0xFF10B981); // emerald-500

// Semantic
const fuelPitError = Color(0xFFEF4444); // red-500
const fuelPitSuccess = Color(0xFF10B981); // emerald-500
const fuelPitWarning = Color(0xFFF59E0B); // amber-500

// Text
const fuelPitTextPrimary = Color(0xFF0F172A); // slate-900
const fuelPitTextSecondary = Color(0xFF64748B); // slate-500
const fuelPitTextOnDark = Color(0xFFF1F5F9); // slate-100

// Backgrounds
const fuelPitBgLight = Color(0xFFF8FAFC); // slate-50
const fuelPitBgDark = Color(0xFF0F172A); // slate-900
const fuelPitSurfaceDark = Color(0xFF1E293B); // slate-800

// Splash
const Color splashBackgroundColor = Color(0xFF0F172A);
const Color splashLogoBlue = Color(0xFF38BDF8);

// ══════════════════════════════════════════════════
// Light Theme — Material 2
// ══════════════════════════════════════════════════

final fuelPitLightTheme = ThemeData(
  useMaterial3: false,
  primaryColor: fuelPitPrimary,
  scaffoldBackgroundColor: fuelPitBgLight,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: fuelPitPrimary,
    onPrimary: Colors.white,
    primaryContainer: fuelPitPrimaryLight,
    secondary: fuelPitSecondary,
    onSecondary: Colors.white,
    secondaryContainer: fuelPitSecondaryLight,
    tertiary: fuelPitTertiary,
    surface: Colors.white,
    onSurface: fuelPitTextPrimary,
    error: fuelPitError,
    onError: Colors.white,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.zero,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: fuelPitBgLight,
    foregroundColor: fuelPitTextPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: fuelPitTextPrimary,
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: fuelPitTextPrimary,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: fuelPitPrimary,
      foregroundColor: Colors.white,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: fuelPitPrimary,
      side: const BorderSide(color: fuelPitPrimary),
    ),
  ),
);

// ══════════════════════════════════════════════════
// Dark Theme — Material 2
// ══════════════════════════════════════════════════

final fuelPitDarkTheme = ThemeData(
  useMaterial3: false,
  primaryColor: fuelPitPrimary,
  scaffoldBackgroundColor: fuelPitBgDark,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: fuelPitPrimaryLight,
    onPrimary: fuelPitBgDark,
    primaryContainer: fuelPitPrimaryDark,
    secondary: fuelPitSecondaryLight,
    onSecondary: fuelPitBgDark,
    secondaryContainer: fuelPitSecondaryDark,
    tertiary: fuelPitTertiary,
    surface: fuelPitSurfaceDark,
    onSurface: fuelPitTextOnDark,
    error: Color(0xFFCF6679),
    onError: Colors.black,
  ),
  cardTheme: const CardThemeData(
    color: fuelPitSurfaceDark,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.zero,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: fuelPitBgDark,
    foregroundColor: fuelPitTextOnDark,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: fuelPitTextOnDark,
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: fuelPitSurfaceDark,
    contentTextStyle: TextStyle(color: fuelPitTextOnDark),
    behavior: SnackBarBehavior.floating,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: fuelPitPrimaryLight,
      foregroundColor: fuelPitBgDark,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: fuelPitPrimaryLight,
      side: const BorderSide(color: fuelPitPrimaryLight),
    ),
  ),
);
