import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../core/utils/app_logger.dart';

/// On-demand ONNX model downloader
///
/// Strategie: Download model při prvním spuštění (ne v APK assets)
/// - Úspora APK size (~100-400MB)
/// - User stáhne model přes Wi-Fi (doporučeno)
/// - Model se uloží do app documents directory
///
/// Model: Qdrant/paraphrase-multilingual-MiniLM-L12-v2-onnx-Q
/// - Kvantizovaný INT8 (menší než fp32)
/// - 384 dimensions
/// - 50+ jazyků (včetně češtiny)
class ModelDownloader {
  /// HuggingFace model URL (Qdrant kvantizovaná verze)
  static const String _modelUrl =
      'https://huggingface.co/Qdrant/paraphrase-multilingual-MiniLM-L12-v2-onnx-Q/resolve/main/model.onnx';

  static const String _modelFileName = 'paraphrase-multilingual-minilm-l12-v2-onnx-q.onnx';

  /// Check jestli je model už stažený
  static Future<bool> isModelDownloaded() async {
    try {
      final modelPath = await getModelPath();
      return File(modelPath).existsSync();
    } catch (e) {
      AppLogger.error('Error checking model existence: $e');
      return false;
    }
  }

  /// Get full path k model souboru
  static Future<String> getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = path.join(appDir.path, 'models');

    // Ensure models directory exists
    await Directory(modelsDir).create(recursive: true);

    return path.join(modelsDir, _modelFileName);
  }

  /// Download model s progress callback
  ///
  /// [onProgress]: callback (downloaded bytes, total bytes, percent)
  /// [forceRedownload]: pokud true, smaže existující model a stáhne znovu
  static Future<void> downloadModel({
    required Function(int downloaded, int total, double percent) onProgress,
    bool forceRedownload = false,
  }) async {
    final modelPath = await getModelPath();

    // Check pokud už existuje
    if (!forceRedownload && File(modelPath).existsSync()) {
      AppLogger.info('✅ Model už existuje, skip download');
      onProgress(100, 100, 100.0); // 100% done
      return;
    }

    // Delete existující pokud force redownload
    if (forceRedownload && File(modelPath).existsSync()) {
      await File(modelPath).delete();
      AppLogger.info('🗑️ Deleted existing model for redownload');
    }

    AppLogger.info('🔽 Downloading ONNX model from HuggingFace...');
    AppLogger.info('   URL: $_modelUrl');

    try {
      // HTTP GET request s streamováním
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw ModelDownloadException(
          'Failed to download model: HTTP ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength ?? 0;
      if (contentLength == 0) {
        throw ModelDownloadException('Unknown model file size');
      }

      AppLogger.info('   Size: ${(contentLength / 1024 / 1024).toStringAsFixed(1)} MB');

      // Download s progress tracking
      final file = File(modelPath);
      final sink = file.openWrite();
      int downloaded = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;

        final percent = (downloaded / contentLength * 100);
        onProgress(downloaded, contentLength, percent);

        // Log každých 10%
        if (percent % 10 < 0.5) {
          AppLogger.debug('   Progress: ${percent.toStringAsFixed(1)}%');
        }
      }

      await sink.close();

      AppLogger.info('✅ Model stažen: $modelPath');
      AppLogger.info('   Size: ${(downloaded / 1024 / 1024).toStringAsFixed(1)} MB');
    } catch (e) {
      // Cleanup partial download
      if (File(modelPath).existsSync()) {
        await File(modelPath).delete();
      }

      throw ModelDownloadException('Model download failed: $e');
    }
  }

  /// Delete stažený model (pro factory reset)
  static Future<void> deleteModel() async {
    try {
      final modelPath = await getModelPath();
      if (File(modelPath).existsSync()) {
        await File(modelPath).delete();
        AppLogger.info('🗑️ Model deleted: $modelPath');
      }
    } catch (e) {
      throw ModelDownloadException('Failed to delete model: $e');
    }
  }

  /// Get velikost staženého modelu v MB
  static Future<double?> getModelSizeMB() async {
    try {
      final modelPath = await getModelPath();
      if (!File(modelPath).existsSync()) {
        return null;
      }

      final size = await File(modelPath).length();
      return size / 1024 / 1024; // bytes → MB
    } catch (e) {
      AppLogger.error('Error getting model size: $e');
      return null;
    }
  }
}

/// Exception pro model download errors
class ModelDownloadException implements Exception {
  final String message;

  ModelDownloadException(this.message);

  @override
  String toString() => 'ModelDownloadException: $message';
}
