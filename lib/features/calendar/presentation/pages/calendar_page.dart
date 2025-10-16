import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/presentation/bloc/todo_list_bloc.dart';
import '../../../todo_list/presentation/bloc/todo_list_state.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../todo_list/presentation/widgets/todo_card.dart';

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
    final theme = Theme.of(context);

    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        return switch (state) {
          TodoListInitial() => const Center(
              child: Text('Inicializace kalendáře...'),
            ),
          TodoListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          TodoListLoaded() => _buildCalendarView(context, state, theme),
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
    ThemeColors theme,
  ) {
    return Column(
      children: [
        // TableCalendar
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
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
                    theme,
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
          child: _buildTasksForDay(context, state, theme),
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
    ThemeColors theme,
  ) {
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
          _buildDot(context, theme.appColors.red, priorities['a']!),
        if (priorities['b'] != null)
          _buildDot(context, theme.appColors.yellow, priorities['b']!),
        if (priorities['c'] != null)
          _buildDot(context, theme.appColors.green, priorities['c']!),
      ],
    );
  }

  /// Vytvořit jednu tečku s počtem úkolů
  Widget _buildDot(BuildContext context, Color color, int count) {
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
    ThemeColors theme,
  ) {
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
}
