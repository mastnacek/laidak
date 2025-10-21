import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/notes_provider.dart';

/// FoldersTabBar - Horizontal scroll tabs pro Notes Views
///
/// Zobrazuje built-in + custom views z Settings.notesConfig:
/// - All Notes (📝)
/// - Recent Notes (🕐)
/// - Custom tag-based views (🛒, ⚽, ...)
/// - Height: 56dp
/// - Icon size: 20dp (emoji)
/// - Touch target: 44x44dp
class FoldersTabBar extends ConsumerWidget {
  const FoldersTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro výběr složky poznámek',
      container: true,
      child: Container(
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
              // View tabs - expandují na celou šířku
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    // Načíst notesConfig ze Settings provider
                    final settingsAsync = ref.watch(settingsProvider);
                    final settingsState = settingsAsync.value;

                    if (settingsState == null) {
                      return const SizedBox.shrink();
                    }

                    final notesConfig = settingsState.notesConfig;

                    // Načíst currentView z Notes provider
                    final notesAsync = ref.watch(notesProvider);
                    final notesState = notesAsync.value;
                    final currentView = notesState is NotesLoaded
                        ? notesState.currentView
                        : ViewMode.allNotes;
                    final currentCustomViewId = notesState is NotesLoaded
                        ? notesState.customViewId
                        : null;

                    // Sestavit seznam view items (built-in + custom)
                    final viewItems = <_ViewItem>[];

                    // Built-in: All Notes
                    if (notesConfig.showAllNotes) {
                      viewItems.add(_ViewItem(
                        emoji: '📝',
                        mode: ViewMode.allNotes,
                        customViewId: null,
                        tagFilter: null,
                      ));
                    }

                    // Built-in: Recent Notes
                    if (notesConfig.showRecentNotes) {
                      viewItems.add(_ViewItem(
                        emoji: '🕐',
                        mode: ViewMode.recentNotes,
                        customViewId: null,
                        tagFilter: null,
                      ));
                    }

                    // Custom views (pouze enabled)
                    for (final customView in notesConfig.customViews) {
                      if (customView.isEnabled) {
                        viewItems.add(_ViewItem(
                          emoji: customView.emoji,
                          mode: ViewMode.customTag,
                          customViewId: customView.id,
                          tagFilter: customView.tagFilter,
                        ));
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: viewItems.map((item) {
                          // Check if selected
                          final isSelected = item.mode == currentView &&
                              (item.mode != ViewMode.customTag ||
                                  item.customViewId == currentCustomViewId);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                _handleViewTap(context, ref, item, isSelected);
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  item.emoji,
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
      ),
    );
  }

  /// Handle tap na view item
  void _handleViewTap(
    BuildContext context,
    WidgetRef ref,
    _ViewItem item,
    bool isSelected,
  ) {
    final notifier = ref.read(notesProvider.notifier);

    // Toggle behavior: Tap na vybraný view → vrátit na All Notes
    if (isSelected && item.mode != ViewMode.allNotes) {
      notifier.changeViewMode(ViewMode.allNotes);
    } else {
      // Změnit view mode s customViewId a tagFilter
      notifier.changeViewMode(
        item.mode,
        customViewId: item.customViewId,
        tagFilter: item.tagFilter,
      );
    }
  }
}

/// Helper class pro view item v tab baru
class _ViewItem {
  final String emoji;
  final ViewMode mode;
  final String? customViewId; // Pro custom views
  final String? tagFilter; // Pro custom tag-based filtrování

  _ViewItem({
    required this.emoji,
    required this.mode,
    this.customViewId,
    this.tagFilter,
  });
}
