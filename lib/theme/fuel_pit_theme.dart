import 'package:flutter/material.dart';

const fuelPitPrimary = Color(0xFF25B4E8); // azul da bomba
const fuelPitSecondary = Color(0xFF6BD735); // verde do pin
const fuelPitBackground = Color(0xFFFFF4DD); // creme de fundo
const fuelPitText = Color(0xFF1F3B4D); // texto "Fuel Pit"

// LIGHT THEME — Material 2
final fuelPitLightTheme = ThemeData(
  useMaterial3: false,
  primaryColor: fuelPitPrimary,
  scaffoldBackgroundColor: fuelPitBackground,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: fuelPitPrimary,
    onPrimary: Colors.white,
    secondary: fuelPitSecondary,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: fuelPitText,
    error: Color(0xFFB00020),
    onError: Colors.white,
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.zero,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: fuelPitBackground,
    foregroundColor: fuelPitText,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: fuelPitText,
    ),
  ),
);

// DARK THEME — Material 2
final fuelPitDarkTheme = ThemeData(
  useMaterial3: false,
  primaryColor: fuelPitPrimary,
  scaffoldBackgroundColor: const Color(0xFF111827),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: fuelPitPrimary,
    onPrimary: Colors.black,
    secondary: fuelPitSecondary,
    onSecondary: Colors.black,
    surface: Color(0xFF111827),
    onSurface: Colors.white,
    error: Color(0xFFCF6679),
    onError: Colors.black,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1F2937),
    surfaceTintColor: Colors.transparent,
    elevation: 1,
    margin: EdgeInsets.zero,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF111827),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: Colors.white,
    ),
  ),
);
