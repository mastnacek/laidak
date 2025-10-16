import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/sort_mode.dart';
import '../../domain/enums/completion_filter.dart';
import '../../../ai_brief/domain/repositories/ai_brief_repository.dart';
import '../../../ai_brief/domain/entities/brief_response.dart';
import '../../../ai_brief/domain/entities/brief_config.dart';
import '../../../ai_brief/data/services/brief_settings_service.dart';
import '../../../markdown_export/domain/repositories/markdown_export_repository.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../../../core/utils/app_logger.dart';
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
/// - Auto-export markdown (pokud zapnutý v settings)
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;
  final AiBriefRepository _aiBriefRepository;
  final BriefSettingsService _briefSettingsService;
  final MarkdownExportRepository _exportRepository;
  final SettingsCubit _settingsCubit;

  // Cache pro AI Brief (1h validity)
  BriefResponse? _aiBriefCache;

  TodoListBloc(
    this._repository,
    this._aiBriefRepository,
    this._briefSettingsService,
    this._exportRepository,
    this._settingsCubit,
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

    // Input bar handlers
    on<PrepopulateInputEvent>(_onPrepopulateInput);
    on<ClearPrepopulatedTextEvent>(_onClearPrepopulatedText);
  }

  /// Handler: Načíst všechny todos
  Future<void> _onLoadTodos(
    LoadTodosEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // Zachovat VŠECHNY důležité parametry z předchozího stavu
    final previousState = state;
    final expandedTodoId = previousState is TodoListLoaded
        ? previousState.expandedTodoId
        : null;
    final viewMode = previousState is TodoListLoaded
        ? previousState.viewMode
        : ViewMode.all;
    final searchQuery = previousState is TodoListLoaded
        ? previousState.searchQuery
        : '';
    final sortMode = previousState is TodoListLoaded
        ? previousState.sortMode
        : null;
    final sortDirection = previousState is TodoListLoaded
        ? previousState.sortDirection
        : SortDirection.desc;
    final currentCustomView = previousState is TodoListLoaded
        ? previousState.currentCustomView
        : null;
    final aiBriefData = previousState is TodoListLoaded
        ? previousState.aiBriefData
        : null;
    final completionFilter = previousState is TodoListLoaded
        ? previousState.completionFilter
        : CompletionFilter.incomplete; // Výchozí: jen nehotové

    emit(const TodoListLoading());

    try {
      final todos = await _repository.getAllTodos();

      // Načíst Brief config ze storage
      final briefConfig = _briefSettingsService.loadConfig();

      emit(TodoListLoaded(
        allTodos: todos,
        expandedTodoId: expandedTodoId, // Zachovat expanded state
        viewMode: viewMode, // ✅ Zachovat view mode (Brief, All, Today, ...)
        searchQuery: searchQuery, // Zachovat search query
        sortMode: sortMode, // Zachovat sort mode
        sortDirection: sortDirection, // Zachovat sort direction
        currentCustomView: currentCustomView, // Zachovat custom view
        aiBriefData: aiBriefData, // ✅ Zachovat Brief data
        completionFilter: completionFilter, // Zachovat completion filter
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

      // ✨ AUTO-EXPORT pokud je zapnutý
      await _autoExportIfEnabled(newTodo);

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

      // ✨ AUTO-EXPORT pokud je zapnutý
      await _autoExportIfEnabled(event.todo);

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

  /// Handler: Přepnout zobrazení hotových úkolů (cycle mezi 3 stavy)
  /// incomplete → completed → all → incomplete
  Future<void> _onToggleShowCompleted(
    ToggleShowCompletedEvent event,
    Emitter<TodoListState> emit,
  ) async {
    final currentState = state;

    // Pouze pokud jsme ve stavu Loaded
    if (currentState is! TodoListLoaded) return;

    // Cycle na další stav
    emit(currentState.copyWith(
      completionFilter: currentState.completionFilter.next,
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
        // Generovat Brief ze VŠECH úkolů (context builder filtruje completed podle config)
        final briefResponse = await _aiBriefRepository.generateBrief(
          tasks: currentState.allTodos, // ← VŠECHNY úkoly (aktivní + completed)
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
      // Generovat Brief ze VŠECH úkolů (context builder filtruje completed podle config)
      final briefResponse = await _aiBriefRepository.generateBrief(
        tasks: currentState.allTodos, // ← VŠECHNY úkoly (aktivní + completed)
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

      // Pokud je user právě v Brief view → automaticky regenerovat
      if (currentState.viewMode == ViewMode.aiBrief) {
        add(const RegenerateBriefEvent());
      }
    } catch (e) {
      // Error při ukládání do storage - ignore (fallback na default)
      emit(currentState.copyWith(
        briefError: 'Chyba při ukládání nastavení: $e',
      ));
    }
  }

  // ==================== INPUT BAR HANDLERS ====================

  /// Handler: Předvyplnit input bar textem (např. z kalendáře)
  void _onPrepopulateInput(
    PrepopulateInputEvent event,
    Emitter<TodoListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Nastavit prepopulated text ve state
    emit(currentState.copyWith(prepopulatedText: event.text));
  }

  /// Handler: Vyčistit předvyplněný text
  void _onClearPrepopulatedText(
    ClearPrepopulatedTextEvent event,
    Emitter<TodoListState> emit,
  ) {
    final currentState = state;
    if (currentState is! TodoListLoaded) return;

    // Vyčistit prepopulated text
    emit(currentState.copyWith(clearPrepopulatedText: true));
  }

  // ==================== MARKDOWN EXPORT HELPERS ====================

  /// Helper: Auto-export TODO pokud je zapnutý v settings
  ///
  /// Fail silently - nebudeme blokovat hlavní operaci kvůli export erroru
  Future<void> _autoExportIfEnabled(Todo todo) async {
    try {
      final settingsState = _settingsCubit.state;

      // Check: settings jsou loaded
      if (settingsState is! SettingsLoaded) {
        AppLogger.debug('⏭️ Settings nejsou načteny, skip auto-export');
        return;
      }

      final exportConfig = settingsState.exportConfig;

      // Check: auto-export zapnutý + target directory nastavený + TODOs export povolený
      if (!exportConfig.autoExportOnSave) {
        AppLogger.debug('⏭️ Auto-export vypnutý, skip');
        return;
      }

      if (!exportConfig.isConfigured) {
        AppLogger.debug('⏭️ Export není nakonfigurovaný (chybí target directory), skip');
        return;
      }

      if (!exportConfig.exportTodos) {
        AppLogger.debug('⏭️ Export TODOs zakázán, skip');
        return;
      }

      // ✅ Export TODO
      await _exportRepository.exportTodo(todo, exportConfig);
      AppLogger.debug('✅ Auto-export TODO ${todo.id} dokončen');
    } catch (e) {
      // Fail silently - logovat error, ale nepropagovat výjimku
      // Auto-export nesmí blokovat hlavní operaci (Add/Update TODO)
      AppLogger.error('❌ Auto-export selhal: $e');
    }
  }
}
