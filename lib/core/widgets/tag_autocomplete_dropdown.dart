import 'package:flutter/material.dart';

/// Dropdown pro tag autocomplete (zobrazí se pod input fieldem)
///
/// Funkce:
/// - Zobrazí TOP 5 matching tagů z databáze
/// - Klik na tag = callback s vybraným tagem
/// - Scroll pro více tagů
class TagAutocompleteDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<String> onTagSelected;
  final VoidCallback onDismiss;

  const TagAutocompleteDropdown({
    super.key,
    required this.suggestions,
    required this.onTagSelected,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          maxHeight: 200,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final tag = suggestions[index];
            final displayName = tag['display_name'] as String;
            final usageCount = tag['usage_count'] as int;

            return InkWell(
              onTap: () => onTagSelected(displayName),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.label,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '($usageCount)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
