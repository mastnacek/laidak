/// TimerState - Stav Pomodoro timeru
///
/// Reprezentuje možné stavy timeru během Pomodoro session.
/// Používá se v PomodoroBloc pro řízení UI a business logiky.
enum TimerState {
  /// Timer nezačal - výchozí stav
  idle,

  /// Timer běží - odpočítává čas
  running,

  /// Timer pozastaven - čas zůstává stejný
  paused,

  /// Přestávka běží - 5 minut odpočítávání
  break_,
}

/// Extension pro TimerState - helper metody
extension TimerStateExtension on TimerState {
  /// Je timer aktivní? (běží nebo pozastaven, nikoliv idle)
  bool get isActive => this == TimerState.running || this == TimerState.paused;

  /// Je timer běžící? (nikoliv pozastaven)
  bool get isRunning => this == TimerState.running;

  /// Je timer pozastaven?
  bool get isPaused => this == TimerState.paused;

  /// Je přestávka?
  bool get isBreak => this == TimerState.break_;

  /// Je timer idle?
  bool get isIdle => this == TimerState.idle;

  /// Displayovatelný text pro UI
  String get displayName {
    switch (this) {
      case TimerState.idle:
        return 'Nepřipraveno';
      case TimerState.running:
        return 'Běží';
      case TimerState.paused:
        return 'Pozastaveno';
      case TimerState.break_:
        return 'Přestávka';
    }
  }

  /// Emoji ikona pro vizualizaci stavu
  String get emoji {
    switch (this) {
      case TimerState.idle:
        return '⏸️';
      case TimerState.running:
        return '▶️';
      case TimerState.paused:
        return '⏸️';
      case TimerState.break_:
        return '☕';
    }
  }
}
