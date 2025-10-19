import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/models/tag_suggestion.dart';

/// Chip button pro zobrazení AI tag suggestion
///
/// UX design:
/// - Existující tag s barvou: custom barva z tag_definitions + emoji + glow efekt
/// - Existující tag bez barvy: zelené pozadí (theme.appColors.green)
/// - Nový tag: žluté pozadí (theme.appColors.yellow) + prefix "+"
/// - Kliknutí: callback onTap()
class TagSuggestionChip extends StatelessWidget {
  final TagSuggestion suggestion;
  final VoidCallback onTap;

  const TagSuggestionChip({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Barva podle typu tagu
    // Pokud existující tag má custom barvu z tag_definitions, použij ji
    Color primaryColor;
    if (suggestion.isExisting && suggestion.color != null) {
      // Parse hex color z tag definition
      final hexColor = suggestion.color!.replaceFirst('#', '');
      primaryColor = Color(int.parse('FF$hexColor', radix: 16));
    } else if (suggestion.isExisting) {
      // Existující tag bez custom barvy
      primaryColor = theme.appColors.green;
    } else {
      // Nový tag
      primaryColor = theme.appColors.yellow;
    }

    final backgroundColor = primaryColor.withValues(alpha: 0.2);
    final textColor = primaryColor;
    final borderColor = primaryColor.withValues(alpha: 0.5);

    // Label: emoji + tag name (pokud existuje emoji), jinak jen tag name
    final tagLabel = suggestion.isExisting
        ? suggestion.tagName
        : '+ ${suggestion.tagName}';

    final hasEmoji = suggestion.emoji != null && suggestion.emoji!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          // Glow efekt pro existující tagy s custom barvou
          boxShadow: (suggestion.isExisting && suggestion.color != null)
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji (pokud existuje) nebo icon
            if (hasEmoji)
              Text(
                suggestion.emoji!,
                style: const TextStyle(fontSize: 14),
              )
            else
              Icon(
                suggestion.isExisting ? Icons.label : Icons.add,
                size: 14,
                color: textColor,
              ),
            const SizedBox(width: 4),
            // Tag name
            Text(
              tagLabel,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Confidence badge (pouze pokud < 0.8)
            if (suggestion.confidence < 0.8) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.appColors.base3.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(suggestion.confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: theme.appColors.base5,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
