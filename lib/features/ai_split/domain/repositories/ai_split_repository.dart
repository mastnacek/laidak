import '../entities/ai_split_request.dart';
import '../entities/ai_split_response.dart';
import '../entities/subtask.dart';

/// Repository interface pro AI split
/// Abstrakce pro volání AI API a práci se subtasks v databázi
abstract class AiSplitRepository {
  /// Zavolat OpenRouter API a vrátit parsed response
  Future<AiSplitResponse> splitTask(AiSplitRequest request);

  /// Uložit subtasks do databáze
  Future<List<Subtask>> saveSubtasks({
    required int parentTodoId,
    required List<String> subtasksTexts,
  });

  /// Získat subtasks pro TODO
  Future<List<Subtask>> getSubtasks(int parentTodoId);

  /// Toggle subtask completed
  Future<void> toggleSubtask(int subtaskId, bool completed);

  /// Smazat subtask
  Future<void> deleteSubtask(int subtaskId);

  /// Update TODO s AI metadata (doporučení a analýza termínu)
  Future<void> updateTodoAIMetadata({
    required int todoId,
    String? recommendations,
    String? deadlineAnalysis,
  });
}
