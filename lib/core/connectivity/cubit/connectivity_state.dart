import 'package:equatable/equatable.dart';

/// Connectivity State pro monitoring síťového připojení
///
/// Kombinuje connectivity_plus (typ sítě) + internet_connection_checker_plus (skutečné připojení)
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

/// Initial state - ještě nebylo provedeno první ověření
class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

/// Kontrola probíhá
class ConnectivityChecking extends ConnectivityState {
  const ConnectivityChecking();
}

/// Zařízení má aktivní připojení k internetu
class ConnectivityConnected extends ConnectivityState {
  final String connectionType; // 'wifi', 'mobile', 'other'

  const ConnectivityConnected(this.connectionType);

  @override
  List<Object?> get props => [connectionType];
}

/// Zařízení NEMÁ aktivní připojení k internetu
/// (buď žádná síť, nebo síť bez internetu - např. WiFi s captive portal)
class ConnectivityDisconnected extends ConnectivityState {
  const ConnectivityDisconnected();
}
