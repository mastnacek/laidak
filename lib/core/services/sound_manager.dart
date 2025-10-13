import 'package:just_audio/just_audio.dart';
import '../utils/app_logger.dart';

/// Singleton služba pro správu zvuků
///
/// ARCHITEKTURA:
/// - Android/iOS/macOS: just_audio nativní implementace
/// - Windows/Linux: just_audio_media_kit (media_kit backend)
///
/// SETUP: JustAudioMediaKit.ensureInitialized() v main.dart
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  /// Přehrát typing_long zvuk ve smyčce (při načítání AI)
  Future<void> playTypingLong() async {
    if (_isPlaying) return;

    try {
      AppLogger.debug('🔊 SoundManager: Playing typing_long.wav');
      _isPlaying = true;
      await _player.setAsset('assets/sounds/typing_long.wav');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.5);
      _player.play(); // NEPOUŽÍVAT await - play() nikdy nekončí při loop!
      AppLogger.debug('✅ SoundManager: typing_long started');
    } catch (e) {
      AppLogger.error('❌ SoundManager ERROR', error: e);
      _isPlaying = false;
    }
  }

  /// Přehrát subtle typing zvuk ve smyčce (při typewriter efektu)
  Future<void> playSubtleTyping() async {
    if (_isPlaying) {
      AppLogger.debug('🔇 SoundManager: Stopping previous sound');
      await stop();
    }

    try {
      AppLogger.debug('🔊 SoundManager: Playing subtle_long_type.wav');
      _isPlaying = true;
      await _player.setAsset('assets/sounds/subtle_long_type.wav');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.3);
      _player.play(); // NEPOUŽÍVAT await - play() nikdy nekončí při loop!
      AppLogger.debug('✅ SoundManager: subtle_long_type started');
    } catch (e) {
      AppLogger.error('❌ SoundManager ERROR', error: e);
      _isPlaying = false;
    }
  }

  /// Zastavit přehrávání
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
      AppLogger.debug('⏹️ SoundManager: Stopped');
    }
  }

  /// Zrušit všechny zdroje
  void dispose() {
    _player.dispose();
  }
}
