import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/doom_one_theme.dart';
import '../services/tag_service.dart';
import '../core/services/database_helper.dart';

/// TextField s live syntax highlighting pro tagy
/// Používá dynamické barvy z TagService
/// Používá EditableText s vlastním TextEditingController
class HighlightedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const HighlightedTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<HighlightedTextField> createState() => _HighlightedTextFieldState();
}

class _HighlightedTextFieldState extends State<HighlightedTextField> {
  FocusNode? _internalFocusNode;
  late HighlightedTextEditingController _highlightController;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();

    // Vytvořit interní FocusNode pouze pokud není předán
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    // Wrap původní controller do highlighting controlleru
    _highlightController = HighlightedTextEditingController(
      text: widget.controller.text,
    );

    // Sync s původním controllerem
    widget.controller.addListener(_syncFromOriginal);
    _highlightController.addListener(_syncToOriginal);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromOriginal);
    _highlightController.removeListener(_syncToOriginal);
    _highlightController.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _syncFromOriginal() {
    if (_highlightController.text != widget.controller.text) {
      _highlightController.value = widget.controller.value;
    }
  }

  void _syncToOriginal() {
    if (widget.controller.text != _highlightController.text) {
      widget.controller.value = _highlightController.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Při tapu vždy požádat o focus a otevřít klávesnici
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: DoomOneTheme.base2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focusNode.hasFocus ? DoomOneTheme.blue : DoomOneTheme.base4,
            width: _focusNode.hasFocus ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: EditableText(
          controller: _highlightController,
          focusNode: _focusNode,
          style: TextStyle(
            color: DoomOneTheme.fg,
            fontSize: 16,
          ),
          cursorColor: DoomOneTheme.cyan,
          backgroundCursorColor: DoomOneTheme.base4,
          maxLines: null,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          autocorrect: true,
          enableSuggestions: true,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}

/// Custom TextEditingController s syntax highlighting
class HighlightedTextEditingController extends TextEditingController {
  final TagService _tagService = TagService();
  String _delimiterStart = '*';
  String _delimiterEnd = '*';
  RegExp? _tagRegex;

  HighlightedTextEditingController({super.text}) {
    _initDelimiters();
  }

  /// Načíst delimitery z DB a vytvořit regex (async init)
  Future<void> _initDelimiters() async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      _delimiterStart = settings['tag_delimiter_start'] as String? ?? '*';
      _delimiterEnd = settings['tag_delimiter_end'] as String? ?? '*';

      // Vytvořit regex s escapovanými delimitery
      final start = RegExp.escape(_delimiterStart);
      final end = RegExp.escape(_delimiterEnd);
      _tagRegex = RegExp('$start([^$end]+)$end');

      // Trigger rebuild pro aplikaci nového regex
      notifyListeners();
    } catch (e) {
      // Fallback na default delimitery pokud DB není ready
      _delimiterStart = '*';
      _delimiterEnd = '*';
      _tagRegex = RegExp(r'\*([^*]+)\*');
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    return _buildHighlightedSpan(text, style);
  }

  TextSpan _buildHighlightedSpan(String text, TextStyle? baseStyle) {
    // Sanitizace textu - odstranění nevalidních UTF-16 znaků
    final sanitizedText = _sanitizeText(text);

    final spans = <InlineSpan>[];
    // Použít dynamický regex (fallback na default pokud ještě není načtený)
    final tagRegex = _tagRegex ?? RegExp(r'\*([^*]+)\*');
    int lastMatchEnd = 0;

    for (final match in tagRegex.allMatches(sanitizedText)) {
      // Text před tagem (normální barva)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: sanitizedText.substring(lastMatchEnd, match.start),
          style: baseStyle?.copyWith(color: DoomOneTheme.fg),
        ));
      }

      // Tag s barvou podle typu
      final tagContent = match.group(1) ?? '';
      final tagColor = _getTagColor(tagContent);

      spans.add(TextSpan(
        text: match.group(0), // Celý tag včetně *
        style: baseStyle?.copyWith(
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Zbytek textu za posledním tagem
    if (lastMatchEnd < sanitizedText.length) {
      spans.add(TextSpan(
        text: sanitizedText.substring(lastMatchEnd),
        style: baseStyle?.copyWith(color: DoomOneTheme.fg),
      ));
    }

    return TextSpan(
      style: baseStyle,
      children: spans,
    );
  }

  /// Odstranění nevalidních UTF-16 znaků (lonely surrogates)
  String _sanitizeText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);

      // High surrogate (0xD800-0xDBFF) musí být následován low surrogate
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        if (i + 1 < text.length) {
          final nextCodeUnit = text.codeUnitAt(i + 1);
          if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
            // Validní surrogate pair
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(nextCodeUnit);
            i++; // Skip next code unit
            continue;
          }
        }
        // Lonely high surrogate - skip
        continue;
      }

      // Low surrogate (0xDC00-0xDFFF) bez předchozího high surrogate
      if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        // Lonely low surrogate - skip
        continue;
      }

      // Normální znak
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }

  Color _getTagColor(String tagContent) {
    final lower = tagContent.toLowerCase();

    // Pokusit se získat definici z TagService (s error handling)
    try {
      final definition = _tagService.getDefinition(lower);

      print('🎨 [HighlightedTextField] Tag: "$lower"');
      print('   Definition: ${definition != null ? "FOUND" : "NULL"}');
      if (definition != null) {
        print('   Color from DB: "${definition.color}"');
      }

      // Pokud existuje definice s barvou, použít ji
      if (definition != null && definition.color != null) {
        final color = _parseHexColor(definition.color!);
        print('   Parsed color: ${color != null ? color.toString() : "NULL (parsing failed)"}');
        if (color != null) {
          print('   ✅ Returning DB color');
          return color;
        }
      }

      print('   ⚠️ Fallback - no valid color from DB');
    } catch (e) {
      // TagService není inicializovaný → použít fallback barvy
      // Toto je OK, protože highlighting controller může být vytvořen
      // před dokončením inicializace TagService v main()
      print('   ❌ TagService error: $e');
      print('   ⚠️ Fallback - TagService not initialized');
    }

    // Fallback barvy podle typu tagu (pokud definice neexistuje nebo nemá color)
    // Priorita
    if (lower == 'a') return DoomOneTheme.red;
    if (lower == 'b') return DoomOneTheme.yellow;
    if (lower == 'c') return DoomOneTheme.green;

    // Datum
    if (lower == 'dnes' || lower == 'zitra') {
      return DoomOneTheme.blue;
    }

    // Akce
    const actions = [
      'udelat',
      'zavolat',
      'napsat',
      'koupit',
      'poslat',
      'pripravit',
      'domluvit',
      'zkontrolovat',
      'opravit',
      'nacist',
      'poslouchat'
    ];
    if (actions.contains(lower)) {
      return DoomOneTheme.violet;
    }

    // Obecný tag (custom tagy)
    return DoomOneTheme.magenta;
  }

  /// Parsovat hex color string na Flutter Color
  ///
  /// Podporované formáty: "#FF5555", "#F55", "FF5555", "F55"
  Color? _parseHexColor(String hexString) {
    try {
      // Odstranit # pokud existuje
      String hex = hexString.replaceAll('#', '');

      // Pokud je 3-znakový (#RGB), expandovat na 6-znakový (#RRGGBB)
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }

      // Pokud je 6-znakový, přidat alfa kanál (FF = plně viditelné)
      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      // Parsovat jako int a vytvořit Color
      if (hex.length == 8) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          return Color(value);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
