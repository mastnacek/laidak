import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../cubit/motivation_state.dart';

part 'motivation_provider.g.dart';

/// Riverpod Notifier pro AI motivaci
///
/// Nahrazuje původní MotivationCubit
/// Jednoduchý Notifier pro one-shot motivační zprávy.
@riverpod
class Motivation extends _$Motivation {
  @override
  MotivationState build() {
    return const MotivationInitial();
  }

  /// Získat motivaci pro úkol
  ///
  /// Vrací motivační zprávu nebo vyhodí exception při chybě.
  Future<String> fetchMotivation({
    required String taskText,
    String? priority,
    List<String>? tags,
  }) async {
    try {
      // Emitovat loading state
      state = const MotivationLoading();

      // Zavolat repository
      final message = await ref.read(motivationRepositoryProvider).getMotivation(
        taskText: taskText,
        priority: priority,
        tags: tags,
      );

      // Emitovat success state
      state = MotivationSuccess(message);

      return message;
    } catch (e) {
      // Emitovat error state
      final errorMessage = e.toString();
      state = MotivationError(errorMessage);

      // Re-throw pro UI handling
      rethrow;
    }
  }

  /// Reset do počátečního stavu
  void reset() {
    state = const MotivationInitial();
  }
}
