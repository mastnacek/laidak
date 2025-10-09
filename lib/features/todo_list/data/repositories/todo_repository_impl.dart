import '../../../../core/services/database_helper.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../../../models/todo_item.dart';

/// Implementace TodoRepository
///
/// Používá DatabaseHelper pro SQLite operace.
/// Konvertuje mezi domain entities (Todo) a DTOs (TodoModel).
class TodoRepositoryImpl implements TodoRepository {
  final DatabaseHelper _db;

  TodoRepositoryImpl(this._db);

  @override
  Future<List<Todo>> getAllTodos() async {
    // DatabaseHelper vrací List<TodoItem> (starý model)
    final todoItems = await _db.getAllTodos();

    // Převést TodoItem → Todo entity
    return todoItems.map((item) => _todoItemToEntity(item)).toList();
  }

  @override
  Future<void> insertTodo(Todo todo) async {
    // Převést Todo entity → TodoItem
    final todoItem = _entityToTodoItem(todo);

    // Uložit do databáze
    await _db.insertTodo(todoItem);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    // ✅ Fail Fast: validace před zpracováním
    if (todo.id == null) {
      throw ArgumentError('Cannot update todo without ID');
    }

    // Převést Todo entity → TodoItem
    final todoItem = _entityToTodoItem(todo);

    // Aktualizovat v databázi
    await _db.updateTodo(todoItem);
  }

  @override
  Future<void> deleteTodo(int id) async {
    // ✅ Fail Fast: validace před zpracováním
    if (id <= 0) {
      throw ArgumentError('Invalid todo ID: $id');
    }

    await _db.deleteTodo(id);
  }

  @override
  Future<void> toggleTodoStatus(int id, bool isCompleted) async {
    // ✅ Fail Fast: validace před zpracováním
    if (id <= 0) {
      throw ArgumentError('Invalid todo ID: $id');
    }

    await _db.toggleTodoStatus(id, isCompleted);
  }

  /// Helper: Převést TodoItem (starý model) → Todo entity
  Todo _todoItemToEntity(TodoItem item) {
    return Todo(
      id: item.id,
      task: item.task,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
      priority: item.priority,
      dueDate: item.dueDate,
      action: item.action,
      tags: item.tags,
    );
  }

  /// Helper: Převést Todo entity → TodoItem (starý model)
  TodoItem _entityToTodoItem(Todo todo) {
    return TodoItem(
      id: todo.id,
      task: todo.task,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      priority: todo.priority,
      dueDate: todo.dueDate,
      action: todo.action,
      tags: todo.tags,
    );
  }
}
