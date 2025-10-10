import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_helper.dart';

/// Debug utility pro správu databáze (POUZE pro development!)
class DatabaseDebugUtils {
  /// Vymazat databázi a znovu ji vytvořit (POZOR: smaže všechna data!)
  static Future<void> resetDatabase() async {
    try {
      // Zavřít existující spojení
      await DatabaseHelper().close();

      // Získat cestu k databázi
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'todo.db');

      // Smazat databázi
      await deleteDatabase(path);

      print('✅ [DatabaseDebugUtils] Databáze smazána: $path');

      // Znovu inicializovat databázi (zavolá _onCreate)
      await DatabaseHelper().database;

      print('✅ [DatabaseDebugUtils] Databáze znovu vytvořena s čistou strukturou');
    } catch (e) {
      print('❌ [DatabaseDebugUtils] Chyba při resetování databáze: $e');
      rethrow;
    }
  }

  /// Získat informace o databázi (verze, sloupce, tabulky)
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final db = await DatabaseHelper().database;

      // Získat verzi databáze
      final version = await db.getVersion();

      // Získat info o todos tabulce
      final todosColumns = await db.rawQuery('PRAGMA table_info(todos)');

      // Získat seznam všech tabulek
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );

      // Získat indexy
      final indexes = await db.rawQuery(
        "SELECT name, tbl_name FROM sqlite_master WHERE type='index' ORDER BY name",
      );

      return {
        'version': version,
        'todos_columns': todosColumns.map((col) => col['name']).toList(),
        'tables': tables.map((t) => t['name']).toList(),
        'indexes': indexes.map((idx) => '${idx['name']} on ${idx['tbl_name']}').toList(),
      };
    } catch (e) {
      print('❌ [DatabaseDebugUtils] Chyba při čtení info databáze: $e');
      rethrow;
    }
  }

  /// Zkontrolovat, jestli databáze má správnou strukturu
  static Future<bool> validateDatabaseStructure() async {
    try {
      final info = await getDatabaseInfo();

      // Zkontrolovat verzi
      if (info['version'] != 9) {
        print('⚠️ [DatabaseDebugUtils] Databáze má nesprávnou verzi: ${info['version']} (očekáváno: 9)');
        return false;
      }

      // Zkontrolovat AI sloupce
      final columns = info['todos_columns'] as List;
      if (!columns.contains('ai_recommendations')) {
        print('⚠️ [DatabaseDebugUtils] Chybí sloupec ai_recommendations');
        return false;
      }
      if (!columns.contains('ai_deadline_analysis')) {
        print('⚠️ [DatabaseDebugUtils] Chybí sloupec ai_deadline_analysis');
        return false;
      }

      // Zkontrolovat tabulky
      final tables = info['tables'] as List;
      final requiredTables = ['todos', 'settings', 'custom_prompts', 'tag_definitions', 'subtasks'];
      for (final table in requiredTables) {
        if (!tables.contains(table)) {
          print('⚠️ [DatabaseDebugUtils] Chybí tabulka: $table');
          return false;
        }
      }

      print('✅ [DatabaseDebugUtils] Databáze má správnou strukturu');
      return true;
    } catch (e) {
      print('❌ [DatabaseDebugUtils] Chyba při validaci databáze: $e');
      return false;
    }
  }
}
