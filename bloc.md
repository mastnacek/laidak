# 📘 BLOC PATTERN & FEATURE-FIRST ARCHITECTURE - Průvodce pro Flutter

> **Účel**: Univerzální průvodce pro výstavbu škálovatelného Flutter projektu s BLoC pattern.
> **Cílová skupina**: Claude Code AI asistent při vývoji Flutter aplikace.
> **Použití**: Aplikovatelné na mobile apps, web apps, desktop apps s Flutter.

---

## 🗺️ NAVIGACE PRO AI AGENTY

**Pokud nevíš kde začít nebo jaký postup použít:**

👉 **[Otevři mapa-bloc.md](mapa-bloc.md)** - Navigační mapa s decision tree pro všechny typy úkolů

**mapa-bloc.md obsahuje:**
- ⚡ Quick Reference - najdi typ úkolu za 10 sekund
- 🚦 Decision Trees - 6 scénářů (přidat feature, upravit, refaktorovat, komunikace, shared widgets, state management)
- 📋 Step-by-step guides - konkrétní postupy
- 🚨 Critical Rules - co NIKDY nedělat
- 📊 Checklists - před/po každém úkolu

**Zlaté pravidlo:**
> Když dostaneš úkol → otevři [mapa-bloc.md](mapa-bloc.md) → najdi scénář → vrať se sem pro detaily

---

## 📚 OBSAH DOKUMENTU

