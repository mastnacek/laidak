import 'package:flutter/material.dart';

/// Utility funkce pro práci s barvami
class ColorUtils {
  /// Konverze z hex stringu na Color
  ///
  /// Podporuje formáty:
  /// - '#FF5555' (RGB)
  /// - '#FFFF5555' (ARGB)
  /// - 'FF5555' (bez #)
  static Color hexToColor(String hexString) {
    // Odstranit '#' pokud existuje
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Konverze z Color na hex string
  ///
  /// Vrací formát: '#RRGGBB'
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Validace hex stringu
  ///
  /// Vrací true pokud je hex string validní
  static bool isValidHex(String hexString) {
    final cleanHex = hexString.replaceFirst('#', '');
    return RegExp(r'^[0-9A-Fa-f]{6}$|^[0-9A-Fa-f]{8}$').hasMatch(cleanHex);
  }
}
