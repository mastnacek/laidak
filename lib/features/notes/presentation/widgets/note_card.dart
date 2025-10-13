import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../models/note.dart';
import '../../../../services/tag_service.dart';
import '../../../../utils/color_utils.dart';
import '../../../todo_list/presentation/widgets/todo_tag_chip.dart';
import '../../domain/services/notes_tag_parser.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../pages/note_editor_page.dart';

/// NoteCard - Karty pro zobrazení poznámek (MILESTONE 3.2)
///
/// Design inspirovaný TodoCard:
/// - Title (první řádek poznámky)
/// - Tags (parsed z content) s správnými barvami a glow efektem
/// - Swipe doleva = smazat
/// - Swipe doprava = archivovat (placeholder pro budoucí funkci)
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

    return Dismissible(
      key: Key('note_${note.id}'),
      // Swipe doprava = archivovat (placeholder)
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.blue, // Modrá pro archivaci
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Icon(
              Icons.archive,
              color: theme.appColors.bg,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'ARCHIVOVAT',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Swipe doleva = smazat
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'SMAZAT',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.delete_forever,
              color: theme.appColors.bg,
              size: 32,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Zavřít klávesnici při jakékoli swipe akci
        FocusScope.of(context).unfocus();

        if (direction == DismissDirection.startToEnd) {
          // Swipe doprava = archivovat (placeholder - zatím jen snackbar)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📦 Archivace bude implementována v budoucí verzi'),
              backgroundColor: theme.appColors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
          return false; // Neodstranit widget
        } else {
          // Swipe doleva = smazat (bez potvrzení jako u TODO)
          return true; // Odstranit widget
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Smazat poznámku
          context.read<NotesBloc>().add(DeleteNoteEvent(note.id!));
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        color: theme.appColors.bgAlt,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Zavřít klávesnici při otevření editoru
            FocusScope.of(context).unfocus();

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
                // Header: Title pouze (delete button odebrán - funkci má swipe)
                Text(
                  titleLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                // Tags (pokud existují)
                if (parsedTags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Běžné tagy (s barvami a glow efektem z TagService)
                      ...parsedTags.tags.map((tag) {
                        final tagDef = TagService().getDefinition(tag);
                        return TodoTagChip(
                          text: tag,
                          color: tagDef?.color != null
                              ? ColorUtils.hexToColor(tagDef!.color!)
                              : theme.appColors.cyan,
                          glowEnabled: tagDef?.glowEnabled ?? false,
                          glowStrength: tagDef?.glowStrength ?? 0.5,
                        );
                      }),

                      // TODO linky
                      ...parsedTags.todoLinks.map(
                        (todoId) => TodoTagChip(
                          text: '🔗 #$todoId',
                          color: theme.appColors.green,
                          glowEnabled: false,
                        ),
                      ),

                      // Note linky
                      ...parsedTags.noteLinks.map(
                        (noteName) => TodoTagChip(
                          text: '📝 $noteName',
                          color: theme.appColors.magenta,
                          glowEnabled: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
