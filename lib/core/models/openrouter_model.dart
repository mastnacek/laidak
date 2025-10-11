/// Model pro OpenRouter AI model z API
///
/// Reprezentuje dostupný AI model z OpenRouter API.
/// Endpoint: https://openrouter.ai/api/v1/models
class OpenRouterModel {
  final String id;
  final String name;
  final String? description;
  final double? promptPrice; // Cena za 1M input tokens ($)
  final double? completionPrice; // Cena za 1M output tokens ($)

  const OpenRouterModel({
    required this.id,
    required this.name,
    this.description,
    this.promptPrice,
    this.completionPrice,
  });

  /// Parse from JSON (z OpenRouter API)
  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    // Pricing může být v json['pricing'] objektu
    final pricing = json['pricing'] as Map<String, dynamic>?;

    return OpenRouterModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
      promptPrice: pricing != null
          ? double.tryParse(pricing['prompt']?.toString() ?? '0')
          : null,
      completionPrice: pricing != null
          ? double.tryParse(pricing['completion']?.toString() ?? '0')
          : null,
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

  /// Extrahovat vendor/provider z ID (např. "openai/gpt-4" → "openai")
  String get provider {
    final parts = id.split('/');
    if (parts.length > 1) {
      return parts.first;
    }
    return 'other';
  }

  /// Zjistit zda je model zdarma (FREE)
  bool get isFree {
    return (promptPrice == null || promptPrice == 0.0) &&
        (completionPrice == null || completionPrice == 0.0);
  }

  /// Průměrná cena za 1M tokenů (pro řazení)
  /// Vrací null pokud není pricing k dispozici
  double? get averagePrice {
    if (promptPrice == null && completionPrice == null) return null;
    final prompt = promptPrice ?? 0.0;
    final completion = completionPrice ?? 0.0;
    return (prompt + completion) / 2;
  }

  /// Formátovaná cena pro zobrazení v UI
  String get priceLabel {
    if (isFree) return '🆓 FREE';
    if (averagePrice == null) return '';

    final price = averagePrice!;
    if (price < 0.001) return '💲 <\$0.001';
    if (price < 1.0) return '💲 \$${price.toStringAsFixed(3)}';
    return '💲 \$${price.toStringAsFixed(2)}';
  }
}
