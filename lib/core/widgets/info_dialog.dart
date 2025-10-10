import 'package:flutter/material.dart';
import '../theme/theme_colors.dart';

/// InfoDialog - Univerzální dialog pro zobrazení nápovědy k funkcím
///
/// Použití:
/// ```dart
/// onLongPress: () => showDialog(
///   context: context,
///   builder: (context) => InfoDialog(
///     title: 'Název funkce',
///     icon: Icons.info,
///     iconColor: Colors.blue,
///     description: 'Popis jak funkce funguje...',
///     examples: ['Příklad 1', 'Příklad 2'],
///   ),
/// ),
/// ```
class InfoDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String description;
  final List<String>? examples;
  final String? tip;

  const InfoDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.description,
    this.examples,
    this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: iconColor, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.appColors.base5),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: theme.appColors.base3, height: 24),

              // Description
              Text(
                description,
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              // Examples
              if (examples != null && examples!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.appColors.base2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.appColors.base3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb,
                              color: theme.appColors.yellow, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Příklady použití:',
                            style: TextStyle(
                              color: theme.appColors.yellow,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...examples!.map((example) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    color: theme.appColors.fg,
                                    fontSize: 13,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    example,
                                    style: TextStyle(
                                      color: theme.appColors.fg,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              // Tip
              if (tip != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.appColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.appColors.blue),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: theme.appColors.blue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip!,
                          style: TextStyle(
                            color: theme.appColors.fg,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Close button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: theme.appColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'ROZUMÍM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
