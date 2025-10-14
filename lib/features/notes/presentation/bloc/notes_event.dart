import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';
import '../../domain/models/smart_folder.dart';

/// Base event pro NotesBloc
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Načíst všechny poznámky + Smart Folders
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

/// Event: Změnit Smart Folder (PHASE 2)
class ChangeSmartFolderEvent extends NotesEvent {
  final SmartFolder? folder; // null = All Notes

  const ChangeSmartFolderEvent(this.folder);

  @override
  List<Object?> get props => [folder];
}

/// Event: Toggle expand poznámky (zobrazit celý obsah)
class ToggleExpandNoteEvent extends NotesEvent {
  final int? noteId; // null = collapse all

  const ToggleExpandNoteEvent(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// ==================== SMART FOLDER CRUD EVENTS (PHASE 3) ====================

/// Event: Vytvořit nový Smart Folder
class CreateSmartFolderEvent extends NotesEvent {
  final SmartFolder folder;

  const CreateSmartFolderEvent(this.folder);

  @override
  List<Object?> get props => [folder];
}

/// Event: Aktualizovat Smart Folder
class UpdateSmartFolderEvent extends NotesEvent {
  final SmartFolder folder;

  const UpdateSmartFolderEvent(this.folder);

  @override
  List<Object?> get props => [folder];
}

/// Event: Smazat Smart Folder
class DeleteSmartFolderEvent extends NotesEvent {
  final int folderId;

  const DeleteSmartFolderEvent(this.folderId);

  @override
  List<Object?> get props => [folderId];
}
