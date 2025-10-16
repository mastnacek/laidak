import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/app_logger.dart';

/// Globální observer pro všechny BLoC/Cubit instance
///
/// **Funkce:**
/// - Loguje všechny změny stavů (onChange)
/// - Loguje všechny události (onEvent) - pouze pro Bloc
/// - Loguje všechny transitions (onTransition) - pouze pro Bloc
/// - Loguje errory (onError)
/// - Loguje lifecycle events (onCreate, onClose)
///
/// **Registrace:**
/// ```dart
/// void main() {
///   Bloc.observer = SimpleBlocObserver();
///   runApp(MyApp());
/// }
/// ```
///
/// **Output Example:**
/// ```
/// 🟢 BLoC Created: TodoListBloc
/// ⚡ BLoC Event: TodoListBloc
///    Event: LoadTodosEvent
/// 🔀 BLoC Transition: TodoListBloc
///    Event: LoadTodosEvent
///    Current: TodoListInitial
///    Next: TodoListLoading
/// 🔄 BLoC Change: TodoListBloc
///    Current: TodoListInitial
///    Next: TodoListLoading
/// ```
class SimpleBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    AppLogger.debug('🟢 BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    AppLogger.debug(
      '🔄 BLoC Change: ${bloc.runtimeType}\n'
      '   Current: ${change.currentState.runtimeType}\n'
      '   Next: ${change.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      '🔴 BLoC Error: ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    AppLogger.debug('🔵 BLoC Closed: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.debug(
      '⚡ BLoC Event: ${bloc.runtimeType}\n'
      '   Event: ${event.runtimeType}',
    );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    // Detailnější logging pro Bloc transitions
    // (Cubit nemá transitions, pouze onChange)
    AppLogger.debug(
      '🔀 BLoC Transition: ${bloc.runtimeType}\n'
      '   Event: ${transition.event.runtimeType}\n'
      '   Current: ${transition.currentState.runtimeType}\n'
      '   Next: ${transition.nextState.runtimeType}',
    );
  }
}
