import 'dart:async';
import 'dart:isolate';

/// PomodoroTimerService - Isolate-based přesný timer
///
/// **Proč Isolate?**
/// - Flutter Timer v UI threadu může lagovat při heavy load
/// - Isolate běží na separátním threadu → přesný timing (~50ms)
/// - Background execution i když je app minimalizovaná (Android)
///
/// **Architektura**:
/// ```
/// Main Isolate (UI)          Background Isolate (Timer)
/// ┌────────────────┐         ┌────────────────┐
/// │ PomodoroBloc   │         │  _timerIsolate │
/// │       ↓        │         │       ↓        │
/// │ TimerService   │ ←─IPC──→│  Timer.periodic│
/// │       ↓        │         │       ↓        │
/// │ tickStream     │         │  SendPort      │
/// │       ↓        │         └────────────────┘
/// │ UI updates     │
/// └────────────────┘
/// ```
///
/// **Komunikace**:
/// - Main → Background: Commands přes SendPort ('pause', 'resume', 'stop')
/// - Background → Main: Ticks přes ReceivePort (Duration objects)
///
/// **Příklad použití**:
/// ```dart
/// final service = PomodoroTimerService();
///
/// // Spustit 25min timer
/// await service.start(Duration(minutes: 25));
///
/// // Subscribe na ticks
/// service.tickStream.listen((remaining) {
///   print('Zbývá: ${remaining.inSeconds}s');
///   if (remaining == Duration.zero) {
///     print('Timer dokončen!');
///   }
/// });
///
/// // Pozastavit
/// service.pause();
///
/// // Pokračovat
/// service.resume();
///
/// // Zastavit
/// service.stop();
/// ```
class PomodoroTimerService {
  // ========== Private fields ==========

  /// Background isolate instance
  Isolate? _isolate;

  /// Port pro příjem zpráv z background isolate
  ReceivePort? _receivePort;

  /// Port pro posílání příkazů do background isolate
  SendPort? _sendPort;

  /// Stream controller pro tick events
  StreamController<Duration>? _tickController;

  /// Je timer aktuálně pozastaven?
  bool _isPaused = false;

  // ========== Public API ==========

  /// Stream tick events (emituje zbývající čas každou sekundu)
  ///
  /// **Emituje**:
  /// - `Duration`: Zbývající čas (každou sekundu)
  /// - `Duration.zero`: Timer dokončen
  ///
  /// **Příklad**:
  /// ```dart
  /// service.tickStream.listen((remaining) {
  ///   if (remaining == Duration.zero) {
  ///     // Timer complete!
  ///   }
  /// });
  /// ```
  Stream<Duration> get tickStream => _tickController!.stream;

  /// Je timer aktuálně pozastaven?
  bool get isPaused => _isPaused;

  /// Běží timer?
  bool get isRunning => _isolate != null && !_isPaused;

  // ========== Timer Operations ==========

  /// Spustit timer na zadanou dobu
  ///
  /// **Parametry**:
  /// - `duration`: Délka timeru (např. Duration(minutes: 25))
  ///
  /// **Chování**:
  /// 1. Vytvoří background isolate
  /// 2. Naváže komunikaci přes SendPort/ReceivePort
  /// 3. Spustí Timer.periodic v isolate
  /// 4. Emituje ticks každou sekundu
  ///
  /// **Výjimky**:
  /// - Vyhodí Exception pokud timer již běží
  ///
  /// **Příklad**:
  /// ```dart
  /// await service.start(Duration(minutes: 25));
  /// ```
  Future<void> start(Duration duration) async {
    // Fail Fast: Kontrola že timer neběží
    if (_isolate != null) {
      throw Exception('Timer již běží! Zavolej stop() před startem nového.');
    }

    // Reset state
    _isPaused = false;

    // Vytvoř receive port pro komunikaci z isolate
    _receivePort = ReceivePort();

    // Vytvoř broadcast stream controller
    _tickController = StreamController<Duration>.broadcast();

    // Spawn background isolate
    _isolate = await Isolate.spawn(
      _timerIsolate,
      _TimerData(
        sendPort: _receivePort!.sendPort,
        duration: duration,
      ),
    );

    // Listen na zprávy z isolate
    _receivePort!.listen((message) {
      if (message is SendPort) {
        // První zpráva = SendPort z isolate pro příkazy
        _sendPort = message;
      } else if (message is Duration) {
        // Tick event
        _tickController!.add(message);
      } else if (message == 'complete') {
        // Timer dokončen
        _tickController!.add(Duration.zero);
      }
    });
  }

