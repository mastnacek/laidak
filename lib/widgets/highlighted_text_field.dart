import 'package:flutter/material.dart';
import '../theme/doom_one_theme.dart';
import '../services/tag_parser.dart';

/// TextField s live syntax highlighting pro tagy
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  /// Zvýraznit text podle tagů
  List<TextSpan> _buildHighlightedText(String text) {
    if (text.isEmpty) return [];

    final spans = <TextSpan>[];
    final tagRegex = RegExp(r'\*([^*]+)\*');
    int lastMatchEnd = 0;

    for (final match in tagRegex.allMatches(text)) {
      // Text před tagem (normální barva)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(color: DoomOneTheme.fg),
        ));
      }

      // Tag s barvou podle typu
      final tagContent = match.group(1)?.toLowerCase() ?? '';
      final tagColor = _getTagColor(tagContent);

      spans.add(TextSpan(
        text: match.group(0), // Celý tag včetně *
        style: TextStyle(
          color: tagColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Zbytek textu za posledním tagem
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(color: DoomOneTheme.fg),
      ));
    }

    return spans;
  }

  /// Získat barvu pro tag podle typu
  Color _getTagColor(String tagContent) {
    // Priorita
    if (tagContent == 'a') return DoomOneTheme.red;
    if (tagContent == 'b') return DoomOneTheme.yellow;
    if (tagContent == 'c') return DoomOneTheme.green;

    // Datum
    if (tagContent == 'dnes' || tagContent == 'zitra') {
      return DoomOneTheme.blue;
    }

    // Akce
    const actions = [
      'udelat', 'zavolat', 'napsat', 'koupit', 'poslat',
      'pripravit', 'domluvit', 'zkontrolovat', 'opravit',
      'nacist', 'poslouchat'
    ];
    if (actions.contains(tagContent)) {
      return DoomOneTheme.magenta;
    }

    // Obecný tag
    return DoomOneTheme.cyan;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible text pro správné měření výšky
        Opacity(
          opacity: 0,
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            style: TextStyle(
              color: DoomOneTheme.fg,
              fontSize: 16,
            ),
          ),
        ),

        // Highlighted overlay (read-only, synchronized scroll)
        Positioned.fill(
          child: IgnorePointer(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                  children: _buildHighlightedText(widget.controller.text),
                ),
              ),
            ),
          ),
        ),

        // Actual TextField (transparent text)
        TextField(
          controller: widget.controller,
          scrollController: _scrollController,
          maxLines: null,
          style: TextStyle(
            color: Colors.transparent, // Transparentní text (vidíme overlay)
            fontSize: 16,
            fontFamily: 'monospace',
            height: 1.4,
          ),
          cursorColor: DoomOneTheme.cyan,
          cursorWidth: 2,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: DoomOneTheme.base5,
              fontSize: 14,
            ),
            filled: true,
            fillColor: DoomOneTheme.base2,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: DoomOneTheme.base4),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DoomOneTheme.base4, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: DoomOneTheme.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          onSubmitted: widget.onSubmitted,
        ),
      ],
    );
  }
}
