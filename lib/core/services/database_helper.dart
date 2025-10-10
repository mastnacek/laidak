import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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

    return await openDatabase(
      path,
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
        tags TEXT,
        ai_recommendations TEXT,
        ai_deadline_analysis TEXT
      )
    ''');

    // Tabulka AI nastavení + nastavení tagů + téma
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
        selected_theme TEXT NOT NULL DEFAULT 'doom_one'
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
}
