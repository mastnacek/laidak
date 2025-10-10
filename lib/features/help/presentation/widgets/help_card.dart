import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/models/help_section.dart';

/// HelpCard - Reusable komponenta pro Help System (podle help.md UI specifikace)
///
/// Struktura:
/// - Header: Ikona + Titul
/// - Description: Popis funkce
/// - Examples: Collapsible ExpansionTile s příklady
/// - Demo button: Tlačítko "Vyzkoušet interaktivně" (pokud hasInteractiveDemo)
/// - Warning: Pokud vyžaduje API key
class HelpCard extends StatelessWidget {
  final HelpSection section;
  final VoidCallback? onTryDemo;

  const HelpCard({
    required this.section,
    this.onTryDemo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.appColors.bgAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.base3, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Ikona + Titul
            Row(
              children: [
                Icon(
                  section.icon,
                  color: theme.appColors.cyan,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: TextStyle(
                      color: theme.appColors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              section.description,
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Examples (collapsible)
            if (section.examples.isNotEmpty) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: theme.appColors.yellow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📖 Zobrazit příklady',
                        style: TextStyle(
                          color: theme.appColors.yellow,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  collapsedIconColor: theme.appColors.base5,
                  iconColor: theme.appColors.yellow,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.appColors.base2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: section.examples
                            .map(
                              (example) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  example,
                                  style: TextStyle(
                                    color: theme.appColors.fg,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Demo button (pokud je interaktivní demo)
            if (section.hasInteractiveDemo) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTryDemo,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text(
                    '🎮 VYZKOUŠET INTERAKTIVNĚ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.green,
                    foregroundColor: theme.appColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Warning pokud vyžaduje API key
            if (section.requiresApiKey)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.appColors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.appColors.yellow,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: theme.appColors.yellow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Vyžaduje OpenRouter API key v Nastavení',
                        style: TextStyle(
                          color: theme.appColors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
