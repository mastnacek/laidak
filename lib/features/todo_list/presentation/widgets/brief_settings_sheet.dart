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
  late bool _includeCompletedToday;
  late bool _includeCompletedWeek;
  late bool _includeCompletedMonth;
  late bool _includeCompletedYear;
  late bool _includeCompletedAll;

  @override
  void initState() {
    super.initState();

    // Načíst aktuální config ze state
    final state = context.read<TodoListBloc>().state;
    if (state is TodoListLoaded) {
      _includeSubtasks = state.briefConfig.includeSubtasks;
      _includePomodoroStats = state.briefConfig.includePomodoroStats;
      _includeCompletedToday = state.briefConfig.includeCompletedToday;
      _includeCompletedWeek = state.briefConfig.includeCompletedWeek;
      _includeCompletedMonth = state.briefConfig.includeCompletedMonth;
      _includeCompletedYear = state.briefConfig.includeCompletedYear;
      _includeCompletedAll = state.briefConfig.includeCompletedAll;
    } else {
      // Fallback na default
      _includeSubtasks = true;
      _includePomodoroStats = true;
      _includeCompletedToday = true;
      _includeCompletedWeek = true;
      _includeCompletedMonth = false;
      _includeCompletedYear = false;
      _includeCompletedAll = false;
    }
  }

  void _saveSettings() {
    final state = context.read<TodoListBloc>().state;
    if (state is! TodoListLoaded) return;

    // Vytvořit nový config s updated hodnotami
    final newConfig = state.briefConfig.copyWith(
      includeSubtasks: _includeSubtasks,
      includePomodoroStats: _includePomodoroStats,
      includeCompletedToday: _includeCompletedToday,
      includeCompletedWeek: _includeCompletedWeek,
      includeCompletedMonth: _includeCompletedMonth,
      includeCompletedYear: _includeCompletedYear,
      includeCompletedAll: _includeCompletedAll,
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

          // === CONTEXT SECTION ===
          Text(
            'Kontext',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

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

          // === COMPLETED TASKS SECTION ===
          Text(
            'Splněné úkoly',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Completed Today toggle
          SwitchListTile(
            value: _includeCompletedToday,
            onChanged: (value) {
              setState(() {
                _includeCompletedToday = value;
              });
            },
            title: Text(
              'Dnes',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Úkoly splněné dnes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          // Completed Week toggle
          SwitchListTile(
            value: _includeCompletedWeek,
            onChanged: (value) {
              setState(() {
                _includeCompletedWeek = value;
              });
            },
            title: Text(
              'Tento týden',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Úkoly splněné tento týden',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          // Completed Month toggle
          SwitchListTile(
            value: _includeCompletedMonth,
            onChanged: (value) {
              setState(() {
                _includeCompletedMonth = value;
              });
            },
            title: Text(
              'Tento měsíc',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Úkoly splněné tento měsíc',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          // Completed Year toggle
          SwitchListTile(
            value: _includeCompletedYear,
            onChanged: (value) {
              setState(() {
                _includeCompletedYear = value;
              });
            },
            title: Text(
              'Letos',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Úkoly splněné letos',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 8),

          // Completed All toggle
          SwitchListTile(
            value: _includeCompletedAll,
            onChanged: (value) {
              setState(() {
                _includeCompletedAll = value;
              });
            },
            title: Text(
              'Všechny splněné',
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text(
              'Všechny splněné úkoly (ignoruje ostatní timeframes)',
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
