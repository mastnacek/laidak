import 'package:flutter/material.dart';

/// OneDark Theme
/// Converted from Kitty theme
class OneDarkTheme {
  // Barvy pozadí
  static const Color bg = Color(0xFF282c34);
  static const Color bgAlt = Color(0xFF282c34);
  static const Color base0 = Color(0xFF282c34);
  static const Color base1 = Color(0xFF282c34);
  static const Color base2 = Color(0xFF979eab);
  static const Color base3 = Color(0xFF979eab);
  static const Color base4 = Color(0xFF393e48);
  static const Color base5 = Color(0xFFe4f8ff);
  static const Color base6 = Color(0xFF979eab);
  static const Color base7 = Color(0xFF979eab);
  static const Color base8 = Color(0xFF979eab);

  // Foreground barvy
  static const Color fg = Color(0xFFffffff);
  static const Color fgAlt = Color(0xFF979eab);

  // Sémantické barvy
  static const Color grey = Color(0xFF979eab);
  static const Color red = Color(0xFFe06c75);
  static const Color orange = Color(0xFFd19a66);
  static const Color green = Color(0xFF98c379);
  static const Color teal = Color(0xFF56b6c2);
  static const Color yellow = Color(0xFFe5c07b);
  static const Color blue = Color(0xFF61afef);
  static const Color darkBlue = Color(0xFF61afef);
  static const Color magenta = Color(0xFFbe5046);
  static const Color violet = Color(0xFFbe5046);
  static const Color cyan = Color(0xFF56b6c2);
  static const Color darkCyan = Color(0xFF56b6c2);

  /// Vytvořit tmavý ThemeData podle OneDark
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
