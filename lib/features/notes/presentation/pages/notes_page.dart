import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';

/// NotesPage - Placeholder pro Notes feature
///
/// Otevírá se jako Modal Bottom Sheet při swipe nahoru na MainPage.
/// Zatím jen testovací UI pro ověření swipe gesta.
class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.appColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.appColors.base3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: theme.appColors.cyan,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.fg,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: theme.appColors.base5,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Zavřít',
                ),
              ],
            ),
          ),

          // Content (placeholder)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.appColors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Swipe funguje!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.appColors.fg,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notes feature bude implementována později.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.appColors.base5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
