import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/models/agenda_view_config.dart';
import '../../../notes/domain/models/notes_view_config.dart';
import '../../../markdown_export/domain/entities/export_config.dart';
import '../../../../core/models/provider_route.dart';

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

  /// Model pro reward (pranky + dobré skutky)
  final String aiRewardModel;

  /// Teplota pro reward (0.0-2.0)
  final double aiRewardTemperature;

  /// Max tokens pro reward
  final int aiRewardMaxTokens;

  /// Model pro AI tag suggestions
  final String aiTagSuggestionsModel;

  /// Teplota pro tag suggestions (0.0-2.0)
  final double aiTagSuggestionsTemperature;

  /// Max tokens pro tag suggestions
  final int aiTagSuggestionsMaxTokens;

  /// Seed pro reproducibility (optional)
  final int? aiTagSuggestionsSeed;

  /// Top-P nucleus sampling (optional, 0.0-1.0)
  final double? aiTagSuggestionsTopP;

  /// Debounce delay v milisekundách (default 500ms)
  final int aiTagSuggestionsDebounceMs;

  // --- OpenRouter Provider Routing & Caching ---
  /// Provider route pro motivation model
  final ProviderRoute aiMotivationProviderRoute;

  /// Enable caching pro motivation model
  final bool aiMotivationEnableCache;

  /// Provider route pro task model
  final ProviderRoute aiTaskProviderRoute;

  /// Enable caching pro task model
  final bool aiTaskEnableCache;

  /// Provider route pro reward model
  final ProviderRoute aiRewardProviderRoute;

  /// Enable caching pro reward model
  final bool aiRewardEnableCache;

  /// Provider route pro tag suggestions model
  final ProviderRoute aiTagSuggestionsProviderRoute;

  /// Enable caching pro tag suggestions model
  final bool aiTagSuggestionsEnableCache;

  // --- Markdown Export Settings ---
  /// Konfigurace pro markdown export
  final ExportConfig exportConfig;

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
    this.aiRewardModel = 'anthropic/claude-3.5-sonnet',
    this.aiRewardTemperature = 0.9,
    this.aiRewardMaxTokens = 1000,
    this.aiTagSuggestionsModel = 'anthropic/claude-3.5-haiku',
    this.aiTagSuggestionsTemperature = 1.0,
    this.aiTagSuggestionsMaxTokens = 500,
    this.aiTagSuggestionsSeed,
    this.aiTagSuggestionsTopP,
    this.aiTagSuggestionsDebounceMs = 500,
    this.aiMotivationProviderRoute = ProviderRoute.default_,
    this.aiMotivationEnableCache = true,
    this.aiTaskProviderRoute = ProviderRoute.floor,
    this.aiTaskEnableCache = true,
    this.aiRewardProviderRoute = ProviderRoute.default_,
    this.aiRewardEnableCache = true,
    this.aiTagSuggestionsProviderRoute = ProviderRoute.floor,
    this.aiTagSuggestionsEnableCache = true,
    ExportConfig? exportConfig,
  })  : agendaConfig = agendaConfig ?? const AgendaViewConfig(),
        notesConfig = notesConfig ?? const NotesViewConfig(),
        exportConfig = exportConfig ?? const ExportConfig.initial();

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
    String? aiRewardModel,
    double? aiRewardTemperature,
    int? aiRewardMaxTokens,
    String? aiTagSuggestionsModel,
    double? aiTagSuggestionsTemperature,
    int? aiTagSuggestionsMaxTokens,
    int? aiTagSuggestionsSeed,
    double? aiTagSuggestionsTopP,
    int? aiTagSuggestionsDebounceMs,
    ProviderRoute? aiMotivationProviderRoute,
    bool? aiMotivationEnableCache,
    ProviderRoute? aiTaskProviderRoute,
    bool? aiTaskEnableCache,
    ProviderRoute? aiRewardProviderRoute,
    bool? aiRewardEnableCache,
    ProviderRoute? aiTagSuggestionsProviderRoute,
    bool? aiTagSuggestionsEnableCache,
    ExportConfig? exportConfig,
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
      aiRewardModel: aiRewardModel ?? this.aiRewardModel,
      aiRewardTemperature: aiRewardTemperature ?? this.aiRewardTemperature,
      aiRewardMaxTokens: aiRewardMaxTokens ?? this.aiRewardMaxTokens,
      aiTagSuggestionsModel: aiTagSuggestionsModel ?? this.aiTagSuggestionsModel,
      aiTagSuggestionsTemperature: aiTagSuggestionsTemperature ?? this.aiTagSuggestionsTemperature,
      aiTagSuggestionsMaxTokens: aiTagSuggestionsMaxTokens ?? this.aiTagSuggestionsMaxTokens,
      aiTagSuggestionsSeed: aiTagSuggestionsSeed ?? this.aiTagSuggestionsSeed,
      aiTagSuggestionsTopP: aiTagSuggestionsTopP ?? this.aiTagSuggestionsTopP,
      aiTagSuggestionsDebounceMs: aiTagSuggestionsDebounceMs ?? this.aiTagSuggestionsDebounceMs,
      aiMotivationProviderRoute: aiMotivationProviderRoute ?? this.aiMotivationProviderRoute,
      aiMotivationEnableCache: aiMotivationEnableCache ?? this.aiMotivationEnableCache,
      aiTaskProviderRoute: aiTaskProviderRoute ?? this.aiTaskProviderRoute,
      aiTaskEnableCache: aiTaskEnableCache ?? this.aiTaskEnableCache,
      aiRewardProviderRoute: aiRewardProviderRoute ?? this.aiRewardProviderRoute,
      aiRewardEnableCache: aiRewardEnableCache ?? this.aiRewardEnableCache,
      aiTagSuggestionsProviderRoute: aiTagSuggestionsProviderRoute ?? this.aiTagSuggestionsProviderRoute,
      aiTagSuggestionsEnableCache: aiTagSuggestionsEnableCache ?? this.aiTagSuggestionsEnableCache,
      exportConfig: exportConfig ?? this.exportConfig,
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
        aiRewardModel,
        aiRewardTemperature,
        aiRewardMaxTokens,
        aiTagSuggestionsModel,
        aiTagSuggestionsTemperature,
        aiTagSuggestionsMaxTokens,
        aiTagSuggestionsSeed,
        aiTagSuggestionsTopP,
        aiTagSuggestionsDebounceMs,
        aiMotivationProviderRoute,
        aiMotivationEnableCache,
        aiTaskProviderRoute,
        aiTaskEnableCache,
        aiRewardProviderRoute,
        aiRewardEnableCache,
        aiTagSuggestionsProviderRoute,
        aiTagSuggestionsEnableCache,
        exportConfig,
      ];
}

/// Error state - chyba při načítání/ukládání nastavení
final class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
