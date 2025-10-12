import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pomodoro_config.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../../../../core/database/database_helper.dart';

/// Implementace PomodoroRepository s SQLite + SharedPreferences
class PomodoroRepositoryImpl implements PomodoroRepository {
  final DatabaseHelper databaseHelper;

  PomodoroRepositoryImpl({required this.databaseHelper});

  @override
  Future<PomodoroSession> createSession(PomodoroSession session) async {
    // TODO: Implement when DB migration is done
    throw UnimplementedError('Database migration for pomodoro_sessions not yet implemented');
  }

  @override
  Future<void> updateSession(PomodoroSession session) async {
    // TODO: Implement when DB migration is done
    throw UnimplementedError('Database migration for pomodoro_sessions not yet implemented');
  }

  @override
  Future<void> deleteSession(int id) async {
    // TODO: Implement when DB migration is done
    throw UnimplementedError('Database migration for pomodoro_sessions not yet implemented');
  }

  @override
  Future<PomodoroSession?> getSessionById(int id) async {
    // TODO: Implement when DB migration is done
    return null;
  }

  @override
  Future<List<PomodoroSession>> getSessionsByTask(int taskId) async {
    // TODO: Implement when DB migration is done
    return [];
  }

  @override
  Future<List<PomodoroSession>> getAllSessions() async {
    // TODO: Implement when DB migration is done
    return [];
  }

  @override
  Future<List<PomodoroSession>> getTodaySessions() async {
    // TODO: Implement when DB migration is done
    return [];
  }

  @override
  Future<int> getCompletedSessionCount(int taskId) async {
    // TODO: Implement when DB migration is done
    return 0;
  }

  @override
  Future<Duration> getTotalTimeForTask(int taskId) async {
    // TODO: Implement when DB migration is done
    return Duration.zero;
  }

  @override
  Future<int> getTodaySessionCount() async {
    // TODO: Implement when DB migration is done
    return 0;
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
