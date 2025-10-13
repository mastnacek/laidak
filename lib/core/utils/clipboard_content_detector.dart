/// ClipboardContentDetector - Detekce typu obsahu schránky
///
/// Podporované typy:
/// - Telefonní čísla (phone)
/// - Email adresy (email)
/// - URL adresy (url)
/// - Běžný text (text)
///
/// Usage:
/// ```dart
/// final detected = ClipboardContentDetector.detect('123-456-7890');
/// if (detected.type == ClipboardContentType.phone) {
///   print('Phone: ${detected.value}');
/// }
/// ```
class ClipboardContentDetector {
  /// Typy obsahu schránky
  static const phoneType = ClipboardContentType.phone;
  static const emailType = ClipboardContentType.email;
  static const urlType = ClipboardContentType.url;
  static const textType = ClipboardContentType.text;

  /// Regex patterny pro detekci
  static final RegExp _phoneRegex = RegExp(
    r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$',
    caseSensitive: false,
  );

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  static final RegExp _urlRegex = RegExp(
    r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$',
    caseSensitive: false,
  );

  /// Detekovat typ obsahu schránky
  static DetectedClipboardContent detect(String text) {
    // Trim whitespace
    final trimmedText = text.trim();

    // Prázdný text
    if (trimmedText.isEmpty) {
      return DetectedClipboardContent(
        type: ClipboardContentType.text,
        value: '',
        originalText: text,
      );
    }

    // Detekce telefonu (nejvyšší priorita - nejspecifičtější)
    if (_phoneRegex.hasMatch(trimmedText)) {
      return DetectedClipboardContent(
        type: ClipboardContentType.phone,
        value: _normalizePhone(trimmedText),
        originalText: text,
      );
    }

    // Detekce emailu
    if (_emailRegex.hasMatch(trimmedText)) {
      return DetectedClipboardContent(
        type: ClipboardContentType.email,
        value: trimmedText.toLowerCase(),
        originalText: text,
      );
    }

    // Detekce URL
    if (_urlRegex.hasMatch(trimmedText)) {
      return DetectedClipboardContent(
        type: ClipboardContentType.url,
        value: _normalizeUrl(trimmedText),
        originalText: text,
      );
    }

    // Fallback: běžný text
    return DetectedClipboardContent(
      type: ClipboardContentType.text,
      value: trimmedText,
      originalText: text,
    );
  }

  /// Normalizovat telefonní číslo (odstranit formátování)
  static String _normalizePhone(String phone) {
    // Odstranit všechny non-digit znaky kromě +
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Normalizovat URL (přidat https:// pokud chybí)
  static String _normalizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }
}

/// Typy obsahu schránky
enum ClipboardContentType {
  phone,
  email,
  url,
  text,
}

/// Detekovaný obsah schránky
class DetectedClipboardContent {
  final ClipboardContentType type;
  final String value; // Normalizovaná hodnota
  final String originalText; // Originální text ze schránky

  const DetectedClipboardContent({
    required this.type,
    required this.value,
    required this.originalText,
  });

  /// Je telefonní číslo?
  bool get isPhone => type == ClipboardContentType.phone;

  /// Je email?
  bool get isEmail => type == ClipboardContentType.email;

  /// Je URL?
  bool get isUrl => type == ClipboardContentType.url;

  /// Je běžný text?
  bool get isText => type == ClipboardContentType.text;

  /// Je akcionovatelný obsah? (ne běžný text)
  bool get isActionable => !isText;

  @override
  String toString() {
    return 'DetectedClipboardContent(type: $type, value: $value)';
  }
}
