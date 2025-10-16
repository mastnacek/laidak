import 'package:flutter_test/flutter_test.dart';
import 'package:todo/features/todo_list/domain/entities/todo.dart';
import 'package:todo/features/todo_list/domain/enums/view_mode.dart';
import 'package:todo/features/todo_list/domain/enums/sort_mode.dart';
import 'package:todo/features/todo_list/domain/extensions/todo_filtering.dart';

void main() {
  group('TodoFiltering Extension Tests', () {
    // Helper pro vytváření testovacích todos
    Todo createTodo({
      required int id,
      required String task,
      bool isCompleted = false,
      String? priority,
      DateTime? dueDate,
      List<String> tags = const [],
      DateTime? createdAt,
    }) {
      return Todo(
        id: id,
        task: task,
        isCompleted: isCompleted,
        createdAt: createdAt ?? DateTime(2025, 1, 1, 10, 0),
        priority: priority,
        dueDate: dueDate,
        tags: tags,
      );
    }

    // ==================== filterBySearch Tests ====================

    group('filterBySearch', () {
      test('prázdný query vrací všechny úkoly', () {
        final todos = [
          createTodo(id: 1, task: 'Nakoupit'),
          createTodo(id: 2, task: 'Zavolat doktorovi'),
        ];

        final result = todos.filterBySearch('');
        expect(result.length, 2);
      });

      test('hledá v task textu (case insensitive)', () {
        final todos = [
          createTodo(id: 1, task: 'Nakoupit mléko'),
          createTodo(id: 2, task: 'Zavolat doktorovi'),
          createTodo(id: 3, task: 'Nakoupit chleba'),
        ];

        final result = todos.filterBySearch('nakoupit');
        expect(result.length, 2);
        expect(result[0].task, 'Nakoupit mléko');
        expect(result[1].task, 'Nakoupit chleba');
      });

      test('hledá v tags', () {
        final todos = [
          createTodo(id: 1, task: 'Úkol 1', tags: ['práce', 'urgent']),
          createTodo(id: 2, task: 'Úkol 2', tags: ['domov', 'rodina']),
          createTodo(id: 3, task: 'Úkol 3', tags: ['práce', 'meeting']),
        ];

        final result = todos.filterBySearch('práce');
        expect(result.length, 2);
      });

      test('hledá v priority', () {
        final todos = [
          createTodo(id: 1, task: 'Úkol 1', priority: 'a'),
          createTodo(id: 2, task: 'Úkol 2', priority: 'b'),
          createTodo(id: 3, task: 'Úkol 3', priority: 'c'),
        ];

        final result = todos.filterBySearch('a');
        expect(result.length, 1);
        expect(result[0].priority, 'a');
      });

      test('vrací prázdný seznam pokud nic nenajde', () {
        final todos = [
          createTodo(id: 1, task: 'Nakoupit'),
        ];

        final result = todos.filterBySearch('neexistující');
        expect(result.length, 0);
      });
    });

    // ==================== filterByViewMode Tests ====================

    group('filterByViewMode', () {
      final now = DateTime(2025, 10, 10, 12, 0);
      final today = DateTime(2025, 10, 10);
      final yesterday = DateTime(2025, 10, 9);
      final tomorrow = DateTime(2025, 10, 11);
      final nextWeek = DateTime(2025, 10, 15);
      final nextMonth = DateTime(2025, 11, 10);

      test('ViewMode.all vrací všechny úkoly', () {
        final todos = [
          createTodo(id: 1, task: 'Úkol 1'),
          createTodo(id: 2, task: 'Úkol 2'),
          createTodo(id: 3, task: 'Úkol 3'),
        ];

        final result = todos.filterByViewMode(ViewMode.all);
        expect(result.length, 3);
      });

      test('ViewMode.today vrací úkoly s deadline dnes', () {
        final todos = [
          createTodo(id: 1, task: 'Dnes 1', dueDate: today),
          createTodo(id: 2, task: 'Zítra', dueDate: tomorrow),
          createTodo(id: 3, task: 'Dnes 2', dueDate: today),
        ];

        final result = todos.filterByViewMode(ViewMode.today);
        expect(result.length, 2);
      });

      test('ViewMode.today vrací overdue úkoly', () {
        final todos = [
          createTodo(id: 1, task: 'Overdue', dueDate: yesterday, isCompleted: false),
          createTodo(id: 2, task: 'Dnes', dueDate: today),
        ];

        final result = todos.filterByViewMode(ViewMode.today);
        expect(result.length, 2);
        expect(result.any((t) => t.task == 'Overdue'), true);
      });

      test('ViewMode.week vrací úkoly v příštích 7 dnech', () {
        final todos = [
          createTodo(id: 1, task: 'Dnes', dueDate: today),
          createTodo(id: 2, task: 'Zítra', dueDate: tomorrow),
          createTodo(id: 3, task: 'Next week', dueDate: nextWeek),
          createTodo(id: 4, task: 'Next month', dueDate: nextMonth),
        ];

        final result = todos.filterByViewMode(ViewMode.week);
        expect(result.length, 3); // Dnes, Zítra, Next week (do 7 dní)
      });

      test('ViewMode.upcoming vrací úkoly v příštích 7 dnech (bez dnes a overdue)', () {
        final todos = [
          createTodo(id: 1, task: 'Overdue', dueDate: yesterday, isCompleted: false),
          createTodo(id: 2, task: 'Dnes', dueDate: today),
          createTodo(id: 3, task: 'Zítra', dueDate: tomorrow),
          createTodo(id: 4, task: 'Next week', dueDate: nextWeek),
        ];

        final result = todos.filterByViewMode(ViewMode.upcoming);
        expect(result.length, 2); // Zítra, Next week (bez overdue a dnes)
      });

      test('ViewMode.overdue vrací pouze overdue úkoly (nedokončené)', () {
        final todos = [
          createTodo(id: 1, task: 'Overdue 1', dueDate: yesterday, isCompleted: false),
          createTodo(id: 2, task: 'Overdue completed', dueDate: yesterday, isCompleted: true),
          createTodo(id: 3, task: 'Dnes', dueDate: today),
        ];

        final result = todos.filterByViewMode(ViewMode.overdue);
        expect(result.length, 1);
        expect(result[0].task, 'Overdue 1');
      });
    });

    // ==================== sortBy Tests ====================

    group('sortBy', () {
      test('SortMode.priority DESC - a > b > c > null', () {
        final todos = [
          createTodo(id: 1, task: 'C task', priority: 'c'),
          createTodo(id: 2, task: 'A task', priority: 'a'),
          createTodo(id: 3, task: 'No priority'),
          createTodo(id: 4, task: 'B task', priority: 'b'),
        ];

        final result = todos.sortBy(SortMode.priority, SortDirection.desc);
        // DESC neguje comparison, takže null > c > b > a
        expect(result[0].priority, null); // Null first v DESC
        expect(result[1].priority, 'c');
        expect(result[2].priority, 'b');
        expect(result[3].priority, 'a');
      });

      test('SortMode.priority ASC - a < b < c < null', () {
        final todos = [
          createTodo(id: 1, task: 'C task', priority: 'c'),
          createTodo(id: 2, task: 'A task', priority: 'a'),
          createTodo(id: 3, task: 'No priority'),
          createTodo(id: 4, task: 'B task', priority: 'b'),
        ];

        final result = todos.sortBy(SortMode.priority, SortDirection.asc);
        // ASC: a < b < c < null (podle priorityOrder)
        expect(result[0].priority, 'a'); // Highest priority first v ASC
        expect(result[1].priority, 'b');
        expect(result[2].priority, 'c');
        expect(result[3].priority, null); // Null last
      });

      test('SortMode.dueDate DESC - nejnovější nahoře', () {
        final todos = [
          createTodo(id: 1, task: '1', dueDate: DateTime(2025, 10, 10)),
          createTodo(id: 2, task: '2', dueDate: DateTime(2025, 10, 15)),
          createTodo(id: 3, task: '3', dueDate: DateTime(2025, 10, 5)),
        ];

        final result = todos.sortBy(SortMode.dueDate, SortDirection.desc);
        // DESC neguje: nejnovější (10/15) první
        expect(result[0].dueDate, DateTime(2025, 10, 15));
        expect(result[1].dueDate, DateTime(2025, 10, 10));
        expect(result[2].dueDate, DateTime(2025, 10, 5));
      });

      test('SortMode.dueDate null hodnoty na začátku v DESC', () {
        final todos = [
          createTodo(id: 1, task: '1', dueDate: DateTime(2025, 10, 10)),
          createTodo(id: 2, task: '2'), // Null dueDate
          createTodo(id: 3, task: '3', dueDate: DateTime(2025, 10, 15)),
        ];

        final result = todos.sortBy(SortMode.dueDate, SortDirection.desc);
        // DESC: null first (return 1 v compare → negováno na -1)
        expect(result[0].dueDate, null);
      });

      test('SortMode.status DESC - completed nahoře', () {
        final todos = [
          createTodo(id: 1, task: '1', isCompleted: false),
          createTodo(id: 2, task: '2', isCompleted: true),
          createTodo(id: 3, task: '3', isCompleted: false),
        ];

        final result = todos.sortBy(SortMode.status, SortDirection.desc);
        // DESC: completed (return 1) → negováno na -1 → completed first
        expect(result[0].isCompleted, true);
        expect(result[2].isCompleted, false);
      });

      test('SortMode.createdAt DESC - nejnovější nahoře', () {
        final todos = [
          createTodo(id: 1, task: '1', createdAt: DateTime(2025, 1, 1)),
          createTodo(id: 2, task: '2', createdAt: DateTime(2025, 1, 3)),
          createTodo(id: 3, task: '3', createdAt: DateTime(2025, 1, 2)),
        ];

        final result = todos.sortBy(SortMode.createdAt, SortDirection.desc);
        // DESC: nejnovější (1/3) first
        expect(result[0].createdAt, DateTime(2025, 1, 3));
        expect(result[1].createdAt, DateTime(2025, 1, 2));
        expect(result[2].createdAt, DateTime(2025, 1, 1));
      });
    });

    // ==================== Integration Test (kombinace filtrů) ====================

    group('Integration - kombinace filtrů', () {
      test('Search + ViewMode + Sort', () {
        final todos = [
          createTodo(
            id: 1,
            task: 'Nakoupit mléko',
            priority: 'a',
            dueDate: DateTime(2025, 10, 10),
            tags: ['domov'],
          ),
          createTodo(
            id: 2,
            task: 'Nakoupit chleba',
            priority: 'b',
            dueDate: DateTime(2025, 10, 11),
            tags: ['domov'],
          ),
          createTodo(
            id: 3,
            task: 'Zavolat doktorovi',
            priority: 'a',
            dueDate: DateTime(2025, 10, 12),
            tags: ['práce'],
          ),
        ];

        // Pipeline: Search "nakoupit" → ViewMode.week → Sort by priority ASC
        var result = todos.filterBySearch('nakoupit');
        result = result.filterByViewMode(ViewMode.week);
        result = result.sortBy(SortMode.priority, SortDirection.asc);

        expect(result.length, 2); // Oba "nakoupit" úkoly
        expect(result[0].priority, 'a'); // ASC: a < b (vyšší priorita první)
        expect(result[1].priority, 'b');
      });
    });
  });
}
