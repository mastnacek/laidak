import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../models/note.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../bloc/notes_state.dart';

part 'notes_provider.g.dart';

/// Riverpod Notifier pro správu Notes
///
/// Nahrazuje původní NotesBloc
/// Zodpovědnosti:
/// - Načítání notes z databáze
/// - Vytváření, aktualizace, mazání notes
/// - Změna ViewMode (filtrování je computed v NotesState)
/// - Auto-export markdown (pokud zapnutý v settings)
@riverpod
class Notes extends _$Notes {
  @override
  Future<NotesState> build() async {
    // Načíst initial data
    try {
      final db = ref.read(databaseHelperProvider);
      final notesData = await db.getAllNotes();
      final notes = notesData.map((data) => Note.fromMap(data)).toList();

      // Načíst tag delimitery ze settings
      final settings = await ref.read(settingsProvider.future);

      return NotesLoaded(
        notes: notes,
        currentView: ViewMode.allNotes, // Default view
        tagDelimiterStart: settings.tagDelimiterStart,
        tagDelimiterEnd: settings.tagDelimiterEnd,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání notes: $e');
      return NotesError(e.toString());
    }
  }

  /// Reload notes z databáze
  Future<void> loadNotes({
    String? tagDelimiterStart,
    String? tagDelimiterEnd,
  }) async {
    state = const AsyncValue.loading();

    try {
      final db = ref.read(databaseHelperProvider);
      final notesData = await db.getAllNotes();
      final notes = notesData.map((data) => Note.fromMap(data)).toList();

      // Pokud nejsou delimitery zadané, načti ze settings
      String startDelimiter = tagDelimiterStart ?? '*';
      String endDelimiter = tagDelimiterEnd ?? '*';

      if (tagDelimiterStart == null || tagDelimiterEnd == null) {
        final settings = await ref.read(settingsProvider.future);
        startDelimiter = settings.tagDelimiterStart;
        endDelimiter = settings.tagDelimiterEnd;
      }

      state = AsyncValue.data(NotesLoaded(
        notes: notes,
        currentView: ViewMode.allNotes,
        tagDelimiterStart: startDelimiter,
        tagDelimiterEnd: endDelimiter,
      ));

      AppLogger.debug('✅ Notes načteny: ${notes.length} items');
    } catch (e) {
      AppLogger.error('Chyba při načítání notes: $e');
      state = AsyncValue.data(NotesError(e.toString()));
    }
  }

  /// Vytvořit novou poznámku
  Future<void> createNote(String content) async {
    // Validace
    if (content.trim().isEmpty) {
      state = AsyncValue.data(const NotesError('Obsah poznámky nesmí být prázdný'));
      return;
    }

    try {
      final db = ref.read(databaseHelperProvider);

      final newNote = Note(
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertNote(newNote.toMap());

      // Auto-export pokud je zapnutý
      await _autoExportIfEnabled(newNote);

      // Reload notes
      await loadNotes();

      AppLogger.info('✅ Note vytvořena');
    } catch (e) {
      AppLogger.error('Chyba při vytváření note: $e');
      state = AsyncValue.data(NotesError(e.toString()));
    }
  }

  /// Aktualizovat poznámku
  Future<void> updateNote(Note note) async {
    // Validace
    if (note.id == null) {
      state = AsyncValue.data(const NotesError('Nelze aktualizovat poznámku bez ID'));
      return;
    }

    if (note.content.trim().isEmpty) {
      state = AsyncValue.data(const NotesError('Obsah poznámky nesmí být prázdný'));
      return;
    }

    try {
      final db = ref.read(databaseHelperProvider);

      // Update updatedAt timestamp
      final updatedNote = note.copyWith(updatedAt: DateTime.now());

      await db.updateNote(updatedNote.toMap());

      // Auto-export pokud je zapnutý
      await _autoExportIfEnabled(updatedNote);

      // Reload notes
      await loadNotes();

      AppLogger.info('✅ Note aktualizována: ${note.id}');
    } catch (e) {
      AppLogger.error('Chyba při aktualizaci note: $e');
      state = AsyncValue.data(NotesError(e.toString()));
    }
  }

  /// Smazat poznámku
  Future<void> deleteNote(int id) async {
    try {
      final db = ref.read(databaseHelperProvider);

      await db.deleteNote(id);

      // Auto-export pokud je zapnutý
      await _autoExportAfterDelete();

      // Reload notes
      await loadNotes();

      AppLogger.info('✅ Note smazána: $id');
    } catch (e) {
      AppLogger.error('Chyba při mazání note: $e');
      state = AsyncValue.data(NotesError(e.toString()));
    }
  }

  /// Změnit view mode
  void changeViewMode(ViewMode viewMode, {String? customTag}) {
    final currentState = state.value;
    if (currentState is! NotesLoaded) return;

    state = AsyncValue.data(currentState.copyWith(
      currentView: viewMode,
      customTag: customTag,
    ));

    AppLogger.debug('🔄 Notes view mode: $viewMode${customTag != null ? " (tag: $customTag)" : ""}');
  }

  /// Expandovat/kolapsovat poznámku
  void toggleExpandNote(int? noteId) {
    final currentState = state.value;
    if (currentState is! NotesLoaded) return;

    // Pokud kliknuto na stejnou note → collapse
    // Pokud kliknuto na jinou note → expand tu novou
    final newExpandedId = currentState.expandedNoteId == noteId ? null : noteId;

    state = AsyncValue.data(currentState.copyWith(
      expandedNoteId: newExpandedId,
      clearExpandedNoteId: newExpandedId == null,
    ));

    AppLogger.debug('🔄 Expanded note: $newExpandedId');
  }

  // ==================== PRIVATE HELPERS ====================

  /// Auto-export markdown pokud je zapnutý v settings
  Future<void> _autoExportIfEnabled(Note note) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final exportConfig = settings.exportConfig;

      if (exportConfig.autoExportOnSave && exportConfig.exportNotes) {
        await ref.read(markdownExportRepositoryProvider).exportNotes(
          format: exportConfig.format,
        );
        AppLogger.debug('✅ Auto-export markdown dokončen (note)');
      }
    } catch (e) {
      AppLogger.error('Chyba při auto-exportu markdown: $e');
      // Neblokovat hlavní operaci při chybě exportu
    }
  }

