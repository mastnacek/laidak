import 'package:equatable/equatable.dart';

/// Konfigurace AI Brief generování
///
/// Obsahuje nastavení pro:
/// - Jaký kontext posílat AI (subtasks, pomodoro stats)
/// - Parametry AI modelu (temperature, max tokens)
class BriefConfig extends Equatable {
  /// Zahrnout statistiky subtasků do kontextu (výchozí: true)
  final bool includeSubtasks;

  /// Zahrnout Pomodoro statistiky do kontextu (výchozí: true)
  final bool includePomodoroStats;

  /// AI temperature (0.0-1.0, výchozí: 0.3)
  /// 0.3 = více konzervativní odpovědi (pro prioritizaci úkolů)
  final double temperature;

  /// Max tokens pro AI odpověď (výchozí: 500)
  final int maxTokens;

  const BriefConfig({
    this.includeSubtasks = true,
    this.includePomodoroStats = true,
    this.temperature = 0.3,
    this.maxTokens = 500,
  });

  /// Vytvoří kopii s upravenými hodnotami
  BriefConfig copyWith({
    bool? includeSubtasks,
    bool? includePomodoroStats,
    double? temperature,
    int? maxTokens,
  }) {
    return BriefConfig(
      includeSubtasks: includeSubtasks ?? this.includeSubtasks,
      includePomodoroStats: includePomodoroStats ?? this.includePomodoroStats,
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
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 500,
    );
  }

  /// Převede BriefConfig do JSON (pro uložení do storage)
  Map<String, dynamic> toJson() {
    return {
      'includeSubtasks': includeSubtasks,
      'includePomodoroStats': includePomodoroStats,
      'temperature': temperature,
      'maxTokens': maxTokens,
    };
  }

  @override
  List<Object?> get props => [
        includeSubtasks,
        includePomodoroStats,
        temperature,
        maxTokens,
      ];

  @override
  String toString() {
    return 'BriefConfig(includeSubtasks: $includeSubtasks, includePomodoroStats: $includePomodoroStats, temperature: $temperature, maxTokens: $maxTokens)';
  }
}