### 🎯 Základy BLoC
- [📋 Quick Reference Card](#-quick-reference-card) - Rychlý přehled základních konceptů
- [🎯 Co je BLoC Pattern?](#-co-je-bloc-pattern) - Základní princip a srovnání
- [📁 Feature-First struktura](#-feature-first-struktura) - Organizace Flutter projektu
- [🏗️ Anatomie jedné Feature](#️-anatomie-jedné-feature) - Co obsahuje jeden slice

### 🧱 Principy a Best Practices
- [🧱 SOLID Principles v Flutter/BLoC](#-solid-principles-v-flutterbloc) - Aplikace SOLID
- [⚖️ Widget Composition](#️-widget-composition---high-cohesion-low-coupling) - Reusable widgets
- [🚫 YAGNI](#-yagni---you-arent-gonna-need-it) - Nepřidávej features "pro budoucnost"
- [🔄 Build Optimization](#-build-optimization---performance) - Kdy použít const, keys, rebuilds
- [⚡ Fail Fast](#-fail-fast---validation) - Validace na začátku, assertions

### 🏗️ BLoC Pattern Deep Dive
- [🎨 BLoC Anatomy](#-bloc-anatomy---events-states-handlers) - Events, States, Handlers
- [📊 State Management Patterns](#-state-management-patterns) - Loading, Success, Error states
- [🔄 BLoC Communication](#-bloc-communication---feature-to-feature) - Jak features komunikují
- [🧪 Testing BLoC](#-testing-bloc) - Unit testy, widget testy, integration testy

### 🛠️ Implementace
- [🔧 Jak přidávat features](#-jak-správně-přidávat-features) - Proces přidání nové feature
- [🎨 Core Infrastructure](#-core-infrastructure---co-tam-patří) - Co patří do core/
- [💉 Dependency Injection](#-dependency-injection) - get_it, Provider, Riverpod
- [🚀 Postup při výstavbě od nuly](#-postup-při-výstavbě-od-nuly) - Fáze 1-4

### 🛠️ Praktické doplňky
- [🛠️ Flutter Best Practices](#️-flutter-best-practices) - Widget lifecycle, BuildContext, Keys
- [🏗️ Riverpod vs BLoC](#️-riverpod-vs-bloc---kdy-použít-co) - Srovnání state management řešení
- [📱 Platform-Specific Code](#-platform-specific-code) - Windows, Android, iOS, Web

### ⚠️ Chyby a Checklist
- [⚠️ Časté chyby](#️-časté-chyby-a-jak-se-jim-vyhnout) - Co nedělat
- [🎯 Checklist](#-checklist-jsem-na-správné-cestě) - Kontrola správnosti

### 📖 Reference
- [📚 Doporučená četba](#-doporučená-četba-pro-hlubší-pochopení) - Další zdroje
- [🎓 Závěrečné principy](#-závěrečné-principy) - Shrnutí klíčových myšlenek

---

## 📋 QUICK REFERENCE CARD

### 🏗️ Základní struktura Feature-First + BLoC

```
lib/
├── core/                    # Shared kernel (widgets, services, models)
├── features/                # Business features (BLoC slices)
│   └── feature_name/
│       ├── presentation/    # UI layer (BLoC, Pages, Widgets)
│       ├── data/            # Data layer (repositories, DTOs)
│       └── domain/          # Business logic (entities, use cases)
└── main.dart                # App entry + DI setup
```

### ➕ Přidání nové feature (5 kroků)

```bash
1. mkdir -p lib/features/{nova_feature}/{presentation,data,domain}
2. Vytvoř BLoC (events, states, bloc)
3. Vytvoř UI (page, widgets)
4. Registruj DI (main.dart nebo get_it)
5. Přidej routing (GoRouter / Navigator)
```

### 🤔 Rozhodovací strom

**Nová feature?**
- ✅ Jiný business proces (Todo List vs AI Motivation vs Tag Manager)
- ✅ Má vlastní BLoC/Cubit
- ✅ Dá se vypnout samostatně

**Shared widget?**
- ✅ Používá se ve 3+ features
- ✅ Žádná business logika
- ✅ Pure presentational component

**Core service?**
- ✅ Technická záležitost (DB, HTTP, AI client)
- ✅ Používá 3+ features
- ✅ Žádná UI logika

---

## 🎯 CO JE BLOC PATTERN?

### 📖 Definice

**BLoC = Business Logic Component**

Architektonický pattern pro Flutter oddělující:
- **Presentation layer** (UI widgets) ← co uživatel vidí
- **Business logic layer** (BLoC) ← jak data zpracováváme
- **Data layer** (repositories) ← odkud data bereme

### 🔄 Data Flow v BLoC

```
┌─────────────┐
│   Widget    │  1. User tapne button
└──────┬──────┘
       │ add(Event)
       ▼
┌─────────────┐
│    BLoC     │  2. BLoC zpracuje event
└──────┬──────┘
       │ emit(State)
       ▼
┌─────────────┐
│   Widget    │  3. Widget rebuilds s novým state
└─────────────┘
```

### 💡 Příklad - Todo List

```dart
// ❌ ŠPATNĚ - business logika v widgetu
class _TodoPageState extends State<TodoPage> {
  List<Todo> todos = [];

  void addTodo(String text) {
    // Business logika přímo ve State!
    final todo = Todo(text: text);
    setState(() => todos.add(todo));
    database.insert(todo); // Database call v UI!
  }
}

// ✅ SPRÁVNĚ - BLoC odděluje logiku
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repo;

  TodoBloc(this._repo) : super(TodoInitial()) {
    on<AddTodo>(_onAddTodo);
  }

  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    final todo = Todo(text: event.text);
    await _repo.insert(todo); // Business logika v BLoC
    final todos = await _repo.getAll();
    emit(TodosLoaded(todos));
  }
}

// Widget jen zobrazuje data
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodosLoaded) {
          return ListView(children: state.todos.map(_buildItem).toList());
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### 🆚 BLoC vs jiné patterns

| Pattern | Pro | Proti | Kdy použít |
|---------|-----|-------|-----------|
| **BLoC** | Škálovatelné, testovatelné, standard | Více boilerplate | Střední-velké projekty (5+ features) |
| **Cubit** | Jednodušší než BLoC, méně kódu | Méně struktura | Menší features, jednoduché state |
| **Riverpod** | Moderní, compile-safe, DI built-in | Novější, učící křivka | Nové projekty, pokud preferuješ functional style |
| **Provider** | Jednoduchý, nízká bariéra | Nevhodné pro komplexní state | Malé projekty, prototypy |
| **setState** | Vestavěné, žádné deps | Nešká­lovatelné | Toy apps, velmi jednoduché widgety |

---

## 📁 FEATURE-FIRST STRUKTURA

### 🏗️ Kompletní struktura projektu

```
lib/
├── core/                           # 🎨 Shared kernel
│   ├── theme/
│   │   └── app_theme.dart          # Material theme, colors
│   ├── widgets/                    # Shared widgets (použité 3+x)
│   │   ├── custom_button.dart
│   │   └── loading_indicator.dart
│   ├── models/                     # Shared domain entities
│   │   └── result.dart             # Result<T> type pro error handling
│   ├── services/                   # Infrastructure services
│   │   ├── database_service.dart   # SQLite/Hive wrapper
│   │   ├── api_client.dart         # HTTP client (dio)
│   │   └── logger.dart             # Logging service
│   ├── utils/                      # Pure utility functions
│   │   ├── date_formatter.dart
│   │   └── validators.dart
│   └── di/                         # Dependency injection setup
│       └── injection.dart          # get_it registrace
│
├── features/                       # 🎯 Business features
│   ├── todo_list/                  # Feature: Seznam úkolů
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   │   ├── todo_list_bloc.dart
│   │   │   │   ├── todo_list_event.dart
│   │   │   │   └── todo_list_state.dart
│   │   │   ├── pages/
│   │   │   │   └── todo_list_page.dart
│   │   │   └── widgets/
│   │   │       ├── todo_card.dart
│   │   │       └── todo_filter_bar.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── todo_repository_impl.dart
│   │   │   └── models/
│   │   │       └── todo_dto.dart   # Data Transfer Object
│   │   └── domain/
│   │       ├── entities/
│   │       │   └── todo.dart       # Business entity
│   │       └── repositories/
│   │           └── todo_repository.dart  # Interface
│   │
│   ├── ai_motivation/              # Feature: AI motivace
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   │   └── motivation_cubit.dart  # Cubit pro jednodušší state
│   │   │   └── widgets/
│   │   │       └── motivation_dialog.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── ai_repository_impl.dart
│   │   └── domain/
│   │       ├── entities/
│   │       │   └── motivation.dart
│   │       └── repositories/
│   │           └── ai_repository.dart
│   │
│   ├── tag_system/                 # Feature: Tag management
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   │   └── tag_manager_bloc.dart
│   │   │   └── pages/
│   │   │       └── tag_manager_page.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── tag_repository_impl.dart
│   │   │   └── services/
│   │   │       └── tag_parser.dart  # Feature-specific service
│   │   └── domain/
│   │       ├── entities/
│   │       │   └── tag_definition.dart
│   │       └── repositories/
│   │           └── tag_repository.dart
│   │
│   └── settings/                   # Feature: Nastavení
│       └── presentation/
│           ├── cubit/
│           │   └── settings_cubit.dart
│           └── pages/
│               └── settings_page.dart
│
├── main.dart                       # 🚀 App entry point
└── app.dart                        # App widget (routing, theme)
```

### 📂 Pravidla organizace složek

| Složka | Co patří | Co NEPATŘÍ |
|--------|----------|------------|
| **core/widgets/** | Widgety použité ve 3+ features | Feature-specific widgety |
| **core/services/** | DB, HTTP, Logger, Cache | Business logika |
| **core/models/** | Shared entities (User, Result<T>) | Feature-specific entities |
| **features/{name}/presentation/** | BLoC, Pages, Widgets | Data access, repositories |
| **features/{name}/data/** | Repositories impl, DTOs, API calls | UI widgets, BLoC |
| **features/{name}/domain/** | Entities, Repository interfaces | Implementation details |

---

## 🏗️ ANATOMIE JEDNÉ FEATURE

### Minimální Feature (Cubit)

```
features/simple_counter/
├── presentation/
│   ├── cubit/
│   │   └── counter_cubit.dart      # State management
│   └── pages/
│       └── counter_page.dart       # UI
```

```dart
// counter_cubit.dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// counter_page.dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: BlocBuilder<CounterCubit, int>(
        builder: (context, count) {
          return Scaffold(
            body: Center(child: Text('Count: $count')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.read<CounterCubit>().increment(),
              child: Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
```

### Plná Feature (BLoC + Clean Architecture)

```
features/todo_list/
├── presentation/
│   ├── bloc/
│   │   ├── todo_list_bloc.dart     # BLoC implementation
│   │   ├── todo_list_event.dart    # Events (sealed class)
│   │   └── todo_list_state.dart    # States (sealed class)
│   ├── pages/
│   │   └── todo_list_page.dart     # Full page widget
│   └── widgets/
│       ├── todo_card.dart          # Feature-specific widget
│       └── todo_filter.dart
├── data/
│   ├── repositories/
│   │   └── todo_repository_impl.dart  # Concrete implementation
│   ├── models/
│   │   └── todo_dto.dart           # Data Transfer Object
│   └── datasources/
│       ├── todo_local_datasource.dart   # SQLite
│       └── todo_remote_datasource.dart  # API (pokud existuje)
└── domain/
    ├── entities/
    │   └── todo.dart               # Pure Dart entity
    ├── repositories/
    │   └── todo_repository.dart    # Abstract interface
    └── usecases/
        ├── get_todos.dart          # Use case (optional pro malé projekty)
        └── add_todo.dart
```

### 🤔 Kdy použít jakou strukturu?

| Velikost feature | Struktura | Poznámka |
|------------------|-----------|----------|
| **Triviální** (1 screen, simple state) | Cubit + Page | Counter, Toggle |
| **Jednoduchá** (1-2 screens, async ops) | BLoC + Page + Widgets | Settings, About |
| **Střední** (3+ screens, data persistence) | BLoC + Data + Domain | Todo List, Notes |
| **Komplexní** (multiple flows, API sync) | Full Clean Architecture | E-commerce, Social |

---

## 🧱 SOLID PRINCIPLES V FLUTTER/BLOC

### 1️⃣ **Single Responsibility Principle (SRP)**

**Pravidlo:** Každý widget/BLoC má JEDNU zodpovědnost.

```dart
// ❌ ŠPATNĚ - widget dělá všechno
class TodoPage extends StatefulWidget {
  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Todo> todos = [];
  bool isLoading = false;

  void loadTodos() async {
    // Data fetching v UI!
    setState(() => isLoading = true);
    todos = await database.getTodos(); // Přímý database access!
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // UI + business logika + data access = SRP violation!
    return Scaffold(...);
  }
}

// ✅ SPRÁVNĚ - separace zodpovědností
// 1. BLoC = business logika
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;
  // Pouze business logika!
}

// 2. Repository = data access
class TodoRepositoryImpl implements TodoRepository {
  final DatabaseService _db;
  // Pouze data access!
}

// 3. Page = UI kompozice
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Pouze UI! Žádná logika.
    return BlocBuilder<TodoBloc, TodoState>(...);
  }
}

// 4. Widget = single piece of UI
class TodoCard extends StatelessWidget {
  final Todo todo;
  // Pouze zobrazení jednoho todo!
}
```

### 2️⃣ **Open/Closed Principle (OCP)**

**Pravidlo:** Rozšiřuj pomocí kompozice, ne modifikací.

```dart
// ❌ ŠPATNĚ - modifikace existujícího BLoC pro novou funkci
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  // Original funkce
  on<LoadTodos>(_onLoadTodos);

  // ❌ Přidáváš AI motivaci přímo do TodoBloc?
  on<GetMotivation>(_onGetMotivation); //违反 OCP!
}

// ✅ SPRÁVNĚ - nová funkce = nový BLoC
// todo_list_bloc.dart - nezměněn
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  on<LoadTodos>(_onLoadTodos);
  on<AddTodo>(_onAddTodo);
  // Zůstává malý a fokusovaný
}

// motivation_cubit.dart - nový soubor
class MotivationCubit extends Cubit<MotivationState> {
  final AIRepository _aiRepo;

  Future<void> getMotivation(Todo todo) async {
    // Nová funkce v novém BLoC!
  }
}

// todo_page.dart - kompozice
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TodoBloc(repo)),
        BlocProvider(create: (_) => MotivationCubit(aiRepo)),
      ],
      child: TodoListView(),
    );
  }
}
```

### 3️⃣ **Liskov Substitution Principle (LSP)**

**Pravidlo:** Implementace musí respektovat kontrakt rozhraní.

```dart
// ❌ ŠPATNĚ - repository mění kontrakt
abstract class TodoRepository {
  Future<List<Todo>> getAll(); // Kontrakt: vždy vrátí list
}

class TodoRepositoryImpl implements TodoRepository {
  @override
  Future<List<Todo>> getAll() async {
    final result = await _db.query('todos');
    if (result.isEmpty) {
      throw Exception('No todos'); // ❌ Mění kontrakt! Může throwovat.
    }
    return result.map((e) => Todo.fromJson(e)).toList();
  }
}

// ✅ SPRÁVNĚ - respektuj kontrakt
abstract class TodoRepository {
  Future<List<Todo>> getAll(); // Kontrakt: vždy vrátí list (může být prázdný)
}

class TodoRepositoryImpl implements TodoRepository {
  @override
  Future<List<Todo>> getAll() async {
    try {
      final result = await _db.query('todos');
      return result.map((e) => Todo.fromJson(e)).toList();
    } catch (e) {
      return []; // ✅ Kontrakt respektován - vždy vrátí list
    }
  }
}
```

### 4️⃣ **Interface Segregation Principle (ISP)**

**Pravidlo:** Malá, fokusovaná rozhraní.

```dart
// ❌ ŠPATNĚ - fat interface
abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(int id);
  Future<void> syncWithCloud(); // ❌ Ne všechny implementace potřebují
  Future<void> exportToCSV();   // ❌ Ne všechny implementace potřebují
  Future<void> importFromJSON(); // ❌ Ne všechny implementace potřebují
}

// Mock v testu musí implementovat všechny metody!
class MockTodoRepository implements TodoRepository {
  // ❌ Musím mockovat i syncWithCloud, i když ho v testu nepotřebuji
  @override
  Future<void> syncWithCloud() => throw UnimplementedError();
}

// ✅ SPRÁVNĚ - segregované interfaces
abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<void> insert(Todo todo);
  Future<void> update(Todo todo);
  Future<void> delete(int id);
}

abstract class TodoSyncRepository {
  Future<void> syncWithCloud();
}

abstract class TodoExportRepository {
  Future<void> exportToCSV();
  Future<void> importFromJSON();
}

// Implementace může implementovat jen to, co potřebuje
class TodoRepositoryImpl implements TodoRepository {
  // Pouze CRUD operace
}

class TodoCloudRepository implements TodoRepository, TodoSyncRepository {
  // CRUD + sync
}

// Mock v testu implementuje jen minimum
class MockTodoRepository implements TodoRepository {
  @override
  Future<List<Todo>> getAll() async => [];
  // Zbytek jen pro test
}
```

### 5️⃣ **Dependency Inversion Principle (DIP)**

**Pravidlo:** Závisej na abstrakcích, ne na konkrétních třídách.

```dart
// ❌ ŠPATNĚ - BLoC závisí na konkrétní implementaci
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final DatabaseService _db; // ❌ Konkrétní třída!

  TodoBloc(this._db) : super(TodoInitial());

  Future<void> _onLoadTodos(LoadTodos event, Emitter emit) async {
    final todos = await _db.query('SELECT * FROM todos'); // ❌ SQL v BLoC!
    emit(TodosLoaded(todos));
  }
}

// ✅ SPRÁVNĚ - BLoC závisí na abstrakci
// 1. Definuj interface
abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<void> insert(Todo todo);
}

// 2. BLoC závisí na interface
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository; // ✅ Abstrakce!

  TodoBloc(this._repository) : super(TodoInitial());

  Future<void> _onLoadTodos(LoadTodos event, Emitter emit) async {
    final todos = await _repository.getAll(); // ✅ Čistá abstrakce!
    emit(TodosLoaded(todos));
  }
}

// 3. Implementace je vyměnitelná
class TodoRepositoryImpl implements TodoRepository {
  final DatabaseService _db;

  @override
  Future<List<Todo>> getAll() async {
    final result = await _db.query('todos');
    return result.map((e) => Todo.fromJson(e)).toList();
  }
}

// 4. DI v main.dart
void main() {
  final db = DatabaseService();
  final repository = TodoRepositoryImpl(db); // Concrete
  final bloc = TodoBloc(repository);         // Interface

  runApp(MyApp());
}

// 5. V testech můžeš snadno mocknout
class MockTodoRepository implements TodoRepository {
  @override
  Future<List<Todo>> getAll() async => [
    Todo(id: 1, text: 'Test todo'),
  ];
}

void main() {
  testWidgets('TodoBloc loads todos', (tester) async {
    final mockRepo = MockTodoRepository(); // ✅ Mock!
    final bloc = TodoBloc(mockRepo);
    // Test...
  });
}
```

---

## ⚖️ WIDGET COMPOSITION - High Cohesion, Low Coupling

### 🎯 Princip: Malé, znovupoužitelné widgety

**High Cohesion**: Widget dělá JEDNU věc dobře.
**Low Coupling**: Widget nezávisí na konkrétní feature.

### ❌ ŠPATNÝ PŘÍKLAD - God Widget

```dart
class TodoCard extends StatelessWidget {
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    // ❌ Obrovský widget dělající všechno
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: todo.isCompleted ? Colors.green : Colors.white,
        border: Border.all(
          color: todo.priority == 'a'
              ? Colors.red
              : todo.priority == 'b'
                  ? Colors.yellow
                  : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo.isCompleted,
            onChanged: (val) {
              // ❌ Business logika v widgetu!
              context.read<TodoBloc>().add(ToggleTodo(todo));
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.text,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontSize: 16,
                  ),
                ),
                if (todo.dueDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12),
                      SizedBox(width: 4),
                      Text(
                        // ❌ Formátování v widgetu!
                        '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                if (todo.tags.isNotEmpty)
                  Wrap(
                    children: todo.tags.map((tag) {
                      // ❌ Inline widget bez reuse
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 10)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              // ❌ Business logika v widgetu!
              context.read<TodoBloc>().add(DeleteTodo(todo.id));
            },
          ),
        ],
      ),
    );
  }
}
```

### ✅ DOBRÝ PŘÍKLAD - Kompozice malých widgetů

```dart
// 1. Atomický widget - Tag chip (reusable)
class TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const TagChip({required this.label, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}

// 2. Atomický widget - Date display (reusable)
class DateDisplay extends StatelessWidget {
  final DateTime date;

  const DateDisplay({required this.date});

  @override
  Widget build(BuildContext context) {
    // ✅ Používá utility funkci pro formátování
    final formatted = DateFormatter.formatShort(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today, size: 12),
        const SizedBox(width: 4),
        Text(formatted, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// 3. Molekulární widget - Todo metadata
class TodoMetadata extends StatelessWidget {
  final DateTime? dueDate;
  final List<String> tags;

  const TodoMetadata({this.dueDate, this.tags = const []});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dueDate != null) DateDisplay(date: dueDate!),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 4,
            children: tags.map((tag) => TagChip(label: tag)).toList(),
          ),
      ],
    );
  }
}

// 4. Organismus - Todo card (kompozice)
class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoCard({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: todo.isCompleted ? Colors.green.shade50 : Colors.white,
        border: Border.all(color: _getPriorityColor(todo.priority)),
      ),
      child: Row(
        children: [
          // ✅ Callback pattern - logika mimo widget
          Checkbox(value: todo.isCompleted, onChanged: (_) => onToggle()),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.text,
                  style: TextStyle(
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                // ✅ Kompozice malých widgetů
                TodoMetadata(dueDate: todo.dueDate, tags: todo.tags),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete, // ✅ Callback
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    // ✅ Private helper - pure function
    switch (priority) {
      case 'a': return Colors.red;
      case 'b': return Colors.yellow;
      case 'c': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// 5. Usage v page
class TodoListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodosLoaded) {
          return ListView.builder(
            itemCount: state.todos.length,
            itemBuilder: (context, index) {
              final todo = state.todos[index];
              return TodoCard(
                todo: todo,
                // ✅ Logika v BLoC, callback v widget
                onToggle: () => context.read<TodoBloc>().add(ToggleTodo(todo)),
                onDelete: () => context.read<TodoBloc>().add(DeleteTodo(todo.id)),
              );
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
```

### 📊 Widget Hierarchy - Atomic Design

```
Atoms (nejmenší jednotky):
├── TagChip
├── DateDisplay
├── PriorityBadge
└── CustomButton

Molecules (kompozice atomů):
├── TodoMetadata (DateDisplay + TagChip[])
├── TodoHeader (Text + PriorityBadge)
└── ActionBar (CustomButton[])

Organisms (kompozice molecules):
├── TodoCard (Checkbox + TodoHeader + TodoMetadata + ActionBar)
├── TodoFilters (CustomButton[] + Dropdown)
└── TodoStats (Text + Chart)

Templates (page layouts):
└── TodoListTemplate (AppBar + TodoFilters + ListView<TodoCard>)

Pages (final compositions):
└── TodoListPage (Template + BLoC provider)
```

---

## 🚫 YAGNI - You Aren't Gonna Need It

### 🎯 Pravidlo: Implementuj POUZE co potřebuješ TEĎ

**YAGNI violations jsou největší zdroj complexity a tech debtu!**

### ❌ YAGNI VIOLATIONS - Příklady

```dart
// ❌ Spekulativní abstrakce
abstract class BaseBloc<E, S> {
  // "Možná budeme potřebovat analytics tracking"
  void trackEvent(E event) { /* ... */ }

  // "Možná budeme chtítundo/redo"
  void undo() { /* ... */ }
  void redo() { /* ... */ }

  // "Možná budeme potřebovat caching"
  Map<String, S> _cache = {};
  S? getCached(String key) => _cache[key];
}

// ❌ Over-engineering repository
abstract class Repository<T> {
  // Používáš jen getAll() a insert(), ale "pro budoucnost":
  Future<T?> getById(int id);
  Future<List<T>> getAll();
  Future<List<T>> getByPage(int page, int size);  // ❌ YAGNI
  Future<void> insert(T entity);
  Future<void> insertBatch(List<T> entities);      // ❌ YAGNI
  Future<void> update(T entity);
  Future<void> upsert(T entity);                   // ❌ YAGNI
  Future<void> delete(int id);
  Future<void> deleteAll();                        // ❌ YAGNI
  Stream<List<T>> watch();                         // ❌ YAGNI
  Future<void> syncWithCloud();                    // ❌ YAGNI
}

// ❌ Spekulativní feature
features/
├── blockchain_integration/   # ❌ "Možná budeme potřebovat NFT"
├── social_sharing/           # ❌ "Možná přidáme social features"
└── premium_subscription/     # ❌ "Možná to zmonetizujeme"

// ❌ Over-configured state
class TodoState {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;
  final TodoFilter filter;       // ✅ Používáš
  final TodoSort sort;           // ❌ Ještě neimplementováno
  final PaginationInfo? pagination;  // ❌ "Pro budoucnost"
  final Map<String, dynamic> metadata;  // ❌ "Možná budeme potřebovat"
}
```

### ✅ YAGNI COMPLIANCE - Jak to dělat správně

```dart
// ✅ Jednoduchý BLoC - žádné spekulace
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;

  TodoBloc(this._repository) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    // Pouze to, co skutečně používáš!
  }
}

// ✅ Minimální repository - jen co potřebuješ TEĎ
abstract class TodoRepository {
  Future<List<Todo>> getAll();
  Future<void> insert(Todo todo);
  Future<void> delete(int id);
  // To je všechno! Zbytek přidáš KDYŽ to budeš potřebovat.
}

// ✅ Jednoduchý state
class TodoState {
  final List<Todo> todos;
  final bool isLoading;
  final String? error;
  // To je všechno! Filter přidáš KDYŽ uživatel řekne "chci filtrovat".
}

// ✅ Grow incrementally
// Teď máš:
features/
└── todo_list/

// KDYŽ uživatel řekne "chci AI motivaci":
features/
├── todo_list/
└── ai_motivation/        # ✅ Přidej TEĎ, ne "pro budoucnost"

// KDYŽ uživatel řekne "chci tagy":
features/
├── todo_list/
├── ai_motivation/
└── tag_system/           # ✅ Přidej TEĎ
```

### 🔄 Rule of Three - Kdy abstraovat

**Duplicita není vždy zlá!**

```dart
// 1. První implementace
features/todo_list/presentation/widgets/todo_card.dart
class TodoCard extends StatelessWidget {
  // Implementace karty
}

// 2. Druhá duplicita - OK, NECH TO TAK!
features/notes/presentation/widgets/note_card.dart
class NoteCard extends StatelessWidget {
  // Podobná implementace - ❌ NEABSTRAHUJ JEŠ��Ě!
  // Duplicita je levnější než špatná abstrakce!
}

// 3. Třetí duplicita - TEĎ abstrahi
features/tasks/presentation/widgets/task_card.dart
class TaskCard extends StatelessWidget {
  // Třetí podobná implementace - ✅ TEĎ je čas abstraovat!
}

// ✅ Po třetí duplikaci vytvoř abstrakci
core/widgets/base_card.dart
class BaseCard extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  // Shared implementace pro všechny 3 karty
}

// Refaktoruj všechny 3:
class TodoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseCard(title: Text(todo.text), ...);
  }
}
```

---

## 🔄 BUILD OPTIMIZATION - Performance

### 🎯 Pravidlo: Minimalizuj rebuildy

**Flutter rebuilds widgety při každém setState/emit. Optimalizuj!**

### 1️⃣ **Const Constructors**

```dart
// ❌ ŠPATNĚ - rebuild při každém parent rebuild
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('TODO List'),  // ❌ Nový Text() při každém rebuildu!
    );
  }
}

// ✅ SPRÁVNĚ - const = Flutter ví, že se to nemění
class Header extends StatelessWidget {
  const Header({super.key});  // ✅ const constructor

  @override
  Widget build(BuildContext context) {
    return const AppBar(
      title: Text('TODO List'),  // ✅ const = žádný rebuild
    );
  }
}
```

### 2️⃣ **BlocBuilder buildWhen**

```dart
// ❌ ŠPATNĚ - rebuild při KAŽDÉ změně state
class TodoCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodosLoaded) {
          return Text('Count: ${state.todos.length}');
        }
        return Text('Count: 0');
      },
    );
  }
}
// ❌ Problém: Rebuilds i když se změní jen isLoading, ne todos!

// ✅ SPRÁVNĚ - rebuild JEN když se změní count
class TodoCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      buildWhen: (previous, current) {
        // ✅ Rebuild JEN když se změní počet todos
        if (previous is TodosLoaded && current is TodosLoaded) {
          return previous.todos.length != current.todos.length;
        }
        return true;
      },
      builder: (context, state) {
        if (state is TodosLoaded) {
          return Text('Count: ${state.todos.length}');
        }
        return const Text('Count: 0');
      },
    );
  }
}
```

### 3️⃣ **BlocSelector - pro konkrétní property**

```dart
// ❌ ŠPATNĚ - celý widget rebuilds když se změní COKOLIV v state
class IsLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        return state.isLoading
            ? CircularProgressIndicator()
            : SizedBox.shrink();
      },
    );
  }
}
// ❌ Rebuilds i když se změní todos, error, filter, ...

