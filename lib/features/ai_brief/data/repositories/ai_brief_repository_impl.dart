import 'dart:convert';
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../domain/entities/brief_config.dart';
import '../../domain/entities/brief_response.dart';
import '../../domain/repositories/ai_brief_repository.dart';
import '../datasources/brief_ai_datasource.dart';
import '../datasources/brief_context_builder.dart';

/// Repository implementace pro AI Brief
///
/// Odpovídá za:
/// - Získání settings z DB (API key, model)
/// - Sestavení user contextu
/// - Zavolání AI datasource
/// - Parsování a validaci AI odpovědi
class AiBriefRepositoryImpl implements AiBriefRepository {
  final DatabaseHelper db;
  final BriefAiDatasource aiDatasource;

  AiBriefRepositoryImpl({
    required this.db,
    required this.aiDatasource,
  });

  @override
  Future<BriefResponse> generateBrief({
    required List<Todo> tasks,
    required BriefConfig config,
  }) async {
    AppLogger.info('🤖 AI Brief - Generuji Brief pro ${tasks.length} úkolů...');

    try {
      // 1. Získat settings z DB
      final settings = await db.getSettings();
      final apiKey = settings['openrouter_api_key'] as String?;
      final model = settings['ai_task_model'] as String? ?? 'anthropic/claude-3.5-sonnet';

      // Fail Fast - API key musí existovat
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'OpenRouter API key není nastavený. Běž do Nastavení → AI a nastav ho.',
        );
      }

      // 2. Sestavit user context
      final userContext = BriefContextBuilder.buildUserContext(tasks);
      AppLogger.debug('📝 Context length: ${userContext.length} chars');

      // 3. Zavolat AI datasource
      final aiResponseRaw = await aiDatasource.generateBrief(
        apiKey: apiKey,
        model: model,
        userContext: userContext,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
      );

      // 4. Parse JSON odpověď
      BriefResponse briefResponse;
      try {
        // Někdy AI vrátí markdown (```json ... ```) - očistit
        final cleanedJson = _cleanMarkdownJson(aiResponseRaw);
        final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
        briefResponse = BriefResponse.fromJson(jsonData);
      } catch (e) {
        AppLogger.error('❌ AI Brief - JSON parsing error: $e');
        AppLogger.error('Raw response: $aiResponseRaw');
        throw Exception('AI vrátilo nevalidní JSON odpověď: $e');
      }

      // 5. Validovat task IDs proti DB
      final validTodoIds = tasks
          .where((t) => t.id != null)
          .map((t) => t.id!)
          .toList();

      final validatedBriefResponse = briefResponse.validate(validTodoIds);

      AppLogger.info('✅ AI Brief - Hotovo! ${validatedBriefResponse.sections.length} sekcí');
      return validatedBriefResponse;

    } catch (e) {
      AppLogger.error('❌ AI Brief - Chyba při generování: $e');
      rethrow;
    }
  }

  /// Očistí AI odpověď od markdown kódu (```json ... ```)
  ///
  /// Někdy AI přidá markdown kolem JSON, což způsobí parsing error.
  /// Tato funkce odstraní markdown wrapper pokud existuje.
  String _cleanMarkdownJson(String raw) {
    final trimmed = raw.trim();

    // Check if starts with ```json
    if (trimmed.startsWith('```json')) {
      // Remove ```json from start and ``` from end
      var cleaned = trimmed.substring(7); // Skip '```json'
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      return cleaned.trim();
    }

    // Check if starts with ``` (generic code block)
    if (trimmed.startsWith('```')) {
      var cleaned = trimmed.substring(3); // Skip '```'
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      return cleaned.trim();
    }

    // No markdown wrapper - return as is
    return trimmed;
  }
}
