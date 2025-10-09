import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_split_response.dart';
import '../../domain/entities/subtask.dart';

/// Sealed classes pro AiSplit states
/// Immutable state pro BLoC pattern
sealed class AiSplitState extends Equatable {
  const AiSplitState();

  @override
  List<Object?> get props => [];
}

/// Počáteční stav - žádná akce nebyla provedena
class AiSplitInitial extends AiSplitState {
  const AiSplitInitial();
}

/// Stav načítání - AI analyzuje úkol
class AiSplitLoading extends AiSplitState {
  final String taskText;
  final String model;

  const AiSplitLoading({
    required this.taskText,
    required this.model,
  });

  @override
  List<Object?> get props => [taskText, model];
}

/// Stav načteno - AI vrátilo návrh
class AiSplitLoaded extends AiSplitState {
  final int taskId;
  final AiSplitResponse response;

  const AiSplitLoaded({
    required this.taskId,
    required this.response,
  });

  @override
  List<Object?> get props => [taskId, response];
}

/// Stav přijato - subtasks uloženy do DB
class AiSplitAccepted extends AiSplitState {
  final int taskId;
  final List<Subtask> subtasks;
  final String message;

  const AiSplitAccepted({
    required this.taskId,
    required this.subtasks,
    required this.message,
  });

  @override
  List<Object?> get props => [taskId, subtasks, message];
}

/// Stav odmítnuto - uživatel zrušil návrh
class AiSplitRejected extends AiSplitState {
  const AiSplitRejected();
}

/// Stav chyby
class AiSplitError extends AiSplitState {
  final String message;

  const AiSplitError(this.message);

  @override
  List<Object?> get props => [message];
}
