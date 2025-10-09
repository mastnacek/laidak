import 'package:flutter/material.dart';

/// Widget pro typewriter efekt (postupné vypisování textu)
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final VoidCallback? onComplete; // Callback po dokončení
  final ScrollController? scrollController; // Pro auto-scroll

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 30),
    this.onComplete,
    this.scrollController,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    if (_currentIndex < widget.text.length) {
      Future.delayed(widget.duration, () {
        if (mounted) {
          setState(() {
            _currentIndex++;
            // Bezpečný substring - nerozdělit surrogate pair
            _displayedText = _safeSubstring(widget.text, 0, _currentIndex);
          });

          // Auto-scroll dolů po každém přidání znaku
          _autoScroll();

          _startTyping();
        }
      });
    } else {
      // Dokončeno - zavolat callback
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    }
  }

  /// Automaticky scrollovat dolů při přidávání textu
  void _autoScroll() {
    if (widget.scrollController != null && widget.scrollController!.hasClients) {
      // Počkat na příští frame, aby se text vykreslil
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController!.hasClients) {
          widget.scrollController!.animateTo(
            widget.scrollController!.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// Bezpečný substring, který nerozděí surrogate pairs (emoji)
  String _safeSubstring(String text, int start, int end) {
    if (end <= start || end > text.length) {
      return text.substring(start, text.length);
    }

    // Zkontrolovat, jestli jsme uprostřed surrogate pair
    int safeEnd = end;
    if (safeEnd > 0 && safeEnd < text.length) {
      final prevCodeUnit = text.codeUnitAt(safeEnd - 1);
      // High surrogate (0xD800-0xDBFF) následovaný low surrogate
      if (prevCodeUnit >= 0xD800 && prevCodeUnit <= 0xDBFF) {
        // Jsme uprostřed surrogate pair - posuňme end o 1 zpět
        safeEnd--;
      }
    }

    try {
      return text.substring(start, safeEnd);
    } catch (e) {
      // Fallback - sanitizace celého textu
      return _sanitizeText(text.substring(start, safeEnd));
    }
  }

  /// Odstranění nevalidních UTF-16 znaků
  String _sanitizeText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);

      // High surrogate musí být následován low surrogate
      if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
        if (i + 1 < text.length) {
          final nextCodeUnit = text.codeUnitAt(i + 1);
          if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(nextCodeUnit);
            i++;
            continue;
          }
        }
        continue; // Skip lonely high surrogate
      }

      // Lonely low surrogate
      if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
        continue; // Skip
      }

      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}
