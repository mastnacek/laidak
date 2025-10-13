import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../models/note.dart';
import 'notes_event.dart';
import 'notes_state.dart';

/// BLoC pro správu Notes
///
/// Zodpovědnosti:
/// - Načítání notes z databáze
/// - Vytváření, aktualizace, mazání notes
/// - MILESTONE 1: Základní CRUD operace
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final DatabaseHelper _db;

  NotesBloc(this._db) : super(const NotesInitial()) {
    // Registrace event handlerů
    on<LoadNotesEvent>(_onLoadNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
  }

  /// Handler: Načíst všechny poznámky
  Future<void> _onLoadNotes(
    LoadNotesEvent event,
    Emitter<NotesState> emit,
  ) async {
    emit(const NotesLoading());

    try {
      final notesData = await _db.getAllNotes();
      final notes = notesData.map((data) => Note.fromMap(data)).toList();

      emit(NotesLoaded(notes: notes));
    } catch (e) {
      emit(NotesError('Chyba při načítání poznámek: $e'));
    }
  }

  /// Handler: Vytvořit novou poznámku
  Future<void> _onCreateNote(
    CreateNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    // Fail Fast: validace před zpracováním
    if (event.content.trim().isEmpty) {
      emit(const NotesError('Obsah poznámky nesmí být prázdný'));
      return;
    }

    try {
      final newNote = Note(
        content: event.content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.insertNote(newNote.toMap());

      // Reload notes
      add(const LoadNotesEvent());
    } catch (e) {
      emit(NotesError('Chyba při vytváření poznámky: $e'));
    }
  }

  /// Handler: Aktualizovat poznámku
  Future<void> _onUpdateNote(
    UpdateNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    // Fail Fast: validace před zpracováním
    if (event.note.id == null) {
      emit(const NotesError('Nelze aktualizovat poznámku bez ID'));
      return;
    }

    if (event.note.content.trim().isEmpty) {
      emit(const NotesError('Obsah poznámky nesmí být prázdný'));
      return;
    }

    try {
      // Update updated_at timestamp
      final updatedNote = event.note.copyWith(
        updatedAt: DateTime.now(),
      );

      await _db.updateNote(updatedNote.id!, updatedNote.toMap());

      // Reload notes
      add(const LoadNotesEvent());
    } catch (e) {
      emit(NotesError('Chyba při aktualizaci poznámky: $e'));
    }
  }

  /// Handler: Smazat poznámku
  Future<void> _onDeleteNote(
    DeleteNoteEvent event,
    Emitter<NotesState> emit,
  ) async {
    // Fail Fast: validace před zpracováním
    if (event.id <= 0) {
      emit(NotesError('Neplatné ID poznámky: ${event.id}'));
      return;
    }

    try {
      await _db.deleteNote(event.id);

      // Reload notes
      add(const LoadNotesEvent());
    } catch (e) {
      emit(NotesError('Chyba při mazání poznámky: $e'));
    }
  }
}
