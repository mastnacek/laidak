import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/enums/sort_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// SortBar - Kompaktní sort controls s triple-toggle (DESC → ASC → OFF)
///
/// Specifikace:
/// - Height: 48dp
/// - Icon size: 20dp (kompaktní)
/// - Touch target: 44x44dp
/// - Spacing: 8dp
/// - Triple toggle: DESC (🔴↓) → ASC (🔴↑) → OFF
class SortBar extends StatelessWidget {
  const SortBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro řazení úkolů',
      container: true,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: theme.appColors.bgAlt,
          border: Border(
            top: BorderSide(
              color: theme.appColors.base3,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BlocBuilder<TodoListBloc, TodoListState>(
            builder: (context, state) {
            final currentSortMode =
                state is TodoListLoaded ? state.sortMode : null;
            final currentDirection = state is TodoListLoaded
                ? state.sortDirection
                : SortDirection.desc;

            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: SortMode.values.map((mode) {
                final isActive = mode == currentSortMode;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: IconButton(
                    icon: _buildSortIcon(
                      mode,
                      isActive,
                      currentDirection,
                      theme,
                    ),
                    tooltip: _buildTooltip(mode, isActive, currentDirection),
                    color: isActive
                        ? theme.appColors.yellow
                        : theme.appColors.base5,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final bloc = context.read<TodoListBloc>();

                      // Triple toggle logic:
                      // 1. First click: DESC
                      // 2. Second click: ASC
                      // 3. Third click: OFF (clear sort)
                      if (!isActive) {
                        // Activate with DESC
                        bloc.add(SortTodosEvent(mode, SortDirection.desc));
                      } else if (currentDirection == SortDirection.desc) {
                        // Switch to ASC
                        bloc.add(SortTodosEvent(mode, SortDirection.asc));
                      } else {
                        // Clear sort
                        bloc.add(const ClearSortEvent());
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
          ),
        ),
      ),
    );
  }

  Widget _buildSortIcon(
    SortMode mode,
    bool isActive,
    SortDirection direction,
    ThemeData theme,
  ) {
    if (!isActive) {
      // Inactive: just the mode icon
      return Icon(mode.icon, size: 20);
    }

    // Active: icon with animated arrow overlay
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(mode.icon, size: 20),
        Positioned(
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: direction == SortDirection.desc ? 0 : 3.14159, // 180° rotation
            ),
            builder: (context, angle, child) {
              return Transform.rotate(
                angle: angle,
                child: Icon(
                  Icons.arrow_downward,
                  size: 10,
                  color: theme.appColors.yellow,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildTooltip(
    SortMode mode,
    bool isActive,
    SortDirection direction,
  ) {
    final directionText = direction == SortDirection.desc
        ? 'sestupně'
        : 'vzestupně';

    if (!isActive) {
      return mode.label;
    }

    return '${mode.label} ($directionText)';
  }
}
