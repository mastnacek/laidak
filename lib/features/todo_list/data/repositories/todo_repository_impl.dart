import '../../../../core/services/database_helper.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../../../models/todo_item.dart';
import '../../../ai_split/data/models/subtask_model.dart';
import '../../domain/services/recurrence_tag_parser.dart';

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

    // Převést TodoItem → Todo entity s načtenými subtasks, tags a recurrence_rules
    final todos = <Todo>[];
    for (final item in todoItems) {
      // Načíst subtasks (stávající kód)
      final subtasksMaps = await _db.getSubtasksByTodoId(item.id!);
      final subtasks = subtasksMaps.map((map) => SubtaskModel.fromMap(map)).toList();

      // ✅ NOVÉ: Načíst tagy z normalizované tabulky
      final tags = await _db.getTagsForTodo(item.id!);

      // ✅ NOVÉ: Načíst recurrence_rule s occurrences (pokud existuje)
      final recurrenceRule = await _loadRecurrenceRuleForTodo(item.id!);

      todos.add(_todoItemToEntity(item, subtasks, tags, recurrenceRule));
    }

    return todos;
  }

  @override
  Future<void> insertTodo(Todo todo) async {
    // Převést Todo entity → TodoItem
    final todoItem = _entityToTodoItem(todo);

    // Uložit do databáze
    final insertedItem = await _db.insertTodo(todoItem);
    final todoId = insertedItem.id!;

    // ✅ NOVÉ: Přidat tagy do todo_tags tabulky
    if (todo.tags.isNotEmpty) {
      await _db.addTagsToTodo(todoId, todo.tags);
    }

    // ✅ RECURRENCE: Zkontrolovat tagy zda obsahují recurrence syntaxi
    await _processRecurrenceTags(todoId, todo.tags);
  }

  /// Zpracovat recurrence tagy a vytvořit pravidlo (Todoist model)
  ///
  /// Parsuje task text a hledá recurrence syntaxi (suffix d/t/m/r)
  /// Pokud najde, vytvoří RecurrenceRule (bez occurrences)
  Future<void> _processRecurrenceTags(int todoId, List<String> tags) async {
    // Načíst user tag delimiters z DB
    final settings = await _db.getSettings();
    final delimiterStart = settings['tag_delimiter_start'] as String? ?? '*';
    final delimiterEnd = settings['tag_delimiter_end'] as String? ?? '*';

    // Rekonstruovat task text s tagy (parser potřebuje celý text s delimitery)
    final taskTextWithTags = tags.map((tag) => '$delimiterStart$tag$delimiterEnd').join(' ');

    // Parse pomocí RecurrenceTagParser (static metoda)
    final recurrenceInfo = RecurrenceTagParser.parse(
      taskTextWithTags,
      tagDelimiterStart: delimiterStart,
      tagDelimiterEnd: delimiterEnd,
    );

    // Pokud nenašel recurrence tag → return
    if (recurrenceInfo == null) return;

    // 1. Vytvořit RecurrenceRule entity pomocí toRecurrenceRule()
    final rule = recurrenceInfo.toRecurrenceRule(todoId);

    // 2. Uložit rule do DB (bez occurrences)
    final ruleMap = rule.toMap();
    await _db.insertRecurrenceRule(ruleMap);
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

  @override
  Future<List<Todo>> fullTextSearchTodos(String query) async {
    // ✅ Fail Fast: validace query
    if (query.trim().isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    // FTS5 Full-Text Search (DatabaseHelper)
    final todoItems = await _db.fullTextSearchTodos(query);

    // Převést TodoItem → Todo entity (včetně subtasks, tags a recurrence)
    final todos = <Todo>[];
    for (final item in todoItems) {
      // Načíst subtasks
      final subtasksMaps = await _db.getSubtasksByTodoId(item.id!);
      final subtasks = subtasksMaps.map((map) => SubtaskModel.fromMap(map)).toList();

      // Načíst tagy z normalizované tabulky
      final tags = await _db.getTagsForTodo(item.id!);

      // ✅ NOVÉ: Načíst recurrence_rule s occurrences
      final recurrenceRule = await _loadRecurrenceRuleForTodo(item.id!);

      todos.add(_todoItemToEntity(item, subtasks, tags, recurrenceRule));
    }

    return todos;
  }

  /// Helper: Převést TodoItem (starý model) → Todo entity
  Todo _todoItemToEntity(
    TodoItem item,
    List<SubtaskModel> subtasks,
    List<String> tags,  // ✅ NOVÉ: tags z normalizované tabulky
    RecurrenceRule? recurrenceRule,  // ✅ NOVÉ: recurrence_rule s occurrences
  ) {
    return Todo(
      id: item.id,
      task: item.task,
      isCompleted: item.isCompleted,
      createdAt: item.createdAt,
      completedAt: item.completedAt,
      priority: item.priority,
      dueDate: item.dueDate,
      tags: tags,  // ✅ NOVÉ: použij normalizované tagy
      subtasks: subtasks,
      aiRecommendations: item.aiRecommendations,
      aiDeadlineAnalysis: item.aiDeadlineAnalysis,
      aiMotivation: item.aiMotivation, // ✅ AI Motivation cache
      aiMotivationGeneratedAt: item.aiMotivationGeneratedAt, // ✅ Unix timestamp
      recurrenceRule: recurrenceRule,  // ✅ NOVÉ: přidat recurrence rule
    );
  }

  /// Helper: Převést Todo entity → TodoItem (starý model)
  TodoItem _entityToTodoItem(Todo todo) {
    return TodoItem(
      id: todo.id,
      task: todo.task,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
      priority: todo.priority,
      dueDate: todo.dueDate,
      tags: [],  // ❌ DEPRECATED: CSV sloupec už nepoužíváme
      aiRecommendations: todo.aiRecommendations,
      aiDeadlineAnalysis: todo.aiDeadlineAnalysis,
      aiMotivation: todo.aiMotivation, // ✅ AI Motivation cache
      aiMotivationGeneratedAt: todo.aiMotivationGeneratedAt, // ✅ Unix timestamp
    );
  }

  // ==================== RECURRENCE METHODS (TODOIST MODEL) ====================

  @override
  Future<void> updateTodoDueDate(int todoId, DateTime newDueDate) async {
    // ✅ Fail Fast: validace před zpracováním
    if (todoId <= 0) {
      throw ArgumentError('Invalid todo ID: $todoId');
    }

    // Delegovat na DatabaseHelper
    await _db.updateTodoDueDate(todoId, newDueDate);
  }

  @override
  Future<void> deleteRecurrenceRule(int todoId) async {
    // ✅ Fail Fast: validace před zpracováním
    if (todoId <= 0) {
      throw ArgumentError('Invalid todo ID: $todoId');
    }

    // Načíst rule by todoId
    final ruleMap = await _db.getRecurrenceRuleByTodoId(todoId);
    if (ruleMap == null) return; // Není recurrence rule

    final ruleId = ruleMap['id'] as int;
    await _db.deleteRecurrenceRule(ruleId);
  }

  // ==================== PRIVATE HELPERS ====================

  /// Načíst RecurrenceRule pro dané TODO (pokud existuje)
  Future<RecurrenceRule?> _loadRecurrenceRuleForTodo(int todoId) async {
    // 1. Načíst recurrence_rule z DB
    final ruleMap = await _db.getRecurrenceRuleByTodoId(todoId);
    if (ruleMap == null) {
      return null; // TODO nemá recurrence
    }

    // 2. Převést Map → RecurrenceRule entity
    return RecurrenceRule.fromMap(ruleMap);
  }
}
