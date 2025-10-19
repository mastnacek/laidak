import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/todo_item.dart';
import '../database/database_schema.dart';
import '../database/database_migrations.dart';
import '../database/database_seed_data.dart';
import '../models/provider_route.dart';

/// Singleton služba pro správu SQLite databáze
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  /// FTS5 support flag (Android nativní SQLite nemá FTS5!)
  bool _fts5Available = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Získat databázovou instanci (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializovat databázi
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo.db');

    final db = await openDatabase(
      path,
      version: 36,  // ← Přidány OpenRouter provider route a cache settings (provider_route, enable_cache pro všechny AI modely)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    return db;
  }

  /// Konfigurace databáze (volá se PŘED onCreate/onUpgrade)
  Future<void> _onConfigure(Database db) async {
    // ✅ Enable foreign keys (důležité pro CASCADE delete)
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Vytvořit tabulky při první inicializaci
  Future<void> _onCreate(Database db, int version) async {
    // Vytvořit všechny tabulky pomocí DatabaseSchema
    await DatabaseSchema.createTables(db);

    // FTS5 Full-Text Search virtual tables (verze 22) - pokud dostupné
    try {
      await DatabaseSchema.createFTS5Tables(db);
      await DatabaseSchema.createFTS5Triggers(db);
      _fts5Available = true;
      print('✅ FTS5 Full-Text Search je dostupné');
    } catch (e) {
      _fts5Available = false;
      print('⚠️ FTS5 není dostupné, fallback na Dart-side filtering: $e');
    }

    // Vložit výchozí nastavení pomocí DatabaseSeedData
    await DatabaseSeedData.insertDefaultSettings(db);
    await DatabaseSeedData.insertDefaultPrompts(db);
    await DatabaseSeedData.insertDefaultTagDefinitions(db);
  }

  /// Upgrade databáze na novou verzi
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Provést všechny migrace pomocí DatabaseMigrations
    await DatabaseMigrations.migrate(db, oldVersion, newVersion);

    // Rebuild FTS5 indexů pokud migrace z verze < 22
    if (oldVersion < 22) {
      await rebuildFTS5Indexes();
    }
  }


  /// Přidat nový TODO úkol
  Future<TodoItem> insertTodo(TodoItem todo) async {
    final db = await database;
    final id = await db.insert('todos', todo.toMap());
    return todo.copyWith(id: id);
  }

  /// Získat všechny TODO úkoly
  Future<List<TodoItem>> getAllTodos() async {
    final db = await database;
    final maps = await db.query('todos', orderBy: 'createdAt DESC');
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// Aktualizovat TODO úkol
  Future<int> updateTodo(TodoItem todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// Smazat TODO úkol
  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Označit úkol jako hotový/nehotový
  ///
  /// Když je úkol označen jako hotový (isCompleted = true), nastaví completed_at na aktuální čas.
  /// Když je úkol odznačen zpět jako nehotový (isCompleted = false), vynuluje completed_at na null.
  Future<int> toggleTodoStatus(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'todos',
      {
        'isCompleted': isCompleted ? 1 : 0,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Zavřít databázi
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Získat AI nastavení
  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) {
      // Pokud neexistuje, vrátit výchozí hodnoty
      return {
        'api_key': null, // User must provide their own OpenRouter API key
        'model': 'mistralai/mistral-medium-3.1',
        'temperature': 1.0,
        'max_tokens': 1000,
        'enabled': 1,
        'tag_delimiter_start': '*',
        'tag_delimiter_end': '*',
        'selected_theme': 'doom_one',
        'has_seen_gesture_hint': 0,
      };
    }

    return result.first;
  }

  /// Aktualizovat AI nastavení
  Future<void> updateSettings({
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? enabled,
    String? tagDelimiterStart,
    String? tagDelimiterEnd,
    String? selectedTheme,
    bool? hasSeenGestureHint,
    // AI Settings - OpenRouter API
    String? openRouterApiKey,
    String? aiMotivationModel,
    double? aiMotivationTemperature,
    int? aiMotivationMaxTokens,
    String? aiTaskModel,
    double? aiTaskTemperature,
    int? aiTaskMaxTokens,
    String? aiRewardModel,
    double? aiRewardTemperature,
    int? aiRewardMaxTokens,
    String? aiTagSuggestionsModel,
    double? aiTagSuggestionsTemperature,
    int? aiTagSuggestionsMaxTokens,
    int? aiTagSuggestionsSeed,
    double? aiTagSuggestionsTopP,
    int? aiTagSuggestionsDebounceMs,
    // OpenRouter Provider Route & Cache Settings (V36)
    ProviderRoute? aiMotivationProviderRoute,
    bool? aiMotivationEnableCache,
    ProviderRoute? aiTaskProviderRoute,
    bool? aiTaskEnableCache,
    ProviderRoute? aiRewardProviderRoute,
    bool? aiRewardEnableCache,
    ProviderRoute? aiTagSuggestionsProviderRoute,
    bool? aiTagSuggestionsEnableCache,
    // Brief Settings
    bool? briefIncludeSubtasks,
    bool? briefIncludePomodoro,
    bool? briefCompletedToday,
    bool? briefCompletedWeek,
    bool? briefCompletedMonth,
    bool? briefCompletedYear,
    bool? briefCompletedAll,
  }) async {
    final db = await database;

    // Načíst současná nastavení
    final current = await getSettings();

    // Připravit data k update
    final updateData = <String, dynamic>{};
    if (apiKey != null) updateData['api_key'] = apiKey;
    if (model != null) updateData['model'] = model;
    if (temperature != null) updateData['temperature'] = temperature;
    if (maxTokens != null) updateData['max_tokens'] = maxTokens;
    if (enabled != null) updateData['enabled'] = enabled ? 1 : 0;
    if (tagDelimiterStart != null) updateData['tag_delimiter_start'] = tagDelimiterStart;
    if (tagDelimiterEnd != null) updateData['tag_delimiter_end'] = tagDelimiterEnd;
    if (selectedTheme != null) updateData['selected_theme'] = selectedTheme;
    if (hasSeenGestureHint != null) updateData['has_seen_gesture_hint'] = hasSeenGestureHint ? 1 : 0;
    // AI Settings
    if (openRouterApiKey != null) updateData['openrouter_api_key'] = openRouterApiKey;
    if (aiMotivationModel != null) updateData['ai_motivation_model'] = aiMotivationModel;
    if (aiMotivationTemperature != null) updateData['ai_motivation_temperature'] = aiMotivationTemperature;
    if (aiMotivationMaxTokens != null) updateData['ai_motivation_max_tokens'] = aiMotivationMaxTokens;
    if (aiTaskModel != null) updateData['ai_task_model'] = aiTaskModel;
    if (aiTaskTemperature != null) updateData['ai_task_temperature'] = aiTaskTemperature;
    if (aiTaskMaxTokens != null) updateData['ai_task_max_tokens'] = aiTaskMaxTokens;
    if (aiRewardModel != null) updateData['ai_reward_model'] = aiRewardModel;
    if (aiRewardTemperature != null) updateData['ai_reward_temperature'] = aiRewardTemperature;
    if (aiRewardMaxTokens != null) updateData['ai_reward_max_tokens'] = aiRewardMaxTokens;
    if (aiTagSuggestionsModel != null) updateData['ai_tag_suggestions_model'] = aiTagSuggestionsModel;
    if (aiTagSuggestionsTemperature != null) updateData['ai_tag_suggestions_temperature'] = aiTagSuggestionsTemperature;
    if (aiTagSuggestionsMaxTokens != null) updateData['ai_tag_suggestions_max_tokens'] = aiTagSuggestionsMaxTokens;
    if (aiTagSuggestionsSeed != null) updateData['ai_tag_suggestions_seed'] = aiTagSuggestionsSeed;
    if (aiTagSuggestionsTopP != null) updateData['ai_tag_suggestions_top_p'] = aiTagSuggestionsTopP;
    if (aiTagSuggestionsDebounceMs != null) updateData['ai_tag_suggestions_debounce_ms'] = aiTagSuggestionsDebounceMs;
    // OpenRouter Provider Route & Cache Settings (V36)
    if (aiMotivationProviderRoute != null) updateData['ai_motivation_provider_route'] = aiMotivationProviderRoute.value;
    if (aiMotivationEnableCache != null) updateData['ai_motivation_enable_cache'] = aiMotivationEnableCache ? 1 : 0;
    if (aiTaskProviderRoute != null) updateData['ai_task_provider_route'] = aiTaskProviderRoute.value;
    if (aiTaskEnableCache != null) updateData['ai_task_enable_cache'] = aiTaskEnableCache ? 1 : 0;
    if (aiRewardProviderRoute != null) updateData['ai_reward_provider_route'] = aiRewardProviderRoute.value;
    if (aiRewardEnableCache != null) updateData['ai_reward_enable_cache'] = aiRewardEnableCache ? 1 : 0;
    if (aiTagSuggestionsProviderRoute != null) updateData['ai_tag_suggestions_provider_route'] = aiTagSuggestionsProviderRoute.value;
    if (aiTagSuggestionsEnableCache != null) updateData['ai_tag_suggestions_enable_cache'] = aiTagSuggestionsEnableCache ? 1 : 0;
    // Brief Settings
    if (briefIncludeSubtasks != null) updateData['brief_include_subtasks'] = briefIncludeSubtasks ? 1 : 0;
    if (briefIncludePomodoro != null) updateData['brief_include_pomodoro'] = briefIncludePomodoro ? 1 : 0;
    if (briefCompletedToday != null) updateData['brief_completed_today'] = briefCompletedToday ? 1 : 0;
    if (briefCompletedWeek != null) updateData['brief_completed_week'] = briefCompletedWeek ? 1 : 0;
    if (briefCompletedMonth != null) updateData['brief_completed_month'] = briefCompletedMonth ? 1 : 0;
    if (briefCompletedYear != null) updateData['brief_completed_year'] = briefCompletedYear ? 1 : 0;
    if (briefCompletedAll != null) updateData['brief_completed_all'] = briefCompletedAll ? 1 : 0;

    if (updateData.isEmpty) return;

    // Update nebo insert
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isEmpty) {
      await db.insert('settings', {
        'id': 1,
        'api_key': apiKey ?? current['api_key'],
        'model': model ?? current['model'],
        'temperature': temperature ?? current['temperature'],
        'max_tokens': maxTokens ?? current['max_tokens'],
        'enabled': (enabled ?? (current['enabled'] == 1)) ? 1 : 0,
        'tag_delimiter_start': tagDelimiterStart ?? current['tag_delimiter_start'],
        'tag_delimiter_end': tagDelimiterEnd ?? current['tag_delimiter_end'],
        'selected_theme': selectedTheme ?? current['selected_theme'],
        'has_seen_gesture_hint': (hasSeenGestureHint ?? (current['has_seen_gesture_hint'] == 1)) ? 1 : 0,
      });
    } else {
      await db.update(
        'settings',
        updateData,
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }

  /// Načíst všechny custom prompty
  Future<List<Map<String, dynamic>>> getAllPrompts() async {
    final db = await database;
    return await db.query('custom_prompts');
  }

  /// Najít prompt podle kategorie nebo tagů
  Future<Map<String, dynamic>?> findPromptByTags(List<String> taskTags) async {
    final db = await database;
    final prompts = await db.query('custom_prompts');

    // Pokusit se najít prompt podle tagů
    for (final prompt in prompts) {
      final promptTagsJson = prompt['tags'] as String;
      final promptTags = (promptTagsJson)
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .toList();

      // Zkontrolovat, jestli se některý tag shoduje
      for (final tag in taskTags) {
        if (promptTags.contains(tag.toLowerCase())) {
          return prompt;
        }
      }
    }

    return null; // Žádný prompt nenalezen
  }

  /// Migrovat staré úkoly - přeparsovat tagy a odstranit je z textu
  Future<void> migrateOldTasks() async {
    final db = await database;

    // Načíst všechny úkoly jako raw data
    final maps = await db.query('todos');

    for (final map in maps) {
      final taskText = map['task'] as String;

      // Zkontrolovat, jestli text obsahuje tagy
      if (taskText.contains('*')) {
        // Přeparsovat pomocí TagParser
        final tagRegex = RegExp(r'\*([^*]+)\*');
        final cleanText = taskText.replaceAll(tagRegex, '').trim();

        // Pokud se text změnil, aktualizovat v databázi
        if (cleanText != taskText) {
          await db.update(
            'todos',
            {'task': cleanText},
            where: 'id = ?',
            whereArgs: [map['id']],
          );
        }
      }
    }
  }

  // ==================== TAG DEFINITIONS CRUD ====================

  /// Získat všechny definice tagů
  Future<List<Map<String, dynamic>>> getAllTagDefinitions() async {
    final db = await database;
    return await db.query('tag_definitions', orderBy: 'tag_type, sort_order');
  }

  /// Získat pouze povolené definice tagů
  Future<List<Map<String, dynamic>>> getEnabledTagDefinitions() async {
    final db = await database;
    return await db.query(
      'tag_definitions',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'tag_type, sort_order',
    );
  }

  /// Získat definice tagů podle typu
  Future<List<Map<String, dynamic>>> getTagDefinitionsByType(
      String tagType) async {
    final db = await database;
    return await db.query(
      'tag_definitions',
      where: 'tag_type = ? AND enabled = ?',
      whereArgs: [tagType, 1],
      orderBy: 'sort_order',
    );
  }

  /// Najít definici tagu podle názvu
  Future<Map<String, dynamic>?> getTagDefinitionByName(String tagName) async {
    final db = await database;
    final results = await db.query(
      'tag_definitions',
      where: 'tag_name = ?',
      whereArgs: [tagName.toLowerCase()],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Přidat novou definici tagu
  Future<int> insertTagDefinition(Map<String, dynamic> tagDef) async {
    final db = await database;
    return await db.insert('tag_definitions', tagDef);
  }

  /// Aktualizovat definici tagu
  Future<int> updateTagDefinition(int id, Map<String, dynamic> tagDef) async {
    final db = await database;
    return await db.update(
      'tag_definitions',
      tagDef,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat definici tagu
  Future<int> deleteTagDefinition(int id) async {
    final db = await database;
    return await db.delete(
      'tag_definitions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Zapnout/vypnout tag
  Future<int> toggleTagDefinition(int id, bool enabled) async {
    final db = await database;
    return await db.update(
      'tag_definitions',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SUBTASKS CRUD ====================

  /// Přidat nový subtask
  Future<int> insertSubtask(Map<String, dynamic> subtask) async {
    final db = await database;
    return await db.insert('subtasks', subtask);
  }

  /// Získat všechny subtasks pro TODO
  Future<List<Map<String, dynamic>>> getSubtasksByTodoId(int todoId) async {
    final db = await database;
    return await db.query(
      'subtasks',
      where: 'parent_todo_id = ?',
      whereArgs: [todoId],
      orderBy: 'subtask_number ASC',
    );
  }

  /// Aktualizovat subtask
  Future<int> updateSubtask(int id, Map<String, dynamic> subtask) async {
    final db = await database;
    return await db.update(
      'subtasks',
      subtask,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat subtask
  Future<int> deleteSubtask(int id) async {
    final db = await database;
    return await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
  }

  /// Smazat všechny subtasks pro TODO (použít před vytvořením nových)
  Future<int> deleteSubtasksByTodoId(int todoId) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'parent_todo_id = ?',
      whereArgs: [todoId],
    );
  }

  /// Toggle subtask completed
  Future<int> toggleSubtaskCompleted(int id, bool completed) async {
    final db = await database;
    return await db.update(
      'subtasks',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update TODO s AI metadata
  Future<int> updateTodoAIMetadata(
    int id, {
    String? aiRecommendations,
    String? aiDeadlineAnalysis,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};

    if (aiRecommendations != null) {
      updates['ai_recommendations'] = aiRecommendations;
    }
    if (aiDeadlineAnalysis != null) {
      updates['ai_deadline_analysis'] = aiDeadlineAnalysis;
    }

    if (updates.isEmpty) return 0;

    return await db.update('todos', updates, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TAGS CRUD ====================

  /// Získat TOP custom tagy (pro autocomplete)
  Future<List<Map<String, dynamic>>> getTopCustomTags({int limit = 10}) async {
    final db = await database;

    return await db.query(
      'tags',
      where: 'tag_type = ?',
      whereArgs: ['custom'],
      orderBy: 'usage_count DESC, last_used DESC',
      limit: limit,
    );
  }

  /// Vyhledat tagy (autocomplete během psaní)
  ///
  /// Vrací custom tagy + systémové tagy (priority, date, status) s barvami/emoji/glow z tag_definitions
  /// Používá prefix matching (začíná na query), ne substring matching
  Future<List<Map<String, dynamic>>> searchTags(String query, {int limit = 5}) async {
    final db = await database;

    // LEFT JOIN s tag_definitions pro získání barvy/emoji/glow (systémové tagy)
    final results = await db.rawQuery('''
      SELECT
        t.tag_name,
        t.display_name,
        t.tag_type,
        t.usage_count,
        td.emoji,
        td.color,
        td.glow_enabled,
        td.glow_strength
      FROM tags t
      LEFT JOIN tag_definitions td ON t.tag_name = td.tag_name
      WHERE t.tag_name LIKE ?
      ORDER BY
        CASE t.tag_type
          WHEN 'priority' THEN 1
          WHEN 'date' THEN 2
          WHEN 'status' THEN 3
          ELSE 4
        END,
        t.usage_count DESC
      LIMIT ?
    ''', ['${query.toLowerCase()}%', limit]);

    return results;
  }

  /// Získat nebo vytvořit tag (při vytváření TODO)
  Future<int> getOrCreateTagId(String tagName) async {
    final db = await database;
    final normalized = tagName.toLowerCase();

    // Check if exists
    final existing = await db.query(
      'tags',
      where: 'tag_name = ?',
      whereArgs: [normalized],
    );

    if (existing.isNotEmpty) {
      // Update last_used timestamp
      await db.update(
        'tags',
        {
          'last_used': DateTime.now().millisecondsSinceEpoch,
          'usage_count': (existing.first['usage_count'] as int) + 1,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );

      return existing.first['id'] as int;
    }

    // Create new tag
    return await db.insert('tags', {
      'tag_name': normalized,
      'display_name': tagName,
      'tag_type': 'custom',
      'usage_count': 1,
      'last_used': DateTime.now().millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Přidat tags k TODO
  Future<void> addTagsToTodo(int todoId, List<String> tagNames) async {
    final db = await database;

    for (final tagName in tagNames) {
      final tagId = await getOrCreateTagId(tagName);

      // Vytvořit vazbu (ignore duplicates)
      await db.insert(
        'todo_tags',
        {
          'todo_id': todoId,
          'tag_id': tagId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Odstranit všechny tags z TODO
  Future<void> removeAllTagsFromTodo(int todoId) async {
    final db = await database;
    await db.delete('todo_tags', where: 'todo_id = ?', whereArgs: [todoId]);
  }

  /// Získat tagy pro TODO
  Future<List<String>> getTagsForTodo(int todoId) async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT t.display_name
      FROM tags t
      INNER JOIN todo_tags tt ON t.id = tt.tag_id
      WHERE tt.todo_id = ?
      ORDER BY t.display_name
    ''', [todoId]);

    return results.map((row) => row['display_name'] as String).toList();
  }

  /// Vyčistit nepoužívané tagy (optional - pro maintenance)
  Future<void> cleanupUnusedTags() async {
    final db = await database;

    // Smazat tagy, které nemají žádnou vazbu na TODO
    await db.rawDelete('''
      DELETE FROM tags
      WHERE id NOT IN (SELECT DISTINCT tag_id FROM todo_tags)
        AND tag_type = 'custom'
    ''');
  }

  // ==================== CUSTOM AGENDA VIEWS CRUD ====================

  /// Získat všechny custom agenda views
  Future<List<Map<String, dynamic>>> getAllCustomAgendaViews() async {
    final db = await database;
    return await db.query('custom_agenda_views', orderBy: 'sort_order ASC');
  }

  /// Získat pouze enabled custom views
  Future<List<Map<String, dynamic>>> getEnabledCustomAgendaViews() async {
    final db = await database;
    return await db.query(
      'custom_agenda_views',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC',
    );
  }

  /// Přidat custom agenda view
  Future<void> insertCustomAgendaView(Map<String, dynamic> view) async {
    final db = await database;
    await db.insert('custom_agenda_views', view);
  }

  /// Aktualizovat custom agenda view
  Future<void> updateCustomAgendaView(String id, Map<String, dynamic> view) async {
    final db = await database;
    await db.update(
      'custom_agenda_views',
      view,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat custom agenda view
  Future<void> deleteCustomAgendaView(String id) async {
    final db = await database;
    await db.delete('custom_agenda_views', where: 'id = ?', whereArgs: [id]);
  }

  /// Toggle custom agenda view enabled
  Future<void> toggleCustomAgendaView(String id, bool enabled) async {
    final db = await database;
    await db.update(
      'custom_agenda_views',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update built-in view settings
  Future<void> updateBuiltInViewSettings({
    bool? showAll,
    bool? showToday,
    bool? showWeek,
    bool? showUpcoming,
    bool? showOverdue,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};

    if (showAll != null) updates['show_all'] = showAll ? 1 : 0;
    if (showToday != null) updates['show_today'] = showToday ? 1 : 0;
    if (showWeek != null) updates['show_week'] = showWeek ? 1 : 0;
    if (showUpcoming != null) updates['show_upcoming'] = showUpcoming ? 1 : 0;
    if (showOverdue != null) updates['show_overdue'] = showOverdue ? 1 : 0;

    if (updates.isNotEmpty) {
      await db.update('settings', updates, where: 'id = 1');
    }
  }

  // ==================== POMODORO SESSIONS CRUD ====================

  /// Získat Pomodoro sessions pro konkrétní TODO úkol
  Future<List<Map<String, dynamic>>> getPomodoroSessionsByTodoId(int todoId) async {
    final db = await database;
    return await db.query(
      'pomodoro_sessions',
      where: 'task_id = ?',
      whereArgs: [todoId],
      orderBy: 'started_at DESC',
    );
  }

  // ==================== PERFORMANCE & MAINTENANCE ====================

  /// Optimalizovat query planner (pravidelně spouštět)
  Future<void> analyzeDatabase() async {
    final db = await database;
    await db.execute('ANALYZE');
  }

  /// Vyčistit fragmentaci DB (POZOR: může trvat dlouho!)
  Future<void> vacuumDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Získat aktuální page size
  Future<int> getPageSize() async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA page_size');
    return result.first['page_size'] as int;
  }

  // ==================== NOTES CRUD (MILESTONE 1) ====================

  /// Vytvořit novou poznámku
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('notes', note);
  }

  /// Získat všechny poznámky (seřazené od nejnovějších)
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await database;
    return await db.query('notes', orderBy: 'updated_at DESC');
  }

  /// Získat poznámku podle ID
  Future<Map<String, dynamic>?> getNoteById(int id) async {
    final db = await database;
    final results = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Aktualizovat poznámku
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await database;
    return await db.update(
      'notes',
      note,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat poznámku
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Získat počet poznámek
  Future<int> getNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Získat nejnovější poznámky (limit)
  Future<List<Map<String, dynamic>>> getRecentNotes({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'notes',
      orderBy: 'updated_at DESC',
      limit: limit,
    );
  }

  // ==================== NOTE_TAGS CRUD (MILESTONE 3) ====================

  /// Přidat tagy k poznámce
  Future<void> addTagsToNote(int noteId, List<String> tags) async {
    final db = await database;

    for (final tag in tags) {
      // Vytvořit vazbu (ignore duplicates)
      await db.insert(
        'note_tags',
        {
          'note_id': noteId,
          'tag': tag.toLowerCase(),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  /// Odstranit všechny tagy z poznámky
  Future<void> removeAllTagsFromNote(int noteId) async {
    final db = await database;
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [noteId]);
  }

  /// Získat tagy pro poznámku
  Future<List<String>> getTagsForNote(int noteId) async {
    final db = await database;

    final results = await db.query(
      'note_tags',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'tag',
    );

    return results.map((row) => row['tag'] as String).toList();
  }

  /// Získat všechny unikátní tagy z poznámek (pro autocomplete)
  Future<List<String>> getAllUniqueNoteTags() async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT DISTINCT tag
      FROM note_tags
      ORDER BY tag
    ''');

    return results.map((row) => row['tag'] as String).toList();
  }

  /// Získat poznámky podle tagu
  Future<List<Map<String, dynamic>>> getNotesByTag(String tag) async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT n.*
      FROM notes n
      INNER JOIN note_tags nt ON n.id = nt.note_id
      WHERE nt.tag = ?
      ORDER BY n.updated_at DESC
    ''', [tag.toLowerCase()]);

    return results;
  }

  /// Vyhledat Note tagy (autocomplete během psaní)
  ///
  /// Používá prefix matching (začíná na query), vrací unique tagy seřazené podle počtu použití
  Future<List<String>> searchNoteTags(String query, {int limit = 5}) async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT tag, COUNT(*) as count
      FROM note_tags
      WHERE tag LIKE ?
      GROUP BY tag
      ORDER BY count DESC
      LIMIT ?
    ''', ['${query.toLowerCase()}%', limit]);

    return results.map((row) => row['tag'] as String).toList();
  }

  // ==================== CUSTOM NOTES VIEWS CRUD ====================

  /// Získat všechny custom notes views
  Future<List<Map<String, dynamic>>> getAllCustomNotesViews() async {
    final db = await database;
    return await db.query('custom_notes_views', orderBy: 'sort_order ASC');
  }

  /// Získat pouze enabled custom notes views
  Future<List<Map<String, dynamic>>> getEnabledCustomNotesViews() async {
    final db = await database;
    return await db.query(
      'custom_notes_views',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'sort_order ASC',
    );
  }

  /// Přidat custom notes view
  Future<void> insertCustomNotesView(Map<String, dynamic> view) async {
    final db = await database;
    await db.insert('custom_notes_views', view);
  }

  /// Aktualizovat custom notes view
  Future<void> updateCustomNotesView(String id, Map<String, dynamic> view) async {
    final db = await database;
    await db.update(
      'custom_notes_views',
      view,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat custom notes view
  Future<void> deleteCustomNotesView(String id) async {
    final db = await database;
    await db.delete('custom_notes_views', where: 'id = ?', whereArgs: [id]);
  }

  /// Toggle custom notes view enabled
  Future<void> toggleCustomNotesView(String id, bool enabled) async {
    final db = await database;
    await db.update(
      'custom_notes_views',
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update built-in notes view settings
  Future<void> updateBuiltInNotesViewSettings({
    bool? showAllNotes,
    bool? showRecentNotes,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};

    if (showAllNotes != null) updates['show_all_notes'] = showAllNotes ? 1 : 0;
    if (showRecentNotes != null) updates['show_recent_notes'] = showRecentNotes ? 1 : 0;

    if (updates.isNotEmpty) {
      await db.update('settings', updates, where: 'id = 1');
    }
  }

  // ==================== FTS5 FULL-TEXT SEARCH (VERZE 22) ====================

  /// Full-text search v TODOs (FTS5 nebo Dart fallback)
  ///
  /// Query syntax (pouze pokud FTS5 dostupné):
  /// - "prezentaci" → simple keyword
  /// - "dokončit prezentaci" → phrase search (exact match)
  /// - "dokončit OR připravit" → boolean OR
  /// - "prezentaci NOT hotovo" → boolean NOT
  /// - "prog*" → prefix search (programming, programmer...)
  ///
  /// Vrací: List<TodoItem> seřazené podle relevance (BM25 rank) nebo podle match score
  Future<List<TodoItem>> fullTextSearchTodos(String query) async {
    final db = await database;

    // Check pokud FTS5 je dostupné
    if (!_fts5Available) {
      // ❌ Fallback: Dart-side filtering (case-insensitive LIKE)
      final allTodos = await db.query('todos');
      final queryLower = query.toLowerCase();

      return allTodos
          .where((map) {
            final task = (map['task'] as String).toLowerCase();
            final tags = (map['tags'] as String? ?? '').toLowerCase();
            return task.contains(queryLower) || tags.contains(queryLower);
          })
          .map((map) => TodoItem.fromMap(map))
          .toList();
    }

    // ✅ FTS5 query s JOINem zpět do todos tabulky
    // rank → BM25 relevance score (nižší = relevantnější)
    final results = await db.rawQuery('''
      SELECT t.*
      FROM todos t
      INNER JOIN todos_fts fts ON t.id = fts.rowid
      WHERE todos_fts MATCH ?
      ORDER BY rank
    ''', [query]);

    return results.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// Full-text search v Notes (FTS5 nebo Dart fallback)
  ///
  /// Query syntax: stejná jako fullTextSearchTodos
  ///
  /// Vrací: List<Map<String, dynamic>> poznámek seřazených podle relevance
  Future<List<Map<String, dynamic>>> fullTextSearchNotes(String query) async {
    final db = await database;

    // Check pokud FTS5 je dostupné
    if (!_fts5Available) {
      // ❌ Fallback: Dart-side filtering (case-insensitive LIKE)
      final allNotes = await db.query('notes');
      final queryLower = query.toLowerCase();

      return allNotes
          .where((map) {
            final content = (map['content'] as String).toLowerCase();
            return content.contains(queryLower);
          })
          .toList();
    }

    // ✅ FTS5 query
    final results = await db.rawQuery('''
      SELECT n.*
      FROM notes n
      INNER JOIN notes_fts fts ON n.id = fts.rowid
      WHERE notes_fts MATCH ?
      ORDER BY rank
    ''', [query]);

    return results;
  }

  /// Rebuild FTS5 indexes (pro maintenance)
  ///
  /// Použij pokud:
  /// - FTS5 index je corrupted
  /// - Migrace z verze < 22 (naplnit FTS5 existujícími daty)
  /// - Performance degradace (OPTIMIZE FTS5)
  Future<void> rebuildFTS5Indexes() async {
    // Skip pokud FTS5 není dostupné
    if (!_fts5Available) {
      print('⚠️ Skip FTS5 rebuild - FTS5 není dostupné');
      return;
    }

    final db = await database;

    // Rebuild todos_fts
    await db.execute("INSERT INTO todos_fts(todos_fts) VALUES('rebuild')");

    // Rebuild notes_fts
    await db.execute("INSERT INTO notes_fts(notes_fts) VALUES('rebuild')");

    // Optimize FTS5 (merge b-tree segments)
    await db.execute("INSERT INTO todos_fts(todos_fts) VALUES('optimize')");
    await db.execute("INSERT INTO notes_fts(notes_fts) VALUES('optimize')");
  }

  // ==================== RECURRENCE CRUD ====================

  /// Vytvořit recurrence rule pro TODO
  Future<int> insertRecurrenceRule(Map<String, dynamic> rule) async {
    final db = await database;
    return await db.insert('recurrence_rules', rule);
  }

  /// Získat recurrence rule pro TODO
  Future<Map<String, dynamic>?> getRecurrenceRuleByTodoId(int todoId) async {
    final db = await database;
    final results = await db.query(
      'recurrence_rules',
      where: 'todo_id = ?',
      whereArgs: [todoId],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Aktualizovat recurrence rule
  Future<int> updateRecurrenceRule(int id, Map<String, dynamic> rule) async {
    final db = await database;
    return await db.update(
      'recurrence_rules',
      rule,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Smazat recurrence rule
  Future<int> deleteRecurrenceRule(int id) async {
    final db = await database;
    return await db.delete('recurrence_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// Update due_date u TODO (pro recurring tasks)
  Future<int> updateTodoDueDate(int id, DateTime newDueDate) async {
    final db = await database;
    return await db.update(
      'todos',
      {'dueDate': newDueDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
