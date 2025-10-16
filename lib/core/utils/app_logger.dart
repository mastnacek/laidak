import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralizovaný logger pro celou aplikaci
///
/// **Usage:**
/// ```dart
/// AppLogger.debug('Debug message');
/// AppLogger.info('User logged in');
/// AppLogger.warning('API rate limit approaching');
/// AppLogger.error('Failed to load data', error: e, stackTrace: st);
/// AppLogger.fatal('Critical app crash', error: e, stackTrace: st);
/// ```
///
/// **Log Levels:**
/// - Debug: Detailní informace pro debugging (pouze v debug mode)
/// - Info: Obecné informace o běhu aplikace
/// - Warning: Varování (nemusí být chyba)
/// - Error: Chyba s exception
/// - Fatal: Kritická chyba (app crash)
///
/// **Production Behavior:**
/// - Debug logs jsou automaticky vypnuty v release mode
/// - Pouze Warning, Error a Fatal logy jsou viditelné v production
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Počet method calls v stack trace
      errorMethodCount: 8, // Počet method calls pro errory
      lineLength: 120, // Šířka výstupu
      colors: true, // Barevný výstup (pokud terminál podporuje)
      printEmojis: true, // Emoji pro vizuální rozlišení
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Debug - detailní informace pro debugging
  ///
  /// **Použití:** Debugging info, trace logs
  ///
  /// **Viditelnost:** Pouze v debug mode
  static void debug(String message) {
    _logger.d(message);
  }

  /// Info - obecné informace o běhu aplikace
  ///
  /// **Použití:** App lifecycle events, user actions
  ///
  /// **Viditelnost:** Debug + Production
  static void info(String message) {
    _logger.i(message);
  }

  /// Warning - varování (nemusí být chyba)
  ///
  /// **Použití:** API rate limits, deprecated API usage
  ///
  /// **Viditelnost:** Debug + Production
  static void warning(String message) {
    _logger.w(message);
  }

  /// Error - chyba s exception
  ///
  /// **Použití:** Handled exceptions, API failures
  ///
  /// **Viditelnost:** Debug + Production
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal - kritická chyba (app crash)
  ///
  /// **Použití:** Unhandled exceptions, critical failures
  ///
  /// **Viditelnost:** Debug + Production
  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
