import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

/// BLoC pro AI chat
class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiChatRepository repository;
  final TaskContext? taskContext;

  AiChatBloc({
    required this.repository,
    required this.taskContext,
  }) : super(const AiChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
  }

  /// Poslat zprávu AI
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final currentState = state;

    // Validace
    if (event.message.trim().isEmpty) {
      return;
    }

    // Přidat user message
    final userMessage = ChatMessage.user(event.message);
    final messages = currentState is AiChatLoaded
        ? [...currentState.messages, userMessage]
        : [userMessage];

    // Emit loading state (AI typing)
    emit(AiChatLoaded(messages: messages, isTyping: true));

    try {
      // Zavolat repository
      final aiResponse = await repository.sendMessage(
        taskContext: taskContext,
        messages: messages.sublist(0, messages.length - 1), // Bez poslední user message
        userMessage: event.message,
      );

      // Přidat AI response
      final updatedMessages = [...messages, aiResponse];

      // Emit loaded state
      emit(AiChatLoaded(messages: updatedMessages, isTyping: false));
    } catch (e) {
      emit(AiChatError('Chyba při komunikaci s AI: $e'));
    }
  }

  /// Vymazat chat
  void _onClearChat(ClearChatEvent event, Emitter<AiChatState> emit) {
    emit(const AiChatInitial());
  }

  /// Načíst historii (optional)
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<AiChatState> emit,
  ) async {
    // Nelze načíst historii bez task contextu
    if (taskContext == null) {
      return;
    }

    try {
      final messages = await repository.loadChatHistory(taskContext!.todo.id!);
      if (messages.isNotEmpty) {
        emit(AiChatLoaded(messages: messages));
      }
    } catch (e) {
      emit(AiChatError('Chyba při načítání historie: $e'));
    }
  }
}
