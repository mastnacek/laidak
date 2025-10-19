import 'package:flutter/material.dart';
import '../../../../../core/theme/theme_colors.dart';
import '../../../domain/entities/todo.dart';
import '../../../../pomodoro/presentation/pages/pomodoro_page.dart';

/// Dialog pro rychlé spuštění Pomodoro pro úkol
///
/// Features:
/// - Rychlé volby (1, 5, 15, 25, 30, 45, 60 min)
/// - Vlastní zadání (TextField)
/// - Validace (1-180 min)
/// - Automatické přepnutí na PomodoroPage
class PomodoroQuickStartDialog {
  /// Zobrazit Quick Start dialog pro Pomodoro
  static Future<void> show(
    BuildContext context, {
    required Todo todo,
  }) async {
    final theme = Theme.of(context);

    // Zavřít klávesnici
    FocusScope.of(context).unfocus();

    int? selectedMinutes; // null = vlastní hodnota
    final customController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: theme.appColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🍅 SPUSTIT POMODORO',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                // Úkol preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.appColors.bgAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.appColors.base3),
                  ),
                  child: Text(
                    '📋 ${todo.task}',
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Výběr délky
                Text(
                  'Délka Pomodoro:',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Rychlé volby (tlačítka)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 5, 15, 25, 30, 45, 60].map((minutes) {
                    final isSelected = selectedMinutes == minutes;
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedMinutes = minutes;
                          customController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.orange.withValues(alpha: 0.2)
                            : null,
                        side: BorderSide(
                          color: isSelected ? Colors.orange : theme.appColors.base5,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: isSelected ? Colors.orange : theme.appColors.fg,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Vlastní zadání (TextField)
                Text(
                  'Nebo zadej vlastní:',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: theme.appColors.fg, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Zadej minuty (1-180)',
                    hintStyle: TextStyle(color: theme.appColors.base5),
                    suffixText: 'min',
                    suffixStyle: TextStyle(color: theme.appColors.base5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    // Pokud user píše, zrušit vybranou rychlou volbu
                    if (value.isNotEmpty) {
                      setState(() {
                        selectedMinutes = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Zrušit',
                        style: TextStyle(color: theme.appColors.base5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Určit finální počet minut
                        int? finalMinutes;
                        if (selectedMinutes != null) {
                          finalMinutes = selectedMinutes;
                        } else if (customController.text.isNotEmpty) {
                          finalMinutes = int.tryParse(customController.text);
                        }

                        // Validace
                        if (finalMinutes == null || finalMinutes < 1 || finalMinutes > 180) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('⚠️ Zadej platný počet minut (1-180)'),
                              backgroundColor: theme.appColors.yellow,
                            ),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop(finalMinutes);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('START'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: theme.appColors.bg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pokud user klikl START, přejít na Pomodoro Page (s vlastním AppBar + auto-start)
    if (result != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PomodoroPage(
            showAppBar: true,
            taskId: todo.id,
            duration: Duration(minutes: result),
          ),
        ),
      );
    }
  }
}
