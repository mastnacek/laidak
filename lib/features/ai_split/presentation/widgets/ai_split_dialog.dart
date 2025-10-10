import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../todo_list/presentation/bloc/todo_list_bloc.dart';
import '../../../todo_list/presentation/bloc/todo_list_event.dart';
import '../cubit/ai_split_cubit.dart';
import '../cubit/ai_split_state.dart';

/// Dialog pro AI rozdělení úkolu
/// Zobrazuje loading, výsledek AI analýzy nebo error
class AiSplitDialog extends StatefulWidget {
  final Todo todo;

  const AiSplitDialog({super.key, required this.todo});

  @override
  State<AiSplitDialog> createState() => _AiSplitDialogState();
}

class _AiSplitDialogState extends State<AiSplitDialog> {
  final _retryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Zavolat AI hned při otevření dialogu
    context.read<AiSplitCubit>().splitTask(
          taskId: widget.todo.id!,
          taskText: widget.todo.task,
          priority: widget.todo.priority,
          deadline: widget.todo.dueDate,
          tags: widget.todo.tags,
        );
  }

  @override
  void dispose() {
    _retryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.cyan, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: BlocConsumer<AiSplitCubit, AiSplitState>(
          listener: (context, state) {
            // Po akceptaci zavřít dialog a refreshnout todo list
            if (state is AiSplitAccepted) {
              // Reload todo list pro zobrazení nových subtasků
              context.read<TodoListBloc>().add(const LoadTodosEvent());

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.appColors.green,
                ),
              );
              Navigator.of(context).pop();
            }
            // Po odmítnutí zavřít dialog
            else if (state is AiSplitRejected) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const Divider(height: 24),
                Expanded(
                  child: _buildBody(context, state, theme),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Header dialogu
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.smart_toy, color: theme.appColors.cyan, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '🤖 AI ROZDĚLENÍ ÚKOLU',
            style: TextStyle(
              color: theme.appColors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.appColors.base5),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Body dialogu - switch podle stavu
  Widget _buildBody(BuildContext context, AiSplitState state, ThemeData theme) {
    return switch (state) {
      AiSplitLoading() => _buildLoading(state, theme),
      AiSplitLoaded() => _buildLoaded(context, state, theme),
      AiSplitError() => _buildError(state, theme),
      _ => const SizedBox.shrink(),
    };
  }

  /// Loading state
  Widget _buildLoading(AiSplitLoading state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.appColors.cyan),
          const SizedBox(height: 16),
          Text(
            'AI analyzuje úkol...',
            style: TextStyle(color: theme.appColors.fg),
          ),
          const SizedBox(height: 8),
          Text(
            'Model: ${state.model}',
            style: TextStyle(color: theme.appColors.base5, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Loaded state - zobrazení návrhů
  Widget _buildLoaded(
      BuildContext context, AiSplitLoaded state, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podúkoly
          if (state.response.subtasks.isNotEmpty) ...[
            Text(
              '📋 PODÚKOLY:',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...state.response.subtasks.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}.',
                      style: TextStyle(
                        color: theme.appColors.base5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: theme.appColors.fg),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Doporučení
          if (state.response.recommendations.isNotEmpty) ...[
            Text(
              '💡 DOPORUČENÍ:',
              style: TextStyle(
                color: theme.appColors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.response.recommendations,
              style: TextStyle(color: theme.appColors.fg),
            ),
            const SizedBox(height: 16),
          ],

          // Analýza termínu
          if (state.response.deadlineAnalysis.isNotEmpty) ...[
            Text(
              '⏰ TERMÍN:',
              style: TextStyle(
                color: theme.appColors.magenta,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.response.deadlineAnalysis,
              style: TextStyle(color: theme.appColors.fg),
            ),
            const SizedBox(height: 24),
          ],

          // Retry s poznámkou
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _retryController,
                  style: TextStyle(color: theme.appColors.fg),
                  decoration: InputDecoration(
                    hintText: 'Poznámka pro retry...',
                    hintStyle: TextStyle(color: theme.appColors.base5),
                    filled: true,
                    fillColor: theme.appColors.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base4),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh, color: theme.appColors.yellow),
                      onPressed: () => _retry(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accept / Reject
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    context.read<AiSplitCubit>().rejectSuggestion(),
                child: Text('Zrušit',
                    style: TextStyle(color: theme.appColors.base5)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () =>
                    context.read<AiSplitCubit>().acceptSuggestion(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appColors.green,
                  foregroundColor: theme.appColors.bg,
                ),
                child: const Text('Přijmout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildError(AiSplitError state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.appColors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Chyba',
            style: TextStyle(
              color: theme.appColors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.appColors.fg),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.base3,
            ),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  /// Retry s poznámkou
  void _retry(BuildContext context) {
    final note = _retryController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadejte poznámku pro retry')),
      );
      return;
    }

    context.read<AiSplitCubit>().retrySuggestion(
          taskId: widget.todo.id!,
          taskText: widget.todo.task,
          userNote: note,
          priority: widget.todo.priority,
          deadline: widget.todo.dueDate,
          tags: widget.todo.tags,
        );

    _retryController.clear();
  }
}
