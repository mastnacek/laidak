import 'package:flutter/material.dart';

/// View modes pro kategorizaci úkolů podle času
///
/// Inspirováno Org Mode Agenda z Tauri TODO app.
/// Každý mode představuje jiný pohled na úkoly.
enum ViewMode {
  /// Všechny úkoly (default)
  all,

  /// Dnes - co musíš dnes udělat
  /// (overdue + deadlines dnes + scheduled dnes)
  today,

  /// Týden - plán na celý týden
  /// (seskupeno po dnech, příštích 7 dní)
  week,

  /// Nadcházející - co tě čeká v příštích 7 dnech
  /// (deadlines v příštích 7 dnech, bez dnes a overdue)
  upcoming,

  /// Po termínu - úkoly kde jsi proklastnul
  /// (dueDate < today && !isCompleted)
  overdue;

  /// Zobrazovací text pro UI
  String get label {
    return switch (this) {
      ViewMode.all => '📋 Všechny',
      ViewMode.today => '📅 Dnes',
      ViewMode.week => '🗓️ Týden',
      ViewMode.upcoming => '⏰ Nadcházející',
      ViewMode.overdue => '⚠️ Overdue',
    };
  }

  /// Krátký popis view mode
  String get description {
    return switch (this) {
      ViewMode.all => 'Zobrazit všechny úkoly',
      ViewMode.today => 'Co musíš dnes udělat',
      ViewMode.week => 'Plán na celý týden',
      ViewMode.upcoming => 'Co tě čeká v příštích 7 dnech',
      ViewMode.overdue => 'Úkoly po termínu',
    };
  }

  /// Ikona pro view mode (kompaktní UI)
  IconData get icon {
    return switch (this) {
      ViewMode.all => Icons.list,
      ViewMode.today => Icons.today,
      ViewMode.week => Icons.view_week,
      ViewMode.upcoming => Icons.schedule,
      ViewMode.overdue => Icons.warning,
    };
  }
}
