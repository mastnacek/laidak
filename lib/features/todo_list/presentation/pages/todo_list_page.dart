import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_input_form.dart';
import '../widgets/view_mode_buttons.dart';
import '../widgets/sort_buttons.dart';

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Views buttons (📋 Všechny, 📅 Dnes, 🗓️ Týden, ...)
              const ViewModeButtons(),

              // Sort buttons (🔴 Priorita, 📅 Deadline, ...)
              const SortButtons(),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Formulář pro přidání nového úkolu / vyhledávání
          const TodoInputForm(),

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
