import 'package:intl/intl.dart';
import '../../../../models/todo_item.dart';

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
  /// --- TASKS ---
  ///
  /// TASK_ID: 5
  /// Text: Dokončit prezentaci
  /// Priority: a (high)
  /// Due Date: 2025-10-13 14:00 (in 2 hours)
  /// Subtasks: 2/5 completed
  /// Status: active
  /// Tags: work, urgent
  /// ...
  /// ```
  static String buildUserContext(List<TodoItem> tasks) {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // Header - aktuální čas a den
    buffer.writeln('CURRENT TIME: ${now.toIso8601String()}');
    buffer.writeln('DAY: ${_getDayOfWeek(now)} (${_formatDate(now)})');
    buffer.writeln();
    buffer.writeln('--- TASKS ---');
    buffer.writeln();

    // Filtr: jen aktivní úkoly (nehotové)
    final activeTasks = tasks.where((t) => !t.isCompleted).toList();

    // Vypsat všechny aktivní úkoly
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

      // Subtasks (pokud máme data - zatím nemáme v TodoItem, ale můžeme přidat později)
      // Prozatím skip

      buffer.writeln('Status: ${task.isCompleted ? "completed" : "active"}');
      buffer.writeln('Tags: ${task.tags.isEmpty ? "none" : task.tags.join(", ")}');
      buffer.writeln();
    }

    // User stats - kolik úkolů dokončil dnes
    final completedToday = tasks.where((t) =>
      t.isCompleted &&
      _isToday(t.createdAt) // POZOR: TodoItem nemá completedAt, použiju createdAt jako fallback
    ).length;

    buffer.writeln('--- USER STATS ---');
    buffer.writeln();
    buffer.writeln('Completed today: $completedToday tasks');
    buffer.writeln('Active tasks: ${activeTasks.length}');

    return buffer.toString();
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
}
