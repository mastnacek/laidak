import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pomodoro_config.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../datasources/pomodoro_local_datasource.dart';

/// Implementace PomodoroRepository s SQLite + SharedPreferences
class PomodoroRepositoryImpl implements PomodoroRepository {
  final PomodoroLocalDataSource _dataSource;

  PomodoroRepositoryImpl({PomodoroLocalDataSource? dataSource})
      : _dataSource = dataSource ?? PomodoroLocalDataSource();

  @override
  Future<PomodoroSession> createSession(PomodoroSession session) async {
    return await _dataSource.createSession(session);
  }

  @override
  Future<void> updateSession(PomodoroSession session) async {
    return await _dataSource.updateSession(session);
  }

  @override
  Future<void> deleteSession(int id) async {
    return await _dataSource.deleteSession(id);
  }

  @override
  Future<PomodoroSession?> getSessionById(int id) async {
    return await _dataSource.getSessionById(id);
  }

  @override
  Future<List<PomodoroSession>> getSessionsByTask(int taskId) async {
    return await _dataSource.getSessionsByTask(taskId);
  }

  @override
  Future<List<PomodoroSession>> getAllSessions() async {
    return await _dataSource.getAllSessions();
  }

  @override
  Future<List<PomodoroSession>> getTodaySessions() async {
    return await _dataSource.getTodaySessions();
  }

  @override
  Future<int> getCompletedSessionCount(int taskId) async {
    return await _dataSource.getCompletedSessionCount(taskId);
  }

  @override
  Future<Duration> getTotalTimeForTask(int taskId) async {
    final seconds = await _dataSource.getTotalTimeForTask(taskId);
    return Duration(seconds: seconds);
  }

  @override
  Future<int> getTodaySessionCount() async {
    return await _dataSource.getTodaySessionCount();
  }

  @override
  Future<void> saveConfig(PomodoroConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_work_minutes', config.workDuration.inMinutes);
    await prefs.setInt('pomodoro_break_minutes', config.breakDuration.inMinutes);
    await prefs.setBool('pomodoro_auto_start_break', config.autoStartBreak);
    await prefs.setBool('pomodoro_sound_enabled', config.soundEnabled);
  }

  @override
  Future<PomodoroConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return PomodoroConfig(
      workDuration: Duration(minutes: prefs.getInt('pomodoro_work_minutes') ?? 25),
      breakDuration: Duration(minutes: prefs.getInt('pomodoro_break_minutes') ?? 5),
      autoStartBreak: prefs.getBool('pomodoro_auto_start_break') ?? false,
      soundEnabled: prefs.getBool('pomodoro_sound_enabled') ?? true,
    );
  }
}
