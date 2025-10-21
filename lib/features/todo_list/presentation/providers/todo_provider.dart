import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/entities/todo.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/sort_mode.dart';
import '../../domain/enums/completion_filter.dart';
import '../../../ai_brief/domain/entities/brief_response.dart';
import '../../../ai_brief/domain/entities/brief_config.dart';
import '../../../settings/domain/models/custom_agenda_view.dart';
import '../bloc/todo_list_state.dart';

part 'todo_provider.g.dart';

/// Riverpod Notifier pro správu Todo List
///
/// Nahrazuje původní TodoListBloc
/// Zodpovědnosti:
/// - Načítání todos z databáze
/// - Přidávání, aktualizace, mazání todos
/// - Filtrování zobrazení (hotové/nehotové)
/// - Expandování/kolapsování úkolů
/// - Generování AI Brief (s 1h cache)
/// - Auto-export markdown (pokud zapnutý v settings)
@riverpod
class TodoList extends _$TodoList {
  // Cache pro AI Brief (1h validity)
  BriefResponse? _aiBriefCache;

  @override
  Future<TodoListState> build() async {
    // Načíst initial data
    try {
      final todos = await ref.read(todoRepositoryProvider).getTodos();
      return TodoListLoaded(allTodos: todos);
    } catch (e) {
      AppLogger.error('Chyba při načítání todos: $e');
      return TodoListError(e.toString());
    }
  }

