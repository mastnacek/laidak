import 'package:flutter/material.dart';
import '../theme/doom_one_theme.dart';
import '../theme/blade_runner_theme.dart';
import '../theme/osaka_jade_theme.dart';
import '../theme/amoled_theme.dart';
import '../services/database_helper.dart';

/// Provider pro správu a dynamickou změnu tématu aplikace
class ThemeProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  String _currentThemeId = 'doom_one';
  ThemeData _currentTheme = DoomOneTheme.darkTheme;

  /// Aktuální ID tématu
  String get currentThemeId => _currentThemeId;

  /// Aktuální ThemeData
  ThemeData get currentTheme => _currentTheme;

  /// Konstruktor - načte téma z databáze
  ThemeProvider() {
    _loadThemeFromDatabase();
  }

  /// Načíst vybrané téma z databáze při startu aplikace
  Future<void> _loadThemeFromDatabase() async {
    try {
      final settings = await _db.getSettings();
      final themeId = settings['selected_theme'] as String? ?? 'doom_one';
      _currentThemeId = themeId;
      _currentTheme = _getThemeDataById(themeId);
      notifyListeners();
    } catch (e) {
      print('❌ Chyba při načítání tématu z databáze: $e');
      // Použít výchozí téma
      _currentThemeId = 'doom_one';
      _currentTheme = DoomOneTheme.darkTheme;
    }
  }

  /// Změnit téma - uložit do databáze a okamžitě aplikovat
  Future<void> changeTheme(String themeId) async {
    try {
      // Uložit do databáze
      await _db.updateSettings(selectedTheme: themeId);

      // Aktualizovat stav
      _currentThemeId = themeId;
      _currentTheme = _getThemeDataById(themeId);

      // Notifikovat listenery -> MaterialApp se znovu vykreslí s novým tématem
      notifyListeners();

      print('✅ Téma změněno na: $themeId');
    } catch (e) {
      print('❌ Chyba při změně tématu: $e');
      throw e;
    }
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
        return DoomOneTheme.darkTheme;
    }
  }
}
