import '../entities/todo.dart';
import '../enums/view_mode.dart';
import '../enums/sort_mode.dart';

/// Extension methods pro filtrování a sortování TODO úkolů
///
/// Pure Dart functions - snadné testování, žádné závislosti.
/// Dart-side filtering (flexibilnější než SQL).
extension TodoFiltering on List<Todo> {
  /// Filtrovat podle search query
  ///
  /// Hledá v task textu, tags a priority.
  /// Case-insensitive search.
  List<Todo> filterBySearch(String query) {
    if (query.trim().isEmpty) return this;

    final lowerQuery = query.toLowerCase();

    return where((todo) {
      // Hledat v task textu
      if (todo.task.toLowerCase().contains(lowerQuery)) return true;

      // Hledat v tags
      if (todo.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }

      // Hledat v priority (např. "a", "priorita a")
      if (todo.priority != null &&
          todo.priority!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Filtrovat podle view mode
  ///
  /// - `all`: Všechny úkoly
  /// - `today`: Overdue + deadlines dnes + scheduled dnes
  /// - `week`: Úkoly s deadline v příštích 7 dnech
  /// - `upcoming`: Deadlines v příštích 7 dnech (bez dnes a overdue)
  /// - `overdue`: Úkoly po termínu
  /// - `custom`: Používá `filterByCustomView()` místo tohoto switche
  List<Todo> filterByViewMode(ViewMode mode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return switch (mode) {
      ViewMode.all => this,
      ViewMode.today => _filterToday(today),
      ViewMode.week => _filterWeek(today, weekEnd),
      ViewMode.upcoming => _filterUpcoming(today, weekEnd),
      ViewMode.overdue => where((todo) => todo.isOverdue).toList(),
      ViewMode.custom => this, // Custom filtering se dělá v displayedTodos
    };
  }

  /// Filtrovat podle custom view (tag-based)
  ///
  /// Zobrazí pouze úkoly, které obsahují zadaný tag.
  /// Case-sensitive match (tag musí přesně odpovídat).
  ///
  /// Příklady:
  /// - tagFilter = "***" → úkoly s tagem "***"
  /// - tagFilter = "#projekt" → úkoly s tagem "#projekt"
  List<Todo> filterByCustomView(String tagFilter) {
    if (tagFilter.trim().isEmpty) return this;

    return where((todo) => todo.tags.contains(tagFilter)).toList();
  }

  /// Filtrovat úkoly na dnes
  List<Todo> _filterToday(DateTime today) {
    return where((todo) {
      // Overdue - po termínu
      if (todo.isOverdue) return true;

      // Deadline dnes
      if (todo.dueDate != null) {
        final due = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        if (due.isAtSameMomentAs(today)) return true;
      }

      // TODO: Přidat scheduled field do Todo entity (pokud chceš)
      // if (todo.scheduled != null) {
      //   final scheduled = DateTime(
      //     todo.scheduled!.year,
      //     todo.scheduled!.month,
      //     todo.scheduled!.day,
      //   );
      //   if (scheduled.isAtSameMomentAs(today)) return true;
      // }

      return false;
    }).toList();
  }

  /// Filtrovat úkoly na týden
  List<Todo> _filterWeek(DateTime today, DateTime weekEnd) {
    return where((todo) {
      if (todo.dueDate == null) return false;

      final due = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );

      // Deadline je mezi dnes a +7 dní
      return due.isAfter(today.subtract(const Duration(days: 1))) &&
          due.isBefore(weekEnd);
    }).toList();
  }

  /// Filtrovat nadcházející úkoly (příštích 7 dní, bez dnes a overdue)
  List<Todo> _filterUpcoming(DateTime today, DateTime weekEnd) {
    return where((todo) {
      if (todo.dueDate == null) return false;
      if (todo.isCompleted) return false;

      final due = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );

      final tomorrow = today.add(const Duration(days: 1));

      // Deadline je mezi zítra a +7 dní
      return due.isAfter(today) &&
          due.isBefore(weekEnd) &&
          due.isAfter(tomorrow.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Seřadit podle sort mode
  ///
  /// - `priority`: a > b > c > null
  /// - `dueDate`: podle deadline (null na konec)
  /// - `status`: completed vs. active
  /// - `createdAt`: podle data vytvoření
  ///
  /// Direction:
  /// - `desc`: Sestupně (nejvyšší nahoře)
  /// - `asc`: Vzestupně (nejnižší nahoře)
  List<Todo> sortBy(SortMode mode, SortDirection direction) {
    final sorted = List<Todo>.from(this);

    sorted.sort((a, b) {
      int comparison = switch (mode) {
        SortMode.priority => _comparePriority(a, b),
        SortMode.dueDate => _compareDueDate(a, b),
        SortMode.status => _compareStatus(a, b),
        SortMode.createdAt => _compareCreatedAt(a, b),
      };

      return direction == SortDirection.desc ? -comparison : comparison;
    });

    return sorted;
  }

  // ==================== HELPER COMPARISON METHODS ====================

  /// Porovnat podle priority (a > b > c > null)
  static int _comparePriority(Todo a, Todo b) {
    const priorityOrder = {'a': 0, 'b': 1, 'c': 2};
    final aPrio = priorityOrder[a.priority] ?? 999;
    final bPrio = priorityOrder[b.priority] ?? 999;
    return aPrio.compareTo(bPrio);
  }

  /// Porovnat podle deadline (null na konec)
  static int _compareDueDate(Todo a, Todo b) {
    if (a.dueDate == null && b.dueDate == null) return 0;
    if (a.dueDate == null) return 1; // null na konec
    if (b.dueDate == null) return -1;
    return a.dueDate!.compareTo(b.dueDate!);
  }

  /// Porovnat podle stavu (completed na konec)
  static int _compareStatus(Todo a, Todo b) {
    if (a.isCompleted == b.isCompleted) return 0;
    return a.isCompleted ? 1 : -1; // completed na konec
  }

  /// Porovnat podle data vytvoření
  static int _compareCreatedAt(Todo a, Todo b) {
    return a.createdAt.compareTo(b.createdAt);
  }
}
