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
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Vytvořit tabulky při první inicializaci
  Future<void> _onCreate(Database db, int version) async {
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
}
