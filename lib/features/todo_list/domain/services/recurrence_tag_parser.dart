import '../entities/recurrence_rule.dart';
import '../enums/recur_type.dart';

/// Výsledek parsování recurrence tagu
class RecurrenceInfo {
  final RecurType recurType;
  final int interval;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int? dayOfWeek; // 0-6 (Monday-Sunday)
  final int? dayOfMonth; // 1-31

  const RecurrenceInfo({
    required this.recurType,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.dayOfWeek,
    this.dayOfMonth,
  });

  /// Vytvořit RecurrenceRule z RecurrenceInfo
  RecurrenceRule toRecurrenceRule(int todoId) {
    return RecurrenceRule(
      todoId: todoId,
      recurType: recurType.toDbString(),
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      createdAt: DateTime.now(),
    );
  }
}

/// Base class pro parsované tagy
abstract class ParsedTag {
  final String originalTag;
  const ParsedTag(this.originalTag);
}

/// Tag s jedním datem (bez recurrence)
class SingleDateTag extends ParsedTag {
  final DateTime date;
  const SingleDateTag(super.originalTag, this.date);
}

/// Tag s recurrence suffixem (d/t/m/r)
class RecurrenceTag extends ParsedTag {
  final RecurrenceInfo info;
  const RecurrenceTag(super.originalTag, this.info);
}

/// Parser pro recurrence tagy
///
/// Podporované syntaxe:
/// - *dnest* → weekly from today
/// - *dnes t* → same (space allowed)
/// - *dnes2t* → every 2 weeks
/// - *20.10.2025t* → weekly from specific date
/// - *po t* → every Monday (weekly)
/// - *po 2t* → every 2nd Monday (bi-weekly)
/// - Suffix: d/t/m/r (daily/týdně/měsíčně/ročně)
class RecurrenceTagParser {
  /// Parse task text a vrátí RecurrenceInfo pokud najde recurrence tag
  ///
  /// [taskText] - kompletní text úkolu
  /// [tagDelimiterStart] - počáteční oddělovač tagů (např. '*', '#')
  /// [tagDelimiterEnd] - koncový oddělovač tagů (např. '*', '#')
  ///
  /// Vrací první nalezený recurrence tag nebo null.
  static RecurrenceInfo? parse(
    String taskText, {
    String tagDelimiterStart = '*',
    String tagDelimiterEnd = '*',
  }) {
    final tags = _extractTags(taskText, tagDelimiterStart, tagDelimiterEnd);

    for (final tag in tags) {
      final recurrenceTag = _parseTag(tag);
      if (recurrenceTag is RecurrenceTag) {
        return recurrenceTag.info;
      }
    }

    return null;
  }

  /// Extrahuj všechny tagy z task textu
  static List<String> _extractTags(
    String taskText,
    String start,
    String end,
  ) {
    final tags = <String>[];

    // Escape special regex characters
    final startEscaped = RegExp.escape(start);
    final endEscaped = RegExp.escape(end);

    final pattern = RegExp('$startEscaped([^$endEscaped]+)$endEscaped');
    final matches = pattern.allMatches(taskText);

    for (final match in matches) {
      final tagContent = match.group(1)?.trim();
      if (tagContent != null && tagContent.isNotEmpty) {
        tags.add(tagContent);
      }
    }

    return tags;
  }

  /// Parse jednotlivý tag a vrátí ParsedTag
  static ParsedTag? _parseTag(String tag) {
    // Trim whitespace
    final cleaned = tag.trim();

    // Check for recurrence suffix (d/t/m/r)
    final recurrenceSuffix = _extractRecurrenceSuffix(cleaned);
    if (recurrenceSuffix != null) {
      return _parseRecurrenceTag(cleaned, recurrenceSuffix);
    }

    // Try parse as single date tag
    final date = _parseDate(cleaned);
    if (date != null) {
      return SingleDateTag(tag, date);
    }

    return null; // Not a date or recurrence tag
  }

  /// Extrahuj recurrence suffix z tagu (např. "dnest" → RecurrenceSuffix(type: weekly, interval: 1))
  static _RecurrenceSuffix? _extractRecurrenceSuffix(String tag) {
    // Pattern: text + optional number + suffix (d/t/m/r)
    // Examples: "dnest", "dnes2t", "dnes 3m", "20.10.2025 t"

    // Pro DD.MM.YYYY formát, interval se nebere (aby "2025t" nevzal "5" jako interval)
    final hasDot = tag.contains('.');
    final pattern = hasDot
        ? RegExp(r'([dtmr])$', caseSensitive: false)  // Pouze suffix, bez intervalu
        : RegExp(r'(\d*)([dtmr])$', caseSensitive: false);  // S intervalem

    final match = pattern.firstMatch(tag);
    if (match == null) return null;

    String intervalStr;
    String suffix;

    if (hasDot) {
      // Pro datum: pouze suffix (group 1), žádný interval
      intervalStr = '';
      suffix = match.group(1)!.toLowerCase();
    } else {
      // Pro normální text: group 1 = interval, group 2 = suffix
      intervalStr = match.group(1) ?? '';
      suffix = match.group(2)!.toLowerCase();
    }

    final interval = intervalStr.isNotEmpty
        ? int.tryParse(intervalStr) ?? 1
        : 1;

    final recurType = suffix.fromTagSuffix();
    if (recurType == null) return null;

    return _RecurrenceSuffix(recurType: recurType, interval: interval);
  }

