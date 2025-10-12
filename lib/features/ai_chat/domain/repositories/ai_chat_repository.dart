import '../entities/chat_message.dart';
import '../entities/task_context.dart';

/// Repository interface pro AI chat
abstract class AiChatRepository {
  /// Poslat zprávu AI a získat odpověď
  ///
  /// [taskContext] - kontext úkolu (první message = system prompt)
  /// [messages] - historie konverzace
  /// [userMessage] - aktuální user message
  ///
  /// Returns: AI odpověď
  Future<ChatMessage> sendMessage({
    required TaskContext taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  });

  /// Optional: Uložit chat historii do DB (pro persistence)
  Future<void> saveChatHistory(int todoId, List<ChatMessage> messages);

  /// Optional: Načíst chat historii z DB
  Future<List<ChatMessage>> loadChatHistory(int todoId);

  /// Optional: Smazat chat historii
  Future<void> clearChatHistory(int todoId);
}
