import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';
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
  }) async {
    AppLogger.debug('🤖 AI Chat - Sending message to OpenRouter...');
    AppLogger.debug('Model: $model');
    AppLogger.debug('User message: $userMessage');

    try {
      // Sestavit messages array pro OpenRouter API
      final apiMessages = _buildMessagesArray(
        taskContext: taskContext,
        messages: messages,
        userMessage: userMessage,
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
          'model': model,
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
  ///   {"role": "system", "content": "Kontext úkolu..."},
  ///   {"role": "user", "content": "První otázka"},
  ///   {"role": "assistant", "content": "První odpověď"},
  ///   {"role": "user", "content": "Aktuální otázka"}
  /// ]
  List<Map<String, String>> _buildMessagesArray({
    required TaskContext? taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  }) {
    final apiMessages = <Map<String, String>>[];

    // 1. System prompt (kontext úkolu nebo standalone)
    apiMessages.add({
      'role': 'system',
      'content': taskContext?.toSystemPrompt() ?? _getStandaloneSystemPrompt(),
    });

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
''';
  }
}
