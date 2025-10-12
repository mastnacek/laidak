import 'dart:convert'; // Pro jsonDecode při migraci z SharedPrefs
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Pro migraci agenda views
import '../../models/todo_item.dart';

/// Singleton služba pro správu SQLite databáze
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

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
      version: 14,  // ← AI Settings (Motivation + Task models)
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
    // Tabulka úkolů (s AI metadata sloupci)
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        priority TEXT,
        dueDate TEXT,
        tags TEXT,  -- ❌ DEPRECATED: Používej todo_tags tabulku!
        ai_recommendations TEXT,
        ai_deadline_analysis TEXT
      )
    ''');

    // Tabulka AI nastavení + nastavení tagů + téma + UX hints + built-in views
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        api_key TEXT,
        model TEXT NOT NULL DEFAULT 'mistralai/mistral-medium-3.1',
        temperature REAL NOT NULL DEFAULT 1.0,
        max_tokens INTEGER NOT NULL DEFAULT 1000,
        enabled INTEGER NOT NULL DEFAULT 1,
        tag_delimiter_start TEXT NOT NULL DEFAULT '*',
        tag_delimiter_end TEXT NOT NULL DEFAULT '*',
        selected_theme TEXT NOT NULL DEFAULT 'doom_one',
        has_seen_gesture_hint INTEGER NOT NULL DEFAULT 0,
        show_all INTEGER NOT NULL DEFAULT 1,
        show_today INTEGER NOT NULL DEFAULT 1,
        show_week INTEGER NOT NULL DEFAULT 1,
        show_upcoming INTEGER NOT NULL DEFAULT 0,
        show_overdue INTEGER NOT NULL DEFAULT 1,
        openrouter_api_key TEXT,
        ai_motivation_model TEXT NOT NULL DEFAULT 'mistralai/mistral-medium-3.1',
        ai_motivation_temperature REAL NOT NULL DEFAULT 0.9,
        ai_motivation_max_tokens INTEGER NOT NULL DEFAULT 200,
        ai_task_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-sonnet',
        ai_task_temperature REAL NOT NULL DEFAULT 0.3,
        ai_task_max_tokens INTEGER NOT NULL DEFAULT 1000
      )
    ''');

    // Tabulka custom promptů pro motivaci
    await db.execute('''
      CREATE TABLE custom_prompts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL UNIQUE,
        system_prompt TEXT NOT NULL,
        tags TEXT NOT NULL,
        style TEXT NOT NULL
      )
    ''');

    // Tabulka definic tagů (systémové tagy konfigurovatelné uživatelem)
    await db.execute('''
      CREATE TABLE tag_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_name TEXT UNIQUE NOT NULL,
        tag_type TEXT NOT NULL,
        display_name TEXT,
        emoji TEXT,
        color TEXT,
        glow_enabled INTEGER NOT NULL DEFAULT 0,
        glow_strength REAL NOT NULL DEFAULT 0.5,
        sort_order INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabulka custom tagů (normalizované)
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_name TEXT UNIQUE NOT NULL,
        display_name TEXT,
        tag_type TEXT NOT NULL DEFAULT 'custom',
        usage_count INTEGER NOT NULL DEFAULT 0,
        last_used INTEGER,
        created_at INTEGER NOT NULL,

        CHECK (tag_name = LOWER(tag_name))
      )
    ''');

    await db.execute('CREATE INDEX idx_tags_type ON tags(tag_type)');
    await db.execute('CREATE INDEX idx_tags_usage ON tags(usage_count DESC)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(tag_name)');

    // Many-to-many vazba: TODO ↔ Tags
    await db.execute('''
      CREATE TABLE todo_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,

        FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE,

        UNIQUE(todo_id, tag_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_todo_tags_todo_id ON todo_tags(todo_id)');
    await db.execute('CREATE INDEX idx_todo_tags_tag_id ON todo_tags(tag_id)');

    // Tabulka custom agenda views
    await db.execute('''
      CREATE TABLE custom_agenda_views (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tag_filter TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '⭐',
        color_hex TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,

        CHECK (LENGTH(name) > 0),
        CHECK (LENGTH(tag_filter) > 0)
      )
    ''');

    await db.execute('CREATE INDEX idx_custom_views_enabled ON custom_agenda_views(enabled)');
    await db.execute('CREATE INDEX idx_custom_views_sort ON custom_agenda_views(sort_order)');

    // Tabulka podúkolů pro AI split
    await db.execute('''
      CREATE TABLE subtasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_todo_id INTEGER NOT NULL,
        subtask_number INTEGER NOT NULL,
        text TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(parent_todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        UNIQUE(parent_todo_id, subtask_number)
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id)');
    await db
        .execute('CREATE INDEX idx_subtasks_completed ON subtasks(completed)');

    // Tabulka Pomodoro sessions
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration INTEGER NOT NULL,
        actual_duration INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        is_break INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(task_id) REFERENCES todos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_pomodoro_task ON pomodoro_sessions(task_id)');
    await db.execute('CREATE INDEX idx_pomodoro_date ON pomodoro_sessions(started_at)');

    // Performance indexy pro todos tabulku (rychlejší vyhledávání a sortování)
    await db.execute('CREATE INDEX idx_todos_task ON todos(task)');
    await db.execute('CREATE INDEX idx_todos_tags ON todos(tags)');
    await db.execute('CREATE INDEX idx_todos_dueDate ON todos(dueDate)');
    await db.execute('CREATE INDEX idx_todos_priority ON todos(priority)');
    await db.execute('CREATE INDEX idx_todos_isCompleted ON todos(isCompleted)');
    await db.execute('CREATE INDEX idx_todos_createdAt ON todos(createdAt)');

    // Vložit výchozí nastavení
    await _insertDefaultSettings(db);
    await _insertDefaultPrompts(db);
    await _insertDefaultTagDefinitions(db);
  }

  /// Upgrade databáze na novou verzi
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Přidat tabulky pro AI nastavení a prompty
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          api_key TEXT,
          model TEXT NOT NULL DEFAULT 'mistralai/mistral-medium-3.1',
          temperature REAL NOT NULL DEFAULT 1.0,
          max_tokens INTEGER NOT NULL DEFAULT 1000,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_prompts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL UNIQUE,
          system_prompt TEXT NOT NULL,
          tags TEXT NOT NULL,
          style TEXT NOT NULL
        )
      ''');

      await _insertDefaultSettings(db);
      await _insertDefaultPrompts(db);
    }

    if (oldVersion < 3) {
      // Přidat tabulku pro definice tagů
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tag_definitions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tag_name TEXT UNIQUE NOT NULL,
          tag_type TEXT NOT NULL,
          display_name TEXT,
          emoji TEXT,
          color TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          enabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await _insertDefaultTagDefinitions(db);
    }

    if (oldVersion < 4) {
      // Přidat sloupce pro nastavení oddělovačů tagů
      await db.execute('''
        ALTER TABLE settings ADD COLUMN tag_delimiter_start TEXT NOT NULL DEFAULT '*'
      ''');

      await db.execute('''
        ALTER TABLE settings ADD COLUMN tag_delimiter_end TEXT NOT NULL DEFAULT '*'
      ''');
    }

    if (oldVersion < 5) {
      // Přidat sloupec pro vybrané téma
      await db.execute('''
        ALTER TABLE settings ADD COLUMN selected_theme TEXT NOT NULL DEFAULT 'doom_one'
      ''');
    }

    if (oldVersion < 6) {
      // Přidat sloupce pro glow efekt tagů
      await db.execute('''
        ALTER TABLE tag_definitions ADD COLUMN glow_enabled INTEGER NOT NULL DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE tag_definitions ADD COLUMN glow_strength REAL NOT NULL DEFAULT 0.5
      ''');
    }

    if (oldVersion < 7) {
      // Přidat AI metadata sloupce do todos
      await db.execute('''
        ALTER TABLE todos ADD COLUMN ai_recommendations TEXT
      ''');

      await db.execute('''
        ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT
      ''');

      // Vytvořit subtasks tabulku
      await db.execute('''
        CREATE TABLE subtasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          parent_todo_id INTEGER NOT NULL,
          subtask_number INTEGER NOT NULL,
          text TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY(parent_todo_id) REFERENCES todos(id) ON DELETE CASCADE,
          UNIQUE(parent_todo_id, subtask_number)
        )
      ''');

      await db.execute(
          'CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id)');
      await db.execute(
          'CREATE INDEX idx_subtasks_completed ON subtasks(completed)');
    }

    if (oldVersion < 8) {
      // Přidat performance indexy pro rychlejší vyhledávání a sortování
      // Tyto indexy urychlí operace v Dart-side filtering pipeline:
      // - search (task text, tags)
      // - sort (priority, dueDate, isCompleted, createdAt)
      // - views (dueDate pro Today/Week/Upcoming/Overdue)

      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_task ON todos(task)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_tags ON todos(tags)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_dueDate ON todos(dueDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_isCompleted ON todos(isCompleted)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_createdAt ON todos(createdAt)');
    }

    if (oldVersion < 9) {
      // Bezpečná migrace: Přidat AI sloupce pokud neexistují
      // Tato migrace opravuje problém pro uživatele, kteří měli verzi < 7
      // ale upgrade na verzi 7 neproběhl správně

      final columns = await db.rawQuery('PRAGMA table_info(todos)');
      final columnNames = columns.map((col) => col['name'] as String).toList();

      if (!columnNames.contains('ai_recommendations')) {
        await db.execute('ALTER TABLE todos ADD COLUMN ai_recommendations TEXT');
      }

      if (!columnNames.contains('ai_deadline_analysis')) {
        await db.execute('ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT');
      }
    }

    if (oldVersion < 10) {
      // Přidat sloupec pro gesture hint tracking
      await db.execute('''
        ALTER TABLE settings ADD COLUMN has_seen_gesture_hint INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 11) {
      // MILESTONE 1: Tags normalization
      await _createTagsTables(db);
      await _migrateTagsToNormalizedSchema(db);

      // MILESTONE 2: Custom Agenda Views to DB
      await _createCustomAgendaViewsTable(db);
      await _addBuiltInViewSettingsColumns(db);
      await _migrateAgendaViewsToDb(db);
    }

    if (oldVersion < 12) {
      // MILESTONE 3: Emoji místo iconCodePoint v custom_agenda_views
      await _migrateIconCodePointToEmoji(db);
    }

    if (oldVersion < 13) {
      // MILESTONE: Pomodoro Sessions tabulka
      await _createPomodoroSessionsTable(db);
    }

    if (oldVersion < 14) {
      // AI Settings: Přidat sloupce pro Motivation + Task models
      await db.execute('ALTER TABLE settings ADD COLUMN openrouter_api_key TEXT');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_model TEXT NOT NULL DEFAULT \'mistralai/mistral-medium-3.1\'');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_temperature REAL NOT NULL DEFAULT 0.9');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_max_tokens INTEGER NOT NULL DEFAULT 200');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_task_model TEXT NOT NULL DEFAULT \'anthropic/claude-3.5-sonnet\'');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_task_temperature REAL NOT NULL DEFAULT 0.3');
      await db.execute('ALTER TABLE settings ADD COLUMN ai_task_max_tokens INTEGER NOT NULL DEFAULT 1000');
    }
  }

  /// Vložit výchozí AI nastavení
  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert('settings', {
      'id': 1,
      'api_key': null, // User must provide their own OpenRouter API key
      'model': 'mistralai/mistral-medium-3.1',
      'temperature': 1.0,
      'max_tokens': 1000,
      'enabled': 1,
      'tag_delimiter_start': '*',
      'tag_delimiter_end': '*',
      'selected_theme': 'doom_one',
      'has_seen_gesture_hint': 0,
      'show_all': 1,
      'show_today': 1,
      'show_week': 1,
      'show_upcoming': 0,
      'show_overdue': 1,
      // AI Settings
      'openrouter_api_key': null,
      'ai_motivation_model': 'mistralai/mistral-medium-3.1',
      'ai_motivation_temperature': 0.9,
      'ai_motivation_max_tokens': 200,
      'ai_task_model': 'anthropic/claude-3.5-sonnet',
      'ai_task_temperature': 0.3,
      'ai_task_max_tokens': 1000,
    });
  }

  /// Vložit výchozí motivační prompty
  ///
  /// NOTE: Tyto prompty jsou jen ukázky! Uživatel si může vytvořit vlastní
  /// v Nastavení → Motivační Prompty podle svých preferencí.
  Future<void> _insertDefaultPrompts(Database db) async {
    // Demo prompt: Profesionální styl
    await db.insert('custom_prompts', {
      'category': 'práce',
      'system_prompt': 'Jsi motivační kouč zaměřený na produktivitu v práci. Motivuj uživatele k dokončení pracovních úkolů s důrazem na profesionalitu a efektivitu. Buď pozitivní, ale asertivní. Používej emoji pro zvýraznění.',
      'tags': '["práce","work","job","office","projekt","meeting"]',
      'style': 'profesionální a motivující',
    });

    // Demo prompt: Rodinný styl
    await db.insert('custom_prompts', {
      'category': 'domov',
      'system_prompt': 'Jsi přátelský asistent zaměřený na domácí úkoly a rodinu. Motivuj uživatele k dokončení domácích činností s důrazem na rodinné hodnoty a pohodlí domova. Buď vlídný a podporující. Používej emoji pro zvýraznění.',
      'tags': '["domov","doma","rodina","family","home"]',
      'style': 'rodinný a vlídný',
    });
  }

  /// Vložit výchozí definice tagů (podle Tauri verze + rozšíření)
  Future<void> _insertDefaultTagDefinitions(Database db) async {
    // Priority tagy
    await db.insert('tag_definitions', {
      'tag_name': 'a',
      'tag_type': 'priority',
      'display_name': 'Vysoká priorita',
      'emoji': '🔴',
      'color': '#ff0000',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'b',
      'tag_type': 'priority',
      'display_name': 'Střední priorita',
      'emoji': '🟡',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'c',
      'tag_type': 'priority',
      'display_name': 'Nízká priorita',
      'emoji': '🟢',
      'color': '#00ff00',
      'sort_order': 3,
      'enabled': 1,
    });

    // Časové/deadline tagy
    await db.insert('tag_definitions', {
      'tag_name': 'dnes',
      'tag_type': 'date',
      'display_name': 'Dnes',
      'emoji': '⏰',
      'color': '#ff0000',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zitra',
      'tag_type': 'date',
      'display_name': 'Zítra',
      'emoji': '📅',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zatyden',
      'tag_type': 'date',
      'display_name': 'Za týden',
      'emoji': '📆',
      'color': '#00aaff',
      'sort_order': 3,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zamesic',
      'tag_type': 'date',
      'display_name': 'Za měsíc',
      'emoji': '📆',
      'color': '#0088ff',
      'sort_order': 4,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zarok',
      'tag_type': 'date',
      'display_name': 'Za rok',
      'emoji': '📆',
      'color': '#0066ff',
      'sort_order': 5,
      'enabled': 1,
    });

    // Status tagy
    await db.insert('tag_definitions', {
      'tag_name': 'hotove',
      'tag_type': 'status',
      'display_name': 'Hotové',
      'emoji': '✅',
      'color': '#00ff00',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'todo',
      'tag_type': 'status',
      'display_name': 'K dokončení',
      'emoji': '📝',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });
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
  Future<int> toggleTodoStatus(int id, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'todos',
      {'isCompleted': isCompleted ? 1 : 0},
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

  // ==================== MIGRACE VERZE 11: TAGS NORMALIZATION ====================

  /// Vytvořit tabulky pro normalizované tagy (verze 11)
  Future<void> _createTagsTables(Database db) async {
    // Tabulka tags
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_name TEXT UNIQUE NOT NULL,
        display_name TEXT,
        tag_type TEXT NOT NULL DEFAULT 'custom',
        usage_count INTEGER NOT NULL DEFAULT 0,
        last_used INTEGER,
        created_at INTEGER NOT NULL,

        CHECK (tag_name = LOWER(tag_name))
      )
    ''');

    await db.execute('CREATE INDEX idx_tags_type ON tags(tag_type)');
    await db.execute('CREATE INDEX idx_tags_usage ON tags(usage_count DESC)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(tag_name)');

    // Tabulka todo_tags
    await db.execute('''
      CREATE TABLE todo_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,

        FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE,

        UNIQUE(todo_id, tag_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_todo_tags_todo_id ON todo_tags(todo_id)');
    await db.execute('CREATE INDEX idx_todo_tags_tag_id ON todo_tags(tag_id)');
  }

  /// Migrovat CSV tagy → normalizované tabulky
  Future<void> _migrateTagsToNormalizedSchema(Database db) async {
    try {
      // 1. Načíst všechny todos s CSV tags
      final todos = await db.query('todos');

      for (final todo in todos) {
        final todoId = todo['id'] as int;
        final tagsCSV = todo['tags'] as String?;

        if (tagsCSV == null || tagsCSV.isEmpty) continue;

        // 2. Split CSV a trim
        final tagsList = tagsCSV
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty);

        for (final tagName in tagsList) {
          // 3. Normalize tag name (lowercase)
          final normalized = tagName.toLowerCase();

          // 4. Insert nebo get existing tag
          final tagId = await _getOrCreateTag(db, normalized, tagName);

          // 5. Vytvořit vazbu todo_tags (ignore duplicates)
          await db.insert(
            'todo_tags',
            {
              'todo_id': todoId,
              'tag_id': tagId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          // 6. Inkrementovat usage_count
          await db.rawUpdate(
            'UPDATE tags SET usage_count = usage_count + 1, last_used = ? WHERE id = ?',
            [DateTime.now().millisecondsSinceEpoch, tagId],
          );
        }
      }

      // 7. Vyčistit CSV sloupec (nastavit na empty string, ne NULL)
      // ⚠️ Nechávám sloupec (SQLite nepodporuje DROP COLUMN), ale označím jako deprecated
      await db.rawUpdate("UPDATE todos SET tags = ''");

    } catch (e) {
      print('❌ Chyba při migraci tagů: $e');
      rethrow;
    }
  }

  /// Get nebo create tag (helper pro migraci)
  Future<int> _getOrCreateTag(
    Database db,
    String normalized,
    String original,
  ) async {
    // Check if exists
    final existing = await db.query(
      'tags',
      where: 'tag_name = ?',
      whereArgs: [normalized],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    // Create new tag
    return await db.insert('tags', {
      'tag_name': normalized,
      'display_name': original,
      'tag_type': 'custom',
      'usage_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ==================== MIGRACE VERZE 11: CUSTOM AGENDA VIEWS TO DB ====================

  /// Vytvořit tabulku custom_agenda_views (verze 11)
  Future<void> _createCustomAgendaViewsTable(Database db) async {
    await db.execute('''
      CREATE TABLE custom_agenda_views (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tag_filter TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '⭐',
        color_hex TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,

        CHECK (LENGTH(name) > 0),
        CHECK (LENGTH(tag_filter) > 0)
      )
    ''');

    await db.execute('CREATE INDEX idx_custom_views_enabled ON custom_agenda_views(enabled)');
    await db.execute('CREATE INDEX idx_custom_views_sort ON custom_agenda_views(sort_order)');
  }

  /// Přidat sloupce pro built-in views do settings
  Future<void> _addBuiltInViewSettingsColumns(Database db) async {
    await db.execute('ALTER TABLE settings ADD COLUMN show_all INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_today INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_week INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_upcoming INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE settings ADD COLUMN show_overdue INTEGER NOT NULL DEFAULT 1');
  }

  /// Migrovat custom agenda views z SharedPreferences → DB
  Future<void> _migrateAgendaViewsToDb(Database db) async {
    try {
      // ⚠️ POZNÁMKA: Migrace z SharedPrefs vyžaduje shared_preferences package
      // Import je ve funkci → fail-safe pro fresh install
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Načíst JSON string z SharedPrefs
      final jsonString = prefs.getString('agenda_config');

      if (jsonString == null || jsonString.isEmpty) {
        // Žádná data → fresh install nebo prázdná konfigurace
        print('ℹ️ Custom Agenda Views migrace: Žádná data v SharedPrefs (fresh install)');
        return;
      }

      // Parse JSON
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // 1. Migrovat built-in views do DB
      await db.update('settings', {
        'show_all': json['showAll'] == true ? 1 : 0,
        'show_today': json['showToday'] == true ? 1 : 0,
        'show_week': json['showWeek'] == true ? 1 : 0,
        'show_upcoming': json['showUpcoming'] == true ? 1 : 0,
        'show_overdue': json['showOverdue'] == true ? 1 : 0,
      }, where: 'id = 1');

      // 2. Migrovat custom views do DB
      final customViews = json['customViews'] as List<dynamic>?;
      if (customViews != null && customViews.isNotEmpty) {
        for (var i = 0; i < customViews.length; i++) {
          final view = customViews[i] as Map<String, dynamic>;

          await db.insert('custom_agenda_views', {
            'id': view['id'] as String,
            'name': view['name'] as String,
            'tag_filter': (view['tagFilter'] as String).toLowerCase(),
            'emoji': '⭐', // Default emoji (původně byl iconCodePoint)
            'color_hex': view['colorHex'] as String?,
            'sort_order': i,
            'enabled': 1,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      // 3. Vyčistit SharedPreferences (již nepotřebujeme)
      await prefs.remove('agenda_config');

      print('✅ Migrace agenda views dokončena: ${customViews?.length ?? 0} custom views přeneseno');
    } catch (e) {
      // Ignoruj chybu - možná žádné custom views neexistují nebo SharedPreferences není dostupný
      print('⚠️ Chyba při migraci agenda views (ignoruji): $e');
    }
  }

  // ==================== MIGRACE VERZE 12: EMOJI MÍSTO ICON_CODE_POINT ====================

  /// Migrovat icon_code_point INTEGER → emoji TEXT
  ///
  /// SQLite nepodporuje ALTER COLUMN, takže musíme:
  /// 1. Vytvořit novou tabulku s emoji sloupcem
  /// 2. Zkopírovat data s default emoji '⭐'
  /// 3. Dropnout starou tabulku
  /// 4. Přejmenovat novou tabulku
  /// 5. Znovu vytvořit indexy
  Future<void> _migrateIconCodePointToEmoji(Database db) async {
    try {
      // 1. Vytvořit temp tabulku s novým schématem
      await db.execute('''
        CREATE TABLE custom_agenda_views_new (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          tag_filter TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT '⭐',
          color_hex TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,

          CHECK (LENGTH(name) > 0),
          CHECK (LENGTH(tag_filter) > 0)
        )
      ''');

      // 2. Zkopírovat data (icon_code_point ignorujeme, použijeme default emoji)
      await db.execute('''
        INSERT INTO custom_agenda_views_new (id, name, tag_filter, emoji, color_hex, sort_order, enabled, created_at)
        SELECT id, name, tag_filter, '⭐', color_hex, sort_order, enabled, created_at
        FROM custom_agenda_views
      ''');

      // 3. Dropnout starou tabulku
      await db.execute('DROP TABLE custom_agenda_views');

      // 4. Přejmenovat novou tabulku
      await db.execute('ALTER TABLE custom_agenda_views_new RENAME TO custom_agenda_views');

      // 5. Znovu vytvořit indexy
      await db.execute('CREATE INDEX idx_custom_views_enabled ON custom_agenda_views(enabled)');
      await db.execute('CREATE INDEX idx_custom_views_sort ON custom_agenda_views(sort_order)');

      print('✅ Migrace icon_code_point → emoji dokončena');
    } catch (e) {
      print('❌ Chyba při migraci emoji: $e');
      rethrow;
    }
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

  // ==================== MIGRACE VERZE 13: POMODORO SESSIONS ====================

  /// Vytvořit tabulku pomodoro_sessions (verze 13)
  Future<void> _createPomodoroSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration INTEGER NOT NULL,
        actual_duration INTEGER,
        completed INTEGER NOT NULL DEFAULT 0,
        is_break INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(task_id) REFERENCES todos(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_pomodoro_task ON pomodoro_sessions(task_id)');
    await db.execute('CREATE INDEX idx_pomodoro_date ON pomodoro_sessions(started_at)');
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
}
