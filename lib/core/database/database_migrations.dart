import 'dart:convert'; // Pro jsonDecode při migraci z SharedPrefs
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_schema.dart';
import 'database_seed_data.dart';

/// Database migrations - veškerá logika upgradu databáze
///
/// Tento soubor obsahuje všechny migrace od verze 1 do aktuální verze.
/// Každá migrace je oddělena pro lepší přehlednost.
class DatabaseMigrations {
  /// Provést všechny migrace od oldVersion do newVersion
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _migrateToV2(db);
    if (oldVersion < 3) await _migrateToV3(db);
    if (oldVersion < 4) await _migrateToV4(db);
    if (oldVersion < 5) await _migrateToV5(db);
    if (oldVersion < 6) await _migrateToV6(db);
    if (oldVersion < 7) await _migrateToV7(db);
    if (oldVersion < 8) await _migrateToV8(db);
    if (oldVersion < 9) await _migrateToV9(db);
    if (oldVersion < 10) await _migrateToV10(db);
    if (oldVersion < 11) await _migrateToV11(db);
    if (oldVersion < 12) await _migrateToV12(db);
    if (oldVersion < 13) await _migrateToV13(db);
    if (oldVersion < 14) await _migrateToV14(db);
    if (oldVersion < 15) await _migrateToV15(db);
    if (oldVersion < 16) await _migrateToV16(db);
    if (oldVersion < 17) await _migrateToV17(db);
    if (oldVersion < 18) await _migrateToV18(db);
    if (oldVersion < 19) await _migrateToV19(db);
    if (oldVersion < 20) await _migrateToV20(db);
    if (oldVersion < 21) await _migrateToV21(db);
    if (oldVersion < 22) await _migrateToV22(db);
    if (oldVersion < 23) await _migrateToV23(db);
    if (oldVersion < 24) await _migrateToV24(db);
    if (oldVersion < 25) await _migrateToV25(db);
    if (oldVersion < 26) await _migrateToV26(db);
    if (oldVersion < 27) await _migrateToV27(db);
    if (oldVersion < 28) await _migrateToV28(db);
    if (oldVersion < 29) await _migrateToV29(db);
    if (oldVersion < 30) await _migrateToV30(db);
    if (oldVersion < 31) await _migrateToV31(db);
    if (oldVersion < 32) await _migrateToV32(db);
    if (oldVersion < 33) await _migrateToV33(db);
    if (oldVersion < 34) await _migrateToV34(db);
    if (oldVersion < 35) await _migrateToV35(db);
    if (oldVersion < 36) await _migrateToV36(db);
  }

  // ==================== MIGRACE V2: AI NASTAVENÍ ====================

  static Future<void> _migrateToV2(Database db) async {
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

    await DatabaseSeedData.insertDefaultSettings(db);
    await DatabaseSeedData.insertDefaultPrompts(db);
  }

  // ==================== MIGRACE V3: TAG DEFINITIONS ====================

  static Future<void> _migrateToV3(Database db) async {
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

    await DatabaseSeedData.insertDefaultTagDefinitions(db);
  }

  // ==================== MIGRACE V4: TAG DELIMITERS ====================

  static Future<void> _migrateToV4(Database db) async {
    // Přidat sloupce pro nastavení oddělovačů tagů
    await db.execute('''
      ALTER TABLE settings ADD COLUMN tag_delimiter_start TEXT NOT NULL DEFAULT '*'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN tag_delimiter_end TEXT NOT NULL DEFAULT '*'
    ''');
  }

  // ==================== MIGRACE V5: SELECTED THEME ====================

  static Future<void> _migrateToV5(Database db) async {
    // Přidat sloupec pro vybrané téma
    await db.execute('''
      ALTER TABLE settings ADD COLUMN selected_theme TEXT NOT NULL DEFAULT 'doom_one'
    ''');
  }

  // ==================== MIGRACE V6: GLOW EFEKT TAGŮ ====================

  static Future<void> _migrateToV6(Database db) async {
    // Přidat sloupce pro glow efekt tagů
    await db.execute('''
      ALTER TABLE tag_definitions ADD COLUMN glow_enabled INTEGER NOT NULL DEFAULT 0
    ''');

    await db.execute('''
      ALTER TABLE tag_definitions ADD COLUMN glow_strength REAL NOT NULL DEFAULT 0.5
    ''');
  }

  // ==================== MIGRACE V7: AI METADATA + SUBTASKS ====================

  static Future<void> _migrateToV7(Database db) async {
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
    await db.execute('CREATE INDEX idx_subtasks_completed ON subtasks(completed)');
  }

  // ==================== MIGRACE V8: PERFORMANCE INDEXY ====================

  static Future<void> _migrateToV8(Database db) async {
    // Přidat performance indexy pro rychlejší vyhledávání a sortování
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_task ON todos(task)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_tags ON todos(tags)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_dueDate ON todos(dueDate)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_isCompleted ON todos(isCompleted)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_todos_createdAt ON todos(createdAt)');
  }

  // ==================== MIGRACE V9: BEZPEČNÁ MIGRACE AI SLOUPCŮ ====================

  static Future<void> _migrateToV9(Database db) async {
    // Bezpečná migrace: Přidat AI sloupce pokud neexistují
    final columns = await db.rawQuery('PRAGMA table_info(todos)');
    final columnNames = columns.map((col) => col['name'] as String).toList();

    if (!columnNames.contains('ai_recommendations')) {
      await db.execute('ALTER TABLE todos ADD COLUMN ai_recommendations TEXT');
    }

    if (!columnNames.contains('ai_deadline_analysis')) {
      await db.execute('ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT');
    }
  }

  // ==================== MIGRACE V10: GESTURE HINT TRACKING ====================

  static Future<void> _migrateToV10(Database db) async {
    await db.execute('''
      ALTER TABLE settings ADD COLUMN has_seen_gesture_hint INTEGER NOT NULL DEFAULT 0
    ''');
  }

  // ==================== MIGRACE V11: TAGS NORMALIZATION + CUSTOM VIEWS ====================

  static Future<void> _migrateToV11(Database db) async {
    // MILESTONE 1: Tags normalization
    await _createTagsTables(db);
    await _migrateTagsToNormalizedSchema(db);

    // MILESTONE 2: Custom Agenda Views to DB
    await _createCustomAgendaViewsTable(db);
    await _addBuiltInViewSettingsColumns(db);
    await _migrateAgendaViewsToDb(db);
  }

  // ==================== MIGRACE V12: EMOJI MÍSTO ICON_CODE_POINT ====================

  static Future<void> _migrateToV12(Database db) async {
    await _migrateIconCodePointToEmoji(db);
  }

  // ==================== MIGRACE V13: POMODORO SESSIONS ====================

  static Future<void> _migrateToV13(Database db) async {
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

  // ==================== MIGRACE V14: AI SETTINGS (MOTIVATION + TASK MODELS) ====================

  static Future<void> _migrateToV14(Database db) async {
    await db.execute('ALTER TABLE settings ADD COLUMN openrouter_api_key TEXT');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_model TEXT NOT NULL DEFAULT \'mistralai/mistral-medium-3.1\'');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_temperature REAL NOT NULL DEFAULT 0.9');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_motivation_max_tokens INTEGER NOT NULL DEFAULT 200');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_task_model TEXT NOT NULL DEFAULT \'anthropic/claude-3.5-sonnet\'');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_task_temperature REAL NOT NULL DEFAULT 0.3');
    await db.execute('ALTER TABLE settings ADD COLUMN ai_task_max_tokens INTEGER NOT NULL DEFAULT 1000');
  }

  // ==================== MIGRACE V15: BRIEF SETTINGS ====================

  static Future<void> _migrateToV15(Database db) async {
    await db.execute('ALTER TABLE settings ADD COLUMN brief_include_subtasks INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN brief_include_pomodoro INTEGER NOT NULL DEFAULT 1');
  }

  // ==================== MIGRACE V16: COMPLETED_AT TIMESTAMP ====================

  static Future<void> _migrateToV16(Database db) async {
    await db.execute('ALTER TABLE todos ADD COLUMN completed_at TEXT');
  }

  // ==================== MIGRACE V17: BRIEF COMPLETED TASKS TIMEFRAMES ====================

  static Future<void> _migrateToV17(Database db) async {
    await db.execute('ALTER TABLE settings ADD COLUMN brief_completed_today INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN brief_completed_week INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN brief_completed_month INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE settings ADD COLUMN brief_completed_year INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE settings ADD COLUMN brief_completed_all INTEGER NOT NULL DEFAULT 0');
  }

  // ==================== MIGRACE V18: NOTES TABULKA ====================

  static Future<void> _migrateToV18(Database db) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_notes_created_at ON notes(created_at DESC)');
    await db.execute('CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC)');
  }

  // ==================== MIGRACE V19: NOTE TAGS ====================

  static Future<void> _migrateToV19(Database db) async {
    await db.execute('''
      CREATE TABLE note_tags (
        note_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (note_id, tag),
        FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_note_tags_note_id ON note_tags(note_id)');
    await db.execute('CREATE INDEX idx_note_tags_tag ON note_tags(tag)');
  }

  // ==================== MIGRACE V20: SMART FOLDERS PRO NOTES ====================

  static Future<void> _migrateToV20(Database db) async {
    await db.execute('''
      CREATE TABLE note_smart_folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        filter_rules TEXT NOT NULL,
        display_order INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_smart_folders_display_order ON note_smart_folders(display_order)');
    await db.execute('CREATE INDEX idx_smart_folders_system ON note_smart_folders(is_system)');
  }

  // ==================== MIGRACE V21: CUSTOM NOTES VIEWS ====================

  static Future<void> _migrateToV21(Database db) async {
    // 1. Drop stará tabulka note_smart_folders
    await db.execute('DROP TABLE IF EXISTS note_smart_folders');

    // 2. Vytvořit novou tabulku custom_notes_views
    await db.execute('''
      CREATE TABLE custom_notes_views (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tag_filter TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '📁',
        sort_order INTEGER NOT NULL DEFAULT 0,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,

        CHECK (LENGTH(name) > 0),
        CHECK (LENGTH(tag_filter) > 0)
      )
    ''');

    await db.execute('CREATE INDEX idx_custom_notes_views_enabled ON custom_notes_views(enabled)');
    await db.execute('CREATE INDEX idx_custom_notes_views_sort ON custom_notes_views(sort_order)');

    // 3. Přidat built-in toggles do settings
    await db.execute('ALTER TABLE settings ADD COLUMN show_all_notes INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_recent_notes INTEGER NOT NULL DEFAULT 1');
  }

  // ==================== MIGRACE V22: FTS5 FULL-TEXT SEARCH ====================

  static Future<void> _migrateToV22(Database db) async {
    try {
      // 1. Vytvořit FTS5 virtual tables
      await DatabaseSchema.createFTS5Tables(db);

      // 2. Vytvořit triggers pro automatickou synchronizaci
      await DatabaseSchema.createFTS5Triggers(db);

      print('✅ FTS5 Full-Text Search je dostupné');
    } catch (e) {
      // FTS5 není dostupné (Android nativní SQLite)
      print('⚠️ FTS5 není dostupné, fallback na Dart-side filtering: $e');
    }
  }

  // ==================== MIGRACE V23: RECURRENCE SYSTEM ====================

  static Future<void> _migrateToV23(Database db) async {
    await db.execute('''
      CREATE TABLE recurrence_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL UNIQUE,
        recur_type TEXT NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        day_of_week INTEGER,
        day_of_month INTEGER,
        end_date TEXT,
        max_occurrences INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        CHECK (recur_type IN ('daily', 'weekly', 'monthly', 'yearly'))
      )
    ''');

    await db.execute('CREATE INDEX idx_recurrence_rules_todo_id ON recurrence_rules(todo_id)');

    await db.execute('''
      CREATE TABLE recurrence_occurrences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recurrence_id INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        skipped INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(recurrence_id) REFERENCES recurrence_rules(id) ON DELETE CASCADE,
        UNIQUE(recurrence_id, due_date)
      )
    ''');

    await db.execute('CREATE INDEX idx_occurrences_recurrence_id ON recurrence_occurrences(recurrence_id)');
    await db.execute('CREATE INDEX idx_occurrences_due_date ON recurrence_occurrences(due_date)');
    await db.execute('CREATE INDEX idx_occurrences_completed ON recurrence_occurrences(completed)');
  }

  // ==================== MIGRACE V24: TODOIST MODEL - ZJEDNODUŠENÍ RECURRING TASKS ====================

  static Future<void> _migrateToV24(Database db) async {
    // 1. DROP occurrences table
    await db.execute('DROP TABLE IF EXISTS recurrence_occurrences');

    // 2. Recreate recurrence_rules bez endDate/maxOccurrences
    await db.execute('''
      CREATE TABLE recurrence_rules_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL UNIQUE,
        recur_type TEXT NOT NULL,
        interval INTEGER NOT NULL DEFAULT 1,
        day_of_week INTEGER,
        day_of_month INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        CHECK (recur_type IN ('daily', 'weekly', 'monthly', 'yearly'))
      )
    ''');

    // 3. Migrate data (bez end_date a max_occurrences)
    await db.execute('''
      INSERT INTO recurrence_rules_new
        (id, todo_id, recur_type, interval, day_of_week, day_of_month, created_at)
      SELECT id, todo_id, recur_type, interval, day_of_week, day_of_month, created_at
      FROM recurrence_rules
    ''');

    // 4. Replace table
    await db.execute('DROP TABLE recurrence_rules');
    await db.execute('ALTER TABLE recurrence_rules_new RENAME TO recurrence_rules');
    await db.execute('CREATE INDEX idx_recurrence_rules_todo_id ON recurrence_rules(todo_id)');
  }

  // ==================== MIGRACE V25: AI MOTIVATION CACHE ====================

  static Future<void> _migrateToV25(Database db) async {
    // Přidat sloupce pro cache AI motivace přímo do todos tabulky
    await db.execute('''
      ALTER TABLE todos ADD COLUMN ai_motivation TEXT
    ''');

    await db.execute('''
      ALTER TABLE todos ADD COLUMN ai_motivation_generated_at INTEGER
    ''');
  }

  // ==================== MIGRACE V26: PROFILE FEATURE ====================

  static Future<void> _migrateToV26(Database db) async {
    // Tabulka profilu uživatele (dítě)
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        name_day TEXT,
        hobbies TEXT,
        about_me TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_user_profile_user_id ON user_profile(user_id)');

    // Tabulka členů rodiny
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        name_day TEXT,
        role TEXT NOT NULL,
        relationship_description TEXT,
        personality_traits TEXT,
        hobbies TEXT,
        occupation TEXT,
        other_notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK (role IN ('mother', 'father', 'brother', 'sister', 'grandmother', 'grandfather', 'other'))
      )
    ''');

    await db.execute('CREATE INDEX idx_family_members_user_id ON family_members(user_id)');
    await db.execute('CREATE INDEX idx_family_members_role ON family_members(role)');
  }

  // ==================== MIGRACE V27: GENDER POLE ====================

  static Future<void> _migrateToV27(Database db) async {
    // Přidat gender sloupec do user_profile
    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN gender TEXT NOT NULL DEFAULT 'other'
    ''');

    // Přidat gender sloupec do family_members
    await db.execute('''
      ALTER TABLE family_members ADD COLUMN gender TEXT NOT NULL DEFAULT 'other'
    ''');

    // Check constraint pro gender hodnoty přidáme při příštím recreate tabulky
    // SQLite nepodporuje ADD CONSTRAINT, takže validace bude v aplikační vrstvě
  }

  // ==================== MIGRACE V28: SILNÉ A SLABÉ STRÁNKY ====================

  static Future<void> _migrateToV28(Database db) async {
    // Přidat silne_stranky a slabe_stranky do user_profile
    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN silne_stranky TEXT
    ''');

    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN slabe_stranky TEXT
    ''');

    // Přidat silne_stranky a slabe_stranky do family_members
    await db.execute('''
      ALTER TABLE family_members ADD COLUMN silne_stranky TEXT
    ''');

    await db.execute('''
      ALTER TABLE family_members ADD COLUMN slabe_stranky TEXT
    ''');
  }

  // ==================== MIGRACE V29: PŘEZDÍVKA (NICKNAME) ====================

  static Future<void> _migrateToV29(Database db) async {
    // Přidat nickname do user_profile
    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN nickname TEXT
    ''');

    // Přidat nickname do family_members
    await db.execute('''
      ALTER TABLE family_members ADD COLUMN nickname TEXT
    ''');
  }

  // ==================== MIGRACE V30: VĚKOVÁ KATEGORIE ====================

  static Future<void> _migrateToV30(Database db) async {
    // Přidat age_category do user_profile
    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN age_category TEXT
    ''');

    // Přidat age_category do family_members
    await db.execute('''
      ALTER TABLE family_members ADD COLUMN age_category TEXT
    ''');
  }

  // ==================== MIGRACE V31: ROZŠÍŘENÍ CHECK CONSTRAINT PRO FAMILY ROLES ====================

  static Future<void> _migrateToV31(Database db) async {
    // SQLite nepodporuje ALTER TABLE DROP/ADD CONSTRAINT
    // Musíme recreate tabulku s novým CHECK constraintem

    // 1. Vytvořit novou tabulku s rozšířeným CHECK constraintem
    await db.execute('''
      CREATE TABLE family_members_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        name_day TEXT,
        nickname TEXT,
        gender TEXT NOT NULL DEFAULT 'other',
        role TEXT NOT NULL,
        relationship_description TEXT,
        personality_traits TEXT,
        hobbies TEXT,
        occupation TEXT,
        other_notes TEXT,
        silne_stranky TEXT,
        slabe_stranky TEXT,
        age_category TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK (role IN ('mother', 'father', 'brother', 'sister', 'grandmother', 'grandfather', 'aunt', 'uncle', 'cousin', 'niece', 'nephew', 'stepmother', 'stepfather', 'stepbrother', 'stepsister', 'greatGrandmother', 'greatGrandfather', 'partner', 'other'))
      )
    ''');

    // 2. Zkopírovat data ze staré tabulky do nové
    await db.execute('''
      INSERT INTO family_members_new
        (id, user_id, first_name, last_name, birth_date, name_day, nickname, gender, role, relationship_description, personality_traits, hobbies, occupation, other_notes, silne_stranky, slabe_stranky, age_category, created_at, updated_at)
      SELECT id, user_id, first_name, last_name, birth_date, name_day, nickname, gender, role, relationship_description, personality_traits, hobbies, occupation, other_notes, silne_stranky, slabe_stranky, age_category, created_at, updated_at
      FROM family_members
    ''');

    // 3. Drop starou tabulku
    await db.execute('DROP TABLE family_members');

    // 4. Přejmenovat novou tabulku
    await db.execute('ALTER TABLE family_members_new RENAME TO family_members');

    // 5. Znovu vytvořit indexy
    await db.execute('CREATE INDEX idx_family_members_user_id ON family_members(user_id)');
    await db.execute('CREATE INDEX idx_family_members_role ON family_members(role)');

    print('✅ Migrace V31: Rozšíření CHECK constraint pro family_members.role dokončena');
  }

  // ==================== MIGRACE V32: COMPLETED TASKS COUNT PRO STŘÍDÁNÍ PRANK/GOOD DEED ====================

  static Future<void> _migrateToV32(Database db) async {
    // Přidat completed_tasks_count do user_profile pro střídání prank/good deed
    await db.execute('''
      ALTER TABLE user_profile ADD COLUMN completed_tasks_count INTEGER NOT NULL DEFAULT 0
    ''');

    print('✅ Migrace V32: Přidán completed_tasks_count do user_profile');
  }

  // ==================== MIGRACE V33: AI PRANK SETTINGS ====================

  static Future<void> _migrateToV33(Database db) async {
    // Přidat ai_prank_model a ai_prank_max_tokens do settings
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_prank_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-sonnet'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_prank_max_tokens INTEGER NOT NULL DEFAULT 1000
    ''');

    print('✅ Migrace V33: Přidány ai_prank_model a ai_prank_max_tokens settings');
  }

  // ==================== MIGRACE V34: PŘEJMENOVÁNÍ AI_PRANK → AI_REWARD ====================

  static Future<void> _migrateToV34(Database db) async {
    // SQLite nepodporuje ALTER TABLE RENAME COLUMN přímo
    // Musíme použít workaround: načíst data, přidat nové sloupce, zkopírovat data, smazat staré

    // 1. Přidat nové sloupce ai_reward_*
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_reward_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-sonnet'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_reward_temperature REAL NOT NULL DEFAULT 0.9
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_reward_max_tokens INTEGER NOT NULL DEFAULT 1000
    ''');

    // 2. Zkopírovat data z ai_prank_* do ai_reward_*
    await db.execute('''
      UPDATE settings
      SET ai_reward_model = ai_prank_model,
          ai_reward_max_tokens = ai_prank_max_tokens
      WHERE id = 1
    ''');

    // 3. Smazat staré sloupce (SQLite neumožní direct DROP COLUMN, ale můžeme je nechat deprecated)
    // POZNÁMKA: Necháme staré sloupce pro backward compatibility
    // V budoucí major verzi je můžeme smazat pomocí ALTER TABLE recreation

    print('✅ Migrace V34: Přejmenováno ai_prank_* → ai_reward_* (zachována backward compatibility)');
  }

  // ==================== MIGRACE V35: AI TAG SUGGESTIONS SETTINGS ====================

  static Future<void> _migrateToV35(Database db) async {
    // Přidat nové sloupce pro AI Tag Suggestions nastavení

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-haiku'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_temperature REAL NOT NULL DEFAULT 1.0
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_max_tokens INTEGER NOT NULL DEFAULT 500
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_seed INTEGER
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_top_p REAL
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_debounce_ms INTEGER NOT NULL DEFAULT 1000
    ''');

    print('✅ Migrace V35: Přidány AI Tag Suggestions settings (model, temperature, max_tokens, seed, top_p, debounce_ms)');
  }

  // ==================== MIGRACE V36: OPENROUTER PROVIDER ROUTE + CACHE ====================

  static Future<void> _migrateToV36(Database db) async {
    // Přidat nové sloupce pro OpenRouter provider routing a caching

    // MOTIVATION model settings
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_motivation_provider_route TEXT NOT NULL DEFAULT 'default'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_motivation_enable_cache INTEGER NOT NULL DEFAULT 1
    ''');

    // TASK model settings
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_task_provider_route TEXT NOT NULL DEFAULT 'floor'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_task_enable_cache INTEGER NOT NULL DEFAULT 1
    ''');

    // REWARD model settings
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_reward_provider_route TEXT NOT NULL DEFAULT 'default'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_reward_enable_cache INTEGER NOT NULL DEFAULT 1
    ''');

    // TAG SUGGESTIONS model settings
    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_provider_route TEXT NOT NULL DEFAULT 'floor'
    ''');

    await db.execute('''
      ALTER TABLE settings ADD COLUMN ai_tag_suggestions_enable_cache INTEGER NOT NULL DEFAULT 1
    ''');

    print('✅ Migrace V36: Přidány OpenRouter provider route a cache settings (8 nových sloupců)');
  }

  // ==================== POMOCNÉ FUNKCE PRO MIGRACE ====================

  /// Vytvořit tabulky pro normalizované tagy (verze 11)
  static Future<void> _createTagsTables(Database db) async {
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
  static Future<void> _migrateTagsToNormalizedSchema(Database db) async {
    try {
      final todos = await db.query('todos');

      for (final todo in todos) {
        final todoId = todo['id'] as int;
        final tagsCSV = todo['tags'] as String?;

        if (tagsCSV == null || tagsCSV.isEmpty) continue;

        final tagsList = tagsCSV
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty);

        for (final tagName in tagsList) {
          final normalized = tagName.toLowerCase();
          final tagId = await _getOrCreateTag(db, normalized, tagName);

          await db.insert(
            'todo_tags',
            {'todo_id': todoId, 'tag_id': tagId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          await db.rawUpdate(
            'UPDATE tags SET usage_count = usage_count + 1, last_used = ? WHERE id = ?',
            [DateTime.now().millisecondsSinceEpoch, tagId],
          );
        }
      }

      await db.rawUpdate("UPDATE todos SET tags = ''");
    } catch (e) {
      print('❌ Chyba při migraci tagů: $e');
      rethrow;
    }
  }

  /// Get nebo create tag (helper pro migraci)
  static Future<int> _getOrCreateTag(
    Database db,
    String normalized,
    String original,
  ) async {
    final existing = await db.query(
      'tags',
      where: 'tag_name = ?',
      whereArgs: [normalized],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('tags', {
      'tag_name': normalized,
      'display_name': original,
      'tag_type': 'custom',
      'usage_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Vytvořit tabulku custom_agenda_views
  static Future<void> _createCustomAgendaViewsTable(Database db) async {
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
  static Future<void> _addBuiltInViewSettingsColumns(Database db) async {
    await db.execute('ALTER TABLE settings ADD COLUMN show_all INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_today INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_week INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE settings ADD COLUMN show_upcoming INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE settings ADD COLUMN show_overdue INTEGER NOT NULL DEFAULT 1');
  }

  /// Migrovat custom agenda views z SharedPreferences → DB
  static Future<void> _migrateAgendaViewsToDb(Database db) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('agenda_config');

      if (jsonString == null || jsonString.isEmpty) {
        print('ℹ️ Custom Agenda Views migrace: Žádná data v SharedPrefs (fresh install)');
        return;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // 1. Migrovat built-in views
      await db.update('settings', {
        'show_all': json['showAll'] == true ? 1 : 0,
        'show_today': json['showToday'] == true ? 1 : 0,
        'show_week': json['showWeek'] == true ? 1 : 0,
        'show_upcoming': json['showUpcoming'] == true ? 1 : 0,
        'show_overdue': json['showOverdue'] == true ? 1 : 0,
      }, where: 'id = 1');

      // 2. Migrovat custom views
      final customViews = json['customViews'] as List<dynamic>?;
      if (customViews != null && customViews.isNotEmpty) {
        for (var i = 0; i < customViews.length; i++) {
          final view = customViews[i] as Map<String, dynamic>;

          await db.insert('custom_agenda_views', {
            'id': view['id'] as String,
            'name': view['name'] as String,
            'tag_filter': (view['tagFilter'] as String).toLowerCase(),
            'emoji': '⭐',
            'color_hex': view['colorHex'] as String?,
            'sort_order': i,
            'enabled': 1,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      await prefs.remove('agenda_config');
      print('✅ Migrace agenda views dokončena: ${customViews?.length ?? 0} custom views přeneseno');
    } catch (e) {
      print('⚠️ Chyba při migraci agenda views (ignoruji): $e');
    }
  }

  /// Migrovat icon_code_point → emoji
  static Future<void> _migrateIconCodePointToEmoji(Database db) async {
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

      // 2. Zkopírovat data
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
}
