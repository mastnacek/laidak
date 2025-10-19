/// OpenRouter Provider Routing Options
///
/// Určuje, jak OpenRouter vybírá provider pro AI request.
enum ProviderRoute {
  /// 🎯 Default - automatický výběr
  /// OpenRouter balancuje mezi rychlostí, cenou a dostupností
  default_('default'),

  /// 💰 :floor - nejlevnější provider
  /// Prioritizuje nejlevnější provider (úspora 50-70%)
  /// Doporučeno pro Brief generování a batch operace
  floor('floor'),

  /// ⚡ :nitro - nejrychlejší provider
  /// Prioritizuje nejrychlejší provider (vyšší cena)
  /// Vhodné pro real-time chat a interaktivní features
  nitro('nitro');

  final String value;
  const ProviderRoute(this.value);

  /// Konverze z String → Enum
  static ProviderRoute fromString(String value) {
    switch (value) {
      case 'floor':
        return ProviderRoute.floor;
      case 'nitro':
        return ProviderRoute.nitro;
      case 'default':
      default:
        return ProviderRoute.default_;
    }
  }

  /// Konverze Enum → String
  @override
  String toString() => value;

  /// User-friendly label pro UI
  String get displayName {
    switch (this) {
      case ProviderRoute.default_:
        return '🎯 Default';
      case ProviderRoute.floor:
        return '💰 :floor';
      case ProviderRoute.nitro:
        return '⚡ :nitro';
    }
  }

  /// Popis pro UI subtitle
  String get description {
    switch (this) {
      case ProviderRoute.default_:
        return 'Automatický výběr';
      case ProviderRoute.floor:
        return 'Nejlevnější provider (💰 úspora ~70%)';
      case ProviderRoute.nitro:
        return 'Nejrychlejší provider';
    }
  }

  /// Suffix pro model ID (např. "model:floor")
  String get modelSuffix {
    if (this == ProviderRoute.default_) return '';
    return ':$value';
  }
}
