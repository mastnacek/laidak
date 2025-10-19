import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../utils/app_logger.dart';
import 'connectivity_state.dart';

/// Cubit pro monitoring síťového připojení
///
/// Kombinuje:
/// - connectivity_plus: detekce typu sítě (WiFi/mobile)
/// - internet_connection_checker_plus: validace skutečného internet přístupu
///
/// Best practices:
/// - Nikdy nepředpokládej internet z connectivity alone (captive portal problem)
/// - Vždy validuj skutečné připojení před API cally
/// - Poslouchej změny connectivity v real-time
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity;
  final InternetConnection _internetChecker;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  ConnectivityCubit({
    Connectivity? connectivity,
    InternetConnection? internetChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetChecker = internetChecker ?? InternetConnection(),
        super(const ConnectivityInitial()) {
    // Spustit initial check
    checkConnectivity();

    // Poslouchat změny connectivity
    _startListening();
  }

  /// Provést jednorázovou kontrolu připojení
  Future<void> checkConnectivity() async {
    emit(const ConnectivityChecking());

    try {
      // 1. Check connectivity type (rychlé - jen system API)
      final connectivityResults = await _connectivity.checkConnectivity();
      AppLogger.debug('🌐 Connectivity type: $connectivityResults');

      // 2. Check real internet access (pomalejší - HTTP HEAD request)
      final hasInternet = await _internetChecker.hasInternetAccess;
      AppLogger.debug('🌐 Internet access: $hasInternet');

      if (hasInternet) {
        // Máme internet → zjistit typ připojení
        final connectionType = _getConnectionType(connectivityResults);
        emit(ConnectivityConnected(connectionType));
        AppLogger.debug('✅ Připojeno k internetu přes $connectionType');
      } else {
        // Nemáme internet (žádná síť nebo síť bez internetu)
        emit(const ConnectivityDisconnected());
        AppLogger.debug('❌ Žádné připojení k internetu');
      }
    } catch (e) {
      AppLogger.error('❌ Chyba při kontrole připojení', error: e);
      emit(const ConnectivityDisconnected());
    }
  }

  /// Spustit real-time listening pro změny connectivity
  void _startListening() {
    // Listen connectivity changes (WiFi ↔ mobile ↔ none)
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (connectivityResults) {
        AppLogger.debug('🔄 Connectivity změněna: $connectivityResults');
        // Po každé změně connectivity zkontrolovat skutečné připojení
        checkConnectivity();
      },
      onError: (error) {
        AppLogger.error('❌ Connectivity stream error', error: error);
        emit(const ConnectivityDisconnected());
      },
    );

    // Listen internet status changes (connected ↔ disconnected)
    _internetSubscription = _internetChecker.onStatusChange.listen(
      (status) {
        AppLogger.debug('🔄 Internet status změněn: $status');
        // Po každé změně internet statusu aktualizovat state
        checkConnectivity();
      },
      onError: (error) {
        AppLogger.error('❌ Internet checker stream error', error: error);
        emit(const ConnectivityDisconnected());
      },
    );
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

  /// Utility getter: je zařízení připojeno k internetu?
  bool get isConnected => state is ConnectivityConnected;

  /// Utility getter: typ připojení (pokud připojeno)
  String? get connectionType {
    final currentState = state;
    if (currentState is ConnectivityConnected) {
      return currentState.connectionType;
    }
    return null;
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    return super.close();
  }
}
