import '../../../../core/services/database_helper.dart';

/// NotesTagParser - Service pro parsování tagů z poznámek (MILESTONE 3)
///
/// Podporuje následující patterny (s dynamickými oddělovači z DB):
/// - *tag* → běžný tag (stejně jako v TODO)
/// - *#123* → link na TODO úkol (zatím jen parsing, linking později)
/// - *[[Note]]* → link na jinou poznámku (parsing, linking Phase 2)
///
/// KONZISTENTNÍ s TODO TagParser - používá DYNAMICKÉ oddělovače z nastavení!
class NotesTagParser {
  static final DatabaseHelper _db = DatabaseHelper();

  /// Získat aktuální nastavení oddělovačů z databáze
  static Future<Map<String, String>> _getDelimiters() async {
    final settings = await _db.getSettings();
    return {
      'start': settings['tag_delimiter_start'] as String? ?? '*',
      'end': settings['tag_delimiter_end'] as String? ?? '*',
    };
  }

  /// Vytvořit RegEx pattern pro běžné tagy s dynamickými oddělovači
  static Future<RegExp> _buildTagRegex() async {
    final delimiters = await _getDelimiters();
    final start = RegExp.escape(delimiters['start']!);
    final end = RegExp.escape(delimiters['end']!);

    // Pattern: start + word characters + end
    return RegExp('$start(\\w+)$end');
  }

  /// Vytvořit RegEx pattern pro TODO linky s dynamickými oddělovači
  static Future<RegExp> _buildTodoLinkRegex() async {
    final delimiters = await _getDelimiters();
    final start = RegExp.escape(delimiters['start']!);
    final end = RegExp.escape(delimiters['end']!);

    // Pattern: start + #digits + end
    return RegExp('$start#(\\d+)$end');
  }

  /// Vytvořit RegEx pattern pro Note linky s dynamickými oddělovači
  static Future<RegExp> _buildNoteLinkRegex() async {
    final delimiters = await _getDelimiters();
    final start = RegExp.escape(delimiters['start']!);
    final end = RegExp.escape(delimiters['end']!);

    // Pattern: start + [[text]] + end
    return RegExp('$start\\[\\[([^\\]]+)\\]\\]$end');
  }

  /// Parse všechny tagy z textu poznámky
  ///
  /// Vrací:
  /// - tags: běžné tagy (["projekt-x", "nápad"])
  /// - todoLinks: odkazy na TODO úkoly (["123", "456"])
  /// - noteLinks: odkazy na poznámky (["Meeting Notes", "Q4 Roadmap"])
  static Future<ParsedNoteTags> parse(String content) async {
    final tags = <String>[];
    final todoLinks = <String>[];
    final noteLinks = <String>[];

    // Načíst regex patterny s aktuálními oddělovači
    final tagPattern = await _buildTagRegex();
    final todoLinkPattern = await _buildTodoLinkRegex();
    final noteLinkPattern = await _buildNoteLinkRegex();

    // 1. Extract běžné tagy (ale ignoruj #123 a [[...]])
    for (final match in tagPattern.allMatches(content)) {
      final tag = match.group(1)!;

      // Skip pokud je to TODO link (#123) nebo Note link
      if (!tag.startsWith('#') && !tag.startsWith('[[')) {
        tags.add(tag.toLowerCase()); // Lowercase pro konzistenci s TODO
      }
    }

    // 2. Extract TODO linky
    for (final match in todoLinkPattern.allMatches(content)) {
      final todoId = match.group(1)!;
      todoLinks.add(todoId);
    }

    // 3. Extract Note linky
    for (final match in noteLinkPattern.allMatches(content)) {
      final noteName = match.group(1)!;
      noteLinks.add(noteName);
    }

    return ParsedNoteTags(
      tags: tags,
      todoLinks: todoLinks,
      noteLinks: noteLinks,
    );
  }

  /// Validovat zda text obsahuje alespoň jeden tag
  static Future<bool> hasAnyTag(String content) async {
    final tagPattern = await _buildTagRegex();
    final todoLinkPattern = await _buildTodoLinkRegex();
    final noteLinkPattern = await _buildNoteLinkRegex();

    return tagPattern.hasMatch(content) ||
        todoLinkPattern.hasMatch(content) ||
        noteLinkPattern.hasMatch(content);
  }

  /// Extrahovat pouze běžné tagy (bez TODO/Note linků)
  static Future<List<String>> extractTags(String content) async {
    final result = await parse(content);
    return result.tags;
  }

  /// Extrahovat pouze TODO linky
  static Future<List<String>> extractTodoLinks(String content) async {
    final result = await parse(content);
    return result.todoLinks;
  }

  /// Extrahovat pouze Note linky
  static Future<List<String>> extractNoteLinks(String content) async {
    final result = await parse(content);
    return result.noteLinks;
  }
}

/// Result objekt pro parsed tagy
class ParsedNoteTags {
  final List<String> tags; // Běžné tagy
  final List<String> todoLinks; // TODO link IDs
  final List<String> noteLinks; // Note link names/IDs

  const ParsedNoteTags({
    required this.tags,
    required this.todoLinks,
    required this.noteLinks,
  });

  /// Celkový počet všech tagů a linků
  int get totalCount => tags.length + todoLinks.length + noteLinks.length;

  /// Je prázdný?
  bool get isEmpty => totalCount == 0;

  /// Má nějaké tagy?
  bool get isNotEmpty => totalCount > 0;

  @override
  String toString() {
    return 'ParsedNoteTags(tags: $tags, todoLinks: $todoLinks, noteLinks: $noteLinks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParsedNoteTags &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.todoLinks, todoLinks) &&
        _listEquals(other.noteLinks, noteLinks);
  }

  @override
  int get hashCode {
    return tags.hashCode ^ todoLinks.hashCode ^ noteLinks.hashCode;
  }

  /// Helper: porovnání dvou listů
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
