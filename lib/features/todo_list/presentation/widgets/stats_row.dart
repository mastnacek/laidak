import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_state.dart';

/// StatsRow - Kompaktní stats dashboard pro AppBar
///
/// Specifikace:
/// - Height: 56dp (standard AppBar)
/// - Icon size: 16dp (malé stats ikony)
/// - Font size: 14dp (čísla)
/// - Jeden řádek: [✅5] [🔴12] [📅3] [⏰7]
/// - Real-time update přes BlocBuilder
class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        if (state is! TodoListLoaded) {
          return const SizedBox();
        }

        final stats = _computeStats(state);

        return Semantics(
          label:
              'Statistiky úkolů: ${stats.completed} hotových, ${stats.active} aktivních, ${stats.today} dnes, ${stats.week} tento týden',
          container: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatChip(
                icon: Icons.check_circle,
                count: stats.completed,
                tooltip: 'Hotové úkoly',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.flag,
                count: stats.active,
                tooltip: 'Aktivní úkoly',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.today,
                count: stats.today,
                tooltip: 'Úkoly dnes',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.date_range,
                count: stats.week,
                tooltip: 'Úkoly tento týden',
              ),
            ],
          ),
        );
      },
    );
  }

  _TodoStats _computeStats(TodoListLoaded state) {
    final todos = state.allTodos; // Fix: použít allTodos místo todos
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    return _TodoStats(
      completed: todos.where((t) => t.isCompleted).length,
      active: todos.where((t) => !t.isCompleted).length,
      today: todos.where((t) {
        if (t.dueDate == null) return false;
        final dueDay = DateTime(
          t.dueDate!.year,
          t.dueDate!.month,
          t.dueDate!.day,
        );
        return dueDay == today;
      }).length,
      week: todos.where((t) {
        if (t.dueDate == null) return false;
        final dueDay = DateTime(
          t.dueDate!.year,
          t.dueDate!.month,
          t.dueDate!.day,
        );
        return dueDay.isAfter(today.subtract(const Duration(days: 1))) &&
            dueDay.isBefore(weekEnd);
      }).length,
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.base2.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16, // Malé ikony
              color: theme.appColors.base5,
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14, // Kompaktní číslice
                fontWeight: FontWeight.bold,
                color: theme.appColors.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoStats {
  final int completed;
  final int active;
  final int today;
  final int week;

  const _TodoStats({
    required this.completed,
    required this.active,
    required this.today,
    required this.week,
  });
}
