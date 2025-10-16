import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

/// Service pro Pomodoro notifikace (zvuk + vibrace)
///
/// Zodpovědnosti:
/// - Přehrání zvuku při dokončení Pomodoro/break
/// - Aktivace vibrací (pokud zařízení podporuje)
/// - Konfigurace na základě PomodoroConfig (soundEnabled)
class NotificationService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  /// Přehrát notifikační zvuk + vibrace
  ///
  /// [soundEnabled] - Pokud false, přehraje pouze vibrace
  Future<void> playCompletionNotification({
    required bool soundEnabled,
  }) async {
    // Vibrace (pokud zařízení podporuje)
    await _vibrate();

    // Zvuk (pokud enabled)
    if (soundEnabled) {
      await _playSound();
    }
  }

  /// Přehrát notifikační zvuk
  Future<void> _playSound() async {
    try {
      // Load audio asset
      await _audioPlayer.setAsset('assets/sounds/pomodoro_complete.wav');

      // Přehrát
      await _audioPlayer.play();

      // Počkat na dokončení přehrávání
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );

      // Reset player pro další použití
      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      print('⚠️ Nelze přehrát notification sound: $e');
    }
  }

  /// Aktivovat vibrace (pattern: krátká-dlouhá-krátká)
  Future<void> _vibrate() async {
    try {
      // Zkontrolovat, zda zařízení podporuje vibrace
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        print('⚠️ Zařízení nepodporuje vibrace');
        return;
      }

      // Zkontrolovat, zda zařízení podporuje custom pattern
      final hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();

      if (hasCustomVibrations == true) {
        // Custom pattern: [pauza, vibrace, pauza, vibrace, ...]
        // Pattern: krátká (200ms) - pauza (100ms) - dlouhá (400ms) - pauza (100ms) - krátká (200ms)
        await Vibration.vibrate(
          pattern: [0, 200, 100, 400, 100, 200],
        );
      } else {
        // Fallback: jednoduchá vibrace (500ms)
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      print('⚠️ Nelze aktivovat vibrace: $e');
    }
  }

  /// Dispose audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
