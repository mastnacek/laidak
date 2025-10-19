import '../../domain/entities/subtask.dart';

/// Subtask model - DTO pro SQLite mapping
/// Konverze mezi databázovou reprezentací a domain entitou
class SubtaskModel extends Subtask {
  const SubtaskModel({
    super.id,
    required super.parentTodoId,
    required super.subtaskNumber,
    required super.text,
    super.completed,
    required super.createdAt,
  });

  /// Factory pro vytvoření z databázového Map
  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] as int?,
      parentTodoId: map['parent_todo_id'] as int,
      subtaskNumber: map['subtask_number'] as int,
      text: map['text'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Konverze do databázového Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_todo_id': parentTodoId,
      'subtask_number': subtaskNumber,
      'text': text,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Factory pro vytvoření z domain entity
  factory SubtaskModel.fromEntity(Subtask entity) {
    return SubtaskModel(
      id: entity.id,
      parentTodoId: entity.parentTodoId,
      subtaskNumber: entity.subtaskNumber,
      text: entity.text,
      completed: entity.completed,
      createdAt: entity.createdAt,
    );
  }
}
