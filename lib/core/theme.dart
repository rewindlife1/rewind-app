import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// REWIND brand palette — soft light theme with signature lime.
class RC {
  static const lime = Color(0xFFCEFF00);
  static const limeSoft = Color(0xFFEFFFB3);
  static const ink = Color(0xFF0E0F0C);
  static const bg = Color(0xFFF3F4EF);
  static const card = Colors.white;
  static const muted = Color(0xFF6B6F66);
  static const line = Color(0xFFE4E6DF);
  static const sage = Color(0xFFDDE5D3);
  static const danger = Color(0xFFD64545);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: RC.lime,
      brightness: Brightness.light,
      primary: RC.ink,
      onPrimary: Colors.white,
      secondary: RC.lime,
      onSecondary: RC.ink,
      surface: RC.bg,
      error: RC.danger,
    ),
    scaffoldBackgroundColor: RC.bg,
  );

  final text = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: RC.ink, displayColor: RC.ink);

  final radius = BorderRadius.circular(16);

  return base.copyWith(
    textTheme: text,
    dividerColor: RC.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: RC.bg,
      foregroundColor: RC.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: radius, borderSide: const BorderSide(color: RC.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: const BorderSide(color: RC.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: RC.ink, width: 1.4)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RC.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RC.ink,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        side: const BorderSide(color: RC.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: RC.ink,
    ),
  );
}
