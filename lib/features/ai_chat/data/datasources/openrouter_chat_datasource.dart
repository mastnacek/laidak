import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';
import '../../../../core/models/provider_route.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';

/// OpenRouter Chat Completion API client
///
/// Docs: https://openrouter.ai/docs/api-reference/chat-completion
class OpenRouterChatDataSource {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _chatEndpoint = '/chat/completions';

  final http.Client client;

  OpenRouterChatDataSource({http.Client? client})
      : client = client ?? http.Client();

  /// Build model ID s provider route suffixem
  String _buildModelId(String baseModel, ProviderRoute route) {
    return baseModel + route.modelSuffix;
  }

  /// Poslat chat message a získat AI odpověď
  ///
  /// [apiKey] - OpenRouter API key
  /// [model] - Model ID (např. 'anthropic/claude-3.5-sonnet')
  /// [taskContext] - Kontext úkolu (pokud null, standalone chat)
  /// [messages] - Historie konverzace
  /// [userMessage] - Aktuální user message
  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required TaskContext? taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
    ProviderRoute providerRoute = ProviderRoute.default_,
    bool enableCache = true,
  }) async {
    // Build model ID s provider route suffixem
    final finalModelId = _buildModelId(model, providerRoute);

    AppLogger.debug('🤖 AI Chat - Sending message to OpenRouter...');
    AppLogger.debug('Model: $finalModelId (base: $model, route: ${providerRoute.value})');
    AppLogger.debug('Cache enabled: $enableCache');
    AppLogger.debug('User message: $userMessage');

    try {
      // Sestavit messages array pro OpenRouter API
      final apiMessages = _buildMessagesArray(
        taskContext: taskContext,
        messages: messages,
        userMessage: userMessage,
        enableCache: enableCache,
      );

      // API request
      final response = await client.post(
        Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://todo-app.local',
          'X-Title': 'TODO App - AI Chat',
        },
        body: jsonEncode({
          'model': finalModelId,
          'messages': apiMessages,
          'temperature': 0.7, // Mírně kreativní (není to JSON generation)
          'max_tokens': 1000, // Delší odpovědi jsou OK
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'OpenRouter API error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      AppLogger.debug('✅ AI Chat - Response received (${content.length} chars)');
      return content;
    } catch (e) {
      AppLogger.error('❌ AI Chat - Error: $e');
      rethrow;
    }
  }

  /// Sestavit messages array pro OpenRouter API
  ///
  /// Format:
  /// [
  ///   {"role": "system", "content": "Kontext úkolu...", "cache_control": {...}},
  ///   {"role": "user", "content": "První otázka"},
  ///   {"role": "assistant", "content": "První odpověď"},
  ///   {"role": "user", "content": "Aktuální otázka"}
  /// ]
  List<Map<String, dynamic>> _buildMessagesArray({
    required TaskContext? taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
    required bool enableCache,
  }) {
    final apiMessages = <Map<String, dynamic>>[];

    // 1. System prompt (kontext úkolu nebo standalone) s optional cache_control
    final systemMessage = <String, dynamic>{
      'role': 'system',
      'content': taskContext?.toSystemPrompt() ?? _getStandaloneSystemPrompt(),
    };

    if (enableCache) {
      systemMessage['cache_control'] = {'type': 'ephemeral'};
    }

    apiMessages.add(systemMessage);

    // 2. Historie konverzace
    for (var msg in messages) {
      apiMessages.add({
        'role': msg.role,
        'content': msg.content,
      });
    }

    // 3. Aktuální user message
    apiMessages.add({
      'role': 'user',
      'content': userMessage,
    });

    AppLogger.debug('📝 Messages array: ${apiMessages.length} messages');
    return apiMessages;
  }

  /// Získat standalone system prompt (bez task kontextu)
  String _getStandaloneSystemPrompt() {
    return '''
Jsi AI asistent pro produktivitu a time management.
Pomáháš uživatelům s plánováním, organizací práce, motivací a efektivitou.

Buď konstruktivní, praktický a konkrétní. Odpovídej v češtině.

# FORMATTING RULES
Formátuj odpovědi pomocí Markdown pro lepší čitelnost:
- Používej **tučný text** pro důležitá slova, čísla úkolů, deadlines
- Používej *kurzívu* pro zdůraznění
- Používej číslované seznamy (1., 2., 3.) pro kroky nebo postupy
- Používej odrážky (-, •) pro seznamy
- Používej nadpisy (# Nadpis) pro strukturu delších odpovědí

Příklad:
"Pro dokončení úkolu **5** doporučuji tento postup:

1. **Nejprve** zkontroluj podklady
2. *Připrav* prezentaci (cca **30 minut**)
3. Pošli klientovi

⚡ **Tip:** Udělej úkol **teď** - deadline je za **2 hodiny**!"
''';
  }
}
