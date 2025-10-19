import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';
import '../../../../core/models/provider_route.dart';

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
1. What to do RIGHT NOW (top 5 tasks)
2. Quick wins (fast tasks with high impact)
3. Key insights (dependencies, patterns)
4. Watch out (conflicts, risks)
5. Tomorrow preview (preparation for next day)
6. Motivation (progress, encouragement)

# INPUT FORMAT
You will receive tasks in this format:

TASK_ID: 5
Text: Dokončit prezentaci pro klienta
Priority: a (high)
Due Date: 2025-10-13 14:00 (in 2 hours)
Subtasks: 2/5 completed
Status: active
Tags: work, urgent

**IMPORTANT: Status field explanation:**
- Status: active = Task is NOT completed yet (use for Focus Now, Quick Wins, Watch Out, Tomorrow Preview)
- Status: completed = Task is ALREADY DONE (use ONLY for Motivation section)

# OUTPUT FORMAT (JSON)

{
  "sections": [
    {
      "type": "focus_now",
      "title": "🎯 Teď se soustřeď na",
      "commentary": "Tyhle úkoly jsou teď **nejdůležitější**. Začni úkolem **5**, protože má deadline **za 2 hodiny** a *blokuje další práci*. Postupuj: 1. Úkol **5** (urgent) 2. Úkol **12** 3. Úkol **8**",
      "task_ids": [5, 12, 8, 15, 22]
    },
    {
      "type": "quick_wins",
      "title": "⚡ Rychlé výhry",
      "commentary": "Tyto úkoly zvládneš **rychle** a mají **velký dopad**. Ideální pro *rychlý pokrok*!\n\n- Úkol **3**: 5 minut\n- Úkol **7**: 10 minut\n- Úkol **19**: rychlý email",
      "task_ids": [3, 7, 19]
    },
    {
      "type": "key_insights",
      "title": "🔍 Důležité souvislosti",
      "commentary": "**Závislosti:** Úkol **5** blokuje úkoly **12** a **18** - udělej ho *první*!\n\n**Konflikt:** Úkol **22** má konflikt s meetingem ve **14:00**.",
      "task_ids": [5, 12, 18, 22]
    },
    {
      "type": "watch_out",
      "title": "⚠️ Pozor na",
      "commentary": "**Varování:** Máš **3 úkoly** s deadlinem *dnes odpoledne* - možný časový konflikt. **Prioritizuj!**",
      "task_ids": [5, 12, 22]
    },
    {
      "type": "tomorrow_preview",
      "title": "📅 Příprava na zítřek",
      "commentary": "Zítra máš **důležitou prezentaci** - připrav si podklady *dnes večer*. Úkoly **25** a **28** ti pomohou.",
      "task_ids": [25, 28, 30]
    },
    {
      "type": "motivation",
      "title": "💪 Motivace",
      "commentary": "**Skvěle!** Dokončil jsi **3 úkoly** dnes:\n\n1. Úkol **2** ✅\n2. Úkol **4** ✅\n3. Úkol **9** ✅\n\nJeště **5 úkolů** a překonáš svůj *týdenní rekord*! 🎉",
      "task_ids": [2, 4, 9]
    }
  ],
  "generated_at": "2025-10-13T10:30:00Z"
}

# ANALYSIS RULES

## Focus Now (always include, max 5 tasks)
- Pick 3-5 most important tasks RIGHT NOW
- **CRITICAL: Use ONLY tasks with Status: active (NOT completed tasks!)**
- Consider: deadline urgency, priority, blocking others, impact
- Explain WHY these tasks are important (deadline, dependencies, impact)
- Max 5 tasks!

## Quick Wins (optional section, max 5 tasks)
- Find tasks that are FAST to complete AND have HIGH impact
- **CRITICAL: Use ONLY tasks with Status: active (NOT completed tasks!)**
- Ideal for building momentum and motivation
- Consider: low time estimate + high priority/impact
- Include ONLY if such tasks exist (at least 2 tasks)
- Max 5 tasks

## Key Insights (optional section)
- Identify dependencies (task A blocks task B)
- Warn about timing conflicts (overlapping deadlines)
- Spot patterns (many urgent tasks, overdue items)
- List ALL tasks mentioned in insights
- Include ONLY if meaningful insights exist

## Watch Out (optional section, max 5 tasks)
- Warning about potential problems/conflicts
- **CRITICAL: Use ONLY tasks with Status: active (NOT completed tasks!)**
- Overdue tasks that need immediate attention
- Deadline conflicts (multiple tasks same time)
- Resource conflicts (too many tasks for available time)
- Include ONLY if warnings exist
- Max 5 tasks

