import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';
import '../utils/clipboard_content_detector.dart';

/// ClipboardMonitorService - Monitoruje schránku a detekuje akcionovatelný obsah
///
/// Používá clipboard_watcher package pro real-time monitoring schránky.
/// Když user zkopíruje telefon/email/URL, automaticky se zobrazí dialog s akcemi.
///
/// Usage:
/// ```dart
/// final monitor = ClipboardMonitorService();
/// monitor.onActionableContentDetected = (detected) {
///   showSmartClipboardDialog(context, detected);
/// };
/// monitor.start();
/// ```
class ClipboardMonitorService with ClipboardListener {
  /// Callback když je detekován akcionovatelný obsah
  void Function(DetectedClipboardContent)? onActionableContentDetected;

  /// Poslední detekovaný obsah (pro prevenci duplicit)
  String? _lastContent;

  /// Start monitoring schránky
  void start() {
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
  }

  /// Stop monitoring schránky
  void stop() {
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
  }

  @override
  void onClipboardChanged() async {
    // Získat obsah schránky
    final clipboardData = await Clipboard.getData('text/plain');
    final text = clipboardData?.text;

    // Prázdná schránka nebo duplicitní obsah
    if (text == null || text.isEmpty || text == _lastContent) {
      return;
    }

    // Uložit poslední obsah
    _lastContent = text;

    // Detekovat typ obsahu
    final detected = ClipboardContentDetector.detect(text);

    // Pokud je akcionovatelný (telefon/email/URL), zavolat callback
    if (detected.isActionable && onActionableContentDetected != null) {
      onActionableContentDetected!(detected);
    }
  }

  /// Dispose
  void dispose() {
    stop();
  }
}
