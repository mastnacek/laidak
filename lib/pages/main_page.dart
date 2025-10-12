import 'package:flutter/material.dart';
import '../core/theme/theme_colors.dart';
import '../features/help/presentation/pages/help_page.dart';
import '../features/todo_list/presentation/pages/todo_list_page.dart';
import '../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../features/todo_list/presentation/widgets/stats_row.dart';
import 'settings_page.dart';

/// MainPage - Hlavní stránka s PageView pro swipeable TODO List a Pomodoro
///
/// Layout:
/// - AppBar (Help + Stats + Settings) - sdílený pro obě stránky
/// - PageView s 2 stránkami:
///   1. TodoListPage (index 0)
///   2. PomodoroPage (index 1)
///
/// Gesture:
/// - Swipe doleva → přejdi na Pomodoro
/// - Swipe doprava → vrať se na TODO List
///
/// AppBar je fixní a nescrolluje se s obsahem.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // PageController pro správu PageView
  final PageController _pageController = PageController(initialPage: 0);

  // Aktuální index stránky (0 = TODO List, 1 = Pomodoro)
  int _currentPageIndex = 0;

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
        // Stats uprostřed (zobrazí se pouze na TODO List stránce)
        title: _currentPageIndex == 0
            ? const StatsRow() // TODO List stats
            : const Text('🍅 Pomodoro Timer'), // Pomodoro title
        centerTitle: _currentPageIndex == 1, // Center only for Pomodoro
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

      // PageView s 2 stránkami (swipeable)
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          // Stránka 0: TODO List
          TodoListPage(),

          // Stránka 1: Pomodoro Timer
          PomodoroPage(),
        ],
      ),
    );
  }
}
