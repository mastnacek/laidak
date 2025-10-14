import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';
import '../../domain/models/smart_folder.dart';
import '../../domain/models/filter_rules.dart';

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
  final List<SmartFolder> smartFolders; // Všechny Smart Folders
  final SmartFolder? currentFolder; // Aktuální folder (null = All Notes)
  final int? expandedNoteId; // ID rozbalené poznámky (pro expand/collapse)

  const NotesLoaded({
    required this.notes,
    required this.smartFolders,
    this.currentFolder,
    this.expandedNoteId,
  });

  @override
  List<Object?> get props => [notes, smartFolders, currentFolder, expandedNoteId];

  /// Computed: Filtrované poznámky podle currentFolder.filterRules
  List<Note> get displayedNotes {
    // Pokud není vybraný folder, zobraz všechny
    if (currentFolder == null) return notes;

    // Aplikuj FilterRules
    return _applyFilterRules(notes, currentFolder!.filterRules);
  }

  /// Aplikovat FilterRules na seznam poznámek
  List<Note> _applyFilterRules(List<Note> notes, FilterRules rules) {
    switch (rules.type) {
      case FilterType.all:
        return notes;

      case FilterType.recent:
        if (rules.recentDays == null) return notes;
        final cutoff = DateTime.now().subtract(Duration(days: rules.recentDays!));
        return notes.where((note) => note.createdAt.isAfter(cutoff)).toList();

      case FilterType.tags:
        // TODO: Implementovat tags filtering v MILESTONE 3 (Note.tags field ještě neexistuje)
        // Zatím vrátit všechny poznámky
        return notes;

      case FilterType.dateRange:
        if (rules.dateRange == null) return notes;
        return notes.where((note) {
          return note.createdAt.isAfter(rules.dateRange!.from) &&
              note.createdAt.isBefore(rules.dateRange!.to);
        }).toList();
    }
  }

  /// Copy with pro immutable updates
  NotesLoaded copyWith({
    List<Note>? notes,
    List<SmartFolder>? smartFolders,
    SmartFolder? currentFolder,
    int? expandedNoteId,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      smartFolders: smartFolders ?? this.smartFolders,
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