// ✅ SPRÁVNĚ - rebuild JEN když se změní isLoading
class IsLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<TodoBloc, bool>(
      (bloc) => bloc.state.isLoading,  // ✅ Select jen isLoading
    );

    return isLoading
        ? const CircularProgressIndicator()
        : const SizedBox.shrink();
  }
}
```

### 4️⃣ **Keys pro ListView performance**

```dart
// ❌ ŠPATNĚ - bez keys
class TodoListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodosLoaded) {
          return ListView.builder(
            itemCount: state.todos.length,
            itemBuilder: (context, index) {
              final todo = state.todos[index];
              // ❌ Bez key - Flutter neví který widget je který
              return TodoCard(todo: todo);
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}

// ✅ SPRÁVNĚ - s ValueKey
class TodoListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodosLoaded) {
          return ListView.builder(
            itemCount: state.todos.length,
            itemBuilder: (context, index) {
              final todo = state.todos[index];
              // ✅ ValueKey - Flutter ví který widget přesunout/update
              return TodoCard(
                key: ValueKey(todo.id),
                todo: todo,
              );
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
```

### 5️⃣ **Equatable pro State comparison**

```dart
// ❌ ŠPATNĚ - bez Equatable
class TodoState {
  final List<Todo> todos;
  final bool isLoading;

  TodoState({required this.todos, required this.isLoading});
}

void emitState() {
  emit(TodoState(todos: [todo1, todo2], isLoading: false));
  emit(TodoState(todos: [todo1, todo2], isLoading: false));
  // ❌ Dva emits se STEJNÝM obsahem = 2 rebuilds!
}

// ✅ SPRÁVNĚ - s Equatable
class TodoState extends Equatable {
  final List<Todo> todos;
  final bool isLoading;

  const TodoState({required this.todos, required this.isLoading});

  @override
  List<Object?> get props => [todos, isLoading];  // ✅ Equatable porovná
}

void emitState() {
  emit(TodoState(todos: [todo1, todo2], isLoading: false));
  emit(TodoState(todos: [todo1, todo2], isLoading: false));
  // ✅ Druhý emit ignorován - stejný obsah = žádný rebuild!
}
```

---

## ⚡ FAIL FAST - Validation

### 🎯 Pravidlo: Validuj hned na začátku, crash early

**Better to crash explicitly než failovat tiše!**

### ❌ ŠPATNÝ PŘÍKLAD - Silent failures

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    // ❌ Žádná validace!
    final todo = Todo(text: event.text);
    await _repository.insert(todo);
    // ❌ Co když event.text je prázdný? Tiše uloží prázdný todo!
  }
}

class TodoRepositoryImpl implements TodoRepository {
  @override
  Future<void> insert(Todo todo) async {
    // ❌ Žádná validace!
    await _db.insert('todos', todo.toJson());
    // ❌ Co když _db je null? Runtime exception!
  }
}
```

### ✅ DOBRÝ PŘÍKLAD - Fail Fast

```dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    // ✅ Fail Fast validace na začátku
    if (event.text.trim().isEmpty) {
      emit(TodoError('Text nesmí být prázdný'));
      return;  // Early return
    }

    if (event.text.length > 500) {
      emit(TodoError('Text je příliš dlouhý (max 500 znaků)'));
      return;
    }

    // ✅ Validace prošla, pokračuj s business logikou
    try {
      final todo = Todo(text: event.text.trim());
      await _repository.insert(todo);

      final todos = await _repository.getAll();
      emit(TodosLoaded(todos));
    } catch (e) {
      // ✅ Explicit error handling
      emit(TodoError('Chyba při ukládání: $e'));
    }
  }
}

class TodoRepositoryImpl implements TodoRepository {
  final DatabaseService _db;

  TodoRepositoryImpl(this._db) {
    // ✅ Assert v konstruktoru (debug mode)
    assert(_db != null, 'DatabaseService nesmí být null');
  }

  @override
  Future<void> insert(Todo todo) async {
    // ✅ Preconditions
    if (todo.text.isEmpty) {
      throw ArgumentError('Todo text nesmí být prázdný');
    }

    // ✅ Business logika
    try {
      await _db.insert('todos', todo.toJson());
    } catch (e) {
      // ✅ Wrap database exception s kontextem
      throw RepositoryException('Chyba při vkládání todo: $e');
    }
  }
}

// ✅ Custom exception pro lepší error handling
class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}
```

### 🔍 Assertions vs Exceptions

```dart
// ✅ Assertion - debug-only checks (developer errors)
void updateTodo(Todo todo) {
  assert(todo.id != null, 'Todo must have ID to update');  // ✅ Developer mistake
  assert(todo.text.isNotEmpty);  // ✅ Should be validated earlier

  _repository.update(todo);
}

// ✅ Exception - runtime checks (user/external errors)
void addTodo(String text) {
  if (text.isEmpty) {
    throw ArgumentError('Text nesmí být prázdný');  // ✅ User input error
  }

  if (text.length > 500) {
    throw ArgumentError('Text příliš dlouhý');  // ✅ Business rule violation
  }

  _repository.insert(Todo(text: text));
}
```

---

## 🎨 BLOC ANATOMY - Events, States, Handlers

### 🏗️ Struktura BLoC

```
features/todo_list/presentation/bloc/
├── todo_list_bloc.dart      # BLoC implementation
├── todo_list_event.dart     # Events (sealed class)
└── todo_list_state.dart     # States (sealed class)
```

### 1️⃣ **Events - Co se stalo**

```dart
// todo_list_event.dart
sealed class TodoListEvent {}

// ✅ Load todos from database
final class LoadTodos extends TodoListEvent {}

// ✅ Add new todo
final class AddTodo extends TodoListEvent {
  final String text;
  final String? priority;
  final DateTime? dueDate;

  AddTodo({required this.text, this.priority, this.dueDate});
}

// ✅ Toggle todo completion
final class ToggleTodo extends TodoListEvent {
  final int todoId;

  ToggleTodo(this.todoId);
}

// ✅ Delete todo
final class DeleteTodo extends TodoListEvent {
  final int todoId;

  DeleteTodo(this.todoId);
}

// ✅ Filter todos
final class FilterTodos extends TodoListEvent {
  final TodoFilter filter;  // all, active, completed

  FilterTodos(this.filter);
}
```

**Best Practices pro Events:**
- ✅ Sealed class - kompilátor ví o všech events
- ✅ Final classes - nelze dědit
- ✅ Immutable - final fields
- ✅ Naming: {What}Happened (LoadTodos, AddTodo, ne LoadTodosEvent)
- ✅ Obsahuje pouze data potřebná pro akci

### 2️⃣ **States - Jak aplikace vypadá**

```dart
// todo_list_state.dart
sealed class TodoListState extends Equatable {
  const TodoListState();

  @override
  List<Object?> get props => [];
}

// ✅ Initial state (před načtením)
final class TodoListInitial extends TodoListState {}

// ✅ Loading state (probíhá načítání)
final class TodoListLoading extends TodoListState {}

// ✅ Success state (data načtena)
final class TodoListLoaded extends TodoListState {
  final List<Todo> todos;
  final TodoFilter filter;

  const TodoListLoaded({
    required this.todos,
    this.filter = TodoFilter.all,
  });

  @override
  List<Object?> get props => [todos, filter];

  // ✅ Convenience getter - filtered todos
  List<Todo> get filteredTodos {
    switch (filter) {
      case TodoFilter.active:
        return todos.where((t) => !t.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((t) => t.isCompleted).toList();
      case TodoFilter.all:
        return todos;
    }
  }

  // ✅ CopyWith pro immutability
  TodoListLoaded copyWith({
    List<Todo>? todos,
    TodoFilter? filter,
  }) {
    return TodoListLoaded(
      todos: todos ?? this.todos,
      filter: filter ?? this.filter,
    );
  }
}

// ✅ Error state
final class TodoListError extends TodoListState {
  final String message;

  const TodoListError(this.message);

  @override
  List<Object?> get props => [message];
}
```

**Best Practices pro States:**
- ✅ Sealed class - exhaustive pattern matching
- ✅ Extends Equatable - prevent unnecessary rebuilds
- ✅ Immutable - všechny fieldy final
- ✅ CopyWith method pro update immutable state
- ✅ Computed properties (getters) pro derived data

### 3️⃣ **BLoC - Event Handlers**

```dart
// todo_list_bloc.dart
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;

  TodoListBloc(this._repository) : super(TodoListInitial()) {
    // ✅ Registrace event handlerů
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<FilterTodos>(_onFilterTodos);
  }

  // ✅ Event handler - Load
  Future<void> _onLoadTodos(
    LoadTodos event,
    Emitter<TodoListState> emit,
  ) async {
    emit(TodoListLoading());

    try {
      final todos = await _repository.getAll();
      emit(TodoListLoaded(todos: todos));
    } catch (e) {
      emit(TodoListError('Chyba při načítání: $e'));
    }
  }

  // ✅ Event handler - Add
  Future<void> _onAddTodo(
    AddTodo event,
    Emitter<TodoListState> emit,
  ) async {
    // ✅ Fail Fast validace
    if (event.text.trim().isEmpty) {
      emit(const TodoListError('Text nesmí být prázdný'));
      return;
    }

    try {
      final todo = Todo(
        text: event.text.trim(),
        priority: event.priority,
        dueDate: event.dueDate,
      );

      await _repository.insert(todo);

      // ✅ Reload všechna todos (optimistic update možný, ale složitější)
      final todos = await _repository.getAll();

      // ✅ Preserve filter state pokud existuje
      if (state is TodoListLoaded) {
        final currentState = state as TodoListLoaded;
        emit(currentState.copyWith(todos: todos));
      } else {
        emit(TodoListLoaded(todos: todos));
      }
    } catch (e) {
      emit(TodoListError('Chyba při přidávání: $e'));
    }
  }

  // ✅ Event handler - Toggle
  Future<void> _onToggleTodo(
    ToggleTodo event,
    Emitter<TodoListState> emit,
  ) async {
    if (state is! TodoListLoaded) return;

    final currentState = state as TodoListLoaded;

    try {
      // ✅ Najdi todo
      final todo = currentState.todos.firstWhere((t) => t.id == event.todoId);

      // ✅ Toggle completion
      final updated = todo.copyWith(isCompleted: !todo.isCompleted);
      await _repository.update(updated);

      // ✅ Update local state
      final updatedTodos = currentState.todos.map((t) {
        return t.id == event.todoId ? updated : t;
      }).toList();

      emit(currentState.copyWith(todos: updatedTodos));
    } catch (e) {
      emit(TodoListError('Chyba při update: $e'));
    }
  }

  // ✅ Event handler - Delete
  Future<void> _onDeleteTodo(
    DeleteTodo event,
    Emitter<TodoListState> emit,
  ) async {
    if (state is! TodoListLoaded) return;

    final currentState = state as TodoListLoaded;

    try {
      await _repository.delete(event.todoId);

      // ✅ Remove from local state
      final updatedTodos = currentState.todos
          .where((t) => t.id != event.todoId)
          .toList();

      emit(currentState.copyWith(todos: updatedTodos));
    } catch (e) {
      emit(TodoListError('Chyba při mazání: $e'));
    }
  }

  // ✅ Event handler - Filter (no async, just state change)
  void _onFilterTodos(
    FilterTodos event,
    Emitter<TodoListState> emit,
  ) {
    if (state is TodoListLoaded) {
      final currentState = state as TodoListLoaded;
      emit(currentState.copyWith(filter: event.filter));
    }
  }
}
```

**Best Practices pro BLoC:**
- ✅ Private event handlers (_onEventName)
- ✅ Fail Fast validace na začátku
- ✅ Try-catch pro všechny async operace
- ✅ Preserve state properties při update (copyWith)
- ✅ Early returns když state není expected type
- ✅ Immutability - vždy emit NEW state

---

## 📊 STATE MANAGEMENT PATTERNS

### 🎯 Loading, Success, Error pattern

**Standard pattern pro async operace:**

```dart
// ✅ State hierarchy
sealed class TodoState extends Equatable {}

final class TodoInitial extends TodoState {}       // Před načtením
final class TodoLoading extends TodoState {}       // Probíhá načítání
final class TodoLoaded extends TodoState {         // Success
  final List<Todo> todos;
  const TodoLoaded(this.todos);
}
final class TodoError extends TodoState {          // Error
  final String message;
  const TodoError(this.message);
}

// ✅ UI handling
Widget build(BuildContext context) {
  return BlocBuilder<TodoBloc, TodoState>(
    builder: (context, state) {
      return switch (state) {
        TodoInitial() => const Text('Klikni pro načtení'),
        TodoLoading() => const CircularProgressIndicator(),
        TodoLoaded(:final todos) => ListView(
          children: todos.map((t) => TodoCard(todo: t)).toList(),
        ),
        TodoError(:final message) => Text('Error: $message'),
      };
    },
  );
}
```

### 🔄 Optimistic vs Pessimistic Updates

**Optimistic Update** - UI se aktualizuje okamžitě, pokud server failne, rollback:

```dart
// ✅ Optimistic update - rychlá UI response
Future<void> _onToggleTodo(ToggleTodo event, Emitter emit) async {
  if (state is! TodoLoaded) return;
  final currentState = state as TodoLoaded;

  // 1. ✅ Najdi todo a toggle lokálně (UI update okamžitě)
  final todo = currentState.todos.firstWhere((t) => t.id == event.todoId);
  final toggled = todo.copyWith(isCompleted: !todo.isCompleted);

  final optimisticTodos = currentState.todos.map((t) {
    return t.id == event.todoId ? toggled : t;
  }).toList();

  emit(TodoLoaded(optimisticTodos));  // ✅ Immediate UI update

  // 2. Update server v pozadí
  try {
    await _repository.update(toggled);
  } catch (e) {
    // 3. ❌ Server failed - rollback
    emit(TodoLoaded(currentState.todos));  // Restore original
    emit(TodoError('Update failed: $e'));
  }
}
```

**Pessimistic Update** - čekej na server response, pak aktualizuj UI:

```dart
// ✅ Pessimistic update - safe, ale pomalejší UX
Future<void> _onToggleTodo(ToggleTodo event, Emitter emit) async {
  if (state is! TodoLoaded) return;
  final currentState = state as TodoLoaded;

  // 1. Ukaž loading (optional)
  emit(TodoLoading());

  // 2. Update na serveru
  try {
    final todo = currentState.todos.firstWhere((t) => t.id == event.todoId);
    final toggled = todo.copyWith(isCompleted: !todo.isCompleted);

    await _repository.update(toggled);  // Čekej na server

    // 3. ✅ Server OK - aktualizuj UI
    final updatedTodos = currentState.todos.map((t) {
      return t.id == event.todoId ? toggled : t;
    }).toList();

    emit(TodoLoaded(updatedTodos));
  } catch (e) {
    // 4. ❌ Server failed - ukaž error, obnovč původní state
    emit(currentState);
    emit(TodoError('Update failed: $e'));
  }
}
```

**Kdy použít co:**
| Pattern | Kdy použít | Příklad |
|---------|-----------|---------|
| **Optimistic** | Rychlé akce, vysoká spolehlivost | Toggle, Like, Favorite |
| **Pessimistic** | Kritické operace, nízká spolehlivost | Payment, Delete, Submit form |

---

## 🔄 BLOC COMMUNICATION - Feature to Feature

### 🎯 Pravidlo: Features NEZNAJÍ o sobě navzájem

**❌ ZAKÁZÁNO: Přímé volání mezi BLoCs**

```dart
// ❌ ŠPATNĚ - TodoBloc volá MotivationCubit
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final MotivationCubit _motivationCubit;  // ❌ Cross-feature dependency!

  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    final todo = Todo(text: event.text);
    await _repository.insert(todo);

    // ❌ TodoBloc volá jinou feature!
    _motivationCubit.celebrate();  // ZAKÁZÁNO!
  }
}
```

### ✅ SPRÁVNĚ: Komunikace přes Events / Streams

#### Způsob 1: BlocListener (jednoduchý)

```dart
// ✅ TodoBloc emituje state, jiná feature reaguje
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TodoBloc(repo)),
        BlocProvider(create: (_) => MotivationCubit(aiRepo)),
      ],
      child: MultiBlocListener(
        listeners: [
          // ✅ Poslouchej TodoBloc events
          BlocListener<TodoBloc, TodoState>(
            listenWhen: (prev, curr) {
              // Reaguj jen když přidán nový todo
              if (prev is TodoLoaded && curr is TodoLoaded) {
                return curr.todos.length > prev.todos.length;
              }
              return false;
            },
            listener: (context, state) {
              // ✅ TodoBloc changed → Motivace reaguje
              if (state is TodoLoaded && state.todos.isNotEmpty) {
                final lastTodo = state.todos.last;
                context.read<MotivationCubit>().celebrate(lastTodo);
              }
            },
          ),
        ],
        child: TodoListView(),
      ),
    );
  }
}
```

#### Způsob 2: Stream Subscription (složitější, ale flexibilnější)

```dart
// ✅ MotivationCubit subscribuje na TodoBloc stream
class MotivationCubit extends Cubit<MotivationState> {
  final TodoBloc _todoBloc;
  StreamSubscription? _todoSubscription;

  MotivationCubit(this._todoBloc) : super(MotivationInitial()) {
    // ✅ Subscribe na TodoBloc changes
    _todoSubscription = _todoBloc.stream.listen((todoState) {
      if (todoState is TodoLoaded && todoState.todos.isNotEmpty) {
        _onTodoAdded(todoState.todos.last);
      }
    });
  }

  void _onTodoAdded(Todo todo) {
    // Reaguj na nový todo
    emit(MotivationCelebrating());
  }

  @override
  Future<void> close() {
    _todoSubscription?.cancel();
    return super.close();
  }
}
```

#### Způsob 3: Event Bus (pro komplexní komunikaci)

```dart
// core/events/app_events.dart
sealed class AppEvent {}

final class TodoAddedEvent extends AppEvent {
  final Todo todo;
  TodoAddedEvent(this.todo);
}

final class TodoDeletedEvent extends AppEvent {
  final int todoId;
  TodoDeletedEvent(this.todoId);
}

// core/services/event_bus.dart
class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  void fire(AppEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

// ✅ TodoBloc emituje events
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final EventBus _eventBus;

  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    final todo = Todo(text: event.text);
    await _repository.insert(todo);

    // ✅ Fire domain event
    _eventBus.fire(TodoAddedEvent(todo));

    emit(TodoLoaded([...state.todos, todo]));
  }
}

// ✅ MotivationCubit poslouchá events
class MotivationCubit extends Cubit<MotivationState> {
  final EventBus _eventBus;
  StreamSubscription? _subscription;

  MotivationCubit(this._eventBus) : super(MotivationInitial()) {
    // ✅ Subscribe na TodoAddedEvent
    _subscription = _eventBus.on<TodoAddedEvent>().listen((event) {
      celebrate(event.todo);
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

**Kdy použít co:**
| Způsob | Kdy použít | Složitost |
|--------|-----------|-----------|
| **BlocListener** | Jednoduchá reakce v UI | ⭐ Nízká |
| **Stream Subscription** | BLoC-to-BLoC komunikace | ⭐⭐ Střední |
| **Event Bus** | Komplexní multi-feature komunikace | ⭐⭐⭐ Vysoká (YAGNI - použij až když potřebuješ!) |

---

## 🧪 TESTING BLOC

### 🎯 Tři vrstvy testů

```
1. Unit Tests     → Test BLoC logiku
2. Widget Tests   → Test UI s mock BLoC
3. Integration    → Test celý flow
```

### 1️⃣ **Unit Testing BLoC**

```dart
// test/features/todo_list/presentation/bloc/todo_list_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ✅ Mock repository
class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  group('TodoListBloc', () {
    late TodoRepository repository;
    late TodoListBloc bloc;

    setUp(() {
      repository = MockTodoRepository();
      bloc = TodoListBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    // ✅ Test initial state
    test('initial state is TodoListInitial', () {
      expect(bloc.state, equals(TodoListInitial()));
    });

    // ✅ Test success scenario
    blocTest<TodoListBloc, TodoListState>(
      'emits [Loading, Loaded] when LoadTodos succeeds',
      build: () {
        // Arrange: mock repository response
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            Todo(id: 1, text: 'Test todo'),
          ],
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodos()),  // Act: dispatch event
      expect: () => [
        // Assert: verify state emissions
        TodoListLoading(),
        TodoListLoaded(todos: [Todo(id: 1, text: 'Test todo')]),
      ],
      verify: (_) {
        // Verify: repository called exactly once
        verify(() => repository.getAll()).called(1);
      },
    );

    // ✅ Test error scenario
    blocTest<TodoListBloc, TodoListState>(
      'emits [Loading, Error] when LoadTodos fails',
      build: () {
        when(() => repository.getAll()).thenThrow(
          Exception('Database error'),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        TodoListLoading(),
        isA<TodoListError>()
            .having((s) => s.message, 'message', contains('Database')),
      ],
    );

    // ✅ Test validation
    blocTest<TodoListBloc, TodoListState>(
      'emits Error when AddTodo with empty text',
      build: () => bloc,
      act: (bloc) => bloc.add(AddTodo(text: '')),
      expect: () => [
        const TodoListError('Text nesmí být prázdný'),
      ],
      verify: (_) {
        // Repository insert should NOT be called
        verifyNever(() => repository.insert(any()));
      },
    );
  });
}
```

### 2️⃣ **Widget Testing s Mock BLoC**

```dart
// test/features/todo_list/presentation/widgets/todo_card_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockTodoBloc extends Mock implements TodoBloc {}

void main() {
  group('TodoCard', () {
    late TodoBloc bloc;

    setUp(() {
      bloc = MockTodoBloc();
    });

    testWidgets('displays todo text', (tester) async {
      // Arrange
      final todo = Todo(id: 1, text: 'Buy milk');

      when(() => bloc.state).thenReturn(
        TodoListLoaded(todos: [todo]),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: TodoCard(
              todo: todo,
              onToggle: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Buy milk'), findsOneWidget);
    });

    testWidgets('calls onToggle when checkbox tapped', (tester) async {
      // Arrange
      final todo = Todo(id: 1, text: 'Buy milk', isCompleted: false);
      var toggleCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: TodoCard(
            todo: todo,
            onToggle: () => toggleCalled = true,
            onDelete: () {},
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));

      // Assert
      expect(toggleCalled, isTrue);
    });
  });
}
```

### 3️⃣ **Integration Testing**

```dart
// integration_test/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Todo App E2E', () {
    testWidgets('full todo lifecycle', (tester) async {
      // 1. Launch app
      app.main();
      await tester.pumpAndSettle();

      // 2. Add todo
      await tester.enterText(
        find.byType(TextField),
        'Buy groceries',
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // 3. Verify todo added
      expect(find.text('Buy groceries'), findsOneWidget);

      // 4. Toggle todo
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // 5. Verify todo completed (strikethrough)
      final textWidget = tester.widget<Text>(
        find.text('Buy groceries'),
      );
      expect(
        textWidget.style?.decoration,
        equals(TextDecoration.lineThrough),
      );

      // 6. Delete todo (swipe left)
      await tester.drag(
        find.text('Buy groceries'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // 7. Verify todo deleted
      expect(find.text('Buy groceries'), findsNothing);
    });
  });
}
```

**Testing Best Practices:**
- ✅ Používej `bloc_test` package pro BLoC testing
- ✅ Mockuj dependencies (repository, services)
- ✅ Test všechny scenarios: success, error, validation
- ✅ Widget tests s mock BLoCs (izolace)
- ✅ Integration tests pro critical user flows
- ✅ AAA pattern: Arrange, Act, Assert

---

## 🔧 JAK SPRÁVNĚ PŘIDÁVAT FEATURES

### 📋 Step-by-Step proces

#### **Krok 1: Identifikuj business funkci**

```
❌ ŠPATNĚ: "Chci přidat repository pro tagy"
→ To je technické řešení!

✅ SPRÁVNĚ: "Uživatel chce spravovat vlastní tagy"
→ To je business funkce!

Feature name: tag_management (ne tag_repository!)
```

#### **Krok 2: Vytvoř strukturu složek**

```bash
# ✅ Minimální feature
mkdir -p lib/features/tag_management/presentation/cubit
mkdir -p lib/features/tag_management/presentation/pages

# ✅ Střední feature (s data layer)
mkdir -p lib/features/tag_management/presentation/{bloc,pages,widgets}
mkdir -p lib/features/tag_management/data/{repositories,models}
mkdir -p lib/features/tag_management/domain/{entities,repositories}
```

#### **Krok 3: Implementuj Domain layer** (pokud používáš Clean Architecture)

```dart
// lib/features/tag_management/domain/entities/tag.dart
class Tag {
  final int? id;
  final String name;
  final String color;

  const Tag({this.id, required this.name, required this.color});
}

// lib/features/tag_management/domain/repositories/tag_repository.dart
abstract class TagRepository {
  Future<List<Tag>> getAll();
  Future<void> insert(Tag tag);
  Future<void> delete(int id);
}
```

#### **Krok 4: Implementuj Data layer**

```dart
// lib/features/tag_management/data/models/tag_dto.dart
class TagDto {
  final int? id;
  final String name;
  final String color;

  TagDto({this.id, required this.name, required this.color});

  // ✅ JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
  };

  factory TagDto.fromJson(Map<String, dynamic> json) => TagDto(
    id: json['id'] as int?,
    name: json['name'] as String,
    color: json['color'] as String,
  );

  // ✅ Convert DTO <-> Entity
  Tag toEntity() => Tag(id: id, name: name, color: color);

  factory TagDto.fromEntity(Tag tag) => TagDto(
    id: tag.id,
    name: tag.name,
    color: tag.color,
  );
}

// lib/features/tag_management/data/repositories/tag_repository_impl.dart
class TagRepositoryImpl implements TagRepository {
  final DatabaseService _db;

  TagRepositoryImpl(this._db);

  @override
  Future<List<Tag>> getAll() async {
    final result = await _db.query('tags');
    return result
        .map((json) => TagDto.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<void> insert(Tag tag) async {
    final dto = TagDto.fromEntity(tag);
    await _db.insert('tags', dto.toJson());
  }

  @override
  Future<void> delete(int id) async {
    await _db.delete('tags', id);
  }
}
```

#### **Krok 5: Implementuj Presentation layer (BLoC)**

```dart
// lib/features/tag_management/presentation/bloc/tag_event.dart
sealed class TagEvent {}
final class LoadTags extends TagEvent {}
final class AddTag extends TagEvent {
  final String name;
  final String color;
  AddTag({required this.name, required this.color});
}
final class DeleteTag extends TagEvent {
  final int id;
  DeleteTag(this.id);
}

// lib/features/tag_management/presentation/bloc/tag_state.dart
sealed class TagState extends Equatable {}
final class TagInitial extends TagState {}
final class TagLoading extends TagState {}
final class TagLoaded extends TagState {
  final List<Tag> tags;
  TagLoaded(this.tags);
  @override
  List<Object?> get props => [tags];
}
final class TagError extends TagState {
  final String message;
  TagError(this.message);
  @override
  List<Object?> get props => [message];
}

// lib/features/tag_management/presentation/bloc/tag_bloc.dart
class TagBloc extends Bloc<TagEvent, TagState> {
  final TagRepository _repository;

  TagBloc(this._repository) : super(TagInitial()) {
    on<LoadTags>(_onLoadTags);
    on<AddTag>(_onAddTag);
    on<DeleteTag>(_onDeleteTag);
  }

  Future<void> _onLoadTags(LoadTags event, Emitter emit) async {
    emit(TagLoading());
    try {
      final tags = await _repository.getAll();
      emit(TagLoaded(tags));
    } catch (e) {
      emit(TagError('Chyba: $e'));
    }
  }

  Future<void> _onAddTag(AddTag event, Emitter emit) async {
    if (event.name.trim().isEmpty) {
      emit(TagError('Název nesmí být prázdný'));
      return;
    }

    try {
      final tag = Tag(name: event.name, color: event.color);
      await _repository.insert(tag);

      final tags = await _repository.getAll();
      emit(TagLoaded(tags));
    } catch (e) {
      emit(TagError('Chyba: $e'));
    }
  }

  Future<void> _onDeleteTag(DeleteTag event, Emitter emit) async {
    try {
      await _repository.delete(event.id);

      if (state is TagLoaded) {
        final current = state as TagLoaded;
        final updated = current.tags.where((t) => t.id != event.id).toList();
        emit(TagLoaded(updated));
      }
    } catch (e) {
      emit(TagError('Chyba: $e'));
    }
  }
}
```

#### **Krok 6: Implementuj UI (Page + Widgets)**

```dart
// lib/features/tag_management/presentation/pages/tag_management_page.dart
class TagManagementPage extends StatelessWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ✅ DI - inject repository (viz Krok 7)
      create: (context) => TagBloc(
        context.read<TagRepository>(),
      )..add(LoadTags()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Správa tagů')),
        body: BlocBuilder<TagBloc, TagState>(
          builder: (context, state) {
            return switch (state) {
              TagInitial() => const Center(child: Text('Načti tagy')),
              TagLoading() => const Center(child: CircularProgressIndicator()),
              TagLoaded(:final tags) => ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) => TagTile(tag: tags[index]),
              ),
              TagError(:final message) => Center(child: Text('Error: $message')),
            };
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTagDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    // Dialog pro přidání tagu
  }
}

// lib/features/tag_management/presentation/widgets/tag_tile.dart
class TagTile extends StatelessWidget {
  final Tag tag;

  const TagTile({required this.tag, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(int.parse(tag.color)),
      ),
      title: Text(tag.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          context.read<TagBloc>().add(DeleteTag(tag.id!));
        },
      ),
    );
  }
}
```

#### **Krok 7: Registruj Dependency Injection**

```dart
// lib/core/di/injection.dart (s get_it)
final getIt = GetIt.instance;

void setupDependencies() {
  // ✅ Core services (singleton)
  getIt.registerLazySingleton(() => DatabaseService());

  // ✅ Repositories (factory - nový instance pro každý BLoC)
  getIt.registerFactory<TagRepository>(
    () => TagRepositoryImpl(getIt<DatabaseService>()),
  );
}

// lib/main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Setup DI
  setupDependencies();

  runApp(const MyApp());
}

// lib/app.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // ✅ Provide repository pro celou app
        RepositoryProvider<TagRepository>(
          create: (_) => getIt<TagRepository>(),
        ),
      ],
      child: MaterialApp(
        home: TagManagementPage(),
      ),
    );
  }
}
```

#### **Krok 8: Přidej routing**

```dart
// lib/app.dart (s GoRouter)
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TodoListPage(),
    ),
    GoRoute(
      path: '/tags',
      builder: (context, state) => const TagManagementPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }
}
```

#### **Krok 9: Commit změny**

```bash
# ✅ Atomic commit
git add lib/features/tag_management/
git commit -m "✨ feat: Přidání Tag Management feature

