import '../../../../models/tag_definition.dart' as old_model;
import '../../../../services/tag_service.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/repositories/tag_management_repository.dart';

/// Implementace TagManagementRepository využívající existující TagService
///
/// Adaptér mezi TagService (starý kód) a novým BLoC repository pattern
class TagManagementRepositoryImpl implements TagManagementRepository {
  final TagService _tagService;

  TagManagementRepositoryImpl(this._tagService);

  @override
  Future<List<TagDefinition>> getAllDefinitions() async {
    // TagService vrací staré modely z lib/models/tag_definition.dart
    // Potřebujeme je převést na nové domain entity
    final oldModels = await _tagService.loadAllDefinitionsFromDb();

    // Převést staré modely na nové domain entity
    return oldModels.map((oldModel) {
      return TagDefinition(
        id: oldModel.id,
        tagName: oldModel.tagName,
        tagType: _convertTagType(oldModel.tagType),
        displayName: oldModel.displayName,
        emoji: oldModel.emoji,
        color: oldModel.color,
        glowEnabled: oldModel.glowEnabled,
        glowStrength: oldModel.glowStrength,
        sortOrder: oldModel.sortOrder,
        enabled: oldModel.enabled,
      );
    }).toList();
  }

  @override
  Future<void> addDefinition(TagDefinition definition) async {
    // Převést domain entity na starý model pro TagService
    final oldModel = _convertToOldModel(definition);
    await _tagService.addDefinition(oldModel);
  }

  @override
  Future<void> updateDefinition(TagDefinition definition) async {
    final oldModel = _convertToOldModel(definition);
    await _tagService.updateDefinition(oldModel);
  }

  @override
  Future<void> deleteDefinition(int id) async {
    await _tagService.deleteDefinition(id);
  }

  @override
  Future<void> toggleDefinition(int id, bool enabled) async {
    await _tagService.toggleDefinition(id, enabled);
  }

  @override
  Future<TagDefinition?> getDefinitionByName(String tagName) async {
    final oldModel = _tagService.getDefinition(tagName);
    if (oldModel == null) return null;

    return TagDefinition(
      id: oldModel.id,
      tagName: oldModel.tagName,
      tagType: _convertTagType(oldModel.tagType),
      displayName: oldModel.displayName,
      emoji: oldModel.emoji,
      color: oldModel.color,
      glowEnabled: oldModel.glowEnabled,
      glowStrength: oldModel.glowStrength,
      sortOrder: oldModel.sortOrder,
      enabled: oldModel.enabled,
    );
  }

  @override
  Future<List<TagDefinition>> getEnabledDefinitions() async {
    final allDefs = await getAllDefinitions();
    return allDefs.where((def) => def.enabled).toList();
  }

  /// Helper: Převést novou domain entitu na starý model (z lib/models/tag_definition.dart)
  ///
  /// Potřebné kvůli backward compatibility s TagService
  old_model.TagDefinition _convertToOldModel(TagDefinition definition) {
    // Vytvoříme instanci starého TagDefinition z lib/models/tag_definition.dart
    return old_model.TagDefinition(
      id: definition.id,
      tagName: definition.tagName,
      tagType: _convertTagTypeReverse(definition.tagType),
      displayName: definition.displayName,
      emoji: definition.emoji,
      color: definition.color,
      glowEnabled: definition.glowEnabled,
      glowStrength: definition.glowStrength,
      sortOrder: definition.sortOrder,
      enabled: definition.enabled,
    );
  }
}

/// Helper: Převést starý TagType na nový TagType
TagType _convertTagType(old_model.TagType oldType) {
  switch (oldType) {
    case old_model.TagType.priority:
      return TagType.priority;
    case old_model.TagType.date:
      return TagType.date;
    case old_model.TagType.status:
      return TagType.status;
    case old_model.TagType.custom:
      return TagType.custom;
  }
}

/// Helper: Převést nový TagType na starý TagType
old_model.TagType _convertTagTypeReverse(TagType newType) {
  switch (newType) {
    case TagType.priority:
      return old_model.TagType.priority;
    case TagType.date:
      return old_model.TagType.date;
    case TagType.status:
      return old_model.TagType.status;
    case TagType.custom:
      return old_model.TagType.custom;
  }
}
