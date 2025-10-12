import 'package:equatable/equatable.dart';
import '../../domain/entities/pomodoro_config.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/timer_state.dart';

/// Immutable state pro Pomodoro feature
class PomodoroState extends Equatable {
  /// Aktuální stav timeru (idle/running/paused/break)
  final TimerState timerState;

  /// ID úkolu pro aktuální session (null pokud idle)
  final int? currentTaskId;

  /// Zbývající čas v aktuální session
  final Duration remainingTime;

  /// Celková délka aktuální session
  final Duration totalDuration;

  /// Počet dokončených Pomodoro sessions na aktuální úkol
  final int sessionCount;

  /// Aktuální běžící session (null pokud idle)
  final PomodoroSession? currentSession;

  /// Historie sessions (dnes nebo pro konkrétní úkol)
  final List<PomodoroSession> history;

  /// Konfigurace Pomodoro (workDuration, breakDuration, etc.)
  final PomodoroConfig config;

  /// Loading state (např. při načítání historie)
  final bool isLoading;

  /// Chybová zpráva (null = žádná chyba)
  final String? errorMessage;

  const PomodoroState({
    this.timerState = TimerState.idle,
    this.currentTaskId,
    this.remainingTime = const Duration(minutes: 25),
    this.totalDuration = const Duration(minutes: 25),
    this.sessionCount = 0,
    this.currentSession,
    this.history = const [],
    this.config = const PomodoroConfig(),
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        timerState,
        currentTaskId,
        remainingTime,
        totalDuration,
        sessionCount,
        currentSession,
        history,
        config,
        isLoading,
        errorMessage,
      ];

  /// Immutable copyWith pro state updates
  PomodoroState copyWith({
    TimerState? timerState,
    int? currentTaskId,
    Duration? remainingTime,
    Duration? totalDuration,
    int? sessionCount,
    PomodoroSession? currentSession,
    List<PomodoroSession>? history,
    PomodoroConfig? config,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PomodoroState(
      timerState: timerState ?? this.timerState,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      remainingTime: remainingTime ?? this.remainingTime,
      totalDuration: totalDuration ?? this.totalDuration,
      sessionCount: sessionCount ?? this.sessionCount,
      currentSession: currentSession ?? this.currentSession,
      history: history ?? this.history,
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  /// Helper: Je nějaký timer aktivní? (běží nebo pozastaven)
  bool get isTimerActive =>
      timerState == TimerState.running || timerState == TimerState.paused;

  /// Helper: Formátovaný zbývající čas (MM:SS)
  String get formattedRemainingTime {
    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Helper: Procento dokončení (0.0 - 1.0)
  double get progress {
    if (totalDuration.inSeconds == 0) return 0.0;
    final elapsed = totalDuration.inSeconds - remainingTime.inSeconds;
    return elapsed / totalDuration.inSeconds;
  }

  /// Helper: Je to přestávka?
  bool get isBreak => timerState == TimerState.break_;
}
