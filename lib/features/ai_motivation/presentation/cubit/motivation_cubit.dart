import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/motivation_repository.dart';
import 'motivation_state.dart';

/// Cubit pro AI motivaci
///
/// Jednoduchý Cubit pro one-shot motivační zprávy.
/// Metoda fetchMotivation() vrací Future<String> pro přímé použití v UI.
class MotivationCubit extends Cubit<MotivationState> {
  final MotivationRepository _repository;

  MotivationCubit(this._repository) : super(const MotivationInitial());

  /// Získat motivaci pro úkol
  ///
  /// Vrací motivační zprávu nebo vyhodí exception při chybě.
  /// Současně emituje states pro debugging/logging.
  Future<String> fetchMotivation({
    required String taskText,
    String? priority,
    List<String>? tags,
  }) async {
    try {
      // Emitovat loading state
      emit(const MotivationLoading());

      // Zavolat repository
      final message = await _repository.getMotivation(
        taskText: taskText,
        priority: priority,
        tags: tags,
      );

      // Emitovat success state
      emit(MotivationSuccess(message));

      return message;
    } catch (e) {
      // Emitovat error state
      final errorMessage = e.toString();
      emit(MotivationError(errorMessage));

      // Re-throw pro UI handling
      rethrow;
    }
  }

  /// Reset do počátečního stavu
  void reset() {
    emit(const MotivationInitial());
  }
}
