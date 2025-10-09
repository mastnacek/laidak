import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/ai_split_request.dart';

/// DataSource pro OpenRouter API
/// Zodpovídá za HTTP komunikaci s AI službou
class OpenRouterDataSource {
  final http.Client client;
  final String baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterDataSource({required this.client});

  /// Zavolat OpenRouter API pro rozdělení úkolu
  Future<String> splitTask({
    required AiSplitRequest request,
    required String apiKey,
    required String model,
    double temperature = 0.7,
    int maxTokens = 800,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(request);

    final response = await client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('OpenRouter API error: ${response.statusCode}');
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

FORMÁT ODPOVĚDI:
PODÚKOLY:
1. [krátký, actionable text - max 50 znaků]
2. [další podúkol...]

DOPORUČENÍ:
• [konkrétní tip, link, rada]
• [další rada...]

TERMÍN:
[posouzení reálnosti termínu vzhledem k podúkolům]

PRAVIDLA:
- Každý podúkol MAX 50 znaků
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
}
