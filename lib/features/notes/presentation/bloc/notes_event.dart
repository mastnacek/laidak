import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';

/// ViewMode - typ pohledu na poznámky (místo SmartFolder)
enum ViewMode {
  allNotes,      // Všechny poznámky
  recentNotes,   // Poslední týden
  customTag,     // Custom tag-based view (ID z SettingsCubit.notesConfig.customViews)
}

/// Base event pro NotesBloc
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Načíst všechny poznámky
class LoadNotesEvent extends NotesEvent {
  final String tagDelimiterStart;
  final String tagDelimiterEnd;

  const LoadNotesEvent({
    this.tagDelimiterStart = '*',
    this.tagDelimiterEnd = '*',
  });

  @override
  List<Object?> get props => [tagDelimiterStart, tagDelimiterEnd];
}

/// Event: Vytvořit novou poznámku
class CreateNoteEvent extends NotesEvent {
  final String content;

  const CreateNoteEvent(this.content);

  @override
  List<Object?> get props => [content];
}

/// Event: Aktualizovat poznámku
class UpdateNoteEvent extends NotesEvent {
  final Note note;

  const UpdateNoteEvent(this.note);

  @override
  List<Object?> get props => [note];
}

/// Event: Smazat poznámku
class DeleteNoteEvent extends NotesEvent {
  final int id;

  const DeleteNoteEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event: Změnit view mode
class ChangeViewModeEvent extends NotesEvent {
  final ViewMode mode;
  final String? customViewId; // Pokud mode == customTag, ID custom view
  final String? tagFilter; // Pokud mode == customTag, tag pro filtrování (např. "projekt")

  const ChangeViewModeEvent(this.mode, {this.customViewId, this.tagFilter});

  @override
  List<Object?> get props => [mode, customViewId, tagFilter];
}

/// Event: Toggle expand poznámky (zobrazit celý obsah)
class ToggleExpandNoteEvent extends NotesEvent {
  final int? noteId; // null = collapse all

  const ToggleExpandNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}
