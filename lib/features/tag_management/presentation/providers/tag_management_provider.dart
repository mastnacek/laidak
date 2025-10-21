import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/repositories/tag_management_repository.dart';
import '../cubit/tag_management_state.dart';

part 'tag_management_provider.g.dart';

/// Provider pro TagManagementRepository
@riverpod
TagManagementRepository tagManagementRepository(TagManagementRepositoryRef ref) {
  throw UnimplementedError('TagManagementRepository musí být implementován');
}

/// Riverpod Notifier pro správu tagů
///
/// Nahrazuje původní TagManagementCubit
/// Zodpovědný za:
/// - Načítání a zobrazení tagů
/// - CRUD operace (přidání, editace, smazání, toggle)
/// - Správu delimiter nastavení
@riverpod
class TagManagement extends _$TagManagement {
  @override
  Future<TagManagementState> build() async {
    // Načíst initial data
    try {
      final repository = ref.read(tagManagementRepositoryProvider);
      final db = ref.read(databaseHelperProvider);

      final tags = await repository.getAllDefinitions();
      final settings = await db.getSettings();

      return TagManagementLoaded(
        tags: tags,
        tagDelimiterStart: settings['tag_delimiter_start'] as String? ?? '*',
        tagDelimiterEnd: settings['tag_delimiter_end'] as String? ?? '*',
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání tagů: $e');
      return TagManagementError(e.toString());
    }
  }

  /// Načíst všechny tagy a delimiter nastavení
  Future<void> loadTags() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tagManagementRepositoryProvider);
      final db = ref.read(databaseHelperProvider);

      final tags = await repository.getAllDefinitions();
      final settings = await db.getSettings();

      state = AsyncValue.data(TagManagementLoaded(
        tags: tags,
        tagDelimiterStart: settings['tag_delimiter_start'] as String? ?? '*',
        tagDelimiterEnd: settings['tag_delimiter_end'] as String? ?? '*',
      ));

