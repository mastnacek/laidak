import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/sort_mode.dart';
import '../../domain/enums/completion_filter.dart';
import '../../domain/extensions/todo_filtering.dart';
import '../../domain/models/brief_section_with_todos.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';
import '../../../../features/ai_brief/domain/entities/brief_response.dart';
import '../../../../features/ai_brief/domain/entities/brief_config.dart';

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
  /// Všechny todos z databáze (nezfiltrované)
  final List<Todo> allTodos;

  /// Filtrování podle completion stavu (incomplete/completed/all)
  final CompletionFilter completionFilter;

  /// ID expandovaného úkolu (pro detail view)
  final int? expandedTodoId;

  // ==================== SEARCH / FILTER / SORT FIELDS ====================

  /// Search query (prázdný string = no search)
  final String searchQuery;

  /// View mode (agenda kategorie)
  final ViewMode viewMode;

  /// Sort mode (null = default sort by createdAt DESC)
  final SortMode? sortMode;

  /// Sort direction (asc/desc)
  final SortDirection sortDirection;

  /// Custom view (když viewMode == ViewMode.custom)
  final CustomAgendaView? currentCustomView;

  // ==================== AI BRIEF FIELDS ====================

  /// AI Brief konfigurace (uživatelská nastavení)
  final BriefConfig briefConfig;

  /// AI Brief data (když viewMode == ViewMode.aiBrief)
  final BriefResponse? aiBriefData;

  /// Generating AI Brief? (loading state)
  final bool isGeneratingBrief;

  /// Brief generation error message
  final String? briefError;

  // ==================== INPUT BAR FIELDS ====================

  /// Text k předvyplnění v input baru (např. z kalendáře)
  final String? prepopulatedText;

  // ==================== RECURRENCE FIELDS ====================

  /// Loading state pro generování occurrences (todoId → isGenerating)
  final Map<int, bool> generatingOccurrences;

  /// Helper: ID aktuálního custom view
  String? get currentCustomViewId => currentCustomView?.id;

  const TodoListLoaded({
    required this.allTodos,
    this.completionFilter = CompletionFilter.incomplete, // Výchozí: jen nehotové
    this.expandedTodoId,
    this.searchQuery = '',
    this.viewMode = ViewMode.all,
    this.sortMode,
    this.sortDirection = SortDirection.desc,
    this.currentCustomView,
    BriefConfig? briefConfig,
    this.aiBriefData,
    this.isGeneratingBrief = false,
    this.briefError,
    this.prepopulatedText,
    this.generatingOccurrences = const {},
  }) : briefConfig = briefConfig ?? const BriefConfig();

  /// Computed property: Brief sections s real Todo objekty
  ///
  /// Mapuje task IDs z AI Brief na skutečné Todo objekty.
  /// Používá se pouze když viewMode == ViewMode.aiBrief.
  List<BriefSectionWithTodos>? get briefSections {
    if (aiBriefData == null) return null;

    return aiBriefData!.sections.map((section) {
      // Map task IDs to real Todo objects
      final sectionTodos = section.taskIds
          .map((id) {
            try {
              return allTodos.firstWhere((t) => t.id == id);
            } catch (e) {
              // Task neexistuje (AI hallucination nebo task byl smazán)
              return null;
            }
          })
          .whereType<Todo>()
          .toList();

      return BriefSectionWithTodos(
        section: section,
        todos: sectionTodos,
      );
    }).toList();
  }

  // ==================== CALENDAR INTEGRATION (Milestone 8) ====================

  /// Helper: Získat todos pro konkrétní datum (pro kalendář)
  ///
  /// Vrátí TODO úkoly, které mají dueDate == target date.
  /// V24 Todoist model: dueDate se posouvá dynamicky, takže zkontrolujeme pouze dueDate.
  List<Todo> getTodosForDate(DateTime date) {
    return allTodos.where((todo) {
      if (todo.dueDate != null && _isSameDay(todo.dueDate!, date)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Helper: Kontrola zda jsou 2 data ve stejném dni (ignoruje čas)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Computed property: Todos pro dnešek (pro Today view v kalendáři)
  List<Todo> get todosForToday {
    final today = DateTime.now();
    return getTodosForDate(today);
  }

  /// Computed property: Todos pro aktuální týden (pro Week view)
  ///
  /// Vrátí všechny todos s dueDate v rozmezí aktuálního týdne (pondělí-neděle).
  /// V24 Todoist model: dueDate se posouvá dynamically.
  List<Todo> get todosForWeek {
    final now = DateTime.now();
    final weekStart = _getStartOfWeek(now);
    final weekEnd = _getEndOfWeek(now);

    return allTodos.where((todo) {
      if (todo.dueDate != null &&
          !todo.dueDate!.isBefore(weekStart) &&
          !todo.dueDate!.isAfter(weekEnd)) {
        return true;
      }
      return false;
    }).toList();
  }

  /// Helper: Začátek týdne (pondělí 00:00)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysToSubtract = weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToSubtract));
    return DateTime(monday.year, monday.month, monday.day); // 00:00:00
  }

  /// Helper: Konec týdne (neděle 23:59:59)
  DateTime _getEndOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final daysToAdd = DateTime.sunday - weekday;
    final sunday = date.add(Duration(days: daysToAdd));
    return DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
  }

  // ==================== END CALENDAR INTEGRATION ====================

  /// Computed property: Filtrované a seřazené todos
  ///
  /// Pipeline:
  /// 1. Filter by search query
  /// 2. Filter by view mode (built-in nebo custom)
  /// 3. Filter by completion status (incomplete/completed/all)
  /// 4. Sort (podle sortMode nebo default)
  ///
  /// Memoizováno díky Equatable.
  List<Todo> get displayedTodos {
    var todos = allTodos;

    // 1. Filter by search query
    if (searchQuery.isNotEmpty) {
      todos = todos.filterBySearch(searchQuery);
    }

    // 2. Filter by view mode
    if (viewMode == ViewMode.custom && currentCustomView != null) {
      // Custom view filtering (tag-based)
      todos = todos.filterByCustomView(currentCustomView!.tagFilter);
    } else {
      // Built-in view filtering
      todos = todos.filterByViewMode(viewMode);
    }

    // 3. Filter by completion status
    switch (completionFilter) {
      case CompletionFilter.incomplete:
        todos = todos.where((t) => !t.isCompleted).toList();
        break;
      case CompletionFilter.completed:
        todos = todos.where((t) => t.isCompleted).toList();
        break;
      case CompletionFilter.all:
        // Zobrazit vše - žádný filter
        break;
    }

    // 4. Sort
    if (sortMode != null) {
      todos = todos.sortBy(sortMode!, sortDirection);
    } else {
      // Default sort: createdAt DESC (nejnovější nahoře)
      todos = todos.sortBy(SortMode.createdAt, SortDirection.desc);
    }

    return todos;
  }

  /// copyWith pro immutable updates
  TodoListLoaded copyWith({
    List<Todo>? allTodos,
    CompletionFilter? completionFilter,
    int? expandedTodoId,
    bool clearExpandedTodoId = false,
    String? searchQuery,
    ViewMode? viewMode,
    SortMode? sortMode,
    bool clearSortMode = false,
    SortDirection? sortDirection,
    CustomAgendaView? currentCustomView,
    bool clearCustomView = false,
    BriefConfig? briefConfig,
    BriefResponse? aiBriefData,
    bool clearAiBriefData = false,
    bool? isGeneratingBrief,
    String? briefError,
    bool clearBriefError = false,
    String? prepopulatedText,
    bool clearPrepopulatedText = false,
    Map<int, bool>? generatingOccurrences,
  }) {
    return TodoListLoaded(
      allTodos: allTodos ?? this.allTodos,
      completionFilter: completionFilter ?? this.completionFilter,
      expandedTodoId:
          clearExpandedTodoId ? null : (expandedTodoId ?? this.expandedTodoId),
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      sortMode: clearSortMode ? null : (sortMode ?? this.sortMode),
      sortDirection: sortDirection ?? this.sortDirection,
      currentCustomView: clearCustomView ? null : (currentCustomView ?? this.currentCustomView),
      briefConfig: briefConfig ?? this.briefConfig,
      aiBriefData: clearAiBriefData ? null : (aiBriefData ?? this.aiBriefData),
      isGeneratingBrief: isGeneratingBrief ?? this.isGeneratingBrief,
      briefError: clearBriefError ? null : (briefError ?? this.briefError),
      prepopulatedText: clearPrepopulatedText ? null : (prepopulatedText ?? this.prepopulatedText),
      generatingOccurrences: generatingOccurrences ?? this.generatingOccurrences,
    );
  }

  @override
  List<Object?> get props => [
        allTodos,
        completionFilter,
        expandedTodoId,
        searchQuery,
        viewMode,
        sortMode,
        sortDirection,
        currentCustomView,
        briefConfig,
        aiBriefData,
        isGeneratingBrief,
        briefError,
        prepopulatedText,
        generatingOccurrences,
      ];
}

/// Error state - chyba při operaci s databází
final class TodoListError extends TodoListState {
  final String message;

  const TodoListError(this.message);

  @override
  List<Object?> get props => [message];
}
