import 'package:equatable/equatable.dart';

/// Model pro AI tag suggestion
///
/// Reprezentuje jeden navržený tag od AI, včetně informace zda jde
/// o existující tag z databáze nebo nový návrh.
class TagSuggestion extends Equatable {
  /// Název tagu (např. "práce", "nakup", "dnes")
  final String tagName;

  /// True = existující tag z databáze, False = nový návrh od AI
  final bool isExisting;

  /// Confidence score 0.0-1.0 (jak moc si je AI jistá)
  final double confidence;

  /// Barva tagu z tag_definitions (hex string, např. "#ff0000")
  /// Pouze pro existující tagy, null pro nové návrhy
  final String? color;

  /// Emoji z tag_definitions (např. "🔴", "⏰")
  /// Pouze pro existující tagy, null pro nové návrhy
  final String? emoji;

  const TagSuggestion({
    required this.tagName,
    required this.isExisting,
    required this.confidence,
    this.color,
    this.emoji,
  });

  /// Factory constructor z JSON response od OpenRouter API
  factory TagSuggestion.fromJson(Map<String, dynamic> json) {
    return TagSuggestion(
      tagName: json['tag'] as String,
      isExisting: json['existing'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Konverze na JSON (pro debugging/logging)
  Map<String, dynamic> toJson() {
    return {
      'tag': tagName,
      'existing': isExisting,
      'confidence': confidence,
    };
  }

  @override
  List<Object?> get props => [tagName, isExisting, confidence, color, emoji];

  @override
  String toString() {
    return 'TagSuggestion(tag: $tagName, existing: $isExisting, confidence: $confidence)';
  }
}
