import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/copyable_text.dart';
import '../../../ai_brief/domain/entities/brief_section.dart';
import '../../domain/entities/todo.dart';
import 'todo_card.dart';

/// BriefSectionWidget - Zobrazí jednu AI Brief sekci
///
/// Struktura:
/// - AI Commentary Header (barevný box s komentářem AI)
/// - Real TodoCards (použije existující TodoCard widget)
///
/// Section typy:
/// - focus_now: 🎯 FOCUS NOW (orange)
/// - key_insights: 📊 KEY INSIGHTS (blue)
/// - motivation: 💪 MOTIVATION (green)
class BriefSectionWidget extends StatelessWidget {
  final BriefSection section;
  final List<Todo> todos;
  final int? expandedTodoId;

  const BriefSectionWidget({
    required this.section,
    required this.todos,
    this.expandedTodoId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Commentary Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _getSectionColor(theme, section.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSectionColor(theme, section.type).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title s copy buttonem
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getSectionColor(theme, section.type),
                      ),
                    ),
                  ),
                  CopyButton(
                    textToCopy: '${section.title}\n\n${section.commentary}',
                    tooltip: 'Kopírovat AI komentář',
                    iconSize: 18,
                    iconColor: _getSectionColor(theme, section.type),
                    successMessage: '📋 AI komentář zkopírován',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // AI Commentary s Markdown renderingem
              MarkdownBody(
                data: section.commentary,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  // Základní text styling
                  p: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  // Bold text (**text**)
                  strong: TextStyle(
                    color: theme.appColors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  // Italic text (*text*)
                  em: TextStyle(
                    color: theme.appColors.cyan,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  // Heading 1 (# text)
                  h1: TextStyle(
                    color: _getSectionColor(theme, section.type),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  // Heading 2 (## text)
                  h2: TextStyle(
                    color: _getSectionColor(theme, section.type),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  // Lists (bullet points)
                  listBullet: TextStyle(
                    color: _getSectionColor(theme, section.type),
                    fontSize: 14,
                  ),
                  // Code inline (`code`)
                  code: TextStyle(
                    color: theme.appColors.orange,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    backgroundColor: theme.appColors.base1,
                  ),
                  // Čísla v ordered listech
                  listIndent: 16,
                ),
              ),
            ],
          ),
        ),

        // Real TodoCards (user může hned pracovat!)
        if (todos.isNotEmpty)
          ...todos.map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodoCard(
                  key: ValueKey('todo_${todo.id}'),
                  todo: todo,
                  isExpanded: expandedTodoId == todo.id,
                ),
              )),

        // Spacing mezi sekcemi
        const SizedBox(height: 16),
      ],
    );
  }

  /// Získat barvu podle section type
  Color _getSectionColor(ThemeData theme, String type) {
    switch (type) {
      case 'focus_now':
        return theme.appColors.orange;
      case 'key_insights':
        return theme.appColors.blue;
      case 'motivation':
        return theme.appColors.green;
      default:
        return theme.appColors.base5;
    }
  }
}
