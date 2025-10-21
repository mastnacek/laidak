import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/timer_state.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../../domain/services/pomodoro_timer_service.dart';
import '../../domain/services/notification_service.dart';
import '../bloc/pomodoro_state.dart';

part 'pomodoro_provider.g.dart';

/// Provider pro PomodoroRepository
@riverpod
PomodoroRepository pomodoroRepository(PomodoroRepositoryRef ref) {
  throw UnimplementedError('PomodoroRepository musí být implementován');
}

/// Provider pro PomodoroTimerService
@riverpod
PomodoroTimerService pomodoroTimerService(PomodoroTimerServiceRef ref) {
  return PomodoroTimerService();
}

/// Provider pro NotificationService
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

/// Riverpod Notifier pro Pomodoro Timer feature
///
/// Nahrazuje původní PomodoroBloc
/// Zodpovědnosti:
/// - State management pro Pomodoro timer
/// - Integrace s PomodoroTimerService (Isolate timer)
/// - Persistence do DB přes PomodoroRepository
/// - Business logika pro Pomodoro workflow
@riverpod
class Pomodoro extends _$Pomodoro {
  /// Subscription na timer tick events
  StreamSubscription<Duration>? _timerSubscription;

  @override
  PomodoroState build() {
    // Cleanup při dispose
    ref.onDispose(() {
      _timerSubscription?.cancel();
      _stopTimer();
    });

    return const PomodoroState();
  }

