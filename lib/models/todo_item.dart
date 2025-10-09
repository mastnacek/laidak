/// Model pro TODO položku s podporou tagů a priorit
class TodoItem {
  int? id;
  String task;
  bool isCompleted;
  DateTime createdAt;

  // Parsované hodnoty z tagů
  String? priority; // 'a', 'b', 'c' z *a*, *b*, *c*
  DateTime? dueDate; // Datum z *dnes*, *zitra*, nebo konkrétní datum
  String? action; // Akce z *udelat*, *zavolat*, *napsat*, atd.
  List<String> tags; // Obecné tagy jako *rodina*, *prace*, atd.

  TodoItem({
    this.id,
    required this.task,
    this.isCompleted = false,
    DateTime? createdAt,
    this.priority,
    this.dueDate,
    this.action,
    List<String>? tags,
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
      'action': action,
      'tags': tags.join(','), // Ukládat jako CSV
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
      action: map['action'] as String?,
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
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
    String? action,
    List<String>? tags,
  }) {
    return TodoItem(
      id: id ?? this.id,
      task: task ?? this.task,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      action: action ?? this.action,
      tags: tags ?? this.tags,
    );
  }
}
