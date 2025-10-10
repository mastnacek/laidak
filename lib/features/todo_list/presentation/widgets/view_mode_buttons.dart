import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/enums/view_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// Widget pro Views tlačítka (kompaktní ikony)
///
/// Umístění: Pod input boxem, horizontální řada ikon
///
/// ```
/// ┌─────────────────────────────────────────────────┐
/// │  📋  │  📅  │  🗓️  │  ⏰  │  ⚠️  │
/// └─────────────────────────────────────────────────┘
/// ```
///
/// **Chování:**
/// - **Selected state:** Barevné pozadí (theme accent)
/// - **Unselected state:** Transparentní
/// - **One-click toggle:** Klik na tlačítko → aktivovat view
/// - **Deselect:** Klik na aktivní tlačítko → deaktivovat (vrátit na "Všechny")
/// - **Tooltips:** Zobrazení názvu při hover (accessibility)
///
/// **Animace:**
/// - Smooth transition (200ms) při přepínání
/// - Ripple effect při kliku
class ViewModeButtons extends StatelessWidget {
  const ViewModeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        final currentViewMode =
            state is TodoListLoaded ? state.viewMode : ViewMode.all;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ViewMode.values
                  .map((mode) => _ViewChip(
                        viewMode: mode,
                        isSelected: currentViewMode == mode,
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Individual View Button (kompaktní ikona s tooltipem)
class _ViewChip extends StatelessWidget {
  final ViewMode viewMode;
  final bool isSelected;

  const _ViewChip({
    required this.viewMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      richMessage: WidgetSpan(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(viewMode.icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(viewMode.label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      preferBelow: false, // Zobrazit tooltip NAD ikonkou (ne pod prstem)
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () {
            final bloc = context.read<TodoListBloc>();

            // One-click toggle: Klik na aktivní tlačítko → vrátit na ViewMode.all
            if (isSelected && viewMode != ViewMode.all) {
              bloc.add(const ChangeViewModeEvent(ViewMode.all));
            } else {
              bloc.add(ChangeViewModeEvent(viewMode));
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.appColors.yellow.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? theme.appColors.yellow : theme.appColors.base3,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              viewMode.icon,
              size: 20,
              color: isSelected ? theme.appColors.yellow : theme.appColors.base5,
            ),
          ),
        ),
      ),
    );
  }
}
