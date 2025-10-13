import 'package:equatable/equatable.dart';
import '../../../../models/note.dart';

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
  final List<Note> notes;

  const NotesLoaded({required this.notes});

  @override
  List<Object?> get props => [notes];

  /// Copy with pro immutable updates
  NotesLoaded copyWith({
    List<Note>? notes,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
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
