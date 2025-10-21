import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../utils/app_logger.dart';
import '../cubit/connectivity_state.dart';

part 'connectivity_provider.g.dart';

/// Provider pro Connectivity instance
final connectivityInstanceProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider pro InternetConnection instance
final internetConnectionProvider = Provider<InternetConnection>((ref) {
  return InternetConnection();
});

/// Riverpod StreamNotifier pro monitoring síťového připojení
///
/// Nahrazuje původní ConnectivityCubit
/// Kombinuje:
/// - connectivity_plus: detekce typu sítě (WiFi/mobile)
/// - internet_connection_checker_plus: validace skutečného internet přístupu
@riverpod
class ConnectivityMonitor extends _$ConnectivityMonitor {
  late Connectivity _connectivity;
  late InternetConnection _internetChecker;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  @override
  Stream<ConnectivityState> build() {
    _connectivity = ref.watch(connectivityInstanceProvider);
    _internetChecker = ref.watch(internetConnectionProvider);

    // Cleanup při dispose
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _internetSubscription?.cancel();
    });

    // Return stream that emits connectivity states
    return _createConnectivityStream();
  }

  /// Vytvoří stream který kombinuje connectivity + internet status
  Stream<ConnectivityState> _createConnectivityStream() async* {
    // Emit initial checking state
    yield const ConnectivityChecking();

    // Provést initial check
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasInternet = await _internetChecker.hasInternetAccess;

      if (hasInternet) {
        final connectionType = _getConnectionType(connectivityResults);
        yield ConnectivityConnected(connectionType);
        AppLogger.debug('✅ Připojeno k internetu přes $connectionType');
      } else {
        yield const ConnectivityDisconnected();
        AppLogger.debug('❌ Žádné připojení k internetu');
      }
    } catch (e) {
      AppLogger.error('❌ Chyba při kontrole připojení', error: e);
      yield const ConnectivityDisconnected();
    }

    // Poslouchat změny - yield new states when connectivity changes
    await for (final _ in _connectivity.onConnectivityChanged) {
      try {
        yield const ConnectivityChecking();

        final connectivityResults = await _connectivity.checkConnectivity();
        final hasInternet = await _internetChecker.hasInternetAccess;

        if (hasInternet) {
          final connectionType = _getConnectionType(connectivityResults);
          yield ConnectivityConnected(connectionType);
          AppLogger.debug('✅ Připojeno k internetu přes $connectionType');
        } else {
          yield const ConnectivityDisconnected();
          AppLogger.debug('❌ Žádné připojení k internetu');
        }
      } catch (e) {
        AppLogger.error('❌ Chyba při kontrole připojení', error: e);
        yield const ConnectivityDisconnected();
      }
    }
  }

  /// Získat lidsky čitelný typ připojení
  String _getConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty) return 'unknown';

    // Android 12+ podporuje multiple simultaneous connections
    // Priorita: WiFi > mobile > other
    if (results.contains(ConnectivityResult.wifi)) {
      return 'wifi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'mobile';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    } else {
      return 'other';
    }
  }

  /// Provést manuální refresh připojení
  Future<void> checkConnectivity() async {
    // Refresh stream by invalidating the provider
    ref.invalidateSelf();
  }
}

/// Helper provider: je zařízení připojeno k internetu?
@riverpod
bool isConnected(IsConnectedRef ref) {
  final connectivityState = ref.watch(connectivityMonitorProvider);
  return connectivityState.maybeWhen(
    data: (state) => state is ConnectivityConnected,
    orElse: () => false,
  );
}

/// Helper provider: typ připojení (pokud připojeno)
@riverpod
String? connectionType(ConnectionTypeRef ref) {
  final connectivityState = ref.watch(connectivityMonitorProvider);
  return connectivityState.maybeWhen(
    data: (state) {
      if (state is ConnectivityConnected) {
        return state.connectionType;
      }
      return null;
    },
    orElse: () => null,
  );
}
