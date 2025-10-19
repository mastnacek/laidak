import 'package:flutter/material.dart';

/// Elemental Theme
/// Converted from Kitty theme
class ElementalTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF21211c);
  static const Color bgAlt = Color(0xFF21211c);
  static const Color base0 = Color(0xFF21211c);
  static const Color base1 = Color(0xFF21211c);
  static const Color base2 = Color(0xFF403729);
  static const Color base3 = Color(0xFF403729);
  static const Color base4 = Color(0xFF545444);
  static const Color base5 = Color(0xFFa8a888);
  static const Color base6 = Color(0xFF807973);
  static const Color base7 = Color(0xFF807973);
  static const Color base8 = Color(0xFF807973);

  // Foreground barvy
  static const Color fg = Color(0xFFe8dbd0);
  static const Color fgAlt = Color(0xFF807973);

  // Sémantické barvy
  static const Color grey = Color(0xFF403729);
  static const Color red = Color(0xFF97280f);
  static const Color orange = Color(0xFFdf502a);
  static const Color green = Color(0xFF479942);
  static const Color teal = Color(0xFF60e06f);
  static const Color yellow = Color(0xFF7f7110);
  static const Color blue = Color(0xFF61aaa7);
  static const Color darkBlue = Color(0xFF78d8d8);
  static const Color magenta = Color(0xFF7e4e2e);
  static const Color violet = Color(0xFFcd7c53);
  static const Color cyan = Color(0xFF51b77f);
  static const Color darkCyan = Color(0xFF58d598);

  /// Vytvořit tmavý ThemeData podle Elemental
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
