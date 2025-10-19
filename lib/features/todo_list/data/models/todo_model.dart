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
  final DateTime? completedAt;
  final String? priority;
  final DateTime? dueDate;
  final List<String> tags;
  final String? aiRecommendations;
  final String? aiDeadlineAnalysis;
  final String? aiMotivation;
  final int? aiMotivationGeneratedAt;

  const TodoModel({
    this.id,
    required this.task,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.priority,
    this.dueDate,
    this.tags = const [],
    this.aiRecommendations,
    this.aiDeadlineAnalysis,
    this.aiMotivation,
    this.aiMotivationGeneratedAt,
  });

  /// Převést na Map pro SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags.join(','), // Ukládat jako CSV
      'ai_recommendations': aiRecommendations,
      'ai_deadline_analysis': aiDeadlineAnalysis,
      'ai_motivation': aiMotivation,
      'ai_motivation_generated_at': aiMotivationGeneratedAt,
    };
  }

  /// Vytvořit z Map (ze SQLite)
  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      task: map['task'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      priority: map['priority'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      aiRecommendations: map['ai_recommendations'] as String?,
      aiDeadlineAnalysis: map['ai_deadline_analysis'] as String?,
      aiMotivation: map['ai_motivation'] as String?,
      aiMotivationGeneratedAt: map['ai_motivation_generated_at'] as int?,
    );
  }

  /// Konverze z domain entity
  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      task: todo.task,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
      priority: todo.priority,
      dueDate: todo.dueDate,
      tags: todo.tags,
      aiRecommendations: todo.aiRecommendations,
      aiDeadlineAnalysis: todo.aiDeadlineAnalysis,
      aiMotivation: todo.aiMotivation,
      aiMotivationGeneratedAt: todo.aiMotivationGeneratedAt,
    );
  }

  /// Konverze na domain entity
  Todo toEntity() {
    return Todo(
      id: id,
      task: task,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      priority: priority,
      dueDate: dueDate,
      tags: tags,
      aiRecommendations: aiRecommendations,
      aiDeadlineAnalysis: aiDeadlineAnalysis,
      aiMotivation: aiMotivation,
      aiMotivationGeneratedAt: aiMotivationGeneratedAt,
    );
  }
}
