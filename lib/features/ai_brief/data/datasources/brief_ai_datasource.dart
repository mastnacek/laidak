import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';

/// OpenRouter AI Datasource pro AI Brief
///
/// Odpovídá za:
/// - Posílání requests na OpenRouter API
/// - Parsování JSON odpovědí
class BriefAiDatasource {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _chatEndpoint = '/chat/completions';

  /// System prompt pro AI Brief (z brief.md řádky 177-246)
  static const String _systemPrompt = '''
You are a task prioritization assistant. Analyze the user's tasks and return a structured JSON response.

# OBJECTIVE
Help user understand:
1. What to do RIGHT NOW (top 3 tasks)
2. Key insights (dependencies, patterns)
3. Motivation (progress, encouragement)

# INPUT FORMAT
You will receive tasks in this format:

TASK_ID: 5
Text: Dokončit prezentaci pro klienta
Priority: a (high)
Due Date: 2025-10-13 14:00 (in 2 hours)
Subtasks: 2/5 completed
Status: active
Tags: work, urgent

# OUTPUT FORMAT (JSON)

{
  "sections": [
    {
      "type": "focus_now",
      "title": "🎯 FOCUS NOW",
      "commentary": "Tyhle 3 úkoly jsou teď nejdůležitější",
      "task_ids": [5, 12, 8]
    },
    {
      "type": "key_insights",
      "title": "📊 KEY INSIGHTS",
      "commentary": "Úkol 5 blokuje 12 a 18. Udělej ho první!",
      "task_ids": [5, 12, 18, 22]
    },
    {
      "type": "motivation",
      "title": "💪 MOTIVATION",
      "commentary": "Skvěle! Dokončil jsi 3/5 včerejších úkolů. Ještě *5* a máš rekord týdne!",
      "task_ids": []
    }
  ],
  "generated_at": "2025-10-13T10:30:00Z"
}

# ANALYSIS RULES

## Focus Now (top 3)
- Pick 3 most important tasks RIGHT NOW
- Consider: deadline urgency, priority, blocking others
- Max 3 tasks (not more!)

## Key Insights (optional section)
- Identify dependencies (task A blocks task B)
- Find quick wins (easy + high impact)
- Warn about conflicts (overlapping deadlines)
- List ALL tasks mentioned in insights

## Motivation (always include)
- Celebrate progress (completed tasks today/this week)
- Encourage next steps
- NO task_ids (just motivational text)

# IMPORTANT
- Return ONLY valid JSON (no markdown, no extra text)
- task_ids MUST be integers from input
- commentary MUST be in Czech
- Be concise (max 2 sentences per commentary)
''';

  final http.Client client;

  BriefAiDatasource({http.Client? client})
      : client = client ?? http.Client();

  /// Generuje AI Brief
  ///
  /// [apiKey] - OpenRouter API key
  /// [model] - Model ID (např. 'anthropic/claude-3.5-sonnet')
  /// [userContext] - Strukturovaný seznam úkolů
  /// [temperature] - AI temperature (0.0-1.0)
  /// [maxTokens] - Max tokens pro odpověď
  ///
  /// Returns: JSON string s AI Brief
  /// Throws: [Exception] pokud AI request selže
  Future<String> generateBrief({
    required String apiKey,
    required String model,
    required String userContext,
    required double temperature,
    required int maxTokens,
  }) async {
    AppLogger.debug('🤖 AI Brief - Generuji Brief...');
    AppLogger.debug('Model: $model');
    AppLogger.debug('Temperature: $temperature');
    AppLogger.debug('Context length: ${userContext.length} chars');

    try {
      // Sestavit messages array
      final messages = [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': userContext,
        },
      ];

      // API request
      final response = await client.post(
        Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://todo-app.local',
          'X-Title': 'TODO App - AI Brief',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'OpenRouter API error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      AppLogger.debug('✅ AI Brief - Response received (${content.length} chars)');

      // Log usage stats (pro cost tracking)
      if (data['usage'] != null) {
        final usage = data['usage'];
        AppLogger.debug('📊 Usage: ${usage['prompt_tokens']} input + ${usage['completion_tokens']} output tokens');
      }

      return content;
    } catch (e) {
      AppLogger.error('❌ AI Brief - Error: $e');
      rethrow;
    }
  }
}
