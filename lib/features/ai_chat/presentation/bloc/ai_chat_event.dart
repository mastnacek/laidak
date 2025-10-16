import 'package:equatable/equatable.dart';

/// Events pro AI chat
sealed class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

/// Poslat zprávu AI
final class SendMessageEvent extends AiChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Vymazat chat historii
final class ClearChatEvent extends AiChatEvent {
  const ClearChatEvent();
}

/// Načíst historii z DB (optional)
final class LoadChatHistoryEvent extends AiChatEvent {
  const LoadChatHistoryEvent();
}
