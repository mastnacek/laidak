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
}