  /// Reload todos z databáze
  Future<void> loadTodos() async {
    // Zachovat VŠECHNY důležité parametry z předchozího stavu
    final previousState = state.value;
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
        : CompletionFilter.incomplete;
    final briefConfig = previousState is TodoListLoaded
        ? previousState.briefConfig
        : const BriefConfig();
    final prepopulatedText = previousState is TodoListLoaded
        ? previousState.prepopulatedText
        : null;

    try {
      final todos = await ref.read(todoRepositoryProvider).getTodos();

      state = AsyncValue.data(TodoListLoaded(
        allTodos: todos,
        expandedTodoId: expandedTodoId,
        viewMode: viewMode,
        searchQuery: searchQuery,
        sortMode: sortMode,
        sortDirection: sortDirection,
        currentCustomView: currentCustomView,
        aiBriefData: aiBriefData,
        completionFilter: completionFilter,
        briefConfig: briefConfig,
        prepopulatedText: prepopulatedText,
      ));

      AppLogger.debug('✅ Todos načteny: ${todos.length} items');
    } catch (e) {
      AppLogger.error('Chyba při načítání todos: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// Přidat nový todo
  Future<void> addTodo({
    required String taskText,
    String? priority,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    try {
      final newTodo = Todo(
        id: 0, // DB auto-increment
        taskText: taskText,
        isCompleted: false,
        priority: priority,
        dueDate: dueDate,
        tags: tags,
        createdAt: DateTime.now(),
      );

      await ref.read(todoRepositoryProvider).addTodo(newTodo);

      // Auto-export markdown pokud je zapnutý
      await _autoExportIfEnabled();

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Todo přidán: $taskText');
    } catch (e) {
      AppLogger.error('Chyba při přidávání todo: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// Aktualizovat existující todo
  Future<void> updateTodo(Todo todo) async {
    try {
      await ref.read(todoRepositoryProvider).updateTodo(todo);

      // Auto-export markdown pokud je zapnutý
      await _autoExportIfEnabled();

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Todo aktualizován: ${todo.taskText}');
    } catch (e) {
      AppLogger.error('Chyba při aktualizaci todo: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// Smazat todo podle ID
  Future<void> deleteTodo(int id) async {
    try {
      await ref.read(todoRepositoryProvider).deleteTodo(id);

      // Auto-export markdown pokud je zapnutý
      await _autoExportIfEnabled();

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Todo smazán: $id');
    } catch (e) {
      AppLogger.error('Chyba při mazání todo: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// Přepnout stav todo (hotovo/nehotovo)
  Future<void> toggleTodo({required int id, required bool isCompleted}) async {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    try {
      // Najít todo
      final todo = currentState.allTodos.firstWhere((t) => t.id == id);

      // Aktualizovat v databázi
      await ref.read(todoRepositoryProvider).updateTodo(
        todo.copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        ),
      );

      // Auto-export markdown pokud je zapnutý
      await _autoExportIfEnabled();

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Todo toggled: $id → $isCompleted');
    } catch (e) {
      AppLogger.error('Chyba při toggle todo: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// Přepnout zobrazení hotových úkolů
  void toggleShowCompleted() {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    // Cycle: incomplete → all → completed → incomplete
    final newFilter = switch (currentState.completionFilter) {
      CompletionFilter.incomplete => CompletionFilter.all,
      CompletionFilter.all => CompletionFilter.completed,
      CompletionFilter.completed => CompletionFilter.incomplete,
    };

    state = AsyncValue.data(currentState.copyWith(completionFilter: newFilter));
    AppLogger.debug('🔄 Completion filter změněn: $newFilter');
  }

  /// Expandovat/kolapsovat úkol podle ID
  void toggleExpandTodo(int? todoId) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    // Pokud kliknuto na stejný todo → collapse
    // Pokud kliknuto na jiný todo → expand ten nový
    final newExpandedId = currentState.expandedTodoId == todoId ? null : todoId;

    state = AsyncValue.data(currentState.copyWith(
      expandedTodoId: newExpandedId,
      clearExpandedTodoId: newExpandedId == null,
    ));

    AppLogger.debug('🔄 Expanded todo: $newExpandedId');
  }

  // ==================== SEARCH / FILTER / SORT ====================

  /// Vyhledat úkoly podle query
  void searchTodos(String query) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    AppLogger.debug('🔍 Search query: "$query"');
  }

  /// Vymazat vyhledávání
  void clearSearch() {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(searchQuery: ''));
    AppLogger.debug('🔍 Search cleared');
  }

  /// Změnit view mode (agenda kategorie)
  void changeViewMode(ViewMode viewMode) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(
      viewMode: viewMode,
      clearCustomView: true, // Clear custom view při přepnutí na built-in
    ));

    AppLogger.debug('🔄 View mode změněn: $viewMode');
  }

  /// Změnit na custom view (tag-based filtr)
  void changeToCustomView(CustomAgendaView customView) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(
      viewMode: ViewMode.custom,
      currentCustomView: customView,
    ));

    AppLogger.debug('🔄 Custom view: ${customView.name}');
  }

  /// Seřadit úkoly podle kritéria
  void sortTodos(SortMode sortMode, SortDirection direction) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(
      sortMode: sortMode,
      sortDirection: direction,
    ));

    AppLogger.debug('🔄 Sort: $sortMode $direction');
  }

  /// Vymazat sortování (vrátit na default)
  void clearSort() {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(clearSortMode: true));
    AppLogger.debug('🔄 Sort cleared (default: createdAt DESC)');
  }

  // ==================== AI BRIEF ====================

  /// Regenerovat AI Brief (ignorovat cache)
  Future<void> regenerateBrief() async {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    // Set loading state
    state = AsyncValue.data(currentState.copyWith(
      isGeneratingBrief: true,
      clearBriefError: true,
    ));

    try {
      // Získat AI Brief settings ze Settings provider
      final settingsState = await ref.read(settingsProvider.future);
      final apiKey = settingsState.openRouterApiKey;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OpenRouter API klíč není nastaven');
      }

      // Generovat AI Brief
      final briefResponse = await ref.read(aiBriefRepositoryProvider).generateBrief(
        todos: currentState.allTodos,
        config: currentState.briefConfig,
      );

      // Update cache
      _aiBriefCache = briefResponse;

      // Update state
      state = AsyncValue.data(currentState.copyWith(
        aiBriefData: briefResponse,
        isGeneratingBrief: false,
      ));

      AppLogger.info('✅ AI Brief vygenerován');
    } catch (e) {
      AppLogger.error('Chyba při generování AI Brief: $e');
      state = AsyncValue.data(currentState.copyWith(
        isGeneratingBrief: false,
        briefError: e.toString(),
      ));
    }
  }

  /// Aktualizovat Brief konfiguraci (nastavení)
  Future<void> updateBriefConfig(BriefConfig config) async {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    // Uložit config do DB
    await ref.read(briefSettingsServiceProvider).saveBriefConfig(config);

    // Update state
    state = AsyncValue.data(currentState.copyWith(briefConfig: config));

    AppLogger.info('✅ Brief config aktualizován');
  }

  // ==================== INPUT BAR ====================

  /// Event pro předvyplnění input baru textem (např. z kalendáře)
  void prepopulateInput(String text) {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(prepopulatedText: text));
    AppLogger.debug('📝 Input prepopulated: "$text"');
  }

  /// Event pro vyčištění předvyplněného textu
  void clearPrepopulatedText() {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    state = AsyncValue.data(currentState.copyWith(clearPrepopulatedText: true));
    AppLogger.debug('📝 Prepopulated text cleared');
  }

  // ==================== RECURRENCE (TODOIST MODEL) ====================

  /// User potvrdil pokračování v opakování
  /// Posune due_date na další termín podle recurrence rule.
  Future<void> continueRecurrence(int todoId, DateTime nextDate) async {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    try {
      // Set generating state
      final newGeneratingMap = Map<int, bool>.from(currentState.generatingOccurrences);
      newGeneratingMap[todoId] = true;
      state = AsyncValue.data(currentState.copyWith(generatingOccurrences: newGeneratingMap));

      // Najít todo
      final todo = currentState.allTodos.firstWhere((t) => t.id == todoId);

      // Aktualizovat due_date
      await ref.read(todoRepositoryProvider).updateTodo(
        todo.copyWith(dueDate: nextDate),
      );

      // Clear generating state
      newGeneratingMap[todoId] = false;

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Recurrence pokračuje: $todoId → $nextDate');
    } catch (e) {
      AppLogger.error('Chyba při pokračování recurrence: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  /// User ukončil opakování
  /// Smaže RecurrenceRule a označí TODO jako completed.
  Future<void> endRecurrence(int todoId) async {
    final currentState = state.value;
    if (currentState is! TodoListLoaded) return;

    try {
      // Set generating state
      final newGeneratingMap = Map<int, bool>.from(currentState.generatingOccurrences);
      newGeneratingMap[todoId] = true;
      state = AsyncValue.data(currentState.copyWith(generatingOccurrences: newGeneratingMap));

      // Najít todo
      final todo = currentState.allTodos.firstWhere((t) => t.id == todoId);

      // Smazat recurrence rule + mark as completed
      await ref.read(todoRepositoryProvider).updateTodo(
        todo.copyWith(
          recurrence: null,
          isCompleted: true,
          completedAt: DateTime.now(),
        ),
      );

      // Clear generating state
      newGeneratingMap[todoId] = false;

      // Reload todos
      await loadTodos();

      AppLogger.info('✅ Recurrence ukončena: $todoId');
    } catch (e) {
      AppLogger.error('Chyba při ukončování recurrence: $e');
      state = AsyncValue.data(TodoListError(e.toString()));
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Auto-export markdown pokud je zapnutý v settings
  Future<void> _autoExportIfEnabled() async {
    try {
      final settingsState = await ref.read(settingsProvider.future);
      final exportConfig = settingsState.exportConfig;

      if (exportConfig.autoExportOnSave && exportConfig.exportTodos) {
        await ref.read(markdownExportRepositoryProvider).exportTodos(
          format: exportConfig.format,
        );
        AppLogger.debug('✅ Auto-export markdown dokončen');
      }
    } catch (e) {
      AppLogger.error('Chyba při auto-exportu markdown: $e');
      // Neblokovat hlavní operaci při chybě exportu
    }
  }
}

/// Helper provider: získat aktuální displayedTodos (pro UI)
@riverpod
List<Todo> displayedTodos(DisplayedTodosRef ref) {
  final todoListAsync = ref.watch(todoListProvider);

  return todoListAsync.maybeWhen(
    data: (state) {
      if (state is TodoListLoaded) {
        return state.displayedTodos;
      }
      return [];
    },
    orElse: () => [],
  );
}

/// Helper provider: získat expanded todo ID
@riverpod
int? expandedTodoId(ExpandedTodoIdRef ref) {
  final todoListAsync = ref.watch(todoListProvider);

  return todoListAsync.maybeWhen(
    data: (state) {
      if (state is TodoListLoaded) {
        return state.expandedTodoId;
      }
      return null;
    },
    orElse: () => null,
  );
}

/// Helper provider: získat current view mode
@riverpod
ViewMode currentViewMode(CurrentViewModeRef ref) {
  final todoListAsync = ref.watch(todoListProvider);

  return todoListAsync.maybeWhen(
    data: (state) {
      if (state is TodoListLoaded) {
        return state.viewMode;
      }
      return ViewMode.all;
    },
    orElse: () => ViewMode.all,
  );
}
