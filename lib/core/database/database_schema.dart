import 'package:sqflite/sqflite.dart';

/// Database schema - všechny CREATE TABLE statements
///
/// Tento soubor obsahuje definice všech tabulek v databázi.
/// Oddělený od DatabaseHelper pro lepší přehlednost a údržbu.
class DatabaseSchema {
  /// Vytvořit všechny tabulky při první inicializaci databáze
  static Future<void> createTables(Database db) async {
    // Tabulka úkolů (s AI metadata sloupci)
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completed_at TEXT,
        priority TEXT,
        dueDate TEXT,
        tags TEXT,  -- ❌ DEPRECATED: Používej todo_tags tabulku!
        ai_recommendations TEXT,
        ai_deadline_analysis TEXT,
        ai_motivation TEXT,
        ai_motivation_generated_at INTEGER
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
        ai_task_max_tokens INTEGER NOT NULL DEFAULT 1000,
        ai_reward_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-sonnet',
        ai_reward_temperature REAL NOT NULL DEFAULT 0.9,
        ai_reward_max_tokens INTEGER NOT NULL DEFAULT 1000,
        ai_tag_suggestions_model TEXT NOT NULL DEFAULT 'anthropic/claude-3.5-haiku',
        ai_tag_suggestions_temperature REAL NOT NULL DEFAULT 1.0,
        ai_tag_suggestions_max_tokens INTEGER NOT NULL DEFAULT 500,
        ai_tag_suggestions_seed INTEGER,
        ai_tag_suggestions_top_p REAL,
        ai_tag_suggestions_debounce_ms INTEGER NOT NULL DEFAULT 500,
        ai_motivation_provider_route TEXT NOT NULL DEFAULT 'default',
        ai_motivation_enable_cache INTEGER NOT NULL DEFAULT 1,
        ai_task_provider_route TEXT NOT NULL DEFAULT 'floor',
        ai_task_enable_cache INTEGER NOT NULL DEFAULT 1,
        ai_reward_provider_route TEXT NOT NULL DEFAULT 'default',
        ai_reward_enable_cache INTEGER NOT NULL DEFAULT 1,
        ai_tag_suggestions_provider_route TEXT NOT NULL DEFAULT 'floor',
        ai_tag_suggestions_enable_cache INTEGER NOT NULL DEFAULT 1,
        brief_include_subtasks INTEGER NOT NULL DEFAULT 1,
        brief_include_pomodoro INTEGER NOT NULL DEFAULT 1,
        brief_completed_today INTEGER NOT NULL DEFAULT 1,
        brief_completed_week INTEGER NOT NULL DEFAULT 1,
        brief_completed_month INTEGER NOT NULL DEFAULT 0,
        brief_completed_year INTEGER NOT NULL DEFAULT 0,
        brief_completed_all INTEGER NOT NULL DEFAULT 0,
        show_all_notes INTEGER NOT NULL DEFAULT 1,
        show_recent_notes INTEGER NOT NULL DEFAULT 1
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

    // Tabulka poznámek (Notes + PARA System - MILESTONE 1)
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

    // Tabulka recurrence_rules - pravidla pro opakující se úkoly (verze 24 - Todoist model)
    await db.execute('''
      CREATE TABLE recurrence_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todo_id INTEGER NOT NULL UNIQUE,
        recur_type TEXT NOT NULL,        -- 'daily', 'weekly', 'monthly', 'yearly'
        interval INTEGER NOT NULL DEFAULT 1,
        day_of_week INTEGER,              -- 0-6 (Monday-Sunday)
        day_of_month INTEGER,             -- 1-31
        created_at INTEGER NOT NULL,
        FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
        CHECK (recur_type IN ('daily', 'weekly', 'monthly', 'yearly'))
      )
    ''');

    await db.execute('CREATE INDEX idx_recurrence_rules_todo_id ON recurrence_rules(todo_id)');

    // Tabulka note_tags - M:N vztah mezi poznámkami a tagy (MILESTONE 3)
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

    // Tabulka Custom Notes Views (identický princip jako Agenda Views)
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

    // Tabulka profilu uživatele (dítě)
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL DEFAULT 'default',
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        birth_date INTEGER NOT NULL,
        name_day TEXT,
        nickname TEXT,
        hobbies TEXT,
        about_me TEXT NOT NULL DEFAULT '',
        silne_stranky TEXT,
        slabe_stranky TEXT,
        age_category TEXT,
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

    await db.execute('CREATE INDEX idx_family_members_user_id ON family_members(user_id)');
    await db.execute('CREATE INDEX idx_family_members_role ON family_members(role)');
  }

  /// Vytvořit FTS5 virtual tables pro full-text search
  ///
  /// FTS5 je SQLite full-text search engine s podporou:
  /// - Keyword search s ranking (BM25)
  /// - Prefix queries ("prog*")
  /// - Phrase queries ("\"dokončit prezentaci\"")
  /// - Boolean operators (AND, OR, NOT)
  /// - Czech diacritics support (díky unicode61 tokenizer)
  static Future<void> createFTS5Tables(Database db) async {
    // FTS5 virtual table pro TODOs
    await db.execute('''
      CREATE VIRTUAL TABLE todos_fts USING fts5(
        task,
        tags,
        content=todos,
        content_rowid=id,
        tokenize='unicode61 remove_diacritics 0'
      )
    ''');

    // FTS5 virtual table pro Notes
    await db.execute('''
      CREATE VIRTUAL TABLE notes_fts USING fts5(
        content,
        content=notes,
        content_rowid=id,
        tokenize='unicode61 remove_diacritics 0'
      )
    ''');
  }

  /// Vytvořit triggers pro automatické update FTS5 indexů
  ///
  /// FTS5 external content tables vyžadují triggers pro sync:
  /// - INSERT → přidat do FTS5
  /// - UPDATE → update FTS5
  /// - DELETE → smazat z FTS5
  static Future<void> createFTS5Triggers(Database db) async {
    // ==================== TODOS FTS5 TRIGGERS ====================

    await db.execute('''
      CREATE TRIGGER todos_fts_insert AFTER INSERT ON todos BEGIN
        INSERT INTO todos_fts(rowid, task, tags)
        VALUES (new.id, new.task, new.tags);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER todos_fts_update AFTER UPDATE ON todos BEGIN
        UPDATE todos_fts
        SET task = new.task, tags = new.tags
        WHERE rowid = old.id;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER todos_fts_delete AFTER DELETE ON todos BEGIN
        DELETE FROM todos_fts WHERE rowid = old.id;
      END
    ''');

    // ==================== NOTES FTS5 TRIGGERS ====================

    await db.execute('''
      CREATE TRIGGER notes_fts_insert AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, content)
        VALUES (new.id, new.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER notes_fts_update AFTER UPDATE ON notes BEGIN
        UPDATE notes_fts
        SET content = new.content
        WHERE rowid = old.id;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER notes_fts_delete AFTER DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE rowid = old.id;
      END
    ''');
  }
}
