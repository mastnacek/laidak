/// Typy tagů v systému
enum TagType {
  priority, // Priorita: *a*, *b*, *c*
  date, // Datum: *dnes*, *zitra*, *zatyden*, *zamesic*, *zarok*
  status, // Status: *hotove*, *todo*
  custom, // Custom tagy: *rodina*, *prace*, atd.
}

/// Rozšíření pro práci s TagType enum
extension TagTypeExtension on TagType {
  /// Převést na string pro databázi
  String toDbString() {
    return toString().split('.').last;
  }

  /// Převést z string z databáze
  static TagType fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'priority':
        return TagType.priority;
      case 'date':
        return TagType.date;
      case 'status':
        return TagType.status;
      case 'custom':
        return TagType.custom;
      default:
        return TagType.custom;
    }
  }

  /// Získat lidsky čitelný název typu
  String get displayName {
    switch (this) {
      case TagType.priority:
        return 'Priorita';
      case TagType.date:
        return 'Termín';
      case TagType.status:
        return 'Status';
      case TagType.custom:
        return 'Vlastní';
    }
  }
}

/// Model pro definici tagu (konfigurovatelné systémové tagy)
class TagDefinition {
  final int? id;
  final String tagName; // název tagu bez hvězdiček, např. "a", "dnes"
  final TagType tagType; // typ tagu
  final String? displayName; // zobrazovaný název, např. "Vysoká priorita"
  final String? emoji; // emoji pro zobrazení
  final String? color; // hex barva pro zvýraznění
  final int sortOrder; // pořadí zobrazení v rámci typu
  final bool enabled; // je tag povolen?

  TagDefinition({
    this.id,
    required this.tagName,
    required this.tagType,
    this.displayName,
    this.emoji,
    this.color,
    this.sortOrder = 0,
    this.enabled = true,
  });

  /// Převést na Map pro SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag_name': tagName.toLowerCase(),
      'tag_type': tagType.toDbString(),
      'display_name': displayName,
      'emoji': emoji,
      'color': color,
      'sort_order': sortOrder,
      'enabled': enabled ? 1 : 0,
    };
  }

  /// Vytvořit z Map (ze SQLite)
  factory TagDefinition.fromMap(Map<String, dynamic> map) {
    return TagDefinition(
      id: map['id'] as int?,
      tagName: (map['tag_name'] as String).toLowerCase(),
      tagType: TagTypeExtension.fromDbString(map['tag_type'] as String),
      displayName: map['display_name'] as String?,
      emoji: map['emoji'] as String?,
      color: map['color'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 1) == 1,
    );
  }

  /// Vytvořit kopii s upravenými hodnotami
  TagDefinition copyWith({
    int? id,
    String? tagName,
    TagType? tagType,
    String? displayName,
    String? emoji,
    String? color,
    int? sortOrder,
    bool? enabled,
  }) {
    return TagDefinition(
      id: id ?? this.id,
      tagName: tagName ?? this.tagName,
      tagType: tagType ?? this.tagType,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  String toString() {
    return 'TagDefinition(id: $id, tagName: $tagName, tagType: $tagType, displayName: $displayName, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TagDefinition &&
        other.id == id &&
        other.tagName == tagName &&
        other.tagType == tagType;
  }

  @override
  int get hashCode {
    return id.hashCode ^ tagName.hashCode ^ tagType.hashCode;
  }
}
