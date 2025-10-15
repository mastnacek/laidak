import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/models/agenda_view_config.dart';
import '../../../notes/domain/models/notes_view_config.dart';

/// Immutable state pro Settings feature
///
/// Obsahuje vybrané téma a aktuální ThemeData
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state - před načtením nastavení
final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state - načítání nastavení z databáze
final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state - nastavení načtena
final class SettingsLoaded extends SettingsState {
  final String selectedThemeId;
  final ThemeData currentTheme;

  /// Zda uživatel už viděl gesture hint tooltip (pro onboarding)
  final bool hasSeenGestureHint;

  /// Konfigurace Agenda Views (built-in + custom views)
  final AgendaViewConfig agendaConfig;

  /// Konfigurace Notes Views (built-in + custom views)
  final NotesViewConfig notesConfig;

  // --- Tag Delimiters ---
  /// Počáteční oddělovač tagů (např. '*', '#', '@')
  final String tagDelimiterStart;

  /// Koncový oddělovač tagů (např. '*', '#', '@')
  final String tagDelimiterEnd;

  // --- AI Settings ---
  /// OpenRouter API klíč
  final String? openRouterApiKey;

  /// Model pro motivaci (uncensored, kreativní)
  final String aiMotivationModel;

  /// Teplota pro motivaci (0.0-2.0)
  final double aiMotivationTemperature;

  /// Max tokens pro motivaci
  final int aiMotivationMaxTokens;

  /// Model pro rozdělení úkolů (chytrý, JSON-ready)
  final String aiTaskModel;

  /// Teplota pro task rozdělení (0.0-2.0)
  final double aiTaskTemperature;

  /// Max tokens pro task rozdělení
  final int aiTaskMaxTokens;

  const SettingsLoaded({
    required this.selectedThemeId,
    required this.currentTheme,
    this.hasSeenGestureHint = false,
    AgendaViewConfig? agendaConfig,
    NotesViewConfig? notesConfig,
    this.tagDelimiterStart = '*',
    this.tagDelimiterEnd = '*',
    this.openRouterApiKey,
    this.aiMotivationModel = 'mistralai/mistral-medium',
    this.aiMotivationTemperature = 0.9,
    this.aiMotivationMaxTokens = 200,
    this.aiTaskModel = 'anthropic/claude-3.5-sonnet',
    this.aiTaskTemperature = 0.3,
    this.aiTaskMaxTokens = 1000,
  }) : agendaConfig = agendaConfig ?? const AgendaViewConfig(),
       notesConfig = notesConfig ?? const NotesViewConfig();

  /// copyWith pro immutable updates
  SettingsLoaded copyWith({
    String? selectedThemeId,
    ThemeData? currentTheme,
    bool? hasSeenGestureHint,
    AgendaViewConfig? agendaConfig,
    NotesViewConfig? notesConfig,
    String? tagDelimiterStart,
    String? tagDelimiterEnd,
    String? openRouterApiKey,
    String? aiMotivationModel,
    double? aiMotivationTemperature,
    int? aiMotivationMaxTokens,
    String? aiTaskModel,
    double? aiTaskTemperature,
    int? aiTaskMaxTokens,
  }) {
    return SettingsLoaded(
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      currentTheme: currentTheme ?? this.currentTheme,
      hasSeenGestureHint: hasSeenGestureHint ?? this.hasSeenGestureHint,
      agendaConfig: agendaConfig ?? this.agendaConfig,
      notesConfig: notesConfig ?? this.notesConfig,
      tagDelimiterStart: tagDelimiterStart ?? this.tagDelimiterStart,
      tagDelimiterEnd: tagDelimiterEnd ?? this.tagDelimiterEnd,
      openRouterApiKey: openRouterApiKey ?? this.openRouterApiKey,
      aiMotivationModel: aiMotivationModel ?? this.aiMotivationModel,
      aiMotivationTemperature: aiMotivationTemperature ?? this.aiMotivationTemperature,
      aiMotivationMaxTokens: aiMotivationMaxTokens ?? this.aiMotivationMaxTokens,
      aiTaskModel: aiTaskModel ?? this.aiTaskModel,
      aiTaskTemperature: aiTaskTemperature ?? this.aiTaskTemperature,
      aiTaskMaxTokens: aiTaskMaxTokens ?? this.aiTaskMaxTokens,
    );
  }

  @override
  List<Object?> get props => [
        selectedThemeId,
        currentTheme,
        hasSeenGestureHint,
        agendaConfig,
        notesConfig,
        tagDelimiterStart,
        tagDelimiterEnd,
        openRouterApiKey,
        aiMotivationModel,
        aiMotivationTemperature,
        aiMotivationMaxTokens,
        aiTaskModel,
        aiTaskTemperature,
        aiTaskMaxTokens,
      ];
}

/// Error state - chyba při načítání/ukládání nastavení
final class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
