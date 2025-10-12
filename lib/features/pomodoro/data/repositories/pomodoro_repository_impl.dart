import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/pomodoro_config.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../datasources/pomodoro_local_datasource.dart';

/// Implementace PomodoroRepository
///
/// Zodpovědnosti:
/// - Delegování CRUD operací na LocalDataSource
/// - Config persistence do SharedPreferences
/// - Business logika (filtrování, sorting, validace)
class PomodoroRepositoryImpl implements PomodoroRepository {
  final PomodoroLocalDataSource _localDataSource;
  final SharedPreferences _prefs;

  static const _configKey = 'pomodoro_config';

  PomodoroRepositoryImpl({
    required PomodoroLocalDataSource localDataSource,
    required SharedPreferences prefs,
  })  : _localDataSource = localDataSource,
        _prefs = prefs;

  // ==================== SESSION CRUD ====================

  @override
  Future<PomodoroSession> createSession(PomodoroSession session) async {
    return await _localDataSource.createSession(session);
  }

  @override
  Future<void> updateSession(PomodoroSession session) async {
    await _localDataSource.updateSession(session);
  }

  @override
  Future<void> deleteSession(int id) async {
    await _localDataSource.deleteSession(id);
  }

  @override
  Future<PomodoroSession?> getSessionById(int id) async {
    return await _localDataSource.getSessionById(id);
  }

  @override
  Future<List<PomodoroSession>> getSessionsByTask(int taskId) async {
    return await _localDataSource.getSessionsByTask(taskId);
  }

  @override
  Future<List<PomodoroSession>> getAllSessions() async {
    return await _localDataSource.getAllSessions();
  }

  @override
  Future<List<PomodoroSession>> getTodaySessions() async {
    return await _localDataSource.getTodaySessions();
  }

  @override
  Future<List<PomodoroSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _localDataSource.getSessionsInRange(start, end);
  }

  // ==================== STATISTICS ====================

  @override
  Future<int> getCompletedSessionCount(int taskId) async {
    return await _localDataSource.getCompletedSessionCount(taskId);
  }

  @override
  Future<int> getTotalTimeForTask(int taskId) async {
    return await _localDataSource.getTotalTimeForTask(taskId);
  }

  @override
  Future<int> getTodaySessionCount() async {
    return await _localDataSource.getTodaySessionCount();
  }

  @override
  Future<double> getAverageSessionDuration(int taskId) async {
    return await _localDataSource.getAverageSessionDuration(taskId);
  }

  @override
  Future<double> getSuccessRate(int taskId) async {
    return await _localDataSource.getSuccessRate(taskId);
  }

  // ==================== CONFIG PERSISTENCE ====================

  @override
  Future<void> saveConfig(PomodoroConfig config) async {
    final json = jsonEncode(config.toJson());
    await _prefs.setString(_configKey, json);
  }

  @override
  Future<PomodoroConfig> loadConfig() async {
    final json = _prefs.getString(_configKey);

    if (json == null || json.isEmpty) {
      // Vrátit výchozí config
      return const PomodoroConfig();
    }

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PomodoroConfig.fromJson(map);
    } catch (e) {
      // Pokud selže parsing, vrátit výchozí
      return const PomodoroConfig();
    }
  }
}
