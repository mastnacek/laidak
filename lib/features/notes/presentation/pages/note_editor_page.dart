import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../models/note.dart';
import '../../../../widgets/kitt_scanner_loader.dart';
import '../../../tag_suggestions/domain/models/tag_suggestion.dart';
import '../../../tag_suggestions/data/services/tag_suggestion_service.dart';
import '../../../tag_suggestions/presentation/widgets/tag_suggestion_chip.dart';
import '../../domain/services/notes_tag_parser.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../widgets/notes_tag_autocomplete_field.dart';

/// NoteEditorPage - Full screen editor pro poznámky (MILESTONE 3)
///
/// Layout:
/// ┌─────────────────────────────────────┐
/// │ AppBar: [← Back] [Save] [Delete]    │
/// ├─────────────────────────────────────┤
/// │                                     │
/// │ TextField (full screen):            │
/// │                                     │
/// │ Text content s tagy *tag*...        │
/// │                                     │
/// │ [AI Tag Suggestions ...]            │
/// └─────────────────────────────────────┘
///
/// Features:
/// - Multiline text input (auto expand)
/// - AI Tag Suggestions (real-time, debounce z DB settings)
/// - Auto-save při navigaci zpět
/// - Delete s potvrzením
/// - TagAutocompleteField integrace
class NoteEditorPage extends StatefulWidget {
  final Note? note; // Null = vytváříme novou poznámku

  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _contentController;
  late final FocusNode _focusNode;
  bool _hasChanges = false;
  bool _isNewNote = false;
  Timer? _suggestionDebounceTimer;

  // Tag suggestions state
  List<TagSuggestion> _aiSuggestions = []; // AI návrhy (debounced)
  List<TagSuggestion> _dbSuggestions = []; // DB návrhy (instant)
  bool _isLoadingAiSuggestions = false;
  int _debounceDelayMs = 1000; // Default, načte se z DB

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _focusNode = FocusNode();

    // Track changes
    _contentController.addListener(() {
      if (!_hasChanges && _contentController.text != (widget.note?.content ?? '')) {
        setState(() {
          _hasChanges = true;
        });
      }
      // Trigger AI suggestions
      _onTextChanged(_contentController.text);
    });

    // Auto-focus pro nové poznámky
    if (_isNewNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }

    // Načíst debounce delay z DB
    _loadDebounceDelay();
  }

  @override
  void dispose() {
    _suggestionDebounceTimer?.cancel();
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
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
                confidence: 1.0,
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

    final currentText = _contentController.text;
    final selection = _contentController.selection;

    // Pokud nemáme selection, append na konec
    if (!selection.isValid) {
      // Přidat mezeru ZA text (pokud text neexistuje nebo už končí mezerou, nepřidávat)
      final needsSpace = currentText.isNotEmpty && !currentText.endsWith(' ');
      final space = needsSpace ? ' ' : '';
      final newText = '$currentText$space$delimiterStart$tagName$delimiterEnd ';
      _contentController.text = newText;
      _contentController.selection = TextSelection.fromPosition(
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

      _contentController.text = newText;
      final cursorOffset = before.length + space.length + delimiterStart.length + tagName.length + delimiterEnd.length + 1; // +1 = mezera za tagem
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorOffset),
      );
    }

    // DŮLEŽITÉ: Nechat suggestions viditelné po insertu!
    // User může chtít vložit více tagů najednou.
    // Suggestions zmizí až při další změně textu (onChanged).
  }

  /// Uložit změny
  Future<void> _saveNote() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      // Prázdná poznámka - nepokračovat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poznámka nemůže být prázdná'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isNewNote) {
      // Vytvořit novou poznámku
      context.read<NotesBloc>().add(CreateNoteEvent(content));
    } else {
      // Aktualizovat existující
      final updatedNote = widget.note!.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
      context.read<NotesBloc>().add(UpdateNoteEvent(updatedNote));
    }

    setState(() {
      _hasChanges = false;
      _dbSuggestions = []; // Clear suggestions po uložení
      _aiSuggestions = [];
    });

    // Zobrazit potvrzení
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poznámka uložena'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    // Zavřít editor po uložení (pro nové poznámky)
    if (_isNewNote && mounted) {
      Navigator.pop(context);
    }
  }

  /// Smazat poznámku
  Future<void> _deleteNote() async {
    if (_isNewNote || widget.note == null) {
      // Nová poznámka - jen zavřít
      Navigator.pop(context);
      return;
    }

    // Potvrzení před smazáním
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat poznámku?'),
        content: const Text('Tato akce je nevratná.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Smazat',
              style: TextStyle(color: Theme.of(context).appColors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<NotesBloc>().add(DeleteNoteEvent(widget.note!.id!));
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Handler pro Back button (s auto-save)
  Future<bool> _onWillPop() async {
    if (_hasChanges && _contentController.text.trim().isNotEmpty) {
      await _saveNote();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.appColors.bg,
        appBar: AppBar(
          backgroundColor: theme.appColors.bgAlt,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.appColors.fg),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _isNewNote ? 'Nová poznámka' : 'Upravit poznámku',
            style: TextStyle(color: theme.appColors.fg),
          ),
          actions: [
            // Save button
            IconButton(
              icon: Icon(
                Icons.save,
                color: _hasChanges ? theme.appColors.green : theme.appColors.base5,
              ),
              onPressed: _hasChanges ? _saveNote : null,
              tooltip: 'Uložit',
            ),
            // Delete button (pouze pro existující poznámky)
            if (!_isNewNote)
              IconButton(
                icon: Icon(Icons.delete, color: theme.appColors.red),
                onPressed: _deleteNote,
                tooltip: 'Smazat',
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Metadata (pro existující poznámky)
              if (!_isNewNote && widget.note != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.appColors.base5,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Vytvořeno: ${_formatDateTime(widget.note!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.appColors.base5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.update,
                        size: 14,
                        color: theme.appColors.base5,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Upraveno: ${_formatDateTime(widget.note!.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.appColors.base5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Text Editor (full screen) - s tag autocomplete
              Expanded(
                child: NotesTagAutocompleteField(
                  controller: _contentController,
                  focusNode: _focusNode,
                  // Když expands: true, maxLines musí být null (řešeno ve widgetu)
                  expands: true, // Zabere celý Expanded prostor
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  hintText: 'Začni psát poznámku...\n\nPoužij *tag* pro tagy',
                ),
              ),

              // Tag suggestions row (pod text editorem)
              // SLOUČENO: DB suggestions (instant) + AI suggestions (debounced)
              if (_dbSuggestions.isNotEmpty || _aiSuggestions.isNotEmpty || _isLoadingAiSuggestions)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: _isLoadingAiSuggestions && _dbSuggestions.isEmpty
                      ? KittScannerLoader(
                          color: theme.appColors.red,
                          height: 4.0,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Návrhy tagů:',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.appColors.base5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
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
                                    .where((aiSug) => !_dbSuggestions.any((dbSug) => dbSug.tagName == aiSug.tagName))
                                    .map((suggestion) => TagSuggestionChip(
                                          suggestion: suggestion,
                                          onTap: () => _insertTag(suggestion.tagName),
                                        )),
                              ],
                            ),
                          ],
                        ),
                ),

              // Bottom hint
              if (_hasChanges)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.appColors.yellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Neuložené změny - klikni Uložit nebo se vrať zpět',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.appColors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format DateTime pro zobrazení
  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
