/// Model pro OpenRouter AI model z API
///
/// Reprezentuje dostupný AI model z OpenRouter API.
/// Endpoint: https://openrouter.ai/api/v1/models
class OpenRouterModel {
  final String id;
  final String name;
  final String? description;

  const OpenRouterModel({
    required this.id,
    required this.name,
    this.description,
  });

  /// Parse from JSON (z OpenRouter API)
  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    return OpenRouterModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
    );
  }

  /// User-friendly display name (krátký)
  String get displayName {
    // Pokud name je příliš dlouhý, zkrátit
    if (name.length > 50) {
      return '${name.substring(0, 47)}...';
    }
    return name;
  }

  /// Krátký label pro dropdown (id bez vendor prefix)
  String get shortLabel {
    // Odstranit vendor prefix (např. "openai/gpt-4" → "gpt-4")
    final parts = id.split('/');
    if (parts.length > 1) {
      return parts.sublist(1).join('/');
    }
    return id;
  }
}
