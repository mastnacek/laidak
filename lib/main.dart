import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'theme/doom_one_theme.dart';
import 'theme/theme_colors.dart';
import 'models/todo_item.dart';
import 'providers/theme_provider.dart';
import 'services/database_helper.dart';
import 'services/tag_parser.dart';
import 'services/tag_service.dart';
import 'services/ai_service.dart';
import 'services/sound_manager.dart';
import 'widgets/highlighted_text_field.dart';
import 'widgets/typewriter_text.dart';
import 'pages/settings_page.dart';

void main() async {
  // Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializovat FFI pro desktop platformy (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializovat TagService (načíst definice tagů do cache)
  await TagService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'TODO Doom',
          theme: themeProvider.currentTheme,
          home: const TodoListPage(),
        );
      },
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
  bool _showCompleted = false; // Zobrazit hotové úkoly?

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

    // Parsovat tagy (async)
    final parsed = await TagParser.parse(taskText);

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
    final theme = Theme.of(context);
    // Filtrovat úkoly podle _showCompleted
    final displayedTodos = _showCompleted
        ? _todoItems
        : _todoItems.where((todo) => !todo.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO // DOOM'),
        actions: [
          // Toggle pro zobrazení/skrytí hotových úkolů
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
              color: _showCompleted ? theme.appColors.green : theme.appColors.base5,
            ),
            tooltip: _showCompleted ? 'Skrýt hotové úkoly' : 'Zobrazit hotové úkoly',
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Nastavení',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulář pro přidání nového úkolu
          Container(
            color: theme.appColors.bgAlt,
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
          Divider(height: 1, color: theme.appColors.base3),

          // Seznam úkolů
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedTodos.isEmpty
                    ? Center(
                        child: Text(
                          _showCompleted
                              ? 'Žádné hotové úkoly.'
                              : 'Zatím žádné úkoly.\nPřidej první úkol!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.appColors.base5,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedTodos.length,
                        itemBuilder: (context, index) {
                          final todo = displayedTodos[index];
                          return _buildTodoCard(todo);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Editovat úkol
  Future<void> _editTodoItem(TodoItem todo) async {
    // Rekonstruovat text s tagy pro editaci (async)
    final textWithTags = await TagParser.reconstructWithTags(
      cleanText: todo.task,
      priority: todo.priority,
      dueDate: todo.dueDate,
      action: todo.action,
      tags: todo.tags,
    );

    final controller = TextEditingController(text: textWithTags);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.yellow, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit, color: theme.appColors.yellow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'EDITOVAT ÚKOL',
                      style: TextStyle(
                        color: theme.appColors.yellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.appColors.base5),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: theme.appColors.base3, height: 24),

              // TextField pro text úkolu
              Text(
                'Text úkolu:',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: TextStyle(color: theme.appColors.fg, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Zadej text úkolu...',
                  hintStyle: TextStyle(color: theme.appColors.base5),
                  filled: true,
                  fillColor: theme.appColors.base2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.appColors.base4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.appColors.yellow, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tlačítka
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.of(context).pop(controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.appColors.yellow,
                      foregroundColor: theme.appColors.bg,
                    ),
                    child: const Text('Uložit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Pokud byl text změněn, uložit do databáze
    if (result != null && result != todo.task) {
      // Parsovat tagy z nového textu (async)
      final parsed = await TagParser.parse(result);

      // Vytvořit aktualizovaný TodoItem
      final updatedTodo = todo.copyWith(
        task: parsed.cleanText,
        priority: parsed.priority,
        dueDate: parsed.dueDate,
        action: parsed.action,
        tags: parsed.tags,
      );

      await _db.updateTodo(updatedTodo);
      await _loadTodos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Úkol byl aktualizován'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    }
  }

  /// Získat barvu rámečku úkolu podle stavu a priority
  Color _getTodoBorderColor(TodoItem todo, BuildContext context) {
    final theme = Theme.of(context);
    if (todo.isCompleted) {
      // Splněné úkoly = neonově cyan (Doom One styl)
      return theme.appColors.cyan;
    } else {
      // Nesplněné úkoly = barva podle priority
      if (todo.priority != null) {
        return _getPriorityColor(todo.priority!, context);
      } else {
        // Bez priority = šedá
        return theme.appColors.base4;
      }
    }
  }

  /// Vytvořit kartu s úkolem
  Widget _buildTodoCard(TodoItem todo) {
    final isExpanded = _expandedTaskId == todo.id;

    return Dismissible(
      key: Key('todo_${todo.id}'),
      // Swipe doprava = toggle hotovo/nehotovo
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: todo.isCompleted ? theme.appColors.yellow : theme.appColors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Icon(
              todo.isCompleted ? Icons.refresh : Icons.check_circle,
              color: theme.appColors.bg,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              todo.isCompleted ? 'VRÁTIT' : 'HOTOVO',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Swipe doleva = smazat
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'SMAZAT',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.delete_forever,
              color: theme.appColors.bg,
              size: 32,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Zavřít klávesnici při jakékoli swipe akci
        FocusScope.of(context).unfocus();

        if (direction == DismissDirection.startToEnd) {
          // Swipe doprava = toggle hotovo/nehotovo
          await _toggleTodoItem(todo);
          return false; // Neodstranit widget
        } else {
          // Swipe doleva = smazat (bez potvrzení)
          return true; // Odstranit widget
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Smazat úkol
          await _removeTodoItem(todo);
        }
      },
      child: InkWell(
        onTap: () {
          // Zavřít klávesnici při expand/collapse
          FocusScope.of(context).unfocus();

          setState(() {
            _expandedTaskId = isExpanded ? null : todo.id;
          });
        },
        onLongPress: () {
          // Zavřít klávesnici při otevření edit dialogu
          FocusScope.of(context).unfocus();
          _editTodoItem(todo);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getTodoBorderColor(todo, context),
              width: 2,
            ),
          ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          color: theme.appColors.base5,
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
                                ? theme.appColors.base5
                                : theme.appColors.fg,
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
                          _getPriorityColor(todo.priority!, context),
                        ),

                      // Datum
                      if (todo.dueDate != null)
                        _buildTag(
                          '📅 ${TagParser.formatDate(todo.dueDate!)}',
                          theme.appColors.blue,
                        ),

                      // Akce
                      if (todo.action != null)
                        _buildTag(
                          '${TagParser.getActionIcon(todo.action)} ${todo.action}',
                          theme.appColors.magenta,
                        ),

                      // Obecné tagy
                      ...todo.tags.map((tag) => _buildTag(
                            tag,
                            theme.appColors.cyan,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            // Tlačítko motivate
            _buildMotivateButton(todo),
          ],
        ),
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
  Color _getPriorityColor(String priority, BuildContext context) {
    final theme = Theme.of(context);
    switch (priority) {
      case 'a':
        return theme.appColors.red;
      case 'b':
        return theme.appColors.yellow;
      case 'c':
        return theme.appColors.green;
      default:
        return theme.appColors.base5;
    }
  }

  /// Vytvořit pulzující růžové tlačítko motivate
  Widget _buildMotivateButton(TodoItem todo) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        // Jemný puls efekt: 0.9 -> 1.0 -> 0.9
        final pulseValue = 0.9 + (0.1 * (0.5 - (value - 0.5).abs()) * 2);

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.appColors.magenta.withOpacity(0.3 * pulseValue),
                blurRadius: 6 * pulseValue,
                spreadRadius: 1 * pulseValue,
              ),
            ],
          ),
          child: IconButton(
            icon: Text(
              'M',
              style: TextStyle(
                color: theme.appColors.magenta,
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
    print('🚀 _motivateTask START pro úkol: ${todo.task}');

    // Zavřít klávesnici (pokud je otevřená)
    FocusScope.of(context).unfocus();

    final soundManager = SoundManager();

    // Spustit typing_long zvuk
    print('🔊 Spouštím typing_long zvuk');
    await soundManager.playTypingLong();

    // Zobrazit loading dialog
    print('⏳ Zobrazuji loading dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: theme.appColors.magenta,
        ),
      ),
    );

    try {
      print('🤖 Volám AIService.getMotivation...');
      // Zavolat AI API
      final motivation = await AIService.getMotivation(
        taskText: todo.task,
        priority: todo.priority,
        tags: todo.tags,
      );
      print('✅ AI odpověď obdržena: ${motivation.substring(0, motivation.length > 50 ? 50 : motivation.length)}...');

      // Přepnout na subtle typing zvuk
      print('🔊 Přepínám na subtle typing zvuk');
      await soundManager.playSubtleTyping();

      // Zavřít loading dialog
      print('❌ Zavírám loading dialog');
      if (mounted) Navigator.of(context).pop();

      // Zobrazit motivaci v dialogu s typewriter efektem
      print('📝 Zobrazuji motivační dialog');
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => _buildMotivationDialog(todo, motivation),
        );

        // Po zavření dialogu zastavit zvuk
        print('⏹️ Zastavuji zvuk po zavření dialogu');
        await soundManager.stop();
      }
      print('✅ _motivateTask KONEC (úspěch)');
    } catch (e, stackTrace) {
      print('❌ EXCEPTION v _motivateTask: $e');
      print('Stack trace: $stackTrace');

      // Zastavit zvuk při chybě
      await soundManager.stop();

      // Zavřít loading dialog
      if (mounted) Navigator.of(context).pop();

      // Zobrazit error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při získávání motivace: $e'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
      print('✅ _motivateTask KONEC (chyba)');
    }
  }

  /// Vytvořit dialog s AI motivací
  Widget _buildMotivationDialog(TodoItem todo, String motivation) {
    final soundManager = SoundManager();
    final scrollController = ScrollController();

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.magenta, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Max 80% výšky obrazovky
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.appColors.magenta, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI MOTIVACE',
                    style: TextStyle(
                      color: theme.appColors.magenta,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.appColors.base5),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(color: theme.appColors.base3, height: 24),

            // Task preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.bgAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.appColors.base3),
              ),
              child: Text(
                '📋 ${todo.task}',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Motivation text s typewriter efektem - Scrollable
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: TypewriterText(
                  text: motivation,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  duration: const Duration(milliseconds: 20),
                  scrollController: scrollController,
                  onComplete: () {
                    // Zastavit zvuk po dokončení typewriter efektu
                    print('🎬 Typewriter dokončen - zastavuji zvuk');
                    soundManager.stop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appColors.magenta,
                  foregroundColor: theme.appColors.bg,
                ),
                child: const Text('Zavřít'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
