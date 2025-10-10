import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/models/agenda_view_config.dart';

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

  const SettingsLoaded({
    required this.selectedThemeId,
    required this.currentTheme,
    this.hasSeenGestureHint = false,
    AgendaViewConfig? agendaConfig,
  }) : agendaConfig = agendaConfig ?? const AgendaViewConfig();

  /// copyWith pro immutable updates
  SettingsLoaded copyWith({
    String? selectedThemeId,
    ThemeData? currentTheme,
    bool? hasSeenGestureHint,
    AgendaViewConfig? agendaConfig,
  }) {
    return SettingsLoaded(
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      currentTheme: currentTheme ?? this.currentTheme,
      hasSeenGestureHint: hasSeenGestureHint ?? this.hasSeenGestureHint,
      agendaConfig: agendaConfig ?? this.agendaConfig,
    );
  }

  @override
  List<Object?> get props => [selectedThemeId, currentTheme, hasSeenGestureHint, agendaConfig];
}

/// Error state - chyba při načítání/ukládání nastavení
final class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
