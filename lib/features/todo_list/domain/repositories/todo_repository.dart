import '../entities/todo.dart';

/// Repository interface pro Todo operace
///
/// Definuje kontrakt pro data layer (dependency inversion principle).
/// Implementace bude v data/repositories/todo_repository_impl.dart
abstract class TodoRepository {
  /// Načíst všechny todos z databáze
  Future<List<Todo>> getAllTodos();

  /// Přidat nový todo
  Future<void> insertTodo(Todo todo);

  /// Aktualizovat existující todo
  Future<void> updateTodo(Todo todo);

  /// Smazat todo podle ID
  Future<void> deleteTodo(int id);

  /// Přepnout stav todo (hotovo/nehotovo)
  Future<void> toggleTodoStatus(int id, bool isCompleted);

  /// FTS5 Full-Text Search v todos
  ///
  /// Query syntax:
  /// - "prezentaci" → simple keyword
  /// - "dokončit prezentaci" → phrase search
  /// - "dokončit OR připravit" → boolean OR
  /// - "prog*" → prefix search
  ///
  /// Vrací: List<Todo> seřazené podle relevance (BM25 rank)
  Future<List<Todo>> fullTextSearchTodos(String query);

  // ==================== RECURRENCE METHODS (TODOIST MODEL) ====================

  /// Posunout due_date u recurring TODO na další termín
  Future<void> updateTodoDueDate(int todoId, DateTime newDueDate);

  /// Ukončit opakování (smazat RecurrenceRule)
  Future<void> deleteRecurrenceRule(int todoId);
}
