import 'package:intl/intl.dart';
import '../models/tag_definition.dart';
import 'tag_service.dart';
import '../core/services/database_helper.dart';

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

  /// Parsovat text a extrahovat tagy, prioritu, datum
  static Future<ParsedTask> parse(String input) async {
    String? priority;
    DateTime? dueDate;
    final tags = <String>[];

    // RegEx pro nalezení všech tagů s aktuálními oddělovači
    final tagRegex = await _buildTagRegex();
    final matches = tagRegex.allMatches(input);

    for (final match in matches) {
      final tagValue = match.group(1)?.toLowerCase();
      if (tagValue == null) continue;

      // KRITICKÉ: Zkusit nejdřív parsovat jako datum (DD.MM.YYYY nebo s časem)
      // Tím zajistíme, že i *25.10.2025* nebo *25.10.2025 15:00* se parsuje jako datum
      final parsedDate = _parseDateTag(tagValue);
      if (parsedDate != null) {
        // Úspěšně parsováno jako datum → nastavit dueDate
        dueDate = parsedDate;
        continue; // Přeskočit zbylou logiku pro tento tag
      }

      // Pro date tagy s časem: extrahovat jen date část pro TagService lookup
      // Např: "dnes 15:30" → "dnes", "zítra 9.30" → "zítra", "dnes15:30" → "dnes"
      // Pattern: text před mezerou nebo před číslicí (pro podporu "dnes15:30")
      final tagValueForLookup = tagValue.split(RegExp(r'[\s\d]')).first;

      // O(1) lookup z TagService cache
      final definition = _tagService.getDefinition(tagValueForLookup);

      if (definition != null && definition.enabled) {
        // Tag je definovaný v databázi a je povolen
        switch (definition.tagType) {
          case TagType.priority:
            priority = tagValue;
            break;

          case TagType.date:
            // Už jsme zkusili parsovat výše, takže tady by to nemělo skončit
            // Ale pro jistotu zkusíme ještě jednou
            dueDate = _parseDateTag(tagValue);
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
      tags: tags,
    );
  }

  /// Parsovat datum tag a převést na DateTime
  ///
  /// Podporované formáty:
  /// - dnes, zítra, pozítří, zatyden, zamesic, zarok
  /// - dnes 14:00, dnes14:00, dnes 14, dnes14 (s/bez mezery, s/bez minut)
  /// - DD.MM.YYYY (jen datum)
  /// - DD.MM.YYYY 15:30, DD.MM.YYYY15:30 (s mezerou / bez mezery)
  /// - DD.MM.YYYY 15, DD.MM.202515 (zkrácený formát, jen hodiny)
  static DateTime? _parseDateTag(String tagValue) {
    final now = DateTime.now();

    // KRITICKÉ: Nejdřív zkusit DD.MM.YYYY formát s časem
    // Tím zajistíme, že "24.10.202515" se správně parsuje jako datum + hodina
    final ddmmyyyyResult = _parseDDMMYYYYWithTime(tagValue, now);
    if (ddmmyyyyResult != null) return ddmmyyyyResult;

    // Pokud to není DD.MM.YYYY → parsovat sémantické tagy (dnes, zítra, ...)
    return _parseSemanticDateWithTime(tagValue, now);
  }

  /// Parsovat DD.MM.YYYY s volitelným časem
  /// Podporuje: 24.10.2025, 24.10.2025 15:30, 24.10.202515:30, 24.10.2025 15, 24.10.202515
  static DateTime? _parseDDMMYYYYWithTime(String tagValue, DateTime now) {
    // 1. Regex pro DD.MM.YYYY (základ)
    final dateRegex = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})');
    final dateMatch = dateRegex.firstMatch(tagValue);

    if (dateMatch == null) return null; // Není DD.MM.YYYY formát

    // Extrahovat datum
    final day = int.tryParse(dateMatch.group(1)!);
    final month = int.tryParse(dateMatch.group(2)!);
    final year = int.tryParse(dateMatch.group(3)!);

    if (day == null || month == null || year == null) return null;

    // Vytvořit base date
    DateTime baseDate;
    try {
      baseDate = DateTime(year, month, day);
    } catch (e) {
      return null; // Nevalidní datum
    }

    // 2. Zkontrolovat, jestli za datem následuje čas
    final afterDate = tagValue.substring(dateMatch.end);

    if (afterDate.isEmpty) {
      // Jen datum bez času
      return baseDate;
    }

    // 3. Parsovat čas (s/bez mezery, s/bez minut)
    int? hour;
    int? minute;

    // 3a. Plný čas: "15:30" nebo " 15:30"
    final fullTimeMatch = RegExp(r'^\s?(\d{1,2}):(\d{2})$').firstMatch(afterDate);
    if (fullTimeMatch != null) {
      hour = int.tryParse(fullTimeMatch.group(1)!);
      minute = int.tryParse(fullTimeMatch.group(2)!);

      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null; // Nevalidní čas
      }

      return DateTime(year, month, day, hour, minute);
    }

    // 3b. Zkrácený čas: "15" nebo " 15"
    final shortTimeMatch = RegExp(r'^\s?(\d{1,2})$').firstMatch(afterDate);
    if (shortTimeMatch != null) {
      hour = int.tryParse(shortTimeMatch.group(1)!);

      if (hour == null || hour > 23) {
        return null; // Nevalidní hodiny
      }

      return DateTime(year, month, day, hour, 0); // Minuty = 0
    }

    // Nějaký divný formát za datem → ignorovat čas, vrátit jen datum
    return baseDate;
  }

  /// Parsovat sémantické date tagy (dnes, zítra, ...) s volitelným časem
  static DateTime? _parseSemanticDateWithTime(String tagValue, DateTime now) {
    // 1. Zkusit extrahovat čas z tagu (pokud existuje)
    int? hour;
    int? minute;
    String datePartOnly = tagValue;

    // 1a. Zkusit plný formát: hodiny + dvojtečka + minuty
    // Podporuje: "dnes 14:00", "dnes14:00"
    final timeMatch = RegExp(r'\s?(\d{1,2}):(\d{2})$').firstMatch(tagValue);

    if (timeMatch != null) {
      hour = int.tryParse(timeMatch.group(1)!);
      minute = int.tryParse(timeMatch.group(2)!);

      if (hour == null || minute == null || hour > 23 || minute > 59) {
        return null; // Nevalidní čas
      }

      datePartOnly = tagValue.substring(0, timeMatch.start).trim();
    } else {
      // 1b. Zkrácený formát: jen hodiny (automaticky :00)
      // Podporuje: "dnes 14", "dnes14"
      final shortTimeMatch = RegExp(r'\s?(\d{1,2})$').firstMatch(tagValue);

      if (shortTimeMatch != null) {
        hour = int.tryParse(shortTimeMatch.group(1)!);
        minute = 0;

        if (hour == null || hour > 23) {
          return null; // Nevalidní hodiny
        }

        datePartOnly = tagValue.substring(0, shortTimeMatch.start).trim();
      }
    }

    // 2. Parsovat sémantické datum
    DateTime? baseDate;

    switch (datePartOnly) {
      case 'dnes':
        baseDate = DateTime(now.year, now.month, now.day);
        break;

      case 'zitra':
        baseDate = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 1));
        break;

      case 'pozitri':
        baseDate = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 2));
        break;

      case 'zatyden':
        baseDate = DateTime(now.year, now.month, now.day)
            .add(const Duration(days: 7));
        break;

      case 'zamesic':
        baseDate = DateTime(now.year, now.month + 1, now.day);
        break;

      case 'zarok':
        baseDate = DateTime(now.year + 1, now.month, now.day);
        break;

      default:
        return null; // Neznámý sémantický tag
    }

    // 3. Přidat čas, pokud byl zadán
    if (hour != null && minute != null) {
      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
    }

    // 4. Bez času → vrátit pouze datum (00:00)
    return baseDate;
  }

  /// Formátovat datum pro zobrazení
  ///
  /// Vrací:
  /// - "dnes" nebo "dnes 14:00" (pokud má čas)
  /// - "zítra" nebo "zítra 9:30" (pokud má čas)
  /// - "pozítří" nebo "pozítří 16:00" (pokud má čas)
  /// - "14.10.2025" nebo "14.10.2025 16:45" (pokud má čas)
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Zkontrolovat, zda datum má čas (ne 00:00)
    final hasTime = date.hour != 0 || date.minute != 0;
    final timeStr = hasTime ? ' ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '';

    if (dateOnly == today) {
      return 'dnes$timeStr';
    } else if (dateOnly == tomorrow) {
      return 'zítra$timeStr';
    } else if (dateOnly == dayAfterTomorrow) {
      return 'pozítří$timeStr';
    } else {
      return '${DateFormat('d.M.yyyy').format(date)}$timeStr';
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
  final List<String> tags;

  ParsedTask({
    required this.originalText,
    required this.cleanText,
    this.priority,
    this.dueDate,
    required this.tags,
  });
}
