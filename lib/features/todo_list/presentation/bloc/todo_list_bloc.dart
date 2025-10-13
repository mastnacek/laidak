import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/enums/view_mode.dart';
import '../../../ai_brief/domain/repositories/ai_brief_repository.dart';
import '../../../ai_brief/domain/entities/brief_response.dart';
import '../../../ai_brief/domain/entities/brief_config.dart';
import '../../../ai_brief/data/services/brief_settings_service.dart';
import 'todo_list_event.dart';
import 'todo_list_state.dart';

/// BLoC pro správu Todo List
///
/// Zodpovědnosti:
/// - Načítání todos z databáze
/// - Přidávání, aktualizace, mazání todos
/// - Filtrování zobrazení (hotové/nehotové)
/// - Expandování/kolapsování úkolů
/// - Generování AI Brief (s 1h cache)
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;
  final AiBriefRepository _aiBriefRepository;
  final BriefSettingsService _briefSettingsService;

  // Cache pro AI Brief (1h validity)
  BriefResponse? _aiBriefCache;

  TodoListBloc(
    this._repository,
    this._aiBriefRepository,
    this._briefSettingsService,
  ) : super(const TodoListInitial()) {
    // Registrace event handlerů
    on<LoadTodosEvent>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<ToggleTodoEvent>(_onToggleTodo);
    on<ToggleShowCompletedEvent>(_onToggleShowCompleted);
    on<ToggleExpandTodoEvent>(_onToggleExpandTodo);

    // Search / Filter / Sort handlers
    on<SearchTodosEvent>(_onSearchTodos);
    on<ClearSearchEvent>(_onClearSearch);
    on<ChangeViewModeEvent>(_onChangeViewMode);
    on<ChangeToCustomViewEvent>(_onChangeToCustomView);
    on<SortTodosEvent>(_onSortTodos);
    on<ClearSortEvent>(_onClearSort);

    // AI Brief handlers
    on<RegenerateBriefEvent>(_onRegenerateBrief);
    on<UpdateBriefConfigEvent>(_onUpdateBriefConfig);
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

      // Načíst Brief config ze storage
      final briefConfig = _briefSettingsService.loadConfig();

      emit(TodoListLoaded(
        allTodos: todos,
        expandedTodoId: expandedTodoId, // Zachovat expanded state
        briefConfig: briefConfig, // Načíst uložený config
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

  // ==================== SEARCH / FILTER / SORT HANDLERS ====================

  /// Handler: Vyhledat úkoly podle query
  void _onSearchTodos(SearchTodosEvent event, Emitter<TodoListState> emit) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Update search query v state
    // displayedTodos getter automaticky aplikuje filtr
    emit(currentState.copyWith(searchQuery: event.query));
  }

  /// Handler: Vymazat vyhledávání
  void _onClearSearch(ClearSearchEvent event, Emitter<TodoListState> emit) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Vymazat search query
    emit(currentState.copyWith(searchQuery: ''));
  }

  /// Handler: Změnit view mode
  Future<void> _onChangeViewMode(
    ChangeViewModeEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Pokud přepínáme NA aiBrief
    if (event.viewMode == ViewMode.aiBrief) {
      // ✅ Check cache first (1h validity)
      if (_aiBriefCache != null && _aiBriefCache!.isCacheValid) {
        emit(currentState.copyWith(
          viewMode: ViewMode.aiBrief,
          aiBriefData: _aiBriefCache,
          clearCustomView: true,
        ));
        return;
      }

      // ❌ Cache neexistuje nebo je starý → Generate new
      emit(currentState.copyWith(
        viewMode: ViewMode.aiBrief,
        isGeneratingBrief: true, // ← Loading state
        clearCustomView: true,
        clearBriefError: true,
      ));

      try {
        // Generovat Brief z nehotových úkolů
        final briefResponse = await _aiBriefRepository.generateBrief(
          tasks: currentState.allTodos
              .where((t) => !t.isCompleted)
              .toList(),
          config: currentState.briefConfig, // Použij aktuální config ze state
        );

        // Uložit cache
        _aiBriefCache = briefResponse;

        // Emit success state
        emit(currentState.copyWith(
          viewMode: ViewMode.aiBrief,
          aiBriefData: briefResponse,
          isGeneratingBrief: false,
          clearBriefError: true,
        ));
      } catch (e) {
        // Emit error state
        emit(currentState.copyWith(
          viewMode: ViewMode.aiBrief,
          isGeneratingBrief: false,
          briefError: e.toString(),
          clearAiBriefData: true,
        ));
      }
      return;
    }

    // Pro ostatní view modes (není aiBrief)
    emit(currentState.copyWith(
      viewMode: event.viewMode,
      clearCustomView: true,
    ));
  }

  /// Handler: Změnit na custom view
  void _onChangeToCustomView(
    ChangeToCustomViewEvent event,
    Emitter<TodoListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // ✅ Fail Fast: validace custom view
    if (event.customView.tagFilter.trim().isEmpty) {
      // Fallback na All view
      emit(currentState.copyWith(
        viewMode: ViewMode.all,
        clearCustomView: true,
      ));
      return;
    }

    // Update view mode + custom view v state
    // displayedTodos getter automaticky aplikuje custom filtr
    emit(currentState.copyWith(
      viewMode: ViewMode.custom,
      currentCustomView: event.customView,
    ));
  }

  /// Handler: Seřadit úkoly
  void _onSortTodos(SortTodosEvent event, Emitter<TodoListState> emit) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Update sort mode a direction v state
    // displayedTodos getter automaticky aplikuje sort
    emit(currentState.copyWith(
      sortMode: event.sortMode,
      sortDirection: event.direction,
    ));
  }

  /// Handler: Vymazat sortování (vrátit na default)
  void _onClearSort(ClearSortEvent event, Emitter<TodoListState> emit) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Vymazat sort mode (default = createdAt DESC)
    emit(currentState.copyWith(clearSortMode: true));
  }

  // ==================== AI BRIEF HANDLERS ====================

  /// Handler: Regenerovat AI Brief (force regenerate, ignorovat cache)
  Future<void> _onRegenerateBrief(
    RegenerateBriefEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Ignorovat cache - vždy generovat nový
    emit(currentState.copyWith(
      isGeneratingBrief: true,
      clearBriefError: true,
    ));

    try {
      final briefResponse = await _aiBriefRepository.generateBrief(
        tasks: currentState.allTodos
            .where((t) => !t.isCompleted)
            .toList(),
        config: currentState.briefConfig, // Použij aktuální config ze state
      );

      // Update cache
      _aiBriefCache = briefResponse;

      emit(currentState.copyWith(
        aiBriefData: briefResponse,
        isGeneratingBrief: false,
        clearBriefError: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isGeneratingBrief: false,
        briefError: e.toString(),
      ));
    }
  }

  /// Handler: Aktualizovat Brief konfiguraci (nastavení)
  Future<void> _onUpdateBriefConfig(
    UpdateBriefConfigEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    try {
      // Uložit config do storage
      await _briefSettingsService.saveConfig(event.config);

      // Invalidovat cache (config se změnil)
      _aiBriefCache = null;

      // Update state s novým configem
      emit(currentState.copyWith(
        briefConfig: event.config,
        clearAiBriefData: true, // Clear starý Brief
      ));
    } catch (e) {
      // Error při ukládání do storage - ignore (fallback na default)
      emit(currentState.copyWith(
        briefError: 'Chyba při ukládání nastavení: $e',
      ));
    }
  }
}
