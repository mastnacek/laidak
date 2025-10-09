import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';

/// Sealed class pro všechny TodoList states
///
/// Immutable state s Equatable pro efektivní state comparison.
sealed class TodoListState extends Equatable {
  const TodoListState();

  @override
  List<Object?> get props => [];
}

/// Initial state - před načtením dat
final class TodoListInitial extends TodoListState {
  const TodoListInitial();
}

/// Loading state - načítání dat z databáze
final class TodoListLoading extends TodoListState {
  const TodoListLoading();
}

/// Loaded state - data načtena, zobrazujeme seznam
final class TodoListLoaded extends TodoListState {
  final List<Todo> todos;
  final bool showCompleted;
  final int? expandedTodoId;

  const TodoListLoaded({
    required this.todos,
    this.showCompleted = false,
    this.expandedTodoId,
  });

  /// Získat filtrované todos (podle showCompleted)
  List<Todo> get displayedTodos {
    if (showCompleted) {
      return todos;
    } else {
      return todos.where((todo) => !todo.isCompleted).toList();
    }
  }

  /// copyWith pro immutable updates
  TodoListLoaded copyWith({
    List<Todo>? todos,
    bool? showCompleted,
    int? expandedTodoId,
    bool clearExpandedTodoId = false,
  }) {
    return TodoListLoaded(
      todos: todos ?? this.todos,
      showCompleted: showCompleted ?? this.showCompleted,
      expandedTodoId:
          clearExpandedTodoId ? null : (expandedTodoId ?? this.expandedTodoId),
    );
  }

  @override
  List<Object?> get props => [todos, showCompleted, expandedTodoId];
}

/// Error state - chyba při operaci s databází
final class TodoListError extends TodoListState {
  final String message;

  const TodoListError(this.message);

  @override
  List<Object?> get props => [message];
}
