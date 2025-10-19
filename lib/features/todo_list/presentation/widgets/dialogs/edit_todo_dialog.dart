import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/theme_colors.dart';
import '../../../../../core/services/database_helper.dart';
import '../../../../../services/tag_parser.dart';
import '../../../../../widgets/tag_autocomplete_field.dart';
import '../../../../../widgets/kitt_scanner_loader.dart';
import '../../../../tag_suggestions/domain/models/tag_suggestion.dart';
import '../../../../tag_suggestions/data/services/tag_suggestion_service.dart';
import '../../../../tag_suggestions/presentation/widgets/tag_suggestion_chip.dart';
import '../../../domain/entities/todo.dart';
import '../../bloc/todo_list_bloc.dart';
import '../../bloc/todo_list_event.dart';
import '../../../../../features/ai_split/presentation/widgets/ai_split_button.dart';

/// Dialog pro editaci TODO úkolu
///
/// Features:
/// - Tag autocomplete (TagAutocompleteField)
/// - AI Tag Suggestions (real-time, debounce 500ms)
/// - Tag parsing (priorita, datum, tagy)
/// - Share button (📤)
/// - AI Split button (🤖)
/// - Responsive layout (min 3mm margins)
class EditTodoDialog {
  /// Zobrazit editační dialog
  static Future<void> show(
    BuildContext context, {
    required Todo todo,
    required Future<void> Function() onShare,
  }) async {
    final theme = Theme.of(context);

    // Rekonstruovat text s tagy pro editaci (async)
    final textWithTags = await TagParser.reconstructWithTags(
      cleanText: todo.task,
      priority: todo.priority,
      dueDate: todo.dueDate,
      tags: todo.tags,
    );

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.yellow, width: 2),
        ),
        // Minimální okraje pro maximální prostor (10px = cca 3mm na každé straně)
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: _EditTodoDialogContent(
          initialText: textWithTags,
          todo: todo,
          onShare: onShare,
        ),
      ),
    );

    // Pokud byl text změněn, uložit do databáze
    if (result != null && context.mounted) {
      // Parsovat tagy z nového textu (async)
      final parsed = await TagParser.parse(result);

      // Vytvořit aktualizovaný Todo
      final updatedTodo = todo.copyWith(
        task: parsed.cleanText,
        priority: parsed.priority,
        dueDate: parsed.dueDate,
        tags: parsed.tags,
      );

      if (context.mounted) {
        context.read<TodoListBloc>().add(UpdateTodoEvent(updatedTodo));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Úkol byl aktualizován'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    }
  }
}

/// Stateful widget pro dialog content s AI tag suggestions
class _EditTodoDialogContent extends StatefulWidget {
  final String initialText;
  final Todo todo;
  final Future<void> Function() onShare;

  const _EditTodoDialogContent({
    required this.initialText,
    required this.todo,
    required this.onShare,
  });

  @override
  State<_EditTodoDialogContent> createState() => _EditTodoDialogContentState();
}

class _EditTodoDialogContentState extends State<_EditTodoDialogContent> {
  late final TextEditingController _controller;
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
    _controller = TextEditingController(text: widget.initialText);
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
    _suggestionDebounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.minHeight,
              maxHeight: viewportConstraints.maxHeight,
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 100),
              curve: Curves.decelerate,
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: IntrinsicHeight(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header (kompaktní - nadpis nad ikonami)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nadpis
                          Row(
                            children: [
                              Icon(Icons.edit,
                                  color: theme.appColors.yellow, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Editace',
                                style: TextStyle(
                                  color: theme.appColors.yellow,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Akční ikony
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Share button (emoji)
                              GestureDetector(
                                onTap: () async {
                                  await widget.onShare();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Text('📤',
                                      style: TextStyle(fontSize: 24)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // AI Split button
                              AiSplitButton(todo: widget.todo),
                              const SizedBox(width: 4),
                              // Close button
                              IconButton(
                                icon: Icon(Icons.close,
                                    color: theme.appColors.base5, size: 22),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Divider(color: theme.appColors.base3, height: 16),

                      // Scrollable TagAutocompleteField (Expanded = využije maximum prostoru)
                      Expanded(
                        child: TagAutocompleteField(
                          controller: _controller,
                          focusNode: _focusNode,
                          hintText: '*a* *dnes* *udelat* nakoupit, *rodina*',
                          onChanged: _onTextChanged,
                        ),
                      ),

                      // Tag suggestions row (pod inputem)
                      // SLOUČENO: DB suggestions (instant) + AI suggestions (debounced)
                      if (_dbSuggestions.isNotEmpty || _aiSuggestions.isNotEmpty || _isLoadingAiSuggestions)
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 8,
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
                                        .where((aiSug) => !_dbSuggestions.any((dbSug) => dbSug.tagName == aiSug.tagName))
                                        .map((suggestion) => TagSuggestionChip(
                                              suggestion: suggestion,
                                              onTap: () => _insertTag(suggestion.tagName),
                                            )),
                                  ],
                                ),
                        ),

                      const SizedBox(height: 16),

                      // Tlačítka
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Zrušit',
                                style: TextStyle(
                                    color: theme.appColors.base5,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_controller.text.trim().isNotEmpty) {
                                Navigator.of(context)
                                    .pop(_controller.text.trim());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.appColors.yellow,
                              foregroundColor: theme.appColors.bg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Uložit',
                                style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
