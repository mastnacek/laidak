import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import 'note_editor_page.dart';
import '../widgets/note_input_bar.dart';

/// NotesListPage - Seznam poznámek (MILESTONE 2)
///
/// Layout (zdola nahoru):
/// - NoteInputBar (bottom fixed) - TODO v MILESTONE 2.3
/// - Notes List (scrollable)
/// - (Folders Tab Bar zatím přeskočen - bude v MILESTONE 4)
///
/// Používá BLoC pattern pro state management (stejně jako TodoListPage).
class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  bool _isInputFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // NotesListPage je child widget MainPage PageView (stejně jako TodoListPage)
    // AppBar je v MainPage, zde pouze body content
    return BlocConsumer<NotesBloc, NotesState>(
      listener: (context, state) {
        // Zobrazit error snackbar
        if (state is NotesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.appColors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Notes List (scrollable) - Expanded = zabere zbytek místa
            Expanded(
              child: switch (state) {
                NotesInitial() => const Center(
                    child: Text('Inicializace poznámek...'),
                  ),
                NotesLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                NotesLoaded() => _buildNotesList(context, state),
                NotesError() => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.appColors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Chyba při načítání poznámek',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.appColors.fg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.appColors.base5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<NotesBloc>().add(const LoadNotesEvent());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Zkusit znovu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.appColors.yellow,
                            foregroundColor: theme.appColors.bg,
                          ),
                        ),
                      ],
                    ),
                  ),
                _ => const Center(
                    child: Text('Neznámý stav'),
                  ),
              },
            ),

            // Bottom Controls (INPUT BAR) - MILESTONE 3
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: NoteInputBar(
                onFocusChanged: (hasFocus) {
                  setState(() {
                    _isInputFocused = hasFocus;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sestavit seznam poznámek (Loaded state)
  Widget _buildNotesList(BuildContext context, NotesLoaded state) {
    final theme = Theme.of(context);
    final notes = state.notes;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: theme.appColors.base5.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Zatím žádné poznámky',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.appColors.fg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Přidej první poznámku pomocí tlačítka dole!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.appColors.base5,
              ),
            ),
          ],
        ),
      );
    }

    // TODO MILESTONE 2.4: Nahradit za NoteCard widget
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          color: theme.appColors.bgAlt,
          child: ListTile(
            // MILESTONE 3: Tap otevře NoteEditorPage
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
            title: Text(
              note.content.split('\n').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.appColors.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${note.createdAt.day}.${note.createdAt.month}.${note.createdAt.year} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: theme.appColors.base5,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: theme.appColors.red),
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
                          context.read<NotesBloc>().add(DeleteNoteEvent(note.id!));
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
          ),
        );
      },
    );
  }

}
