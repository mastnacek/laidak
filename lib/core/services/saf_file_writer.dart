import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

/// Platform Channel pro Storage Access Framework (Android)
///
/// Umožňuje zápis souborů do user-selected složky přes SAF na Androidu.
/// Na ostatních platformách (Windows, Linux, macOS) se používá dart:io File API.
class SafFileWriter {
  static const MethodChannel _channel = MethodChannel('com.laidak.markdown_export/saf');

  /// Zapíše soubor přes SAF (Android) nebo dart:io (ostatní platformy)
  ///
  /// [directoryUri] - SAF tree URI (na Androidu) nebo file path (ostatní platformy)
  /// [relativePath] - relativní cesta od directoryUri (např. "tasks/todo.md")
  /// [content] - obsah souboru jako bytes
  /// [mimeType] - MIME type (default: "text/markdown")
  ///
  /// Throws [PlatformException] pokud selže zápis
  static Future<void> writeFile({
    required String directoryUri,
    required String relativePath,
    required Uint8List content,
    String mimeType = 'text/markdown',
  }) async {
    try {
      if (Platform.isAndroid) {
        // Android: použij SAF přes Platform Channel
        AppLogger.debug('📱 Android: Zapisuji soubor přes SAF: $relativePath');

        final result = await _channel.invokeMethod<bool>('writeFile', {
          'directoryUri': directoryUri,
          'relativePath': relativePath,
          'content': content,
          'mimeType': mimeType,
        });

        if (result != true) {
          throw Exception('SAF write failed - native method returned false');
        }

        AppLogger.debug('✅ Android: Soubor zapsán: $relativePath');
      } else {
        // Desktop: tento případ by neměl nastat (file_picker vrací normální path)
        throw UnsupportedError(
          'SafFileWriter.writeFile() je určen pouze pro Android. '
          'Na desktopu použij dart:io File API přímo.',
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error('❌ SAF write failed: ${e.message}');
      throw Exception('SAF write failed: ${e.message}');
    } catch (e) {
      AppLogger.error('❌ Unexpected error in SafFileWriter: $e');
      rethrow;
    }
  }

  /// Smaže složku přes SAF (Android)
  ///
  /// [directoryUri] - SAF tree URI
  /// [relativePath] - relativní cesta ke složce (např. "tasks")
  ///
  /// Throws [PlatformException] pokud selže mazání
  static Future<void> deleteDirectory({
    required String directoryUri,
    required String relativePath,
  }) async {
    try {
      if (Platform.isAndroid) {
        AppLogger.debug('📱 Android: Mažu složku přes SAF: $relativePath');

        final result = await _channel.invokeMethod<bool>('deleteDirectory', {
          'directoryUri': directoryUri,
          'relativePath': relativePath,
        });

        if (result != true) {
          AppLogger.debug('⚠️ Složka neexistuje nebo už byla smazána: $relativePath');
        } else {
          AppLogger.debug('✅ Android: Složka smazána: $relativePath');
        }
      } else {
        throw UnsupportedError(
          'SafFileWriter.deleteDirectory() je určen pouze pro Android.',
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error('❌ SAF delete failed: ${e.message}');
      throw Exception('SAF delete failed: ${e.message}');
    }
  }

  /// Kontrola jestli je cesta SAF URI (Android content://)
  static bool isSafUri(String path) {
    return path.startsWith('content://');
  }

  /// Otevře SAF directory picker a vrátí content URI (Android)
  ///
  /// Throws [UnsupportedError] pokud není Android
  /// Throws [PlatformException] pokud user zruší picker nebo selže
  static Future<String?> pickDirectory() async {
    try {
      if (Platform.isAndroid) {
        AppLogger.debug('📱 Android: Otevírám SAF directory picker');

        final result = await _channel.invokeMethod<String>('pickDirectory');

        if (result != null) {
          AppLogger.debug('✅ Android: Vybrána složka: $result');
        } else {
          AppLogger.debug('⚠️ Android: Picker zrušen uživatelem');
        }

        return result;
      } else {
        throw UnsupportedError(
          'SafFileWriter.pickDirectory() je určen pouze pro Android.',
        );
      }
    } on PlatformException catch (e) {
      AppLogger.error('❌ SAF picker failed: ${e.message}');
      throw Exception('SAF picker failed: ${e.message}');
    }
  }
}
