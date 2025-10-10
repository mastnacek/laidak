import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../domain/enums/view_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// ViewBar - Kompaktní view mode selector s visibility toggle
///
/// Specifikace:
/// - Height: 56dp
/// - Icon size: 20-22dp (menší než dříve)
/// - Eye icon: 24dp (větší než ostatní)
/// - Touch target: 44x44dp
/// - Spacing: 6-8dp
class ViewBar extends StatelessWidget {
  const ViewBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro výběr zobrazení úkolů',
      container: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          child: Row(
            children: [
            // View mode buttons (kompaktní ikony)
            Expanded(
              child: BlocBuilder<TodoListBloc, TodoListState>(
                builder: (context, state) {
                  final currentViewMode =
                      state is TodoListLoaded ? state.viewMode : ViewMode.all;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: ViewMode.values.map((mode) {
                      final isSelected = currentViewMode == mode;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            final bloc = context.read<TodoListBloc>();
                            // One-click toggle: klik na selected = All mode
                            if (isSelected && mode != ViewMode.all) {
                              bloc.add(const ChangeViewModeEvent(ViewMode.all));
                            } else {
                              bloc.add(ChangeViewModeEvent(mode));
                            }
                          },
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => InfoDialog(
                                title: mode.label,
                                icon: mode.icon,
                                iconColor: theme.appColors.yellow,
                                description: _getViewModeDescription(mode),
                                examples: _getViewModeExamples(mode),
                                tip: 'Klikni na ikonku pro aktivaci tohoto pohledu. Klikni znovu pro vrácení na "Všechny".',
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              mode.icon,
                              size: 20,
                              color: isSelected
                                  ? theme.appColors.yellow
                                  : theme.appColors.base5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Divider před visibility toggle
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: theme.appColors.base3,
            ),

            // Visibility toggle (výraznější ikona 24dp)
            BlocBuilder<TodoListBloc, TodoListState>(
              builder: (context, state) {
                final showCompleted =
                    state is TodoListLoaded ? state.showCompleted : false;

                return IconButton(
                  icon: Icon(
                    showCompleted ? Icons.visibility : Icons.visibility_off,
                    size: 24, // Větší než ostatní ikony!
                  ),
                  tooltip: showCompleted
                      ? 'Skrýt hotové úkoly'
                      : 'Zobrazit hotové úkoly',
                  color: showCompleted
                      ? theme.appColors.green
                      : theme.appColors.base5,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context
                        .read<TodoListBloc>()
                        .add(const ToggleShowCompletedEvent());
                  },
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// Získat popis pro ViewMode
  String _getViewModeDescription(ViewMode mode) {
    return switch (mode) {
      ViewMode.all =>
        'Zobrazí všechny úkoly bez filtru. Toto je výchozí pohled, kde vidíš kompletní seznam všech aktivních i dokončených úkolů.',
      ViewMode.today =>
        'Zobrazí pouze úkoly s termínem dnes. Ideální pro denní plánování - vidíš co musíš stihnout ještě dnes.',
      ViewMode.week =>
        'Zobrazí úkoly s termínem v příštích 7 dnech. Pomůže ti plánovat týden dopředu a rozložit práci.',
      ViewMode.upcoming =>
        'Zobrazí všechny úkoly s termínem v budoucnosti (od zítřka dál). Pro dlouhodobé plánování.',
      ViewMode.overdue =>
        'Zobrazí úkoly po termínu - ty, které jsi nestihl včas. Prioritizuj je jako první!',
    };
  }

  /// Získat příklady použití pro ViewMode
  List<String> _getViewModeExamples(ViewMode mode) {
    return switch (mode) {
      ViewMode.all => [
          '📋 Všechny aktivní úkoly',
          '📋 Dokončené úkoly',
          '📋 Bez jakéhokoliv filtru',
        ],
      ViewMode.today => [
          '📅 Termín: Dnes 14:00',
          '📅 Dnes do konce dne',
          '📅 Urgentní úkoly na dnes',
        ],
      ViewMode.week => [
          '🗓️ Pondělí - Prezentace',
          '🗓️ Středa - Code review',
          '🗓️ Pátek - Team meeting',
        ],
      ViewMode.upcoming => [
          '📆 Příští týden - Projekt X',
          '📆 Konec měsíce - Report',
          '📆 Budoucí plánování',
        ],
      ViewMode.overdue => [
          '⚠️ Včera mělo být hotovo!',
          '⚠️ 3 dny po termínu',
          '⚠️ Nesplněné deadlines',
        ],
    };
  }
}
