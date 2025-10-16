/// Enum pro filtrování úkolů podle completion stavu
///
/// Používá se v TodoListState a CalendarPage pro filtrování zobrazených úkolů.
enum CompletionFilter {
  /// Zobrazit pouze nesplněné úkoly (výchozí stav)
  incomplete,

  /// Zobrazit pouze splněné úkoly
  completed,

  /// Zobrazit všechny úkoly (splněné i nesplněné)
  all,
}

/// Extension pro user-friendly názvy
extension CompletionFilterExtension on CompletionFilter {
  /// Název pro zobrazení v UI
  String get displayName {
    switch (this) {
      case CompletionFilter.incomplete:
        return 'Ke splnění';
      case CompletionFilter.completed:
        return 'Hotové';
      case CompletionFilter.all:
        return 'Vše';
    }
  }

  /// Ikona podle stavu (pro eye button)
  String get icon {
    switch (this) {
      case CompletionFilter.incomplete:
        return '👁️'; // Oko - zobrazit nehotové
      case CompletionFilter.completed:
        return '✅'; // Check - zobrazit hotové
      case CompletionFilter.all:
        return '👀'; // Dvě oči - zobrazit vše
    }
  }

  /// Cycle na další stav (incomplete → completed → all → incomplete)
  CompletionFilter get next {
    switch (this) {
      case CompletionFilter.incomplete:
        return CompletionFilter.completed;
      case CompletionFilter.completed:
        return CompletionFilter.all;
      case CompletionFilter.all:
        return CompletionFilter.incomplete;
    }
  }
}
