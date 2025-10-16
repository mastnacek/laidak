import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../cubit/ai_split_cubit.dart';
import 'ai_split_dialog.dart';

/// 🤖 ikona v edit režimu
/// Po kliknutí otevře AI Split Dialog
class AiSplitButton extends StatelessWidget {
  final Todo todo;

  const AiSplitButton({
    super.key,
    required this.todo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: const Icon(Icons.smart_toy, size: 24),
      color: theme.appColors.cyan,
      tooltip: 'AI rozděl úkol',
      onPressed: () => _showAiSplitDialog(context),
    );
  }

  /// Zobrazit AI Split Dialog
  void _showAiSplitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AiSplitCubit>(),
        child: AiSplitDialog(todo: todo),
      ),
    );
  }
}
