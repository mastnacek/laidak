import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';
import '../../domain/enums/view_mode.dart';
import '../providers/todo_provider.dart';

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
class ViewBar extends ConsumerWidget {
  const ViewBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Semantics(
      label: 'Panel pro výběr zobrazení úkolů',
      container: true,
      child: settingsAsync.when(
        data: (settingsState) {
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

          // AI Brief view (VŽDY dostupný - není v AgendaViewConfig)
          visibleViews.add(_ViewItem.builtIn(ViewMode.aiBrief));

          // Custom views (pouze enabled)
          for (final customView in agendaConfig.customViews) {
            if (customView.isEnabled) {
              visibleViews.add(_ViewItem.custom(customView));
            }
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
                  // View mode buttons (dynamicky generované) - zabírají celou šířku
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final todoAsync = ref.watch(todoListProvider);

                        final currentViewMode = todoAsync.value is TodoListLoaded
                            ? (todoAsync.value as TodoListLoaded).viewMode
                            : ViewMode.all;

                        final currentCustomViewId = todoAsync.value is TodoListLoaded
                            ? (todoAsync.value as TodoListLoaded).currentCustomViewId
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
                                    _handleViewTap(context, ref, viewItem, isSelected);
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
                                    child: Text(
                                      viewItem.emoji,
                                      style: TextStyle(
                                        fontSize: 20,
                                        // Emoji s opacity pokud není vybraný
                                        color: isSelected
                                            ? null
                                            : Colors.white.withOpacity(0.5),
                                      ),
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
                ],
              ),
            ),
          );
        },
        loading: () => _buildFallbackViewBar(context, theme),
        error: (error, stack) => _buildFallbackViewBar(context, theme),
      ),
    );
  }

  /// Handle tap na view item
  void _handleViewTap(BuildContext context, WidgetRef ref, _ViewItem viewItem, bool isSelected) {
    final notifier = ref.read(todoListProvider.notifier);

    if (viewItem.isBuiltIn) {
      // Built-in view: toggle behavior
      if (isSelected && viewItem.builtInMode != ViewMode.all) {
        notifier.changeViewMode(ViewMode.all);
      } else {
        notifier.changeViewMode(viewItem.builtInMode!);
      }
    } else {
      // Custom view: toggle behavior
      if (isSelected) {
        notifier.changeViewMode(ViewMode.all);
      } else {
        notifier.changeToCustomView(viewItem.customView!);
      }
    }
  }

  /// Zobrazit InfoDialog s popisem view
  void _showInfoDialog(BuildContext context, _ViewItem viewItem, ThemeData theme) {
    if (viewItem.isBuiltIn) {
      // Built-in view info (s emoji)
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: '${viewItem.emoji} ${viewItem.label}',
          emoji: viewItem.emoji, // Použij emoji místo Material Icon
          description: _getViewModeDescription(viewItem.builtInMode!),
          examples: _getViewModeExamples(viewItem.builtInMode!),
          tip: 'Klikni na emoji pro aktivaci tohoto pohledu. Klikni znovu pro vrácení na "Všechny".',
        ),
      );
    } else {
      // Custom view info (s emoji)
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: '${viewItem.emoji} ${viewItem.label}',
          emoji: viewItem.emoji, // Použij emoji místo Material Icon
          description: 'Vlastní pohled filtrující úkoly podle tagu: ${viewItem.customView?.tagFilter}',
          examples: [
            'Zobrazí pouze úkoly s tagem ${viewItem.customView?.tagFilter}',
            'Nastavení: Settings > Agenda > Custom Views',
          ],
          tip: 'Klikni na emoji pro aktivaci. Upravit můžeš v Settings.',
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
      ViewMode.aiBrief =>
        'AI inteligentně prioritizuje tvoje úkoly do 3 sekcí: FOCUS NOW (top 3 úkoly), KEY INSIGHTS (dependencies, quick wins), MOTIVATION (progress, povzbuzení). Cache 1h.',
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
      ViewMode.aiBrief => [
          '🎯 FOCUS NOW: Top 3 urgentní úkoly',
          '📊 KEY INSIGHTS: Závislosti, quick wins',
          '💪 MOTIVATION: Pokrok + povzbuzení',
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

  // Emoji pro všechny views (built-in i custom)
  String get emoji {
    if (isBuiltIn) {
      return builtInMode!.emoji;
    } else {
      return customView!.emoji;
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
