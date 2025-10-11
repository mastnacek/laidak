import 'package:flutter/material.dart';
import '../core/services/database_helper.dart';
import '../core/theme/theme_colors.dart';

/// TextField s tag autocomplete dropdownem
///
/// Detekuje když uživatel píše tag (za *) a zobrazí dropdown s návrhy.
/// Například: "*proj" → zobrazí "projekt", "projekty", ...
class TagAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  const TagAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.onSubmitted,
  });

  @override
  State<TagAutocompleteField> createState() => _TagAutocompleteFieldState();
}

class _TagAutocompleteFieldState extends State<TagAutocompleteField> {
  final DatabaseHelper _db = DatabaseHelper();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<Map<String, dynamic>> _suggestions = [];
  String _currentTagPrefix = '';

  @override
  void initState() {
    super.initState();
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

    // Najít * před cursorem
    int startPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '*') {
        startPos = i;
        break;
      }
      // Pokud narazíme na mezeru nebo další *, přerušit
      if (text[i] == ' ') break;
    }

    if (startPos == -1) return null;

    // Extrahovat text mezi * a cursorem
    final tagContent = text.substring(startPos + 1, cursorPos);

    // Pokud je prázdný nebo končí *, není to validní typed tag
    if (tagContent.isEmpty || tagContent.endsWith('*')) return null;

    return tagContent;
  }

  /// Zobrazit autocomplete dropdown
  Future<void> _showAutocomplete(String query) async {
    // Query databázi
    final results = await _db.searchTags(query, limit: 5);

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
                    final displayName = tag['display_name'] as String;
                    final usageCount = tag['usage_count'] as int;
                    final emoji = tag['emoji'] as String?;
                    final colorHex = tag['color'] as String?;

                    // Parse barvu z hex (#ff0000 → Color)
                    Color tagColor = theme.appColors.cyan; // Default pro custom
                    if (colorHex != null && colorHex.startsWith('#')) {
                      try {
                        tagColor = Color(
                          int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
                        );
                      } catch (e) {
                        // Fallback na cyan pokud parsing selže
                        tagColor = theme.appColors.cyan;
                      }
                    }

                    return InkWell(
                      onTap: () => _onTagSelected(displayName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Emoji pro systémové tagy, ikona pro custom
                            if (emoji != null)
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 16),
                              )
                            else
                              Icon(
                                Icons.label,
                                size: 16,
                                color: tagColor,
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  color: tagColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '($usageCount)',
                              style: TextStyle(
                                color: theme.appColors.base5,
                                fontSize: 12,
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

    // Najít * před cursorem
    int startPos = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '*') {
        startPos = i;
        break;
      }
    }

    if (startPos == -1) return;

    // Replace typed text s vybraným tagem
    final before = text.substring(0, startPos + 1);
    final after = text.substring(cursorPos);
    final newText = '$before$tagName*$after';

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: before.length + tagName.length + 1,
      ),
    );

    _removeOverlay();
  }

  /// Odstranit overlay
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 0,
          ),
          isDense: true,
          hintStyle: TextStyle(
            color: theme.appColors.base5,
            fontSize: 16,
          ),
        ),
        style: TextStyle(
          color: theme.appColors.fg,
          fontSize: 16,
        ),
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
