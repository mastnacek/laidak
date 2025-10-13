import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/ai_brief/domain/entities/brief_config.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// Bottom sheet pro nastavení AI Brief
///
/// MVP verze s 2 toggle switches:
/// - Include Subtasks
/// - Include Pomodoro Stats
class BriefSettingsSheet extends StatefulWidget {
  const BriefSettingsSheet({super.key});

  @override
  State<BriefSettingsSheet> createState() => _BriefSettingsSheetState();
}

class _BriefSettingsSheetState extends State<BriefSettingsSheet> {
  late bool _includeSubtasks;
  late bool _includePomodoroStats;

  @override
  void initState() {
    super.initState();

    // Načíst aktuální config ze state
    final state = context.read<TodoListBloc>().state;
    if (state is TodoListLoaded) {
      _includeSubtasks = state.briefConfig.includeSubtasks;
      _includePomodoroStats = state.briefConfig.includePomodoroStats;
    } else {
      // Fallback na default
      _includeSubtasks = true;
      _includePomodoroStats = true;
    }
  }

  void _saveSettings() {
    final state = context.read<TodoListBloc>().state;
    if (state is! TodoListLoaded) return;

    // Vytvořit nový config s updated hodnotami
    final newConfig = state.briefConfig.copyWith(
      includeSubtasks: _includeSubtasks,
      includePomodoroStats: _includePomodoroStats,
    );

    // Dispatch event pro update
    context.read<TodoListBloc>().add(UpdateBriefConfigEvent(newConfig));

    // Zavřít bottom sheet
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Brief Nastavení',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Include Subtasks toggle
          SwitchListTile(
            value: _includeSubtasks,
            onChanged: (value) {
              setState(() {
                _includeSubtasks = value;
              });
            },
            title: Text(
              'Zahrnout subtasky',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'AI uvidí progress subtasků',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          // Include Pomodoro toggle
          SwitchListTile(
            value: _includePomodoroStats,
            onChanged: (value) {
              setState(() {
                _includePomodoroStats = value;
              });
            },
            title: Text(
              'Zahrnout Pomodoro statistiky',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'AI bude znát tvé pracovní vzorce',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Uložit nastavení',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Safe area padding pro bottom notch
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
