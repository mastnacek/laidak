import 'package:equatable/equatable.dart';

/// PomodoroConfig - Konfigurace Pomodoro timeru
///
/// Immutable entity obsahující nastavení pro Pomodoro timer.
/// Ukládáno v SharedPreferences (persistence mezi sessions).
///
/// Výchozí hodnoty:
/// - workDuration: 25 minut
/// - breakDuration: 5 minut
/// - autoStartBreak: false
/// - soundEnabled: true
class PomodoroConfig extends Equatable {
  /// Délka pracovní session (výchozí 25 min)
  final Duration workDuration;

  /// Délka přestávky (výchozí 5 min)
  final Duration breakDuration;

  /// Automaticky spustit přestávku po dokončení Pomodoro?
  final bool autoStartBreak;

  /// Přehrát zvuk při dokončení?
  final bool soundEnabled;

  /// Konstruktor s výchozími hodnotami
  const PomodoroConfig({
    this.workDuration = const Duration(minutes: 25),
    this.breakDuration = const Duration(minutes: 5),
    this.autoStartBreak = false,
    this.soundEnabled = true,
  });

  /// Výchozí konfigurace (factory constructor)
  factory PomodoroConfig.defaultConfig() => const PomodoroConfig();

  @override
  List<Object?> get props => [
        workDuration,
        breakDuration,
        autoStartBreak,
        soundEnabled,
      ];

  /// copyWith pro immutable updates
  PomodoroConfig copyWith({
    Duration? workDuration,
    Duration? breakDuration,
    bool? autoStartBreak,
    bool? soundEnabled,
  }) {
    return PomodoroConfig(
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  /// toJson pro serialization (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'work_duration_minutes': workDuration.inMinutes,
      'break_duration_minutes': breakDuration.inMinutes,
      'auto_start_break': autoStartBreak,
      'sound_enabled': soundEnabled,
    };
  }

  /// fromJson pro deserialization
  factory PomodoroConfig.fromJson(Map<String, dynamic> json) {
    return PomodoroConfig(
      workDuration: Duration(minutes: json['work_duration_minutes'] as int),
      breakDuration: Duration(minutes: json['break_duration_minutes'] as int),
      autoStartBreak: json['auto_start_break'] as bool,
      soundEnabled: json['sound_enabled'] as bool,
    );
  }

  @override
  String toString() {
    return 'PomodoroConfig(work: ${workDuration.inMinutes}min, '
        'break: ${breakDuration.inMinutes}min, '
        'autoBreak: $autoStartBreak, sound: $soundEnabled)';
  }
}
