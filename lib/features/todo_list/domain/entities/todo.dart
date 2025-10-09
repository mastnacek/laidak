import 'package:equatable/equatable.dart';
import '../../../ai_split/domain/entities/subtask.dart';

/// Domain entita pro TODO úkol
///
/// Čistá Dart třída bez závislostí na Flutter nebo databázi.
/// Obsahuje business logiku a pravidla pro Todo item.
final class Todo extends Equatable {
  final int? id;
  final String task;
  final bool isCompleted;
  final DateTime createdAt;

  // Parsované metadata z tagů
  final String? priority; // 'a', 'b', 'c'
  final DateTime? dueDate;
  final List<String> tags;

  // AI Split metadata
  final List<Subtask>? subtasks;
  final String? aiRecommendations;
  final String? aiDeadlineAnalysis;

  const Todo({
    this.id,
    required this.task,
    this.isCompleted = false,
    required this.createdAt,
    this.priority,
    this.dueDate,
    this.tags = const [],
    this.subtasks,
    this.aiRecommendations,
    this.aiDeadlineAnalysis,
  });

  /// Vytvořit kopii s upravenými hodnotami
  Todo copyWith({
    int? id,
    String? task,
    bool? isCompleted,
    DateTime? createdAt,
    String? priority,
    DateTime? dueDate,
    List<String>? tags,
    List<Subtask>? subtasks,
    String? aiRecommendations,
    String? aiDeadlineAnalysis,
  }) {
    return Todo(
      id: id ?? this.id,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      subtasks: subtasks ?? this.subtasks,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      aiDeadlineAnalysis: aiDeadlineAnalysis ?? this.aiDeadlineAnalysis,
    );
  }

  /// Business logika: Je úkol urgent? (priorita A a má dueDate dnes/včera)
  bool get isUrgent {
    if (priority != 'a') return false;
    if (dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    return due.isBefore(today) || due.isAtSameMomentAs(today);
  }

  /// Business logika: Je úkol po deadline? (má dueDate v minulosti)
  bool get isOverdue {
    if (dueDate == null) return false;
    if (isCompleted) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    return due.isBefore(today);
  }

  @override
  List<Object?> get props => [
        id,
        task,
        isCompleted,
        createdAt,
        priority,
        dueDate,
        tags,
        subtasks,
        aiRecommendations,
        aiDeadlineAnalysis,
      ];
}
