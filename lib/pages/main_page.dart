import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/theme_colors.dart';
import '../features/help/presentation/pages/help_page.dart';
import '../features/todo_list/presentation/pages/todo_list_page.dart';
import '../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../features/ai_chat/presentation/bloc/ai_chat_bloc.dart';
import '../features/ai_chat/presentation/bloc/ai_chat_event.dart';
import '../features/todo_list/presentation/widgets/stats_row.dart';
import '../features/todo_list/presentation/bloc/todo_list_bloc.dart';
import '../features/todo_list/presentation/bloc/todo_list_event.dart';
import '../features/todo_list/presentation/bloc/todo_list_state.dart';
import '../features/todo_list/domain/enums/completion_filter.dart';
import '../features/notes/presentation/pages/notes_list_page.dart';
import '../features/calendar/presentation/pages/calendar_page.dart';
import 'settings_page.dart';

/// MainPage - Hlavní stránka s PageView pro swipeable obrazovky
///
/// Layout:
/// - AppBar (Help + Stats/Title + Settings) - sdílený pro všechny stránky
/// - PageView s 5 stránkami:
///   0. AiChatPage (standalone mode) - vlevo
///   1. TodoListPage (střed, initial)
///   2. NotesListPage - vpravo
///   3. CalendarPage - vpravo
///   4. PomodoroPage - vpravo
///
/// Gesture:
/// - Swipe doprava → AI Chat
/// - Swipe doleva → Notes → Calendar → Pomodoro
/// - Initial page: TodoListPage (index 1)
///
/// AppBar je fixní a nescrolluje se s obsahem.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  // PageController pro správu PageView
  // initialPage: 1 = TodoListPage (střed)
  final PageController _pageController = PageController(initialPage: 1);

  // Aktuální index stránky (0 = AI Chat, 1 = TODO List, 2 = Pomodoro)
  int _currentPageIndex = 1;

  // Veřejný getter pro PageController (pro přístup z CalendarPage)
  PageController get pageController => _pageController;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Callback když se změní stránka swipem
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // AppBar sdílený pro všechny stránky
      appBar: AppBar(
        // Help button VLEVO
        leading: IconButton(
          icon: Icon(Icons.help_outline, color: theme.appColors.cyan),
          tooltip: 'Nápověda',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HelpPage(),
              ),
            );
          },
        ),
        // Title závisí na aktuální stránce
        title: _buildAppBarTitle(),
        centerTitle: true, // Vždy centrovaný title
        // Actions VPRAVO (dynamické podle stránky)
        actions: _buildAppBarActions(),
      ),

      // PageView s 5 stránkami (swipeable)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          // Stránka 0: AI Chat (standalone mode)
          AiChatPage.standalone(),

          // Stránka 1: TODO List (střed, initial)
          TodoListPage(),

          // Stránka 2: Notes
          NotesListPage(),

          // Stránka 3: Calendar (nový tab!)
          CalendarPage(),

          // Stránka 4: Pomodoro Timer
          PomodoroPage(),
        ],
      ),
    );
  }

  /// AppBar title podle aktuální stránky
  Widget _buildAppBarTitle() {
    switch (_currentPageIndex) {
      case 0:
        return const Text('🤖 AI Chat');
      case 1:
        return const StatsRow(); // TODO List stats
      case 2:
        return const Text('📝 Notes');
      case 3:
        return const Text('📅 Kalendář');
      case 4:
        return const Text('🍅 Pomodoro Timer');
      default:
        return const Text('TODO');
    }
  }

  /// AppBar actions podle aktuální stránky
  List<Widget> _buildAppBarActions() {
    // AI Chat (index 0): Clear chat + Info + Settings
    if (_currentPageIndex == 0) {
      return [
        // Clear chat button
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: 'Vymazat chat',
          onPressed: () {
            // Najít AiChatBloc z PageView child widgetu
            final bloc = context.read<AiChatBloc>();
            bloc.add(const ClearChatEvent());
          },
        ),
        // Info button (zobrazit kontext)
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Zobrazit kontext',
          onPressed: () {
            // TODO: Scroll to top / expand summary
          },
        ),
        // Settings (vždy viditelný)
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Nastavení',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ];
    }

    // Calendar (index 3): Eye button + Settings
    if (_currentPageIndex == 3) {
      return [
        // Completion filter toggle (eye button)
        BlocBuilder<TodoListBloc, TodoListState>(
          builder: (context, state) {
            final filter = state is TodoListLoaded
                ? state.completionFilter
                : CompletionFilter.incomplete;

            // Ikony a barvy podle filtru
            final icon = switch (filter) {
              CompletionFilter.incomplete => Icons.visibility_off,
              CompletionFilter.completed => Icons.check_circle,
              CompletionFilter.all => Icons.visibility,
            };

            final color = switch (filter) {
              CompletionFilter.incomplete => theme.appColors.base5,
              CompletionFilter.completed => theme.appColors.green,
              CompletionFilter.all => theme.appColors.cyan,
            };

            final tooltip = switch (filter) {
              CompletionFilter.incomplete => 'Ke splnění',
              CompletionFilter.completed => 'Hotové',
              CompletionFilter.all => 'Vše',
            };

            return IconButton(
              icon: Icon(icon),
              tooltip: tooltip,
              color: color,
              onPressed: () {
                context.read<TodoListBloc>().add(const ToggleShowCompletedEvent());
              },
            );
          },
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Nastavení',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ];
    }

    // TODO List (index 1), Notes (index 2), Pomodoro (index 4): Jen Settings
    return [
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Nastavení',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
      ),
    ];
  }
}
