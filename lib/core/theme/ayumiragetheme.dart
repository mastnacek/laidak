import 'package:flutter/material.dart';

/// ayu mirage Theme
/// Converted from Kitty theme
class AyumirageTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF212733);
  static const Color bgAlt = Color(0xFF212733);
  static const Color base0 = Color(0xFF212733);
  static const Color base1 = Color(0xFF212733);
  static const Color base2 = Color(0xFF343f4c);
  static const Color base3 = Color(0xFF343f4c);
  static const Color base4 = Color(0xFF686868);
  static const Color base5 = Color(0xFFd0d0d0);
  static const Color base6 = Color(0xFFd9d7ce);
  static const Color base7 = Color(0xFFd9d7ce);
  static const Color base8 = Color(0xFFd9d7ce);

  // Foreground barvy
  static const Color fg = Color(0xFFd9d7ce);
  static const Color fgAlt = Color(0xFFd9d7ce);

  // Sémantické barvy
  static const Color grey = Color(0xFF343f4c);
  static const Color red = Color(0xFFed8274);
  static const Color orange = Color(0xFFf28779);
  static const Color green = Color(0xFFa6cc70);
  static const Color teal = Color(0xFFbae67e);
  static const Color yellow = Color(0xFFfad07b);
  static const Color blue = Color(0xFF6dcbfa);
  static const Color darkBlue = Color(0xFF73d0ff);
  static const Color magenta = Color(0xFFcfbafa);
  static const Color violet = Color(0xFFd4bfff);
  static const Color cyan = Color(0xFF90e1c6);
  static const Color darkCyan = Color(0xFF95e6cb);

  /// Vytvořit tmavý ThemeData podle ayu mirage
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: blue,
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
          borderSide: BorderSide(color: blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
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
