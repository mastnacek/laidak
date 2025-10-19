import '../../domain/repositories/markdown_export_repository.dart';
import '../../domain/entities/export_config.dart';
import '../../domain/services/markdown_formatter_service.dart';
import '../../domain/services/file_writer_service.dart';
import '../../../todo_list/domain/repositories/todo_repository.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../models/note.dart';
import '../../../../core/utils/app_logger.dart';

/// Implementace MarkdownExportRepository
///
/// Dependencies:
/// - MarkdownFormatterService - konverze do markdown formátů
/// - FileWriterService - zápis souborů
/// - TodoRepository - načítání všech TODOs
/// - DatabaseHelper - načítání všech Notes
class MarkdownExportRepositoryImpl implements MarkdownExportRepository {
  final MarkdownFormatterService _formatter;
  final FileWriterService _fileWriter;
  final TodoRepository _todoRepository;
  final DatabaseHelper _db;

  MarkdownExportRepositoryImpl({
    required MarkdownFormatterService formatter,
    required FileWriterService fileWriter,
    required TodoRepository todoRepository,
    required DatabaseHelper db,
  })  : _formatter = formatter,
        _fileWriter = fileWriter,
        _todoRepository = todoRepository,
        _db = db;

  @override
  Future<void> exportTodo(Todo todo, ExportConfig config) async {
    // ✅ Fail Fast: validace konfigurace
    _validateConfig(config);

    // Skip pokud user zakázal TODO export
    if (!config.exportTodos) {
      AppLogger.debug('Export TODOs je zakázán, skip TODO ${todo.id}');
      return;
    }

    try {
      // Format todo do markdown
      final markdown = _formatter.formatTodo(todo, config.format);

      // Zapsat do souboru
      await _fileWriter.writeTodoFile(
        targetDirectory: config.targetDirectory!,
        todo: todo,
        markdownContent: markdown,
      );

      AppLogger.debug('✅ Exportován TODO ${todo.id} → ${config.targetDirectory}/tasks/');
    } catch (e) {
      throw ExportException('Failed to export TODO ${todo.id}: $e');
    }
  }

  @override
  Future<void> exportNote(Note note, ExportConfig config) async {
    // ✅ Fail Fast: validace konfigurace
    _validateConfig(config);

    // Skip pokud user zakázal Notes export
    if (!config.exportNotes) {
      AppLogger.debug('Export Notes je zakázán, skip Note ${note.id}');
      return;
    }

    try {
      // Format note do markdown
      final markdown = _formatter.formatNote(note, config.format);

      // Zapsat do souboru
      await _fileWriter.writeNoteFile(
        targetDirectory: config.targetDirectory!,
        note: note,
        markdownContent: markdown,
      );

      AppLogger.debug('✅ Exportována Note ${note.id} → ${config.targetDirectory}/notes/');
    } catch (e) {
      throw ExportException('Failed to export Note ${note.id}: $e');
    }
  }

  @override
  Future<void> exportAll(ExportConfig config) async {
    // ✅ Fail Fast: validace konfigurace
    _validateConfig(config);

    AppLogger.info('🚀 Začínám full export (format: ${config.format.name})');

    try {
      // Clean existující soubory (clean re-export)
      AppLogger.debug('🧹 Čistím existující export soubory...');
      await _fileWriter.clearExportedFiles(config.targetDirectory!);

      // Export všech TODOs
      if (config.exportTodos) {
        AppLogger.debug('📝 Exportuji TODOs...');
        final todos = await _todoRepository.getAllTodos();

        for (final todo in todos) {
          await exportTodo(todo, config);
        }

        AppLogger.info('✅ Exportováno ${todos.length} TODOs');
      } else {
        AppLogger.debug('⏭️ Export TODOs přeskočen (zakázán v configu)');
      }

      // Export všech Notes
      if (config.exportNotes) {
        AppLogger.debug('📝 Exportuji Notes...');
        final notesData = await _db.getAllNotes();
        final notes = notesData.map((data) => Note.fromMap(data)).toList();

        for (final note in notes) {
          await exportNote(note, config);
        }

        AppLogger.info('✅ Exportováno ${notes.length} Notes');
      } else {
        AppLogger.debug('⏭️ Export Notes přeskočen (zakázán v configu)');
      }

      AppLogger.info('🎉 Full export dokončen!');
    } catch (e) {
      throw ExportException('Failed to export all: $e');
    }
  }

  /// Validuje export konfiguraci
  ///
  /// Throws [ExportException] pokud není validní
  void _validateConfig(ExportConfig config) {
    if (!config.isConfigured) {
      throw ExportException(
        'Target directory není nastaven. Otevřete Settings a vyberte cílovou složku.',
      );
    }
  }
}
