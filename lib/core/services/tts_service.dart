import 'package:flutter_tts/flutter_tts.dart';
import '../utils/app_logger.dart';

/// Service pro Text-to-Speech (čtení textů nahlas)
///
/// Používá flutter_tts plugin pro převod textu na řeč.
/// Podporuje češtinu, nastavení rychlosti/hlasitosti/pitch.
///
/// Use case: Čtení AI motivačních textů v dialogu
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isInitialized = false;

  /// Getter pro stav mluvení
  bool get isSpeaking => _isSpeaking;

  /// Inicializace TTS (nastavení jazyka, rychlosti, event handlers)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Nastavení češtiny
      await _flutterTts.setLanguage("cs-CZ");

      // Parametry řeči
      await _flutterTts.setSpeechRate(0.5); // 0.5 = pomalejší, 1.0 = normální
      await _flutterTts.setVolume(1.0); // Max hlasitost
      await _flutterTts.setPitch(1.0); // Normální výška hlasu

      // Event handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        AppLogger.debug('🔊 TTS: Začíná mluvit');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        AppLogger.debug('✅ TTS: Dokončeno');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        AppLogger.error('❌ TTS error: $msg');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        AppLogger.debug('⏹️ TTS: Zrušeno');
      });

      _isInitialized = true;
      AppLogger.info('✅ TtsService initialized (cs-CZ)');
    } catch (e) {
      AppLogger.error('❌ TtsService init failed: $e');
      rethrow;
    }
  }

  /// Přečíst text nahlas
  ///
  /// Pokud už něco mluví, automaticky to zastaví a začne nový text.
  /// Text je automaticky očištěn od markdown syntaxe (*, **, #, etc.)
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Pokud už něco mluví, zastav to
      if (_isSpeaking) {
        await _flutterTts.stop();
      }

      // Očistit text od markdown syntaxe
      final cleanText = _stripMarkdown(text);

      // Začni mluvit
      final result = await _flutterTts.speak(cleanText);
      if (result == 1) {
        AppLogger.debug('🔊 TTS: Začínám mluvit (${cleanText.length} znaků)');
      }
    } catch (e) {
      AppLogger.error('❌ TTS speak failed: $e');
      _isSpeaking = false;
    }
  }

  /// Odstranit markdown syntaxi z textu
  ///
  /// Odstraní: *, **, ***, #, ##, ###, -, bullet points, etc.
  /// Zachová: čitelný text bez formátování
  String _stripMarkdown(String text) {
    var clean = text;

    // Odstranit headings (# Nadpis)
    clean = clean.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');

    // Odstranit bold (**text** nebo __text__)
    clean = clean.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    clean = clean.replaceAll(RegExp(r'__([^_]+)__'), r'$1');

    // Odstranit italic (*text* nebo _text_)
    clean = clean.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    clean = clean.replaceAll(RegExp(r'_([^_]+)_'), r'$1');

    // Odstranit bullet points (- item nebo * item)
    clean = clean.replaceAll(RegExp(r'^[\s]*[-*]\s+', multiLine: true), '');

    // Odstranit numbered lists (1. item)
    clean = clean.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // Odstranit links [text](url)
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');

    // Odstranit code blocks (``` nebo `)
    clean = clean.replaceAll(RegExp(r'```[^`]*```'), '');
    clean = clean.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // Odstranit horizontal rules (---, ***)
    clean = clean.replaceAll(RegExp(r'^[\s]*[-*]{3,}[\s]*$', multiLine: true), '');

    // Odstranit excess whitespace (multiple newlines → single)
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Trim
    clean = clean.trim();

    return clean;
  }

  /// Zastavit mluvení
  Future<void> stop() async {
    try {
      final result = await _flutterTts.stop();
      if (result == 1) {
        _isSpeaking = false;
        AppLogger.debug('⏹️ TTS: Zastaveno');
      }
    } catch (e) {
      AppLogger.error('❌ TTS stop failed: $e');
    }
  }

  /// Cleanup (zavolat při dispose)
  void dispose() {
    _flutterTts.stop();
    _isSpeaking = false;
  }
}
