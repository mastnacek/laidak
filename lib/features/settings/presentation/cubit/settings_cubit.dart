import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/doom_one_theme.dart';
import '../../../../core/theme/blade_runner_theme.dart';
import '../../../../core/theme/osaka_jade_theme.dart';
import '../../../../core/theme/amoled_theme.dart';
import '../../domain/models/agenda_view_config.dart';
import '../../domain/models/custom_agenda_view.dart';
import 'settings_state.dart';

/// Cubit pro správu nastavení aplikace (themes, preferences)
///
/// Zodpovědnosti:
/// - Načítání nastavení z databáze
/// - Změna tématu aplikace
/// - Ukládání nastavení do databáze
class SettingsCubit extends Cubit<SettingsState> {
  final DatabaseHelper _db;

  SettingsCubit(this._db) : super(const SettingsInitial()) {
    // Automaticky načíst nastavení při vytvoření
    loadSettings();
  }

  /// Načíst nastavení z databáze + SharedPreferences
  Future<void> loadSettings() async {
    emit(const SettingsLoading());

    try {
      // Načíst theme + onboarding z databáze
      final settings = await _db.getSettings();
      final themeId = settings['selected_theme'] as String? ?? 'doom_one';
      final hasSeenGestureHint = (settings['has_seen_gesture_hint'] as int? ?? 0) == 1;

      // ✅ Fail Fast: validace themeId
      if (!_isValidThemeId(themeId)) {
        emit(const SettingsError('Neplatné ID tématu v databázi'));
        return;
      }

      final theme = _getThemeDataById(themeId);

      // Načíst agenda config ze SharedPreferences
      final agendaConfig = await _loadAgendaConfig();

      // Načíst AI settings z databáze
      final openRouterApiKey = settings['openrouter_api_key'] as String?;
      final aiMotivationModel = settings['ai_motivation_model'] as String? ?? 'mistralai/mistral-medium';
      final aiMotivationTemperature = (settings['ai_motivation_temperature'] as num?)?.toDouble() ?? 0.9;
      final aiMotivationMaxTokens = settings['ai_motivation_max_tokens'] as int? ?? 200;
      final aiTaskModel = settings['ai_task_model'] as String? ?? 'anthropic/claude-3.5-sonnet';
      final aiTaskTemperature = (settings['ai_task_temperature'] as num?)?.toDouble() ?? 0.3;
      final aiTaskMaxTokens = settings['ai_task_max_tokens'] as int? ?? 1000;

      emit(SettingsLoaded(
        selectedThemeId: themeId,
        currentTheme: theme,
        hasSeenGestureHint: hasSeenGestureHint,
        agendaConfig: agendaConfig,
        openRouterApiKey: openRouterApiKey,
        aiMotivationModel: aiMotivationModel,
        aiMotivationTemperature: aiMotivationTemperature,
        aiMotivationMaxTokens: aiMotivationMaxTokens,
        aiTaskModel: aiTaskModel,
        aiTaskTemperature: aiTaskTemperature,
        aiTaskMaxTokens: aiTaskMaxTokens,
      ));
    } catch (e) {
      emit(SettingsError('Chyba při načítání nastavení: $e'));
    }
  }

  /// Změnit téma aplikace
  Future<void> changeTheme(String themeId) async {
    // ✅ Fail Fast: validace před zpracováním
    if (themeId.trim().isEmpty) {
      emit(const SettingsError('ID tématu nesmí být prázdné'));
      return;
    }

    if (!_isValidThemeId(themeId)) {
      emit(SettingsError('Neplatné ID tématu: $themeId'));
      return;
    }

    try {
      // Uložit do databáze
      await _db.updateSettings(selectedTheme: themeId);

      // Aktualizovat state
      final theme = _getThemeDataById(themeId);

      emit(SettingsLoaded(
        selectedThemeId: themeId,
        currentTheme: theme,
      ));

      AppLogger.info('✅ Téma změněno na: $themeId');
    } catch (e) {
      emit(SettingsError('Chyba při změně tématu: $e'));
    }
  }

