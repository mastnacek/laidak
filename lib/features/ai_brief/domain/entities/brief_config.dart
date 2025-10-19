import 'package:equatable/equatable.dart';

/// Konfigurace AI Brief generování
///
/// Obsahuje nastavení pro:
/// - Jaký kontext posílat AI (subtasks, pomodoro stats, completed tasks)
/// - Parametry AI modelu (temperature, max tokens)
class BriefConfig extends Equatable {
  /// Zahrnout statistiky subtasků do kontextu (výchozí: true)
  final bool includeSubtasks;

  /// Zahrnout Pomodoro statistiky do kontextu (výchozí: true)
  final bool includePomodoroStats;

  /// Zahrnout splněné úkoly z dnešního dne (výchozí: true)
  final bool includeCompletedToday;

  /// Zahrnout splněné úkoly za týden (výchozí: true)
  final bool includeCompletedWeek;

  /// Zahrnout splněné úkoly za měsíc (výchozí: false)
  final bool includeCompletedMonth;

  /// Zahrnout splněné úkoly za rok (výchozí: false)
  final bool includeCompletedYear;

  /// Zahrnout všechny splněné úkoly (výchozí: false)
  final bool includeCompletedAll;

  /// AI temperature (0.0-1.0, výchozí: 0.3)
  /// 0.3 = více konzervativní odpovědi (pro prioritizaci úkolů)
  final double temperature;

  /// Max tokens pro AI odpověď (výchozí: 2000)
  ///
  /// ⚠️ POZOR: Příliš nízká hodnota způsobí truncated JSON!
  /// - 500 tokens = často truncated (starý default)
  /// - 2000 tokens = safe pro většinu případů
  /// - 4000 tokens = pro velké Briefy (50+ úkolů)
  final int maxTokens;

  const BriefConfig({
    this.includeSubtasks = true,
    this.includePomodoroStats = true,
    this.includeCompletedToday = true,
    this.includeCompletedWeek = true,
    this.includeCompletedMonth = false,
    this.includeCompletedYear = false,
    this.includeCompletedAll = false,
    this.temperature = 0.3,
    this.maxTokens = 2000,
  });

  /// Vytvoří kopii s upravenými hodnotami
  BriefConfig copyWith({
    bool? includeSubtasks,
    bool? includePomodoroStats,
    bool? includeCompletedToday,
    bool? includeCompletedWeek,
    bool? includeCompletedMonth,
    bool? includeCompletedYear,
    bool? includeCompletedAll,
    double? temperature,
    int? maxTokens,
  }) {
    return BriefConfig(
      includeSubtasks: includeSubtasks ?? this.includeSubtasks,
      includePomodoroStats: includePomodoroStats ?? this.includePomodoroStats,
      includeCompletedToday: includeCompletedToday ?? this.includeCompletedToday,
      includeCompletedWeek: includeCompletedWeek ?? this.includeCompletedWeek,
      includeCompletedMonth: includeCompletedMonth ?? this.includeCompletedMonth,
      includeCompletedYear: includeCompletedYear ?? this.includeCompletedYear,
      includeCompletedAll: includeCompletedAll ?? this.includeCompletedAll,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  /// Výchozí konfigurace
  factory BriefConfig.defaultConfig() {
    return const BriefConfig();
  }

  /// Vytvoří BriefConfig z JSON (pro načtení ze storage)
  factory BriefConfig.fromJson(Map<String, dynamic> json) {
    return BriefConfig(
      includeSubtasks: json['includeSubtasks'] as bool? ?? true,
      includePomodoroStats: json['includePomodoroStats'] as bool? ?? true,
      includeCompletedToday: json['includeCompletedToday'] as bool? ?? true,
      includeCompletedWeek: json['includeCompletedWeek'] as bool? ?? true,
      includeCompletedMonth: json['includeCompletedMonth'] as bool? ?? false,
      includeCompletedYear: json['includeCompletedYear'] as bool? ?? false,
      includeCompletedAll: json['includeCompletedAll'] as bool? ?? false,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 2000,
    );
  }

  /// Převede BriefConfig do JSON (pro uložení do storage)
  Map<String, dynamic> toJson() {
    return {
      'includeSubtasks': includeSubtasks,
      'includePomodoroStats': includePomodoroStats,
      'includeCompletedToday': includeCompletedToday,
      'includeCompletedWeek': includeCompletedWeek,
      'includeCompletedMonth': includeCompletedMonth,
      'includeCompletedYear': includeCompletedYear,
      'includeCompletedAll': includeCompletedAll,
      'temperature': temperature,
      'maxTokens': maxTokens,
    };
  }

  @override
  List<Object?> get props => [
        includeSubtasks,
        includePomodoroStats,
        includeCompletedToday,
        includeCompletedWeek,
        includeCompletedMonth,
        includeCompletedYear,
        includeCompletedAll,
        temperature,
        maxTokens,
      ];

  @override
  String toString() {
    return 'BriefConfig(includeSubtasks: $includeSubtasks, includePomodoroStats: $includePomodoroStats, includeCompletedToday: $includeCompletedToday, includeCompletedWeek: $includeCompletedWeek, includeCompletedMonth: $includeCompletedMonth, includeCompletedYear: $includeCompletedYear, includeCompletedAll: $includeCompletedAll, temperature: $temperature, maxTokens: $maxTokens)';
  }
}
