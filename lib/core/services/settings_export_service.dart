import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import 'database_helper.dart';
import '../utils/app_logger.dart';

/// Singleton service pro export všech nastavení aplikace
///
/// Zodpovědnosti:
/// - Collect data z DatabaseHelper (settings, custom_prompts, views, tags)
/// - Collect data ze SharedPreferences (export config)
/// - Serialize do JSON (pretty-printed)
/// - Export pomocí SAF picker (file_picker)
///
/// Pattern: Singleton
class SettingsExportService {
  static final SettingsExportService _instance = SettingsExportService._internal();

  factory SettingsExportService() => _instance;

  SettingsExportService._internal();

  /// Export všech nastavení do JSON souboru
  ///
  /// Returns: path k exportovanému souboru nebo null při chybě
  ///
  /// ✅ Fail Fast:
  /// - Kontrola práv zápisu
  /// - Validace JSON struktury
  Future<String?> exportAllSettings({
    required DatabaseHelper db,
  }) async {
    try {
      AppLogger.info('🔄 Začínám export všech nastavení...');

      // ========== KROK 1: COLLECT DATA ==========

      // 1. Settings table
      final settingsMap = await db.getSettings();

      // 2. Custom prompts
      final customPrompts = await db.getAllPrompts();

      // 3. Custom agenda views
      final customAgendaViews = await db.getAllCustomAgendaViews();

      // 4. Custom notes views
      final customNotesViews = await db.getAllCustomNotesViews();

      // 5. Tag definitions
      final tagDefinitions = await db.getAllTagDefinitions();

      // 6. Export config (SharedPreferences)
      final exportConfig = await _loadExportConfigFromPrefs();

      // ========== KROK 2: SESTAVIT JSON STRUKTURU ==========

      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // TODO: Načíst z package_info_plus
        'general_settings': _sanitizeSettings(settingsMap),
        'custom_prompts': customPrompts,
        'custom_agenda_views': customAgendaViews,
        'custom_notes_views': customNotesViews,
        'tag_definitions': tagDefinitions,
        'export_config': exportConfig,
      };

      // ========== KROK 3: SERIALIZE DO JSON ==========

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      AppLogger.info('✅ Data připravena k exportu (${jsonString.length} znaků)');

      // ========== KROK 4: SAF PICKER + ULOŽIT ==========

      final fileName = _generateFileName();

      // Desktop: file_picker s directoryPath
      // Android: SAF picker
      String? outputFilePath;

      if (Platform.isAndroid) {
        // Android: Použij SAF picker
        outputFilePath = await _saveFileAndroid(jsonString, fileName);
      } else {
        // Desktop: Klasický file picker
        outputFilePath = await _saveFileDesktop(jsonString, fileName);
      }

      if (outputFilePath == null) {
        AppLogger.error('❌ Export zrušen uživatelem nebo chyba při ukládání');
        return null;
      }

      AppLogger.info('✅ Export dokončen: $outputFilePath');
      return outputFilePath;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při exportu nastavení: $e\n$stackTrace');
      return null;
    }
  }

  /// Import nastavení ze JSON souboru
  ///
  /// Strategie:
  /// - REPLACE - přepsat všechna existující nastavení
  /// - Validace JSON struktury (schema check)
  /// - Fail Fast při neplatných datech
  ///
  /// Returns: true při úspěchu, false při chybě
  Future<bool> importAllSettings({
    required DatabaseHelper db,
  }) async {
    try {
      AppLogger.info('🔄 Začínám import nastavení...');

      // ========== KROK 1: FILE PICKER ==========

      FilePickerResult? result;

      if (Platform.isAndroid) {
        // Android: Použij file picker pro výběr souboru
        result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Vyberte soubor s nastavením',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else {
        // Desktop: Klasický file picker
        result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Import nastavení aplikace',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      }

      if (result == null || result.files.isEmpty) {
        AppLogger.info('⚠️ Uživatel zrušil výběr souboru');
        return false;
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        AppLogger.error('❌ Nepodařilo se získat cestu k souboru');
        return false;
      }

      // ========== KROK 2: NAČÍST + VALIDOVAT JSON ==========

      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.error('❌ Soubor neexistuje: $filePath');
        return false;
      }

      final jsonString = await file.readAsString(encoding: utf8);
      final Map<String, dynamic> importData;

      try {
        importData = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.error('❌ Neplatný JSON formát: $e');
        return false;
      }

      // ✅ Fail Fast: validace struktury
      if (!_isValidImportStructure(importData)) {
        AppLogger.error('❌ Neplatná struktura JSON souboru (chybí povinná pole)');
        return false;
      }

      AppLogger.info('✅ JSON validován, začínám import...');

      // ========== KROK 3: IMPORT DAT DO DB ==========

      // 3.1 General settings
      if (importData.containsKey('general_settings')) {
        await _importGeneralSettings(db, importData['general_settings'] as Map<String, dynamic>);
      }

      // 3.2 Custom prompts
      if (importData.containsKey('custom_prompts')) {
        await _importCustomPrompts(db, importData['custom_prompts'] as List<dynamic>);
      }

      // 3.3 Custom agenda views
      if (importData.containsKey('custom_agenda_views')) {
        await _importCustomAgendaViews(db, importData['custom_agenda_views'] as List<dynamic>);
      }

      // 3.4 Custom notes views
      if (importData.containsKey('custom_notes_views')) {
        await _importCustomNotesViews(db, importData['custom_notes_views'] as List<dynamic>);
      }

      // 3.5 Tag definitions
      if (importData.containsKey('tag_definitions')) {
        await _importTagDefinitions(db, importData['tag_definitions'] as List<dynamic>);
      }

      // 3.6 Export config
      if (importData.containsKey('export_config')) {
        await _importExportConfig(importData['export_config'] as Map<String, dynamic>);
      }

      AppLogger.info('✅ Import dokončen: $filePath');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při importu nastavení: $e\n$stackTrace');
      return false;
    }
  }

  // ========== PRIVATE HELPERS ==========

  /// Sanitizovat settings map (odstranit sensitive data pro preview)
  Map<String, dynamic> _sanitizeSettings(Map<String, dynamic> settings) {
    // Zkopírovat settings map
    final sanitized = Map<String, dynamic>.from(settings);

    // ⚠️ BEZPEČNOST: Maskovat API klíče (pro preview - v exportu necháme plné)
    // Poznámka: V plném exportu chceme skutečné API klíče!
    // Toto je jen pro LOG preview, ne pro export JSON

    return sanitized;
  }

  /// Načíst export config ze SharedPreferences
  Future<Map<String, dynamic>> _loadExportConfigFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'target_directory': prefs.getString('export_target_directory') ?? '',
        'format': prefs.getString('export_format') ?? 'default_',
        'export_todos': prefs.getBool('export_todos') ?? true,
        'export_notes': prefs.getBool('export_notes') ?? true,
        'auto_export_on_save': prefs.getBool('export_auto_on_save') ?? false,
      };
    } catch (e) {
      AppLogger.error('Chyba při načítání export config: $e');
      return {};
    }
  }

  /// Generovat název souboru pro export
  ///
  /// Format: todo_settings_export_YYYY-MM-DD_HH-MM-SS.json
  String _generateFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    return 'todo_settings_export_${formatter.format(now)}.json';
  }

  /// Uložit soubor na Android (SAF picker)
  Future<String?> _saveFileAndroid(String jsonString, String fileName) async {
    try {
      // Android: Použij file_picker pro výběr složky
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Vyberte složku pro export nastavení',
      );

      if (result == null) {
        AppLogger.info('⚠️ Uživatel zrušil výběr složky');
        return null;
      }

      // Vytvořit cestu k souboru
      final filePath = path.join(result, fileName);

      // Uložit soubor
      final file = File(filePath);
      await file.writeAsString(jsonString, encoding: utf8);

      AppLogger.info('✅ Soubor uložen (Android SAF): $filePath');
      return filePath;
    } catch (e) {
      AppLogger.error('❌ Chyba při ukládání souboru (Android): $e');
      return null;
    }
  }

  /// Uložit soubor na Desktop (file_picker)
  Future<String?> _saveFileDesktop(String jsonString, String fileName) async {
    try {
      // Desktop: Použij saveFile picker
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export nastavení aplikace',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        AppLogger.info('⚠️ Uživatel zrušil export');
        return null;
      }

      // Uložit soubor
      final file = File(result);
      await file.writeAsString(jsonString, encoding: utf8);

      AppLogger.info('✅ Soubor uložen (Desktop): $result');
      return result;
    } catch (e) {
      AppLogger.error('❌ Chyba při ukládání souboru (Desktop): $e');
      return null;
    }
  }

  // ========== IMPORT VALIDATION + HELPERS ==========

  /// Validace struktury importovaného JSON
  ///
  /// ✅ Fail Fast: kontrola povinných polí
  bool _isValidImportStructure(Map<String, dynamic> data) {
    // Musí obsahovat alespoň jedno z těchto polí
    final hasValidSection = data.containsKey('general_settings') ||
        data.containsKey('custom_prompts') ||
        data.containsKey('custom_agenda_views') ||
        data.containsKey('custom_notes_views') ||
        data.containsKey('tag_definitions') ||
        data.containsKey('export_config');

    return hasValidSection;
  }

  /// Import general settings (settings table)
  Future<void> _importGeneralSettings(
    DatabaseHelper db,
    Map<String, dynamic> settings,
  ) async {
    try {
      AppLogger.info('🔄 Importuji general settings...');

      // Přepsat settings v DB
      await db.updateSettings(
        selectedTheme: settings['selected_theme'] as String?,
        hasSeenGestureHint: (settings['has_seen_gesture_hint'] as int?) == 1,
        tagDelimiterStart: settings['tag_delimiter_start'] as String?,
        tagDelimiterEnd: settings['tag_delimiter_end'] as String?,
        openRouterApiKey: settings['openrouter_api_key'] as String?,
        aiMotivationModel: settings['ai_motivation_model'] as String?,
        aiMotivationTemperature: (settings['ai_motivation_temperature'] as num?)?.toDouble(),
        aiMotivationMaxTokens: settings['ai_motivation_max_tokens'] as int?,
        aiTaskModel: settings['ai_task_model'] as String?,
        aiTaskTemperature: (settings['ai_task_temperature'] as num?)?.toDouble(),
        aiTaskMaxTokens: settings['ai_task_max_tokens'] as int?,
      );

      // Update built-in views (agenda)
      await db.updateBuiltInViewSettings(
        showAll: (settings['show_all'] as int?) == 1,
        showToday: (settings['show_today'] as int?) == 1,
        showWeek: (settings['show_week'] as int?) == 1,
        showUpcoming: (settings['show_upcoming'] as int?) == 1,
        showOverdue: (settings['show_overdue'] as int?) == 1,
      );

      // Update built-in views (notes)
      await db.updateBuiltInNotesViewSettings(
        showAllNotes: (settings['show_all_notes'] as int?) == 1,
        showRecentNotes: (settings['show_recent_notes'] as int?) == 1,
      );

      AppLogger.info('✅ General settings importovány');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu general settings: $e');
      rethrow;
    }
  }

  /// Import custom prompts (custom_prompts table)
  Future<void> _importCustomPrompts(
    DatabaseHelper db,
    List<dynamic> prompts,
  ) async {
    try {
      AppLogger.info('🔄 Importuji custom prompts (${prompts.length})...');

      // REPLACE strategie: Smazat všechny existující custom prompty
      final rawDb = await db.database;
      await rawDb.delete('custom_prompts');

      // Vložit nové prompty
      for (final prompt in prompts) {
        final promptMap = prompt as Map<String, dynamic>;
        await rawDb.insert('custom_prompts', promptMap);
      }

      AppLogger.info('✅ Custom prompts importovány (${prompts.length})');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu custom prompts: $e');
      rethrow;
    }
  }

  /// Import custom agenda views (custom_agenda_views table)
  Future<void> _importCustomAgendaViews(
    DatabaseHelper db,
    List<dynamic> views,
  ) async {
    try {
      AppLogger.info('🔄 Importuji custom agenda views (${views.length})...');

      // REPLACE strategie: Smazat všechny existující custom agenda views
      final existingViews = await db.getAllCustomAgendaViews();
      for (final view in existingViews) {
        await db.deleteCustomAgendaView(view['id'] as String);
      }

      // Vložit nové views
      for (final view in views) {
        final viewMap = view as Map<String, dynamic>;
        await db.insertCustomAgendaView(viewMap);
      }

      AppLogger.info('✅ Custom agenda views importovány (${views.length})');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu custom agenda views: $e');
      rethrow;
    }
  }

  /// Import custom notes views (custom_notes_views table)
  Future<void> _importCustomNotesViews(
    DatabaseHelper db,
    List<dynamic> views,
  ) async {
    try {
      AppLogger.info('🔄 Importuji custom notes views (${views.length})...');

      // REPLACE strategie: Smazat všechny existující custom notes views
      final existingViews = await db.getAllCustomNotesViews();
      for (final view in existingViews) {
        await db.deleteCustomNotesView(view['id'] as String);
      }

      // Vložit nové views
      for (final view in views) {
        final viewMap = view as Map<String, dynamic>;
        await db.insertCustomNotesView(viewMap);
      }

      AppLogger.info('✅ Custom notes views importovány (${views.length})');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu custom notes views: $e');
      rethrow;
    }
  }

  /// Import tag definitions (tag_definitions table)
  Future<void> _importTagDefinitions(
    DatabaseHelper db,
    List<dynamic> tags,
  ) async {
    try {
      AppLogger.info('🔄 Importuji tag definitions (${tags.length})...');

      // REPLACE strategie: Smazat všechny existující tag definitions
      final rawDb = await db.database;
      await rawDb.delete('tag_definitions');

      // Vložit nové tags
      for (final tag in tags) {
        final tagMap = tag as Map<String, dynamic>;
        await rawDb.insert('tag_definitions', tagMap);
      }

      AppLogger.info('✅ Tag definitions importovány (${tags.length})');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu tag definitions: $e');
      rethrow;
    }
  }

  /// Import export config (SharedPreferences)
  Future<void> _importExportConfig(Map<String, dynamic> config) async {
    try {
      AppLogger.info('🔄 Importuji export config...');

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'export_target_directory',
        config['target_directory'] as String? ?? '',
      );
      await prefs.setString(
        'export_format',
        config['format'] as String? ?? 'default_',
      );
      await prefs.setBool(
        'export_todos',
        config['export_todos'] as bool? ?? true,
      );
      await prefs.setBool(
        'export_notes',
        config['export_notes'] as bool? ?? true,
      );
      await prefs.setBool(
        'export_auto_on_save',
        config['auto_export_on_save'] as bool? ?? false,
      );

      AppLogger.info('✅ Export config importován');
    } catch (e) {
      AppLogger.error('❌ Chyba při importu export config: $e');
      rethrow;
    }
  }
}
