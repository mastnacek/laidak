/// Model pro TODO položku s podporou tagů a priorit
class TodoItem {
  int? id;
  String task;
  bool isCompleted;
  DateTime createdAt;

  // Parsované hodnoty z tagů
  String? priority; // 'a', 'b', 'c' z *a*, *b*, *c*
  DateTime? dueDate; // Datum z *dnes*, *zitra*, nebo konkrétní datum
  List<String> tags; // Obecné tagy jako *rodina*, *prace*, atd.

  // AI Split metadata
  String? aiRecommendations;
  String? aiDeadlineAnalysis;

  TodoItem({
    this.id,
    required this.task,
    this.isCompleted = false,
    DateTime? createdAt,
    this.priority,
    this.dueDate,
    List<String>? tags,
    this.aiRecommendations,
    this.aiDeadlineAnalysis,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  /// Převést na Map pro SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags.join(','), // Ukládat jako CSV
      'ai_recommendations': aiRecommendations,
      'ai_deadline_analysis': aiDeadlineAnalysis,
    };
  }

  /// Vytvořit z Map (ze SQLite)
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as int?,
      task: map['task'] as String,
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      priority: map['priority'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      aiRecommendations: map['ai_recommendations'] as String?,
      aiDeadlineAnalysis: map['ai_deadline_analysis'] as String?,
    );
  }

  /// Vytvořit kopii s upravenými hodnotami
  TodoItem copyWith({
    int? id,
    String? task,
    bool? isCompleted,
    DateTime? createdAt,
    String? priority,
    DateTime? dueDate,
    List<String>? tags,
    String? aiRecommendations,
    String? aiDeadlineAnalysis,
  }) {
    return TodoItem(
      id: id ?? this.id,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      tags: tags ?? this.tags,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      aiDeadlineAnalysis: aiDeadlineAnalysis ?? this.aiDeadlineAnalysis,
    );
  }
}
