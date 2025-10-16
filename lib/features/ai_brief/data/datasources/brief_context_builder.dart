import 'package:intl/intl.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../domain/entities/brief_config.dart';

/// Context Builder pro AI Brief
///
/// Odpovídá za sestavení strukturovaného user contextu pro AI
/// Format podle brief.md řádky 249-313
class BriefContextBuilder {
  /// Sestaví strukturovaný user context z úkolů
  ///
  /// Format:
  /// ```
  /// CURRENT TIME: 2025-10-13T10:30:00Z
  /// DAY: Pondělí (13.10.2025)
  ///
  /// --- ACTIVE TASKS ---
  /// (nehotové úkoly)
  ///
  /// --- COMPLETED TASKS ---
  /// (hotové úkoly podle config timeframes)
  ///
  /// --- USER STATS ---
  /// Completed today: X tasks
  /// Active tasks: Y tasks
  /// ...
  /// ```
  static String buildUserContext(List<Todo> tasks, BriefConfig config) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // Header - aktuální čas a den
    buffer.writeln('CURRENT TIME: ${now.toIso8601String()}');
    buffer.writeln('DAY: ${_getDayOfWeek(now)} (${_formatDate(now)})');
    buffer.writeln();

    // Filtr: aktivní úkoly (nehotové)
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();

    // Filtr: completed úkoly podle config timeframes
    final completedTasks = _filterCompletedTasks(tasks, config, now);

    // --- ACTIVE TASKS ---
    buffer.writeln('--- ACTIVE TASKS ---');
    buffer.writeln();

    for (final task in activeTasks) {
      buffer.writeln('TASK_ID: ${task.id}');
      buffer.writeln('Text: ${task.task}');
      buffer.writeln('Priority: ${task.priority ?? "none"} (a=high, b=medium, c=low)');

      // Due Date s urgency výpočtem
      if (task.dueDate != null) {
        final urgency = _calculateUrgency(task.dueDate!, now);
        buffer.writeln('Due Date: ${_formatDateTime(task.dueDate!)} ($urgency)');
      } else {
        buffer.writeln('Due Date: none');
      }

      buffer.writeln('Status: active');
      buffer.writeln('Tags: ${task.tags.isEmpty ? "none" : task.tags.join(", ")}');
      buffer.writeln();
    }

    // --- COMPLETED TASKS ---
    if (completedTasks.isNotEmpty) {
      buffer.writeln('--- COMPLETED TASKS ---');
      buffer.writeln();

      for (final task in completedTasks) {
        buffer.writeln('TASK_ID: ${task.id}');
        buffer.writeln('Text: ${task.task}');
        buffer.writeln('Priority: ${task.priority ?? "none"}');
        buffer.writeln('Completed at: ${task.completedAt != null ? _formatDateTime(task.completedAt!) : "unknown"}');
        buffer.writeln('Tags: ${task.tags.isEmpty ? "none" : task.tags.join(", ")}');
        buffer.writeln();
      }
    }

    // --- USER STATS ---
    final completedToday = tasks.where((t) =>
      t.isCompleted &&
      t.completedAt != null &&
      _isToday(t.completedAt!)
    ).length;

    final completedWeek = tasks.where((t) =>
      t.isCompleted &&
      t.completedAt != null &&
      _isThisWeek(t.completedAt!, now)
    ).length;

    buffer.writeln('--- USER STATS ---');
    buffer.writeln();
    buffer.writeln('Completed today: $completedToday tasks');
    buffer.writeln('Completed this week: $completedWeek tasks');
    buffer.writeln('Active tasks: ${activeTasks.length}');

    return buffer.toString();
  }

  /// Filtruje completed úkoly podle BriefConfig timeframes
  static List<Todo> _filterCompletedTasks(List<Todo> tasks, BriefConfig config, DateTime now) {
    final completed = tasks.where((t) => t.isCompleted && t.completedAt != null).toList();

    // Pokud includeCompletedAll je true, vrátit všechny
    if (config.includeCompletedAll) {
      return completed;
    }

    // Jinak filtruj podle timeframes
    return completed.where((t) {
      final completedAt = t.completedAt!;

      if (config.includeCompletedToday && _isToday(completedAt)) return true;
      if (config.includeCompletedWeek && _isThisWeek(completedAt, now)) return true;
      if (config.includeCompletedMonth && _isThisMonth(completedAt, now)) return true;
      if (config.includeCompletedYear && _isThisYear(completedAt, now)) return true;

      return false;
    }).toList();
  }

  /// Vypočítá urgency popis pro deadline
  ///
  /// Examples:
  /// - "OVERDUE by 5h"
  /// - "in 2h (URGENT!)"
  /// - "today at 14:00"
  /// - "in 3 days"
  static String _calculateUrgency(DateTime dueDate, DateTime now) {
    final diff = dueDate.difference(now);

    if (diff.isNegative) {
      // OVERDUE
      final hoursOverdue = -diff.inHours;
      final daysOverdue = -diff.inDays;

      if (daysOverdue > 0) {
        return 'OVERDUE by $daysOverdue days';
      } else {
        return 'OVERDUE by $hoursOverdue hours';
      }
    }

    // Future deadline
    final hoursUntil = diff.inHours;
    final daysUntil = diff.inDays;

    if (hoursUntil < 2) {
      return 'in ${hoursUntil}h (URGENT!)';
    } else if (daysUntil == 0) {
      return 'today at ${_formatTime(dueDate)}';
    } else if (daysUntil == 1) {
      return 'tomorrow at ${_formatTime(dueDate)}';
    } else if (daysUntil <= 7) {
      return 'in $daysUntil days';
    } else {
      return 'in ${(daysUntil / 7).ceil()} weeks';
    }
  }

  /// Získá název dne v týdnu (česky)
  static String _getDayOfWeek(DateTime date) {
    const days = [
      'Pondělí',
      'Úterý',
      'Středa',
      'Čtvrtek',
      'Pátek',
      'Sobota',
      'Neděle',
    ];
    return days[date.weekday - 1];
  }

  /// Formátuje datum (DD.MM.YYYY)
  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  /// Formátuje datum a čas (YYYY-MM-DD HH:mm)
  static String _formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// Formátuje čas (HH:mm)
  static String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Zkontroluje, zda je datum dnes
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Zkontroluje, zda je datum tento týden
  static bool _isThisWeek(DateTime date, DateTime now) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
           date.isBefore(endOfWeek);
  }

  /// Zkontroluje, zda je datum tento měsíc
  static bool _isThisMonth(DateTime date, DateTime now) {
    return date.year == now.year && date.month == now.month;
  }

  /// Zkontroluje, zda je datum tento rok
  static bool _isThisYear(DateTime date, DateTime now) {
    return date.year == now.year;
  }
}
