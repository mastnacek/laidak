import 'package:flutter/material.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/theme/theme_colors.dart';

/// TextField pro poznámky s tag autocomplete (MILESTONE 3.1)
///
/// Simplified verze TODO TagAutocompleteField:
/// - BEZ highlighting (jen plain text)
/// - BEZ emoji/color (Notes nemají custom tags)
/// - Pouze autocomplete dropdown s existujícími tagy
///
/// Detekuje když uživatel píše tag (za *) a zobrazí dropdown s návrhy.
/// Například: "*proj" → zobrazí "projekt", "projekty", ...
class NotesTagAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final int maxLines;
  final bool expands;
  final TextAlignVertical textAlignVertical;
  final TextInputType keyboardType;

  const NotesTagAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical = TextAlignVertical.center,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<NotesTagAutocompleteField> createState() =>
      _NotesTagAutocompleteFieldState();
}

class _NotesTagAutocompleteFieldState
    extends State<NotesTagAutocompleteField> {
  final DatabaseHelper _db = DatabaseHelper();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _suggestions = [];
  String _currentTagPrefix = '';
  final String _delimiterStart = '*';
  final String _delimiterEnd = '*';

  @override
  void initState() {
    super.initState();

    // Naslouchat změnám v textfieldu
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  /// Detekovat typed tag a zobrazit autocomplete
  Future<void> _onTextChanged() async {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Najít aktuální typed tag (text mezi * a cursorem)
    final tagMatch = _findCurrentTag(text, cursorPos);

    if (tagMatch != null && tagMatch.length >= 1) {
      // Uživatel píše tag → zobrazit autocomplete
      _currentTagPrefix = tagMatch;
      await _showAutocomplete(tagMatch);
    } else {
      // Není v tagu → skrýt autocomplete
      _removeOverlay();
    }
  }

  /// Najít aktuální typed tag na cursor pozici
  String? _findCurrentTag(String text, int cursorPos) {
    if (cursorPos <= 0 || cursorPos > text.length) return null;

    // Najít start delimiter před cursorem
    int startPos = -1;

    for (int i = cursorPos - 1; i >= 0; i--) {
      if (i + _delimiterStart.length <= text.length &&
          text.substring(i, i + _delimiterStart.length) == _delimiterStart) {
        startPos = i;
        break;
      }
      // Pokud narazíme na mezeru nebo newline, přerušit
      if (text[i] == ' ' || text[i] == '\n') break;
    }

    if (startPos == -1) return null;

    // Extrahovat text mezi start delimiter a cursorem
    final tagContent =
        text.substring(startPos + _delimiterStart.length, cursorPos);

    // Pokud je prázdný nebo končí end delimiterem, není to validní typed tag
    if (tagContent.isEmpty || tagContent.endsWith(_delimiterEnd)) return null;

    return tagContent;
  }

  /// Zobrazit autocomplete dropdown
  Future<void> _showAutocomplete(String query) async {
    // Query databázi
    final results = await _db.searchNoteTags(query, limit: 5);

    if (results.isEmpty) {
      _removeOverlay();
      return;
    }

    setState(() {
      _suggestions = results;
    });

    // Pokud už existuje overlay, update ho
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    // Vytvořit nový overlay
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Vytvořit OverlayEntry s dropdownem NAD input fieldem
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    // Vypočítat výšku dropdownu (max 200px, ale může být menší)
    final dropdownHeight = (_suggestions.length * 48.0).clamp(0.0, 200.0);

    return OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);

        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            // Záporný offset = dropdown NAD input fieldem
            // -4 = gap, -dropdownHeight = výška dropdownu
            offset: Offset(0, -dropdownHeight - 4),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: theme.appColors.bgAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.appColors.base3,
                    width: 1,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final tag = _suggestions[index];

                    return InkWell(
                      onTap: () => _onTagSelected(tag),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Simple icon (Note tagy nemají emoji)
                            Icon(
                              Icons.tag,
                              size: 16,
                              color: theme.appColors.cyan,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: theme.appColors.fg,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle výběr tagu z dropdownu
  void _onTagSelected(String tagName) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Najít start delimiter před cursorem
    int startPos = -1;

    for (int i = cursorPos - 1; i >= 0; i--) {
      if (i + _delimiterStart.length <= text.length &&
          text.substring(i, i + _delimiterStart.length) == _delimiterStart) {
        startPos = i;
        break;
      }
    }

    if (startPos == -1) return;

    // Replace typed text s vybraným tagem
    final before = text.substring(0, startPos + _delimiterStart.length);
    final after = text.substring(cursorPos);
    final newText = '$before$tagName$_delimiterEnd$after';

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + tagName.length + _delimiterEnd.length,
      ),
    );

    _removeOverlay();
  }

  /// Odstranit overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    // setState pouze pokud je widget stále mounted (ne během dispose)
    if (mounted) {
      setState(() {
        _suggestions = [];
      });
    } else {
      // Widget je během dispose → jen clear data bez setState
      _suggestions = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        expands: widget.expands,
        textAlignVertical: widget.textAlignVertical,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.appColors.base5.withOpacity(0.6),
            fontSize: 16,
          ),
          border: InputBorder.none,
        ),
        style: TextStyle(
          color: theme.appColors.fg,
          fontSize: 16,
          height: 1.5, // Line height
        ),
      ),
    );
  }
}
