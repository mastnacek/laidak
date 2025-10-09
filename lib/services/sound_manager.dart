import 'package:audioplayers/audioplayers.dart';

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

    print('🔊 SoundManager: Playing typing_long.wav');
    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5); // Zvýšil jsem volume
    await _player.play(AssetSource('sounds/typing_long.wav'));
    print('✅ SoundManager: typing_long started');
  }

  /// Přehrát subtle typing zvuk ve smyčce (při typewriter efektu)
  Future<void> playSubtleTyping() async {
    if (_isPlaying) {
      // Pokud hraje typing_long, zastavit ho a přepnout na subtle
      print('🔇 SoundManager: Stopping previous sound');
      await stop();
    }

    print('🔊 SoundManager: Playing subtle_long_type.wav');
    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.3); // Zvýšil jsem volume
    await _player.play(AssetSource('sounds/subtle_long_type.wav'));
    print('✅ SoundManager: subtle_long_type started');
  }

  /// Zastavit přehrávání
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
    }
  }

  /// Zrušit všechny zdroje
  void dispose() {
    _player.dispose();
  }
}
