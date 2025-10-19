import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../data/repositories/prank_repository.dart';
import 'prank_state.dart';

/// Cubit pro AI Prank generování
class PrankCubit extends Cubit<PrankState> {
  final PrankRepository _repository;

  PrankCubit(this._repository) : super(const PrankInitial());

  /// Vygenerovat prank tip po dokončení úkolu
  Future<void> generatePrank(Todo completedTodo) async {
    try {
      emit(const PrankLoading(isPrank: true));

      AppLogger.debug('═══════════════════════════════════════════');
      AppLogger.debug('🎭 PRANK CUBIT: generatePrank START');
      AppLogger.debug('    Todo: ${completedTodo.task}');
      AppLogger.debug('═══════════════════════════════════════════');

      final prankMessage = await _repository.generatePrank(
        completedTodo: completedTodo,
      );

      AppLogger.debug('✅ Prank vygenerován: ${prankMessage.substring(0, prankMessage.length > 50 ? 50 : prankMessage.length)}...');

      emit(PrankLoaded(prankMessage, completedTodo, isPrank: true)); // ✅ Předáváme todo + isPrank=true
      AppLogger.debug('🎭 PRANK CUBIT: generatePrank KONEC (SUCCESS)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při generování pranku', error: e, stackTrace: stackTrace);
      AppLogger.error('❌ Error type: ${e.runtimeType}');
      AppLogger.error('❌ Error toString: $e');

      // User-friendly error messages
      String errorMessage = 'Nepodařilo se vygenerovat prank tip';

      if (e is StateError) {
        errorMessage = e.message; // API klíč není nastaven
      } else if (e is ArgumentError) {
        errorMessage = e.message; // Validační chyby
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Chyba připojení k internetu';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout - zkus to znovu';
      }

      emit(PrankError(errorMessage));
    }
  }

  /// Vygenerovat good deed tip po dokončení úkolu
  Future<void> generateGoodDeed(Todo completedTodo) async {
    try {
      emit(const PrankLoading(isPrank: false));

      AppLogger.debug('═══════════════════════════════════════════');
      AppLogger.debug('💚 PRANK CUBIT: generateGoodDeed START');
      AppLogger.debug('    Todo: ${completedTodo.task}');
      AppLogger.debug('═══════════════════════════════════════════');

      final goodDeedMessage = await _repository.generateGoodDeed(
        completedTodo: completedTodo,
      );

      AppLogger.debug('✅ Good deed vygenerován: ${goodDeedMessage.substring(0, goodDeedMessage.length > 50 ? 50 : goodDeedMessage.length)}...');

      emit(PrankLoaded(goodDeedMessage, completedTodo, isPrank: false)); // ✅ Předáváme todo + isPrank=false
      AppLogger.debug('💚 PRANK CUBIT: generateGoodDeed KONEC (SUCCESS)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při generování good deed', error: e, stackTrace: stackTrace);
      AppLogger.error('❌ Error type: ${e.runtimeType}');
      AppLogger.error('❌ Error toString: $e');

      // User-friendly error messages
      String errorMessage = 'Nepodařilo se vygenerovat tip na dobrý skutek';

      if (e is StateError) {
        errorMessage = e.message; // API klíč není nastaven
      } else if (e is ArgumentError) {
        errorMessage = e.message; // Validační chyby
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Chyba připojení k internetu';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout - zkus to znovu';
      }

      emit(PrankError(errorMessage));
    }
  }

  /// Reset state zpět na initial
  void reset() {
    emit(const PrankInitial());
  }
}
