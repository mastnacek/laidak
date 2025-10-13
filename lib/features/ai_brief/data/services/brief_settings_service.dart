import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/brief_config.dart';

/// Service pro ukládání a načítání Brief nastavení
///
/// Používá SharedPreferences pro perzistenci uživatelských preferencí.
class BriefSettingsService {
  static const String _keyBriefConfig = 'brief_config';

  final SharedPreferences _prefs;

  BriefSettingsService(this._prefs);

  /// Načte BriefConfig ze storage
  ///
  /// Pokud není uložen, vrátí výchozí konfiguraci.
  BriefConfig loadConfig() {
    final jsonString = _prefs.getString(_keyBriefConfig);
    if (jsonString == null) {
      return BriefConfig.defaultConfig();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return BriefConfig.fromJson(json);
    } catch (e) {
      // Fallback při chybě parsování
      return BriefConfig.defaultConfig();
    }
  }

  /// Uloží BriefConfig do storage
  Future<void> saveConfig(BriefConfig config) async {
    final jsonString = jsonEncode(config.toJson());
    await _prefs.setString(_keyBriefConfig, jsonString);
  }

  /// Resetuje nastavení na výchozí hodnoty
  Future<void> resetToDefault() async {
    await _prefs.remove(_keyBriefConfig);
  }
}
