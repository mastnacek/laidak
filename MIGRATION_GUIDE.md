# 🚀 Průvodce migrací BLoC → Riverpod

Tento průvodce ti pomůže dokončit převod projektu **lAidak** z BLoC/Cubit na Riverpod.

## ✅ Co už je hotové (Phase 1 + Phase 2)

### 1. Dependencies
- ✅ Přidány `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`
- ✅ `build_runner` připraven pro code generation
- ✅ `analysis_options.yaml` nakonfigurován pro Riverpod

### 2. Core Providers
- ✅ `lib/core/providers/core_providers.dart` - DatabaseHelper, HTTP client, TagService
- ✅ `lib/core/providers/repository_providers.dart` - Všechny repository providers

### 3. Kompletní konverze (Phase 1 + Phase 2)

#### Settings & Connectivity
- ✅ **SettingsCubit** → `lib/features/settings/presentation/providers/settings_provider.dart`
  - Používá `@riverpod` + AsyncNotifier
  - Ukázka async state managementu

- ✅ **ConnectivityCubit** → `lib/core/connectivity/providers/connectivity_provider.dart`
  - Používá StreamNotifier
  - Ukázka real-time stream monitoring

#### Core Features
- ✅ **TodoListBloc** → `lib/features/todo_list/presentation/providers/todo_provider.dart`
  - Kompletní převod včetně search, filter, sort, AI Brief
  - Helper providers: displayedTodos, expandedTodoId, currentViewMode

#### AI Features
- ✅ **MotivationCubit** → `lib/features/ai_motivation/presentation/providers/motivation_provider.dart`
  - Jednoduchý Notifier pro motivační zprávy

- ✅ **AiSplitCubit** → `lib/features/ai_split/presentation/providers/ai_split_provider.dart`
  - Rozdělování úkolů pomocí AI

- ✅ **PrankCubit** → `lib/features/ai_prank/presentation/providers/prank_provider.dart`
  - Pranky + good deeds po dokončení úkolu

### 4. Main entry point
- ✅ `lib/main_riverpod.dart` - Nový main.dart s ProviderScope
  - Nahrazuje MultiBlocProvider
  - Používá `ref.watch()` místo `BlocBuilder`
  - Importuje všechny nové providers

---

## 📋 Co zbývá udělat

### Krok 1: Spustit build_runner

Nejprve vygeneruj `.g.dart` soubory pro riverpod_annotation:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

To vytvoří `.g.dart` soubory pro všechny providery:
- `lib/features/settings/presentation/providers/settings_provider.g.dart`
- `lib/core/connectivity/providers/connectivity_provider.g.dart`
- `lib/features/todo_list/presentation/providers/todo_provider.g.dart`
- `lib/features/ai_motivation/presentation/providers/motivation_provider.g.dart`
- `lib/features/ai_split/presentation/providers/ai_split_provider.g.dart`
- `lib/features/ai_prank/presentation/providers/prank_provider.g.dart`

### Krok 2: Převést zbylé BLoC/Cubit (volitelné)

**Hlavní features jsou hotové!** Zbývající blocy jsou méně kritické:

#### 🟢 Priority 3 (ostatní - lze převést postupně)

**NotesBloc** → `lib/features/notes/presentation/providers/notes_provider.dart`
**ProfileBloc** → `lib/features/profile/presentation/providers/profile_provider.dart`
**PomodoroBloc** → `lib/features/pomodoro/presentation/providers/pomodoro_provider.dart`
**TagManagementCubit** → `lib/features/tag_management/presentation/providers/tag_management_provider.dart`
**AiChatBloc** → `lib/features/ai_chat/presentation/providers/ai_chat_provider.dart`

Použij stejný pattern jako u TodoList provideru.

---

## 🔄 Pattern pro převod

### BLoC → AsyncNotifier (async operations)

**Před (BLoC):**
```dart
class TodoListBloc extends Bloc<TodoEvent, TodoState> {
  TodoListBloc(this._repository) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter emit) async {
    emit(TodoLoading());
    try {
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
}
```

**Po (Riverpod):**
```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  Future<TodoState> build() async {
    final todos = await ref.read(todoRepositoryProvider).getTodos();
    return TodoLoaded(todos);
  }

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final todos = await ref.read(todoRepositoryProvider).getTodos();
      return TodoLoaded(todos);
    });
  }

  Future<void> addTodo(Todo todo) async {
    await ref.read(todoRepositoryProvider).addTodo(todo);
    ref.invalidateSelf(); // Re-run build()
  }
}
```

### Cubit → Notifier (synchronní state)

**Před (Cubit):**
```dart
class MotivationCubit extends Cubit<MotivationState> {
  MotivationCubit(this._repository) : super(MotivationInitial());

  Future<void> generateMotivation() async {
    emit(MotivationLoading());
    try {
      final text = await _repository.generateMotivation();
      emit(MotivationLoaded(text));
    } catch (e) {
      emit(MotivationError(e.toString()));
    }
  }
}
```

