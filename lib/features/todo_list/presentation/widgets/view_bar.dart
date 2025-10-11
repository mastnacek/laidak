import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../../../features/settings/presentation/cubit/settings_state.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';
import '../../domain/enums/view_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

/// ViewBar - Kompaktní view mode selector s visibility toggle
///
/// **Dynamic Rendering**: Zobrazuje pouze enabled views z AgendaViewConfig
///
/// Specifikace:
/// - Height: 56dp
/// - Icon size: 20-22dp (menší než visibility toggle)
/// - Eye icon: 24dp (větší než ostatní)
/// - Touch target: 44x44dp
/// - Spacing: 4-8dp
/// - Horizontal scroll pro > 6 views
class ViewBar extends StatelessWidget {
  const ViewBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro výběr zobrazení úkolů',
      container: true,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          if (settingsState is! SettingsLoaded) {
            // Fallback: zobrazit jen základní views
            return _buildFallbackViewBar(context, theme);
          }

          final agendaConfig = settingsState.agendaConfig;

          // Build list of visible views
          final visibleViews = <_ViewItem>[];

          // Built-in views (podle AgendaViewConfig)
          if (agendaConfig.showAll) {
            visibleViews.add(_ViewItem.builtIn(ViewMode.all));
          }
          if (agendaConfig.showToday) {
            visibleViews.add(_ViewItem.builtIn(ViewMode.today));
          }
          if (agendaConfig.showWeek) {
            visibleViews.add(_ViewItem.builtIn(ViewMode.week));
          }
          if (agendaConfig.showUpcoming) {
            visibleViews.add(_ViewItem.builtIn(ViewMode.upcoming));
          }
          if (agendaConfig.showOverdue) {
            visibleViews.add(_ViewItem.builtIn(ViewMode.overdue));
          }

          // Custom views (všechny jsou enabled)
          for (final customView in agendaConfig.customViews) {
            visibleViews.add(_ViewItem.custom(customView));
          }

          // Empty state - žádné views aktivní
          if (visibleViews.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.appColors.bgAlt,
              border: Border(
                top: BorderSide(color: theme.appColors.base3, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // View mode buttons (dynamicky generované)
                  Expanded(
                    child: BlocBuilder<TodoListBloc, TodoListState>(
                      builder: (context, todoState) {
                        final currentViewMode = todoState is TodoListLoaded
                            ? todoState.viewMode
                            : ViewMode.all;

                        final currentCustomViewId = todoState is TodoListLoaded
                            ? todoState.currentCustomViewId
                            : null;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: visibleViews.map((viewItem) {
                              final isSelected = viewItem.isBuiltIn
                                  ? currentViewMode == viewItem.builtInMode
                                  : currentCustomViewId == viewItem.customView?.id;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: InkWell(
                                  onTap: () {
                                    _handleViewTap(context, viewItem, isSelected);
                                  },
                                  onLongPress: () {
                                    _showInfoDialog(context, viewItem, theme);
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      viewItem.icon,
                                      size: 20,
                                      color: isSelected
                                          ? theme.appColors.yellow
                                          : theme.appColors.base5,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
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
                          size: 24,
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
          );
        },
      ),
    );
  }

  /// Handle tap na view item
  void _handleViewTap(BuildContext context, _ViewItem viewItem, bool isSelected) {
    final bloc = context.read<TodoListBloc>();

    if (viewItem.isBuiltIn) {
      // Built-in view: toggle behavior
      if (isSelected && viewItem.builtInMode != ViewMode.all) {
        bloc.add(const ChangeViewModeEvent(ViewMode.all));
      } else {
        bloc.add(ChangeViewModeEvent(viewItem.builtInMode!));
      }
    } else {
      // Custom view: toggle behavior
      if (isSelected) {
        bloc.add(const ChangeViewModeEvent(ViewMode.all));
      } else {
        bloc.add(ChangeToCustomViewEvent(viewItem.customView!));
      }
    }
  }

  /// Zobrazit InfoDialog s popisem view
  void _showInfoDialog(BuildContext context, _ViewItem viewItem, ThemeData theme) {
    if (viewItem.isBuiltIn) {
      // Built-in view info
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: viewItem.label,
          icon: viewItem.icon,
          iconColor: theme.appColors.yellow,
          description: _getViewModeDescription(viewItem.builtInMode!),
          examples: _getViewModeExamples(viewItem.builtInMode!),
          tip: 'Klikni na ikonku pro aktivaci tohoto pohledu. Klikni znovu pro vrácení na "Všechny".',
        ),
      );
    } else {
      // Custom view info
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: viewItem.label,
          icon: viewItem.icon,
          iconColor: viewItem.customView?.color ?? theme.appColors.magenta,
          description: 'Vlastní pohled filtrující úkoly podle tagu: ${viewItem.customView?.tagFilter}',
          examples: [
            'Zobrazí pouze úkoly s tagem ${viewItem.customView?.tagFilter}',
            'Nastavení: Settings > Agenda > Custom Views',
          ],
          tip: 'Klikni na ikonku pro aktivaci. Upravit můžeš v Settings.',
        ),
      );
    }
  }

  /// Fallback ViewBar (když settings loading)
  Widget _buildFallbackViewBar(BuildContext context, ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.appColors.bgAlt,
        border: Border(
          top: BorderSide(color: theme.appColors.base3, width: 1),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Empty state - žádné views aktivní
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.bgAlt,
        border: Border(
          top: BorderSide(color: theme.appColors.base3, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          'Žádné views aktivní. Zapni je v Settings > Agenda',
          style: TextStyle(
            color: theme.appColors.base5,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
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
      ViewMode.custom =>
        'Vlastní pohled',
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
      ViewMode.custom => [],
    };
  }
}

/// Helper class pro view items (built-in + custom)
class _ViewItem {
  final ViewMode? builtInMode;
  final CustomAgendaView? customView;

  bool get isBuiltIn => builtInMode != null;

  IconData get icon {
    if (isBuiltIn) {
      return builtInMode!.icon;
    } else {
      // Použít helper metodu s MaterialIcons font family
      return customView!.getIcon();
    }
  }

  String get label {
    if (isBuiltIn) {
      return builtInMode!.label;
    } else {
      return customView!.name;
    }
  }

  _ViewItem.builtIn(this.builtInMode) : customView = null;
  _ViewItem.custom(this.customView) : builtInMode = null;
}
