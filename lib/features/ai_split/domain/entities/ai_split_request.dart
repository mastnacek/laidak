import 'package:equatable/equatable.dart';

/// Request pro AI split API
/// Obsahuje všechny informace potřebné pro AI analýzu úkolu
class AiSplitRequest extends Equatable {
  final String taskText;
  final String? priority;
  final DateTime? deadline;
  final List<String> tags;
  final String? userNote; // Pro retry s poznámkou uživatele

  const AiSplitRequest({
    required this.taskText,
    this.priority,
    this.deadline,
    this.tags = const [],
    this.userNote,
  });

  @override
  List<Object?> get props => [
        taskText,
        priority,
        deadline,
        tags,
        userNote,
      ];
}
