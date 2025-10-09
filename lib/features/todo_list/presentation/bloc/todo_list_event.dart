import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';

/// Sealed class pro všechny TodoList events
///
/// Používá sealed class pattern pro exhaustive pattern matching.
sealed class TodoListEvent extends Equatable {
  const TodoListEvent();

  @override
  List<Object?> get props => [];
}

/// Načíst všechny todos z databáze
final class LoadTodosEvent extends TodoListEvent {
  const LoadTodosEvent();
}

/// Přidat nový todo
final class AddTodoEvent extends TodoListEvent {
  final String taskText;
  final String? priority;
  final DateTime? dueDate;
  final List<String> tags;

  const AddTodoEvent({
    required this.taskText,
    this.priority,
    this.dueDate,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [taskText, priority, dueDate, tags];
}

/// Aktualizovat existující todo
final class UpdateTodoEvent extends TodoListEvent {
  final Todo todo;

  const UpdateTodoEvent(this.todo);

  @override
  List<Object?> get props => [todo];
}

/// Smazat todo podle ID
final class DeleteTodoEvent extends TodoListEvent {
  final int id;

  const DeleteTodoEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Přepnout stav todo (hotovo/nehotovo)
final class ToggleTodoEvent extends TodoListEvent {
  final int id;
  final bool isCompleted;

  const ToggleTodoEvent({
    required this.id,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [id, isCompleted];
}

/// Přepnout zobrazení hotových úkolů
final class ToggleShowCompletedEvent extends TodoListEvent {
  const ToggleShowCompletedEvent();
}

/// Expandovat/kolapsovat úkol podle ID
final class ToggleExpandTodoEvent extends TodoListEvent {
  final int? todoId;

  const ToggleExpandTodoEvent(this.todoId);

  @override
  List<Object?> get props => [todoId];
}
