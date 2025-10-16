import 'package:flutter/material.dart';

/// TodoTagChip - Chip pro zobrazení tagu
///
/// Reusable widget pro zobrazení tagů (priorita, datum, akce, vlastní tagy).
/// Podporuje optional glow efekt pro systémové tagy.
class TodoTagChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool glowEnabled;
  final double glowStrength;

  const TodoTagChip({
    super.key,
    required this.text,
    required this.color,
    this.glowEnabled = false,
    this.glowStrength = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
        boxShadow: glowEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4 * glowStrength),
                  blurRadius: 8 * glowStrength,
                  spreadRadius: 2 * glowStrength,
                ),
              ]
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
