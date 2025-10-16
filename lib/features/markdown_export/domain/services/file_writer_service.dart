import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../../../../core/services/saf_file_writer.dart';
import '../../../todo_list/domain/entities/todo.dart';
// TODO: Uncomment when Notes entity is implemented
// import '../../../notes/domain/entities/note.dart';

/// Service pro zápis markdown souborů do file systemu
///
/// Zodpovědnosti:
/// - Zápis TODO a Note do .md souborů
/// - Vytvoření složek tasks/ a notes/
/// - Sanitizace názvů souborů
/// - Error handling
class FileWriterService {
  /// Zapíše TODO jako markdown soubor
  ///
  /// File path: {targetDirectory}/tasks/{sanitized_task_name}.md
  ///
  /// Podporuje Android SAF i desktop file systém
  ///
  /// Throws [FileWriterException] pokud selže zápis
  Future<void> writeTodoFile({
    required String targetDirectory,
    required Todo todo,
    required String markdownContent,
  }) async {
    try {
      // Sanitizovat název souboru z task textu
      final fileName = _sanitizeFileName(todo.task);
      final relativePath = 'tasks/$fileName.md';

      // Android SAF vs Desktop File API
      if (SafFileWriter.isSafUri(targetDirectory)) {
        // Android: použij SAF přes Platform Channel
        final contentBytes = Uint8List.fromList(utf8.encode(markdownContent));
        await SafFileWriter.writeFile(
          directoryUri: targetDirectory,
          relativePath: relativePath,
          content: contentBytes,
          mimeType: 'text/markdown',
        );
      } else {
        // Desktop: klasické dart:io File API
        final filePath = '$targetDirectory/$relativePath';
        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsString(markdownContent, encoding: utf8);
      }
    } catch (e) {
      throw FileWriterException('Failed to write TODO file: $e');
    }
  }

  // TODO: Uncomment when Notes entity is implemented
  /*
  /// Zapíše Note jako markdown soubor
  ///
  /// File path: {targetDirectory}/notes/Note-{id}.md
  ///
  /// Throws [FileWriterException] pokud selže zápis
  Future<void> writeNoteFile({
    required String targetDirectory,
    required Note note,
    required String markdownContent,
  }) async {
    try {
      // Název souboru: Note-{id}.md (konzistentní, bez sanitizace)
      final fileName = 'Note-${note.id}';
      final filePath = '$targetDirectory/notes/$fileName.md';

      // Vytvořit notes/ složku pokud neexistuje
      final file = File(filePath);
      await file.create(recursive: true);

      // Zapsat markdown content s UTF-8 encoding
      await file.writeAsString(markdownContent, encoding: utf8);
    } catch (e) {
      throw FileWriterException('Failed to write Note file: $e');
    }
  }
  */

  /// Vymaže všechny exportované soubory (pro clean re-export)
  ///
  /// Smaže tasks/ a notes/ složky včetně obsahu
  ///
  /// Podporuje Android SAF i desktop file systém
  Future<void> clearExportedFiles(String targetDirectory) async {
    try {
      // Android SAF vs Desktop File API
      if (SafFileWriter.isSafUri(targetDirectory)) {
        // Android: použij SAF přes Platform Channel
        await SafFileWriter.deleteDirectory(
          directoryUri: targetDirectory,
          relativePath: 'tasks',
        );
        await SafFileWriter.deleteDirectory(
          directoryUri: targetDirectory,
          relativePath: 'notes',
        );
      } else {
        // Desktop: klasické dart:io File API
        final tasksDir = Directory('$targetDirectory/tasks');
        final notesDir = Directory('$targetDirectory/notes');

        if (await tasksDir.exists()) {
          await tasksDir.delete(recursive: true);
        }

        if (await notesDir.exists()) {
          await notesDir.delete(recursive: true);
        }
      }
    } catch (e) {
      throw FileWriterException('Failed to clear exported files: $e');
    }
  }

  /// Sanitizuje název souboru (odstraní nepovolené znaky)
  ///
  /// Pravidla:
  /// - Vezme prvních 50 znaků
  /// - Odstraní speciální znaky: < > : " / \ | ? *
  /// - Whitespace → underscore
  /// - Trim whitespace
  /// - Fallback: 'untitled' pokud je prázdný
  ///
  /// Příklady:
  /// - "Dokončit prezentaci pro klienta" → "Dokoncit_prezentaci_pro_klienta"
  /// - "Meeting: Q4 Planning (urgent!)" → "Meeting_Q4_Planning_urgent"
  /// - "Email → manager [ASAP]" → "Email_manager_ASAP"
  String _sanitizeFileName(String text) {
    // Vezmi prvních 50 znaků
    final truncated = text.length > 50 ? text.substring(0, 50) : text;

    // Odstraň nepovolené znaky pro file system
    var sanitized = truncated
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Nepovolené znaky → _
        .replaceAll(RegExp(r'[()[\]{}]'), '') // Závorky → odstranit
        .replaceAll(RegExp(r'[→←↑↓]'), '_') // Šipky → _
        .replaceAll(RegExp(r'\s+'), '_') // Whitespace → _
        .replaceAll(RegExp(r'_+'), '_') // Multiple underscores → single
        .trim();

    // Odstranění trailing underscores
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');

    // Fallback pokud je prázdný
    return sanitized.isEmpty ? 'untitled' : sanitized;
  }
}

/// Custom exception pro file writer errors
class FileWriterException implements Exception {
  final String message;

  FileWriterException(this.message);

  @override
  String toString() => 'FileWriterException: $message';
}
