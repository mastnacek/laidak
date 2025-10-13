import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/database_helper.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../ai_split/domain/entities/subtask.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';
import '../../data/datasources/openrouter_chat_datasource.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../domain/entities/task_context.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';
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
    // Použít task context pokud existuje, jinak null
    final effectiveTaskContext = taskContext;

    // Vytvořit repository
    final repository = AiChatRepositoryImpl(
      dataSource: OpenRouterChatDataSource(),
      db: DatabaseHelper(),
    );

    return BlocProvider(
      create: (_) => AiChatBloc(
        repository: repository,
        taskContext: effectiveTaskContext,
      ),
      child: _AiChatPageView(taskContext: effectiveTaskContext),
    );
  }
}

/// Internal view widget
class _AiChatPageView extends StatefulWidget {
  final TaskContext? taskContext;

  const _AiChatPageView({required this.taskContext});

  @override
  State<_AiChatPageView> createState() => _AiChatPageViewState();
}

class _AiChatPageViewState extends State<_AiChatPageView> {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskContext != null
              ? '🤖 AI Chat: ${widget.taskContext!.todo.task}'
              : '🤖 AI Chat',
        ),
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vymazat chat',
            onPressed: () {
              context.read<AiChatBloc>().add(const ClearChatEvent());
            },
          ),
          // Info button (expand context summary)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Zobrazit kontext',
            onPressed: () {
              // TODO: Scroll to top / expand summary
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Summary Card (top) - pouze pokud je task context
          if (widget.taskContext != null) ...[
            ContextSummaryCard(taskContext: widget.taskContext!),
            const Divider(height: 1),
          ],

          // Chat Messages (scrollable)
          Expanded(
            child: BlocConsumer<AiChatBloc, AiChatState>(
              listener: (context, state) {
                // Auto-scroll po přidání zprávy
                if (state is AiChatLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
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

          // Chat Input (bottom)
          ChatInput(
            onSend: (message) {
              context.read<AiChatBloc>().add(SendMessageEvent(message));
            },
          ),
        ],
      ),
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