  /// Označit gesture hint jako viděný (pro onboarding)
  Future<void> markGestureHintSeen() async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      // Uložit do databáze
      await _db.updateSettings(hasSeenGestureHint: true);

      // Aktualizovat state
      emit(currentState.copyWith(hasSeenGestureHint: true));

      AppLogger.info('✅ Gesture hint označen jako viděný');
    } catch (e) {
      AppLogger.error('Chyba při ukládání gesture hint: $e');
    }
  }

  /// Validace theme ID
  bool _isValidThemeId(String themeId) {
    const validIds = ['doom_one', 'blade_runner', 'osaka_jade', 'amoled'];
    return validIds.contains(themeId);
  }

  /// Získat ThemeData podle ID tématu
  ThemeData _getThemeDataById(String themeId) {
    switch (themeId) {
      case 'doom_one':
        return DoomOneTheme.darkTheme;
      case 'blade_runner':
        return BladeRunnerTheme.darkTheme;
      case 'osaka_jade':
        return OsakaJadeTheme.darkTheme;
      case 'amoled':
        return AmoledTheme.darkTheme;
      default:
        // Fallback na default téma
        return DoomOneTheme.darkTheme;
    }
  }

  // ========== AGENDA VIEW CONFIG MANAGEMENT ==========

  /// Zapnout/vypnout built-in view
  Future<void> toggleBuiltInView(String viewName, bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace viewName
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
    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Built-in view "$viewName" nastaven na: $enabled');
  }

  /// Přidat custom view
  Future<void> addCustomView(CustomAgendaView view) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (view.name.trim().isEmpty) {
      AppLogger.error('❌ Název custom view nesmí být prázdný');
      return;
    }
    if (view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Tag filter nesmí být prázdný');
      return;
    }

    // ✅ Uložit do DB
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

    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view přidán: ${view.name}');
  }

  /// Aktualizovat custom view
  Future<void> updateCustomView(CustomAgendaView view) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (view.name.trim().isEmpty || view.tagFilter.trim().isEmpty) {
      AppLogger.error('❌ Název a tag filter nesmí být prázdné');
      return;
    }

    // ✅ Uložit do DB
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

    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view aktualizován: ${view.name}');
  }

  /// Zapnout/vypnout custom view
  Future<void> toggleCustomView(String id, bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom view nesmí být prázdné');
      return;
    }

    // ✅ Update v DB
    await _db.updateCustomAgendaView(id, {
      'enabled': enabled ? 1 : 0,
    });

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .map((v) => v.id == id ? v.copyWith(isEnabled: enabled) : v)
          .toList(),
    );

    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view "$id" nastaven na: $enabled');
  }

  /// Smazat custom view
  Future<void> deleteCustomView(String id) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (id.trim().isEmpty) {
      AppLogger.error('❌ ID custom view nesmí být prázdné');
      return;
    }

    // ✅ Smazat z DB
    await _db.deleteCustomAgendaView(id);

    // Update state
    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .where((v) => v.id != id)
          .toList(),
    );

    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view smazán: $id');
  }

  // ========== PRIVATE HELPERS ==========

  /// Načíst AgendaViewConfig z DATABASE (ne SharedPrefs!)
  Future<AgendaViewConfig> _loadAgendaConfig() async {
    try {
      // Načíst built-in view settings ze settings table
      final settings = await _db.getSettings();

      final showAll = (settings['show_all'] as int? ?? 1) == 1;
      final showToday = (settings['show_today'] as int? ?? 1) == 1;
      final showWeek = (settings['show_week'] as int? ?? 1) == 1;
      final showUpcoming = (settings['show_upcoming'] as int? ?? 0) == 1;
      final showOverdue = (settings['show_overdue'] as int? ?? 1) == 1;

      // Načíst VŠECHNY custom views z custom_agenda_views table (včetně disabled)
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

  /// Uložit built-in views do DATABASE (ne SharedPrefs!)
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

  /// DEPRECATED: _saveAgendaConfig už není potřeba (používáme DB CRUD metody)
  /// Built-in views: _saveBuiltInViews()
  /// Custom views: insertCustomAgendaView(), updateCustomAgendaView(), deleteCustomAgendaView()
  @Deprecated('Use _saveBuiltInViews() + DB CRUD metody místo toho')
  Future<void> _saveAgendaConfig(AgendaViewConfig config) async {
    await _saveBuiltInViews(config);
    // Custom views se ukládají přes CRUD metody
  }

  // ========== AI SETTINGS MANAGEMENT ==========

  /// Uložit OpenRouter API klíč
  Future<void> saveOpenRouterApiKey(String apiKey) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (apiKey.trim().isEmpty) {
      AppLogger.error('❌ API klíč nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(openRouterApiKey: apiKey);

      // Update state
      emit(currentState.copyWith(openRouterApiKey: apiKey));

      AppLogger.info('✅ OpenRouter API klíč uložen');
    } catch (e) {
      AppLogger.error('Chyba při ukládání API klíče: $e');
    }
  }

  /// Nastavit model pro motivaci
  Future<void> setMotivationModel(String model) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (model.trim().isEmpty) {
      AppLogger.error('❌ Model nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationModel: model);

      // Update state
      emit(currentState.copyWith(aiMotivationModel: model));

      AppLogger.info('✅ Motivation model nastaven: $model');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation modelu: $e');
    }
  }

  /// Nastavit teplotu pro motivaci
  Future<void> setMotivationTemperature(double temperature) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (temperature < 0.0 || temperature > 2.0) {
      AppLogger.error('❌ Teplota musí být mezi 0.0 a 2.0');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationTemperature: temperature);

      // Update state
      emit(currentState.copyWith(aiMotivationTemperature: temperature));

      AppLogger.info('✅ Motivation temperature nastavena: $temperature');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation temperature: $e');
    }
  }

  /// Nastavit max tokens pro motivaci
  Future<void> setMotivationMaxTokens(int maxTokens) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (maxTokens < 1 || maxTokens > 4000) {
      AppLogger.error('❌ Max tokens musí být mezi 1 a 4000');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiMotivationMaxTokens: maxTokens);

      // Update state
      emit(currentState.copyWith(aiMotivationMaxTokens: maxTokens));

      AppLogger.info('✅ Motivation max tokens nastaveny: $maxTokens');
    } catch (e) {
      AppLogger.error('Chyba při ukládání motivation max tokens: $e');
    }
  }

  /// Nastavit model pro rozdělení úkolů (AI Split)
  Future<void> setTaskModel(String model) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (model.trim().isEmpty) {
      AppLogger.error('❌ Model nesmí být prázdný');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskModel: model);

      // Update state
      emit(currentState.copyWith(aiTaskModel: model));

      AppLogger.info('✅ Task model nastaven: $model');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task modelu: $e');
    }
  }

  /// Nastavit teplotu pro rozdělení úkolů
  Future<void> setTaskTemperature(double temperature) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (temperature < 0.0 || temperature > 2.0) {
      AppLogger.error('❌ Teplota musí být mezi 0.0 a 2.0');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskTemperature: temperature);

      // Update state
      emit(currentState.copyWith(aiTaskTemperature: temperature));

      AppLogger.info('✅ Task temperature nastavena: $temperature');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task temperature: $e');
    }
  }

  /// Nastavit max tokens pro rozdělení úkolů
  Future<void> setTaskMaxTokens(int maxTokens) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // ✅ Fail Fast: validace
    if (maxTokens < 1 || maxTokens > 4000) {
      AppLogger.error('❌ Max tokens musí být mezi 1 a 4000');
      return;
    }

    try {
      // Uložit do DB
      await _db.updateSettings(aiTaskMaxTokens: maxTokens);

      // Update state
      emit(currentState.copyWith(aiTaskMaxTokens: maxTokens));

      AppLogger.info('✅ Task max tokens nastaveny: $maxTokens');
    } catch (e) {
      AppLogger.error('Chyba při ukládání task max tokens: $e');
    }
  }
}
