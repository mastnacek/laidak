import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../cubit/prank_state.dart';

part 'prank_provider.g.dart';

/// Riverpod Notifier pro AI Prank generování
///
/// Nahrazuje původní PrankCubit
@riverpod
class Prank extends _$Prank {
  @override
  PrankState build() {
    return const PrankInitial();
  }

  /// Vygenerovat prank tip po dokončení úkolu
  Future<void> generatePrank(Todo completedTodo) async {
    try {
      state = const PrankLoading(isPrank: true);

      AppLogger.debug('═══════════════════════════════════════════');
      AppLogger.debug('🎭 PRANK PROVIDER: generatePrank START');
      AppLogger.debug('    Todo: ${completedTodo.task}');
      AppLogger.debug('═══════════════════════════════════════════');

      final prankMessage = await ref.read(prankRepositoryProvider).generatePrank(
        completedTodo: completedTodo,
      );

      AppLogger.debug('✅ Prank vygenerován: ${prankMessage.substring(0, prankMessage.length > 50 ? 50 : prankMessage.length)}...');

      state = PrankLoaded(prankMessage, completedTodo, isPrank: true);
      AppLogger.debug('🎭 PRANK PROVIDER: generatePrank KONEC (SUCCESS)');
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

      state = PrankError(errorMessage);
    }
  }

  /// Vygenerovat good deed tip po dokončení úkolu
  Future<void> generateGoodDeed(Todo completedTodo) async {
    try {
      state = const PrankLoading(isPrank: false);

      AppLogger.debug('═══════════════════════════════════════════');
      AppLogger.debug('💚 PRANK PROVIDER: generateGoodDeed START');
      AppLogger.debug('    Todo: ${completedTodo.task}');
      AppLogger.debug('═══════════════════════════════════════════');

      final goodDeedMessage = await ref.read(prankRepositoryProvider).generateGoodDeed(
        completedTodo: completedTodo,
      );

      AppLogger.debug('✅ Good deed vygenerován: ${goodDeedMessage.substring(0, goodDeedMessage.length > 50 ? 50 : goodDeedMessage.length)}...');

      state = PrankLoaded(goodDeedMessage, completedTodo, isPrank: false);
      AppLogger.debug('💚 PRANK PROVIDER: generateGoodDeed KONEC (SUCCESS)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Chyba při generování good deed', error: e, stackTrace: stackTrace);

      // User-friendly error messages
      String errorMessage = 'Nepodařilo se vygenerovat good deed';

      if (e is StateError) {
        errorMessage = e.message;
      } else if (e is ArgumentError) {
        errorMessage = e.message;
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Chyba připojení k internetu';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout - zkus to znovu';
      }

      state = PrankError(errorMessage);
    }
  }

  /// Reset do počátečního stavu
  void reset() {
    state = const PrankInitial();
  }
}
