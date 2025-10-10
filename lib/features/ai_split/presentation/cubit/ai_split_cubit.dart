import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ai_split_request.dart';
import '../../domain/repositories/ai_split_repository.dart';
import 'ai_split_state.dart';

/// Cubit pro správu AI Split funkce
/// Business logika pro rozdělování úkolů pomocí AI
class AiSplitCubit extends Cubit<AiSplitState> {
  final AiSplitRepository repository;

  AiSplitCubit({required this.repository}) : super(const AiSplitInitial());

  /// Zavolat AI API pro rozdělení úkolu
  Future<void> splitTask({
    required int taskId,
    required String taskText,
    String? priority,
    DateTime? deadline,
    List<String>? tags,
    String? userNote,
  }) async {
    try {
      // Fail Fast: validace
      if (taskText.trim().isEmpty) {
        emit(const AiSplitError('Text úkolu nesmí být prázdný'));
        return;
      }

      // Emit loading state
      emit(AiSplitLoading(
        taskText: taskText,
        model: 'Načítám...', // Model se načte v repository z settings
      ));

      // Sestavit request
      final request = AiSplitRequest(
        taskText: taskText,
        priority: priority,
        deadline: deadline,
        tags: tags ?? [],
        userNote: userNote,
      );

      // Zavolat repository
      final response = await repository.splitTask(request);

      // Validace response
      if (response.subtasks.isEmpty) {
        emit(const AiSplitError('AI nevrátilo žádné podúkoly'));
        return;
      }

      if (response.subtasks.length < 3 || response.subtasks.length > 8) {
        emit(AiSplitError(
            'AI vrátilo neplatný počet podúkolů (${response.subtasks.length})'));
        return;
      }

      // Emit loaded state
      emit(AiSplitLoaded(
        taskId: taskId,
        response: response,
      ));
    } catch (e) {
      emit(AiSplitError('Chyba při volání AI: $e'));
    }
  }

  /// Přijmout návrh (uložit do DB)
  Future<void> acceptSuggestion() async {
    final currentState = state;
    if (currentState is! AiSplitLoaded) {
      emit(const AiSplitError('Není co přijmout'));
      return;
    }

    try {
      // Uložit subtasks
      final subtasks = await repository.saveSubtasks(
        parentTodoId: currentState.taskId,
        subtasksTexts: currentState.response.subtasks,
      );

      // Uložit AI metadata
      await repository.updateTodoAIMetadata(
        todoId: currentState.taskId,
        recommendations: currentState.response.recommendations,
        deadlineAnalysis: currentState.response.deadlineAnalysis,
      );

      emit(AiSplitAccepted(
        taskId: currentState.taskId,
        subtasks: subtasks,
        message: '✓ ${subtasks.length} podúkolů přidáno',
      ));
    } catch (e) {
      emit(AiSplitError('Chyba při ukládání: $e'));
    }
  }

  /// Odmítnout návrh
  void rejectSuggestion() {
    emit(const AiSplitRejected());
  }

  /// Znovu vygenerovat s poznámkou
  Future<void> retrySuggestion({
    required int taskId,
    required String taskText,
    required String userNote,
    String? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    await splitTask(
      taskId: taskId,
      taskText: taskText,
      priority: priority,
      deadline: deadline,
      tags: tags,
      userNote: userNote,
    );
  }

  /// Toggle subtask completed
  Future<void> toggleSubtask(int subtaskId, bool completed) async {
    try {
      await repository.toggleSubtask(subtaskId, completed);
    } catch (e) {
      emit(AiSplitError('Chyba při toggleování subtasku: $e'));
    }
  }

  /// Reset state
  void reset() {
    emit(const AiSplitInitial());
  }
}
