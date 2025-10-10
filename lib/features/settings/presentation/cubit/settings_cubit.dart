import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/theme/doom_one_theme.dart';
import '../../../../core/theme/blade_runner_theme.dart';
import '../../../../core/theme/osaka_jade_theme.dart';
import '../../../../core/theme/amoled_theme.dart';
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

  /// Načíst nastavení z databáze
  Future<void> loadSettings() async {
    emit(const SettingsLoading());

    try {
      final settings = await _db.getSettings();
      final themeId = settings['selected_theme'] as String? ?? 'doom_one';
      final hasSeenGestureHint = (settings['has_seen_gesture_hint'] as int? ?? 0) == 1;

      // ✅ Fail Fast: validace themeId
      if (!_isValidThemeId(themeId)) {
        emit(const SettingsError('Neplatné ID tématu v databázi'));
        return;
      }

      final theme = _getThemeDataById(themeId);

      emit(SettingsLoaded(
        selectedThemeId: themeId,
        currentTheme: theme,
        hasSeenGestureHint: hasSeenGestureHint,
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
}
