import '../../domain/entities/todo.dart';

/// Data Transfer Object (DTO) pro Todo
///
/// Konvertuje mezi domain entitou (Todo) a databází (Map<String, dynamic>).
/// Používá se v data layer pro komunikaci s DatabaseHelper.
class TodoModel {
  final int? id;
  final String task;
  final bool isCompleted;
  final DateTime createdAt;
  final String? priority;
  final DateTime? dueDate;
  final String? action;
  final List<String> tags;

  const TodoModel({
    this.id,
    required this.task,
    this.isCompleted = false,
    required this.createdAt,
    this.priority,
    this.dueDate,
    this.action,
    this.tags = const [],
  });

  /// Převést na Map pro SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'action': action,
      'tags': tags.join(','), // Ukládat jako CSV
    };
  }

  /// Vytvořit z Map (ze SQLite)
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      task: map['task'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      priority: map['priority'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      action: map['action'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
    );
  }

  /// Konverze z domain entity
  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      task: todo.task,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      priority: todo.priority,
      dueDate: todo.dueDate,
      action: todo.action,
      tags: todo.tags,
    );
  }

  /// Konverze na domain entity
  Todo toEntity() {
    return Todo(
      id: id,
      task: task,
      isCompleted: isCompleted,
      createdAt: createdAt,
      priority: priority,
      dueDate: dueDate,
      action: action,
      tags: tags,
    );
  }
}
