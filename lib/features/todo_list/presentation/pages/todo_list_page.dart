import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';
import '../../../help/presentation/pages/help_page.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../domain/enums/view_mode.dart';
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
  void initState() {
    super.initState();
    
    // Zobrazit gesture hint pro nové uživatele (po 2 sekundách)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGestureHintIfNeeded();
    });
  }

  /// Zobrazit gesture hint pokud uživatel ho ještě neviděl
  void _showGestureHintIfNeeded() {
    final settingsCubit = context.read<SettingsCubit>();
    final settingsState = settingsCubit.state;
    
    if (settingsState is SettingsLoaded && !settingsState.hasSeenGestureHint) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '💡 Long press = edit, Swipe = actions',
              style: TextStyle(fontSize: 14),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: theme.appColors.bgAlt,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 120, // Nad InputBar (aby nepřekrýval controls)
              left: 16,
              right: 16,
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: theme.appColors.cyan,
              onPressed: () {
                settingsCubit.markGestureHintSeen();
              },
            ),
          ),
        ).closed.then((_) {
          // Označit jako viděný i když byl automaticky dismissed (po 5 sekundách)
          final currentState = settingsCubit.state;
          if (currentState is SettingsLoaded && !currentState.hasSeenGestureHint) {
            settingsCubit.markGestureHintSeen();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Automatický posun při otevření klávesnice
      resizeToAvoidBottomInset: true,

      // AppBar s Stats dashboard, Help a Settings
      appBar: AppBar(
        // Help button VLEVO (vedle hamburger menu pozice)
        leading: IconButton(
          icon: Icon(Icons.help_outline, color: theme.appColors.cyan),
          tooltip: 'Nápověda',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const HelpPage(), // Import přidáme na začátek souboru
              ),
            );
          },
        ),
        // Stats uprostřed
        title: const StatsRow(),
        // Settings VPRAVO
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

      // TODO List + Bottom Controls (keyboard aware!)
      body: BlocListener<SettingsCubit, SettingsState>(
        listener: (context, settingsState) {
          // Auto-switch na "All" když vypnu aktivní custom view
          if (settingsState is SettingsLoaded) {
            final todoState = context.read<TodoListBloc>().state;
            if (todoState is TodoListLoaded &&
                todoState.viewMode == ViewMode.custom &&
                todoState.currentCustomViewId != null) {
              // Zkontroluj jestli aktivní custom view je stále enabled
              final activeCustomView = settingsState.agendaConfig.customViews
                  .where((v) => v.id == todoState.currentCustomViewId)
                  .firstOrNull;

              if (activeCustomView == null || !activeCustomView.isEnabled) {
                // Custom view byl vypnut nebo smazán → přepni na "All"
                context.read<TodoListBloc>().add(const ChangeViewModeEvent(ViewMode.all));
              }
            }
          }
        },
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
          return Column(
            children: [
              // TODO List (scrollable) - Expanded = zabere zbytek místa
              Expanded(
                child: switch (state) {
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
                },
              ),

              // Bottom Controls (KEYBOARD AWARE!)
              Container(
                decoration: BoxDecoration(
                  color: theme.appColors.bgAlt,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                // DŮLEŽITÉ: Padding podle keyboard inset!
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SortBar (skrytý při psaní s animací!)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isInputFocused
                            ? const SizedBox.shrink()
                            : const SortBar(),
                      ),

                      // ViewBar (skrytý při psaní s animací!)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isInputFocused
                            ? const SizedBox.shrink()
                            : const ViewBar(),
                      ),

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
            ],
          );
        },
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
