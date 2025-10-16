import 'package:equatable/equatable.dart';

/// State pro AI motivaci
///
/// Sealed class pro type-safe pattern matching.
sealed class MotivationState extends Equatable {
  const MotivationState();

  @override
  List<Object?> get props => [];
}

/// Počáteční stav
final class MotivationInitial extends MotivationState {
  const MotivationInitial();
}

/// Načítání motivace z AI
final class MotivationLoading extends MotivationState {
  const MotivationLoading();
}

/// Motivace úspěšně načtena
final class MotivationSuccess extends MotivationState {
  final String message;

  const MotivationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Chyba při načítání motivace
final class MotivationError extends MotivationState {
  final String error;

  const MotivationError(this.error);

  @override
  List<Object?> get props => [error];
}
