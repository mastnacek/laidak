import 'package:flutter/material.dart';
import 'core/services/database_helper.dart';

/// Debug script pro kontrolu Pomodoro sessions v databázi
///
/// Použití:
/// 1. Spusť app a klikni na Pomodoro timer
/// 2. Po ukončení timeru zavři app
/// 3. V main.dart temporarily zavolej debugPomodoroDatabase()
Future<void> debugPomodoroDatabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;

  print('\n' + '='*80);
  print('🍅 POMODORO SESSIONS DEBUG');
  print('='*80);

  // Získat všechny sessions
  final sessions = await db.query('pomodoro_sessions', orderBy: 'started_at DESC');

  if (sessions.isEmpty) {
    print('❌ Žádné Pomodoro sessions v databázi!');
    print('   Zkus spustit timer a pak ho zastavit/dokončit.');
  } else {
    print('✅ Nalezeno ${sessions.length} Pomodoro sessions:\n');

    for (var i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      final id = session['id'];
      final taskId = session['task_id'];
      final startedAt = session['started_at'] as int;
      final endedAt = session['ended_at'] as int?;
      final duration = session['duration'] as int;
      final actualDuration = session['actual_duration'] as int?;
      final completed = session['completed'] as int;
      final isBreak = session['is_break'] as int;

      final startTime = DateTime.fromMillisecondsSinceEpoch(startedAt);
      final endTime = endedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(endedAt)
          : null;

      print('Session #${i + 1}:');
      print('  • ID: $id');
      print('  • Task ID: $taskId');
      print('  • Started: $startTime');
      print('  • Ended: ${endTime ?? "NULL (neukončeno)"}');
      print('  • Plánovaná délka: ${duration}s (${(duration / 60).toStringAsFixed(1)} min)');
      print('  • Skutečná délka: ${actualDuration ?? "NULL"}s');
      print('  • Dokončeno: ${completed == 1 ? "✅ ANO" : "❌ NE"}');
      print('  • Je pauza: ${isBreak == 1 ? "☕ ANO" : "⚡ NE (práce)"}');
      print('');
    }

    // Statistiky
    print('-'*80);
    print('📊 STATISTIKY:');

    final completedCount = sessions.where((s) => s['completed'] == 1).length;
    final totalSessions = sessions.length;
    final successRate = (completedCount / totalSessions * 100).toStringAsFixed(1);

    print('  • Celkem sessions: $totalSessions');
    print('  • Dokončeno: $completedCount');
    print('  • Success rate: $successRate%');

    // Celkový čas
    int totalTime = 0;
    for (var session in sessions) {
      if (session['completed'] == 1) {
        final actual = session['actual_duration'] as int?;
        final planned = session['duration'] as int;
        totalTime += actual ?? planned;
      }
    }

    final totalMinutes = (totalTime / 60).toStringAsFixed(1);
    final totalHours = (totalTime / 3600).toStringAsFixed(2);
    print('  • Celkový odpracovaný čas: ${totalTime}s (${totalMinutes} min / ${totalHours} h)');
  }

  print('='*80 + '\n');
}
