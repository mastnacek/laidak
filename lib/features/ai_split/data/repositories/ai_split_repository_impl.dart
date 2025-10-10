import '../../../../core/services/database_helper.dart';
import '../../domain/entities/ai_split_request.dart';
import '../../domain/entities/ai_split_response.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/repositories/ai_split_repository.dart';
import '../datasources/openrouter_datasource.dart';
import '../models/subtask_model.dart';

/// Implementace AiSplitRepository
/// Orchestruje komunikaci s AI API a databází
class AiSplitRepositoryImpl implements AiSplitRepository {
  final OpenRouterDataSource dataSource;
  final DatabaseHelper db;

  AiSplitRepositoryImpl({
    required this.dataSource,
    required this.db,
  });

  @override
  Future<AiSplitResponse> splitTask(AiSplitRequest request) async {
    // Načíst settings z DB
    final settings = await db.getSettings();
    final apiKey = settings['api_key'] as String?;
    final model = settings['model'] as String;
    final temperature = settings['temperature'] as double;

    // Fail Fast: validace API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API klíč není nastaven v nastavení');
    }

    // Zavolat OpenRouter API
    final rawResponse = await dataSource.splitTask(
      request: request,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: 800,
    );

    // Parsovat odpověď
    print('🔍 AI Split - Parsing response...');
    final parsed = _parseResponse(rawResponse);
    print('✅ AI Split - Parsed ${parsed.subtasks.length} subtasks');
    return parsed;
  }

  @override
  Future<List<Subtask>> saveSubtasks({
    required int parentTodoId,
    required List<String> subtasksTexts,
  }) async {
    final savedSubtasks = <Subtask>[];
    final now = DateTime.now();

    for (var i = 0; i < subtasksTexts.length; i++) {
      final subtask = SubtaskModel(
        parentTodoId: parentTodoId,
        subtaskNumber: i + 1,
        text: subtasksTexts[i],
        completed: false,
        createdAt: now,
      );

      final id = await db.insertSubtask(subtask.toMap());
      savedSubtasks.add(subtask.copyWith(id: id));
    }

    return savedSubtasks;
  }

  @override
  Future<List<Subtask>> getSubtasks(int parentTodoId) async {
    final maps = await db.getSubtasksByTodoId(parentTodoId);
    return maps.map((map) => SubtaskModel.fromMap(map)).toList();
  }

  @override
  Future<void> toggleSubtask(int subtaskId, bool completed) async {
    await db.toggleSubtaskCompleted(subtaskId, completed);
  }

  @override
  Future<void> deleteSubtask(int subtaskId) async {
    await db.deleteSubtask(subtaskId);
  }

  @override
  Future<void> updateTodoAIMetadata({
    required int todoId,
    String? recommendations,
    String? deadlineAnalysis,
  }) async {
    await db.updateTodoAIMetadata(
      todoId,
      aiRecommendations: recommendations,
      aiDeadlineAnalysis: deadlineAnalysis,
    );
  }

  /// Parse AI response do struktury
  /// Extrahuje PODÚKOLY:, DOPORUČENÍ: a TERMÍN: sekce
  AiSplitResponse _parseResponse(String response) {
    print('📄 AI Split - Raw response:\n$response');
    print('─' * 50);

    final lines = response.split('\n');
    final subtasks = <String>[];
    final recommendations = <String>[];
    final deadlineAnalysisBuffer = StringBuffer();
    String section = '';

    for (final line in lines) {
      final trimmed = line.trim();

      // Detekce sekcí
      if (trimmed.startsWith('PODÚKOLY:')) {
        section = 'subtasks';
        continue;
      } else if (trimmed.startsWith('DOPORUČENÍ:')) {
        section = 'recommendations';
        continue;
      } else if (trimmed.startsWith('TERMÍN:')) {
        section = 'deadline';
        continue;
      }

      // Parse subtasks (1. Text...)
      if (section == 'subtasks' && RegExp(r'^\d+\.').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (text.isNotEmpty) {
          subtasks.add(text);
        }
      }
      // Parse recommendations (• Text... nebo - Text...)
      else if (section == 'recommendations' &&
               (trimmed.startsWith('•') || trimmed.startsWith('-'))) {
        final text = trimmed.substring(1).trim();
        if (text.isNotEmpty) {
          recommendations.add(text);
        }
      }
      // Parse deadline analysis
      else if (section == 'deadline' && trimmed.isNotEmpty) {
        deadlineAnalysisBuffer.writeln(trimmed);
      }
    }

    return AiSplitResponse(
      subtasks: subtasks,
      recommendations: recommendations.join('\n'),
      deadlineAnalysis: deadlineAnalysisBuffer.toString().trim(),
    );
  }
}
