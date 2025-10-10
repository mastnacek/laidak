import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

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

  const SettingsLoaded({
    required this.selectedThemeId,
    required this.currentTheme,
    this.hasSeenGestureHint = false,
  });

  /// copyWith pro immutable updates
  SettingsLoaded copyWith({
    String? selectedThemeId,
    ThemeData? currentTheme,
    bool? hasSeenGestureHint,
  }) {
    return SettingsLoaded(
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      currentTheme: currentTheme ?? this.currentTheme,
      hasSeenGestureHint: hasSeenGestureHint ?? this.hasSeenGestureHint,
    );
  }

  @override
  List<Object?> get props => [selectedThemeId, currentTheme, hasSeenGestureHint];
}

/// Error state - chyba při načítání/ukládání nastavení
final class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
