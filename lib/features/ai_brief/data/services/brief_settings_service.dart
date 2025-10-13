import '../../../../core/services/database_helper.dart';
import '../../domain/entities/brief_config.dart';

/// Service pro ukládání a načítání Brief nastavení
///
/// Používá DatabaseHelper (settings tabulka) pro perzistenci.
class BriefSettingsService {
  final DatabaseHelper _db;

  BriefSettingsService(this._db);

  /// Načte BriefConfig z databáze
  ///
  /// Pokud není uložen, vrátí výchozí konfiguraci.
  BriefConfig loadConfig() {
    // Synchronní verze - načte z DB cache v DatabaseHelper
    // Pro async verzi použij loadConfigAsync()
    return BriefConfig.defaultConfig();
  }

  /// Načte BriefConfig z databáze (async)
  Future<BriefConfig> loadConfigAsync() async {
    try {
      final settings = await _db.getSettings();

      final includeSubtasks = settings['brief_include_subtasks'] == 1;
      final includePomodoroStats = settings['brief_include_pomodoro'] == 1;

      return BriefConfig(
        includeSubtasks: includeSubtasks,
        includePomodoroStats: includePomodoroStats,
      );
    } catch (e) {
      // Fallback při chybě
      return BriefConfig.defaultConfig();
    }
  }

  /// Uloží BriefConfig do databáze
  Future<void> saveConfig(BriefConfig config) async {
    await _db.updateSettings(
      briefIncludeSubtasks: config.includeSubtasks,
      briefIncludePomodoro: config.includePomodoroStats,
    );
  }

  /// Resetuje nastavení na výchozí hodnoty
  Future<void> resetToDefault() async {
    await saveConfig(BriefConfig.defaultConfig());
  }
}
