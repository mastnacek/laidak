import '../../../todo_list/domain/entities/todo.dart';
import '../../../../models/note.dart';
import '../entities/export_config.dart';

/// Repository interface pro Markdown Export
///
/// Zodpovědnosti:
/// - Export jednotlivých TODO/Note do markdown souborů
/// - Full export všech úkolů a poznámek
/// - Validace konfigurace před exportem
abstract class MarkdownExportRepository {
  /// Exportovat jeden TODO úkol do markdown souboru
  ///
  /// Throws [ExportException] pokud config není validní nebo selže zápis
  Future<void> exportTodo(Todo todo, ExportConfig config);

  /// Exportovat jednu Note poznámku do markdown souboru
  ///
  /// Throws [ExportException] pokud config není validní nebo selže zápis
  Future<void> exportNote(Note note, ExportConfig config);

  /// Exportovat všechny TODO + Notes (full export)
  ///
  /// Clean re-export:
  /// 1. Smaže existující tasks/ a notes/ složky
  /// 2. Exportuje všechny TODOs (pokud exportTodos = true)
  /// 3. Exportuje všechny Notes (pokud exportNotes = true)
  ///
  /// Throws [ExportException] pokud config není validní nebo selže zápis
  Future<void> exportAll(ExportConfig config);
}

/// Custom exception pro export errors
class ExportException implements Exception {
  final String message;

  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}
