import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../domain/enums/sort_mode.dart';
import '../providers/todo_provider.dart';

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
class SortButtons extends ConsumerWidget {
  const SortButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);
    final currentSortMode =
        todoAsync.value is TodoListLoaded ? (todoAsync.value as TodoListLoaded).sortMode : null;
    final currentDirection =
        todoAsync.value is TodoListLoaded ? (todoAsync.value as TodoListLoaded).sortDirection : SortDirection.desc;

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
  }
}

/// Individual Sort Button (kompaktní ikona s tooltipem)
class _SortButton extends ConsumerWidget {
  final SortMode sortMode;
  final SortMode? currentSortMode;
  final SortDirection currentDirection;

  const _SortButton({
    required this.sortMode,
    required this.currentSortMode,
    required this.currentDirection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = sortMode == currentSortMode;
    final theme = Theme.of(context);

    // Určit barvu podle směru sortování (color coding)
    final sortColor = isActive
        ? (currentDirection == SortDirection.desc
            ? theme.appColors.red // 🔴 DESC = červená
            : theme.appColors.green) // 🟢 ASC = zelená
        : theme.appColors.base5; // ⚫ OFF = šedá

    return InkWell(
      onTap: () {
        final notifier = ref.read(todoListProvider.notifier);

        if (!isActive) {
          // První klik → aktivovat DESC
          notifier.sortTodos(sortMode, SortDirection.desc);
        } else if (currentDirection == SortDirection.desc) {
          // Druhý klik → přepnout na ASC
          notifier.sortTodos(sortMode, SortDirection.asc);
        } else {
          // Třetí klik → deaktivovat (null sort = default)
          notifier.clearSort();
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => InfoDialog(
            title: sortMode.label,
            icon: sortMode.icon,
            iconColor: theme.appColors.yellow,
            description: _getSortModeDescription(sortMode),
            examples: _getSortModeExamples(sortMode),
            tip: '1. klik = 🔴 Sestupně ↓  |  2. klik = 🟢 Vzestupně ↑  |  3. klik = Vypnout',
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? sortColor.withValues(alpha: 0.2) : null,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: sortColor, width: 2)
              : Border.all(color: theme.appColors.base3, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sortMode.icon,
              size: 18,
              color: isActive ? sortColor : theme.appColors.base5,
            ),
            if (isActive) ...[
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: currentDirection == SortDirection.desc ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_downward,
                  size: 12,
                  color: sortColor, // Šipka také barevná
                ),
              ),
            ],
          ],
        ),
      ),
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
