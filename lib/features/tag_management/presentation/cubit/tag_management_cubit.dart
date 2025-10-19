import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/database_helper.dart';
import '../../domain/entities/tag_definition.dart';
import '../../domain/repositories/tag_management_repository.dart';
import 'tag_management_state.dart';

/// Cubit pro správu tagů
///
/// Zodpovědný za:
/// - Načítání a zobrazení tagů
/// - CRUD operace (přidání, editace, smazání, toggle)
/// - Správu delimiter nastavení
class TagManagementCubit extends Cubit<TagManagementState> {
  final TagManagementRepository _repository;
  final DatabaseHelper _db;

  TagManagementCubit({
    required TagManagementRepository repository,
    required DatabaseHelper db,
  })  : _repository = repository,
        _db = db,
        super(const TagManagementInitial());

  /// Načíst všechny tagy a delimiter nastavení
  Future<void> loadTags() async {
    try {
      emit(const TagManagementLoading());

      final tags = await _repository.getAllDefinitions();
      final settings = await _db.getSettings();

      emit(TagManagementLoaded(
        tags: tags,
        tagDelimiterStart: settings['tag_delimiter_start'] as String? ?? '*',
        tagDelimiterEnd: settings['tag_delimiter_end'] as String? ?? '*',
      ));
    } catch (e) {
      emit(TagManagementError('Chyba při načítání tagů: $e'));
    }
  }

  /// Přidat nový tag
  Future<void> addTag(TagDefinition tag) async {
    try {
      await _repository.addDefinition(tag);

      // Znovu načíst tagy a emitovat success state
      final tags = await _repository.getAllDefinitions();
      final currentState = state;

      if (currentState is TagManagementLoaded) {
        emit(TagManagementOperationSuccess(
          message: '✅ Tag byl úspěšně přidán',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emitovat loaded state
        emit(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));
      }
    } catch (e) {
      emit(TagManagementError('Chyba při přidávání tagu: $e'));
      await loadTags(); // Reload po chybě
    }
  }

  /// Aktualizovat existující tag
  Future<void> updateTag(TagDefinition tag) async {
    try {
      await _repository.updateDefinition(tag);

      // Znovu načíst tagy a emitovat success state
      final tags = await _repository.getAllDefinitions();
      final currentState = state;

      if (currentState is TagManagementLoaded) {
        emit(TagManagementOperationSuccess(
          message: '✅ Tag byl úspěšně uložen',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emitovat loaded state
        emit(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));
      }
    } catch (e) {
      emit(TagManagementError('Chyba při aktualizaci tagu: $e'));
      await loadTags(); // Reload po chybě
    }
  }

  /// Smazat tag
  Future<void> deleteTag(int id) async {
    try {
      await _repository.deleteDefinition(id);

      // Znovu načíst tagy a emitovat success state
      final tags = await _repository.getAllDefinitions();
      final currentState = state;

      if (currentState is TagManagementLoaded) {
        emit(TagManagementOperationSuccess(
          message: '🗑️ Tag byl smazán',
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));

        // Hned poté emitovat loaded state
        emit(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));
      }
    } catch (e) {
      emit(TagManagementError('Chyba při mazání tagu: $e'));
      await loadTags(); // Reload po chybě
    }
  }

  /// Zapnout/vypnout tag
  Future<void> toggleTag(int id, bool enabled) async {
    try {
      await _repository.toggleDefinition(id, enabled);

      // Znovu načíst tagy bez success message (toggle je tichá operace)
      final tags = await _repository.getAllDefinitions();
      final currentState = state;

      if (currentState is TagManagementLoaded) {
        emit(TagManagementLoaded(
          tags: tags,
          tagDelimiterStart: currentState.tagDelimiterStart,
          tagDelimiterEnd: currentState.tagDelimiterEnd,
        ));
      }
    } catch (e) {
      emit(TagManagementError('Chyba při přepínání tagu: $e'));
      await loadTags(); // Reload po chybě
    }
  }

  /// Uložit delimiter nastavení
  Future<void> saveDelimiters(String start, String end) async {
    try {
      await _db.updateSettings(
        tagDelimiterStart: start,
        tagDelimiterEnd: end,
      );

      final currentState = state;
      if (currentState is TagManagementLoaded) {
        emit(TagManagementOperationSuccess(
          message: '✅ Oddělovače byly uloženy',
          tags: currentState.tags,
          tagDelimiterStart: start,
          tagDelimiterEnd: end,
        ));

        // Hned poté emitovat loaded state
        emit(TagManagementLoaded(
          tags: currentState.tags,
          tagDelimiterStart: start,
          tagDelimiterEnd: end,
        ));
      }
    } catch (e) {
      emit(TagManagementError('Chyba při ukládání oddělovačů: $e'));
      await loadTags(); // Reload po chybě
    }
  }

  /// Dočasně aktualizovat delimiters v UI (bez uložení do DB)
  void updateDelimitersTemporarily(String start, String end) {
    final currentState = state;
    if (currentState is TagManagementLoaded) {
      emit(currentState.copyWith(
        tagDelimiterStart: start,
        tagDelimiterEnd: end,
      ));
    }
  }
}
