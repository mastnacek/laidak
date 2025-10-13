import 'package:flutter/material.dart';
import '../core/theme/theme_colors.dart';
import '../features/help/presentation/pages/help_page.dart';
import '../features/todo_list/presentation/pages/todo_list_page.dart';
import '../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../features/todo_list/presentation/widgets/stats_row.dart';
import 'settings_page.dart';

/// MainPage - Hlavní stránka s PageView pro swipeable obrazovky
///
/// Layout:
/// - AppBar (Help + Stats/Title + Settings) - sdílený pro všechny stránky
/// - PageView s 3 stránkami:
///   0. AiChatPage (standalone mode) - vlevo
///   1. TodoListPage (střed, initial)
///   2. PomodoroPage - vpravo
///
/// Gesture:
/// - Swipe doprava → AI Chat
/// - Swipe doleva → Pomodoro
/// - Initial page: TodoListPage (index 1)
///
/// AppBar je fixní a nescrolluje se s obsahem.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // PageController pro správu PageView
  // initialPage: 1 = TodoListPage (střed)
  final PageController _pageController = PageController(initialPage: 1);

  // Aktuální index stránky (0 = AI Chat, 1 = TODO List, 2 = Pomodoro)
  int _currentPageIndex = 1;

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
      // AppBar sdílený pro obě stránky
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
        centerTitle: _currentPageIndex != 1, // Center pro AI Chat a Pomodoro
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

      // PageView s 3 stránkami (swipeable)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          // Stránka 0: AI Chat (standalone mode)
          AiChatPage.standalone(),

          // Stránka 1: TODO List (střed, initial)
          TodoListPage(),

          // Stránka 2: Pomodoro Timer
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
        return const Text('🍅 Pomodoro Timer');
      default:
        return const Text('TODO');
    }
  }
}
