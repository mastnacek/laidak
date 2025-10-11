import '../../../../core/services/database_helper.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../../../models/todo_item.dart';
import '../../../ai_split/data/models/subtask_model.dart';

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

    // Převést TodoItem → Todo entity s načtenými subtasks a tags
    final todos = <Todo>[];
    for (final item in todoItems) {
      // Načíst subtasks (stávající kód)
      final subtasksMaps = await _db.getSubtasksByTodoId(item.id!);
      final subtasks = subtasksMaps.map((map) => SubtaskModel.fromMap(map)).toList();

      // ✅ NOVÉ: Načíst tagy z normalizované tabulky
      final tags = await _db.getTagsForTodo(item.id!);

      todos.add(_todoItemToEntity(item, subtasks, tags));
    }

    return todos;
  }

  @override
  Future<void> insertTodo(Todo todo) async {
    // Převést Todo entity → TodoItem
    final todoItem = _entityToTodoItem(todo);

    // Uložit do databáze
    final insertedItem = await _db.insertTodo(todoItem);

    // ✅ NOVÉ: Přidat tagy do todo_tags tabulky
    if (todo.tags.isNotEmpty) {
      await _db.addTagsToTodo(insertedItem.id!, todo.tags);
    }
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

    // ✅ NOVÉ: Update tagy (remove all + add new)
    await _db.removeAllTagsFromTodo(todo.id!);
    if (todo.tags.isNotEmpty) {
      await _db.addTagsToTodo(todo.id!, todo.tags);
    }
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
  Todo _todoItemToEntity(
    TodoItem item,
    List<SubtaskModel> subtasks,
    List<String> tags,  // ✅ NOVÉ: tags z normalizované tabulky
  ) {
    return Todo(
      id: item.id,
      task: item.task,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
      priority: item.priority,
      dueDate: item.dueDate,
      tags: tags,  // ✅ NOVÉ: použij normalizované tagy
      subtasks: subtasks,
      aiRecommendations: item.aiRecommendations,
      aiDeadlineAnalysis: item.aiDeadlineAnalysis,
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
      tags: [],  // ❌ DEPRECATED: CSV sloupec už nepoužíváme
      aiRecommendations: todo.aiRecommendations,
      aiDeadlineAnalysis: todo.aiDeadlineAnalysis,
    );
  }
}