## Tomorrow Preview (optional section, max 5 tasks)
- Tasks with deadline tomorrow or tasks that help prepare for tomorrow
- **CRITICAL: Use ONLY tasks with Status: active (NOT completed tasks!)**
- Help user prepare for next day
- Consider: tomorrow's deadlines, preparation tasks
- Include ONLY if relevant tasks exist
- Max 5 tasks

## Motivation (always include)
- Celebrate progress (completed tasks today/this week)
- **CRITICAL: Use ONLY tasks with Status: completed (NOT active tasks!)**
- Include task_ids of completed tasks that you mention
- Encourage next steps with specific numbers
- Reference specific completed tasks in commentary
- Be enthusiastic and supportive!

# IMPORTANT
- Return ONLY valid JSON (no markdown code blocks, no extra text)
- task_ids MUST be integers from input
- commentary MUST be in Czech
- commentary MUST use Markdown formatting for rich text:
  - Use **bold** for important words (task numbers, deadlines, key terms)
  - Use *italic* for emphasis
  - Use numbered lists (1., 2., 3.) for steps or priorities
  - Use bullet points (-, •) for lists
  - CRITICAL: Use \\n for line breaks in JSON strings (not actual newlines!)
  - CRITICAL: Ensure all JSON strings are properly closed with quotes
  - Example: "Úkol **5** má deadline **za 2 hodiny** - *urgentní*!\\n\\nPostupuj:\\n1. Dokončit prezentaci\\n2. Poslat klientovi"
- Be concise (max 10 sentences per commentary)
''';

  final http.Client client;

  BriefAiDatasource({http.Client? client})
      : client = client ?? http.Client();

  /// Build model ID s provider route suffixem
  ///
  /// Např: "anthropic/claude-3.5-sonnet" + ProviderRoute.floor → "anthropic/claude-3.5-sonnet:floor"
  String _buildModelId(String baseModel, ProviderRoute route) {
    return baseModel + route.modelSuffix;
  }

  /// Vyčistí AI response od markdown code blocks a přebytečného whitespace
  ///
  /// AI modely často vracejí JSON v markdown code blocích (```json...```)
  /// nebo s extra whitespace. Tato metoda to opraví.
  String _cleanAiResponse(String rawResponse) {
    var cleaned = rawResponse.trim();

    // Odstranit markdown code blocks (```json ... ```)
    if (cleaned.startsWith('```')) {
      // Najít první { (začátek JSON)
      final jsonStart = cleaned.indexOf('{');
      // Najít poslední } (konec JSON)
      final jsonEnd = cleaned.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      }
    }

    return cleaned.trim();
  }

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
    ProviderRoute providerRoute = ProviderRoute.default_,
    bool enableCache = true,
  }) async {
    // Build model ID s provider route suffixem
    final finalModelId = _buildModelId(model, providerRoute);

    AppLogger.debug('🤖 AI Brief - Generuji Brief...');
    AppLogger.debug('Model: $finalModelId (base: $model, route: ${providerRoute.value})');
    AppLogger.debug('Temperature: $temperature');
    AppLogger.debug('Max tokens: $maxTokens');
    AppLogger.debug('Cache enabled: $enableCache');
    AppLogger.debug('Context length: ${userContext.length} chars');

    try {
      // Sestavit messages array
      final systemMessage = <String, dynamic>{
        'role': 'system',
        'content': _systemPrompt,
      };

      // Přidat cache_control pokud je caching zapnutý
      if (enableCache) {
        systemMessage['cache_control'] = {'type': 'ephemeral'};
      }

      final messages = [
        systemMessage,
        {
          'role': 'user',
          'content': userContext,
        },
      ];

      // API request (⚠️ TIMEOUT: 60 sekund - AI Brief může trvat dlouho!)
      final response = await client
          .post(
            Uri.parse('$_baseUrl$_chatEndpoint'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://todo-app.local',
              'X-Title': 'TODO App - AI Brief',
            },
            body: jsonEncode({
              'model': finalModelId,
              'messages': messages,
              'temperature': temperature,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('AI request timeout (60s) - zkus to znovu nebo zmenši počet úkolů');
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'OpenRouter API error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final rawContent = data['choices'][0]['message']['content'] as String;

      AppLogger.debug('✅ AI Brief - Response received (${rawContent.length} chars)');

      // Clean AI response (odstranit markdown code blocks, whitespace)
      final cleanedContent = _cleanAiResponse(rawContent);

      // Log usage stats (pro cost tracking)
      if (data['usage'] != null) {
        final usage = data['usage'];
        AppLogger.debug('📊 Usage: ${usage['prompt_tokens']} input + ${usage['completion_tokens']} output tokens');
      }

      return cleanedContent;
    } catch (e) {
      AppLogger.error('❌ AI Brief - Error: $e');
      rethrow;
    }
  }
}