- Implementace TagBloc s events a states
- UI pro správu tagů (seznam, přidání, smazání)
- TagRepository s SQLite persistence
- DI registrace s get_it
- Routing v GoRouter"
```

---

## 🎨 CORE INFRASTRUCTURE - Co tam patří

### 🎯 Pravidlo: Core = Technické, ne Business

**Core obsahuje:**
- ✅ Infrastructure services (DB, HTTP, Logger)
- ✅ Shared widgets použité ve 3+ features
- ✅ Pure utility functions (date formatter, validators)
- ✅ Shared domain entities (pokud jsou skutečně shared)
- ✅ Theme, constants

**Core NEOBSAHUJE:**
- ❌ Business logiku
- ❌ Feature-specific widgety
- ❌ BLoCs/Cubits

### 📁 Struktura core/

```
core/
├── theme/
│   ├── app_theme.dart          # Material theme definition
│   └── app_colors.dart         # Color constants
│
├── widgets/                    # Shared UI components (3+ features)
│   ├── custom_button.dart
│   ├── loading_indicator.dart
│   └── error_display.dart
│
├── models/                     # Shared domain entities
│   ├── result.dart             # Result<T> for error handling
│   └── user.dart               # User entity (pokud shared)
│
├── services/                   # Infrastructure services
│   ├── database_service.dart   # SQLite/Hive wrapper
│   ├── api_client.dart         # HTTP client (dio)
│   ├── logger.dart             # Logging service
│   └── storage_service.dart    # SharedPreferences wrapper
│
├── utils/                      # Pure utility functions
│   ├── date_formatter.dart
│   ├── validators.dart
│   └── extensions.dart         # Dart extensions
│
├── constants/
│   ├── app_constants.dart      # App-wide constants
│   └── api_constants.dart      # API endpoints
│
└── di/
    └── injection.dart          # Dependency injection setup
