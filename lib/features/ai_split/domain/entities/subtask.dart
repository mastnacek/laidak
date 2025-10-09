import 'package:equatable/equatable.dart';

/// Subtask entity - Pure Dart object
/// Reprezentuje jeden podúkol vytvořený AI rozdělením
class Subtask extends Equatable {
  final int? id;
  final int parentTodoId;
  final int subtaskNumber; // Pořadí (1, 2, 3...)
  final String text;
  final bool completed;
  final DateTime createdAt;

  const Subtask({
    this.id,
    required this.parentTodoId,
    required this.subtaskNumber,
    required this.text,
    this.completed = false,
    required this.createdAt,
  });

  Subtask copyWith({
    int? id,
    int? parentTodoId,
    int? subtaskNumber,
    String? text,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      parentTodoId: parentTodoId ?? this.parentTodoId,
      subtaskNumber: subtaskNumber ?? this.subtaskNumber,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        parentTodoId,
        subtaskNumber,
        text,
        completed,
        createdAt,
      ];
}
