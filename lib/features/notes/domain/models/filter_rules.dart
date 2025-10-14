import 'package:equatable/equatable.dart';

/// Typ filtru pro Smart Folder
enum FilterType {
  all,       // Všechny poznámky (žádný filtr)
  recent,    // Poslední X dní
  tags,      // Filtrování podle tagů (include/exclude)
  dateRange, // Custom date range (from-to)
}

/// Operátor pro kombinaci tagů
enum FilterOperator {
  and,  // Musí obsahovat VŠECHNY tagy (z include_tags)
  or,   // Musí obsahovat ALESPOŇ JEDEN tag (z include_tags)
}

/// Date range pro dateRange filter
class DateRange extends Equatable {
  final DateTime from;
  final DateTime to;

  const DateRange({
    required this.from,
    required this.to,
  });

  /// Vytvořit DateRange z JSON
  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
    );
  }

  /// Převést DateRange na JSON
  Map<String, dynamic> toJson() {
    return {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [from, to];

  @override
  String toString() => 'DateRange(from: $from, to: $to)';
}

/// Pravidla filtrování pro Smart Folder
///
/// Podporuje různé typy filtrů:
/// - all: žádný filtr (všechny poznámky)
/// - recent: poslední X dní
/// - tags: filtrování podle tagů (include/exclude + operator)
/// - dateRange: custom date range
class FilterRules extends Equatable {
  final FilterType type;
  final List<String> includeTags;   // Zobraz poznámky S těmito tagy
  final List<String> excludeTags;   // Nezobrazuj poznámky S těmito tagy
  final FilterOperator operator;    // AND = všechny tagy, OR = alespoň jeden tag
  final int? recentDays;            // Pro type=recent: počet dní
  final DateRange? dateRange;       // Pro type=dateRange: custom range

  const FilterRules({
    required this.type,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.operator = FilterOperator.and,
    this.recentDays,
    this.dateRange,
  });

  /// Vytvořit FilterRules z JSON
  factory FilterRules.fromJson(Map<String, dynamic> json) {
    return FilterRules(
      type: FilterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FilterType.all,
      ),
      includeTags: (json['include_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      excludeTags: (json['exclude_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      operator: json['operator'] != null
          ? FilterOperator.values.firstWhere(
              (e) => e.name == json['operator'],
              orElse: () => FilterOperator.and,
            )
          : FilterOperator.and,
      recentDays: json['recent_days'] as int?,
      dateRange: json['date_range'] != null
          ? DateRange.fromJson(json['date_range'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Převést FilterRules na JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'include_tags': includeTags,
      'exclude_tags': excludeTags,
      'operator': operator.name,
      'recent_days': recentDays,
      'date_range': dateRange?.toJson(),
    };
  }

  /// Vytvořit kopii s upravenými hodnotami
  FilterRules copyWith({
    FilterType? type,
    List<String>? includeTags,
    List<String>? excludeTags,
    FilterOperator? operator,
    int? recentDays,
    DateRange? dateRange,
  }) {
    return FilterRules(
      type: type ?? this.type,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
      operator: operator ?? this.operator,
      recentDays: recentDays ?? this.recentDays,
      dateRange: dateRange ?? this.dateRange,
    );
  }

  @override
  List<Object?> get props => [
        type,
        includeTags,
        excludeTags,
        operator,
        recentDays,
        dateRange,
      ];

  @override
  String toString() {
    return 'FilterRules(type: $type, includeTags: $includeTags, excludeTags: $excludeTags, operator: $operator, recentDays: $recentDays, dateRange: $dateRange)';
  }
}
