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
    return GestureDetector(
      onTap: () => _showAiSplitDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Text('🤖', style: TextStyle(fontSize: 24)),
      ),
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
