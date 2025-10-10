import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../services/tag_parser.dart';
import '../../../../widgets/highlighted_text_field.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';

/// Widget pro input form s dual mode:
/// - Default Mode: Přidání TODO úkolu
/// - Search Mode: Vyhledávání v úkolech (aktivováno lupou)
///
/// UI Design:
/// ┌─────────────────────────────────────────────────┐
/// │  🔍  [TextField: *a* *dnes* nakoupit...]   ➕  │
/// └─────────────────────────────────────────────────┘
///
/// **Default Mode:**
/// - Placeholder: `*a* *dnes* *udelat* nakoupit, *rodina*`
/// - OnSubmit → přidat TODO úkol
/// - Ikona vlevo: 🔍 (šedá, kliknutelná)
/// - Ikona vpravo: ➕ (zelená, submit button)
///
/// **Search Mode (aktivováno kliknutím na 🔍):**
/// - Placeholder: `🔍 Vyhledat úkol...`
/// - OnChange → vyhledávání (debounced 300ms)
/// - Ikona vlevo: ✖️ (červená, clear search + exit search mode)
/// - Ikona vpravo: ➕ (disabled, šedá)
///
/// **Transition:**
/// - Klik na 🔍 → switch to Search Mode + focus TextField
/// - Klik na ✖️ → clear search + switch to Add Mode
/// - ESC key → clear search + switch to Add Mode (pokud v Search Mode)
class TodoInputForm extends StatefulWidget {
  const TodoInputForm({super.key});

  @override
  State<TodoInputForm> createState() => _TodoInputFormState();
}

class _TodoInputFormState extends State<TodoInputForm> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchMode = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Toggle mezi Add Mode a Search Mode
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        // Přepnout do Search Mode
        _textController.clear();
        _focusNode.requestFocus();
      } else {
        // Vrátit do Add Mode
        context.read<TodoListBloc>().add(const ClearSearchEvent());
        _textController.clear();
      }
    });
  }

  /// Handler pro změnu textu (search mode)
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

  /// Přidat nový úkol s parsováním tagů (Add mode)
  Future<void> _addTodoItem(String taskText) async {
    if (taskText.trim().isEmpty || _isSearchMode) return;

    // Parsovat tagy (async)
    final parsed = await TagParser.parse(taskText);

    // Dispatch AddTodoEvent
    if (mounted) {
      context.read<TodoListBloc>().add(
            AddTodoEvent(
              taskText: parsed.cleanText,
              priority: parsed.priority,
              dueDate: parsed.dueDate,
              tags: parsed.tags,
            ),
          );

      // Vyčistit textfield
      _textController.clear();
    }
  }

  /// Handler pro ESC key (exit search mode)
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _isSearchMode) {
      _toggleSearchMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.appColors.bgAlt,
      padding: const EdgeInsets.all(16.0),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Row(
          children: [
            // Ikona vlevo (🔍 v Add Mode, ✖️ v Search Mode)
            IconButton(
              icon: Icon(
                _isSearchMode ? Icons.close : Icons.search,
                color: _isSearchMode
                    ? theme.appColors.red
                    : theme.appColors.base5,
              ),
              tooltip: _isSearchMode ? 'Zrušit hledání' : 'Vyhledat úkol',
              onPressed: _toggleSearchMode,
            ),
            const SizedBox(width: 8),

            // TextField (highlight v Add Mode, plain v Search Mode)
            Expanded(
              child: _isSearchMode
                  ? TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '🔍 Vyhledat úkol...',
                        hintStyle: TextStyle(color: theme.appColors.base5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: theme.appColors.base3, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: theme.appColors.base3, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: theme.appColors.yellow, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: TextStyle(color: theme.appColors.fg),
                      onChanged: _onTextChanged,
                    )
                  : HighlightedTextField(
                      controller: _textController,
                      hintText: '*a* *dnes* *udelat* nakoupit, *rodina*',
                      onSubmitted: _addTodoItem,
                    ),
            ),
            const SizedBox(width: 8),

            // Ikona vpravo (➕ button, disabled v Search Mode)
            ElevatedButton(
              onPressed: _isSearchMode
                  ? null // Disabled v Search Mode
                  : () => _addTodoItem(_textController.text),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _isSearchMode
                    ? theme.appColors.base3
                    : theme.appColors.green,
                disabledBackgroundColor: theme.appColors.base3,
              ),
              child: Icon(
                Icons.add,
                color: _isSearchMode ? theme.appColors.base5 : theme.appColors.bg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