      AppLogger.debug('✅ Tagy načteny: ${tags.length} items');
    } catch (e) {
      AppLogger.error('Chyba při načítání tagů: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
    }
  }

  /// Přidat nový tag
  Future<void> addTag(TagDefinition tag) async {
    try {
      final repository = ref.read(tagManagementRepositoryProvider);

      await repository.addDefinition(tag);

      // Znovu načíst tagy a emitovat success state
      final tags = await repository.getAllDefinitions();
      final currentState = state.value;

      if (currentState is TagManagementLoaded) {
        // Dočasně zobraz success message
        state = AsyncValue.data(TagManagementOperationSuccess(
          message: '✅ Tag byl úspěšně přidán',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emituj loaded state
        await Future.delayed(const Duration(milliseconds: 100));
        state = AsyncValue.data(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        AppLogger.info('✅ Tag přidán: ${tag.tag}');
      }
    } catch (e) {
      AppLogger.error('Chyba při přidávání tagu: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
      await loadTags(); // Reload po chybě
    }
  }

  /// Aktualizovat existující tag
  Future<void> updateTag(TagDefinition tag) async {
    try {
      final repository = ref.read(tagManagementRepositoryProvider);

      await repository.updateDefinition(tag);

      // Znovu načíst tagy a emitovat success state
      final tags = await repository.getAllDefinitions();
      final currentState = state.value;

      if (currentState is TagManagementLoaded) {
        // Dočasně zobraz success message
        state = AsyncValue.data(TagManagementOperationSuccess(
          message: '✅ Tag byl úspěšně uložen',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emituj loaded state
        await Future.delayed(const Duration(milliseconds: 100));
        state = AsyncValue.data(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        AppLogger.info('✅ Tag aktualizován: ${tag.id}');
      }
    } catch (e) {
      AppLogger.error('Chyba při aktualizaci tagu: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
      await loadTags(); // Reload po chybě
    }
  }

  /// Smazat tag
  Future<void> deleteTag(int id) async {
    try {
      final repository = ref.read(tagManagementRepositoryProvider);

      await repository.deleteDefinition(id);

      // Znovu načíst tagy a emitovat success state
      final tags = await repository.getAllDefinitions();
      final currentState = state.value;

      if (currentState is TagManagementLoaded) {
        // Dočasně zobraz success message
        state = AsyncValue.data(TagManagementOperationSuccess(
          message: '🗑️ Tag byl smazán',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emituj loaded state
        await Future.delayed(const Duration(milliseconds: 100));
        state = AsyncValue.data(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        AppLogger.info('✅ Tag smazán: $id');
      }
    } catch (e) {
      AppLogger.error('Chyba při mazání tagu: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
      await loadTags(); // Reload po chybě
    }
  }

  /// Zapnout/vypnout tag
  Future<void> toggleTag(int id, bool enabled) async {
    try {
      final repository = ref.read(tagManagementRepositoryProvider);

      await repository.toggleDefinition(id, enabled);

      // Znovu načíst tagy bez success message (toggle je tichá operace)
      final tags = await repository.getAllDefinitions();
      final currentState = state.value;

      if (currentState is TagManagementLoaded) {
        state = AsyncValue.data(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        AppLogger.debug('✅ Tag toggled: $id → $enabled');
      }
    } catch (e) {
      AppLogger.error('Chyba při přepínání tagu: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
      await loadTags(); // Reload po chybě
    }
  }

  /// Uložit delimiter nastavení
  Future<void> saveDelimiters(String start, String end) async {
    try {
      final db = ref.read(databaseHelperProvider);

      await db.updateSettings(
        tagDelimiterStart: start,
        tagDelimiterEnd: end,
      );

      final currentState = state.value;
      if (currentState is TagManagementLoaded) {
        // Dočasně zobraz success message
        state = AsyncValue.data(TagManagementOperationSuccess(
          message: '✅ Oddělovače byly uloženy',
          tags: currentState.tags,
          tagDelimiterStart: start,
          tagDelimiterEnd: end,
        ));

        // Hned poté emituj loaded state
        await Future.delayed(const Duration(milliseconds: 100));
        state = AsyncValue.data(TagManagementLoaded(
          tags: currentState.tags,
          tagDelimiterStart: start,
          tagDelimiterEnd: end,
        ));

        AppLogger.info('✅ Delimiters uloženy: $start...$end');
      }
    } catch (e) {
      AppLogger.error('Chyba při ukládání oddělovačů: $e');
      state = AsyncValue.data(TagManagementError(e.toString()));
      await loadTags(); // Reload po chybě
    }
  }

  /// Dočasně aktualizovat delimiters v UI (bez uložení do DB)
  void updateDelimitersTemporarily(String start, String end) {
    final currentState = state.value;
    if (currentState is TagManagementLoaded) {
      state = AsyncValue.data(currentState.copyWith(
        tagDelimiterStart: start,
        tagDelimiterEnd: end,
      ));

      AppLogger.debug('🔄 Delimiters temporarily updated: $start...$end');
    }
  }
}

/// Helper provider: získat všechny tagy
@riverpod
List<TagDefinition> allTags(AllTagsRef ref) {
  final tagManagementAsync = ref.watch(tagManagementProvider);

  return tagManagementAsync.maybeWhen(
    data: (state) {
      if (state is TagManagementLoaded) {
        return state.tags;
      }
      return [];
    },
    orElse: () => [],
  );
}

/// Helper provider: získat delimiters
@riverpod
({String start, String end}) tagDelimiters(TagDelimitersRef ref) {
  final tagManagementAsync = ref.watch(tagManagementProvider);

  return tagManagementAsync.maybeWhen(
    data: (state) {
      if (state is TagManagementLoaded) {
        return (start: state.tagDelimiterStart, end: state.tagDelimiterEnd);
      }
      return (start: '*', end: '*');
    },
    orElse: () => (start: '*', end: '*'),
  );
}
