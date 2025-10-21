import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/settings_export_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/theme_registry.dart';
import '../../../../core/theme/doom_one_theme.dart';
import '../../../../core/models/provider_route.dart';
import '../../domain/models/agenda_view_config.dart';
import '../../domain/models/custom_agenda_view.dart';
import '../../../notes/domain/models/notes_view_config.dart';
import '../../../notes/domain/models/custom_notes_view.dart';
import '../../../markdown_export/domain/entities/export_config.dart';
import '../../../markdown_export/domain/entities/export_format.dart';
import '../cubit/settings_state.dart';

part 'settings_provider.g.dart';

/// Riverpod Notifier pro správu nastavení aplikace
///
/// Nahrazuje původní SettingsCubit
/// Zodpovědnosti:
/// - Načítání nastavení z databáze
/// - Změna tématu aplikace
/// - Ukládání nastavení do databáze
@riverpod
class Settings extends _$Settings {
  DatabaseHelper get _db => ref.read(databaseHelperProvider);

  @override
  Future<SettingsLoaded> build() async {
    // Automaticky načíst nastavení při vytvoření
    return await _loadSettings();
  }

  /// Načíst nastavení z databáze + SharedPreferences
  Future<SettingsLoaded> _loadSettings() async {
    try {
      // Načíst theme + onboarding + tag delimiters z databáze
      final settings = await _db.getSettings();
      final themeId = settings['selected_theme'] as String? ?? 'doom_one';
      final hasSeenGestureHint = (settings['has_seen_gesture_hint'] as int? ?? 0) == 1;
      final tagDelimiterStart = settings['tag_delimiter_start'] as String? ?? '*';
      final tagDelimiterEnd = settings['tag_delimiter_end'] as String? ?? '*';

      // Validace themeId
      if (!_isValidThemeId(themeId)) {
        throw Exception('Neplatné ID tématu v databázi');
      }

      final theme = _getThemeDataById(themeId);

      // Načíst agenda config z databáze
      final agendaConfig = await _loadAgendaConfig();

      // Načíst notes config z databáze
      final notesConfig = await _loadNotesConfig();

      // Načíst AI settings z databáze
      final openRouterApiKey = settings['openrouter_api_key'] as String?;
      final aiMotivationModel = settings['ai_motivation_model'] as String? ?? 'mistralai/mistral-medium';
      final aiMotivationTemperature = (settings['ai_motivation_temperature'] as num?)?.toDouble() ?? 0.9;
      final aiMotivationMaxTokens = settings['ai_motivation_max_tokens'] as int? ?? 200;
      final aiTaskModel = settings['ai_task_model'] as String? ?? 'anthropic/claude-3.5-sonnet';
      final aiTaskTemperature = (settings['ai_task_temperature'] as num?)?.toDouble() ?? 0.3;
      final aiTaskMaxTokens = settings['ai_task_max_tokens'] as int? ?? 1000;

      // Načíst OpenRouter Provider Route & Cache settings z databáze (V36)
      final aiMotivationProviderRoute = ProviderRoute.fromString(
        settings['ai_motivation_provider_route'] as String? ?? 'default',
      );
      final aiMotivationEnableCache = (settings['ai_motivation_enable_cache'] as int? ?? 1) == 1;

      final aiTaskProviderRoute = ProviderRoute.fromString(
        settings['ai_task_provider_route'] as String? ?? 'floor',
      );
      final aiTaskEnableCache = (settings['ai_task_enable_cache'] as int? ?? 1) == 1;

      final aiRewardProviderRoute = ProviderRoute.fromString(
        settings['ai_reward_provider_route'] as String? ?? 'default',
      );
      final aiRewardEnableCache = (settings['ai_reward_enable_cache'] as int? ?? 1) == 1;

      final aiTagSuggestionsProviderRoute = ProviderRoute.fromString(
        settings['ai_tag_suggestions_provider_route'] as String? ?? 'floor',
      );
      final aiTagSuggestionsEnableCache = (settings['ai_tag_suggestions_enable_cache'] as int? ?? 1) == 1;

      // Načíst export config ze SharedPreferences
      final exportConfig = await _loadExportConfig();

      return SettingsLoaded(
        selectedThemeId: themeId,
        currentTheme: theme,
        hasSeenGestureHint: hasSeenGestureHint,
        agendaConfig: agendaConfig,
        notesConfig: notesConfig,
        tagDelimiterStart: tagDelimiterStart,
        tagDelimiterEnd: tagDelimiterEnd,
        openRouterApiKey: openRouterApiKey,
        aiMotivationModel: aiMotivationModel,
        aiMotivationTemperature: aiMotivationTemperature,
        aiMotivationMaxTokens: aiMotivationMaxTokens,
        aiTaskModel: aiTaskModel,
        aiTaskTemperature: aiTaskTemperature,
        aiTaskMaxTokens: aiTaskMaxTokens,
        aiMotivationProviderRoute: aiMotivationProviderRoute,
        aiMotivationEnableCache: aiMotivationEnableCache,
        aiTaskProviderRoute: aiTaskProviderRoute,
        aiTaskEnableCache: aiTaskEnableCache,
        aiRewardProviderRoute: aiRewardProviderRoute,
        aiRewardEnableCache: aiRewardEnableCache,
        aiTagSuggestionsProviderRoute: aiTagSuggestionsProviderRoute,
        aiTagSuggestionsEnableCache: aiTagSuggestionsEnableCache,
        exportConfig: exportConfig,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání nastavení: $e');
      rethrow;
    }
  }

  /// Reload settings (public method)
  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadSettings());
  }

  /// Změnit téma aplikace
  Future<void> changeTheme(String themeId) async {
    // Validace před zpracováním
    if (themeId.trim().isEmpty) {
      throw Exception('ID tématu nesmí být prázdné');
    }

    if (!_isValidThemeId(themeId)) {
      throw Exception('Neplatné ID tématu: $themeId');
    }

    // Získat current state
    final currentState = state.value;
    if (currentState == null) {
      throw Exception('Nelze změnit téma - nastavení nejsou načtena');
    }

    try {
      // Uložit do databáze
      await _db.updateSettings(selectedTheme: themeId);

      // Aktualizovat state pomocí copyWith
      final theme = _getThemeDataById(themeId);

      state = AsyncValue.data(currentState.copyWith(
        selectedThemeId: themeId,
        currentTheme: theme,
      ));

      AppLogger.info('✅ Téma změněno na: $themeId');
    } catch (e) {
      AppLogger.error('Chyba při změně tématu: $e');
      rethrow;
    }
  }

  /// Označit gesture hint jako viděný (pro onboarding)
  Future<void> markGestureHintSeen() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do databáze
      await _db.updateSettings(hasSeenGestureHint: true);

      // Aktualizovat state
      state = AsyncValue.data(currentState.copyWith(hasSeenGestureHint: true));

      AppLogger.info('✅ Gesture hint označen jako viděný');
    } catch (e) {
      AppLogger.error('Chyba při ukládání gesture hint: $e');
    }
  }

  /// Validace theme ID pomocí ThemeRegistry
  bool _isValidThemeId(String themeId) {
    return ThemeRegistry.isValidThemeId(themeId);
  }

  /// Získat ThemeData podle ID tématu z ThemeRegistry
  ThemeData _getThemeDataById(String themeId) {
    try {
      return ThemeRegistry.getTheme(themeId);
    } catch (e) {
      // Fallback na default téma při chybě
      AppLogger.error('Theme "$themeId" nenalezen, použit fallback: $e');
      return ThemeRegistry.defaultTheme;
    }
  }

  // ========== AGENDA VIEW CONFIG MANAGEMENT ==========

  /// Zapnout/vypnout built-in view
  Future<void> toggleBuiltInView(String viewName, bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace viewName
    const validViews = ['all', 'today', 'week', 'upcoming', 'overdue'];
    if (!validViews.contains(viewName)) {
      AppLogger.error('❌ Neplatný název view: $viewName');
      return;
    }

    final updated = switch (viewName) {
      'all' => currentState.agendaConfig.copyWith(showAll: enabled),
      'today' => currentState.agendaConfig.copyWith(showToday: enabled),
      'week' => currentState.agendaConfig.copyWith(showWeek: enabled),
      'upcoming' => currentState.agendaConfig.copyWith(showUpcoming: enabled),
      'overdue' => currentState.agendaConfig.copyWith(showOverdue: enabled),
      _ => currentState.agendaConfig,
    };

    await _saveAgendaConfig(updated);
    state = AsyncValue.data(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Built-in view "$viewName" nastaven na: $enabled');
  }

  /// Přidat custom view
  Future<void> addCustomView(CustomAgendaView view) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (view.name.trim().isEmpty) {
      AppLogger.error('❌ Název custom view nesmí být prázdný');
      return;
    }
    if (view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Tag filter nesmí být prázdný');
      return;
    }

    // Uložit do DB
    await _db.insertCustomAgendaView({
      'id': view.id,
      'name': view.name,
      'tag_filter': view.tagFilter.toLowerCase(),
      'emoji': view.emoji,
      'color_hex': view.colorHex,
      'sort_order': currentState.agendaConfig.customViews.length,
      'enabled': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: [...currentState.agendaConfig.customViews, view],
    );

    state = AsyncValue.data(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view přidán: ${view.name}');
  }

  /// Aktualizovat custom view
  Future<void> updateCustomView(CustomAgendaView view) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (view.name.trim().isEmpty || view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Název a tag filter nesmí být prázdné');
      return;
    }

    // Uložit do DB
    await _db.updateCustomAgendaView(view.id, {
      'name': view.name,
      'tag_filter': view.tagFilter.toLowerCase(),
      'emoji': view.emoji,
      'color_hex': view.colorHex,
    });

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .map((v) => v.id == view.id ? view : v)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view aktualizován: ${view.name}');
  }

  /// Zapnout/vypnout custom view
  Future<void> toggleCustomView(String id, bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom view nesmí být prázdné');
      return;
    }

    // Update v DB
    await _db.updateCustomAgendaView(id, {
      'enabled': enabled ? 1 : 0,
    });

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .map((v) => v.id == id ? v.copyWith(isEnabled: enabled) : v)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view "$id" nastaven na: $enabled');
  }

  /// Smazat custom view
  Future<void> deleteCustomView(String id) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom view nesmí být prázdné');
      return;
    }

    // Smazat z DB
    await _db.deleteCustomAgendaView(id);

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .where((v) => v.id != id)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view smazán: $id');
  }

  // ========== NOTES VIEW CONFIG MANAGEMENT ==========

  /// Zapnout/vypnout built-in notes view
  Future<void> toggleBuiltInNotesView(String viewName, bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace viewName
    const validViews = ['all_notes', 'recent_notes'];
    if (!validViews.contains(viewName)) {
      AppLogger.error('❌ Neplatný název notes view: $viewName');
      return;
    }

    final updated = switch (viewName) {
      'all_notes' => currentState.notesConfig.copyWith(showAllNotes: enabled),
      'recent_notes' => currentState.notesConfig.copyWith(showRecentNotes: enabled),
      _ => currentState.notesConfig,
    };

    await _saveBuiltInNotesViews(updated);
    state = AsyncValue.data(currentState.copyWith(notesConfig: updated));

    AppLogger.info('✅ Built-in notes view "$viewName" nastaven na: $enabled');
  }

  /// Přidat custom notes view
  Future<void> addCustomNotesView(CustomNotesView view) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (view.name.trim().isEmpty) {
      AppLogger.error('❌ Název custom notes view nesmí být prázdný');
      return;
    }
    if (view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Tag filter nesmí být prázdný');
      return;
    }

    // Uložit do DB
    await _db.insertCustomNotesView({
      'id': view.id,
      'name': view.name,
      'tag_filter': view.tagFilter.toLowerCase(),
      'emoji': view.emoji,
      'sort_order': currentState.notesConfig.customViews.length,
      'enabled': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    // Update state
    final updated = currentState.notesConfig.copyWith(
      customViews: [...currentState.notesConfig.customViews, view],
    );

    state = AsyncValue.data(currentState.copyWith(notesConfig: updated));

    AppLogger.info('✅ Custom notes view přidán: ${view.name}');
  }

  /// Aktualizovat custom notes view
  Future<void> updateCustomNotesView(CustomNotesView view) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (view.name.trim().isEmpty || view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Název a tag filter nesmí být prázdné');
      return;
    }

    // Uložit do DB
    await _db.updateCustomNotesView(view.id, {
      'name': view.name,
      'tag_filter': view.tagFilter.toLowerCase(),
      'emoji': view.emoji,
    });

    // Update state
    final updated = currentState.notesConfig.copyWith(
      customViews: currentState.notesConfig.customViews
          .map((v) => v.id == view.id ? view : v)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(notesConfig: updated));

    AppLogger.info('✅ Custom notes view aktualizován: ${view.name}');
  }

  /// Zapnout/vypnout custom notes view
  Future<void> toggleCustomNotesView(String id, bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom notes view nesmí být prázdné');
      return;
    }

    // Update v DB
    await _db.toggleCustomNotesView(id, enabled);

    // Update state
    final updated = currentState.notesConfig.copyWith(
      customViews: currentState.notesConfig.customViews
          .map((v) => v.id == id ? v.copyWith(isEnabled: enabled) : v)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(notesConfig: updated));

    AppLogger.info('✅ Custom notes view "$id" nastaven na: $enabled');
  }

  /// Smazat custom notes view
  Future<void> deleteCustomNotesView(String id) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom notes view nesmí být prázdné');
      return;
    }

    // Smazat z DB
    await _db.deleteCustomNotesView(id);

    // Update state
    final updated = currentState.notesConfig.copyWith(
      customViews: currentState.notesConfig.customViews
          .where((v) => v.id != id)
          .toList(),
    );

    state = AsyncValue.data(currentState.copyWith(notesConfig: updated));

    AppLogger.info('✅ Custom notes view smazán: $id');
  }

  // ========== PRIVATE HELPERS ==========

  /// Načíst AgendaViewConfig z DATABASE
  Future<AgendaViewConfig> _loadAgendaConfig() async {
    try {
      // Načíst built-in view settings ze settings table
      final settings = await _db.getSettings();

      final showAll = (settings['show_all'] as int? ?? 1) == 1;
      final showToday = (settings['show_today'] as int? ?? 1) == 1;
      final showWeek = (settings['show_week'] as int? ?? 1) == 1;
      final showUpcoming = (settings['show_upcoming'] as int? ?? 0) == 1;
      final showOverdue = (settings['show_overdue'] as int? ?? 1) == 1;

      // Načíst VŠECHNY custom views z custom_agenda_views table
      final customViewsMaps = await _db.getAllCustomAgendaViews();

      final customViews = customViewsMaps.map((map) {
        return CustomAgendaView(
          id: map['id'] as String,
          name: map['name'] as String,
          tagFilter: map['tag_filter'] as String,
          emoji: map['emoji'] as String? ?? '⭐',
          colorHex: map['color_hex'] as String?,
          isEnabled: (map['enabled'] as int? ?? 1) == 1,
        );
      }).toList();

      return AgendaViewConfig(
        showAll: showAll,
        showToday: showToday,
        showWeek: showWeek,
        showUpcoming: showUpcoming,
        showOverdue: showOverdue,
        customViews: customViews,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání agenda config: $e');
      return AgendaViewConfig.defaultConfig();
    }
  }

  /// Uložit built-in views do DATABASE
  Future<void> _saveBuiltInViews(AgendaViewConfig config) async {
    try {
      // Update built-in views v settings table
      await _db.updateBuiltInViewSettings(
        showAll: config.showAll,
        showToday: config.showToday,
        showWeek: config.showWeek,
        showUpcoming: config.showUpcoming,
        showOverdue: config.showOverdue,
      );
    } catch (e) {
      AppLogger.error('Chyba při ukládání built-in views: $e');
      rethrow;
    }
  }

  Future<void> _saveAgendaConfig(AgendaViewConfig config) async {
    await _saveBuiltInViews(config);
    // Custom views se ukládají přes CRUD metody
  }

  /// Načíst NotesViewConfig z DATABASE
  Future<NotesViewConfig> _loadNotesConfig() async {
    try {
      // Načíst built-in view settings ze settings table
      final settings = await _db.getSettings();

      final showAllNotes = (settings['show_all_notes'] as int? ?? 1) == 1;
      final showRecentNotes = (settings['show_recent_notes'] as int? ?? 1) == 1;

      // Načíst VŠECHNY custom notes views z custom_notes_views table
      final customViewsMaps = await _db.getAllCustomNotesViews();

      final customViews = customViewsMaps.map((map) {
        return CustomNotesView(
          id: map['id'] as String,
          name: map['name'] as String,
          tagFilter: map['tag_filter'] as String,
          emoji: map['emoji'] as String? ?? '📁',
          isEnabled: (map['enabled'] as int? ?? 1) == 1,
        );
      }).toList();

      return NotesViewConfig(
        showAllNotes: showAllNotes,
        showRecentNotes: showRecentNotes,
        customViews: customViews,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání notes config: $e');
      return NotesViewConfig.defaultConfig();
    }
  }

  /// Uložit built-in notes views do DATABASE
  Future<void> _saveBuiltInNotesViews(NotesViewConfig config) async {
    try {
      // Update built-in views v settings table
      await _db.updateBuiltInNotesViewSettings(
        showAllNotes: config.showAllNotes,
        showRecentNotes: config.showRecentNotes,
      );
    } catch (e) {
      AppLogger.error('Chyba při ukládání built-in notes views: $e');
      rethrow;
    }
  }

  // ========== AI SETTINGS MANAGEMENT ==========

  /// Uložit OpenRouter API klíč
  Future<void> saveOpenRouterApiKey(String apiKey) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (apiKey.trim().isEmpty) {
      AppLogger.error('❌ API klíč nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(openRouterApiKey: apiKey);

      // Update state
      state = AsyncValue.data(currentState.copyWith(openRouterApiKey: apiKey));

      AppLogger.info('✅ OpenRouter API klíč uložen');
    } catch (e) {
      AppLogger.error('Chyba při ukládání API klíče: $e');
    }
  }

  /// Nastavit model pro motivaci
  Future<void> setMotivationModel(String model) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (model.trim().isEmpty) {
      AppLogger.error('❌ Model nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationModel: model);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiMotivationModel: model));

      AppLogger.info('✅ Motivation model nastaven: $model');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation modelu: $e');
    }
  }

  /// Nastavit teplotu pro motivaci
  Future<void> setMotivationTemperature(double temperature) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (temperature < 0.0 || temperature > 2.0) {
      AppLogger.error('❌ Teplota musí být mezi 0.0 a 2.0');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationTemperature: temperature);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiMotivationTemperature: temperature));

      AppLogger.info('✅ Motivation temperature nastavena: $temperature');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation temperature: $e');
    }
  }

  /// Nastavit max tokens pro motivaci
  Future<void> setMotivationMaxTokens(int maxTokens) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (maxTokens < 1 || maxTokens > 4000) {
      AppLogger.error('❌ Max tokens musí být mezi 1 a 4000');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationMaxTokens: maxTokens);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiMotivationMaxTokens: maxTokens));

      AppLogger.info('✅ Motivation max tokens nastaveny: $maxTokens');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation max tokens: $e');
    }
  }

  /// Nastavit model pro rozdělení úkolů (AI Split)
  Future<void> setTaskModel(String model) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (model.trim().isEmpty) {
      AppLogger.error('❌ Model nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskModel: model);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTaskModel: model));

      AppLogger.info('✅ Task model nastaven: $model');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task modelu: $e');
    }
  }

  /// Nastavit teplotu pro rozdělení úkolů
  Future<void> setTaskTemperature(double temperature) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (temperature < 0.0 || temperature > 2.0) {
      AppLogger.error('❌ Teplota musí být mezi 0.0 a 2.0');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskTemperature: temperature);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTaskTemperature: temperature));

      AppLogger.info('✅ Task temperature nastavena: $temperature');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task temperature: $e');
    }
  }

  /// Nastavit max tokens pro rozdělení úkolů
  Future<void> setTaskMaxTokens(int maxTokens) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Validace
    if (maxTokens < 1 || maxTokens > 4000) {
      AppLogger.error('❌ Max tokens musí být mezi 1 a 4000');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskMaxTokens: maxTokens);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTaskMaxTokens: maxTokens));

      AppLogger.info('✅ Task max tokens nastaveny: $maxTokens');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task max tokens: $e');
    }
  }

  // ========== OPENROUTER PROVIDER ROUTE & CACHE SETTINGS ==========

  /// Nastavit provider route pro motivation model
  Future<void> setMotivationProviderRoute(ProviderRoute route) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationProviderRoute: route);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiMotivationProviderRoute: route));

      AppLogger.info('✅ Motivation provider route nastaven: ${route.value}');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation provider route: $e');
    }
  }

  /// Zapnout/vypnout caching pro motivation model
  Future<void> setMotivationEnableCache(bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationEnableCache: enabled);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiMotivationEnableCache: enabled));

      AppLogger.info('✅ Motivation cache nastaven: $enabled');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation cache: $e');
    }
  }

  /// Nastavit provider route pro task model
  Future<void> setTaskProviderRoute(ProviderRoute route) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskProviderRoute: route);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTaskProviderRoute: route));

      AppLogger.info('✅ Task provider route nastaven: ${route.value}');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task provider route: $e');
    }
  }

  /// Zapnout/vypnout caching pro task model
  Future<void> setTaskEnableCache(bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskEnableCache: enabled);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTaskEnableCache: enabled));

      AppLogger.info('✅ Task cache nastaven: $enabled');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task cache: $e');
    }
  }

  /// Nastavit provider route pro reward model
  Future<void> setRewardProviderRoute(ProviderRoute route) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiRewardProviderRoute: route);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiRewardProviderRoute: route));

      AppLogger.info('✅ Reward provider route nastaven: ${route.value}');
    } catch (e) {
      AppLogger.error('Chyba při ukládání reward provider route: $e');
    }
  }

  /// Zapnout/vypnout caching pro reward model
  Future<void> setRewardEnableCache(bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiRewardEnableCache: enabled);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiRewardEnableCache: enabled));

      AppLogger.info('✅ Reward cache nastaven: $enabled');
    } catch (e) {
      AppLogger.error('Chyba při ukládání reward cache: $e');
    }
  }

  /// Nastavit provider route pro tag suggestions model
  Future<void> setTagSuggestionsProviderRoute(ProviderRoute route) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiTagSuggestionsProviderRoute: route);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTagSuggestionsProviderRoute: route));

      AppLogger.info('✅ Tag suggestions provider route nastaven: ${route.value}');
    } catch (e) {
      AppLogger.error('Chyba při ukládání tag suggestions provider route: $e');
    }
  }

  /// Zapnout/vypnout caching pro tag suggestions model
  Future<void> setTagSuggestionsEnableCache(bool enabled) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do DB
      await _db.updateSettings(aiTagSuggestionsEnableCache: enabled);

      // Update state
      state = AsyncValue.data(currentState.copyWith(aiTagSuggestionsEnableCache: enabled));

      AppLogger.info('✅ Tag suggestions cache nastaven: $enabled');
    } catch (e) {
      AppLogger.error('Chyba při ukládání tag suggestions cache: $e');
    }
  }

  // ========== SETTINGS EXPORT (VŠECHNA NASTAVENÍ) ==========

  /// Exportovat VŠECHNA nastavení aplikace do JSON souboru
  Future<String?> exportAllSettings() async {
    final currentState = state.value;
    if (currentState == null) {
      AppLogger.error('❌ Nelze exportovat - nastavení nejsou načtena');
      return null;
    }

    try {
      AppLogger.info('🔄 Zahajuji export všech nastavení...');

      // Použít SettingsExportService singleton
      final exportService = SettingsExportService();

      // Export (zobrazí SAF picker)
      final filePath = await exportService.exportAllSettings(db: _db);

      if (filePath != null) {
        AppLogger.info('✅ Export dokončen: $filePath');
      } else {
        AppLogger.info('⚠️ Export zrušen uživatelem');
      }

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při exportu nastavení: $e\n$stackTrace');
      return null;
    }
  }

  /// Importovat VŠECHNA nastavení aplikace ze JSON souboru
  Future<bool> importAllSettings() async {
    final currentState = state.value;
    if (currentState == null) {
      AppLogger.error('❌ Nelze importovat - nastavení nejsou načtena');
      return false;
    }

    try {
      AppLogger.info('🔄 Zahajuji import všech nastavení...');

      // Použít SettingsExportService singleton
      final exportService = SettingsExportService();

      // Import (zobrazí file picker + validace + DB update)
      final success = await exportService.importAllSettings(db: _db);

      if (success) {
        AppLogger.info('✅ Import dokončen - reload settings...');

        // Reload settings po importu
        await loadSettings();

        return true;
      } else {
        AppLogger.info('⚠️ Import zrušen uživatelem nebo selhal');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při importu nastavení: $e\n$stackTrace');
      return false;
    }
  }

  // ========== MARKDOWN EXPORT SETTINGS MANAGEMENT ==========

  /// Aktualizovat export konfiguraci
  Future<void> updateExportConfig(ExportConfig config) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      // Uložit do SharedPreferences
      await _saveExportConfig(config);

      // Update state
      state = AsyncValue.data(currentState.copyWith(exportConfig: config));

      AppLogger.info('✅ Export config aktualizován');
    } catch (e) {
      AppLogger.error('Chyba při ukládání export config: $e');
    }
  }

  /// Uložit export config do SharedPreferences
  Future<void> _saveExportConfig(ExportConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'export_target_directory',
        config.targetDirectory ?? '',
      );
      await prefs.setString('export_format', config.format.name);
      await prefs.setBool('export_todos', config.exportTodos);
      await prefs.setBool('export_notes', config.exportNotes);
      await prefs.setBool('export_auto_on_save', config.autoExportOnSave);
    } catch (e) {
      AppLogger.error('Chyba při ukládání export config do SharedPrefs: $e');
      rethrow;
    }
  }

  /// Načíst export config ze SharedPreferences
  Future<ExportConfig> _loadExportConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final targetDir = prefs.getString('export_target_directory');
      final formatStr = prefs.getString('export_format') ?? 'default_';
      final format = ExportFormat.values.firstWhere(
        (e) => e.name == formatStr,
        orElse: () => ExportFormat.default_,
      );

      return ExportConfig(
        targetDirectory: targetDir?.isEmpty ?? true ? null : targetDir,
        format: format,
        exportTodos: prefs.getBool('export_todos') ?? true,
        exportNotes: prefs.getBool('export_notes') ?? true,
        autoExportOnSave: prefs.getBool('export_auto_on_save') ?? false,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání export config: $e');
      return const ExportConfig.initial();
    }
  }
}
