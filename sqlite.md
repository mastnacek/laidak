 🔥 ULTRATHINK: BRUTÁLNÍ DATABASE AUDIT

  📊 SOUČASNÝ STAV - CO JSEM NAŠEL

  ✅ SQLite Databáze (database_helper.dart)

  5 tabulek:

  1. todos - TODO úkoly
    - ✅ Dobré: AI metadata sloupce, indexy na search/sort
    - ❌ KRITICKÝ PROBLÉM: tags TEXT - CSV string místo normalizace!
    - Formát: 'projekt,prace,urgent' (comma-separated)
  2. settings - Aplikační nastavení
    - ✅ Dobré: Singleton pattern (id = 1)
    - ⚠️ Mix: Theme v DB, ale Agenda Config v SharedPrefs (inconsistence!)
  3. custom_prompts - Motivační prompty
    - ✅ Dobré: Správně v DB, UNIQUE constraint na category
  4. tag_definitions - Definice systémových tagů
    - ✅ Dobré: Priority/Date/Status tagy s metadata
    - ❌ CHYBÍ: Custom tagy (projekt, nakup, sport...) NEJSOU zde!
  5. subtasks - Podúkoly pro AI split
    - ✅ Dobré: CASCADE delete, indexy, správná normalizace

  🗂️ SharedPreferences

  1 klíč:
  - agenda_config - Custom Agenda Views (JSON string)
  - ⚠️ ŠPATNÉ MÍSTO! - Mělo by být v DB

  ---
  🚨 KRITICKÉ PROBLÉMY

  1️⃣ Tags jako CSV - NEJVĚTŠÍ PROBLÉM!

  // todo_item.dart řádek 39
  'tags': tags.join(',')  // ❌ Denormalizace!

  // Když uložíš: ['projekt', 'prace', 'urgent']
  // V DB bude: "projekt,prace,urgent"  (TEXT sloupec)

  Problémy:
  - ❌ Nelze efektivně vyhledávat - WHERE tags LIKE '%projekt%' je POMALÉ
  - ❌ Nelze počítat usage - kolikrát je tag "projekt" použit?
  - ❌ Nelze autocomplete - žádný seznam všech existujících tagů
  - ❌ Nelze normalizovat - "Projekt", "projekt", "PROJEKT" = 3 různé tagy
  - ❌ Nelze smazat tag - musíš updatovat všechny CSV stringy
  - ❌ Chybí referential integrity - můžeš mít mrtvé tagy

  Index na tags sloupec (řádek 115) je téměř ZBYTEČNÝ!
  CREATE INDEX idx_todos_tags ON todos(tags)
  - Index na TEXT sloupec s CSV je neefektivní
  - Pomáhá pouze pro WHERE tags = 'exact,match' (NIKDY se nestane!)
  - Pro LIKE '%projekt%' musí skenovat celou tabulku

  ---
  2️⃣ Custom Tags NEJSOU persistovány

  Co mám:
  - tag_definitions - pouze systémové tagy (a, b, c, dnes, zitra...)
  - todos.tags - CSV string custom tagů (projekt, nakup, sport...)

  Co CHYBÍ:
  - ❌ Žádná tabulka pro custom tagy
  - ❌ Žádný autocomplete pro existující tagy
  - ❌ Žádné statistiky (kolikrát použit, kdy naposledy)
  - ❌ Žádná normalizace (malá/velká písmena)

  Představ si:
  User napíše: "Koupit mleko *nakup* *urgent*"
  - Tags: ['nakup', 'urgent']
  - Uloženo v DB: "nakup,urgent" (TEXT)

  Příště píše: "Koupit chleba *Nakup*"
  - Tags: ['Nakup']  (jiný case!)
  - Autocomplete? ❌ NENÍ! User musí vzpomínat
  - Statistics? ❌ NENÍ! Nevíš že "nakup" už použil 5x

  ---
  3️⃣ Custom Agenda Views v SharedPreferences

  // settings_cubit.dart řádek 236-252
  Future<AgendaViewConfig> _loadAgendaConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('agenda_config');
    // ...
  }

  Proč je to ŠPATNĚ?
  - ❌ Inconsistence - settings v DB, ale agenda_config v SharedPrefs
  - ❌ Nelze queryovat - nemůžeš udělat SELECT * FROM custom_views WHERE tag = 'projekt'
  - ❌ Nelze migrovat - když přidáš nový field, musíš handleovat JSON parsing errors
  - ❌ Složitější testing - mock SharedPreferences vs. mock Database
  - ❌ Chybí constraints - můžeš mít duplicitní tag_filter, prázdné name...

  Mělo by být:
  CREATE TABLE custom_agenda_views (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    tag_filter TEXT NOT NULL,
    icon_code_point INTEGER NOT NULL,
    color_hex TEXT,
    sort_order INTEGER DEFAULT 0,
    enabled INTEGER DEFAULT 1
  )

  ---
  4️⃣ Nastavení roztříštěná mezi DB a SharedPrefs

  | Nastavení             | Uloženo v         | Správné? |
  |-----------------------|-------------------|----------|
  | selected_theme        | SQLite settings   | ✅ ANO    |
  | api_key               | SQLite settings   | ✅ ANO    |
  | tag_delimiter_start   | SQLite settings   | ✅ ANO    |
  | has_seen_gesture_hint | SQLite settings   | ✅ ANO    |
  | agenda_config         | SharedPreferences | ❌ NE!    |

  Proč je to problém?
  - 🤔 Konzistence: Jeden zdroj pravdy, nebo dva?
  - 🤔 Migrace: DB má onUpgrade, SharedPrefs nemá
  - 🤔 Testování: Mock 2 různé systémy
  - 🤔 Backup: Export DB nestačí, musíš i SharedPrefs

  ---
  💡 DOPORUČENÉ ŘEŠENÍ

  🎯 FÁZE 1: Normalizace Tags (HIGHEST PRIORITY)

  Krok 1: Vytvoř tabulku tags

  CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tag_name TEXT UNIQUE NOT NULL,      -- lowercase normalized ('projekt')
    display_name TEXT,                  -- original case ('Projekt')
    tag_type TEXT NOT NULL DEFAULT 'custom',  -- 'custom', 'priority', 'date', 'status'
    usage_count INTEGER NOT NULL DEFAULT 0,
    last_used INTEGER,                  -- Unix timestamp
    created_at INTEGER NOT NULL,        -- Unix timestamp

    CHECK (tag_name = LOWER(tag_name))  -- Force lowercase
  );

  CREATE INDEX idx_tags_type ON tags(tag_type);
  CREATE INDEX idx_tags_usage ON tags(usage_count DESC);

  Krok 2: Vytvoř many-to-many tabulku todo_tags

  CREATE TABLE todo_tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    todo_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,

    FOREIGN KEY(todo_id) REFERENCES todos(id) ON DELETE CASCADE,
    FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE,

    UNIQUE(todo_id, tag_id)  -- Jeden tag jednou per TODO
  );

  CREATE INDEX idx_todo_tags_todo_id ON todo_tags(todo_id);
  CREATE INDEX idx_todo_tags_tag_id ON todo_tags(tag_id);

  Krok 3: Migrace dat z CSV → normalizované tagy

  Future<void> _migrateTagsToNormalizedSchema(Database db) async {
    // 1. Načíst všechny todos s CSV tags
    final todos = await db.query('todos');

    for (final todo in todos) {
      final todoId = todo['id'] as int;
      final tagsCSV = todo['tags'] as String?;

      if (tagsCSV == null || tagsCSV.isEmpty) continue;

      final tagsList = tagsCSV.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);

      for (final tagName in tagsList) {
        // 2. Normalize tag name (lowercase)
        final normalized = tagName.toLowerCase();

        // 3. Insert nebo get existing tag
        var tagId = await _getOrCreateTag(db, normalized, tagName);

        // 4. Vytvořit vazbu todo_tags
        await db.insert('todo_tags', {
          'todo_id': todoId,
          'tag_id': tagId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // 5. Inkrementovat usage_count
        await db.rawUpdate(
          'UPDATE tags SET usage_count = usage_count + 1, last_used = ? WHERE id = ?',
          [DateTime.now().millisecondsSinceEpoch, tagId],
        );
      }
    }

    // 6. ODSTRANIT CSV sloupec (deprecated)
    // ⚠️ SQLite nepodporuje DROP COLUMN přímo, musíš recreate tabulku
    // nebo nechat sloupec prázdný a označit jako deprecated
  }

  Future<int> _getOrCreateTag(Database db, String normalized, String original) async {
    final existing = await db.query('tags', where: 'tag_name = ?', whereArgs: [normalized]);

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

  Krok 4: Autocomplete query

  /// Získat nejpoužívanější custom tagy pro autocomplete
  Future<List<String>> getTopCustomTags({int limit = 10}) async {
    final db = await database;

    final results = await db.query(
      'tags',
      where: 'tag_type = ?',
      whereArgs: ['custom'],
      orderBy: 'usage_count DESC, last_used DESC',
      limit: limit,
    );

    return results.map((row) => row['display_name'] as String).toList();
  }

  /// Search tags (autocomplete během psaní)
  Future<List<String>> searchTags(String query, {int limit = 5}) async {
    final db = await database;

    final results = await db.query(
      'tags',
      where: 'tag_name LIKE ? AND tag_type = ?',
      whereArgs: ['%${query.toLowerCase()}%', 'custom'],
      orderBy: 'usage_count DESC',
      limit: limit,
    );

    return results.map((row) => row['display_name'] as String).toList();
  }

  ---
  🎯 FÁZE 2: Přesunout Custom Agenda Views do DB

  Krok 1: Vytvoř tabulku

  CREATE TABLE custom_agenda_views (
    id TEXT PRIMARY KEY,              -- UUID
    name TEXT NOT NULL,
    tag_filter TEXT NOT NULL,         -- Normalized tag name
    icon_code_point INTEGER NOT NULL,
    color_hex TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,      -- Unix timestamp

    CHECK (LENGTH(name) > 0),
    CHECK (LENGTH(tag_filter) > 0),

    FOREIGN KEY(tag_filter) REFERENCES tags(tag_name) ON DELETE CASCADE
  );

  CREATE INDEX idx_custom_views_enabled ON custom_agenda_views(enabled);

  Krok 2: Migrace z SharedPreferences

  Future<void> _migrateAgendaViewsToDb(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('agenda_config');

      if (jsonString == null) return;

      final config = AgendaViewConfig.fromJson(jsonDecode(jsonString));

      // Vložit custom views do DB
      for (final view in config.customViews) {
        await db.insert('custom_agenda_views', {
          'id': view.id,
          'name': view.name,
          'tag_filter': view.tagFilter.toLowerCase(),  // Normalize!
          'icon_code_point': view.iconCodePoint,
          'color_hex': view.colorHex,
          'sort_order': config.customViews.indexOf(view),
          'enabled': 1,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Vyčistit SharedPreferences (deprecated)
      await prefs.remove('agenda_config');

    } catch (e) {
      AppLogger.error('Chyba při migraci agenda views: $e');
    }
  }

  Krok 3: Přidat built-in view settings do settings tabulky

  -- Migrace v onUpgrade
  ALTER TABLE settings ADD COLUMN show_all INTEGER NOT NULL DEFAULT 1;
  ALTER TABLE settings ADD COLUMN show_today INTEGER NOT NULL DEFAULT 1;
  ALTER TABLE settings ADD COLUMN show_week INTEGER NOT NULL DEFAULT 1;
  ALTER TABLE settings ADD COLUMN show_upcoming INTEGER NOT NULL DEFAULT 0;
  ALTER TABLE settings ADD COLUMN show_overdue INTEGER NOT NULL DEFAULT 1;

  ---
  🎯 FÁZE 3: Cleanup & Performance

  Krok 1: Odstranit deprecated sloupec tags z todos

  ⚠️ SQLite nepodporuje ALTER TABLE DROP COLUMN

  Řešení: Recreate tabulky

  Future<void> _dropDeprecatedTagsColumn(Database db) async {
    // 1. Vytvořit novou tabulku bez 'tags' sloupce
    await db.execute('''
      CREATE TABLE todos_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        priority TEXT,
        dueDate TEXT,
        ai_recommendations TEXT,
        ai_deadline_analysis TEXT
      )
    ''');

    // 2. Zkopírovat data (bez tags sloupce)
    await db.execute('''
      INSERT INTO todos_new (id, task, isCompleted, createdAt, priority, dueDate, ai_recommendations,
  ai_deadline_analysis)
      SELECT id, task, isCompleted, createdAt, priority, dueDate, ai_recommendations, ai_deadline_analysis
      FROM todos
    ''');

    // 3. Dropnout starou tabulku
    await db.execute('DROP TABLE todos');

    // 4. Přejmenovat novou
    await db.execute('ALTER TABLE todos_new RENAME TO todos');

    // 5. Recreate indexy
    await db.execute('CREATE INDEX idx_todos_task ON todos(task)');
    await db.execute('CREATE INDEX idx_todos_dueDate ON todos(dueDate)');
    await db.execute('CREATE INDEX idx_todos_priority ON todos(priority)');
    await db.execute('CREATE INDEX idx_todos_isCompleted ON todos(isCompleted)');
    await db.execute('CREATE INDEX idx_todos_createdAt ON todos(createdAt)');
  }

  NEBO (jednodušší): Nechat sloupec prázdný a deprecated

  // Nepsat do něj, ignorovat při čtení
  // Označit komentářem jako DEPRECATED
  await db.execute('-- DEPRECATED: tags sloupec, používej todo_tags tabulku');

  Krok 2: Optimalizovat queries

  PŘED (pomalé):
  -- Vyhledat všechny todos s tagem "projekt"
  SELECT * FROM todos WHERE tags LIKE '%projekt%';  -- ❌ Full table scan!

  PO (rychlé):
  -- Vyhledat všechny todos s tagem "projekt"
  SELECT t.*
  FROM todos t
  INNER JOIN todo_tags tt ON t.id = tt.todo_id
  INNER JOIN tags tag ON tt.tag_id = tag.id
  WHERE tag.tag_name = 'projekt';  -- ✅ Index scan!

  ---
  📈 OČEKÁVANÉ ZLEPŠENÍ

  | Metrická             | Před                    | Po               | Zlepšení          |
  |----------------------|-------------------------|------------------|-------------------|
  | Tag autocomplete     | ❌ Nelze                 | ✅ Instant        | ♾️                |
  | Search úkolů s tagem | 🐌 O(n) scan            | ⚡ O(log n) index | 10-100x rychlejší |
  | Normalizace tagů     | ❌ "Projekt" ≠ "projekt" | ✅ Unified        | ♾️                |
  | Tag statistics       | ❌ Nelze                 | ✅ usage_count    | ♾️                |
  | Custom view filtr    | 🐌 LIKE query           | ⚡ JOIN query     | 5-10x rychlejší   |
  | Data consistency     | ⚠️ CSV může být broken  | ✅ Foreign keys   | ♾️                |
  | Settings persistence | ⚠️ DB + SharedPrefs     | ✅ Pouze DB       | Unified           |

  ---
  🚀 IMPLEMENTAČNÍ PLÁN - DOPORUČENÝ POSTUP

  MILESTONE 1: Tags Normalization ⏱️ 4-6h

  1. ✅ Snapshot commit
  2. ✅ Vytvořit tags tabulku
  3. ✅ Vytvořit todo_tags tabulku
  4. ✅ Migrace: CSV → normalizované tagy
  5. ✅ Update TodoRepository: používat todo_tags
  6. ✅ Přidat autocomplete API
  7. ✅ Testing: search, autocomplete, statistics
  8. ✅ Commit

  MILESTONE 2: Custom Agenda Views to DB ⏱️ 2-3h

  1. ✅ Snapshot commit
  2. ✅ Vytvořit custom_agenda_views tabulku
  3. ✅ Přidat built-in view settings do settings
  4. ✅ Migrace: SharedPrefs → DB
  5. ✅ Update SettingsCubit: používat DB místo SharedPrefs
  6. ✅ Testing: CRUD operace
  7. ✅ Commit

  MILESTONE 3: Cleanup ⏱️ 1-2h

  1. ✅ Snapshot commit
  2. ✅ Drop deprecated tags sloupec (nebo mark deprecated)
  3. ✅ Remove SharedPreferences agenda_config code
  4. ✅ Performance testing
  5. ✅ Commit

  Celkový čas: 7-11 hodin

  ---
  ⚠️ MIGRACE CONSIDERATIONS

  Database Version Bump

  // database_helper.dart
  return await openDatabase(
    path,
    version: 11,  // ← Změnit z 10 na 11
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );

  onUpgrade Handler

  if (oldVersion < 11) {
    // MILESTONE 1: Tags normalization
    await _createTagsTables(db);
    await _migrateTagsToNormalizedSchema(db);

    // MILESTONE 2: Custom Agenda Views
    await _createCustomAgendaViewsTable(db);
    await _migrateAgendaViewsToDb(db);
    await _addBuiltInViewSettingsColumns(db);

    // MILESTONE 3: Cleanup
    // Optional: Drop deprecated columns
  }

  Backward Compatibility

  - ⚠️ Nelze downgrade z v11 → v10!
  - ✅ Doporučuji: Export/Backup před migrací
  - ✅ Testing na kopii databáze

  ---
  🎯 ZÁVĚREČNÉ DOPORUČENÍ

  PRIORITY RANKING:

  1. 🔴 CRITICAL: Tags normalizace (CSV → tags + todo_tags)
    - Proč: Největší performance win, umožní autocomplete
    - Kdy: Co nejdříve! (před dalším vývojem)
  2. 🟡 HIGH: Custom Agenda Views do DB
    - Proč: Konzistence dat, lepší queryování
    - Kdy: Po tags normalizaci
  3. 🟢 MEDIUM: Cleanup deprecated code
    - Proč: Code hygiene, technical debt reduction
    - Kdy: Po Milestone 1 & 2

  ---
  💬 OTÁZKY PRO TEBE, MISTŘE JARDO:

  1. Chceš implementovat tags normalizaci hned teď, nebo to plánovat na později?
  2. Custom Agenda Views - priorita? (už je naplánováno v custom-agenda-views.md)
  3. Backward compatibility - potřebuješ podporovat downgr

  ade z v11 → v10?
  4. Testing strategy - máš testovací databázi, nebo testovat na produkční?
  5. Autocomplete UI - kde chceš zobrazit tag suggestions? (TextField, Dropdown, BottomSheet?)

  ---
  Verdict: Databázová architektura je solidní základ, ale má kritickou slabinu v tags denormalizaci.

  Doporučuji ASAP refaktoring → normalizace tagů pro dlouhodobou škálovatelnost a UX win (autocomplete). 🚀

  Jak chceš postupovat? 🤔