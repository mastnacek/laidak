import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../services/tag_parser.dart';
import '../../../../widgets/highlighted_text_field.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

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
class InputBar extends StatefulWidget {
  /// Callback volaný při změně focus stavu
  final ValueChanged<bool>? onFocusChanged;

  const InputBar({
    super.key,
    this.onFocusChanged,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    // Naslouchat změnám focusu
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _debounceTimer?.cancel();
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
        context.read<TodoListBloc>().add(const ClearSearchEvent());
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
          _focusNode.requestFocus();
          widget.onFocusChanged?.call(true);
        });
      } else {
        // Máme text → vyhledat a přepnout do search mode
        setState(() {
          _isSearchMode = true;
          widget.onFocusChanged?.call(true);
        });
        context.read<TodoListBloc>().add(SearchTodosEvent(text));
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
        context.read<TodoListBloc>().add(
              AddTodoEvent(
                taskText: parsed.cleanText,
                priority: parsed.priority,
                dueDate: parsed.dueDate,
                tags: parsed.tags,
              ),
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
        context.read<TodoListBloc>().add(SearchTodosEvent(text));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Panel pro přidání úkolu a vyhledávání',
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: theme.appColors.bgAlt,
          border: Border(
            top: BorderSide(
              color: theme.appColors.base3,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
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
              child: _isSearchMode
                  ? GestureDetector(
                      onTap: () {
                        // Při tapu vždy požádat o focus a otevřít klávesnici
                        if (!_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: '🔍 Vyhledat úkol...',
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
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _onSubmit(),
                        textInputAction: TextInputAction.search,
                      ),
                    )
                  : HighlightedTextField(
                      controller: _controller,
                      focusNode: _focusNode, // Předat focusNode!
                      hintText: '*a* *dnes* nakoupit...',
                      onSubmitted: (_) => _onSubmit(),
                    ),
            ),

            // Add button (edge-aligned, skrytý v search mode)
            BlocBuilder<TodoListBloc, TodoListState>(
              builder: (context, state) {
                if (_isSearchMode) {
                  return const SizedBox(width: 48);
                }

                return IconButton(
                  icon: const Icon(Icons.add, size: 24),
                  tooltip: 'Přidat úkol',
                  color: theme.appColors.green,
                  onPressed: _onSubmit,
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}
