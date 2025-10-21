import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/ai_split_request.dart';
import '../cubit/ai_split_state.dart';

part 'ai_split_provider.g.dart';

/// Riverpod Notifier pro správu AI Split funkce
///
/// Nahrazuje původní AiSplitCubit
/// Business logika pro rozdělování úkolů pomocí AI
@riverpod
class AiSplit extends _$AiSplit {
  @override
  AiSplitState build() {
    return const AiSplitInitial();
  }

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
      // Validace
      if (taskText.trim().isEmpty) {
        state = const AiSplitError('Text úkolu nesmí být prázdný');
        return;
      }

      // Emit loading state
      state = AiSplitLoading(
        taskText: taskText,
        model: 'Načítám...', // Model se načte v repository z settings
      );

      // Sestavit request
      final request = AiSplitRequest(
        taskText: taskText,
        priority: priority,
        deadline: deadline,
        tags: tags ?? [],
        userNote: userNote,
      );

      // Zavolat repository
      final response = await ref.read(aiSplitRepositoryProvider).splitTask(request);

      // Validace response
      if (response.subtasks.isEmpty) {
        state = const AiSplitError('AI nevrátilo žádné podúkoly');
        return;
      }

      if (response.subtasks.length < 3 || response.subtasks.length > 8) {
        state = AiSplitError(
            'AI vrátilo neplatný počet podúkolů (${response.subtasks.length})');
        return;
      }

      // Emit loaded state
      state = AiSplitLoaded(
        taskId: taskId,
        response: response,
      );
    } catch (e) {
      state = AiSplitError('Chyba při volání AI: $e');
    }
  }

  /// Přijmout návrh (uložit do DB)
  Future<void> acceptSuggestion() async {
    final currentState = state;
    if (currentState is! AiSplitLoaded) {
      state = const AiSplitError('Není co přijmout');
      return;
    }

    try {
      // Uložit subtasks
      await ref.read(aiSplitRepositoryProvider).saveSubtasks(
        parentTodoId: currentState.taskId,
        subtasks: currentState.response.subtasks,
      );

      // Reset state
      state = const AiSplitInitial();
    } catch (e) {
      state = AiSplitError('Chyba při ukládání: $e');
    }
  }

  /// Odmítnout návrh (reset)
  void rejectSuggestion() {
    state = const AiSplitInitial();
  }

  /// Reset do počátečního stavu
  void reset() {
    state = const AiSplitInitial();
  }
}
