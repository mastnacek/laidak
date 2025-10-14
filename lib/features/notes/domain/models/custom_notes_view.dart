import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Custom Notes View definice (tag-based filtr)
///
/// Umožňuje uživateli vytvořit vlastní pohled na poznámky filtrované podle tagu.
/// Identický princip jako CustomAgendaView pro TODO úkoly.
/// Například: "projekt" = Projekty, "nakup" = Nákupy (bez oddělovačů *)
class CustomNotesView extends Equatable {
  /// Unikátní ID (UUID)
  final String id;

  /// Název view (zobrazený v InfoDialog)
  final String name;

  /// Tag(y) pro filtrování
  /// - Single tag: "projekt"
  /// - Multiple tags (CSV): "programovani,todoapp"
  /// Poznámky se zobrazí pokud obsahují JAKÝKOLIV z těchto tagů (OR logika)
  final String tagFilter;

  /// Emoji ikona (např. "📁", "🛒", "⚽")
  final String emoji;

  /// Zapnuto/vypnuto (zobrazit v FoldersTabBar)
  final bool isEnabled;

  const CustomNotesView({
    required this.id,
    required this.name,
    required this.tagFilter,
    required this.emoji,
    this.isEnabled = true, // Default zapnuto
  });

  /// Serialization pro Database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tag_filter': tagFilter.toLowerCase(),
      'emoji': emoji,
      'enabled': isEnabled ? 1 : 0,
    };
  }

  /// Deserialization z JSON
  factory CustomNotesView.fromJson(Map<String, dynamic> json) {
    return CustomNotesView(
      id: json['id'] as String,
      name: json['name'] as String,
      tagFilter: json['tag_filter'] as String,
      emoji: json['emoji'] as String? ?? '📁', // Default emoji pokud chybí
      isEnabled: (json['enabled'] as int? ?? 1) == 1, // Default zapnuto
    );
  }

  /// CopyWith pro immutable updates
  CustomNotesView copyWith({
    String? id,
    String? name,
    String? tagFilter,
    String? emoji,
    bool? isEnabled,
  }) {
    return CustomNotesView(
      id: id ?? this.id,
      name: name ?? this.name,
      tagFilter: tagFilter ?? this.tagFilter,
      emoji: emoji ?? this.emoji,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Helper: Rozdělit tagFilter na seznam jednotlivých tagů
  ///
  /// Příklady:
  /// - "projekt" → ["projekt"]
  /// - "programovani,todoapp" → ["programovani", "todoapp"]
  /// - "  work , home  " → ["work", "home"] (trimuje whitespace)
  List<String> get tags {
    return tagFilter
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [id, name, tagFilter, emoji, isEnabled];

  @override
  String toString() {
    return 'CustomNotesView(id: $id, name: $name, tagFilter: $tagFilter, emoji: $emoji, isEnabled: $isEnabled)';
  }
}
