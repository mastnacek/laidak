import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/enums/folder_mode.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';

/// FoldersTabBar - Horizontal scroll tabs pro Notes folders (MILESTONE 4)
///
/// Inspired by ViewBar (TODO), but simplified:
/// - Pouze 3 basic folders (All, Recent, Favorites)
/// - BEZ custom folders (zatím)
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
                    final currentFolder = notesState is NotesLoaded
                        ? notesState.currentFolder
                        : FolderMode.all;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: FolderMode.values.map((folder) {
                          final isSelected = currentFolder == folder;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                _handleFolderTap(context, folder, isSelected);
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
      BuildContext context, FolderMode folder, bool isSelected) {
    final bloc = context.read<NotesBloc>();

    // Toggle behavior: Tap na vybraný folder → vrátit na All
    if (isSelected && folder != FolderMode.all) {
      bloc.add(const ChangeFolderEvent(FolderMode.all));
    } else {
      bloc.add(ChangeFolderEvent(folder));
    }
  }
}
