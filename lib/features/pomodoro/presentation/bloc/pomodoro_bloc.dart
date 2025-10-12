import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pomodoro_session.dart';
import '../../domain/entities/timer_state.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../../domain/services/pomodoro_timer_service.dart';
import 'pomodoro_event.dart';
import 'pomodoro_state.dart';

/// BLoC pro Pomodoro Timer feature
///
/// Zodpovědnosti:
/// - State management pro Pomodoro timer
/// - Integrace s PomodoroTimerService (Isolate timer)
/// - Persistence do DB přes PomodoroRepository
/// - Business logika pro Pomodoro workflow
class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  final PomodoroRepository _repository;
  final PomodoroTimerService _timerService;

  /// Subscription na timer tick events
  StreamSubscription<Duration>? _timerSubscription;

  PomodoroBloc({
    required PomodoroRepository repository,
    required PomodoroTimerService timerService,
  })  : _repository = repository,
        _timerService = timerService,
        super(const PomodoroState()) {
    // Registrovat event handlery
    on<StartPomodoroEvent>(_onStartPomodoro);
    on<PausePomodoroEvent>(_onPausePomodoro);
    on<ResumePomodoroEvent>(_onResumePomodoro);
    on<StopPomodoroEvent>(_onStopPomodoro);
    on<TimerTickEvent>(_onTimerTick);
    on<TimerCompleteEvent>(_onTimerComplete);
    on<StartBreakEvent>(_onStartBreak);
    on<ContinuePomodoroEvent>(_onContinuePomodoro);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<UpdateConfigEvent>(_onUpdateConfig);
    on<FinishTaskEvent>(_onFinishTask);
  }

  /// Handler: Spustit nové Pomodoro
  Future<void> _onStartPomodoro(
    StartPomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    // Fail Fast validace
    if (state.isTimerActive) {
      emit(state.copyWith(
        errorMessage: 'Timer již běží! Nejdřív zastavte současný timer.',
      ));
      return;
    }

    final duration = event.customDuration ?? state.config.workDuration;
    final now = DateTime.now();

    // Vytvořit novou session v DB
    final session = PomodoroSession(
      taskId: event.taskId,
      startedAt: now,
      duration: duration,
      completed: false,
      isBreak: false,
    );

    try {
      // Uložit session do DB
      final savedSession = await _repository.createSession(session);

      // Načíst počet sessions pro tento úkol
      final completedCount = await _repository.getCompletedSessionCount(event.taskId);

      emit(state.copyWith(
        timerState: TimerState.running,
        currentTaskId: event.taskId,
        remainingTime: duration,
        totalDuration: duration,
        currentSession: savedSession,
        sessionCount: completedCount,
        errorMessage: null, // Clear chybu
      ));

      // Spustit isolate timer
      await _timerService.start(duration);

      // Subscribe na tick events
      _timerSubscription = _timerService.tickStream.listen(
        (remaining) {
          if (remaining == Duration.zero) {
            add(const TimerCompleteEvent());
          } else {
            add(TimerTickEvent(remaining));
          }
        },
        onError: (error) {
          add(StopPomodoroEvent()); // Zastavit při chybě
        },
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nelze spustit Pomodoro: $e',
      ));
    }
  }

  /// Handler: Pozastavit běžící Pomodoro
  Future<void> _onPausePomodoro(
    PausePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.timerState != TimerState.running) return;

    _timerService.pause();

    emit(state.copyWith(
      timerState: TimerState.paused,
    ));
  }

  /// Handler: Obnovit pozastavené Pomodoro
  Future<void> _onResumePomodoro(
    ResumePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.timerState != TimerState.paused) return;

    _timerService.resume();

    emit(state.copyWith(
      timerState: TimerState.running,
    ));
  }

  /// Handler: Zastavit běžící Pomodoro (přerušit)
  Future<void> _onStopPomodoro(
    StopPomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    _timerService.stop();
    await _timerSubscription?.cancel();
    _timerSubscription = null;

    // Update session v DB jako incomplete
    if (state.currentSession != null) {
      final now = DateTime.now();
      final elapsed = now.difference(state.currentSession!.startedAt);

      await _repository.updateSession(
        state.currentSession!.copyWith(
          endedAt: now,
          actualDuration: elapsed,
          completed: false, // Přerušeno
        ),
      );
    }

    emit(state.copyWith(
      timerState: TimerState.idle,
      currentTaskId: null,
      currentSession: null,
      remainingTime: state.config.workDuration, // Reset na default
      errorMessage: null,
    ));

    // Auto-refresh historie
    add(const LoadHistoryEvent());
  }

  /// Handler: Timer tick (každou sekundu)
  void _onTimerTick(
    TimerTickEvent event,
    Emitter<PomodoroState> emit,
  ) {
    emit(state.copyWith(
      remainingTime: event.remainingTime,
    ));
  }

  /// Handler: Timer dokončen (0:00)
  Future<void> _onTimerComplete(
    TimerCompleteEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    _timerService.stop();
    await _timerSubscription?.cancel();
    _timerSubscription = null;

    // Update session jako completed
    if (state.currentSession != null) {
      final now = DateTime.now();

      await _repository.updateSession(
        state.currentSession!.copyWith(
          endedAt: now,
          actualDuration: state.totalDuration, // Celá délka
          completed: true,
        ),
      );
    }

    final newCount = state.sessionCount + 1;

    // TODO: Play sound (pokud enabled v config)
    // TODO: Show notification "Pomodoro Complete!"

    // Auto-refresh historie
    add(const LoadHistoryEvent());

    // Auto-start break?
    if (state.config.autoStartBreak) {
      add(const StartBreakEvent());
    } else {
      emit(state.copyWith(
        timerState: TimerState.idle,
        sessionCount: newCount,
        remainingTime: state.config.workDuration,
        currentSession: null,
      ));
    }
  }

  /// Handler: Spustit přestávku
  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    final duration = state.config.breakDuration;
    final now = DateTime.now();

    // Vytvořit break session (pokud chceme trackovat v DB)
    // Pro jednoduchost V1: break není v DB, pouze UI state
    emit(state.copyWith(
      timerState: TimerState.break_,
      remainingTime: duration,
      totalDuration: duration,
    ));

    await _timerService.start(duration);

    _timerSubscription = _timerService.tickStream.listen(
      (remaining) {
        if (remaining == Duration.zero) {
          _onBreakComplete(emit);
        } else {
          add(TimerTickEvent(remaining));
        }
      },
    );
  }

  /// Break dokončen (privátní helper)
  void _onBreakComplete(Emitter<PomodoroState> emit) {
    _timerService.stop();
    _timerSubscription?.cancel();
    _timerSubscription = null;

    // TODO: Play sound

    emit(state.copyWith(
      timerState: TimerState.idle,
      remainingTime: state.config.workDuration,
    ));
  }

  /// Handler: Pokračovat v Pomodoro (další session na stejný úkol)
  Future<void> _onContinuePomodoro(
    ContinuePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.currentTaskId == null) {
      emit(state.copyWith(errorMessage: 'Žádný úkol k pokračování'));
      return;
    }

    // Re-use StartPomodoroEvent
    add(StartPomodoroEvent(
      state.currentTaskId!,
      event.customDuration,
    ));
  }

  /// Handler: Načíst historii sessions
  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final history = event.taskId != null
          ? await _repository.getSessionsByTask(event.taskId!)
          : await _repository.getTodaySessions();

      emit(state.copyWith(
        history: history,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nelze načíst historii: $e',
        isLoading: false,
      ));
    }
  }

  /// Handler: Aktualizovat konfiguraci
  Future<void> _onUpdateConfig(
    UpdateConfigEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    try {
      // Save config do SharedPreferences
      await _repository.saveConfig(event.config);

      emit(state.copyWith(
        config: event.config,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nelze uložit konfiguraci: $e',
      ));
    }
  }

  /// Handler: Ukončit práci na úkolu (vyčistit currentTaskId)
  void _onFinishTask(
    FinishTaskEvent event,
    Emitter<PomodoroState> emit,
  ) {
    // Fail Fast validace
    if (state.isTimerActive) {
      emit(state.copyWith(
        errorMessage: 'Nejdřív zastavte běžící timer!',
      ));
      return;
    }

    // Vyčistit currentTaskId a sessionCount
    emit(state.copyWith(
      currentTaskId: null,
      sessionCount: 0,
      errorMessage: null,
    ));
  }

  /// Cleanup při dispose
  @override
  Future<void> close() {
    _timerService.stop();
    _timerSubscription?.cancel();
    return super.close();
  }
}
