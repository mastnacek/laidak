import 'package:equatable/equatable.dart';

/// Sealed class pro všechny Pomodoro eventy
sealed class PomodoroEvent extends Equatable {
  const PomodoroEvent();
}

/// Spustit nové Pomodoro pro daný úkol
class StartPomodoroEvent extends PomodoroEvent {
  final int taskId;
  final Duration? customDuration; // Null = použij config.workDuration

  const StartPomodoroEvent(this.taskId, [this.customDuration]);

  @override
  List<Object?> get props => [taskId, customDuration];
}

/// Pozastavit běžící Pomodoro
class PausePomodoroEvent extends PomodoroEvent {
  const PausePomodoroEvent();

  @override
  List<Object?> get props => [];
}

/// Obnovit pozastavené Pomodoro
class ResumePomodoroEvent extends PomodoroEvent {
  const ResumePomodoroEvent();

  @override
  List<Object?> get props => [];
}

/// Zastavit běžící Pomodoro (přerušit)
class StopPomodoroEvent extends PomodoroEvent {
  const StopPomodoroEvent();

  @override
  List<Object?> get props => [];
}

/// Timer tick event - emitován každou sekundu z TimerService
class TimerTickEvent extends PomodoroEvent {
  final Duration remainingTime;

  const TimerTickEvent(this.remainingTime);

  @override
  List<Object?> get props => [remainingTime];
}

/// Timer dokončen - emitován když zbývá 0:00
class TimerCompleteEvent extends PomodoroEvent {
  const TimerCompleteEvent();

  @override
  List<Object?> get props => [];
}

/// Spustit přestávku (break)
class StartBreakEvent extends PomodoroEvent {
  const StartBreakEvent();

  @override
  List<Object?> get props => [];
}

/// Pokračovat v Pomodoro na stejný úkol (další session)
class ContinuePomodoroEvent extends PomodoroEvent {
  final Duration? customDuration;

  const ContinuePomodoroEvent([this.customDuration]);

  @override
  List<Object?> get props => [customDuration];
}

/// Načíst historii sessions
class LoadHistoryEvent extends PomodoroEvent {
  final int? taskId; // Null = všechny sessions

  const LoadHistoryEvent([this.taskId]);

  @override
  List<Object?> get props => [taskId];
}

/// Aktualizovat konfiguraci (workDuration, breakDuration, etc.)
class UpdateConfigEvent extends PomodoroEvent {
  final dynamic config; // PomodoroConfig

  const UpdateConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}

/// Ukončit práci na úkolu (vyčistit currentTaskId)
class FinishTaskEvent extends PomodoroEvent {
  const FinishTaskEvent();

  @override
  List<Object?> get props => [];
}
