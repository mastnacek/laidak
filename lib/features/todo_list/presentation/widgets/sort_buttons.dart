import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/enums/sort_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// Widget pro Sort tlačítka (kompaktní ikony)
///
/// Umístění: Pod views tlačítky, kompaktní řada ikon
///
/// ```
/// ┌─────────────────────────────────────────────────┐
/// │  Sort:  🔴↓  │  📅↓  │  ✅  │  🆕  │
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SortMode.values
                  .map((mode) => _SortButton(
                        sortMode: mode,
                        currentSortMode: currentSortMode,
                        currentDirection: currentDirection,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Individual Sort Button (kompaktní ikona s tooltipem)
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

    return Tooltip(
      message: sortMode.label,
      preferBelow: false, // Zobrazit tooltip NAD ikonkou (ne pod prstem)
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? theme.appColors.yellow.withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: theme.appColors.yellow, width: 2)
                : Border.all(color: theme.appColors.base3, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sortMode.icon,
                size: 18,
                color: isActive ? theme.appColors.yellow : theme.appColors.base5,
              ),
              if (isActive) ...[
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: currentDirection == SortDirection.desc ? 0 : 0.5,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 12,
                    color: theme.appColors.yellow,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
