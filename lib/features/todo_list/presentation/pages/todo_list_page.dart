import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';
import '../../../../services/tag_parser.dart';
import '../../../../widgets/highlighted_text_field.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';
import '../widgets/todo_card.dart';

/// TodoListPage - Hlavní stránka s TODO seznamem
///
/// Používá BLoC pattern pro state management.
/// UI je immutable a reaguje na změny state.
class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO // DOOM'),
        actions: [
          // BlocBuilder pro toggle zobrazení hotových úkolů
          BlocBuilder<TodoListBloc, TodoListState>(
            builder: (context, state) {
              final showCompleted =
                  state is TodoListLoaded ? state.showCompleted : false;

              return IconButton(
                icon: Icon(
                  showCompleted ? Icons.visibility : Icons.visibility_off,
                  color: showCompleted
                      ? theme.appColors.green
                      : theme.appColors.base5,
                ),
                tooltip: showCompleted
                    ? 'Skrýt hotové úkoly'
                    : 'Zobrazit hotové úkoly',
                onPressed: () {
                  context
                      .read<TodoListBloc>()
                      .add(const ToggleShowCompletedEvent());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Nastavení',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulář pro přidání nového úkolu
          _TodoInputForm(),
          Divider(height: 1, color: theme.appColors.base3),

          // Seznam úkolů s BlocBuilder
          Expanded(
            child: BlocConsumer<TodoListBloc, TodoListState>(
              listener: (context, state) {
                // Zobrazit error snackbar
                if (state is TodoListError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.appColors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return switch (state) {
                  TodoListInitial() => const Center(
                      child: Text('Inicializace...'),
                    ),
                  TodoListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  TodoListLoaded() => _buildTodoList(context, state),
                  TodoListError() => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: theme.appColors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Chyba při načítání úkolů',
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
                              context
                                  .read<TodoListBloc>()
                                  .add(const LoadTodosEvent());
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
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Sestavit seznam úkolů (Loaded state)
  Widget _buildTodoList(BuildContext context, TodoListLoaded state) {
    final theme = Theme.of(context);
    final displayedTodos = state.displayedTodos;

    if (displayedTodos.isEmpty) {
      return Center(
        child: Text(
          state.showCompleted
              ? 'Žádné hotové úkoly.'
              : 'Zatím žádné úkoly.\nPřidej první úkol!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: theme.appColors.base5,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedTodos.length,
      itemBuilder: (context, index) {
        final todo = displayedTodos[index];
        return TodoCard(
          todo: todo,
          isExpanded: state.expandedTodoId == todo.id,
        );
      },
    );
  }
}

/// Widget pro formulář přidání nového úkolu
class _TodoInputForm extends StatefulWidget {
  @override
  State<_TodoInputForm> createState() => _TodoInputFormState();
}

class _TodoInputFormState extends State<_TodoInputForm> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Přidat nový úkol s parsováním tagů
  Future<void> _addTodoItem(BuildContext context, String taskText) async {
    if (taskText.trim().isEmpty) return;

    // Parsovat tagy (async)
    final parsed = await TagParser.parse(taskText);

    // Dispatch AddTodoEvent
    if (context.mounted) {
      context.read<TodoListBloc>().add(
            AddTodoEvent(
              taskText: parsed.cleanText,
              priority: parsed.priority,
              dueDate: parsed.dueDate,
              tags: parsed.tags,
            ),
          );

      // Vyčistit textfield
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.appColors.bgAlt,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: HighlightedTextField(
              controller: _textController,
              hintText: '*a* *dnes* *udelat* nakoupit, *rodina*',
              onSubmitted: (text) => _addTodoItem(context, text),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addTodoItem(context, _textController.text),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
