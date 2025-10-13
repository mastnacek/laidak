import '../entities/todo.dart';
import '../../../ai_brief/domain/entities/brief_section.dart';

/// Helper class kombinující BriefSection s real Todo objekty
///
/// Používá se v TodoListState pro zobrazení Brief view.
/// Obsahuje AI sekci + příslušné Todo objekty pro zobrazení v UI.
class BriefSectionWithTodos {
  /// AI Brief sekce (title, commentary, task IDs)
  final BriefSection section;

  /// Real Todo objekty pro tuto sekci
  final List<Todo> todos;

  const BriefSectionWithTodos({
    required this.section,
    required this.todos,
  });

  @override
  String toString() {
    return 'BriefSectionWithTodos(section: ${section.type}, todos: ${todos.length})';
  }
}
