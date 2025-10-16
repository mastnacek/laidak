import 'package:equatable/equatable.dart';

/// PomodoroSession - Entita reprezentující jednu Pomodoro session
///
/// Immutable domain entity pro Pomodoro session.
/// Ukládána v SQLite databázi (tabulka `pomodoro_sessions`).
///
/// Životní cyklus:
/// 1. Vytvořena při startu (completed = false, endedAt = null)
/// 2. Aktualizována při dokončení/přerušení (completed, endedAt, actualDuration)
///
/// Příklad:
/// ```dart
/// final session = PomodoroSession(
///   taskId: 5,
///   startedAt: DateTime.now(),
///   duration: Duration(minutes: 25),
///   completed: false,
/// );
/// ```
class PomodoroSession extends Equatable {
  /// ID session v databázi (null pro novou session)
  final int? id;

  /// ID úkolu z todos tabulky (FOREIGN KEY)
  final int taskId;

  /// Čas startu session
  final DateTime startedAt;

  /// Čas ukončení session (null pokud běží)
  final DateTime? endedAt;

  /// Plánovaná délka session (např. 25 min)
  final Duration duration;

  /// Skutečná délka session (pokud přerušeno před dokončením)
  /// Např. plánováno 25 min, ale přerušeno po 12 min → actualDuration = 12 min
  final Duration? actualDuration;

  /// Je session dokončena? (true = dokončena, false = přerušena)
  final bool completed;

  /// Je to přestávka? (true = break, false = work session)
  final bool isBreak;

  /// Konstruktor
  const PomodoroSession({
    this.id,
    required this.taskId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    this.actualDuration,
    required this.completed,
    this.isBreak = false,
  });

  @override
  List<Object?> get props => [
        id,
        taskId,
        startedAt,
        endedAt,
        duration,
        actualDuration,
        completed,
        isBreak,
      ];

  /// copyWith pro immutable updates
  PomodoroSession copyWith({
    int? id,
    int? taskId,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? duration,
    Duration? actualDuration,
    bool? completed,
    bool? isBreak,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      actualDuration: actualDuration ?? this.actualDuration,
      completed: completed ?? this.completed,
      isBreak: isBreak ?? this.isBreak,
    );
  }

  /// toMap pro SQLite serialization
  Map<String, dynamic> toMap() {
    final endedAtTimestamp = endedAt != null
        ? endedAt!.millisecondsSinceEpoch ~/ 1000
        : null;

    return {
      'id': id,
      'task_id': taskId,
      'started_at': startedAt.millisecondsSinceEpoch ~/ 1000, // Unix timestamp
      'ended_at': endedAtTimestamp,
      'duration': duration.inSeconds,
      'actual_duration': actualDuration?.inSeconds,
      'completed': completed ? 1 : 0, // SQLite boolean
      'is_break': isBreak ? 1 : 0,
    };
  }

  /// fromMap pro SQLite deserialization
  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['started_at'] as int) * 1000,
      ),
      endedAt: map['ended_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['ended_at'] as int) * 1000,
            )
          : null,
      duration: Duration(seconds: map['duration'] as int),
      actualDuration: map['actual_duration'] != null
          ? Duration(seconds: map['actual_duration'] as int)
          : null,
      completed: (map['completed'] as int) == 1,
      isBreak: (map['is_break'] as int) == 1,
    );
  }

  /// Je session aktivní? (běží, nikoliv dokončena)
  bool get isActive => endedAt == null;

  /// Byla session přerušena? (nedokončena)
  bool get wasInterrupted => !completed && endedAt != null;

  /// Zobrazitelná délka (actualDuration nebo duration)
  Duration get displayDuration => actualDuration ?? duration;

  /// Formátovaný čas startu (HH:mm)
  String get formattedStartTime {
    final hour = startedAt.hour.toString().padLeft(2, '0');
    final minute = startedAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formátovaná délka (MM:SS nebo MM min)
  String get formattedDuration {
    final dur = displayDuration;
    if (dur.inSeconds < 60) {
      return '${dur.inSeconds}s';
    }
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    if (seconds == 0) {
      return '$minutes min';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Status ikona (pro UI)
  String get statusIcon {
    if (isBreak) return '☕';
    if (completed) return '✅';
    if (wasInterrupted) return '⏸️';
    return '🍅';
  }

  @override
  String toString() {
    return 'PomodoroSession(id: $id, task: $taskId, '
        'started: $formattedStartTime, duration: $formattedDuration, '
        'completed: $completed, isBreak: $isBreak)';
  }
}
