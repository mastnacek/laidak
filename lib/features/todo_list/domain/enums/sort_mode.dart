import 'package:flutter/material.dart';

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

  /// Ikona pro UI button
  IconData get icon {
    return switch (this) {
      SortMode.priority => Icons.flag,
      SortMode.dueDate => Icons.calendar_today,
      SortMode.status => Icons.check_circle,
      SortMode.createdAt => Icons.access_time,
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

  /// IconData šipky pro AnimatedRotation
  IconData get arrowIcon {
    return this == SortDirection.desc
        ? Icons.arrow_downward
        : Icons.arrow_upward;
  }
}
