import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/models/smart_folder.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../widgets/smart_folder_form_sheet.dart';

/// SmartFolderSettingsPage - Správa Smart Folders (PHASE 3)
///
/// Features:
/// - Seznam všech folders (system + custom)
/// - System folders: nelze smazat/upravit
/// - Custom folders: edit/delete
/// - FAB: Vytvořit novou složku
/// - Long-press: Delete confirmation
class SmartFolderSettingsPage extends StatelessWidget {
  const SmartFolderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa složek'),
        backgroundColor: theme.appColors.bg,
        foregroundColor: theme.appColors.fg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: theme.appColors.bg,
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is! NotesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = state.smartFolders;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _SmartFolderListItem(
                key: ValueKey('folder_${folder.id}'),
                folder: folder,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderSheet(context),
        backgroundColor: theme.appColors.blue,
        foregroundColor: theme.appColors.bg,
        icon: const Icon(Icons.add),
        label: const Text('Nová složka'),
      ),
    );
  }

  /// Zobrazit bottom sheet pro vytvoření nové složky
  void _showCreateFolderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SmartFolderFormSheet(),
    );
  }
}

/// SmartFolderListItem - Položka v seznamu složek
class _SmartFolderListItem extends StatelessWidget {
  final SmartFolder folder;

  const _SmartFolderListItem({
    super.key,
    required this.folder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystemFolder = folder.isSystem;

    return Card(
      color: theme.appColors.base2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.base3, width: 1),
      ),
      child: InkWell(
        onTap: isSystemFolder ? null : () => _showEditFolderSheet(context),
        onLongPress: isSystemFolder ? null : () => _showDeleteDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.appColors.base3,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  folder.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),

              // Name + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.appColors.fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFilterDescription(folder),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.appColors.base5,
                      ),
                    ),
                  ],
                ),
              ),

              // System badge nebo edit button
              if (isSystemFolder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.appColors.base4,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Systémová',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.appColors.base6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: theme.appColors.blue),
                      onPressed: () => _showEditFolderSheet(context),
                      tooltip: 'Upravit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.appColors.red),
                      onPressed: () => _showDeleteDialog(context),
                      tooltip: 'Smazat',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Popis filtru
  String _getFilterDescription(SmartFolder folder) {
    final rules = folder.filterRules;

    switch (rules.type) {
      case FilterType.all:
        return 'Všechny poznámky';
      case FilterType.recent:
        return 'Poslední ${rules.recentDays} dní';
      case FilterType.tags:
        return 'Tagy: ${rules.includeTags.join(", ")}';
      case FilterType.dateRange:
        return 'Custom date range';
    }
  }

  /// Zobrazit edit bottom sheet
  void _showEditFolderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartFolderFormSheet(folder: folder),
    );
  }

  /// Zobrazit delete confirmation dialog
  void _showDeleteDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.appColors.base2,
        title: Text(
          'Smazat složku?',
          style: TextStyle(color: theme.appColors.fg),
        ),
        content: Text(
          'Opravdu chcete smazat složku "${folder.name}"? Tato akce je nevratná.',
          style: TextStyle(color: theme.appColors.base6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Zrušit',
              style: TextStyle(color: theme.appColors.base6),
            ),
          ),
          TextButton(
            onPressed: () {
              // Delete folder
              context.read<NotesBloc>().add(DeleteSmartFolderEvent(folder.id!));
              Navigator.pop(dialogContext);

              // Show snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Složka "${folder.name}" byla smazána'),
                  backgroundColor: theme.appColors.green,
                ),
              );
            },
            child: Text(
              'Smazat',
              style: TextStyle(
                color: theme.appColors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
