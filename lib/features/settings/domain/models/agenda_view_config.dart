import 'package:equatable/equatable.dart';
import 'custom_agenda_view.dart';

/// Konfigurace Agenda Views (built-in + custom)
///
/// Obsahuje nastavení, které built-in views jsou viditelné,
/// a seznam custom views vytvořených uživatelem.
class AgendaViewConfig extends Equatable {
  /// Built-in views (enable/disable)
  final bool showAll;
  final bool showToday;
  final bool showWeek;
  final bool showUpcoming;
  final bool showOverdue;

  /// Custom views (tag-based filters)
  final List<CustomAgendaView> customViews;

  const AgendaViewConfig({
    this.showAll = true,
    this.showToday = true,
    this.showWeek = true,
    this.showUpcoming = false,
    this.showOverdue = true,
    this.customViews = const [],
  });

  /// Default config (pro first launch)
  factory AgendaViewConfig.defaultConfig() {
    return const AgendaViewConfig(
      showAll: true,
      showToday: true,
      showWeek: true,
      showUpcoming: false,
      showOverdue: true,
      customViews: [],
    );
  }

  /// CopyWith pro immutable updates
  AgendaViewConfig copyWith({
    bool? showAll,
    bool? showToday,
    bool? showWeek,
    bool? showUpcoming,
    bool? showOverdue,
    List<CustomAgendaView>? customViews,
  }) {
    return AgendaViewConfig(
      showAll: showAll ?? this.showAll,
      showToday: showToday ?? this.showToday,
      showWeek: showWeek ?? this.showWeek,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      showOverdue: showOverdue ?? this.showOverdue,
      customViews: customViews ?? this.customViews,
    );
  }

  /// Serialization pro SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'showAll': showAll,
      'showToday': showToday,
      'showWeek': showWeek,
      'showUpcoming': showUpcoming,
      'showOverdue': showOverdue,
      'customViews': customViews.map((v) => v.toJson()).toList(),
    };
  }

  /// Deserialization z JSON
  factory AgendaViewConfig.fromJson(Map<String, dynamic> json) {
    return AgendaViewConfig(
      showAll: json['showAll'] as bool? ?? true,
      showToday: json['showToday'] as bool? ?? true,
      showWeek: json['showWeek'] as bool? ?? true,
      showUpcoming: json['showUpcoming'] as bool? ?? false,
      showOverdue: json['showOverdue'] as bool? ?? true,
      customViews: (json['customViews'] as List<dynamic>?)
              ?.map((v) => CustomAgendaView.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        showAll,
        showToday,
        showWeek,
        showUpcoming,
        showOverdue,
        customViews,
      ];
}
