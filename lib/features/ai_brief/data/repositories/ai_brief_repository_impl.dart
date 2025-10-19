import 'dart:convert';
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/models/provider_route.dart';
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

      // Načíst provider route a cache settings (V36)
      final providerRoute = ProviderRoute.fromString(
        settings['ai_task_provider_route'] as String? ?? 'floor',
      );
      final enableCache = (settings['ai_task_enable_cache'] as int? ?? 1) == 1;

      // Fail Fast - API key musí existovat
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'OpenRouter API key není nastavený. Běž do Nastavení → AI a nastav ho.',
        );
      }

      // 2. Sestavit user context (s config pro completed tasks filtering)
      final userContext = BriefContextBuilder.buildUserContext(tasks, config);
      AppLogger.debug('📝 Context length: ${userContext.length} chars');

      // 3. Zavolat AI datasource s provider route a cache
      final aiResponseRaw = await aiDatasource.generateBrief(
        apiKey: apiKey,
        model: model,
        userContext: userContext,
        temperature: config.temperature,
        maxTokens: config.maxTokens,
        providerRoute: providerRoute,
        enableCache: enableCache,
      );

      // 4. Parse JSON odpověď
      BriefResponse briefResponse;
      try {
        // Někdy AI vrátí markdown (```json ... ```) - očistit
        final cleanedJson = _cleanMarkdownJson(aiResponseRaw);

        AppLogger.debug('🧹 Cleaned JSON length: ${cleanedJson.length} chars');
        AppLogger.debug('🧹 First 200 chars: ${cleanedJson.substring(0, cleanedJson.length > 200 ? 200 : cleanedJson.length)}');

        final jsonData = jsonDecode(cleanedJson) as Map<String, dynamic>;
        briefResponse = BriefResponse.fromJson(jsonData);
      } on FormatException catch (e) {
        // FormatException = JSON parsing error (unterminated string, etc.)
        AppLogger.error('❌ AI Brief - FormatException: $e');
        AppLogger.warning('⚒️ Attempting to fix unterminated JSON...');

        try {
          // Pokus o opravu unterminated JSON
          final cleanedJson = _cleanMarkdownJson(aiResponseRaw);
          final fixedJson = _tryFixUnterminatedString(cleanedJson);

          final jsonData = jsonDecode(fixedJson) as Map<String, dynamic>;
          briefResponse = BriefResponse.fromJson(jsonData);

          AppLogger.info('✅ JSON fix successful! Parsed ${briefResponse.sections.length} sections');
        } catch (retryError) {
          // Fix selhal - throw original error s detaily
          AppLogger.error('❌ JSON fix failed: $retryError');
          AppLogger.error('📄 Raw AI response:\n$aiResponseRaw');

          throw Exception(
            'AI vrátilo nevalidní JSON odpověď: '
            'FormatException: Unterminated string (at line ${e.source}, character ${e.offset})\n\n'
            '... to pro tebe důležitá oblast. Úkoly 2, 4, 12, 13, 15, 21, 22, 30, 43, 49 se',
          );
        }
      } catch (e) {
        AppLogger.error('❌ AI Brief - JSON parsing error: $e');
        AppLogger.error('📄 Raw AI response:\n$aiResponseRaw');
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
  ///
  /// ⚠️ POZOR: Pokud AI response je truncated (nedokončený JSON),
  /// tato funkce nemůže opravit - musíš zvýšit max_tokens!
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

  /// EXPERIMENTAL: Pokusí se opravit unterminated string v JSON
  ///
  /// ⚠️ Používej POUZE pokud jsonDecode() selže!
  /// Nefunguje pro všechny případy - lepší je zvýšit max_tokens.
  String _tryFixUnterminatedString(String json) {
    // Najít poslední validní } bracket
    final lastValidBracket = json.lastIndexOf('}');
    if (lastValidBracket == -1) {
      // Žádný bracket - nemůžeme opravit
      return json;
    }

    // Ořízni vše za posledním }
    final fixed = json.substring(0, lastValidBracket + 1);
    AppLogger.debug('⚒️ Attempting to fix unterminated JSON (trimmed ${json.length - fixed.length} chars)');

    return fixed;
  }
}
