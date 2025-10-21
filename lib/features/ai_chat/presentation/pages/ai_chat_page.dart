import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../ai_split/domain/entities/subtask.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';
import '../../domain/entities/task_context.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/context_summary_card.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';

/// AI Chat Page - konverzace s AI asistentem
///
/// Dva režimy:
/// 1. Standalone mode: obecný chat bez kontextu úkolu (taskContext = null)
/// 2. Task-specific mode: chat s kontextem konkrétního úkolu (taskContext != null)
class AiChatPage extends StatelessWidget {
  /// Task context (optional) - pokud null, jde o standalone chat
  final TaskContext? taskContext;

  /// Constructor pro task-specific chat
  AiChatPage.withTask({
    super.key,
    required Todo todo,
    List<Subtask> subtasks = const [],
    List<PomodoroSession> pomodoroSessions = const [],
  }) : taskContext = TaskContext(
          todo: todo,
          subtasks: subtasks,
          pomodoroSessions: pomodoroSessions,
        );

  /// Constructor pro standalone chat
  const AiChatPage.standalone({super.key}) : taskContext = null;

  @override
  Widget build(BuildContext context) {
    return _AiChatPageView(taskContext: taskContext);
  }
}

/// Internal view widget
class _AiChatPageView extends ConsumerStatefulWidget {
  final TaskContext? taskContext;

  const _AiChatPageView({required this.taskContext});

  @override
  ConsumerState<_AiChatPageView> createState() => _AiChatPageViewState();
}

class _AiChatPageViewState extends ConsumerState<_AiChatPageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to bottom (po přidání nové zprávy)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // AiChatPage už NENÍ Scaffold - je child widgetem MainPage PageView!
    // AppBar je v MainPage, zde pouze body content

    // Padding pro klávesnici
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Column(
        children: [
          // Context Summary Card (top) - pouze pokud je task context
          if (widget.taskContext != null) ...[
            ContextSummaryCard(taskContext: widget.taskContext!),
            const Divider(height: 1),
          ],

          // Chat Messages (scrollable)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                // Listen for state changes to auto-scroll
                ref.listen<AiChatState>(
                  aiChatProvider(taskContext: widget.taskContext),
                  (previous, state) {
                    // Auto-scroll po přidání zprávy
                    if (state is AiChatLoaded) {
                      _scrollToBottom();
                    }
                  },
                );

                final state = ref.watch(aiChatProvider(taskContext: widget.taskContext));

                if (state is AiChatInitial) {
                  return _buildEmptyState();
                }

                if (state is AiChatError) {
                  return _buildErrorState(state.message);
                }

                if (state is AiChatLoaded) {
                  return _buildChatList(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          const Divider(height: 1),

          // Chat Input (bottom) - s paddingem pro klávesnici
          Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: ChatInput(
              onSend: (message) {
                ref.read(aiChatProvider(taskContext: widget.taskContext).notifier).sendMessage(message);
              },
            ),
          ),
        ],
    );
  }

  /// Empty state - první návštěva chatu
  Widget _buildEmptyState() {
    final isTaskMode = widget.taskContext != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isTaskMode
                  ? '💬 Jak ti můžu pomoct s tímto úkolem?'
                  : '💬 Ahoj! Jak ti můžu pomoct?',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTaskMode
                  ? 'Zeptej se na cokoliv - plánování, rozdělení úkolu, tipy na efektivitu...'
                  : 'Zeptej se na cokoliv - můžu ti pomoct s produktivitou, time managementem, nebo čímkoliv jiným...',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Chyba',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Chat list
  Widget _buildChatList(AiChatLoaded state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator na konci
        if (state.isTyping && index == state.messages.length) {
          return const TypingIndicator();
        }

        final message = state.messages[index];
        return ChatMessageBubble(message: message);
      },
    );
  }
}
