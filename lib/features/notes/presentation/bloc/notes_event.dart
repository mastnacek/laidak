import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';
import '../../domain/enums/folder_mode.dart';

/// Base event pro NotesBloc
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Načíst všechny poznámky
class LoadNotesEvent extends NotesEvent {
  const LoadNotesEvent();
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

/// Event: Změnit folder (MILESTONE 4)
class ChangeFolderEvent extends NotesEvent {
  final FolderMode mode;

  const ChangeFolderEvent(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Event: Toggle expand poznámky (zobrazit celý obsah)
class ToggleExpandNoteEvent extends NotesEvent {
  final int? noteId; // null = collapse all

  const ToggleExpandNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}
