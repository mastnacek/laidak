import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/subtask.dart';

/// Widget pro zobrazení subtasks v TodoCard
/// Zobrazuje seznam podúkolů s možností toggle a delete
class SubtaskListView extends StatelessWidget {
  final List<Subtask> subtasks;
  final void Function(int subtaskId, bool completed) onToggle;
  final void Function(int subtaskId) onDelete;

  const SubtaskListView({
    super.key,
    required this.subtasks,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = subtasks.where((s) => s.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header s progress
        Row(
          children: [
            Icon(Icons.checklist, color: theme.appColors.cyan, size: 16),
            const SizedBox(width: 8),
            Text(
              'PODÚKOLY ($completedCount/${subtasks.length} hotovo)',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Seznam subtasks
        ...subtasks.map((subtask) => _SubtaskItem(
              subtask: subtask,
              onToggle: onToggle,
              onDelete: onDelete,
            )),
      ],
    );
  }
}

/// Privátní widget pro jeden subtask item
class _SubtaskItem extends StatelessWidget {
  final Subtask subtask;
  final void Function(int subtaskId, bool completed) onToggle;
  final void Function(int subtaskId) onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: subtask.completed,
            onChanged: (value) => onToggle(subtask.id!, value ?? false),
            activeColor: theme.appColors.green,
          ),

          // Text
          Expanded(
            child: Text(
              '${subtask.subtaskNumber}. ${subtask.text}',
              style: TextStyle(
                color: subtask.completed
                    ? theme.appColors.base5
                    : theme.appColors.fg,
                decoration: subtask.completed
                    ? TextDecoration.lineThrough
                    : null,
                fontSize: 14,
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete, color: theme.appColors.red, size: 18),
            onPressed: () => onDelete(subtask.id!),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