  /// Pozastavit timer
  ///
  /// **Chování**:
  /// - Zastaví Timer.periodic v isolate
  /// - Zachová zbývající čas
  /// - Lze pokračovat přes resume()
  ///
  /// **Příklad**:
  /// ```dart
  /// service.pause(); // Pozastaví na 15:30
  /// // ... nějaká pauza ...
  /// service.resume(); // Pokračuje z 15:30
  /// ```
  void pause() {
    if (_sendPort == null || _isPaused) return;

    _isPaused = true;
    _sendPort!.send('pause');
  }

  /// Pokračovat v pozastaveném timeru
  ///
  /// **Chování**:
  /// - Obnoví Timer.periodic v isolate
  /// - Pokračuje ze zachovaného zbývajícího času
  ///
  /// **Poznámka**: Funguje pouze pokud byl timer pozastaven přes pause()
  void resume() {
    if (_sendPort == null || !_isPaused) return;

    _isPaused = false;
    _sendPort!.send('resume');
  }

  /// Zastavit timer a uvolnit resources
  ///
  /// **Chování**:
  /// 1. Pošle 'stop' příkaz do isolate
  /// 2. Zabije isolate (Isolate.kill)
  /// 3. Zavře všechny porty a stream controller
  /// 4. Reset state
  ///
  /// **Poznámka**: Po stop() je potřeba zavolat start() pro nový timer
  ///
  /// **Příklad**:
  /// ```dart
  /// service.stop();
  /// // Timer zničen, je potřeba nový start()
  /// ```
  void stop() {
    // Pošli stop příkaz do isolate
    _sendPort?.send('stop');

    // Zabij isolate
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;

    // Zavři komunikační porty
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;

    // Zavři stream controller
    _tickController?.close();
    _tickController = null;

    // Reset state
    _isPaused = false;
  }

  // ========== Background Isolate Entry Point ==========

  /// Entry point pro background isolate (PRIVATE - nevolat přímo!)
  ///
  /// **Běží v separátním threadu** - nemá přístup k Main isolate paměti!
  ///
  /// **Komunikace**:
  /// - Přijímá: 'pause', 'resume', 'stop' (přes ReceivePort)
  /// - Odesílá: Duration ticks, 'complete' (přes SendPort)
  ///
  /// **Timer logika**:
  /// ```dart
  /// Timer.periodic(1 second) {
  ///   if (!paused && remaining > 0) {
  ///     remaining -= 1 second;
  ///     send(remaining);
  ///   }
  ///   if (remaining == 0) {
  ///     send('complete');
  ///     stop();
  ///   }
  /// }
  /// ```
  static void _timerIsolate(_TimerData data) {
    // Vytvoř receive port pro příkazy z Main isolate
    final receivePort = ReceivePort();

    // Pošli SendPort zpět do Main isolate (první zpráva)
    data.sendPort.send(receivePort.sendPort);

    // State
    Timer? timer;
    bool isPaused = false;
    Duration remaining = data.duration;

    // Helper funkce pro start/resume timer (closure s přístupem ke state)
    void startPeriodicTimer() {
      timer?.cancel();

      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!isPaused && remaining > Duration.zero) {
          // Odpočítej sekundu
          remaining -= const Duration(seconds: 1);

          // Pošli tick do Main isolate
          data.sendPort.send(remaining);

          // Check completion
          if (remaining == Duration.zero) {
            data.sendPort.send('complete');
            t.cancel();
          }
        }
      });
    }

    // Listen na příkazy z Main isolate
    receivePort.listen((message) {
      if (message == 'pause') {
        isPaused = true;
        timer?.cancel();
      } else if (message == 'resume') {
        isPaused = false;
        startPeriodicTimer();
      } else if (message == 'stop') {
        timer?.cancel();
        receivePort.close();
      }
    });

    // Spusť timer ihned
    startPeriodicTimer();
  }
}

// ========== Private Helper Class ==========

/// Data pro inicializaci isolate
///
/// **INTERNAL USE ONLY** - Používá se pro předání dat do Isolate.spawn()
///
/// Isolate.spawn() nemůže přijímat arbitrary objekty - pouze simple types
/// a SendPort. Proto musíme zabalit data do simple class.
class _TimerData {
  /// SendPort pro komunikaci zpět do Main isolate
  final SendPort sendPort;

  /// Počáteční délka timeru
  final Duration duration;

  const _TimerData({
    required this.sendPort,
    required this.duration,
  });
}
