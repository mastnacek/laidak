import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'theme/doom_one_theme.dart';
import 'models/todo_item.dart';
import 'services/database_helper.dart';
import 'services/tag_parser.dart';
import 'widgets/highlighted_text_field.dart';

void main() {
  // Inicializovat FFI pro desktop platformy (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Doom',
      theme: DoomOneTheme.darkTheme,
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final DatabaseHelper _db = DatabaseHelper();
  List<TodoItem> _todoItems = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;
  int? _expandedTaskId; // ID expandovaného úkolu

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  /// Načíst úkoly z databáze
  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final todos = await _db.getAllTodos();
    setState(() {
      _todoItems = todos;
      _isLoading = false;
    });
  }

  /// Přidat nový úkol s parsováním tagů
  Future<void> _addTodoItem(String taskText) async {
    if (taskText.trim().isEmpty) return;

    // Parsovat tagy
    final parsed = TagParser.parse(taskText);

    // Vytvořit TodoItem
    final todo = TodoItem(
      task: parsed.cleanText,
      priority: parsed.priority,
      dueDate: parsed.dueDate,
      action: parsed.action,
      tags: parsed.tags,
    );

    // Uložit do DB
    await _db.insertTodo(todo);

    // Reload
    await _loadTodos();
    _textController.clear();
  }

  /// Přepnout stav úkolu (hotovo/nehotovo)
  Future<void> _toggleTodoItem(TodoItem todo) async {
    await _db.toggleTodoStatus(todo.id!, !todo.isCompleted);
    await _loadTodos();
  }

  /// Smazat úkol
  Future<void> _removeTodoItem(TodoItem todo) async {
    await _db.deleteTodo(todo.id!);
    await _loadTodos();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO // DOOM'),
      ),
      body: Column(
        children: [
          // Formulář pro přidání nového úkolu
          Container(
            color: DoomOneTheme.bgAlt,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: HighlightedTextField(
                    controller: _textController,
                    hintText: '*a* *dnes* *udelat* nakoupit, *rodina*',
                    onSubmitted: _addTodoItem,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTodoItem(_textController.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: DoomOneTheme.base3),

          // Seznam úkolů
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _todoItems.isEmpty
                    ? Center(
                        child: Text(
                          'Zatím žádné úkoly.\nPřidej první úkol!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: DoomOneTheme.base5,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _todoItems.length,
                        itemBuilder: (context, index) {
                          final todo = _todoItems[index];
                          return _buildTodoCard(todo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Vytvořit kartu s úkolem
  Widget _buildTodoCard(TodoItem todo) {
    final isExpanded = _expandedTaskId == todo.id;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedTaskId = isExpanded ? null : todo.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DoomOneTheme.bgAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: todo.isCompleted ? DoomOneTheme.green : DoomOneTheme.base3,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => _toggleTodoItem(todo),
            ),
            const SizedBox(width: 8),

            // Obsah (ID + text + metadata)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // První řádek: ID + text úkolu
                  Row(
                    children: [
                      // ID
                      Text(
                        '[${todo.id}]',
                        style: TextStyle(
                          color: DoomOneTheme.base5,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text úkolu (oříznutý nebo plný)
                      Expanded(
                        child: Text(
                          todo.task,
                          maxLines: isExpanded ? null : 1,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.isCompleted
                                ? DoomOneTheme.base5
                                : DoomOneTheme.fg,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Druhý řádek: Metadata (priorita, datum, akce, tagy)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Priorita
                      if (todo.priority != null)
                        _buildTag(
                          '${TagParser.getPriorityIcon(todo.priority)} ${todo.priority!.toUpperCase()}',
                          _getPriorityColor(todo.priority!),
                        ),

                      // Datum
                      if (todo.dueDate != null)
                        _buildTag(
                          '📅 ${TagParser.formatDate(todo.dueDate!)}',
                          DoomOneTheme.blue,
                        ),

                      // Akce
                      if (todo.action != null)
                        _buildTag(
                          '${TagParser.getActionIcon(todo.action)} ${todo.action}',
                          DoomOneTheme.magenta,
                        ),

                      // Obecné tagy
                      ...todo.tags.map((tag) => _buildTag(
                            tag,
                            DoomOneTheme.cyan,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            // Tlačítko motivate
            _buildMotivateButton(todo),
            const SizedBox(width: 8),

            // Tlačítko smazat
            IconButton(
              icon: const Icon(Icons.delete_outline, color: DoomOneTheme.red),
              onPressed: () => _removeTodoItem(todo),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// Vytvořit tag chip
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Získat barvu pro prioritu
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'a':
        return DoomOneTheme.red;
      case 'b':
        return DoomOneTheme.yellow;
      case 'c':
        return DoomOneTheme.green;
      default:
        return DoomOneTheme.base5;
    }
  }

  /// Vytvořit pulzující růžové tlačítko motivate
  Widget _buildMotivateButton(TodoItem todo) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Puls efekt: 0.8 -> 1.0 -> 0.8
        final pulseValue = 0.8 + (0.2 * (0.5 - (value - 0.5).abs()) * 2);

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: DoomOneTheme.magenta.withOpacity(0.6 * pulseValue),
                blurRadius: 12 * pulseValue,
                spreadRadius: 3 * pulseValue,
              ),
            ],
          ),
          child: IconButton(
            icon: Text(
              'M',
              style: TextStyle(
                color: DoomOneTheme.magenta,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _motivateTask(todo),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        );
      },
      onEnd: () {
        // Nekonečná smyčka - restart animace
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  /// Získat AI motivaci pro úkol
  Future<void> _motivateTask(TodoItem todo) async {
    // TODO: Implementovat AI motivaci
    print('🎯 Motivate task #${todo.id}: ${todo.task}');
  }
}
