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
class InputBar extends StatefulWidget {
  const InputBar({super.key});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchMode = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        // Přepnout do Search Mode
        _controller.clear();
        _focusNode.requestFocus();
      } else {
        // Vrátit do Add Mode
        context.read<TodoListBloc>().add(const ClearSearchEvent());
        _controller.clear();
      }
    });
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

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '🔍 Vyhledat úkol...',
                        border: InputBorder.none,
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
                      textInputAction: TextInputAction.search,
                    )
                  : HighlightedTextField(
                      controller: _controller,
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
    );
  }
}
