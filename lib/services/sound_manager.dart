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

    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.2);
    await _player.play(AssetSource('sounds/typing_long.wav'));
  }

  /// Přehrát subtle typing zvuk ve smyčce (při typewriter efektu)
  Future<void> playSubtleTyping() async {
    if (_isPlaying) {
      // Pokud hraje typing_long, zastavit ho a přepnout na subtle
      await stop();
    }

    _isPlaying = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.15);
    await _player.play(AssetSource('sounds/subtle_long_type.wav'));
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
