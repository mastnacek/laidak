import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/tag_suggestion.dart';

/// Service pro AI-powered tag suggestions
///
/// Využívá OpenRouter API (Claude 3.5 Haiku) pro generování relevantních tagů
/// při psaní úkolů. Preferuje existující custom tagy z databáze.
class TagSuggestionService {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final DatabaseHelper _db;
  final String _apiKey;

  TagSuggestionService(this._db, this._apiKey);

  /// Navrhne 1-3 tagy pro daný task text
  ///
  /// - Minimální délka: 15 znaků (cca 3 slova)
  /// - Vrací prázdný seznam pokud text je krátký nebo při chybě
  /// - Prioritizuje existující tagy (isExisting: true)
  /// - Response do 5s (timeout)
  /// - [usedTags]: Tagy už použité v textu (nebudou navrženy)
  Future<List<TagSuggestion>> suggestTags(
    String taskText, {
    List<String> usedTags = const [],
  }) async {
    // ✅ Fail Fast: validace
    if (taskText.trim().length < 15) {
      AppLogger.debug(
          '⏭️ TagSuggestionService: Text příliš krátký (<15 znaků), skipping');
      return [];
    }

    if (_apiKey.isEmpty) {
      AppLogger.error('❌ TagSuggestionService: API klíč není nastaven');
      return [];
    }

    try {
      // 1. Načíst existující custom tagy z DB
      final allExistingTags = await _loadExistingTags();
      AppLogger.debug(
          '📋 TagSuggestionService: Načteno ${allExistingTags.length} existujících tagů');

      // 2. Programově odebrat již použité tagy ze seznamu (PŘED AI call)
      final availableTags = allExistingTags
          .where((tag) => !usedTags.contains(tag))
          .toList();

      if (usedTags.isNotEmpty) {
        AppLogger.debug(
            '🏷️ TagSuggestionService: Použité tagy (${usedTags.length}): $usedTags');
        AppLogger.debug(
            '✂️ TagSuggestionService: Dostupné tagy po filtraci: ${availableTags.length}/${allExistingTags.length}');
      }

      // 3. Načíst AI settings z DB
      final settings = await _db.getSettings();
      final model = settings['ai_tag_suggestions_model'] as String;
      final temperature = settings['ai_tag_suggestions_temperature'] as double;
      final maxTokens = settings['ai_tag_suggestions_max_tokens'] as int;
      final seed = settings['ai_tag_suggestions_seed'] as int?;
      final topP = settings['ai_tag_suggestions_top_p'] as double?;

      // 4. Sestavit system prompt POUZE s dostupnými tagy (již odfiltrované)
      final systemPrompt = _buildSystemPrompt(availableTags);

      // 4. Zavolat OpenRouter Chat API s JSON mode
      AppLogger.debug('🚀 TagSuggestionService: Volám OpenRouter API...');
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://github.com/your-repo',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': systemPrompt,
                },
                {
                  'role': 'user',
                  'content': taskText.trim(),
                }
              ],
              'temperature': temperature,
              'max_tokens': maxTokens,
              if (seed != null) 'seed': seed,
              if (topP != null) 'top_p': topP,
              // JSON mode - KRITICKÉ pro structured output
              'response_format': {
                'type': 'json_object',
              },
            }),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.error('⏱️ TagSuggestionService: Timeout (5s)');
              throw Exception('API timeout after 5 seconds');
            },
          );

      // 5. Parse response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messageContent =
            data['choices'][0]['message']['content'] as String;

        AppLogger.debug(
            '✅ TagSuggestionService: API response OK, parsing JSON...');

        // Parse JSON response
        final jsonResponse = jsonDecode(messageContent);
        final suggestionsJson = jsonResponse['suggestions'] as List<dynamic>;

        // Convert to TagSuggestion models
        final suggestions = suggestionsJson
            .map((json) => TagSuggestion.fromJson(json as Map<String, dynamic>))
            .toList();

        // 5.5. Obohacení o barvy z tag_definitions pro existující tagy
        final tagDefinitions = await _loadTagDefinitions();
        final enrichedSuggestions = suggestions.map((suggestion) {
          if (suggestion.isExisting) {
            // Najít tag definition pro tento tag
            final definition = tagDefinitions[suggestion.tagName];
            if (definition != null) {
              return TagSuggestion(
                tagName: suggestion.tagName,
                isExisting: suggestion.isExisting,
                confidence: suggestion.confidence,
                color: definition['color'] as String?,
                emoji: definition['emoji'] as String?,
              );
            }
          }
          return suggestion;
        }).toList();

        // 6. Prioritizovat (existing first, confidence DESC)
        enrichedSuggestions.sort((a, b) {
          // Existující tagy first
          if (a.isExisting && !b.isExisting) return -1;
          if (!a.isExisting && b.isExisting) return 1;
          // Pak podle confidence (DESC)
          return b.confidence.compareTo(a.confidence);
        });

        AppLogger.debug(
            '🎯 TagSuggestionService: Navrženo ${enrichedSuggestions.length} tagů');
        return enrichedSuggestions;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        AppLogger.error('🚫 TagSuggestionService: Rate limit (429)');
        AppLogger.error('Response: ${response.body}');
        return []; // Graceful degradation
      } else if (response.statusCode == 401) {
        // Unauthorized (invalid API key)
        AppLogger.error('🔒 TagSuggestionService: Neplatný API klíč (401)');
        return [];
      } else {
        // Jiné API errory
        AppLogger.error(
            '❌ TagSuggestionService: API error ${response.statusCode}');
        AppLogger.error('Response: ${response.body}');
        return []; // Graceful degradation
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Exception v TagSuggestionService.suggestTags()',
          error: e, stackTrace: stackTrace);
      return []; // Graceful degradation - app funguje i bez suggestions
    }
  }

  /// Načte všechny existující custom tag names z databáze
  Future<List<String>> _loadExistingTags() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'tags',
        columns: ['tag_name'],
        orderBy: 'tag_name ASC',
      );

      return results.map((row) => row['tag_name'] as String).toList();
    } catch (e) {
      AppLogger.error('❌ Chyba při načítání existujících tagů', error: e);
      return [];
    }
  }

  /// Načte tag definitions (barvy, emoji) z databáze
  ///
  /// Returns: Map<tagName, {color, emoji}>
  Future<Map<String, Map<String, dynamic>>> _loadTagDefinitions() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'tag_definitions',
        columns: ['tag_name', 'color', 'emoji'],
        where: 'enabled = ?',
        whereArgs: [1],
      );

      // Převést na Map pro rychlé vyhledávání
      return Map.fromEntries(
        results.map((row) => MapEntry(
          row['tag_name'] as String,
          {
            'color': row['color'],
            'emoji': row['emoji'],
          },
        )),
      );
    } catch (e) {
      AppLogger.error('❌ Chyba při načítání tag definitions', error: e);
      return {};
    }
  }

  /// Sestaví system prompt s existujícími tagy
  String _buildSystemPrompt(List<String> existingTags) {
    final tagsString = existingTags.isEmpty
        ? '(žádné custom tagy zatím neexistují)'
        : existingTags.map((tag) => '- $tag').join('\n');

    return '''
Jsi asistent pro kategorizaci úkolů.

EXISTUJÍCÍ CUSTOM TAGY (VŽDY preferuj!):
$tagsString

PRAVIDLA:
1. Navrhni 1-3 nejvhodnější tagy pro úkol
2. VŽDY preferuj existující tagy pokud se hodí
3. Navrhni nový tag POUZE pokud žádný existující nesedí
4. Nové tagy: lowercase, bez diakritiky, krátké (max 15 znaků)
5. Confidence: 0.0-1.0 (jak moc si jsi jistý)

RESPONSE FORMAT:
Odpovídej POUZE validním JSON objektem ve formátu:

{
  "suggestions": [
    {"tag": "práce", "existing": true, "confidence": 0.95},
    {"tag": "dnes", "existing": true, "confidence": 0.8}
  ]
}

PŘÍKLAD:
User: "Koupit mléko a chleba v Albertu"
Assistant: {"suggestions": [{"tag": "nakup", "existing": true, "confidence": 0.98}, {"tag": "dnes", "existing": true, "confidence": 0.7}]}

KRITICKÉ: Odpovídej POUZE JSON, žádný další text!
''';
  }
}
