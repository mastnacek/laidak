import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../widgets/kitt_scanner_loader.dart';
import '../../../tag_suggestions/domain/models/tag_suggestion.dart';
import '../../../tag_suggestions/data/services/tag_suggestion_service.dart';
import '../../../tag_suggestions/presentation/widgets/tag_suggestion_chip.dart';
import '../../domain/services/notes_tag_parser.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';

/// NoteInputBar - Fixed bottom input pro vytváření poznámek
///
/// Inspirováno TODO InputBar:
/// - Tag autocomplete (stejně jako v TODO)
/// - AI Tag Suggestions (real-time, debounce z DB settings)
/// - Dynamické oddělovače z nastavení
/// - Edge-to-edge design
/// - Icon vlevo: note_add
/// - Icon vpravo: add (zelený)
/// - Expanded TagAutocompleteField mezi nimi
///
/// Layout:
/// ┌─────────────────────────────────────┐
/// │ [📝] [TagAutocomplete_________] [➕]  │
/// │     [AI Tag Suggestions ...]         │
/// └─────────────────────────────────────┘
class NoteInputBar extends StatefulWidget {
  /// Callback volaný při změně focus stavu
  final ValueChanged<bool>? onFocusChanged;

  const NoteInputBar({
    super.key,
    this.onFocusChanged,
  });

  @override
  State<NoteInputBar> createState() => _NoteInputBarState();
}

