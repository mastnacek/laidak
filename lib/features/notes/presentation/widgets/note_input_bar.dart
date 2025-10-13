import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';

/// NoteInputBar - Fixed bottom input pro vytváření poznámek
///
/// Inspirováno TODO InputBar, ale jednodušší:
/// - Bez search mode (search bude v MILESTONE 5)
/// - Pouze přidání poznámky
/// - Edge-to-edge design
/// - Icon vlevo: note_add
/// - Icon vpravo: add (zelený)
/// - Expanded TextField mezi nimi
///
/// Layout:
/// ┌─────────────────────────────────────┐
/// │ [📝] [TextField______________] [➕]  │
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

  @override
  void initState() {
    super.initState();
    // Naslouchat změnám focusu
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Notifikovat parent o focus změně
    widget.onFocusChanged?.call(_focusNode.hasFocus);
  }

  Future<void> _onSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Přidat poznámku
    context.read<NotesBloc>().add(CreateNoteEvent(text));
    _controller.clear();

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
                  color: theme.appColors.yellow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
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
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSubmit(),
                    // KRITICKÉ: Při tapu VŽDY request focus (Android fix)
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                    // KRITICKÉ: Force show cursor (Android keyboard fix)
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
          ),
        ),
      ),
    );
  }
}
