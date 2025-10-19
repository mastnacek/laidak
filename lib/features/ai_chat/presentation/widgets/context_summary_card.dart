import 'package:flutter/material.dart';
import '../../domain/entities/task_context.dart';

/// Kompaktní summary úkolu (nahoře v chatu)
class ContextSummaryCard extends StatefulWidget {
  final TaskContext taskContext;

  const ContextSummaryCard({
    super.key,
    required this.taskContext,
  });

  @override
  State<ContextSummaryCard> createState() => _ContextSummaryCardState();
}

class _ContextSummaryCardState extends State<ContextSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todo = widget.taskContext.todo;

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text('📋 ${todo.task}'),
        subtitle: _buildSummaryLine(),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubtasksList(),
                const SizedBox(height: 12),
                _buildPomodoroSummary(),
                const SizedBox(height: 12),
                _buildAIMetadata(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine() {
    final todo = widget.taskContext.todo;
    final subtasks = widget.taskContext.subtasks;
    final pomodoro = widget.taskContext.pomodoroSessions;

    final parts = <String>[];

    if (todo.priority != null) {
      parts.add('${todo.priority!.toUpperCase()}');
    }

    if (todo.dueDate != null) {
      parts.add('⏰ ${_formatDate(todo.dueDate!)}');
    }

    if (subtasks.isNotEmpty) {
      final completed = widget.taskContext.completedSubtasks;
      parts.add('$completed/${subtasks.length} podúkolů');
    }

    if (pomodoro.isNotEmpty) {
      parts.add('🍅 ${pomodoro.length}x');
    }

    return Text(parts.join(' │ '));
  }

  Widget _buildSubtasksList() {
    final subtasks = widget.taskContext.subtasks;
    if (subtasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Podúkoly:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...subtasks.map((subtask) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${subtask.completed ? "✅" : "☐"} ${subtask.subtaskNumber}. ${subtask.text}',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPomodoroSummary() {
    final sessions = widget.taskContext.pomodoroSessions;
    if (sessions.isEmpty) return const SizedBox.shrink();

    final totalMinutes = widget.taskContext.totalPomodoroMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pomodoro:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('🍅 ${sessions.length} sessions ($totalMinutes minut celkem)'),
      ],
    );
  }

  Widget _buildAIMetadata() {
    final todo = widget.taskContext.todo;
    final hasRecommendations =
        todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty;
    final hasDeadlineAnalysis = todo.aiDeadlineAnalysis != null &&
        todo.aiDeadlineAnalysis!.isNotEmpty;

    if (!hasRecommendations && !hasDeadlineAnalysis) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRecommendations) ...[
          const Text(
            'AI Doporučení:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(todo.aiRecommendations!),
          const SizedBox(height: 8),
        ],
        if (hasDeadlineAnalysis) ...[
          const Text(
            'AI Analýza termínu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(todo.aiDeadlineAnalysis!),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
