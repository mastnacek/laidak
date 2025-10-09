import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI služba pro motivaci pomocí OpenRouter API
class AIService {
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // TODO: Přesunout do konfigurace/env
  static const String _apiKey = 'YOUR_OPENROUTER_API_KEY';
  static const String _model = 'anthropic/claude-3.5-sonnet';

  /// Získat motivační zprávu pro úkol
  static Future<String> getMotivation({
    required String taskText,
    String? priority,
    List<String>? tags,
  }) async {
    // Sestavit prompt podle úkolu
    final prompt = _buildPrompt(taskText, priority, tags);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://github.com/your-repo', // Volitelné
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'Jsi motivační kouč. Tvým úkolem je motivovat uživatele k dokončení úkolu. Buď stručný, inspirativní a konkrétní. Používej emoji.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['choices'][0]['message']['content'] as String;
        return message.trim();
      } else {
        print('❌ OpenRouter API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return 'Chyba při získávání motivace. Zkontrolujte API klíč.';
      }
    } catch (e) {
      print('❌ Exception při volání AI: $e');
      return 'Chyba: Nelze se připojit k AI službě.';
    }
  }

  /// Sestavit prompt pro AI podle úkolu
  static String _buildPrompt(String taskText, String? priority, List<String>? tags) {
    final buffer = StringBuffer();
    buffer.writeln('Motivuj mě k dokončení tohoto úkolu:');
    buffer.writeln('"$taskText"');

    if (priority != null) {
      final priorityText = priority == 'a' ? 'Vysoká' : priority == 'b' ? 'Střední' : 'Nízká';
      buffer.writeln('Priorita: $priorityText');
    }

    if (tags != null && tags.isNotEmpty) {
      buffer.writeln('Tagy: ${tags.join(', ')}');
    }

    return buffer.toString();
  }
}
