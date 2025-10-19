import '../entities/recurrence_rule.dart';
import '../enums/recur_type.dart';

/// Služba pro výpočet dalšího termínu opakování (Todoist model)
class RecurrenceGenerator {
  /// Vypočítat další termín od currentDate podle recurrence rule
  ///
  /// [rule] - Recurrence pravidlo
  /// [currentDate] - Aktuální termín (Todo.dueDate)
  ///
  /// Returns: DateTime dalšího termínu, nebo null pokud chyba
  static DateTime? calculateNextDate({
    required RecurrenceRule rule,
    required DateTime currentDate,
  }) {
    // Normalize to midnight to avoid DST issues
    final current = DateTime(currentDate.year, currentDate.month, currentDate.day);

    switch (rule.recurType.toRecurType()) {
      case RecurType.daily:
        return DateTime(
          current.year,
          current.month,
          current.day + rule.interval,
        );

      case RecurType.weekly:
        return DateTime(
          current.year,
          current.month,
          current.day + (7 * rule.interval),
        );

      case RecurType.monthly:
        return DateTime(
          current.year,
          current.month + rule.interval,
          rule.dayOfMonth ?? current.day,
        );

      case RecurType.yearly:
        return DateTime(
          current.year + rule.interval,
          current.month,
          current.day,
        );

      case null:
        // Invalid recurType
        return null;
    }
  }

  /// Formátovat frekvenci pro UI (např. "denně", "každé 2 týdny")
  ///
  /// [rule] - Recurrence pravidlo
  ///
  /// Returns: String popisující frekvenci v češtině
  static String formatRecurrenceFrequency(RecurrenceRule rule) {
    final interval = rule.interval;

    switch (rule.recurType.toRecurType()) {
      case RecurType.daily:
        return interval == 1 ? 'denně' : 'každé $interval dny';

      case RecurType.weekly:
        return interval == 1 ? 'týdně' : 'každé $interval týdny';

      case RecurType.monthly:
        return interval == 1 ? 'měsíčně' : 'každé $interval měsíce';

      case RecurType.yearly:
        return interval == 1 ? 'ročně' : 'každé $interval roky';

      case null:
        return 'opakování';
    }
  }
}
