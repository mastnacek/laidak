import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';
import '../../../../core/models/openrouter_model.dart';
import '../../../../core/models/provider_route.dart';
import '../../domain/entities/ai_split_request.dart';

/// DataSource pro OpenRouter API
/// Zodpovídá za HTTP komunikaci s AI službou
class OpenRouterDataSource {
  final http.Client client;
  final String baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterDataSource({required this.client});

  /// Build model ID s provider route suffixem
  String _buildModelId(String baseModel, ProviderRoute route) {
    return baseModel + route.modelSuffix;
  }

  /// Zavolat OpenRouter API pro rozdělení úkolu
  Future<String> splitTask({
    required AiSplitRequest request,
    required String apiKey,
    required String model,
    double temperature = 0.7,
    int maxTokens = 800,
    ProviderRoute providerRoute = ProviderRoute.default_,
    bool enableCache = true,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(request);

    // Build model ID s provider route suffixem
    final finalModelId = _buildModelId(model, providerRoute);

    // System message s optional cache_control
    final systemMessage = <String, dynamic>{
      'role': 'system',
      'content': systemPrompt,
    };

    if (enableCache) {
      systemMessage['cache_control'] = {'type': 'ephemeral'};
    }

    final response = await client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/your-repo',
      },
      body: jsonEncode({
        'model': finalModelId,
        'messages': [
          systemMessage,
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content = json['choices'][0]['message']['content'] as String;
      AppLogger.debug('✅ AI Split - API response received: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
      return content;
    } else {
      AppLogger.error('❌ AI Split - OpenRouter API error: ${response.statusCode}');
      AppLogger.error('Response body: ${response.body}');
      throw Exception('OpenRouter API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// System prompt definující chování AI
  String _buildSystemPrompt() {
    return '''
Jsi asistent pro rozklad složitých úkolů na menší, realizovatelné kroky.

TVŮJ ÚKOL:
1. Rozdělit úkol na 3-8 logických podúkolů
2. Seřadit je chronologicky (první = první krok)
3. Navrhnout konkrétní řešení/tipy/odkazy

FORMÁT ODPOVĚDI - PŘESNĚ DODRŽUJ (BEZ MARKDOWN):
PODÚKOLY:
1. Text prvního podúkolu
2. Text druhého podúkolu
3. Text třetího podúkolu

DOPORUČENÍ:
• První rada
• Druhá rada

TERMÍN:
Posouzení reálnosti termínu

KRITICKÁ PRAVIDLA FORMÁTOVÁNÍ:
- ZAKÁZÁNO používat markdown (**, __, ~~, atd.)
- ZAKÁZÁNO používat HTML
- Pouze čistý text bez formátování
- Sekce musí začínat přesně: "PODÚKOLY:", "DOPORUČENÍ:", "TERMÍN:"
- Podúkoly začínají "1. ", "2. ", "3. " atd.
- Doporučení začínají "• "
- Každý podúkol MAX 50 znaků

OBSAHOVÁ PRAVIDLA:
- 3-8 podúkolů (ne víc, ne míň)
- Konkrétní akce, ne abstrakce
- Pokud je úkol jednoduchý: "Tento úkol je již dostatečně konkrétní"
''';
  }

  /// User prompt sestavený z detailů úkolu
  String _buildUserPrompt(AiSplitRequest request) {
    final buffer = StringBuffer();
    buffer.writeln('ÚKOL: ${request.taskText}');

    if (request.priority != null) {
      buffer.writeln('PRIORITA: ${request.priority}');
    }

    if (request.deadline != null) {
      buffer.writeln('DEADLINE: ${_formatDeadline(request.deadline!)}');
    }

    if (request.tags.isNotEmpty) {
      buffer.writeln('KATEGORIE: ${request.tags.join(", ")}');
    }

    if (request.userNote != null) {
      buffer.writeln('POZNÁMKA UŽIVATELE: ${request.userNote}');
    }

    return buffer.toString();
  }

  /// Formátování deadlinu pro lepší čitelnost
  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.inDays == 0) return 'Dnes';
    if (diff.inDays == 1) return 'Zítra';
    if (diff.inDays < 7) return '${diff.inDays} dní';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} týdnů';
    return '${(diff.inDays / 30).round()} měsíců';
  }

  /// Načíst seznam všech dostupných modelů z OpenRouter API
  ///
  /// Vrací seznam [OpenRouterModel] objektů.
  /// Endpoint: https://openrouter.ai/api/v1/models
  Future<List<OpenRouterModel>> fetchAvailableModels() async {
    try {
      AppLogger.debug('🔍 Načítám seznam modelů z OpenRouter API...');

      final response = await client.get(
        Uri.parse('$baseUrl/models'),
        headers: {
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/your-repo',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List<dynamic>;

        final models = data
            .map((modelJson) => OpenRouterModel.fromJson(modelJson as Map<String, dynamic>))
            .toList();

        AppLogger.debug('✅ Načteno ${models.length} modelů z OpenRouter API');
        return models;
      } else {
        AppLogger.error('❌ Chyba při načítání modelů: ${response.statusCode}');
        AppLogger.error('Response body: ${response.body}');
        throw Exception('Chyba při načítání modelů: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Exception při načítání modelů', error: e, stackTrace: stackTrace);
      throw Exception('Nepodařilo se načíst modely: $e');
    }
  }
}
