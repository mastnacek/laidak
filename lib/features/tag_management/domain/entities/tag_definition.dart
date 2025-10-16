import 'package:equatable/equatable.dart';

/// Typy tagů v systému
enum TagType {
  priority, // Priorita: *a*, *b*, *c*
  date, // Datum: *dnes*, *zitra*, *zatyden*, *zamesic*, *zarok*
  status, // Status: *hotove*, *todo*
  custom, // Custom tagy: *rodina*, *prace*, atd.
}

/// Rozšíření pro práci s TagType enum
extension TagTypeExtension on TagType {
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
}

/// Domain Entity pro definici tagu (konfigurovatelné systémové tagy)
///
/// Pure domain object bez závislostí na databázi nebo framework
class TagDefinition extends Equatable {
  final int? id;
  final String tagName; // název tagu bez hvězdiček, např. "a", "dnes"
  final TagType tagType; // typ tagu
  final String? displayName; // zobrazovaný název, např. "Vysoká priorita"
  final String? emoji; // emoji pro zobrazení
  final String? color; // hex barva pro zvýraznění
  final bool glowEnabled; // je zapnutý glow efekt?
  final double glowStrength; // síla glow efektu (0.0 - 1.0)
  final int sortOrder; // pořadí zobrazení v rámci typu
  final bool enabled; // je tag povolen?

  const TagDefinition({
    this.id,
    required this.tagName,
    required this.tagType,
    this.displayName,
    this.emoji,
    this.color,
    this.glowEnabled = false,
    this.glowStrength = 0.5,
    this.sortOrder = 0,
    this.enabled = true,
  });

  /// Vytvořit kopii s upravenými hodnotami
  TagDefinition copyWith({
    int? id,
    String? tagName,
    TagType? tagType,
    String? displayName,
    String? emoji,
    String? color,
    bool? glowEnabled,
    double? glowStrength,
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
      glowEnabled: glowEnabled ?? this.glowEnabled,
      glowStrength: glowStrength ?? this.glowStrength,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tagName,
        tagType,
        displayName,
        emoji,
        color,
        glowEnabled,
        glowStrength,
        sortOrder,
        enabled,
      ];

  @override
  String toString() {
    return 'TagDefinition(id: $id, tagName: $tagName, tagType: $tagType, displayName: $displayName, enabled: $enabled)';
  }
}
