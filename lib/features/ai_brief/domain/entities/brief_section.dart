import 'package:equatable/equatable.dart';

/// Sekce v AI Brief (Focus Now, Key Insights, Motivation)
///
/// Každá sekce obsahuje:
/// - [type]: Typ sekce (focus_now, key_insights, motivation)
/// - [title]: Název sekce s emoji ("🎯 FOCUS NOW")
/// - [commentary]: AI komentář vysvětlující PROČ tyto úkoly
/// - [taskIds]: Seznam ID úkolů v této sekci
class BriefSection extends Equatable {
  /// Typ sekce (focus_now, key_insights, motivation)
  final String type;

  /// Název sekce s emoji ("🎯 FOCUS NOW")
  final String title;

  /// AI komentář vysvětlující PROČ tyto úkoly
  final String commentary;

  /// Seznam ID úkolů v této sekci
  final List<int> taskIds;

  const BriefSection({
    required this.type,
    required this.title,
    required this.commentary,
    required this.taskIds,
  });

  /// Vytvoří BriefSection z JSON
  factory BriefSection.fromJson(Map<String, dynamic> json) {
    return BriefSection(
      type: json['type'] as String,
      title: json['title'] as String,
      commentary: json['commentary'] as String,
      taskIds: (json['task_ids'] as List<dynamic>)
          .map((id) => id as int)
          .toList(),
    );
  }

  /// Převede BriefSection na JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'commentary': commentary,
      'task_ids': taskIds,
    };
  }

  /// Vytvoří kopii s upravenými task IDs (pro validaci)
  BriefSection copyWith({List<int>? taskIds}) {
    return BriefSection(
      type: type,
      title: title,
      commentary: commentary,
      taskIds: taskIds ?? this.taskIds,
    );
  }

  @override
  List<Object?> get props => [type, title, commentary, taskIds];

  @override
  String toString() {
    return 'BriefSection(type: $type, title: $title, taskIds: ${taskIds.length})';
  }
}
