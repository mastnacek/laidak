import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../bloc/ai_chat_state.dart';

part 'ai_chat_provider.g.dart';

/// Provider pro AiChatRepository
@riverpod
AiChatRepository aiChatRepository(AiChatRepositoryRef ref) {
  throw UnimplementedError('AiChatRepository musí být implementován');
}

/// Riverpod Notifier pro AI chat
///
/// Nahrazuje původní AiChatBloc
/// Používá family pattern pro podporu task contextu
@riverpod
class AiChat extends _$AiChat {
  TaskContext? _taskContext;

  @override
  AiChatState build({TaskContext? taskContext}) {
    _taskContext = taskContext;
    return const AiChatInitial();
  }

  /// Poslat zprávu AI
  Future<void> sendMessage(String message) async {
    // Validace
    if (message.trim().isEmpty) {
      return;
    }

    final currentState = state;

    // Přidat user message
    final userMessage = ChatMessage.user(message);
    final messages = currentState is AiChatLoaded
        ? [...currentState.messages, userMessage]
        : [userMessage];

    // Emit loading state (AI typing)
    state = AiChatLoaded(messages: messages, isTyping: true);

    try {
      final repository = ref.read(aiChatRepositoryProvider);

      // Zavolat repository
      final aiResponse = await repository.sendMessage(
        taskContext: _taskContext,
        messages: messages.sublist(0, messages.length - 1), // Bez poslední user message
        userMessage: message,
      );

      // Přidat AI response
      final updatedMessages = [...messages, aiResponse];

      // Emit loaded state
      state = AiChatLoaded(messages: updatedMessages, isTyping: false);

      AppLogger.info('✅ AI chat message sent');
    } catch (e) {
      AppLogger.error('Chyba při komunikaci s AI: $e');
      state = AiChatError(e.toString());
    }
  }

  /// Vymazat chat
  void clearChat() {
    state = const AiChatInitial();
    AppLogger.debug('🗑️ Chat cleared');
  }

  /// Načíst historii (optional)
  Future<void> loadChatHistory() async {
    // Nelze načíst historii bez task contextu
    if (_taskContext == null) {
      return;
    }

    try {
      final repository = ref.read(aiChatRepositoryProvider);

      final messages = await repository.loadChatHistory(_taskContext!.todo.id!);
      if (messages.isNotEmpty) {
        state = AiChatLoaded(messages: messages);
        AppLogger.debug('✅ Chat history loaded: ${messages.length} messages');
      }
    } catch (e) {
      AppLogger.error('Chyba při načítání historie: $e');
      state = AiChatError(e.toString());
    }
  }
}

/// Helper provider: získat chat messages
@riverpod
List<ChatMessage> chatMessages(ChatMessagesRef ref, {TaskContext? taskContext}) {
  final chatState = ref.watch(aiChatProvider(taskContext: taskContext));

  if (chatState is AiChatLoaded) {
    return chatState.messages;
  }
  return [];
}

/// Helper provider: je AI typing?
@riverpod
bool isAiTyping(IsAiTypingRef ref, {TaskContext? taskContext}) {
  final chatState = ref.watch(aiChatProvider(taskContext: taskContext));

  if (chatState is AiChatLoaded) {
    return chatState.isTyping;
  }
  return false;
}
