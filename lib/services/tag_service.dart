import '../models/tag_definition.dart';
import '../core/services/database_helper.dart';

/// Singleton služba pro správu tagů s cachingem pro rychlý přístup
///
/// Výhody caching:
/// - O(1) lookup místo O(n) regex matching při každém parsování
/// - Načtení definic pouze jednou při startu aplikace
/// - Automatická invalidace cache při změně definic
class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;

  TagService._internal();

  final DatabaseHelper _db = DatabaseHelper();

  /// Cache pro definice tagů (key = tag_name lowercase)
  Map<String, TagDefinition> _definitionsCache = {};

  /// Příznak, zda byla cache inicializována
  bool _isInitialized = false;

  /// Inicializovat service a načíst tagy do cache
  Future<void> init() async {
    if (_isInitialized) return;

    await _loadDefinitionsIntoCache();
    _isInitialized = true;
  }

  /// Načíst všechny povolené definice do cache
  Future<void> _loadDefinitionsIntoCache() async {
    final maps = await _db.getEnabledTagDefinitions();
    _definitionsCache = {
      for (var map in maps)
        (map['tag_name'] as String).toLowerCase():
            TagDefinition.fromMap(map)
    };
  }

  /// Invalidovat cache a znovu načíst (zavolat po změně definic)
  Future<void> refreshCache() async {
    await _loadDefinitionsIntoCache();
  }

  /// Získat definici tagu podle názvu (O(1) lookup z cache)
  TagDefinition? getDefinition(String tagName) {
    if (!_isInitialized) {
      throw StateError(
          'TagService nebyla inicializována! Zavolej init() před použitím.');
    }

    return _definitionsCache[tagName.toLowerCase()];
  }

  /// Zkontrolovat, zda tag existuje a je povolen
  bool isTagEnabled(String tagName) {
    final def = getDefinition(tagName);
    return def != null && def.enabled;
  }

  /// Získat všechny definice z cache
  List<TagDefinition> getAllDefinitions() {
    if (!_isInitialized) {
      throw StateError(
          'TagService nebyla inicializována! Zavolej init() před použitím.');
    }

    return _definitionsCache.values.toList()
      ..sort((a, b) {
        final typeCompare = a.tagType.index.compareTo(b.tagType.index);
        if (typeCompare != 0) return typeCompare;
        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  /// Získat definice podle typu
  List<TagDefinition> getDefinitionsByType(TagType type) {
    return getAllDefinitions()
        .where((def) => def.tagType == type)
        .toList();
  }

  /// Získat definice pro prioritu
  List<TagDefinition> getPriorityDefinitions() {
    return getDefinitionsByType(TagType.priority);
  }

  /// Získat definice pro datum
  List<TagDefinition> getDateDefinitions() {
    return getDefinitionsByType(TagType.date);
  }

  /// Získat definice pro akci
  List<TagDefinition> getActionDefinitions() {
    return getDefinitionsByType(TagType.action);
  }

  /// Získat definice pro status
  List<TagDefinition> getStatusDefinitions() {
    return getDefinitionsByType(TagType.status);
  }

  // ==================== CRUD operace (s auto-refresh cache) ====================

  /// Přidat novou definici
  Future<int> addDefinition(TagDefinition definition) async {
    final id = await _db.insertTagDefinition(definition.toMap());
    await refreshCache();
    return id;
  }

  /// Aktualizovat definici
  Future<void> updateDefinition(TagDefinition definition) async {
    if (definition.id == null) {
      throw ArgumentError('TagDefinition musí mít id pro update');
    }

    await _db.updateTagDefinition(definition.id!, definition.toMap());
    await refreshCache();
  }

  /// Smazat definici
  Future<void> deleteDefinition(int id) async {
    await _db.deleteTagDefinition(id);
    await refreshCache();
  }

  /// Zapnout/vypnout tag
  Future<void> toggleDefinition(int id, bool enabled) async {
    await _db.toggleTagDefinition(id, enabled);
    await refreshCache();
  }

  /// Načíst všechny definice z databáze (pro admin GUI)
  Future<List<TagDefinition>> loadAllDefinitionsFromDb() async {
    final maps = await _db.getAllTagDefinitions();
    return maps.map((map) => TagDefinition.fromMap(map)).toList();
  }
}