```

### ❌ Co NEPATŘÍ do core/ - příklady

```dart
// ❌ ŠPATNĚ - business logika v core/
// core/services/todo_service.dart
class TodoService {
  Future<void> addTodo(String text) {
    // ❌ Business logika patří do features/todo_list/!
    if (text.isEmpty) { /* validation */ }
    final todo = Todo(text: text);
    await _repository.insert(todo);
  }
}

// ✅ SPRÁVNĚ - business logika v feature
// features/todo_list/presentation/bloc/todo_list_bloc.dart
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  // ✅ Business logika zde!
}

// ❌ ŠPATNĚ - feature-specific widget v core/
// core/widgets/todo_card.dart
class TodoCard extends StatelessWidget {
  // ❌ Používá se jen v todo_list feature!
  // Patří do features/todo_list/presentation/widgets/
}

// ✅ SPRÁVNĚ - generic widget v core/
// core/widgets/card_container.dart
class CardContainer extends StatelessWidget {
  // ✅ Generic container použitelný v jakékoliv feature
  final Widget child;
  final Color borderColor;
  final VoidCallback? onTap;
}
```

---

## 💉 DEPENDENCY INJECTION

### 🎯 Tři přístupy v Flutter

#### 1️⃣ **get_it (Service Locator)**

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // ✅ Singleton - jedna instance pro celou app
  getIt.registerLazySingleton<DatabaseService>(
    () => DatabaseService(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: 'https://api.example.com'),
  );

  // ✅ Factory - nový instance při každém použití
  getIt.registerFactory<TodoRepository>(
    () => TodoRepositoryImpl(getIt<DatabaseService>()),
  );

  getIt.registerFactory<TagRepository>(
    () => TagRepositoryImpl(getIt<DatabaseService>()),
  );

  // ✅ BLoC factory (nebo použij flutter_bloc)
  getIt.registerFactory<TodoBloc>(
    () => TodoBloc(getIt<TodoRepository>()),
  );
}

// main.dart
void main() {
  setupDependencies();
  runApp(MyApp());
}

// Usage v widgetu
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TodoBloc>()..add(LoadTodos()),
      child: TodoListView(),
    );
  }
}
```

