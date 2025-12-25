 import 'package:flutter/material.dart';

// ================= COLORS =================
const Color primaryColor   = Color(0xFF8A5BE0);
const Color secondaryColor = Color(0xFF38C172);
const Color tertiaryColor  = Color(0xFFF65B7B);
const Color backgroundColor = Color(0xFF1C1C23);
const Color cardColor       = Color(0xFF2E2E39);
const Color errorColor      = Color(0xFFCF6679);

// ================= THEME =================
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,

  scaffoldBackgroundColor: backgroundColor,

  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    tertiary: tertiaryColor,
    surface: cardColor,
    error: errorColor,
  ),

  // ================= APPBAR =================
  appBarTheme: const AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),

  // ================= CARD THEME (FIXED) =================
  cardTheme: CardThemeData(
    color: cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  // ================= DIALOG THEME (FIXED) =================
  dialogTheme: DialogThemeData(
    backgroundColor: cardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    contentTextStyle: const TextStyle(
      color: Colors.white70,
      fontSize: 16,
    ),
  ),

  // ================= INPUT =================
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);
