import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Aplikace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
  final List<TodoItem> _todoItems = [];
  final TextEditingController _textController = TextEditingController();

  void _addTodoItem(String task) {
    if (task.isNotEmpty) {
      setState(() {
        _todoItems.add(TodoItem(task: task));
      });
      _textController.clear();
    }
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoItems[index].isCompleted = !_todoItems[index].isCompleted;
    });
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Moje TODO seznam'),
      ),
      body: Column(
        children: [
          // Formulář pro přidání nového úkolu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Přidat nový úkol...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTodoItem,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTodoItem(_textController.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const Divider(),
          // Seznam úkolů
          Expanded(
            child: _todoItems.isEmpty
                ? const Center(
                    child: Text(
                      'Zatím žádné úkoly.\nPřidej první úkol!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _todoItems.length,
                    itemBuilder: (context, index) {
                      final todo = _todoItems[index];
                      return ListTile(
                        leading: Checkbox(
                          value: todo.isCompleted,
                          onChanged: (_) => _toggleTodoItem(index),
                        ),
                        title: Text(
                          todo.task,
                          style: TextStyle(
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeTodoItem(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Model pro TODO položku
class TodoItem {
  String task;
  bool isCompleted;

  TodoItem({
    required this.task,
    this.isCompleted = false,
  });
}