**Po (Riverpod):**
```dart
@riverpod
class Motivation extends _$Motivation {
  @override
  MotivationState build() {
    return const MotivationInitial();
  }

  Future<void> generateMotivation() async {
    state = const MotivationLoading();
    try {
      final text = await ref.read(motivationRepositoryProvider).generateMotivation();
      state = MotivationLoaded(text);
    } catch (e) {
      state = MotivationError(e.toString());
    }
  }
}
```

---

## 🎨 Aktualizace UI widgetů

### BlocBuilder → Consumer/ref.watch

**Před:**
```dart
BlocBuilder<TodoListBloc, TodoState>(
  builder: (context, state) {
    if (state is TodoLoading) {
      return CircularProgressIndicator();
    } else if (state is TodoLoaded) {
      return ListView.builder(...);
    }
    return SizedBox.shrink();
  },
)
```

**Po (Option 1 - Consumer):**
```dart
Consumer(
  builder: (context, ref, child) {
    final todoAsync = ref.watch(todoListProvider);

    return todoAsync.when(
      data: (todoState) {
        if (todoState is TodoLoaded) {
          return ListView.builder(...);
        }
        return SizedBox.shrink();
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  },
)
```

**Po (Option 2 - ConsumerWidget):**
```dart
class TodoListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoAsync = ref.watch(todoListProvider);

    return todoAsync.when(
      data: (todoState) {
        if (todoState is TodoLoaded) {
          return ListView.builder(...);
        }
        return SizedBox.shrink();
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### BlocConsumer → ref.listen + ref.watch

**Před:**
```dart
BlocConsumer<TodoListBloc, TodoState>(
  listener: (context, state) {
    if (state is TodoError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // ...
  },
)
```

**Po:**
```dart
class TodoListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for errors
    ref.listen<AsyncValue<TodoState>>(todoListProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    // Watch for state changes
    final todoAsync = ref.watch(todoListProvider);

    return todoAsync.when(
      // ...
    );
  }
}
```

### context.read → ref.read

**Před:**
```dart
context.read<TodoListBloc>().add(AddTodoEvent(todo));
```

**Po:**
```dart
ref.read(todoListProvider.notifier).addTodo(todo);
```

---

## 🛠️ Testování migrace

### 1. Postupná migrace

Můžeš mít BLoC i Riverpod současně! Přepiš nejdřív jedno feature a otestuj:

```dart
runApp(
  ProviderScope(
    child: MultiBlocProvider(
      providers: [
        // Stará BLoC features (co ještě nejsou převedené)
        BlocProvider(create: (_) => TodoListBloc(...)),

        // Nové Riverpod providers jsou dostupné přes ProviderScope
      ],
      child: TodoApp(),
    ),
  ),
);
```

### 2. Přepnutí na main_riverpod.dart

Když máš převedené klíčové features:

```bash
# Záloha starého main.dart
mv lib/main.dart lib/main_bloc.dart

# Aktivuj Riverpod verzi
mv lib/main_riverpod.dart lib/main.dart
```

### 3. Spuštění

```bash
flutter pub run build_runner watch  # Auto-regenerate při změnách
flutter run
```

---

## 🎯 Doporučený postup

1. **✅ Fáze 1 HOTOVÁ**: Settings + Connectivity
2. **✅ Fáze 2 HOTOVÁ**: TodoList + AI features (Motivation, Split, Prank)
3. **Fáze 3**: Převeď zbylé (Notes, Profile, Pomodoro, TagManagement, AiChat) - volitelné
4. **Fáze 4**: Spusť build_runner a otestuj aplikaci
5. **Fáze 5**: Aktualizuj UI widgety postupně (můžeš začít jednou feature)
6. **Fáze 6**: Odstranění BLoC dependencies (až bude vše převedené)

---

## 📚 Užitečné zdroje

- [Riverpod Documentation](https://riverpod.dev/)
- [Migrace z BLoC](https://riverpod.dev/docs/from_provider/motivation)
- [Code Generation](https://riverpod.dev/docs/concepts/about_code_generation)
- [AsyncNotifier](https://riverpod.dev/docs/providers/notifier_provider)
- [StreamNotifier](https://riverpod.dev/docs/providers/stream_provider)

---

## ⚠️ Časté problémy

### Problem: "part 'xxx.g.dart' doesn't exist"
**Řešení:** Spusť `flutter pub run build_runner build`

### Problem: Provider ne found
**Řešení:** Zkontroluj že máš `ProviderScope` v `main.dart`

### Problem: Circular dependency
**Řešení:** Použij `ref.read()` pro jednorázové čtení, `ref.watch()` pro reaktivní observování

---

## 🎉 Výhody Riverpod oproti BLoC

- ✅ **Compile-time safety** - chyby při kompilaci místo runtime
- ✅ **Méně boilerplate** - žádné Events, méně souborů
- ✅ **Lepší testování** - snazší mockování providers
- ✅ **Auto-disposal** - automatické čištění resources
- ✅ **DevTools** - lepší debugging s Riverpod DevTools
- ✅ **Scoped providers** - per-route nebo per-widget state
- ✅ **Familie providers** - parametrizované providers

Hodně štěstí s migrací! 🚀
