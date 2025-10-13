import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../models/note.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';

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
/// │                                     │
/// └─────────────────────────────────────┘
///
/// Features:
/// - Multiline text input (auto expand)
/// - Auto-save při navigaci zpět
/// - Delete s potvrzením
/// - TagAutocompleteField integrace (TODO v kroku 2)
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
    });

    // Auto-focus pro nové poznámky
    if (_isNewNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
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
      final newNote = Note(content: content);
      context.read<NotesBloc>().add(CreateNoteEvent(newNote));
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

              // Text Editor (full screen)
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _focusNode,
                  maxLines: null, // Multiline - expanduje s obsahem
                  expands: true, // Zabere celý Expanded prostor
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: 'Začni psát poznámku...\n\nPoužij *tag* pro tagy',
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
