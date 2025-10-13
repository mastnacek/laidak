import 'dart:io' show Platform;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import '../utils/app_logger.dart';

/// Singleton služba pro správu zvuků
///
/// ARCHITEKTURA:
/// - Android/iOS: používá just_audio (stabilní)
/// - Windows: používá audioplayers (stabilnější než just_audio_windows)
class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal();

  // just_audio player (Android/iOS)
  final just_audio.AudioPlayer _justAudioPlayer = just_audio.AudioPlayer();

  // audioplayers player (Windows)
  final audioplayers.AudioPlayer _audioPlayer = audioplayers.AudioPlayer();

  bool _isPlaying = false;

  /// Přehrát typing_long zvuk ve smyčce (při načítání AI)
  Future<void> playTypingLong() async {
    if (_isPlaying) return;

    try {
      AppLogger.debug('🔊 SoundManager: Playing typing_long.wav');
      _isPlaying = true;

      if (Platform.isWindows) {
        // Windows: použít audioplayers
        await _audioPlayer.setReleaseMode(audioplayers.ReleaseMode.loop);
        await _audioPlayer.setVolume(0.5);
        await _audioPlayer.play(audioplayers.AssetSource('sounds/typing_long.wav'));
      } else {
        // Android/iOS: použít just_audio
        await _justAudioPlayer.setAsset('assets/sounds/typing_long.wav');
        await _justAudioPlayer.setLoopMode(just_audio.LoopMode.one);
        await _justAudioPlayer.setVolume(0.5);
        _justAudioPlayer.play();
      }

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

      if (Platform.isWindows) {
        // Windows: použít audioplayers
        await _audioPlayer.setReleaseMode(audioplayers.ReleaseMode.loop);
        await _audioPlayer.setVolume(0.3);
        await _audioPlayer.play(audioplayers.AssetSource('sounds/subtle_long_type.wav'));
      } else {
        // Android/iOS: použít just_audio
        await _justAudioPlayer.setAsset('assets/sounds/subtle_long_type.wav');
        await _justAudioPlayer.setLoopMode(just_audio.LoopMode.one);
        await _justAudioPlayer.setVolume(0.3);
        _justAudioPlayer.play();
      }

      AppLogger.debug('✅ SoundManager: subtle_long_type started');
    } catch (e) {
      AppLogger.error('❌ SoundManager ERROR', error: e);
      _isPlaying = false;
    }
  }

  /// Zastavit přehrávání
  Future<void> stop() async {
    if (_isPlaying) {
      if (Platform.isWindows) {
        await _audioPlayer.stop();
      } else {
        await _justAudioPlayer.stop();
      }
      _isPlaying = false;
      AppLogger.debug('⏹️ SoundManager: Stopped');
    }
  }

  /// Zrušit všechny zdroje
  void dispose() {
    _justAudioPlayer.dispose();
    _audioPlayer.dispose();
  }
}
