import 'package:sqflite/sqflite.dart';
import '../../../../core/services/database_helper.dart';
import '../../domain/entities/pomodoro_session.dart';

/// Local datasource pro Pomodoro Sessions (SQLite)
///
/// Zodpovědnosti:
/// - CRUD operace nad pomodoro_sessions tabulkou
/// - Statistiky a agregace (completed sessions, total time)
class PomodoroLocalDataSource {
  final DatabaseHelper _dbHelper;

  PomodoroLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper();

  /// Vytvořit novou session v DB
  Future<PomodoroSession> createSession(PomodoroSession session) async {
    final db = await _dbHelper.database;
    final id = await db.insert('pomodoro_sessions', session.toMap());
    return session.copyWith(id: id);
  }

  /// Aktualizovat existující session
  Future<void> updateSession(PomodoroSession session) async {
    final db = await _dbHelper.database;
    await db.update(
      'pomodoro_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Smazat session podle ID
  Future<void> deleteSession(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pomodoro_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Získat session podle ID
  Future<PomodoroSession?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'pomodoro_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return PomodoroSession.fromMap(results.first);
  }

  /// Získat všechny sessions pro konkrétní úkol
  Future<List<PomodoroSession>> getSessionsByTask(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'pomodoro_sessions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'started_at DESC',
    );

    return results.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  /// Získat všechny sessions (globální historie)
  Future<List<PomodoroSession>> getAllSessions() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'pomodoro_sessions',
      orderBy: 'started_at DESC',
    );

    return results.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  /// Získat dnešní sessions
  Future<List<PomodoroSession>> getTodaySessions() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch;

    final results = await db.query(
      'pomodoro_sessions',
      where: 'started_at >= ?',
      whereArgs: [startTimestamp],
      orderBy: 'started_at DESC',
    );

    return results.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  /// Získat sessions v určitém časovém rozmezí
  Future<List<PomodoroSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'pomodoro_sessions',
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'started_at DESC',
    );

    return results.map((map) => PomodoroSession.fromMap(map)).toList();
  }

  /// Statistika: Počet dokončených sessions pro úkol
  Future<int> getCompletedSessionCount(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM pomodoro_sessions
      WHERE task_id = ? AND completed = 1 AND is_break = 0
    ''', [taskId]);

    return Sqflite.firstIntValue(results) ?? 0;
  }

  /// Statistika: Celkový čas strávený na úkolu (v sekundách)
  Future<int> getTotalTimeForTask(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT SUM(COALESCE(actual_duration, duration)) as total
      FROM pomodoro_sessions
      WHERE task_id = ? AND completed = 1 AND is_break = 0
    ''', [taskId]);

    final total = results.first['total'];
    return (total is int) ? total : 0;
  }

  /// Statistika: Počet dnešních sessions
  Future<int> getTodaySessionCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startTimestamp = startOfDay.millisecondsSinceEpoch;

    final results = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM pomodoro_sessions
      WHERE started_at >= ? AND completed = 1 AND is_break = 0
    ''', [startTimestamp]);

    return Sqflite.firstIntValue(results) ?? 0;
  }

  /// Statistika: Průměrná délka session pro úkol
  Future<double> getAverageSessionDuration(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT AVG(COALESCE(actual_duration, duration)) as avg
      FROM pomodoro_sessions
      WHERE task_id = ? AND completed = 1 AND is_break = 0
    ''', [taskId]);

    final avg = results.first['avg'];
    return (avg is num) ? avg.toDouble() : 0.0;
  }

  /// Statistika: Success rate (dokončené / celkem) pro úkol
  Future<double> getSuccessRate(int taskId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed,
        COUNT(*) as total
      FROM pomodoro_sessions
      WHERE task_id = ? AND is_break = 0
    ''', [taskId]);

    final row = results.first;
    final completed = row['completed'] as int? ?? 0;
    final total = row['total'] as int? ?? 0;

    if (total == 0) return 0.0;
    return completed / total;
  }
}
