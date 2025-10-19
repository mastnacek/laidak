import 'package:flutter/material.dart';

/// Renault Style Light Theme
/// Converted from Kitty theme
class RenaultStyleLightTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF3a3a3a);
  static const Color bgAlt = Color(0xFF3a3a3a);
  static const Color base0 = Color(0xFF3a3a3a);
  static const Color base1 = Color(0xFF3a3a3a);
  static const Color base2 = Color(0xFF958553);
  static const Color base3 = Color(0xFF958553);
  static const Color base4 = Color(0xFF323232);
  static const Color base5 = Color(0xFFc8c8c8);
  static const Color base6 = Color(0xFFe9cb7b);
  static const Color base7 = Color(0xFFe9cb7b);
  static const Color base8 = Color(0xFFe9cb7b);

  // Foreground barvy
  static const Color fg = Color(0xFFffffce);
  static const Color fgAlt = Color(0xFFe9cb7b);

  // Sémantické barvy
  static const Color grey = Color(0xFF958553);
  static const Color red = Color(0xFFda4839);
  static const Color orange = Color(0xFFff7b6a);
  static const Color green = Color(0xFF509f50);
  static const Color teal = Color(0xFF83d082);
  static const Color yellow = Color(0xFFffd249);
  static const Color blue = Color(0xFF8ccafa);
  static const Color darkBlue = Color(0xFF9fcef0);
  static const Color magenta = Color(0xFFcfcfff);
  static const Color violet = Color(0xFFffffff);
  static const Color cyan = Color(0xFF87c1f1);
  static const Color darkCyan = Color(0xFFa4d4f8);

  /// Vytvořit tmavý ThemeData podle Renault Style Light
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
