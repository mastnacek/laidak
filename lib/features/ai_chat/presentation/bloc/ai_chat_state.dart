import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

/// States pro AI chat
sealed class AiChatState extends Equatable {
  const AiChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state - prázdný chat
final class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

/// Loaded state - konverzace běží
final class AiChatLoaded extends AiChatState {
  /// Historie zpráv
  final List<ChatMessage> messages;

  /// AI právě odpovídá?
  final bool isTyping;

  const AiChatLoaded({
    required this.messages,
    this.isTyping = false,
  });

  AiChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return AiChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping];
}

/// Error state
final class AiChatError extends AiChatState {
  final String message;

  const AiChatError(this.message);

  @override
  List<Object?> get props => [message];
}
