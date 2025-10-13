/// NotesTagParser - Service pro parsování tagů z poznámek (MILESTONE 3)
///
/// Podporuje následující patterny:
/// - *tag* → běžný tag (stejně jako v TODO)
/// - *#123* → link na TODO úkol (zatím jen parsing, linking později)
/// - *[[Note]]* → link na jinou poznámku (parsing, linking Phase 2)
///
/// Konzistentní s existujícím TODO tag systémem (TagParser).
class NotesTagParser {
  /// Regex pro běžné tagy: *tag*
  static final RegExp _tagPattern = RegExp(r'\*(\w+)\*');

  /// Regex pro TODO linky: *#123*
  static final RegExp _todoLinkPattern = RegExp(r'\*#(\d+)\*');

  /// Regex pro Note linky: *[[text]]*
  static final RegExp _noteLinkPattern = RegExp(r'\*\[\[([^\]]+)\]\]\*');

  /// Parse všechny tagy z textu poznámky
  ///
  /// Vrací:
  /// - tags: běžné tagy (["projekt-x", "nápad"])
  /// - todoLinks: odkazy na TODO úkoly (["123", "456"])
  /// - noteLinks: odkazy na poznámky (["Meeting Notes", "Q4 Roadmap"])
  static ParsedNoteTags parse(String content) {
    final tags = <String>[];
    final todoLinks = <String>[];
    final noteLinks = <String>[];

    // 1. Extract běžné tagy (ale ignoruj #123 a [[...]])
    for (final match in _tagPattern.allMatches(content)) {
      final tag = match.group(1)!;

      // Skip pokud je to TODO link (#123) nebo Note link
      if (!tag.startsWith('#') && !tag.startsWith('[[')) {
        tags.add(tag);
      }
    }

    // 2. Extract TODO linky
    for (final match in _todoLinkPattern.allMatches(content)) {
      final todoId = match.group(1)!;
      todoLinks.add(todoId);
    }

    // 3. Extract Note linky
    for (final match in _noteLinkPattern.allMatches(content)) {
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
  static bool hasAnyTag(String content) {
    return _tagPattern.hasMatch(content) ||
        _todoLinkPattern.hasMatch(content) ||
        _noteLinkPattern.hasMatch(content);
  }

  /// Extrahovat pouze běžné tagy (bez TODO/Note linků)
  static List<String> extractTags(String content) {
    return parse(content).tags;
  }

  /// Extrahovat pouze TODO linky
  static List<String> extractTodoLinks(String content) {
    return parse(content).todoLinks;
  }

  /// Extrahovat pouze Note linky
  static List<String> extractNoteLinks(String content) {
    return parse(content).noteLinks;
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