class _NoteInputBarState extends State<NoteInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _suggestionDebounceTimer;

  // Tag suggestions state
  List<TagSuggestion> _aiSuggestions = []; // AI návrhy (debounced)
  List<TagSuggestion> _dbSuggestions = []; // DB návrhy (instant)
  bool _isLoadingAiSuggestions = false;
  int _debounceDelayMs = 1000; // Default, načte se z DB

  @override
  void initState() {
    super.initState();
    // Naslouchat změnám focusu
    _focusNode.addListener(_onFocusChange);
    // Načíst debounce delay z DB
    _loadDebounceDelay();
  }

  @override
  void dispose() {
    _suggestionDebounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Notifikovat parent o focus změně
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  /// Načte ai_tag_suggestions_debounce_ms z databáze
  Future<void> _loadDebounceDelay() async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final debounceMs = settings['ai_tag_suggestions_debounce_ms'] as int? ?? 1000;

      if (mounted) {
        setState(() {
          _debounceDelayMs = debounceMs;
        });
      }
    } catch (e) {
      // Fallback na default 1000ms
      if (mounted) {
        setState(() {
          _debounceDelayMs = 1000;
        });
      }
    }
  }

  /// Handle text změny - trigger DB + AI suggestions
  void _onTextChanged(String text) {
    _suggestionDebounceTimer?.cancel();

    // Pokud je text prázdný, clear suggestions
    if (text.trim().isEmpty) {
      setState(() {
        _dbSuggestions = [];
        _aiSuggestions = [];
      });
      return;
    }

    // 1. INSTANT: Načíst DB tag suggestions (autocomplete)
    _fetchDbTagSuggestions(text);

    // 2. DEBOUNCED: Spustit timer pro AI tag suggestions
    _suggestionDebounceTimer = Timer(Duration(milliseconds: _debounceDelayMs), () {
      _fetchAiTagSuggestions(text);
    });
  }

  /// Načte DB tag suggestions (INSTANT autocomplete)
  Future<void> _fetchDbTagSuggestions(String text) async {
    try {
      // Naparsovat již použité tagy
      final usedTags = await NotesTagParser.extractTags(text);

      // Hledat tagy v DB (searchTags)
      final db = DatabaseHelper();
      final results = await db.searchTags(text, limit: 10);

      // Převést na TagSuggestion a odfiltrovat použité
      final suggestions = results
          .where((tag) => !usedTags.contains(tag['tag_name'] as String))
          .map((tag) => TagSuggestion(
                tagName: tag['tag_name'] as String,
                isExisting: true,
                confidence: 1.0, // DB match = 100% confidence
                color: tag['color'] as String?,
                emoji: tag['emoji'] as String?,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _dbSuggestions = suggestions;
        });
      }
    } catch (e) {
      // Graceful degradation
      if (mounted) {
        setState(() {
          _dbSuggestions = [];
        });
      }
    }
  }

  /// Načte AI tag suggestions (DEBOUNCED, pro delší text)
  Future<void> _fetchAiTagSuggestions(String text) async {
    if (text.trim().length < 15) {
      setState(() => _aiSuggestions = []);
      return;
    }

    setState(() => _isLoadingAiSuggestions = true);

    try {
      final db = DatabaseHelper();
      final settings = await db.getSettings();
      final apiKey = settings['openrouter_api_key'] as String? ?? '';

      // Naparsovat již použité tagy z textu (programově odfiltrujeme)
      final usedTags = await NotesTagParser.extractTags(text);

      final service = TagSuggestionService(db, apiKey);
      final suggestions = await service.suggestTags(text, usedTags: usedTags);

      if (mounted) {
        setState(() {
          _aiSuggestions = suggestions;
          _isLoadingAiSuggestions = false;
        });
      }
    } catch (e) {
      // Graceful degradation - při chybě jen clear suggestions
      if (mounted) {
        setState(() {
          _aiSuggestions = [];
          _isLoadingAiSuggestions = false;
        });
      }
    }
  }

  /// Vloží tag do input fieldu na aktuální pozici kurzoru
  ///
  /// DŮLEŽITÉ: Používá delimitery z DB (tag_delimiter_start/end)
  /// a přidává mezeru ZA původní text před tagem
  Future<void> _insertTag(String tagName) async {
    // Načíst delimitery z DB
    final db = DatabaseHelper();
    final settings = await db.getSettings();
    final delimiterStart = settings['tag_delimiter_start'] as String? ?? '*';
    final delimiterEnd = settings['tag_delimiter_end'] as String? ?? '*';

    final currentText = _controller.text;
    final selection = _controller.selection;

    // Pokud nemáme selection, append na konec
    if (!selection.isValid) {
      // Přidat mezeru ZA text (pokud text neexistuje nebo už končí mezerou, nepřidávat)
      final needsSpace = currentText.isNotEmpty && !currentText.endsWith(' ');
      final space = needsSpace ? ' ' : '';
      final newText = '$currentText$space$delimiterStart$tagName$delimiterEnd ';
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    } else {
      // Insert na pozici kurzoru
      final before = currentText.substring(0, selection.start);
      final after = currentText.substring(selection.end);

      // Přidat mezeru ZA before text (pokud before neexistuje nebo už končí mezerou, nepřidávat)
      final needsSpace = before.isNotEmpty && !before.endsWith(' ');
      final space = needsSpace ? ' ' : '';
      final newText = '$before$space$delimiterStart$tagName$delimiterEnd $after';

      _controller.text = newText;
      final cursorOffset = before.length + space.length + delimiterStart.length + tagName.length + delimiterEnd.length + 1; // +1 = mezera za tagem
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorOffset),
      );
    }

    // DŮLEŽITÉ: Nechat suggestions viditelné po insertu!
    // User může chtít vložit více tagů najednou.
    // Suggestions zmizí až při další změně textu (onChanged).
  }

  Future<void> _onSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Přidat poznámku
    context.read<NotesBloc>().add(CreateNoteEvent(text));
    _controller.clear();

    // Clear suggestions po submitu
    setState(() {
      _dbSuggestions = [];
      _aiSuggestions = [];
    });

    // Unfocus po přidání
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro přidání poznámky',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.appColors.bgAlt,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.appColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.appColors.base3.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.appColors.yellow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input row
                Row(
                  children: [
                    // Note icon (edge-aligned)
                    IconButton(
                      icon: const Icon(
                        Icons.note_add_outlined,
                        size: 24,
                      ),
                      tooltip: 'Nová poznámka',
                      color: theme.appColors.base5,
                      onPressed: () {
                        _focusNode.requestFocus();
                      },
                    ),

                    // TextField (EXPANDED = maximální šířka!)
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Nová poznámka... *tag*',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
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
                        onTap: () {
                          _focusNode.requestFocus();
                        },
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _onSubmit(),
                        textInputAction: TextInputAction.done,
                        showCursor: true,
                      ),
                    ),

                    // Add button (edge-aligned)
                    IconButton(
                      icon: const Icon(Icons.add, size: 24),
                      tooltip: 'Přidat poznámku',
                      color: theme.appColors.green,
                      onPressed: _onSubmit,
                    ),
                  ],
                ),

                // Tag suggestions row (pod inputem)
                // SLOUČENO: DB suggestions (instant) + AI suggestions (debounced)
                if (_dbSuggestions.isNotEmpty || _aiSuggestions.isNotEmpty || _isLoadingAiSuggestions)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 8,
                      bottom: 4,
                      left: 8,
                      right: 8,
                    ),
                    child: _isLoadingAiSuggestions && _dbSuggestions.isEmpty
                        ? KittScannerLoader(
                            color: theme.appColors.red,
                            height: 4.0,
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              // DB suggestions first (instant autocomplete)
                              ..._dbSuggestions.map((suggestion) => TagSuggestionChip(
                                    suggestion: suggestion,
                                    onTap: () => _insertTag(suggestion.tagName),
                                  )),
                              // AI suggestions after (debounced, contextuální)
                              ..._aiSuggestions
                                  // Odfiltrovat duplicity
                                  .where((aiSug) => !_dbSuggestions.any((dbSug) => dbSug.tagName == aiSug.tagName))
                                  .map((suggestion) => TagSuggestionChip(
                                        suggestion: suggestion,
                                        onTap: () => _insertTag(suggestion.tagName),
                                      )),
                            ],
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