  /// Parse recurrence tag
  static RecurrenceTag? _parseRecurrenceTag(String tag, _RecurrenceSuffix suffix) {
    // Remove suffix from tag to get base date part
    final basePart = tag.substring(0, tag.length - suffix.length).trim();

    // Try parse weekday (po, ut, st, ct, pa, so, ne)
    final weekday = _parseWeekday(basePart);
    if (weekday != null) {
      return _createWeekdayRecurrence(tag, weekday, suffix);
    }

    // Try parse date (dnes, zitra, pozitri, zatyden, 20.10.2025)
    final date = _parseDate(basePart);
    if (date != null) {
      return _createDateRecurrence(tag, date, suffix);
    }

    return null; // Invalid recurrence tag
  }

  /// Parse weekday z českého názvu (po, ut, st, ct, pa, so, ne)
  static int? _parseWeekday(String text) {
    final lower = text.toLowerCase().trim();

    switch (lower) {
      case 'po': return DateTime.monday;    // 1
      case 'ut': return DateTime.tuesday;   // 2
      case 'st': return DateTime.wednesday; // 3
      case 'ct': return DateTime.thursday;  // 4
      case 'pa': return DateTime.friday;    // 5
      case 'so': return DateTime.saturday;  // 6
      case 'ne': return DateTime.sunday;    // 7
      default: return null;
    }
  }

  /// Parse datum z textu
  static DateTime? _parseDate(String text) {
    final lower = text.toLowerCase().trim();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // České date tagy
    switch (lower) {
      case 'dnes':
        return today;
      case 'zitra':
        return today.add(const Duration(days: 1));
      case 'pozitri':
        return today.add(const Duration(days: 2));
      case 'zatyden':
        return today.add(const Duration(days: 7));
      case 'zamesic':
        return DateTime(today.year, today.month + 1, today.day);
      case 'zarok':
        return DateTime(today.year + 1, today.month, today.day);
    }

    // DD.MM.YYYY format
    final datePattern = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
    final match = datePattern.firstMatch(text);

    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (e) {
          return null; // Invalid date
        }
      }
    }

    return null;
  }

  /// Vytvoř weekday recurrence (např. "po t" → každé pondělí)
  static RecurrenceTag _createWeekdayRecurrence(
    String originalTag,
    int weekday,
    _RecurrenceSuffix suffix,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find next occurrence of this weekday
    final daysUntilWeekday = (weekday - today.weekday) % 7;
    final nextOccurrence = daysUntilWeekday == 0
        ? today
        : today.add(Duration(days: daysUntilWeekday));

    final info = RecurrenceInfo(
      recurType: suffix.recurType,
      interval: suffix.interval,
      startDate: nextOccurrence,
      dayOfWeek: weekday - 1, // Convert to 0-indexed (0 = Monday)
    );

    return RecurrenceTag(originalTag, info);
  }

  /// Vytvoř date recurrence (např. "dnes t" → týdně od dneška)
  static RecurrenceTag _createDateRecurrence(
    String originalTag,
    DateTime date,
    _RecurrenceSuffix suffix,
  ) {
    int? dayOfWeek;
    int? dayOfMonth;

    // Pro weekly recurrence uložit day of week
    if (suffix.recurType == RecurType.weekly) {
      dayOfWeek = date.weekday - 1; // 0-indexed
    }

    // Pro monthly recurrence uložit day of month
    if (suffix.recurType == RecurType.monthly) {
      dayOfMonth = date.day;
    }

    final info = RecurrenceInfo(
      recurType: suffix.recurType,
      interval: suffix.interval,
      startDate: date,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
    );

    return RecurrenceTag(originalTag, info);
  }
}

/// Helper class pro parsed recurrence suffix
class _RecurrenceSuffix {
  final RecurType recurType;
  final int interval;

  const _RecurrenceSuffix({
    required this.recurType,
    required this.interval,
  });

  /// Délka suffixu v charakterech (např. "2t" = 2, "t" = 1)
  int get length {
    final intervalStr = interval > 1 ? interval.toString() : '';
    return intervalStr.length + 1; // +1 for suffix letter
  }
}
