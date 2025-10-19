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
      final cleanText = stripMarkdown(text);

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
  /// Odstraní: *, **, ***, #, ##, ###, -, bullet points, atd.
  /// Zachová: čitelný text bez formátování a emoji
  ///
  /// Použití: Vyčistit AI výstup před čtením TTS
  static String stripMarkdown(String text) {
    var clean = text;

    // PRVNÍ: Odstranit code blocks (před ostatními operacemi)
    clean = clean.replaceAll(RegExp(r'```[^`]*```', dotAll: true), '');
    clean = clean.replaceAll(RegExp(r'`[^`]+`'), '');

    // Odstranit headings (# Nadpis → Nadpis)
    clean = clean.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // Odstranit bold (**text** → text) - použít callback funkci
    clean = clean.replaceAllMapped(
      RegExp(r'\*\*([^\*]+)\*\*'),
      (match) => match.group(1)!,
    );
    clean = clean.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1)!,
    );

    // Odstranit italic (*text* → text) - použít callback funkci
    clean = clean.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^\*]+)\*(?!\*)'),
      (match) => match.group(1)!,
    );
    clean = clean.replaceAllMapped(
      RegExp(r'(?<!_)_(?!_)([^_]+)_(?!_)'),
      (match) => match.group(1)!,
    );

    // Odstranit bullet points (- item → item)
    clean = clean.replaceAll(RegExp(r'^[\s]*[-*+]\s+', multiLine: true), '');

    // Odstranit numbered lists (1. item → item)
    clean = clean.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // Odstranit links [text](url) → text - použít callback funkci
    clean = clean.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1)!,
    );

    // Odstranit horizontal rules (---)
    clean = clean.replaceAll(RegExp(r'^[\s]*[-*_]{3,}[\s]*$', multiLine: true), '');

    // Odstranit blockquotes (> text → text)
    clean = clean.replaceAll(RegExp(r'^>\s*', multiLine: true), '');

    // Odstranit excess whitespace
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    clean = clean.replaceAll(RegExp(r'[ \t]{2,}'), ' ');

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
