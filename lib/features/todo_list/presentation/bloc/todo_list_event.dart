import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/sort_mode.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';
import '../../../../features/ai_brief/domain/entities/brief_config.dart';

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

// ==================== SEARCH / FILTER / SORT EVENTS ====================

/// Vyhledat úkoly podle query
final class SearchTodosEvent extends TodoListEvent {
  final String query;

  const SearchTodosEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Vymazat vyhledávání
final class ClearSearchEvent extends TodoListEvent {
  const ClearSearchEvent();
}

/// Změnit view mode (agenda kategorie)
final class ChangeViewModeEvent extends TodoListEvent {
  final ViewMode viewMode;

  const ChangeViewModeEvent(this.viewMode);

  @override
  List<Object?> get props => [viewMode];
}

/// Seřadit úkoly podle kritéria
final class SortTodosEvent extends TodoListEvent {
  final SortMode sortMode;
  final SortDirection direction;

  const SortTodosEvent(this.sortMode, this.direction);

  @override
  List<Object?> get props => [sortMode, direction];
}

/// Vymazat sortování (vrátit na default)
final class ClearSortEvent extends TodoListEvent {
  const ClearSortEvent();
}

/// Změnit na custom view (tag-based filtr)
final class ChangeToCustomViewEvent extends TodoListEvent {
  final CustomAgendaView customView;

  const ChangeToCustomViewEvent(this.customView);

  @override
  List<Object?> get props => [customView];
}

// ==================== AI BRIEF EVENTS ====================

/// Regenerovat AI Brief (ignorovat cache)
final class RegenerateBriefEvent extends TodoListEvent {
  const RegenerateBriefEvent();
}

/// Aktualizovat Brief konfiguraci (nastavení)
final class UpdateBriefConfigEvent extends TodoListEvent {
  final BriefConfig config;

  const UpdateBriefConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

// ==================== INPUT BAR EVENTS ====================

/// Event pro předvyplnění input baru textem (např. z kalendáře)
final class PrepopulateInputEvent extends TodoListEvent {
  final String text;

  const PrepopulateInputEvent({required this.text});

  @override
  List<Object?> get props => [text];
}

/// Event pro vyčištění předvyplněného textu
final class ClearPrepopulatedTextEvent extends TodoListEvent {
  const ClearPrepopulatedTextEvent();
}

// ==================== RECURRENCE EVENTS (TODOIST MODEL) ====================

/// User potvrdil pokračování v opakování (swipe → dialog → Pokračovat)
///
/// Posune due_date na další termín podle recurrence rule.
final class ContinueRecurrenceEvent extends TodoListEvent {
  final int todoId;
  final DateTime nextDate;

  const ContinueRecurrenceEvent(this.todoId, this.nextDate);

  @override
  List<Object?> get props => [todoId, nextDate];
}

/// User ukončil opakování (swipe → dialog → Ukončit)
///
/// Smaže RecurrenceRule a označí TODO jako completed.
final class EndRecurrenceEvent extends TodoListEvent {
  final int todoId;

  const EndRecurrenceEvent(this.todoId);

  @override
  List<Object?> get props => [todoId];
}
