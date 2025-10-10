import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:todo/features/todo_list/domain/entities/todo.dart';
import 'package:todo/features/todo_list/domain/repositories/todo_repository.dart';
import 'package:todo/features/todo_list/domain/enums/view_mode.dart';
import 'package:todo/features/todo_list/domain/enums/sort_mode.dart';
import 'package:todo/features/todo_list/presentation/bloc/todo_list_bloc.dart';
import 'package:todo/features/todo_list/presentation/bloc/todo_list_event.dart';
import 'package:todo/features/todo_list/presentation/bloc/todo_list_state.dart';

import 'todo_list_bloc_test.mocks.dart';

/// Unit testy pro TodoListBloc
///
/// Testuje všechny event handlery a edge cases.
/// Používá bloc_test package a mockito pro repository mocking.
@GenerateMocks([TodoRepository])
void main() {
  group('TodoListBloc', () {
    late MockTodoRepository mockRepository;

    // Test data
    final testTodo1 = Todo(
      id: 1,
      task: 'Test úkol 1',
      createdAt: DateTime(2025, 1, 10, 10, 0),
      isCompleted: false,
      priority: 'a',
      dueDate: DateTime(2025, 1, 15),
      tags: ['work', 'urgent'],
    );

    final testTodo2 = Todo(
      id: 2,
      task: 'Test úkol 2',
      createdAt: DateTime(2025, 1, 10, 11, 0),
      isCompleted: true,
      priority: 'b',
      tags: ['personal'],
    );

    final testTodo3 = Todo(
      id: 3,
      task: 'Test úkol 3',
      createdAt: DateTime(2025, 1, 10, 12, 0),
      isCompleted: false,
      priority: 'c',
      dueDate: DateTime(2025, 1, 20),
      tags: ['shopping'],
    );

    final testTodos = [testTodo1, testTodo2, testTodo3];

    setUp(() {
      mockRepository = MockTodoRepository();
      // Default stub pro getAllTodos (aby BLoC mohl reloadovat data kdykoliv)
      when(mockRepository.getAllTodos()).thenAnswer((_) async => testTodos);
    });

    // ==================== INITIAL STATE ====================

    test('initial state je TodoListInitial', () {
      final bloc = TodoListBloc(mockRepository);
      expect(bloc.state, equals(const TodoListInitial()));
      bloc.close();
    });

    // ==================== LOAD TODOS ====================

    group('LoadTodosEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'emituje [Loading, Loaded] když načtení todos uspěje',
        build: () {
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const LoadTodosEvent()),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(allTodos: testTodos),
        ],
        verify: (_) {
          verify(mockRepository.getAllTodos()).called(1);
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'emituje [Loading, Error] když načtení todos selže',
        build: () {
          when(mockRepository.getAllTodos())
              .thenThrow(Exception('Database error'));
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const LoadTodosEvent()),
        expect: () => [
          const TodoListLoading(),
          isA<TodoListError>()
              .having((s) => s.message, 'message', contains('Database error')),
        ],
        verify: (_) {
          verify(mockRepository.getAllTodos()).called(1);
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'zachová expandedTodoId při reload',
        build: () {
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          expandedTodoId: 1,
        ),
        act: (bloc) => bloc.add(const LoadTodosEvent()),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(
            allTodos: testTodos,
            expandedTodoId: 1, // Zachováno!
          ),
        ],
      );
    });

    // ==================== ADD TODO ====================

    group('AddTodoEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když taskText je prázdný',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(const AddTodoEvent(taskText: '')),
        expect: () => [
          const TodoListError('Text úkolu nesmí být prázdný'),
        ],
        verify: (_) {
          verifyNever(mockRepository.insertTodo(any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když taskText obsahuje pouze whitespace',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(const AddTodoEvent(taskText: '   ')),
        expect: () => [
          const TodoListError('Text úkolu nesmí být prázdný'),
        ],
        verify: (_) {
          verifyNever(mockRepository.insertTodo(any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'zavolá insertTodo a reload když taskText je validní',
        build: () {
          when(mockRepository.insertTodo(any)).thenAnswer((_) async => {});
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const AddTodoEvent(
          taskText: 'Nový úkol',
          priority: 'a',
          tags: ['test'],
        )),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(allTodos: testTodos),
        ],
        verify: (_) {
          verify(mockRepository.insertTodo(any)).called(1);
          verify(mockRepository.getAllTodos()).called(1);
        },
      );
    });

    // ==================== UPDATE TODO ====================

    group('UpdateTodoEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když todo nemá ID',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(UpdateTodoEvent(
          testTodo1.copyWith(id: null),
        )),
        expect: () => [
          const TodoListError('Nelze aktualizovat úkol bez ID'),
        ],
        verify: (_) {
          verifyNever(mockRepository.updateTodo(any));
        },
        // Skip states before our event (kvůli async events z předchozích testů)
        skip: 0,
      );

      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když task je prázdný',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(UpdateTodoEvent(
          testTodo1.copyWith(task: ''),
        )),
        expect: () => [
          const TodoListError('Text úkolu nesmí být prázdný'),
        ],
        verify: (_) {
          verifyNever(mockRepository.updateTodo(any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'zavolá updateTodo a reload když todo je validní',
        build: () {
          when(mockRepository.updateTodo(any)).thenAnswer((_) async => {});
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(UpdateTodoEvent(
          testTodo1.copyWith(task: 'Upravený úkol'),
        )),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(allTodos: testTodos),
        ],
        verify: (_) {
          verify(mockRepository.updateTodo(any)).called(1);
          verify(mockRepository.getAllTodos()).called(1);
        },
      );
    });

    // ==================== DELETE TODO ====================

    group('DeleteTodoEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když ID je neplatné (0)',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(const DeleteTodoEvent(0)),
        expect: () => [
          isA<TodoListError>()
              .having((s) => s.message, 'message', contains('Neplatné ID')),
        ],
        verify: (_) {
          verifyNever(mockRepository.deleteTodo(any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když ID je negativní',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(const DeleteTodoEvent(-1)),
        expect: () => [
          isA<TodoListError>()
              .having((s) => s.message, 'message', contains('Neplatné ID')),
        ],
        verify: (_) {
          verifyNever(mockRepository.deleteTodo(any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'zavolá deleteTodo a reload když ID je validní',
        build: () {
          when(mockRepository.deleteTodo(1)).thenAnswer((_) async => {});
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const DeleteTodoEvent(1)),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(allTodos: testTodos),
        ],
        verify: (_) {
          verify(mockRepository.deleteTodo(1)).called(1);
          verify(mockRepository.getAllTodos()).called(1);
        },
      );
    });

    // ==================== TOGGLE TODO ====================

    group('ToggleTodoEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'emituje Error když ID je neplatné',
        build: () => TodoListBloc(mockRepository),
        act: (bloc) => bloc.add(const ToggleTodoEvent(id: 0, isCompleted: true)),
        expect: () => [
          isA<TodoListError>()
              .having((s) => s.message, 'message', contains('Neplatné ID')),
        ],
        verify: (_) {
          verifyNever(mockRepository.toggleTodoStatus(any, any));
        },
      );

      blocTest<TodoListBloc, TodoListState>(
        'zavolá toggleTodoStatus a reload',
        build: () {
          when(mockRepository.toggleTodoStatus(1, true))
              .thenAnswer((_) async => {});
          when(mockRepository.getAllTodos())
              .thenAnswer((_) async => testTodos);
          return TodoListBloc(mockRepository);
        },
        act: (bloc) => bloc.add(const ToggleTodoEvent(id: 1, isCompleted: true)),
        expect: () => [
          const TodoListLoading(),
          TodoListLoaded(allTodos: testTodos),
        ],
        verify: (_) {
          verify(mockRepository.toggleTodoStatus(1, true)).called(1);
          verify(mockRepository.getAllTodos()).called(1);
        },
      );
    });

    // ==================== TOGGLE SHOW COMPLETED ====================

    group('ToggleShowCompletedEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'toggle showCompleted z false na true',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          showCompleted: false,
        ),
        act: (bloc) => bloc.add(const ToggleShowCompletedEvent()),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            showCompleted: true,
          ),
        ],
      );

      blocTest<TodoListBloc, TodoListState>(
        'toggle showCompleted z true na false',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          showCompleted: true,
        ),
        act: (bloc) => bloc.add(const ToggleShowCompletedEvent()),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            showCompleted: false,
          ),
        ],
      );

      blocTest<TodoListBloc, TodoListState>(
        'nedělá nic když state není TodoListLoaded',
        build: () => TodoListBloc(mockRepository),
        seed: () => const TodoListLoading(),
        act: (bloc) => bloc.add(const ToggleShowCompletedEvent()),
        expect: () => [],
      );
    });

    // ==================== TOGGLE EXPAND TODO ====================

    group('ToggleExpandTodoEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'expanduje todo když žádné není expandováno',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          expandedTodoId: null,
        ),
        act: (bloc) => bloc.add(const ToggleExpandTodoEvent(1)),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            expandedTodoId: 1,
          ),
        ],
      );

      blocTest<TodoListBloc, TodoListState>(
        'kolapsuje todo když klikneš na stejné ID',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          expandedTodoId: 1,
        ),
        act: (bloc) => bloc.add(const ToggleExpandTodoEvent(1)),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            expandedTodoId: null,
          ),
        ],
      );

      blocTest<TodoListBloc, TodoListState>(
        'přepne na nové todo když klikneš na jiné ID',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          expandedTodoId: 1,
        ),
        act: (bloc) => bloc.add(const ToggleExpandTodoEvent(2)),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            expandedTodoId: 2,
          ),
        ],
      );
    });

    // ==================== SEARCH ====================

    group('SearchTodosEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'nastaví search query',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          searchQuery: '',
        ),
        act: (bloc) => bloc.add(const SearchTodosEvent('test')),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            searchQuery: 'test',
          ),
        ],
      );

      blocTest<TodoListBloc, TodoListState>(
        'nedělá nic když state není TodoListLoaded',
        build: () => TodoListBloc(mockRepository),
        seed: () => const TodoListLoading(),
        act: (bloc) => bloc.add(const SearchTodosEvent('test')),
        expect: () => [],
      );
    });

    group('ClearSearchEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'vymaže search query',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          searchQuery: 'test',
        ),
        act: (bloc) => bloc.add(const ClearSearchEvent()),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            searchQuery: '',
          ),
        ],
      );
    });

    // ==================== VIEW MODE ====================

    group('ChangeViewModeEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'změní view mode',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          viewMode: ViewMode.all,
        ),
        act: (bloc) => bloc.add(const ChangeViewModeEvent(ViewMode.today)),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            viewMode: ViewMode.today,
          ),
        ],
      );
    });

    // ==================== SORT ====================

    group('SortTodosEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'nastaví sort mode a direction',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          sortMode: null,
          sortDirection: SortDirection.desc,
        ),
        act: (bloc) => bloc.add(const SortTodosEvent(
          SortMode.priority,
          SortDirection.asc,
        )),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            sortMode: SortMode.priority,
            sortDirection: SortDirection.asc,
          ),
        ],
      );
    });

    group('ClearSortEvent', () {
      blocTest<TodoListBloc, TodoListState>(
        'vymaže sort mode (vrátí na default)',
        build: () => TodoListBloc(mockRepository),
        seed: () => TodoListLoaded(
          allTodos: testTodos,
          sortMode: SortMode.priority,
          sortDirection: SortDirection.asc,
        ),
        act: (bloc) => bloc.add(const ClearSortEvent()),
        expect: () => [
          TodoListLoaded(
            allTodos: testTodos,
            sortMode: null,
            sortDirection: SortDirection.asc,
          ),
        ],
      );
    });
  });
}