  /// Spustit nové Pomodoro
  Future<void> startPomodoro({
    required int taskId,
    Duration? customDuration,
  }) async {
    // Validace
    if (state.isTimerActive) {
      state = state.copyWith(
        errorMessage: 'Timer již běží! Nejdřív zastavte současný timer.',
      );
      return;
    }

    final repository = ref.read(pomodoroRepositoryProvider);
    final timerService = ref.read(pomodoroTimerServiceProvider);

    final duration = customDuration ?? state.config.workDuration;
    final now = DateTime.now();

    // Vytvořit novou session v DB
    final session = PomodoroSession(
      taskId: taskId,
      startedAt: now,
      duration: duration,
      completed: false,
      isBreak: false,
    );

    try {
      // Uložit session do DB
      final savedSession = await repository.createSession(session);

      // Načíst počet sessions pro tento úkol
      final completedCount = await repository.getCompletedSessionCount(taskId);

      state = state.copyWith(
        currentSession: savedSession,
        timerState: TimerState.running,
        remainingTime: duration,
        elapsedTime: Duration.zero,
        completedPomodorosForTask: completedCount,
        errorMessage: null,
      );

      // Spustit timer
      _startTimer(duration);

      AppLogger.info('✅ Pomodoro spuštěno: task $taskId, duration ${duration.inMinutes}m');
    } catch (e) {
      AppLogger.error('Chyba při spuštění Pomodoro: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Pozastavit timer
  void pausePomodoro() {
    if (!state.isTimerActive) return;

    final timerService = ref.read(pomodoroTimerServiceProvider);
    timerService.pauseTimer();

    state = state.copyWith(timerState: TimerState.paused);
    AppLogger.debug('⏸️ Pomodoro pozastaveno');
  }

  /// Obnovit timer
  void resumePomodoro() {
    if (state.timerState != TimerState.paused) return;

    final timerService = ref.read(pomodoroTimerServiceProvider);
    timerService.resumeTimer();

    state = state.copyWith(timerState: TimerState.running);
    AppLogger.debug('▶️ Pomodoro obnoveno');
  }

  /// Zastavit timer
  Future<void> stopPomodoro() async {
    _stopTimer();

    // Mark session as incomplete
    if (state.currentSession != null) {
      final repository = ref.read(pomodoroRepositoryProvider);
      await repository.updateSession(
        state.currentSession!.copyWith(
          completed: false,
          endedAt: DateTime.now(),
        ),
      );
    }

    state = state.copyWith(
      currentSession: null,
      timerState: TimerState.idle,
      remainingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

    AppLogger.info('⏹️ Pomodoro zastaveno');
  }

  /// Timer tick event
  void onTimerTick(Duration elapsed) {
    final currentSession = state.currentSession;
    if (currentSession == null) return;

    final duration = currentSession.duration;
    final remaining = duration - elapsed;

    // Update state
    state = state.copyWith(
      elapsedTime: elapsed,
      remainingTime: remaining > Duration.zero ? remaining : Duration.zero,
    );

    // Log každých 10s
    if (elapsed.inSeconds % 10 == 0) {
      AppLogger.debug('⏱️ Elapsed: ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s');
    }
  }

  /// Timer complete event
  Future<void> onTimerComplete() async {
    final currentSession = state.currentSession;
    if (currentSession == null) return;

    _stopTimer();

    try {
      final repository = ref.read(pomodoroRepositoryProvider);
      final notificationService = ref.read(notificationServiceProvider);

      // Mark session as completed
      await repository.updateSession(
        currentSession.copyWith(
          completed: true,
          endedAt: DateTime.now(),
        ),
      );

      // Show notification
      await notificationService.showPomodoroCompleteNotification();

      // Update state - show completion dialog
      state = state.copyWith(
        timerState: TimerState.completed,
        showCompletionDialog: true,
      );

      AppLogger.info('✅ Pomodoro dokončeno!');
    } catch (e) {
      AppLogger.error('Chyba při dokončení Pomodoro: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Spustit přestávku
  Future<void> startBreak({bool isLongBreak = false}) async {
    final repository = ref.read(pomodoroRepositoryProvider);
    final timerService = ref.read(pomodoroTimerServiceProvider);

    final duration = isLongBreak
        ? state.config.longBreakDuration
        : state.config.shortBreakDuration;

    final now = DateTime.now();

    // Vytvořit break session
    final breakSession = PomodoroSession(
      taskId: state.currentSession?.taskId,
      startedAt: now,
      duration: duration,
      completed: false,
      isBreak: true,
    );

    try {
      final savedSession = await repository.createSession(breakSession);

      state = state.copyWith(
        currentSession: savedSession,
        timerState: TimerState.running,
        remainingTime: duration,
        elapsedTime: Duration.zero,
        showCompletionDialog: false,
      );

      _startTimer(duration);

      AppLogger.info('☕ Přestávka spuštěna: ${duration.inMinutes}m');
    } catch (e) {
      AppLogger.error('Chyba při spuštění přestávky: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Pokračovat dalším Pomodoro
  void continuePomodoro() {
    state = state.copyWith(
      showCompletionDialog: false,
      timerState: TimerState.idle,
    );
  }

  /// Načíst historii sessions
  Future<void> loadHistory({int? taskId}) async {
    try {
      final repository = ref.read(pomodoroRepositoryProvider);
      final sessions = taskId != null
          ? await repository.getSessionsForTask(taskId)
          : await repository.getAllSessions();

      state = state.copyWith(history: sessions);
      AppLogger.debug('✅ Historie načtena: ${sessions.length} sessions');
    } catch (e) {
      AppLogger.error('Chyba při načítání historie: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Aktualizovat konfiguraci
  void updateConfig({
    Duration? workDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? pomodorosUntilLongBreak,
  }) {
    state = state.copyWith(
      config: state.config.copyWith(
        workDuration: workDuration,
        shortBreakDuration: shortBreakDuration,
        longBreakDuration: longBreakDuration,
        pomodorosUntilLongBreak: pomodorosUntilLongBreak,
      ),
    );

    AppLogger.debug('✅ Pomodoro config aktualizován');
  }

  /// Dokončit úkol (mark session as task finished)
  Future<void> finishTask() async {
    final currentSession = state.currentSession;
    if (currentSession == null) return;

    _stopTimer();

    try {
      final repository = ref.read(pomodoroRepositoryProvider);

      await repository.updateSession(
        currentSession.copyWith(
          completed: true,
          endedAt: DateTime.now(),
        ),
      );

      state = state.copyWith(
        currentSession: null,
        timerState: TimerState.idle,
        showCompletionDialog: false,
      );

      AppLogger.info('✅ Úkol dokončen');
    } catch (e) {
      AppLogger.error('Chyba při dokončení úkolu: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // ==================== PRIVATE HELPERS ====================

  /// Spustit timer
  void _startTimer(Duration duration) {
    final timerService = ref.read(pomodoroTimerServiceProvider);

    timerService.startTimer(
      duration: duration,
      onTick: (elapsed) => onTimerTick(elapsed),
      onComplete: () => onTimerComplete(),
    );

    // Subscribe to timer stream
    _timerSubscription?.cancel();
    _timerSubscription = timerService.timerStream.listen(
      (elapsed) => onTimerTick(elapsed),
    );
  }

  /// Zastavit timer
  void _stopTimer() {
    final timerService = ref.read(pomodoroTimerServiceProvider);
    timerService.stopTimer();
    _timerSubscription?.cancel();
  }
}

/// Helper provider: je timer aktivní?
@riverpod
bool isPomodoroActive(IsPomodoroActiveRef ref) {
  final pomodoroState = ref.watch(pomodoroProvider);
  return pomodoroState.isTimerActive;
}

/// Helper provider: zbývající čas
@riverpod
Duration pomodoroRemainingTime(PomodoroRemainingTimeRef ref) {
  final pomodoroState = ref.watch(pomodoroProvider);
  return pomodoroState.remainingTime;
}
