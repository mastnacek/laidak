import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Custom Agenda View definice (tag-based filtr)
///
/// Umožňuje uživateli vytvořit vlastní pohled na úkoly filtrované podle tagu.
/// Například: "***" = Oblíbené úkoly, "#projekt" = Projekty
class CustomAgendaView extends Equatable {
  /// Unikátní ID (UUID)
  final String id;

  /// Název view (zobrazený v InfoDialog)
  final String name;

  /// Tag pro filtrování (např. "***", "#projekt")
  final String tagFilter;

  /// Ikona (Material Icons code point)
  final int iconCodePoint;

  /// Barva (optional, hex string)
  final String? colorHex;

  const CustomAgendaView({
    required this.id,
    required this.name,
    required this.tagFilter,
    required this.iconCodePoint,
    this.colorHex,
  });

  /// Helper: IconData z code pointu
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

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
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
    };
  }

  /// Deserialization z JSON
  factory CustomAgendaView.fromJson(Map<String, dynamic> json) {
    return CustomAgendaView(
      id: json['id'] as String,
      name: json['name'] as String,
      tagFilter: json['tagFilter'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorHex: json['colorHex'] as String?,
    );
  }

  /// CopyWith pro immutable updates
  CustomAgendaView copyWith({
    String? id,
    String? name,
    String? tagFilter,
    int? iconCodePoint,
    String? colorHex,
  }) {
    return CustomAgendaView(
      id: id ?? this.id,
      name: name ?? this.name,
      tagFilter: tagFilter ?? this.tagFilter,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, name, tagFilter, iconCodePoint, colorHex];
}
