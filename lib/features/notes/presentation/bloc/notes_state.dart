import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';
import 'notes_event.dart'; // Pro ViewMode enum

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
  final ViewMode currentView; // Aktuální view mode
  final String? customViewId; // ID custom view (pokud currentView == customTag)
  final String? customViewTagFilter; // Tag filter pro custom view (např. "projekt")
  final int? expandedNoteId; // ID rozbalené poznámky (pro expand/collapse)

  const NotesLoaded({
    required this.notes,
    this.currentView = ViewMode.allNotes,
    this.customViewId,
    this.customViewTagFilter,
    this.expandedNoteId,
  });

  @override
  List<Object?> get props => [notes, currentView, customViewId, customViewTagFilter, expandedNoteId];

  /// Computed: Filtrované poznámky podle currentView
  List<Note> get displayedNotes {
    switch (currentView) {
      case ViewMode.allNotes:
        return notes;

      case ViewMode.recentNotes:
        // Poslední týden (7 dní)
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        return notes.where((note) => note.createdAt.isAfter(cutoff)).toList();

      case ViewMode.customTag:
        // Tag-based filtrování
        if (customViewTagFilter == null || customViewTagFilter!.isEmpty) {
          return notes; // Fallback pokud chybí tag
        }
        // Filtruj poznámky které obsahují *tag* v content
        final tagPattern = '*${customViewTagFilter!.toLowerCase()}*';
        return notes.where((note) {
          return note.content.toLowerCase().contains(tagPattern);
        }).toList();
    }
  }

  /// Copy with pro immutable updates
  NotesLoaded copyWith({
    List<Note>? notes,
    ViewMode? currentView,
    String? customViewId,
    String? customViewTagFilter,
    int? expandedNoteId,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      currentView: currentView ?? this.currentView,
      customViewId: customViewId ?? this.customViewId,
      customViewTagFilter: customViewTagFilter ?? this.customViewTagFilter,
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
