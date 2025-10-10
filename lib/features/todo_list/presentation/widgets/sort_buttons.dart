import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/enums/sort_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// Widget pro Sort tlačítka (kompaktní ikony + text)
///
/// Umístění: Pod views tlačítky, menší řada
///
/// ```
/// ┌─────────────────────────────────────────────────┐
/// │  Sort:  🔴 Priorita ↓  │  📅 Deadline ↓  │  ✅ Status  │  🆕 Datum  │
/// └─────────────────────────────────────────────────┘
/// ```
///
/// **Chování:**
/// - **One-click toggle direction**: První klik → DESC, druhý klik → ASC, třetí klik → OFF (default sort)
/// - **Vizuální feedback:**
///   - Active sort: Barevné pozadí + šipka (↓/↑)
///   - Inactive: Šedé, bez šipky
///
/// **Animace:**
/// - Šipka rotuje 180° při změně směru (smooth rotation)
/// - Ripple effect při kliku
///
/// **Sort Modes:**
/// 1. 🔴 Priorita (`SortMode.priority`) - a > b > c
/// 2. 📅 Deadline (`SortMode.dueDate`) - podle dueDate
/// 3. ✅ Status (`SortMode.status`) - completed vs. active
/// 4. 🆕 Datum (`SortMode.createdAt`) - podle data vytvoření
class SortButtons extends StatelessWidget {
  const SortButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        final currentSortMode =
            state is TodoListLoaded ? state.sortMode : null;
        final currentDirection =
            state is TodoListLoaded ? state.sortDirection : SortDirection.desc;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Label "Sort:"
                Text(
                  'Sort:',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.appColors.base5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),

                // Sort buttons
                ...SortMode.values.map((mode) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SortButton(
                        sortMode: mode,
                        currentSortMode: currentSortMode,
                        currentDirection: currentDirection,
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Individual Sort Button
class _SortButton extends StatelessWidget {
  final SortMode sortMode;
  final SortMode? currentSortMode;
  final SortDirection currentDirection;

  const _SortButton({
    required this.sortMode,
    required this.currentSortMode,
    required this.currentDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = sortMode == currentSortMode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        final bloc = context.read<TodoListBloc>();

        if (!isActive) {
          // První klik → aktivovat DESC
          bloc.add(SortTodosEvent(sortMode, SortDirection.desc));
        } else if (currentDirection == SortDirection.desc) {
          // Druhý klik → přepnout na ASC
          bloc.add(SortTodosEvent(sortMode, SortDirection.asc));
        } else {
          // Třetí klik → deaktivovat (null sort = default)
          bloc.add(const ClearSortEvent());
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.appColors.yellow.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: theme.appColors.yellow, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sortMode.icon,
              size: 16,
              color: isActive ? theme.appColors.yellow : theme.appColors.base5,
            ),
            const SizedBox(width: 4),
            Text(
              sortMode.label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? theme.appColors.fg : theme.appColors.base5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: currentDirection == SortDirection.desc ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: theme.appColors.yellow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
