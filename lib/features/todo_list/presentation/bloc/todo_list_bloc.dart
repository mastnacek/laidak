import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import 'todo_list_event.dart';
import 'todo_list_state.dart';

/// BLoC pro správu Todo List
///
/// Zodpovědnosti:
/// - Načítání todos z databáze
/// - Přidávání, aktualizace, mazání todos
/// - Filtrování zobrazení (hotové/nehotové)
/// - Expandování/kolapsování úkolů
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;

  TodoListBloc(this._repository) : super(const TodoListInitial()) {
    // Registrace event handlerů
    on<LoadTodosEvent>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<ToggleTodoEvent>(_onToggleTodo);
    on<ToggleShowCompletedEvent>(_onToggleShowCompleted);
    on<ToggleExpandTodoEvent>(_onToggleExpandTodo);
  }

  /// Handler: Načíst všechny todos
  Future<void> _onLoadTodos(
    LoadTodosEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // Zachovat expandedTodoId z předchozího stavu
    final previousState = state;
    final expandedTodoId = previousState is TodoListLoaded
        ? previousState.expandedTodoId
        : null;

    emit(const TodoListLoading());

    try {
      final todos = await _repository.getAllTodos();
      emit(TodoListLoaded(
        todos: todos,
        expandedTodoId: expandedTodoId, // Zachovat expanded state
      ));
    } catch (e) {
      emit(TodoListError('Chyba při načítání úkolů: $e'));
    }
  }

  /// Handler: Přidat nový todo
  Future<void> _onAddTodo(
    AddTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ✅ Fail Fast: validace před zpracováním
    if (event.taskText.trim().isEmpty) {
      emit(const TodoListError('Text úkolu nesmí být prázdný'));
      return;
    }

    try {
      // Vytvořit novou Todo entitu
      final newTodo = Todo(
        task: event.taskText,
        createdAt: DateTime.now(),
        priority: event.priority,
        dueDate: event.dueDate,
        tags: event.tags,
      );

      // Uložit do databáze
      await _repository.insertTodo(newTodo);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při přidávání úkolu: $e'));
    }
  }

  /// Handler: Aktualizovat existující todo
  Future<void> _onUpdateTodo(
    UpdateTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ✅ Fail Fast: validace před zpracováním
    if (event.todo.id == null) {
      emit(const TodoListError('Nelze aktualizovat úkol bez ID'));
      return;
    }

    if (event.todo.task.trim().isEmpty) {
      emit(const TodoListError('Text úkolu nesmí být prázdný'));
      return;
    }

    try {
      await _repository.updateTodo(event.todo);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při aktualizaci úkolu: $e'));
    }
  }

  /// Handler: Smazat todo
  Future<void> _onDeleteTodo(
    DeleteTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ✅ Fail Fast: validace před zpracováním
    if (event.id <= 0) {
      emit(TodoListError('Neplatné ID úkolu: ${event.id}'));
      return;
    }

    try {
      await _repository.deleteTodo(event.id);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při mazání úkolu: $e'));
    }
  }

  /// Handler: Přepnout stav todo (hotovo/nehotovo)
  Future<void> _onToggleTodo(
    ToggleTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ✅ Fail Fast: validace před zpracováním
    if (event.id <= 0) {
      emit(TodoListError('Neplatné ID úkolu: ${event.id}'));
      return;
    }

    try {
      await _repository.toggleTodoStatus(event.id, event.isCompleted);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při změně stavu úkolu: $e'));
    }
  }

  /// Handler: Přepnout zobrazení hotových úkolů
  Future<void> _onToggleShowCompleted(
    ToggleShowCompletedEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;

    // Pouze pokud jsme ve stavu Loaded
    if (currentState is! TodoListLoaded) return;

    // Toggle showCompleted flag
    emit(currentState.copyWith(
      showCompleted: !currentState.showCompleted,
    ));
  }

  /// Handler: Expandovat/kolapsovat úkol
  Future<void> _onToggleExpandTodo(
    ToggleExpandTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;

    // Pouze pokud jsme ve stavu Loaded
    if (currentState is! TodoListLoaded) return;

    // Pokud stejné ID, zavřít (null), jinak otevřít nové
    final newExpandedId =
        currentState.expandedTodoId == event.todoId ? null : event.todoId;

    emit(currentState.copyWith(
      expandedTodoId: newExpandedId,
      clearExpandedTodoId: newExpandedId == null,
    ));
  }
}
