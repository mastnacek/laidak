import 'package:flutter/material.dart';

/// TodoTagChip - Chip pro zobrazení tagu
///
/// Jednoduchý reusable widget pro zobrazení tagů (priorita, datum, akce, vlastní tagy).
class TodoTagChip extends StatelessWidget {
  final String text;
  final Color color;

  const TodoTagChip({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
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
