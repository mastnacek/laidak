import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import 'note_editor_page.dart';
import '../widgets/note_input_bar.dart';
import '../widgets/note_card.dart';
import '../widgets/folders_tab_bar.dart';

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
                            // Získat delimiters z SettingsCubit
                            final settingsState = context.read<SettingsCubit>().state;
                            final delimiters = settingsState is SettingsLoaded
                                ? (
                                    start: settingsState.tagDelimiterStart,
                                    end: settingsState.tagDelimiterEnd,
                                  )
                                : (start: '*', end: '*'); // Fallback

                            context.read<NotesBloc>().add(LoadNotesEvent(
                              tagDelimiterStart: delimiters.start,
                              tagDelimiterEnd: delimiters.end,
                            ));
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

            // Bottom Controls - Folders Tab Bar + Input Bar (MILESTONE 4)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FoldersTabBar (MILESTONE 4)
                  const FoldersTabBar(),

                  // NoteInputBar (MILESTONE 3)
                  NoteInputBar(
                    onFocusChanged: (hasFocus) {
                      setState(() {
                        _isInputFocused = hasFocus;
                      });
                    },
                  ),
                ],
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
    final notes = state.displayedNotes; // MILESTONE 4: filtrované podle currentFolder

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

    // ✅ MILESTONE 3.2: NoteCard s tag display + expand/collapse
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isExpanded = state.expandedNoteId == note.id;
        return NoteCard(
          key: ValueKey('note_${note.id}'),
          note: note,
          isExpanded: isExpanded,
        );
      },
    );
  }

}
