import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      emit(SettingsLoaded(
        selectedThemeId: themeId,
        currentTheme: theme,
        hasSeenGestureHint: hasSeenGestureHint,
        agendaConfig: agendaConfig,
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

    final updated = currentState.agendaConfig.copyWith(
      customViews: [...currentState.agendaConfig.customViews, view],
    );

    await _saveAgendaConfig(updated);
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

    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .map((v) => v.id == view.id ? view : v)
          .toList(),
    );

    await _saveAgendaConfig(updated);
    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view aktualizován: ${view.name}');
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

    final updated = currentState.agendaConfig.copyWith(
      customViews: currentState.agendaConfig.customViews
          .where((v) => v.id != id)
          .toList(),
    );

    await _saveAgendaConfig(updated);
    emit(currentState.copyWith(agendaConfig: updated));

    AppLogger.info('✅ Custom view smazán: $id');
  }

  // ========== PRIVATE HELPERS ==========

  /// Načíst AgendaViewConfig ze SharedPreferences
  Future<AgendaViewConfig> _loadAgendaConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('agenda_config');

      if (jsonString == null) {
        return AgendaViewConfig.defaultConfig();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AgendaViewConfig.fromJson(json);
    } catch (e) {
      AppLogger.error('Chyba při načítání agenda config: $e');
      return AgendaViewConfig.defaultConfig();
    }
  }

  /// Uložit AgendaViewConfig do SharedPreferences
  Future<void> _saveAgendaConfig(AgendaViewConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());
      await prefs.setString('agenda_config', jsonString);
    } catch (e) {
      AppLogger.error('Chyba při ukládání agenda config: $e');
      rethrow;
    }
  }
}
