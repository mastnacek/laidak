import '../entities/tag_definition.dart';

/// Repository interface pro správu tagů
///
/// Definuje kontrakt pro přístup k tag definitions bez specifikace implementace
abstract class TagManagementRepository {
  /// Načíst všechny tag definitions z databáze
  Future<List<TagDefinition>> getAllDefinitions();

  /// Přidat novou tag definition
  Future<void> addDefinition(TagDefinition definition);

  /// Aktualizovat existující tag definition
  Future<void> updateDefinition(TagDefinition definition);

  /// Smazat tag definition
  Future<void> deleteDefinition(int id);

  /// Zapnout/vypnout tag definition
  Future<void> toggleDefinition(int id, bool enabled);

  /// Načíst tag definition podle názvu
  Future<TagDefinition?> getDefinitionByName(String tagName);

  /// Načíst všechny aktivní (enabled) tag definitions
  Future<List<TagDefinition>> getEnabledDefinitions();
}
