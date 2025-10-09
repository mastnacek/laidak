import 'package:flutter/material.dart';

/// Blade Runner 2049 theme
/// Inspirováno sci-fi atmosférou filmu
class BladeRunnerTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF0a0e14);
  static const Color bgAlt = Color(0xFF151a21);
  static const Color base0 = Color(0xFF050810);
  static const Color base1 = Color(0xFF0a0e14);
  static const Color base2 = Color(0xFF151a21);
  static const Color base3 = Color(0xFF1f2430);
  static const Color base4 = Color(0xFF2d3540);
  static const Color base5 = Color(0xFF6c7a89);
  static const Color base6 = Color(0xFF8a99a6);
  static const Color base7 = Color(0xFFa8b5c2);
  static const Color base8 = Color(0xFFd9d7ce);

  // Foreground barvy
  static const Color fg = Color(0xFFcccac2);
  static const Color fgAlt = Color(0xFF8a99a6);

  // Sémantické barvy
  static const Color grey = Color(0xFF3e4b59);
  static const Color red = Color(0xFFff3333);
  static const Color orange = Color(0xFFffb454);
  static const Color green = Color(0xFFc2d94c);
  static const Color teal = Color(0xFF59c2ff);
  static const Color yellow = Color(0xFFffcc66);
  static const Color blue = Color(0xFF59c2ff);
  static const Color darkBlue = Color(0xFF3d9dd9);
  static const Color magenta = Color(0xFFff77ff);
  static const Color violet = Color(0xFFc792ea);
  static const Color cyan = Color(0xFF5ccfe6);
  static const Color darkCyan = Color(0xFF4db3cc);

  /// Vytvořit tmavý ThemeData podle Blade Runner
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: cyan,
        secondary: magenta,
        surface: bgAlt,
        surfaceContainerHighest: base3,
        error: red,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: fg,
        onError: bg,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgAlt,
        foregroundColor: fg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: cyan,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),

      // Text
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: fg),
        bodyMedium: TextStyle(color: fg),
        titleMedium: TextStyle(color: fg, fontWeight: FontWeight.bold),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base2,
        hintStyle: TextStyle(color: base5),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: base4),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: base4, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cyan, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Checkboxes
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return green;
          }
          return base4;
        }),
        checkColor: WidgetStateProperty.all(bg),
      ),

      // Icons
      iconTheme: IconThemeData(color: fg),

      // Divider
      dividerTheme: DividerThemeData(
        color: base3,
        thickness: 1,
      ),

      // Card
      cardTheme: CardThemeData(
        color: bgAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: base3, width: 1),
        ),
      ),
    );
  }
}