**Výhody:**
- ✅ Jednoduchý, jasný
- ✅ Centrální místo pro registraci
- ✅ Testování - snadno swap implementace

**Nevýhody:**
- ❌ Runtime errors (ne compile-time safe)
- ❌ Service Locator anti-pattern (někteří považují za smell)

#### 2️⃣ **Provider / RepositoryProvider (z flutter_bloc)**

```dart
// lib/app.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ Provide dependencies na top-level
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        RepositoryProvider<TodoRepository>(
          create: (context) => TodoRepositoryImpl(
            context.read<DatabaseService>(),
          ),
        ),
        RepositoryProvider<TagRepository>(
          create: (context) => TagRepositoryImpl(
            context.read<DatabaseService>(),
          ),
        ),
      ],
      child: MaterialApp(
        home: TodoPage(),
      ),
    );
  }
}

// Usage v widgetu
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // ✅ Read dependency z context
      create: (context) => TodoBloc(
        context.read<TodoRepository>(),
      )..add(LoadTodos()),
      child: TodoListView(),
    );
  }
}
```

**Výhody:**
- ✅ Compile-time safe
- ✅ Flutter-native (část flutter_bloc)
- ✅ Context-aware

**Nevýhody:**
- ❌ Verbose (hodně boilerplate)
- ❌ Potřebuješ BuildContext

