import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';
import '../widgets/todo_card.dart';
import '../widgets/input_bar.dart';
import '../widgets/view_bar.dart';
import '../widgets/sort_bar.dart';
import '../widgets/stats_row.dart';

/// TodoListPage - Hlavní stránka s TODO seznamem (Mobile-First redesign)
///
/// Layout (zdola nahoru):
/// - InputBar (bottom fixed) - Easy Thumb Zone
/// - ViewBar (kompaktní ikony) - Easy Thumb Zone (skrytý při psaní!)
/// - SortBar (kompaktní ikony) - Easy Thumb Zone (skrytý při psaní!)
/// - TODO List (scrollable) - Stretch Zone
/// - StatsRow (AppBar) - Hard Zone (ale jen info)
///
/// Keyboard awareness:
/// - ViewBar a SortBar se skryjí při focus na InputBar
/// - Šetří místo pro klávesnici a TODO list
///
/// Používá BLoC pattern pro state management.
/// UI je immutable a reaguje na změny state.
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool _isInputFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Automatický posun při otevření klávesnice
      resizeToAvoidBottomInset: true,

      // AppBar s Stats dashboard a Settings
      appBar: AppBar(
        title: const StatsRow(), // Stats vlevo
        actions: [
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

      // TODO List (scrollable)
      body: BlocConsumer<TodoListBloc, TodoListState>(
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
                        context.read<TodoListBloc>().add(const LoadTodosEvent());
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

      // Bottom Navigation Bar - Fixed controls (Easy Thumb Zone!)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.appColors.bgAlt,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SortBar (skrytý při psaní!)
              if (!_isInputFocused) const SortBar(),

              // ViewBar (skrytý při psaní!)
              if (!_isInputFocused) const ViewBar(),

              // InputBar (VŽDY viditelný)
              InputBar(
                onFocusChanged: (hasFocus) {
                  setState(() {
                    _isInputFocused = hasFocus;
                  });
                },
              ),
            ],
          ),
        ),
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
