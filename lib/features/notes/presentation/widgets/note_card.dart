import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../models/note.dart';
import '../../domain/services/notes_tag_parser.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../pages/note_editor_page.dart';

/// NoteCard - Karty pro zobrazení poznámek (MILESTONE 3.2)
///
/// Design inspirovaný TodoCard:
/// - Title (první řádek poznámky)
/// - Metadata (created_at, updated_at)
/// - Tags (parsed z content)
/// - Delete button
/// - Tap = otevře NoteEditorPage
class NoteCard extends StatelessWidget {
  final Note note;

  const NoteCard({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse tagy z content
    final parsedTags = NotesTagParser.parse(note.content);

    // První řádek jako title
    final titleLine = note.content.split('\n').first;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      color: theme.appColors.bgAlt,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<NotesBloc>(),
                child: NoteEditorPage(note: note),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Delete button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titleLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: Icon(Icons.delete, color: theme.appColors.red),
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: () {
                      // Potvrzení před smazáním
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Smazat poznámku?'),
                          content: const Text('Tato akce je nevratná.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Zrušit'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context
                                    .read<NotesBloc>()
                                    .add(DeleteNoteEvent(note.id!));
                              },
                              child: Text(
                                'Smazat',
                                style: TextStyle(color: theme.appColors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Metadata
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: theme.appColors.base5,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vytvořeno: ${_formatDateTime(note.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.appColors.base5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.update,
                    size: 12,
                    color: theme.appColors.base5,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Upraveno: ${_formatDateTime(note.updatedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.appColors.base5,
                    ),
                  ),
                ],
              ),

              // Tags (pokud existují)
              if (parsedTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Běžné tagy
                    ...parsedTags.tags.map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.appColors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.appColors.cyan.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.appColors.cyan,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // TODO linky
                    ...parsedTags.todoLinks.map(
                      (todoId) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.appColors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.appColors.green.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 12,
                              color: theme.appColors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '#$todoId',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.appColors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Note linky
                    ...parsedTags.noteLinks.map(
                      (noteName) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.appColors.magenta.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.appColors.magenta.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 12,
                              color: theme.appColors.magenta,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              noteName,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.appColors.magenta,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Format DateTime pro zobrazení
  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
