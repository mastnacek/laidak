/// Sort modes pro řazení úkolů
///
/// Každý mode představuje jiné kritérium pro sortování.
/// One-click toggle: DESC → ASC → OFF
enum SortMode {
  /// Podle priority (a > b > c > null)
  priority,

  /// Podle deadline (dueDate)
  dueDate,

  /// Podle stavu (completed vs. active)
  status,

  /// Podle data vytvoření (createdAt/id)
  createdAt;

  /// Zobrazovací text pro UI
  String get label {
    return switch (this) {
      SortMode.priority => 'Priorita',
      SortMode.dueDate => 'Deadline',
      SortMode.status => 'Status',
      SortMode.createdAt => 'Datum',
    };
  }

  /// Emoji pro UI button (konzistence s ViewBar)
  String get emoji {
    return switch (this) {
      SortMode.priority => '🔴',
      SortMode.dueDate => '📅',
      SortMode.status => '✅',
      SortMode.createdAt => '🆕',
    };
  }

  /// Popis sort mode
  String get description {
    return switch (this) {
      SortMode.priority => 'Seřadit podle priority (A→B→C)',
      SortMode.dueDate => 'Seřadit podle deadline',
      SortMode.status => 'Seřadit podle stavu (hotové/aktivní)',
      SortMode.createdAt => 'Seřadit podle data vytvoření',
    };
  }
}

/// Směr sortování
enum SortDirection {
  /// Ascending (vzestupně)
  asc,

  /// Descending (sestupně)
  desc;

  /// Opačný směr
  SortDirection get opposite {
    return this == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
  }

  /// Symbol šipky pro UI
  String get arrowSymbol {
    return this == SortDirection.asc ? '↑' : '↓';
  }
}
