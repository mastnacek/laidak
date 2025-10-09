import 'package:just_audio/just_audio.dart';

/// Singleton služba pro správu zvuků
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
      print('🔊 SoundManager: Playing typing_long.wav');
      _isPlaying = true;
      await _player.setAsset('assets/sounds/typing_long.wav');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.5);
      _player.play(); // NEPOUŽÍVAT await - play() nikdy nekončí při loop!
      print('✅ SoundManager: typing_long started');
    } catch (e) {
      print('❌ SoundManager ERROR: $e');
      _isPlaying = false;
    }
  }

  /// Přehrát subtle typing zvuk ve smyčce (při typewriter efektu)
  Future<void> playSubtleTyping() async {
    if (_isPlaying) {
      print('🔇 SoundManager: Stopping previous sound');
      await stop();
    }

    try {
      print('🔊 SoundManager: Playing subtle_long_type.wav');
      _isPlaying = true;
      await _player.setAsset('assets/sounds/subtle_long_type.wav');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0.3);
      _player.play(); // NEPOUŽÍVAT await - play() nikdy nekončí při loop!
      print('✅ SoundManager: subtle_long_type started');
    } catch (e) {
      print('❌ SoundManager ERROR: $e');
      _isPlaying = false;
    }
  }

  /// Zastavit přehrávání
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
      print('⏹️ SoundManager: Stopped');
    }
  }

  /// Zrušit všechny zdroje
  void dispose() {
    _player.dispose();
  }
}
