import '../../../todo_list/domain/entities/todo.dart';
// TODO: Uncomment when Notes entity is implemented
// import '../../../notes/domain/entities/note.dart';
import '../entities/export_format.dart';

/// Service pro konverzi TODO a Notes do markdown formátů
///
/// Podporované formáty:
/// - default_: náš custom syntax (*tag*, *a*, *#123*)
/// - obsidian: YAML frontmatter, #hashtags, [[backlinks]]
class MarkdownFormatterService {
  // ==================== TODO FORMATTING ====================

  /// Konvertuje TODO do markdown formátu
  String formatTodo(Todo todo, ExportFormat format) {
    if (format == ExportFormat.obsidian) {
      return _formatTodoObsidian(todo);
    }
    return _formatTodoDefault(todo);
  }

  /// Obsidian formát TODO s frontmatter
  String _formatTodoObsidian(Todo todo) {
    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('id: ${todo.id}');
    buffer.writeln('created: ${_formatIso8601(todo.createdAt)}');

    if (todo.dueDate != null) {
      buffer.writeln('due: ${_formatIso8601(todo.dueDate!)}');
    }

    if (todo.priority != null) {
      buffer.writeln('priority: ${todo.priority}');
    }

    if (todo.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in todo.tags) {
        buffer.writeln('  - $tag'); // YAML array
      }
    }

    buffer.writeln('completed: ${todo.isCompleted}');
    buffer.writeln('---');
    buffer.writeln();

    // Task checkbox (Obsidian syntax: - [ ] nebo - [x])
    buffer.write(todo.isCompleted ? '- [x] ' : '- [ ] ');

    // Task text (bez escape - Obsidian zvládá většinu znaků)
    buffer.writeln(todo.task);
    buffer.writeln();

    // Tags jako hashtags (Obsidian inline tags)
    if (todo.tags.isNotEmpty) {
      buffer.writeln(todo.tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }

    // Backlinks pro linked note IDs (konverze *#123* → [[Note-123]])
    final noteLinks = _extractNoteLinks(todo.task);
    if (noteLinks.isNotEmpty) {
      buffer.writeln('## Linked Notes');
      for (final noteId in noteLinks) {
        buffer.writeln('- [[Note-$noteId]]');
      }
    }

    return buffer.toString();
  }

  /// Výchozí formát TODO (náš custom syntax)
  String _formatTodoDefault(Todo todo) {
    final buffer = StringBuffer();

    // Checkbox
    buffer.write(todo.isCompleted ? '[x] ' : '[ ] ');

    // Task text (ponechat original)
    buffer.write(todo.task);

    // Priority tag
    if (todo.priority != null) {
      buffer.write(' *${todo.priority}*');
    }

    // Date tag
    if (todo.dueDate != null) {
      final dateStr = _formatDateTag(todo.dueDate!);
      buffer.write(' *$dateStr*');
    }

    // Custom tags
    for (final tag in todo.tags) {
      buffer.write(' *$tag*');
    }

    buffer.writeln();
    return buffer.toString();
  }

  // ==================== NOTE FORMATTING ====================
  // TODO: Uncomment when Notes entity is implemented

  /*
  /// Konvertuje Note do markdown formátu
  String formatNote(Note note, ExportFormat format) {
    if (format == ExportFormat.obsidian) {
      return _formatNoteObsidian(note);
    }
    return _formatNoteDefault(note);
  }

  /// Obsidian formát Note s frontmatter
  String _formatNoteObsidian(Note note) {
    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('id: ${note.id}');
    buffer.writeln('title: ${_escapeYaml(note.displayTitle)}');
    buffer.writeln('created: ${_formatIso8601(note.createdAt)}');

    if (note.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in note.tags) {
        buffer.writeln('  - $tag');
      }
    }

    buffer.writeln('---');
    buffer.writeln();

    // Note title jako H1
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();

    // Note content
    buffer.writeln(note.content);
    buffer.writeln();

    // Tags jako hashtags
    if (note.tags.isNotEmpty) {
      buffer.writeln(note.tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }

    // Backlinks (TODO IDs + Note IDs)
    final todoLinks = _extractTodoLinks(note.content);
    final noteLinks = _extractNoteLinks(note.content);

    if (todoLinks.isNotEmpty || noteLinks.isNotEmpty) {
      buffer.writeln('## Backlinks');

      for (final todoId in todoLinks) {
        buffer.writeln('- [[TODO-$todoId]]');
      }

      for (final noteId in noteLinks) {
        buffer.writeln('- [[Note-$noteId]]');
      }
    }

    return buffer.toString();
  }

  /// Výchozí formát Note (náš custom syntax)
  String _formatNoteDefault(Note note) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();

    // Content (ponechat original s našimi tagy)
    buffer.writeln(note.content);
    buffer.writeln();

    // Tags
    if (note.tags.isNotEmpty) {
      buffer.write('Tags: ');
      buffer.writeln(note.tags.map((t) => '*$t*').join(' '));
    }

    return buffer.toString();
  }
  */

  // ==================== HELPER METHODS ====================

  /// Extrahuje TODO link IDs z textu (*@123* → [123])
  List<int> _extractTodoLinks(String text) {
    final regex = RegExp(r'\*@(\d+)\*');
    return regex
        .allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .toList();
  }

  /// Extrahuje Note link IDs z textu (*#123* → [123])
  List<int> _extractNoteLinks(String text) {
    final regex = RegExp(r'\*#(\d+)\*');
    return regex
        .allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .toList();
  }

  /// Escape YAML string (pro frontmatter)
  /// Pokud obsahuje speciální znaky, zabal do uvozovek
  String _escapeYaml(String text) {
    if (text.contains(':') ||
        text.contains('#') ||
        text.contains('-') ||
        text.contains('[') ||
        text.contains(']')) {
      // Escape uvozovky uvnitř stringu
      return '"${text.replaceAll('"', '\\"')}"';
    }
    return text;
  }

  /// Formátuje DateTime do ISO 8601 (pro Obsidian frontmatter)
  String _formatIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Formátuje datum do našeho date tagu (DD.MM.YYYY HH:MM)
  String _formatDateTag(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
