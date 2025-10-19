import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Custom Agenda View definice (tag-based filtr)
///
/// Umožňuje uživateli vytvořit vlastní pohled na úkoly filtrované podle tagu.
/// Například: "projekt" = Projekty, "nakup" = Nákupy (bez oddělovačů *)
class CustomAgendaView extends Equatable {
  /// Unikátní ID (UUID)
  final String id;

  /// Název view (zobrazený v InfoDialog)
  final String name;

  /// Tag pro filtrování (např. "projekt", "nakup", "sport" - bez oddělovačů)
  final String tagFilter;

  /// Emoji ikona (např. "📁", "🛒", "⚽")
  final String emoji;

  /// Barva (optional, hex string)
  final String? colorHex;

  /// Zapnuto/vypnuto (zobrazit v ViewBar)
  final bool isEnabled;

  const CustomAgendaView({
    required this.id,
    required this.name,
    required this.tagFilter,
    required this.emoji,
    this.colorHex,
    this.isEnabled = true, // Default zapnuto
  });

  /// Helper: Color z hex stringu
  Color? get color => colorHex != null
      ? Color(int.parse(colorHex!.substring(1), radix: 16) + 0xFF000000)
      : null;

  /// Serialization pro SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagFilter': tagFilter,
      'emoji': emoji,
      'colorHex': colorHex,
      'isEnabled': isEnabled,
    };
  }

  /// Deserialization z JSON
  factory CustomAgendaView.fromJson(Map<String, dynamic> json) {
    return CustomAgendaView(
      id: json['id'] as String,
      name: json['name'] as String,
      tagFilter: json['tagFilter'] as String,
      emoji: json['emoji'] as String? ?? '📁', // Default emoji pokud chybí
      colorHex: json['colorHex'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? true, // Default zapnuto
    );
  }

  /// CopyWith pro immutable updates
  CustomAgendaView copyWith({
    String? id,
    String? name,
    String? tagFilter,
    String? emoji,
    String? colorHex,
    bool? isEnabled,
  }) {
    return CustomAgendaView(
      id: id ?? this.id,
      name: name ?? this.name,
      tagFilter: tagFilter ?? this.tagFilter,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [id, name, tagFilter, emoji, colorHex, isEnabled];
}