  /// Auto-export po smazání
  Future<void> _autoExportAfterDelete() async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final exportConfig = settings.exportConfig;

      if (exportConfig.autoExportOnSave && exportConfig.exportNotes) {
        await ref.read(markdownExportRepositoryProvider).exportNotes(
          format: exportConfig.format,
        );
        AppLogger.debug('✅ Auto-export markdown dokončen (po smazání)');
      }
    } catch (e) {
      AppLogger.error('Chyba při auto-exportu markdown: $e');
    }
  }
}

/// Helper provider: získat aktuální displayedNotes (pro UI)
@riverpod
List<Note> displayedNotes(DisplayedNotesRef ref) {
  final notesAsync = ref.watch(notesProvider);

  return notesAsync.maybeWhen(
    data: (state) {
      if (state is NotesLoaded) {
        return state.displayedNotes;
      }
      return [];
    },
    orElse: () => [],
  );
}

/// Helper provider: získat expanded note ID
@riverpod
int? expandedNoteId(ExpandedNoteIdRef ref) {
  final notesAsync = ref.watch(notesProvider);

  return notesAsync.maybeWhen(
    data: (state) {
      if (state is NotesLoaded) {
        return state.expandedNoteId;
      }
      return null;
    },
    orElse: () => null,
  );
}

/// Helper provider: získat current view mode
@riverpod
ViewMode currentNotesViewMode(CurrentNotesViewModeRef ref) {
  final notesAsync = ref.watch(notesProvider);

  return notesAsync.maybeWhen(
    data: (state) {
      if (state is NotesLoaded) {
        return state.currentView;
      }
      return ViewMode.allNotes;
    },
    orElse: () => ViewMode.allNotes,
  );
}
