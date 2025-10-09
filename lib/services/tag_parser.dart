import 'package:intl/intl.dart';
import '../models/tag_definition.dart';
import 'tag_service.dart';
import 'database_helper.dart';

/// Služba pro parsování tagů z textu úkolu
///
/// Využívá TagService pro O(1) lookup definic tagů místo hardcoded if-else
/// Podporuje konfigurovatelné oddělovače tagů (*, @, !, atd.)
class TagParser {
  static final TagService _tagService = TagService();
  static final DatabaseHelper _db = DatabaseHelper();

  /// Získat aktuální nastavení oddělovačů z databáze
  static Future<Map<String, String>> _getDelimiters() async {
    final settings = await _db.getSettings();
    return {
      'start': settings['tag_delimiter_start'] as String? ?? '*',
      'end': settings['tag_delimiter_end'] as String? ?? '*',
    };
  }

  /// Vytvořit RegEx pattern pro aktuální oddělovače
  static Future<RegExp> _buildTagRegex() async {
    final delimiters = await _getDelimiters();
    final start = RegExp.escape(delimiters['start']!);
    final end = RegExp.escape(delimiters['end']!);

    // Pattern: start + obsah + end
    return RegExp('$start([^$end]+)$end');
  }

  /// Parsovat text a extrahovat tagy, prioritu, datum, akci
  static Future<ParsedTask> parse(String input) async {
    String? priority;
    DateTime? dueDate;
    String? action;
    final tags = <String>[];

    // RegEx pro nalezení všech tagů s aktuálními oddělovači
    final tagRegex = await _buildTagRegex();
    final matches = tagRegex.allMatches(input);

    for (final match in matches) {
      final tagValue = match.group(1)?.toLowerCase();
      if (tagValue == null) continue;

      // O(1) lookup z TagService cache
      final definition = _tagService.getDefinition(tagValue);

      if (definition != null && definition.enabled) {
        // Tag je definovaný v databázi a je povolen
        switch (definition.tagType) {
          case TagType.priority:
            priority = tagValue;
            break;

          case TagType.date:
            dueDate = _parseDateTag(tagValue);
            break;

          case TagType.action:
            action = tagValue;
            break;

          case TagType.status:
            // Status tagy můžeme přidat do custom tags nebo ignorovat
            tags.add(tagValue);
            break;

          case TagType.custom:
            tags.add(tagValue);
            break;
        }
      } else {
        // Tag není definovaný nebo je vypnutý → přidat jako custom tag
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

  /// Parsovat datum tag a převést na DateTime
  static DateTime? _parseDateTag(String tagValue) {
    final now = DateTime.now();

    switch (tagValue) {
      case 'dnes':
        return DateTime(now.year, now.month, now.day);

      case 'zitra':
        return DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1));

      case 'zatyden':
        return DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 7));

      case 'zamesic':
        return DateTime(now.year, now.month + 1, now.day);

      case 'zarok':
        return DateTime(now.year + 1, now.month, now.day);

      default:
        // Zkusit parsovat DD.MM.YYYY formát
        return _parseDateFormat(tagValue);
    }
  }

  /// Parsovat datum ve formátu DD.MM.YYYY
  static DateTime? _parseDateFormat(String input) {
    final dateRegex = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$');
    final match = dateRegex.firstMatch(input);

    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (e) {
          return null;
        }
      }
    }

    return null;
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

  /// Získat emoji ikonu pro prioritu (z TagService)
  static String getPriorityIcon(String? priority) {
    if (priority == null) return '';

    final definition = _tagService.getDefinition(priority);
    return definition?.emoji ?? '';
  }

  /// Získat emoji ikonu pro akci (z TagService)
  static String getActionIcon(String? action) {
    if (action == null) return '';

    final definition = _tagService.getDefinition(action);
    return definition?.emoji ?? '';
  }

  /// Získat emoji ikonu pro jakýkoliv tag (univerzální)
  static String getTagIcon(String tag) {
    final definition = _tagService.getDefinition(tag);
    return definition?.emoji ?? '';
  }

  /// Získat barvu pro tag (z TagService)
  static String? getTagColor(String tag) {
    final definition = _tagService.getDefinition(tag);
    return definition?.color;
  }

  /// Rekonstruovat text s tagy z TodoItem (pro editaci)
  static Future<String> reconstructWithTags({
    required String cleanText,
    String? priority,
    DateTime? dueDate,
    String? action,
    List<String>? tags,
  }) async {
    final delimiters = await _getDelimiters();
    final start = delimiters['start']!;
    final end = delimiters['end']!;

    final buffer = StringBuffer();

    // Přidat prioritu
    if (priority != null) {
      buffer.write('$start$priority$end ');
    }

    // Přidat datum
    if (dueDate != null) {
      final dateTag = formatDate(dueDate);
      buffer.write('$start$dateTag$end ');
    }

    // Přidat akci
    if (action != null) {
      buffer.write('$start$action$end ');
    }

    // Přidat čistý text
    buffer.write(cleanText);

    // Přidat obecné tagy na konec
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        buffer.write(' $start$tag$end');
      }
    }

    return buffer.toString();
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
