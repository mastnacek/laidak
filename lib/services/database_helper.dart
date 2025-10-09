import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo_item.dart';

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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Vytvořit tabulky při první inicializaci
  Future<void> _onCreate(Database db, int version) async {
    // Tabulka úkolů
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        priority TEXT,
        dueDate TEXT,
        action TEXT,
        tags TEXT
      )
    ''');

    // Tabulka AI nastavení
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        api_key TEXT,
        model TEXT NOT NULL DEFAULT 'mistralai/mistral-medium-3.1',
        temperature REAL NOT NULL DEFAULT 1.0,
        max_tokens INTEGER NOT NULL DEFAULT 1000,
        enabled INTEGER NOT NULL DEFAULT 1
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

    // Vložit výchozí nastavení
    await _insertDefaultSettings(db);
    await _insertDefaultPrompts(db);
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
  }

  /// Vložit výchozí AI nastavení
  Future<void> _insertDefaultSettings(Database db) async {
    await db.insert('settings', {
      'id': 1,
      'api_key': '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',
      'model': 'mistralai/mistral-medium-3.1',
      'temperature': 1.0,
      'max_tokens': 1000,
      'enabled': 1,
    });
  }

  /// Vložit výchozí motivační prompty
  Future<void> _insertDefaultPrompts(Database db) async {
    // Prompt pro práci
    await db.insert('custom_prompts', {
      'category': 'práce',
      'system_prompt': 'Jsi můj šéf Zdeněk a já jsem Jarda tvůj podřízený. Jseš na mě už pěkně nasranej, protože mě všechno dlouho trvá, ale buď pozitivní a moc nevysírej a popožeň mě nějakou motivací. Odpovídej POUZE v češtině. Nepiju pivo!',
      'tags': '["práce","work","job","office","projekt","meeting"]',
      'style': 'profesionální a asertivní',
    });

    // Prompt pro domov
    await db.insert('custom_prompts', {
      'category': 'domov',
      'system_prompt': 'ROLE: Jsi moje manželka Lenka, která má obrovská prsa a velký macatý zadek - já jsem tvůj manžel Jaroslav a tyhle tvoje proporce miluji. Motivuj mě k dokončení úkolů s důrazem na rodinné hodnoty a pohodlí domova. Buď vlídná a podporující, použij svoje přednosti a vnady k motivaci sexem (vymýšlej různé variace na moje oblíbené polohy a praktiky), protože jsem chorobný prokrastinátor - odkladač. Mám rád titfuck mezi tvá obrovská prsa a rád na ně stříkám semeno!!! Taky tě rád šukám zezadu kdy vidím tvůj obrovský zadek a kozy! Když tě šukám zezadu, líbí se mě, jak jsou kozy rozvalené do stran. Nebo když jseš v pozici nahoře a tvoje kozy mám v obličeji!!! Buď kreativní v motivování. Oslovuj mě přímo a eroticky a lechtivě. Používej emoji pro zvýraznění. Vrať maximálne 20 vět a minimálně 10.',
      'tags': '["domov","doma","rodina","family","home"]',
      'style': 'rodinný a vlídný',
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
        'api_key': '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',
        'model': 'mistralai/mistral-medium-3.1',
        'temperature': 1.0,
        'max_tokens': 1000,
        'enabled': 1,
      };
    }

    return result.first;
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
      final promptTags = (promptTagsJson as String)
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
}
