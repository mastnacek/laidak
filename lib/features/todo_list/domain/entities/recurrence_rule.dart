import 'package:equatable/equatable.dart';

/// Domain entita pro pravidlo opakování úkolu (Todoist model)
///
/// Definuje, jak se má úkol opakovat (denně, týdně, měsíčně, ročně).
/// Todoist model: Todo.dueDate se posouvá, žádné pre-generované occurrences.
final class RecurrenceRule extends Equatable {
  final int? id;
  final int todoId;
  final String recurType; // 'daily', 'weekly', 'monthly', 'yearly'
  final int interval; // Každých N dní/týdnů/měsíců/let
  final int? dayOfWeek; // 0-6 (Monday-Sunday) - pro weekly recurrence
  final int? dayOfMonth; // 1-31 - pro monthly recurrence
  final DateTime createdAt;

  const RecurrenceRule({
    this.id,
    required this.todoId,
    required this.recurType,
    this.interval = 1,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.createdAt,
  });

  /// Vytvořit kopii s upravenými hodnotami
  RecurrenceRule copyWith({
    int? id,
    int? todoId,
    String? recurType,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? createdAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      recurType: recurType ?? this.recurType,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Konverze z databázového Map
  factory RecurrenceRule.fromMap(Map<String, dynamic> map) {
    return RecurrenceRule(
      id: map['id'] as int?,
      todoId: map['todo_id'] as int,
      recurType: map['recur_type'] as String,
      interval: map['interval'] as int? ?? 1,
      dayOfWeek: map['day_of_week'] as int?,
      dayOfMonth: map['day_of_month'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Konverze na databázový Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'todo_id': todoId,
      'recur_type': recurType,
      'interval': interval,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        id,
        todoId,
        recurType,
        interval,
        dayOfWeek,
        dayOfMonth,
        createdAt,
      ];
}
