import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../services/tag_parser.dart';
import '../../../../widgets/kitt_scanner_loader.dart';
import '../../../tag_suggestions/domain/models/tag_suggestion.dart';
import '../../../tag_suggestions/data/services/tag_suggestion_service.dart';
import '../../../tag_suggestions/presentation/widgets/tag_suggestion_chip.dart';
import '../providers/todo_provider.dart';

/// InputBar - Fixed bottom input s maximální šířkou TextField
///
/// Specifikace:
/// - Edge-to-edge ikony (search vlevo, add vpravo)
/// - Expanded TextField = maximální šířka
/// - Height: 64dp
/// - Icon size: 24dp
/// - Touch target: 48x48dp
/// - Padding: 16dp horizontal
///
/// Funkce:
/// - Default mode: HighlightedTextField s TagParser (*a* *dnes* ...)
/// - Search mode: Normální TextField s debouncing
/// - Focus callback: Notifikuje parent o focus změnách (pro keyboard awareness)
class InputBar extends ConsumerStatefulWidget {
  /// Callback volaný při změně focus stavu
  final ValueChanged<bool>? onFocusChanged;

  const InputBar({
    super.key,
    this.onFocusChanged,
  });

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  Timer? _suggestionDebounceTimer;
  bool _isSearchMode = false;

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

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _debounceTimer?.cancel();
    _suggestionDebounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Notifikovat parent o focus změně POUZE v search mode
    // V add mode chceme vidět ViewBar/SortBar!
    widget.onFocusChanged?.call(_focusNode.hasFocus && _isSearchMode);
  }

  void _toggleSearchMode() {
    if (_isSearchMode) {
      // Křížek → zrušit filtr
      setState(() {
        _isSearchMode = false;
        ref.read(todoListProvider.notifier).clearSearch();
        _controller.clear();
        widget.onFocusChanged?.call(false);
      });
    } else {
      // Lupa → spustit vyhledávání
      final text = _controller.text.trim();
      if (text.isEmpty) {
        // Pokud je prázdné pole, jen přepnout do search mode
        setState(() {
          _isSearchMode = true;
          widget.onFocusChanged?.call(true);
        });
        // KRITICKÉ: Request focus AFTER setState (Android keyboard fix)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        // Máme text → vyhledat a přepnout do search mode
        setState(() {
          _isSearchMode = true;
          widget.onFocusChanged?.call(true);
        });
        // KRITICKÉ: Request focus AFTER setState (Android keyboard fix)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
        ref.read(todoListProvider.notifier).searchTodos(text);
      }
    }
  }

  Future<void> _onSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_isSearchMode) {
      // V search mode jen vyhledáváme
      context.read<TodoListBloc>().add(SearchTodosEvent(text));
    } else {
      // V normal mode přidáme TODO s TagParser
      final parsed = await TagParser.parse(text);

      if (mounted) {
        ref.read(todoListProvider.notifier).addTodo(
              taskText: parsed.cleanText,
              priority: parsed.priority,
              dueDate: parsed.dueDate,
              tags: parsed.tags,
            );
        _controller.clear();
      }
    }
  }

  void _onTextChanged(String text) {
    if (_isSearchMode) {
      // Cancel předchozí timer
      _debounceTimer?.cancel();

      // Spustit nový timer (300ms debounce)
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        ref.read(todoListProvider.notifier).searchTodos(text);
      });
    } else {
      // V add mode: trigger tag suggestions
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
  }

  /// Načte DB tag suggestions (INSTANT autocomplete)
  Future<void> _fetchDbTagSuggestions(String text) async {
    try {
      // Naparsovat již použité tagy
      final parsedTask = await TagParser.parse(text);
      final usedTags = <String>[
        if (parsedTask.priority != null) parsedTask.priority!,
        ...parsedTask.tags,
      ];

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
      final parsedTask = await TagParser.parse(text);
      final usedTags = <String>[
        if (parsedTask.priority != null) parsedTask.priority!,
        ...parsedTask.tags,
      ];

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<TodoListBloc, TodoListState>(
      listener: (context, state) {
        // Reagovat na předvyplněný text z kalendáře
        if (state is TodoListLoaded && state.prepopulatedText != null) {
          // KRITICKÉ: Zkontrolovat, zda je widget stále mounted
          if (!mounted) return;

          // Nastavit text a focus
          _controller.text = state.prepopulatedText!;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );

          // Request focus po frame render (Android keyboard fix)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _focusNode.requestFocus();

              // Vyčistit prepopulated text ve state POUZE pokud je widget stále mounted
              if (mounted) {
                ref.read(todoListProvider.notifier).clearPrepopulatedText();
              }
            }
          });
        }
      },
      child: Semantics(
        label: 'Panel pro přidání úkolu a vyhledávání',
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.appColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.appColors.base3.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.appColors.cyan.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input Row (search icon + TextField + add button)
                Row(
                  children: [
                    // Search icon (edge-aligned)
                    IconButton(
                      icon: Icon(
                        _isSearchMode ? Icons.close : Icons.search,
                        size: 24,
                      ),
                      tooltip: _isSearchMode ? 'Zrušit vyhledávání' : 'Vyhledat úkol',
                      color: _isSearchMode
                          ? theme.appColors.red
                          : theme.appColors.base5,
                      onPressed: _toggleSearchMode,
                    ),

                    // TextField (EXPANDED = maximální šířka!)
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: _isSearchMode
                              ? '🔍 Vyhledat úkol...'
                              : '*a* *dnes* nakoupit...',
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
                        // KRITICKÉ: Při tapu VŽDY request focus (Android fix)
                        onTap: () {
                          _focusNode.requestFocus();
                        },
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _onSubmit(),
                        textInputAction: _isSearchMode
                            ? TextInputAction.search
                            : TextInputAction.done,
                        // KRITICKÉ: Force show cursor (Android keyboard fix)
                        showCursor: true,
                        autofocus: false,
                      ),
                    ),

                    // Add button (edge-aligned, skrytý v search mode)
                    if (_isSearchMode)
                      const SizedBox(width: 48)
                    else
                      IconButton(
                        icon: const Icon(Icons.add, size: 24),
                        tooltip: 'Přidat úkol',
                        color: theme.appColors.green,
                        onPressed: _onSubmit,
                      ),
                  ],
                ),

                // Tag suggestions row (pod inputem, pouze v add mode)
                // SLOUČENO: DB suggestions (instant) + AI suggestions (debounced)
                if (!_isSearchMode && (_dbSuggestions.isNotEmpty || _aiSuggestions.isNotEmpty || _isLoadingAiSuggestions))
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
                            color: theme.appColors.cyan,
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
                                  // Odfiltrovat duplicity (pokud AI navrhla tag, který už je v DB suggestions)
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
      ),
    );
  }
}
