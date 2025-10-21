import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../domain/enums/view_mode.dart';
import '../providers/todo_provider.dart';

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
class ViewModeButtons extends ConsumerWidget {
  const ViewModeButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);
    final currentViewMode =
        todoAsync.value is TodoListLoaded ? (todoAsync.value as TodoListLoaded).viewMode : ViewMode.all;

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
  }
}

/// Individual View Button (kompaktní ikona s tooltipem)
class _ViewChip extends ConsumerWidget {
  final ViewMode viewMode;
  final bool isSelected;

  const _ViewChip({
    required this.viewMode,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        final notifier = ref.read(todoListProvider.notifier);

        // One-click toggle: Klik na aktivní tlačítko → vrátit na ViewMode.all
        if (isSelected && viewMode != ViewMode.all) {
          notifier.changeViewMode(ViewMode.all);
        } else {
          notifier.changeViewMode(viewMode);
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => InfoDialog(
            title: viewMode.label,
            icon: viewMode.icon,
            iconColor: theme.appColors.yellow,
            description: _getViewModeDescription(viewMode),
            examples: _getViewModeExamples(viewMode),
            tip: 'Klikni na ikonku pro aktivaci tohoto pohledu. Klikni znovu pro vrácení na "Všechny".',
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.appColors.yellow.withValues(alpha: 0.2)
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
        'Zobrazí úkoly s termínem v příštích 7 dnech. Perfektní pro týdenní přehled a plánování.',
      ViewMode.upcoming =>
        'Zobrazí nadcházející úkoly (příštích 7 dní, kromě dnešních). Pomůže ti připravit se na to, co tě čeká.',
      ViewMode.overdue =>
        'Zobrazí úkoly po termínu - ty, které jsi nestihl včas. Čas je dotáhnout!',
      ViewMode.custom =>
        'Vlastní pohled filtrující úkoly podle tagu.',
    };
  }

  /// Získat příklady použití pro ViewMode
  List<String> _getViewModeExamples(ViewMode mode) {
    return switch (mode) {
      ViewMode.all => [
          'Všechny aktivní úkoly',
          'Dokončené úkoly',
          'Úkoly bez termínu',
        ],
      ViewMode.today => [
          'Úkoly s deadlinem dnes',
          'Overdue úkoly z včerejška',
          'Naplánované na dnešek',
        ],
      ViewMode.week => [
          'Pondělí: Schůzka s klientem',
          'Středa: Odevzdat projekt',
          'Pátek: Týmový meeting',
        ],
      ViewMode.upcoming => [
          'Úkoly příští týden',
          'Budoucí deadliny',
          'Naplánované aktivity',
        ],
      ViewMode.overdue => [
          'Včerejší nedokončené úkoly',
          'Překročené termíny',
          'Co jsi nestihl',
        ],
      ViewMode.custom => [
          'Filtrování podle vlastních tagů',
          'Nastavení v Settings > Agenda',
        ],
    };
  }
}
