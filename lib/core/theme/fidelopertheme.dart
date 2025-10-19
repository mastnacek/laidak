import 'package:flutter/material.dart';

/// Fideloper Theme
/// Converted from Kitty theme
class FideloperTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF282f32);
  static const Color bgAlt = Color(0xFF282f32);
  static const Color base0 = Color(0xFF282f32);
  static const Color base1 = Color(0xFF282f32);
  static const Color base2 = Color(0xFFeeb7ab);
  static const Color base3 = Color(0xFFeeb7ab);
  static const Color base4 = Color(0xFF092027);
  static const Color base5 = Color(0xFF092027);
  static const Color base6 = Color(0xFFdad9df);
  static const Color base7 = Color(0xFFdad9df);
  static const Color base8 = Color(0xFFdad9df);

  // Foreground barvy
  static const Color fg = Color(0xFF3c3b3d);
  static const Color fgAlt = Color(0xFFdad9df);

  // Sémantické barvy
  static const Color grey = Color(0xFFeeb7ab);
  static const Color red = Color(0xFFca1d2c);
  static const Color orange = Color(0xFFd35f5a);
  static const Color green = Color(0xFFedb7ab);
  static const Color teal = Color(0xFFd35f5a);
  static const Color yellow = Color(0xFFb7aa9a);
  static const Color blue = Color(0xFF4cc7ff);
  static const Color darkBlue = Color(0xFF7c84c4);
  static const Color magenta = Color(0xFFc0226e);
  static const Color violet = Color(0xFF5b5db2);
  static const Color cyan = Color(0xFF3fbeaf);
  static const Color darkCyan = Color(0xFF81908f);

  /// Vytvořit tmavý ThemeData podle Fideloper
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
