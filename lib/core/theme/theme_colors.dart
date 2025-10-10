import 'package:flutter/material.dart';

/// Extension na ThemeData pro snadný přístup k barvám aktuálního tématu
/// Používá se jako: Theme.of(context).appColors.cyan
extension ThemeColors on ThemeData {
  AppColors get appColors {
    // Načíst barvy z colorScheme
    final scheme = colorScheme;

    // Vrátit AppColors objekt s barvami z aktuálního tématu
    return AppColors(
      bg: scheme.surface,
      bgAlt: scaffoldBackgroundColor,
      base0: scaffoldBackgroundColor,
      base1: scaffoldBackgroundColor,
      base2: scheme.surfaceContainerHighest,
      base3: scheme.surfaceContainerHighest,
      base4: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      base5: scheme.onSurface.withValues(alpha: 0.5),
      base6: scheme.onSurface.withValues(alpha: 0.7),
      base7: scheme.onSurface.withValues(alpha: 0.8),
      base8: scheme.onSurface,
      fg: scheme.onSurface,
      fgAlt: scheme.onSurface.withValues(alpha: 0.8),
      grey: scheme.surfaceContainerHighest,
      red: const Color(0xFFff6c6b),
      orange: const Color(0xFFda8548),
      green: const Color(0xFF98be65),
      teal: const Color(0xFF4db5bd),
      yellow: const Color(0xFFecbe7b),
      blue: const Color(0xFF51afef),
      darkBlue: const Color(0xFF2257a0),
      magenta: const Color(0xFFc678dd),
      violet: const Color(0xFFa9a1e1),
      cyan: scheme.primary,
      darkCyan: const Color(0xFF5699af),
    );
  }
}

/// Třída obsahující všechny barvy tématu
class AppColors {
  final Color bg;
  final Color bgAlt;
  final Color base0;
  final Color base1;
  final Color base2;
  final Color base3;
  final Color base4;
  final Color base5;
  final Color base6;
  final Color base7;
  final Color base8;
  final Color fg;
  final Color fgAlt;
  final Color grey;
  final Color red;
  final Color orange;
  final Color green;
  final Color teal;
  final Color yellow;
  final Color blue;
  final Color darkBlue;
  final Color magenta;
  final Color violet;
  final Color cyan;
  final Color darkCyan;

  const AppColors({
    required this.bg,
    required this.bgAlt,
    required this.base0,
    required this.base1,
    required this.base2,
    required this.base3,
    required this.base4,
    required this.base5,
    required this.base6,
    required this.base7,
    required this.base8,
    required this.fg,
    required this.fgAlt,
    required this.grey,
    required this.red,
    required this.orange,
    required this.green,
    required this.teal,
    required this.yellow,
    required this.blue,
    required this.darkBlue,
    required this.magenta,
    required this.violet,
    required this.cyan,
    required this.darkCyan,
  });
}
