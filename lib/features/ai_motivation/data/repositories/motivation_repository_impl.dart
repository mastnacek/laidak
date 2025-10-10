import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import 'motivation_repository.dart';

/// Implementace MotivationRepository
///
/// Používá OpenRouter API pro získání motivačních zpráv.
class MotivationRepositoryImpl implements MotivationRepository {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final DatabaseHelper _db;

  MotivationRepositoryImpl(this._db);

  @override
  Future<String> getMotivation({
    required String taskText,
    String? priority,
    List<String>? tags,
  }) async {
    // ✅ Fail Fast: validace
    if (taskText.trim().isEmpty) {
      throw ArgumentError('Task text nesmí být prázdný');
    }

    // Načíst nastavení z databáze
    final settings = await _db.getSettings();
    final apiKey = settings['api_key'] as String?;
    final model = settings['model'] as String;
    final temperature = settings['temperature'] as double;
    final maxTokens = settings['max_tokens'] as int;

    // ✅ Fail Fast: kontrola API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('API klíč není nastaven. Přejděte do nastavení.');
    }

    // Najít custom prompt podle tagů
    String systemPrompt =
        'Jsi motivační kouč. Tvým úkolem je motivovat uživatele k dokončení úkolu. Buď stručný, inspirativní a konkrétní. Používej emoji.';

    if (tags != null && tags.isNotEmpty) {
      final customPrompt = await _db.findPromptByTags(tags);
      if (customPrompt != null) {
        systemPrompt = customPrompt['system_prompt'] as String;
        AppLogger.debug('✅ Použit custom prompt: ${customPrompt['category']}');
      }
    }

    // Sestavit prompt podle úkolu
    final prompt = _buildPrompt(taskText, priority, tags);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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
              'content': prompt,
            }
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message']['content'] as String;
        return message.trim();
      } else {
        AppLogger.error('❌ OpenRouter API error: ${response.statusCode}');
        AppLogger.error('Response: ${response.body}');
        throw Exception(
            'API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.error('❌ Exception při volání AI', error: e);
      rethrow; // Propagovat chybu nahoru
    }
  }

  /// Sestavit prompt pro AI podle úkolu
  String _buildPrompt(String taskText, String? priority, List<String>? tags) {
    final buffer = StringBuffer();
    buffer.writeln('Motivuj mě k dokončení tohoto úkolu:');
    buffer.writeln('"$taskText"');

    if (priority != null) {
      final priorityText =
          priority == 'a' ? 'Vysoká' : priority == 'b' ? 'Střední' : 'Nízká';
      buffer.writeln('Priorita: $priorityText');
    }

    if (tags != null && tags.isNotEmpty) {
      buffer.writeln('Tagy: ${tags.join(', ')}');
    }

    return buffer.toString();
  }
}
