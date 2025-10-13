import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';
import '../../domain/enums/folder_mode.dart';

/// Base state pro NotesBloc
abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

/// State: Počáteční stav
class NotesInitial extends NotesState {
  const NotesInitial();
}

/// State: Načítání poznámek
class NotesLoading extends NotesState {
  const NotesLoading();
}

/// State: Poznámky načteny
class NotesLoaded extends NotesState {
  final List<Note> notes; // Všechny poznámky (unfiltered)
  final FolderMode currentFolder; // Aktuální folder (MILESTONE 4)
  final int? expandedNoteId; // ID rozbalené poznámky (pro expand/collapse)

  const NotesLoaded({
    required this.notes,
    this.currentFolder = FolderMode.all,
    this.expandedNoteId,
  });

  @override
  List<Object?> get props => [notes, currentFolder, expandedNoteId];

  /// Computed: Filtrované poznámky podle currentFolder
  List<Note> get displayedNotes {
    switch (currentFolder) {
      case FolderMode.all:
        return notes;
      case FolderMode.recent:
        // Poslední týden
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return notes.where((note) => note.createdAt.isAfter(weekAgo)).toList();
      case FolderMode.favorites:
        // TODO: Implementovat favorites v MILESTONE 4.1
        return [];
    }
  }

  /// Copy with pro immutable updates
  NotesLoaded copyWith({
    List<Note>? notes,
    FolderMode? currentFolder,
    int? expandedNoteId,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      currentFolder: currentFolder ?? this.currentFolder,
      expandedNoteId: expandedNoteId,
    );
  }
}

/// State: Chyba
class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}
