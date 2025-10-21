import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../domain/enums/sort_mode.dart';
import '../../domain/enums/completion_filter.dart';
import '../providers/todo_provider.dart';

/// SortBar - Kompaktní sort controls s triple-toggle (DESC → ASC → OFF)
///
/// Specifikace:
/// - Height: 48dp
/// - Icon size: 20dp (kompaktní)
/// - Touch target: 44x44dp
/// - Spacing: 8dp
/// - Triple toggle: DESC (🔴↓) → ASC (🔴↑) → OFF
class SortBar extends ConsumerWidget {
  const SortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todoAsync = ref.watch(todoListProvider);

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
          child: Builder(
            builder: (context) {
            final currentSortMode =
                todoAsync.value is TodoListLoaded ? (todoAsync.value as TodoListLoaded).sortMode : null;
            final currentDirection = todoAsync.value is TodoListLoaded
                ? (todoAsync.value as TodoListLoaded).sortDirection
                : SortDirection.desc;

            return Row(
              children: [
                // Sort buttons (vlevo)
                ...SortMode.values.map((mode) {
                  final isActive = mode == currentSortMode;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        final notifier = ref.read(todoListProvider.notifier);

                        // Triple toggle logic:
                        // 1. First click: DESC
                        // 2. Second click: ASC
                        // 3. Third click: OFF (clear sort)
                        if (!isActive) {
                          // Activate with DESC
                          notifier.sortTodos(mode, SortDirection.desc);
                        } else if (currentDirection == SortDirection.desc) {
                          // Switch to ASC
                          notifier.sortTodos(mode, SortDirection.asc);
                        } else {
                          // Clear sort
                          notifier.clearSort();
                        }
                      },
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (context) => InfoDialog(
                            title: mode.label,
                            emoji: mode.emoji,
                            description: _getSortModeDescription(mode),
                            examples: _getSortModeExamples(mode),
                            tip: '1. klik = Sestupně ↓  |  2. klik = Vzestupně ↑  |  3. klik = Vypnout',
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
                        child: _buildSortIcon(
                          mode,
                          isActive,
                          currentDirection,
                          theme,
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Spacer - posune eye icon úplně doprava
                const Spacer(),

                // Divider před visibility toggle
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: theme.appColors.base3,
                ),

                // Visibility toggle (eye icon úplně vpravo - 3 stavy)
                BlocBuilder<TodoListBloc, TodoListState>(
                  builder: (context, state) {
                    final filter = state is TodoListLoaded
                        ? state.completionFilter
                        : CompletionFilter.incomplete;

                    // Ikony a barvy podle filtru
                    final icon = switch (filter) {
                      CompletionFilter.incomplete => Icons.visibility_off, // 👁️ Nehotové
                      CompletionFilter.completed => Icons.check_circle, // ✅ Hotové
                      CompletionFilter.all => Icons.visibility, // 👀 Vše
                    };

                    final color = switch (filter) {
                      CompletionFilter.incomplete => theme.appColors.base5, // Šedá
                      CompletionFilter.completed => theme.appColors.green, // Zelená
                      CompletionFilter.all => theme.appColors.cyan, // Cyan
                    };

                    final tooltip = switch (filter) {
                      CompletionFilter.incomplete => 'Ke splnění',
                      CompletionFilter.completed => 'Hotové',
                      CompletionFilter.all => 'Vše',
                    };

                    return IconButton(
                      icon: Icon(icon, size: 24),
                      tooltip: tooltip,
                      color: color,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        ref.read(todoListProvider.notifier).toggleShowCompleted();
                      },
                    );
                  },
                ),
              ],
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
      // Inactive: just the mode emoji
      return Text(
        mode.emoji,
        style: const TextStyle(fontSize: 20),
      );
    }

    // Active: emoji with animated arrow overlay
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          mode.emoji,
          style: const TextStyle(fontSize: 20),
        ),
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

  /// Získat popis pro SortMode
  String _getSortModeDescription(SortMode mode) {
    return switch (mode) {
      SortMode.priority =>
        'Seřadí úkoly podle priority. Vysoká priorita (🔴 A) nahoře, nízká (🟢 C) dole. Ideální pro focus na nejdůležitější úkoly.',
      SortMode.dueDate =>
        'Seřadí úkoly podle termínu dokončení (deadline). Nejbližší termíny nahoře, pomůže ti nestihnout deadline.',
      SortMode.status =>
        'Seřadí úkoly podle stavu - aktivní úkoly nahoře, dokončené dole. Perfektní pro oddělení hotových od rozpracovaných.',
      SortMode.createdAt =>
        'Seřadí úkoly podle data vytvoření. Nejnovější úkoly nahoře (nebo dole při vzestupném řazení).',
    };
  }

  /// Získat příklady použití pro SortMode
  List<String> _getSortModeExamples(SortMode mode) {
    return switch (mode) {
      SortMode.priority => [
          '🔴 A - Urgentní meeting (nahoře)',
          '🟡 B - Napsat email',
          '🟢 C - Uklidit stůl (dole)',
        ],
      SortMode.dueDate => [
          '📅 Dnes 14:00 - Odevzdat projekt',
          '📅 Zítra - Schůzka s klientem',
          '📅 Příští týden - Plánování',
        ],
      SortMode.status => [
          '⭕ Aktivní úkol 1',
          '⭕ Aktivní úkol 2',
          '✅ Hotový úkol (dole)',
        ],
      SortMode.createdAt => [
          '🆕 Dnes vytvořený (nahoře)',
          '🆕 Včera vytvořený',
          '🆕 Minulý týden (dole)',
        ],
    };
  }
}
