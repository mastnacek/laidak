import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/doom_one_theme.dart';

/// TextField s live syntax highlighting pro tagy
/// Používá EditableText s vlastním TextEditingController
class HighlightedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  const HighlightedTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  State<HighlightedTextField> createState() => _HighlightedTextFieldState();
}

class _HighlightedTextFieldState extends State<HighlightedTextField> {
  final FocusNode _focusNode = FocusNode();
  late HighlightedTextEditingController _highlightController;

  @override
  void initState() {
    super.initState();
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
    _focusNode.dispose();
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
    return Container(
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
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

/// Custom TextEditingController s syntax highlighting
class HighlightedTextEditingController extends TextEditingController {
  HighlightedTextEditingController({String? text}) : super(text: text);

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
    final tagRegex = RegExp(r'\*([^*]+)\*');
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
      'udelat', 'zavolat', 'napsat', 'koupit', 'poslat',
      'pripravit', 'domluvit', 'zkontrolovat', 'opravit',
      'nacist', 'poslouchat'
    ];
    if (actions.contains(lower)) {
      return DoomOneTheme.magenta;
    }

    // Obecný tag
    return DoomOneTheme.cyan;
  }
}
