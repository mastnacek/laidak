import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/presentation/bloc/todo_list_bloc.dart';
import '../../../todo_list/presentation/bloc/todo_list_event.dart';
import '../../../todo_list/presentation/bloc/todo_list_state.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../todo_list/presentation/widgets/todo_card.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../../../pages/main_page.dart';

/// CalendarPage - Kalendár s přehledem úkolů (5. tab PageView)
///
/// Layout:
/// - TableCalendar (měsíční pohled) - interactive
/// - Selected day tasks - ListView s TODO cards pro vybraný den
///
/// Features:
/// - Event markers (barevné tečky podle priority úkolů)
/// - Day selection → zobrazí úkoly pro tento den
/// - Priority visualization: červená (*a*), žlutá (*b*), zelená (*c*)
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        return switch (state) {
          TodoListInitial() => const Center(
              child: Text('Inicializace kalendáře...'),
            ),
          TodoListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          TodoListLoaded() => _buildCalendarView(context, state),
          TodoListError() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: theme.appColors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Chyba při načítání kalendáře',
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
                ],
              ),
            ),
        };
      },
    );
  }

  /// Sestavit kalendář + seznam úkolů pro vybraný den
  Widget _buildCalendarView(
    BuildContext context,
    TodoListLoaded state,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // TableCalendar
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: TableCalendar(
              key: ValueKey(state.allTodos.length), // Force rebuild při změně dat
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              locale: 'cs_CZ', // Česká lokalizace (měsíce + dny v češtině)
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              // Event loader - načíst úkoly pro tento den
              eventLoader: (day) {
                return _getTodosForDate(state.allTodos, day);
              },
              // User tap na den
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              // User long press na den - přepnout na TodoListPage s date tagem
              onDayLongPressed: (selectedDay, focusedDay) {
                _handleDayLongPress(context, selectedDay);
              },
              // Výchozí nastavení calendáře
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.fg,
                ),
                formatButtonVisible: false,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: theme.appColors.cyan,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: theme.appColors.cyan,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                // Vybraný den - highlight
                selectedDecoration: BoxDecoration(
                  color: theme.appColors.cyan.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.appColors.cyan,
                    width: 2,
                  ),
                ),
                // Dnešek - highlight s tečkou
                todayDecoration: BoxDecoration(
                  color: theme.appColors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.appColors.green,
                    width: 1,
                  ),
                ),
                // Standardní dni
                defaultTextStyle: TextStyle(
                  color: theme.appColors.fg,
                ),
                weekendTextStyle: TextStyle(
                  color: theme.appColors.yellow,
                ),
                outsideTextStyle: TextStyle(
                  color: theme.appColors.base5.withOpacity(0.5),
                ),
              ),
              // Custom marker builder - barevné tečky podle priority
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return _buildPriorityMarkers(
                    context,
                    events.cast<Todo>(),
                  );
                },
              ),
            ),
          ),
        ),
        // Divider
        Divider(
          height: 1,
          color: theme.appColors.base3.withOpacity(0.3),
        ),
        // Tasks for selected day
        Expanded(
          flex: 1,
          child: _buildTasksForDay(context, state),
        ),
      ],
    );
  }

  /// Načíst úkoly pro zadaný den
  List<Todo> _getTodosForDate(List<Todo> allTodos, DateTime date) {
    return allTodos.where((todo) {
      if (todo.dueDate == null) return false;

      // Porovnat pouze datum (ignorovat čas)
      final todoDate = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );

      final targetDate = DateTime(date.year, date.month, date.day);

      return todoDate == targetDate;
    }).toList();
  }

  /// Vytvořit barevné tečky podle priority úkolů
  Widget _buildPriorityMarkers(
    BuildContext context,
    List<Todo> todos,
  ) {
    final theme = Theme.of(context);

    // Grupovat podle priority
    final priorities = <String, int>{};
    for (final todo in todos) {
      final priority = todo.priority ?? 'none';
      priorities[priority] = (priorities[priority] ?? 0) + 1;
    }

    // Zobrazit barevné tečky
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (priorities['a'] != null)
          _buildDot(theme.appColors.red, priorities['a']!),
        if (priorities['b'] != null)
          _buildDot(theme.appColors.yellow, priorities['b']!),
        if (priorities['c'] != null)
          _buildDot(theme.appColors.green, priorities['c']!),
      ],
    );
  }

  /// Vytvořit jednu tečku s počtem úkolů
  Widget _buildDot(Color color, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Vytvořit seznam úkolů pro vybraný den
  Widget _buildTasksForDay(
    BuildContext context,
    TodoListLoaded state,
  ) {
    final theme = Theme.of(context);

    if (_selectedDay == null) {
      return Center(
        child: Text(
          'Vyber den',
          style: TextStyle(
            fontSize: 16,
            color: theme.appColors.base5,
          ),
        ),
      );
    }

    final tasksForDay = _getTodosForDate(state.allTodos, _selectedDay!);

    if (tasksForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.appColors.base5.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Žádné úkoly na tento den',
              style: TextStyle(
                fontSize: 16,
                color: theme.appColors.fg,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Schváleno! Odpočívej 🎉',
              style: TextStyle(
                fontSize: 12,
                color: theme.appColors.green,
              ),
            ),
          ],
        ),
      );
    }

    // ListView s TodoCards
    return ListView.builder(
      itemCount: tasksForDay.length,
      itemBuilder: (context, index) {
        final todo = tasksForDay[index];
        return TodoCard(
          key: ValueKey('calendar_todo_${todo.id}'),
          todo: todo,
          isExpanded: state.expandedTodoId == todo.id,
        );
      },
    );
  }

  /// Handler pro dlouhé podržení na dni - přepnout na TodoListPage s date tagem
  void _handleDayLongPress(BuildContext context, DateTime selectedDay) {
    // 1. Získat nastavení oddělovačů tagů
    final settingsState = context.read<SettingsCubit>().state;

    if (settingsState is SettingsLoaded) {
      final startDelim = settingsState.tagDelimiterStart;
      final endDelim = settingsState.tagDelimiterEnd;

      // 2. Vytvořit tag pro datum
      final dateTag = _createDateTag(selectedDay, startDelim, endDelim);

      // 3. Přepnout na TodoListPage s předvyplněným textem
      _navigateToTodoListWithTag(context, dateTag);
    }
  }

  /// Vytvořit date tag podle vybraného dne
  String _createDateTag(DateTime date, String startDelim, String endDelim) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final selectedDateOnly = DateTime(date.year, date.month, date.day);

    // Použít sémantické tagy kde to dává smysl
    // KRITICKÉ: Tag NENÍ uzavřený, aby uživatel mohl doplnit čas
    // Ale BEZ trailing mezery - tu si uživatel přidá sám při psaní
    if (selectedDateOnly == today) {
      return '${startDelim}dnes';
    } else if (selectedDateOnly == tomorrow) {
      return '${startDelim}zitra';
    } else if (selectedDateOnly == dayAfterTomorrow) {
      return '${startDelim}pozitri';
    } else {
      // Pro ostatní dny použít formát DD.MM.YYYY (kompatibilní s TagParser)
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      return '$startDelim$dateStr';
    }
  }

  /// Navigovat na TodoListPage s předvyplněným textem
  void _navigateToTodoListWithTag(BuildContext context, String dateTag) {
    // 1. KRITICKÉ: Získat BLoC referenci PŘED navigací
    // Context může být disposed během animace!
    final todoListBloc = context.read<TodoListBloc>();

    // 2. Najít MainPageState a získat PageController
    final mainPageState = context.findAncestorStateOfType<MainPageState>();
    if (mainPageState != null) {
      // 3. Přepnout na TodoListPage (index 1)
      final animationFuture = mainPageState.pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // 4. Počkat až se dokončí animace a odeslat event
      // Použijeme uloženou BLoC referenci (ne context.read!)
      animationFuture.then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Nepoužíváme context.mounted check - máme přímou referenci
          todoListBloc.add(PrepopulateInputEvent(text: dateTag));
        });
      });
    }
  }
}
