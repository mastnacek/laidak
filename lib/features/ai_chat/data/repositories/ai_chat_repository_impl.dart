import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/openrouter_chat_datasource.dart';

/// Implementace AiChatRepository
class AiChatRepositoryImpl implements AiChatRepository {
  final OpenRouterChatDataSource dataSource;
  final DatabaseHelper db;

  AiChatRepositoryImpl({
    required this.dataSource,
    required this.db,
  });

  @override
  Future<ChatMessage> sendMessage({
    required TaskContext? taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  }) async {
    // Načíst settings z DB
    final settings = await db.getSettings();
    final apiKey = settings['openrouter_api_key'] as String?;
    final model = settings['ai_task_model'] as String; // Použít task model (inteligentní)

    // Fail Fast: validace API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API klíč není nastaven v nastavení');
    }

    // Zavolat OpenRouter API
    final responseText = await dataSource.sendMessage(
      apiKey: apiKey,
      model: model,
      taskContext: taskContext,
      messages: messages,
      userMessage: userMessage,
    );

    // Vrátit jako ChatMessage entity
    return ChatMessage.assistant(responseText);
  }

  @override
  Future<void> saveChatHistory(int todoId, List<ChatMessage> messages) async {
    // TODO: Implementovat persistence do DB (optional v1.0)
    // Pro v1.0: Chat history je jen v paměti (session-based)
    AppLogger.debug('💾 Chat history save skipped (not implemented yet)');
  }

  @override
  Future<List<ChatMessage>> loadChatHistory(int todoId) async {
    // TODO: Implementovat load z DB (optional v1.0)
    AppLogger.debug('📂 Chat history load skipped (not implemented yet)');
    return [];
  }

  @override
  Future<void> clearChatHistory(int todoId) async {
    // TODO: Implementovat clear z DB (optional v1.0)
    AppLogger.debug('🗑️ Chat history clear skipped (not implemented yet)');
  }
}
