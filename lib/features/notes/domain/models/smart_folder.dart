import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'filter_rules.dart';

/// Smart Folder model pro Notes
///
/// Reprezentuje uživatelsky definovaný nebo systémový folder s pravidly filtrování.
/// Podporuje tag-based filtering, date ranges, a recent notes filtering.
class SmartFolder extends Equatable {
  final int? id;
  final String name;
  final String icon;
  final bool isSystem; // true = built-in folder (All, Recent, Favorites)
  final FilterRules filterRules;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SmartFolder({
    this.id,
    required this.name,
    required this.icon,
    required this.isSystem,
    required this.filterRules,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Vytvořit SmartFolder z DB map
  factory SmartFolder.fromMap(Map<String, dynamic> map) {
    return SmartFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isSystem: (map['is_system'] as int) == 1,
      filterRules: FilterRules.fromJson(
        jsonDecode(map['filter_rules'] as String),
      ),
      displayOrder: map['display_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Převést SmartFolder na DB map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'is_system': isSystem ? 1 : 0,
      'filter_rules': jsonEncode(filterRules.toJson()),
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Vytvořit kopii s upravenými hodnotami
  SmartFolder copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isSystem,
    FilterRules? filterRules,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      filterRules: filterRules ?? this.filterRules,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        isSystem,
        filterRules,
        displayOrder,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'SmartFolder(id: $id, name: $name, icon: $icon, isSystem: $isSystem, filterRules: $filterRules, displayOrder: $displayOrder)';
  }
}
