import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/models/smart_folder.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

/// FoldersTabBar - Horizontal scroll tabs pro Notes Smart Folders (PHASE 2)
///
/// Zobrazuje všechny Smart Folders z databáze (default + custom):
/// - All Notes (📝)
/// - Recent (🕐)
/// - Favorites (⭐)
/// - Custom folders (phase 3+)
/// - Height: 56dp
/// - Icon size: 20dp (emoji)
/// - Touch target: 44x44dp
class FoldersTabBar extends StatelessWidget {
  const FoldersTabBar({super.key});

  @override
  Widget build(BuildContext context) {
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
              // Folder tabs - expandují na celou šířku
              Expanded(
                child: BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, notesState) {
                    // Načíst SmartFolders a currentFolder ze state
                    if (notesState is! NotesLoaded) {
                      return const SizedBox.shrink();
                    }

                    final smartFolders = notesState.smartFolders;
                    final currentFolder = notesState.currentFolder;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: smartFolders.map((folder) {
                          final isSelected = currentFolder?.id == folder.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                _handleFolderTap(context, folder, isSelected, smartFolders);
                              },
                              borderRadius: BorderRadius.circular(22),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  folder.icon,
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

  /// Handle tap na folder item
  void _handleFolderTap(
    BuildContext context,
    SmartFolder folder,
    bool isSelected,
    List<SmartFolder> allFolders,
  ) {
    final bloc = context.read<NotesBloc>();

    // Toggle behavior: Tap na vybraný folder → vrátit na All Notes (první systémový folder)
    if (isSelected && folder.displayOrder != 0) {
      final allNotesFolder = allFolders.firstWhere(
        (f) => f.isSystem && f.displayOrder == 0,
        orElse: () => allFolders.first,
      );
      bloc.add(ChangeSmartFolderEvent(allNotesFolder));
    } else {
      bloc.add(ChangeSmartFolderEvent(folder));
    }
  }
}
