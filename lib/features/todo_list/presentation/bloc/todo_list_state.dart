import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/sort_mode.dart';
import '../../domain/extensions/todo_filtering.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';

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

  /// Zobrazit hotové úkoly?
  final bool showCompleted;

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

  /// Helper: ID aktuálního custom view
  String? get currentCustomViewId => currentCustomView?.id;

  const TodoListLoaded({
    required this.allTodos,
    this.showCompleted = false,
    this.expandedTodoId,
    this.searchQuery = '',
    this.viewMode = ViewMode.all,
    this.sortMode,
    this.sortDirection = SortDirection.desc,
    this.currentCustomView,
  });

  /// Computed property: Filtrované a seřazené todos
  ///
  /// Pipeline:
  /// 1. Filter by search query
  /// 2. Filter by view mode (built-in nebo custom)
  /// 3. Filter by showCompleted
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

    // 3. Filter by showCompleted
    if (!showCompleted) {
      todos = todos.where((t) => !t.isCompleted).toList();
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
    bool? showCompleted,
    int? expandedTodoId,
    bool clearExpandedTodoId = false,
    String? searchQuery,
    ViewMode? viewMode,
    SortMode? sortMode,
    bool clearSortMode = false,
    SortDirection? sortDirection,
    CustomAgendaView? currentCustomView,
    bool clearCustomView = false,
  }) {
    return TodoListLoaded(
      allTodos: allTodos ?? this.allTodos,
      showCompleted: showCompleted ?? this.showCompleted,
      expandedTodoId:
          clearExpandedTodoId ? null : (expandedTodoId ?? this.expandedTodoId),
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      sortMode: clearSortMode ? null : (sortMode ?? this.sortMode),
      sortDirection: sortDirection ?? this.sortDirection,
      currentCustomView: clearCustomView ? null : (currentCustomView ?? this.currentCustomView),
    );
  }

  @override
  List<Object?> get props => [
        allTodos,
        showCompleted,
        expandedTodoId,
        searchQuery,
        viewMode,
        sortMode,
        sortDirection,
        currentCustomView,
      ];
}

/// Error state - chyba při operaci s databází
final class TodoListError extends TodoListState {
  final String message;

  const TodoListError(this.message);

  @override
  List<Object?> get props => [message];
}
