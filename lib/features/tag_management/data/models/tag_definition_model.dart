import '../../domain/entities/tag_definition.dart';

/// Data Model pro TagDefinition s SQLite mapping
///
/// Rozšiřuje domain entitu o databázové operace (toMap, fromMap)
class TagDefinitionModel extends TagDefinition {
  const TagDefinitionModel({
    super.id,
    required super.tagName,
    required super.tagType,
    super.displayName,
    super.emoji,
    super.color,
    super.glowEnabled,
    super.glowStrength,
    super.sortOrder,
    super.enabled,
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
      'glow_enabled': glowEnabled ? 1 : 0,
      'glow_strength': glowStrength,
      'sort_order': sortOrder,
      'enabled': enabled ? 1 : 0,
    };
  }

  /// Vytvořit z Map (ze SQLite)
  factory TagDefinitionModel.fromMap(Map<String, dynamic> map) {
    return TagDefinitionModel(
      id: map['id'] as int?,
      tagName: (map['tag_name'] as String).toLowerCase(),
      tagType: TagTypeExtension.fromDbString(map['tag_type'] as String),
      displayName: map['display_name'] as String?,
      emoji: map['emoji'] as String?,
      color: map['color'] as String?,
      glowEnabled: (map['glow_enabled'] as int? ?? 0) == 1,
      glowStrength: (map['glow_strength'] as num?)?.toDouble() ?? 0.5,
      sortOrder: map['sort_order'] as int? ?? 0,
      enabled: (map['enabled'] as int? ?? 1) == 1,
    );
  }

  /// Převést z domain entity na data model
  factory TagDefinitionModel.fromEntity(TagDefinition entity) {
    return TagDefinitionModel(
      id: entity.id,
      tagName: entity.tagName,
      tagType: entity.tagType,
      displayName: entity.displayName,
      emoji: entity.emoji,
      color: entity.color,
      glowEnabled: entity.glowEnabled,
      glowStrength: entity.glowStrength,
      sortOrder: entity.sortOrder,
      enabled: entity.enabled,
    );
  }

  /// Převést na domain entity
  TagDefinition toEntity() {
    return TagDefinition(
      id: id,
      tagName: tagName,
      tagType: tagType,
      displayName: displayName,
      emoji: emoji,
      color: color,
      glowEnabled: glowEnabled,
      glowStrength: glowStrength,
      sortOrder: sortOrder,
      enabled: enabled,
    );
  }
}
