import 'package:intl/intl.dart';

/// Služba pro parsování tagů z textu úkolu
class TagParser {
  /// Parsovat text a extrahovat tagy, prioritu, datum, akci
  static ParsedTask parse(String input) {
    String? priority;
    DateTime? dueDate;
    String? action;
    final tags = <String>[];

    // RegEx pro nalezení všech *tagů*
    final tagRegex = RegExp(r'\*([^*]+)\*');
    final matches = tagRegex.allMatches(input);

    for (final match in matches) {
      final tagValue = match.group(1)?.toLowerCase();
      if (tagValue == null) continue;

      // Priorita: *a*, *b*, *c*
      if (tagValue == 'a' || tagValue == 'b' || tagValue == 'c') {
        priority = tagValue;
      }
      // Datum: *dnes*, *zitra*
      else if (tagValue == 'dnes') {
        dueDate = DateTime.now();
      } else if (tagValue == 'zitra') {
        dueDate = DateTime.now().add(const Duration(days: 1));
      }
      // Akce: *udelat*, *zavolat*, *napsat*, atd.
      else if (_isAction(tagValue)) {
        action = tagValue;
      }
      // Obecný tag
      else {
        tags.add(tagValue);
      }
    }

    // Odstranit všechny tagy z textu (včetně hvězdiček)
    final cleanText = input.replaceAll(tagRegex, '').trim();

    return ParsedTask(
      originalText: input,
      cleanText: cleanText,
      priority: priority,
      dueDate: dueDate,
      action: action,
      tags: tags,
    );
  }

  /// Zkontrolovat, zda je tag akční sloveso
  static bool _isAction(String tag) {
    const actions = [
      'udelat',
      'zavolat',
      'napsat',
      'koupit',
      'poslat',
      'pripravit',
      'domluvit',
      'zkontrolovat',
      'opravit',
      'nacist',
      'poslouchat',
    ];
    return actions.contains(tag);
  }

  /// Formátovat datum pro zobrazení
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'dnes';
    } else if (dateOnly == tomorrow) {
      return 'zítra';
    } else {
      return DateFormat('d.M.yyyy').format(date);
    }
  }

  /// Získat emoji ikonu pro prioritu
  static String getPriorityIcon(String? priority) {
    switch (priority) {
      case 'a':
        return '🔴'; // Vysoká priorita
      case 'b':
        return '🟡'; // Střední priorita
      case 'c':
        return '🟢'; // Nízká priorita
      default:
        return '';
    }
  }

  /// Získat emoji ikonu pro akci
  static String getActionIcon(String? action) {
    switch (action) {
      case 'udelat':
        return '✅';
      case 'zavolat':
        return '📞';
      case 'napsat':
        return '✍️';
      case 'koupit':
        return '🛒';
      case 'poslat':
        return '📤';
      case 'pripravit':
        return '🔧';
      case 'domluvit':
        return '🤝';
      case 'zkontrolovat':
        return '🔍';
      case 'opravit':
        return '🔨';
      case 'nacist':
        return '📖';
      case 'poslouchat':
        return '🎧';
      default:
        return '';
    }
  }
}

/// Výsledek parsování úkolu
class ParsedTask {
  final String originalText;
  final String cleanText;
  final String? priority;
  final DateTime? dueDate;
  final String? action;
  final List<String> tags;

  ParsedTask({
    required this.originalText,
    required this.cleanText,
    this.priority,
    this.dueDate,
    this.action,
    required this.tags,
  });
}
