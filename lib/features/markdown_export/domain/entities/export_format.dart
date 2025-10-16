/// Export formát pro markdown soubory
enum ExportFormat {
  /// Výchozí formát - náš custom syntax s oddělovači *tag*
  default_,

  /// Obsidian formát - frontmatter + #hashtags + [[backlinks]]
  obsidian,
}

extension ExportFormatExtension on ExportFormat {
  /// Displayovaný název pro UI
  String get displayName {
    switch (this) {
      case ExportFormat.default_:
        return 'Výchozí (vlastní tagy)';
      case ExportFormat.obsidian:
        return 'Obsidian (frontmatter)';
    }
  }

  /// Popis formátu
  String get description {
    switch (this) {
      case ExportFormat.default_:
        return 'Náš custom syntax: *tag*, *a*, *#123*';
      case ExportFormat.obsidian:
        return 'Standardní Obsidian: YAML frontmatter, #hashtags, [[backlinks]]';
    }
  }
}