#### 3️⃣ **Riverpod (moderní řešení)**

```dart
// lib/core/di/providers.dart
import 'package:riverpod/riverpod.dart';

// ✅ Provider definice
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return TodoRepositoryImpl(db);
});

final todoBlocProvider = Provider.autoDispose<TodoBloc>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return TodoBloc(repo)..add(LoadTodos());
});

// main.dart
void main() {
  runApp(
    ProviderScope(  // ✅ Root provider scope
      child: MyApp(),
    ),
  );
}

// Usage v widgetu
class TodoPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Watch provider
    final bloc = ref.watch(todoBlocProvider);

    return Scaffold(
      body: /* ... */,
    );
  }
}
```

**Výhody:**
- ✅ Compile-time safe
- ✅ Auto-dispose
- ✅ Built-in caching
- ✅ Testovatelné (override providers v testech)

**Nevýhody:**
- ❌ Učící křivka (nový koncept)
- ❌ Breaking changes mezi verzemi (historically)

### 🎯 Doporučení - Co použít?

| Projekt | Doporučení |
|---------|------------|
| **Malý** (< 5 features) | **Provider** (z flutter_bloc) - jednoduché, built-in |
| **Střední** (5-20 features) | **get_it** - centrální DI, dobrá kontrola |
| **Velký** (20+ features) | **Riverpod** - škálovatelné, moderní, compile-safe |
| **Legacy migration** | **get_it** - snadná migrace z non-DI kódu |

---

## 🚀 POSTUP PŘI VÝSTAVBĚ OD NULY

### Fáze 1: **Setup projektu** (30 min)

```bash
# 1. Vytvoř Flutter projekt
flutter create todo_app
cd todo_app

# 2. Přidej dependencies
flutter pub add flutter_bloc
flutter pub add equatable
flutter pub add get_it
flutter pub add sqflite
flutter pub add go_router

flutter pub add --dev bloc_test
flutter pub add --dev mocktail

# 3. Vytvoř základní strukturu
mkdir -p lib/core/{theme,widgets,services,di,utils}
mkdir -p lib/features

# 4. Initial commit
git init
git add .
git commit -m "🎉 init: Flutter projekt s BLoC architekturou"
```

### Fáze 2: **Core Infrastructure** (1-2 hodiny)

```bash
# 1. Vytvoř theme
touch lib/core/theme/app_theme.dart

# 2. Vytvoř database service
touch lib/core/services/database_service.dart

# 3. Vytvoř DI setup
touch lib/core/di/injection.dart

# 4. Commit
git add lib/core/
git commit -m "🔧 config: Core infrastructure (theme, DB, DI)"
```

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    );
  }
}

// lib/core/services/database_service.dart
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'app.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Vytvoř tabulky
  }
}

// lib/core/di/injection.dart
final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => DatabaseService());
}

// lib/main.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MyApp());
}
```

### Fáze 3: **První feature** (2-3 hodiny)

```bash
# 1. Vytvoř todo_list feature (podle kroků v sekci "Jak přidávat features")
mkdir -p lib/features/todo_list/{presentation/bloc,data/repositories,domain}

