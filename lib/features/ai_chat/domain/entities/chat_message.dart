import 'package:equatable/equatable.dart';

/// Message v AI chat konverzaci
class ChatMessage extends Equatable {
  /// Unique ID (pro ListView keys)
  final String id;

  /// Role: 'user' nebo 'assistant'
  final String role;

  /// Obsah zprávy
  final String content;

  /// Timestamp
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Factory pro user message
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Factory pro AI assistant message
  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Je to user message?
  bool get isUser => role == 'user';

  /// Je to AI message?
  bool get isAssistant => role == 'assistant';

  @override
  List<Object?> get props => [id, role, content, timestamp];
}
