import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../providers/todo_provider.dart';

/// StatsRow - Kompaktní stats dashboard pro AppBar
///
/// Specifikace:
/// - Height: 56dp (standard AppBar)
/// - Icon size: 16dp (malé stats ikony)
/// - Font size: 14dp (čísla)
/// - Jeden řádek: [✅5] [🔴12] [📅3] [⏰7]
/// - Real-time update přes Riverpod
class StatsRow extends ConsumerWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);

    return todoAsync.when(
      data: (state) {
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
                emoji: '✅',
                count: stats.completed,
                tooltip: 'Hotové úkoly',
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '🔴',
                count: stats.active,
                tooltip: 'Aktivní úkoly',
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '📅',
                count: stats.today,
                tooltip: 'Úkoly dnes',
              ),
              const SizedBox(width: 8),
              _StatChip(
                emoji: '⏰',
                count: stats.week,
                tooltip: 'Úkoly tento týden',
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
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
  final String emoji;
  final int count;
  final String tooltip;

  const _StatChip({
    required this.emoji,
    required this.count,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => InfoDialog(
            title: tooltip,
            emoji: emoji, // Použij emoji místo icon
            description: _getStatDescription(tooltip),
            examples: _getStatExamples(tooltip),
            tip: 'Tato statistika se aktualizuje v reálném čase při změnách úkolů.',
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.base2.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 16, // Emoji size
              ),
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

  /// Získat popis pro statistiku
  String _getStatDescription(String statName) {
    if (statName.contains('Hotové')) {
      return 'Počet dokončených úkolů. Tyto úkoly máš za sebou - gratulujeme! Můžeš je najít filtrováním nebo je smazat.';
    } else if (statName.contains('Aktivní')) {
      return 'Počet aktivních (nedokončených) úkolů. To jsou úkoly, na kterých stále pracuješ nebo je čeká dokončení.';
    } else if (statName.contains('dnes')) {
      return 'Počet úkolů s termínem dnes. Tyto úkoly bys měl dokončit ještě dnes, aby jsi nestihl deadline.';
    } else if (statName.contains('týden')) {
      return 'Počet úkolů s termínem v příštích 7 dnech. Plánuj si čas, aby jsi všechno stihl včas!';
    }
    return 'Statistika úkolů v reálném čase.';
  }

  /// Získat příklady pro statistiku
  List<String> _getStatExamples(String statName) {
    if (statName.contains('Hotové')) {
      return [
        '✅ Úkol označený jako hotový',
        '✅ Splněný cíl',
        '✅ Dokončený projekt',
      ];
    } else if (statName.contains('Aktivní')) {
      return [
        '⭕ Rozepsaný úkol',
        '⭕ Čekající na dokončení',
        '⭕ V procesu',
      ];
    } else if (statName.contains('dnes')) {
      return [
        '📅 Meeting ve 14:00',
        '📅 Odevzdat projekt do 18:00',
        '📅 Zavolat klientovi dnes',
      ];
    } else if (statName.contains('týden')) {
      return [
        '📆 Pondělí - Prezentace',
        '📆 Středa - Code review',
        '📆 Pátek - Team meeting',
      ];
    }
    return [];
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
