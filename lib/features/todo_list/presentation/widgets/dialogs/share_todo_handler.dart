import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/theme_colors.dart';
import '../../../../../services/tag_parser.dart';
import '../../../domain/entities/todo.dart';

/// Handler pro sdílení TODO úkolu
///
/// Features:
/// - Markdown formát (# TODO, ## sekce, atd.)
/// - Kompletní obsah (základní info + subtasks + AI metadata)
/// - Kopírování do schránky
/// - Success/error notifikace
class ShareTodoHandler {
  /// Sdílet úkol do schránky (kompletní obsah včetně subtasks + AI metadata)
  static Future<void> share(
    BuildContext context, {
    required Todo todo,
  }) async {
    final theme = Theme.of(context);

    try {
      // Sestavit Markdown formátovaný text
      final buffer = StringBuffer();

      // Header
      buffer.writeln('# TODO: ${todo.task}');
      buffer.writeln();

      // Metadata
      buffer.writeln('## 📋 Základní info');
      buffer.writeln('- **ID**: ${todo.id}');
      buffer.writeln('- **Status**: ${todo.isCompleted ? "✅ Hotovo" : "⭕ Aktivní"}');
      if (todo.priority != null) {
        buffer.writeln('- **Priorita**: ${TagParser.getPriorityIcon(todo.priority)} ${todo.priority!.toUpperCase()}');
      }
      if (todo.dueDate != null) {
        buffer.writeln('- **Deadline**: 📅 ${TagParser.formatDate(todo.dueDate!)}');
      }
      if (todo.tags.isNotEmpty) {
        buffer.writeln('- **Tagy**: ${todo.tags.map((t) => '*$t*').join(', ')}');
      }
      buffer.writeln('- **Vytvořeno**: ${todo.createdAt.toLocal()}');
      buffer.writeln();

      // Subtasks
      if (todo.subtasks != null && todo.subtasks!.isNotEmpty) {
        buffer.writeln('## 📋 Podúkoly (${todo.subtasks!.where((s) => s.completed).length}/${todo.subtasks!.length})');
        for (final subtask in todo.subtasks!) {
          final checkbox = subtask.completed ? '✅' : '⬜';
          buffer.writeln('$checkbox ${subtask.subtaskNumber}. ${subtask.text}');
        }
        buffer.writeln();
      }

      // AI Doporučení
      if (todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty) {
        buffer.writeln('## 💡 AI Doporučení');
        buffer.writeln(todo.aiRecommendations);
        buffer.writeln();
      }

      // AI Analýza termínu
      if (todo.aiDeadlineAnalysis != null && todo.aiDeadlineAnalysis!.isNotEmpty) {
        buffer.writeln('## ⏰ AI Analýza termínu');
        buffer.writeln(todo.aiDeadlineAnalysis);
        buffer.writeln();
      }

      // Footer
      buffer.writeln('---');
      buffer.writeln('📱 Exportováno z TODO App');

      final shareText = buffer.toString();

      // Zkopírovat do schránky
      await Clipboard.setData(ClipboardData(text: shareText));

      // Zobrazit úspěšnou notifikaci
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Úkol zkopírován do schránky (Markdown formát)'),
            backgroundColor: theme.appColors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: theme.appColors.bg,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Error handling
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při kopírování: $e'),
            backgroundColor: theme.appColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