# 2. Implementuj (viz sekce "Jak přidávat features" výše)

# 3. Commit
git add lib/features/todo_list/
git commit -m "✨ feat: Todo List feature s BLoC"
```

### Fáze 4: **Iterativní růst** (ongoing)

```bash
# Přidávej features postupně (YAGNI!)
# 1. AI Motivation
# 2. Tag System
# 3. Settings
# ...každou samostatně s atomic commits
```

---

## ⚠️ ČASTÉ CHYBY A JAK SE JIM VYHNOUT

### ❌ **Chyba 1: God BLoC**

```dart
// ❌ ŠPATNĚ - jeden BLoC pro všechno
class AppBloc extends Bloc<AppEvent, AppState> {
  on<LoadTodos>(...);
  on<AddTodo>(...);
  on<LoadTags>(...);      // ❌ Jiná feature!
  on<GetMotivation>(...);  // ❌ Jiná feature!
  on<UpdateSettings>(...); // ❌ Jiná feature!
}

// ✅ SPRÁVNĚ - každá feature má vlastní BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> { /* ... */ }
class TagBloc extends Bloc<TagEvent, TagState> { /* ... */ }
class MotivationCubit extends Cubit<MotivationState> { /* ... */ }
class SettingsCubit extends Cubit<SettingsState> { /* ... */ }
```

### ❌ **Chyba 2: Business logika v widgetu**

```dart
// ❌ ŠPATNĚ
class TodoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        // ❌ Business logika v UI!
        final db = DatabaseService();
        await db.update('todos', {...});
        setState(() { /* ... */ });
      },
      child: /* ... */,
    );
  }
}

// ✅ SPRÁVNĚ
class TodoCard extends StatelessWidget {
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,  // ✅ Callback - logika v BLoC
      child: /* ... */,
    );
  }
}

// Usage
TodoCard(
  onTap: () => context.read<TodoBloc>().add(ToggleTodo(todo.id)),
)
```

### ❌ **Chyba 3: Zbytečné rebuildy**

```dart
// ❌ ŠPATNĚ - rebuild při každé změně
class TodoCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        return Text('Count: ${state.todos.length}');
      },
    );
  }
}

// ✅ SPRÁVNĚ - rebuild jen když count změní
class TodoCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.select<TodoBloc, int>(
      (bloc) => bloc.state.todos.length,
    );
    return Text('Count: $count');
  }
}
```

### ❌ **Chyba 4: Zapomenuté close() / dispose()**

```dart
// ❌ ŠPATNĚ - memory leak
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final TodoBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TodoBloc(repository);
  }

  // ❌ Zapomněl dispose!
}

// ✅ SPRÁVNĚ
class _MyWidgetState extends State<MyWidget> {
  late final TodoBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TodoBloc(repository);
  }

  @override
  void dispose() {
    _bloc.close();  // ✅ Clean up!
    super.dispose();
  }
}

// ✅ NEBO použij BlocProvider (auto-dispose)
BlocProvider(
  create: (_) => TodoBloc(repository),  // Auto-dispose!
  child: /* ... */,
)
```

### ❌ **Chyba 5: Mutable state**

```dart
// ❌ ŠPATNĚ - mutable state
class TodoState {
  List<Todo> todos = [];  // ❌ Mutable!

  void addTodo(Todo todo) {
    todos.add(todo);  // ❌ Direct mutation!
  }
}

// ✅ SPRÁVNĚ - immutable state
class TodoState {
  final List<Todo> todos;  // ✅ Final!

  const TodoState({required this.todos});

  TodoState copyWith({List<Todo>? todos}) {
    return TodoState(
      todos: todos ?? this.todos,  // ✅ New instance!
    );
  }
}

// BLoC emits new state
emit(state.copyWith(
  todos: [...state.todos, newTodo],  // ✅ Nový list!
));
```

---

## 🎯 CHECKLIST: Jsem na správné cestě?

### ✅ Feature Structure

```
[ ] Každá feature má vlastní složku v lib/features/
[ ] Presentation layer obsahuje BLoC/Cubit (ne business logiku v widgetu)
[ ] Data layer má Repository implementation
[ ] Domain layer má čistou Dart logiku (ne Flutter dependencies)
[ ] Feature-specific widgety jsou v features/{name}/presentation/widgets/
[ ] Shared widgety (3+ uses) jsou v core/widgets/
```

### ✅ BLoC Pattern

```
[ ] Events jsou sealed classes
[ ] States jsou sealed classes s Equatable
[ ] BLoC event handlers jsou private (_onEventName)
[ ] Všechny async operace mají try-catch
[ ] State je immutable (final fields, copyWith)
[ ] BLoC neobsahuje Flutter dependencies (BuildContext, Navigator, atd.)
```

### ✅ Code Quality

```
[ ] Žádná business logika v widgetech
[ ] Validace na začátku (Fail Fast)
[ ] Const constructors kde možné
[ ] Keys na ListView items
[ ] buildWhen / listenWhen pro optimalizaci
[ ] Equatable na states (prevent unnecessary rebuilds)
```

### ✅ Architecture

```
[ ] Features neimportují jiné features
[ ] Core obsahuje jen technické věci (ne business logiku)
[ ] Rule of Three dodržováno (duplicita -> abstrakce až na 3. použití)
[ ] YAGNI - neimplementuju "pro budoucnost"
[ ] SRP - každá třída/widget/BLoC má jednu zodpovědnost
```

### ✅ Testing

```
[ ] BLoC má unit testy (bloc_test)
[ ] Critical widgety mají widget testy
[ ] Critical user flows mají integration testy
[ ] Testy používají mocks (mocktail)
```

### ✅ Git

```
[ ] Atomic commits (1 commit = 1 feature/fix)
[ ] Commit messages s emoji (✨ feat, 🐛 fix, ♻️ refactor)
[ ] Snapshot commit před risky refactoring
```

---

## 📚 DOPORUČENÁ ČETBA PRO HLUBŠÍ POCHOPENÍ

### 📖 BLoC Pattern

1. **Official BLoC Documentation**
   - https://bloclibrary.dev/
   - Kompletní guide, best practices, tutorials

2. **Felix Angelov (BLoC author) - YouTube**
   - https://www.youtube.com/@FelixAngelov
   - Video tutoriály přímo od autora knihovny

3. **Reso Coder - Flutter BLoC Course**
   - https://resocoder.com/flutter-clean-architecture-tdd/
   - Clean Architecture s BLoC

### 📖 Feature-First Architecture

1. **Andrea Bizzotto - Flutter Project Structure**
   - https://codewithandrea.com/articles/flutter-project-structure/
   - Feature-First best practices

2. **Very Good Ventures - Architecture Guide**
   - https://verygood.ventures/blog/very-good-flutter-architecture
   - Production-ready architecture

### 📖 Testing

1. **Official Flutter Testing**
   - https://docs.flutter.dev/testing
   - Unit, widget, integration testing

2. **bloc_test Package**
   - https://pub.dev/packages/bloc_test
   - BLoC testing utilities

### 📖 SOLID Principles

1. **Uncle Bob - Clean Architecture**
   - Kniha: "Clean Architecture: A Craftsman's Guide"
   - SOLID principy v depth

2. **Reso Coder - SOLID in Flutter**
   - https://resocoder.com/category/flutter/
   - SOLID aplikované na Flutter

---

## 🎓 ZÁVĚREČNÉ PRINCIPY

### 🎯 Klíčové myšlenky - zapamatuj si

1. **Feature-First**
   - Organizuj kód podle business funkcí, ne podle technických vrstev
   - Každá feature = izolovaná, testovatelná jednotka

2. **BLoC = Business Logic Component**
   - Separace UI ↔️ Logika ↔️ Data
   - Events in, States out
   - Immutable, testovatelné

3. **SOLID Principles**
   - SRP: 1 třída = 1 zodpovědnost
   - OCP: Rozšiřuj kompozicí, ne modifikací
   - LSP: Respektuj kontrakty
   - ISP: Malá, fokusovaná rozhraní
   - DIP: Závisej na abstrakcích

4. **YAGNI > Premature Optimization**
   - Implementuj JEN co potřebuješ TEĎ
   - Rule of Three: abstrahi až na 3. duplikaci
   - Duplicita je levnější než špatná abstrakce

5. **Fail Fast**
   - Validuj na začátku
   - Crash explicitly, ne tiše failovat
   - Assert pro dev errors, Exception pro user errors

6. **Widget Composition**
   - Malé, reusable widgety
   - Atomic Design: Atoms → Molecules → Organisms → Templates
   - Callback pattern pro oddělení logiky

7. **Performance**
   - Const constructors
   - buildWhen / listenWhen
   - Equatable na states
   - Keys na ListView

8. **Testing**
   - Unit test BLoC logiku
   - Widget test UI s mock BLoC
   - Integration test critical flows

### 🚀 Začni jednoduše, růsti postupně

```
Fáze 1: Core + První feature (todo_list)
  ↓
Fáze 2: Druhá feature (ai_motivation)
  ↓
Fáze 3: Třetí feature (tag_system)
  ↓
Fáze 4: Refaktoruj duplicity (Rule of Three)
  ↓
Fáze 5: Pokračuj iterativně...
```

**Zlaté pravidlo:**
> "Make it work, make it right, make it fast."
>
> 1. Fungující feature (rychlý prototype)
> 2. Refaktoruj (clean code, SOLID)
> 3. Optimalizuj (performance, jen když potřeba)

**A hlavně:**
> **VŽDY se vrať k [mapa-bloc.md](mapa-bloc.md) když nevíš co dělat!**

---

## 🎉 KONEC

Tato dokumentace je **living document** - evoluu s projektem.

**Feedback:**
- 💬 Něco není jasné? Přidej příklad do příslušné sekce.
- 💬 Našel jsi lepší pattern? Update dokumentaci.
- 💬 Chybí scénář? Přidej do [mapa-bloc.md](mapa-bloc.md).

**Good luck & happy coding!** 🚀

---

📅 **Metadata:**
- Vytvořeno: 2025-10-09
- Autor: Claude Code (AI asistent)
- Účel: BLoC & Feature-First guide pro Flutter projekty
- Verze: 1.0
