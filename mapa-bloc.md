# 🗺️ BLOC NAVIGATION MAP - Decision Tree pro AI Agenty

> **Účel**: Navigační mapa pro AI agenty při práci s BLoC architekturou ve Flutter.
> **Kdy použít**: Vždy když dostaneš úkol - **ZAČNI TADY**, najdi svůj scénář v Quick Reference.

---

## ⚡ QUICK REFERENCE - Najdi svůj úkol a klikni

| 🎯 Typ úkolu | 📖 Kam jít | ⏱️ Čas |
|--------------|------------|--------|
| **➕ Přidat novou feature** | [SCÉNÁŘ 1](#-scénář-1-přidej-novou-feature) | 2 min čtení |
| **🔧 Upravit existující feature** | [SCÉNÁŘ 2](#-scénář-2-uprav-existující-feature) | 1 min čtení |
| **🐛 Opravit bug** | [SCÉNÁŘ 2: Bug fix](#-oprava-bugu) | 30 sec čtení |
| **♻️ Refaktorovat kód** | [SCÉNÁŘ 2: Refaktoring](#️-refaktoring--optimalizace) | 1 min čtení |
| **📣 Features potřebují komunikovat** | [SCÉNÁŘ 3](#-scénář-3-komunikace-mezi-features) | 1 min čtení |
| **🎨 Přidat shared widget** | [SCÉNÁŘ 4](#-scénář-4-přidej-shared-widget) | 1 min čtení |
| **📊 State management pattern** | [SCÉNÁŘ 5](#-scénář-5-state-management-patterns) | 30 sec čtení |
| **⚡ Performance optimization** | [SCÉNÁŘ 6](#-scénář-6-performance-optimization) | 1 min čtení |

### 🚨 CRITICAL RULES - Přečti si VŽDY před začátkem:

| ❌ ZAKÁZÁNO | ✅ MÍSTO TOHO |
|-------------|--------------|
| Business logika v widgetech | Logika v BLoC/Cubit ([bloc.md#bloc-anatomy](bloc.md#-bloc-anatomy---events-states-handlers)) |
| `features.other_feature import ...` | BlocListener nebo Event Bus ([SCÉNÁŘ 3](#-scénář-3-komunikace-mezi-features)) |
| Duplicita → okamžitě abstrahi | Rule of Three: abstrahi až na 3. použití ([bloc.md#yagni](bloc.md#-yagni---you-arent-gonna-need-it)) |
| "Možná budeme potřebovat..." | YAGNI: implementuj až když potřebuješ ([bloc.md#yagni](bloc.md#-yagni---you-arent-gonna-need-it)) |
| Mutable state | Immutable state s copyWith ([bloc.md#bloc-anatomy](bloc.md#-bloc-anatomy---events-states-handlers)) |

### 📋 Quick Checklist - Před začátkem práce:

```
[ ] Našel jsem svůj scénář v Quick Reference výše
[ ] Klikl jsem na odkaz a přečetl relevantní sekci
[ ] Snapshot commit: git commit -m "🔖 snapshot: Před {co děláš}"
[ ] Použil jsem ultrathink pro critical changes (přidání/odstranění funkce)
[ ] Vytvořil jsem TODO list (TodoWrite) pokud 3+ kroky
```

### 🎯 Zlaté pravidlo:

> **"Quick Reference → Najdi scénář → Klikni → Čti bloc.md → Aplikuj"**

---

## 🎯 JAK TENTO DOKUMENT POUŽÍVAT

**Pro AI agenty (Claude Code, Cursor, atd.):**

1. **⚡ Začni Quick Reference** - najdi typ úkolu (výše ↑)
2. **🔍 Klikni na scénář** - přejdi na detailní decision tree
3. **📚 Klikni na odkaz do bloc.md** - prostuduj best practices
4. **✅ Aplikuj postup** - dodržuj principy
5. **🔄 Commit změny** - atomické commity (CLAUDE.md)

**Důležité:**
- ❌ **NIKDY nezačínej kódovat bez čtení relevantní sekce**
- ✅ **VŽDY použij ultrathink pro critical changes**
- ✅ **VŽDY dodržuj principy: SOLID, YAGNI, DRY, Fail Fast**

---

## 🚦 DECISION TREE - Jaký je můj úkol?

### 📌 SCÉNÁŘ 1: "Přidej novou feature"

**Otázka:** Jde o NOVOU business funkci nebo ROZŠÍŘENÍ existující?

#### ✅ **NOVÁ business funkce** → Vytvoř novou feature

**Kdy?**
- ✅ Jiný business proces (Todo List vs AI Motivation vs Tag Manager)
- ✅ Má vlastní BLoC/Cubit
- ✅ Dá se vypnout samostatně (feature flag)
- ✅ Má vlastní UI (alespoň 1 page/dialog)
- ✅ Má vlastní lifecycle

**Co prostudovat:**
1. 📖 **[🔧 Jak přidávat features](bloc.md#-jak-správně-přidávat-features)** - kompletní step-by-step (9 kroků)
2. 📖 **[🏗️ Anatomie jedné Feature](bloc.md#️-anatomie-jedné-feature)** - minimální vs plná struktura
3. 📖 **[🎨 BLoC Anatomy](bloc.md#-bloc-anatomy---events-states-handlers)** - Events, States, Handlers
4. 📖 **[🚫 YAGNI](bloc.md#-yagni---you-arent-gonna-need-it)** - nepřidávej "pro budoucnost"
5. 📖 **[🧱 SOLID Principles](bloc.md#-solid-principles-v-flutterbloc)** - SRP: 1 feature = 1 business funkce

**Checklist před začátkem:**
- [ ] Prostudoval jsem sekci "Jak přidávat features"
- [ ] Identifikoval jsem business funkci (ne technické řešení!)
- [ ] Zkontroloval jsem že feature už neexistuje
- [ ] Vytvořil jsem TODO list s 9 kroky (TodoWrite)
- [ ] Připravil jsem commit message (emoji + popis)

**Postup:**
```bash
# 1. Vytvoř strukturu složek
mkdir -p lib/features/{nazev_business_funkce}/{presentation/bloc,data/repositories,domain}

# 2. Implementuj Domain layer (entities, repository interface)
# 3. Implementuj Data layer (repository impl, DTOs)
# 4. Implementuj Presentation layer (BLoC: events, states, handlers)
# 5. Implementuj UI (pages, widgets)
# 6. Registruj DI (get_it / RepositoryProvider)
# 7. Přidej routing (GoRouter / Navigator)
# 8. Testuj (unit + widget tests)
# 9. Commit: git commit -m "✨ feat: {nazev_business_funkce}"
```

**Příklad:**
```
✅ Uživatel chce "spravovat vlastní tagy"
→ Feature: tag_management
→ BLoC: TagBloc (events: LoadTags, AddTag, DeleteTag)
→ UI: TagManagementPage

❌ "Přidat tag repository"
→ To je technické řešení, ne business funkce!
```

---

#### ⚠️ **ROZŠÍŘENÍ existující feature** → Extension existující

**Kdy?**
- ✅ Stejný business proces, nová implementace (offline vs online sync)
- ✅ Stejná funkce, nový parametr (filter, sort)
- ✅ Alternative approach pro stejný problém

**Co prostudovat:**
1. 📖 **[🔧 Jak přidávat features: Krok 4-5](bloc.md#-jak-správně-přidávat-features)** - upravit existující BLoC
2. 📖 **[🧱 SOLID: OCP](bloc.md#-solid-principles-v-flutterbloc)** - Open/Closed Principle
3. 📖 **[⚡ Fail Fast](bloc.md#-fail-fast---validation)** - validace nových parametrů

**Postup:**
```dart
// 1. Přidej nový Event
sealed class TodoListEvent {}
final class FilterTodos extends TodoListEvent {  // ✅ Nový event
  final TodoFilter filter;
  FilterTodos(this.filter);
}

// 2. Uprav State (pokud potřeba)
final class TodoListLoaded extends TodoListState {
  final List<Todo> todos;
  final TodoFilter filter;  // ✅ Nový parametr

  const TodoListLoaded({required this.todos, this.filter = TodoFilter.all});

  @override
  List<Object?> get props => [todos, filter];  // ✅ Update props
}

// 3. Přidej event handler do BLoC
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  TodoListBloc(repo) : super(TodoListInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<FilterTodos>(_onFilterTodos);  // ✅ Nový handler
  }

  void _onFilterTodos(FilterTodos event, Emitter emit) {
    if (state is TodoListLoaded) {
      final current = state as TodoListLoaded;
      emit(current.copyWith(filter: event.filter));  // ✅ Preserve state
    }
  }
}

// 4. Commit
git commit -m "✨ feat: Přidání filtru do Todo List"
```

---

### 📌 SCÉNÁŘ 2: "Uprav existující feature"

**Otázka:** Co přesně měním?

#### 🔧 **Změna business logiky**

**Co prostudovat:**
1. 📖 **[⚡ Fail Fast](bloc.md#-fail-fast---validation)** - validace na začátku, early returns
2. 📖 **[🧱 SOLID: OCP](bloc.md#-solid-principles-v-flutterbloc)** - Open/Closed Principle
3. 📖 **[🎨 BLoC Anatomy](bloc.md#-bloc-anatomy---events-states-handlers)** - jak správně upravit handler

**Checklist:**
- [ ] 🔖 Snapshot commit PŘED změnou: `git commit -m "🔖 snapshot: Před úpravou {feature}"`
- [ ] 🧠 Použil jsem ultrathink pro analýzu dopadu?
- [ ] ✅ Přidal jsem Fail Fast validaci pokud potřeba
- [ ] ✅ State zůstává immutable (copyWith, ne direct mutation)
- [ ] ✅ Testy prošly po změně
- [ ] 🔖 Commit: `git commit -m "♻️ refactor: {popis změny}"`

**Postup:**
```dart
// ❌ PŘED - bez validace
Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
  final todo = Todo(text: event.text);
  await _repository.insert(todo);
  // ...
}

// ✅ PO - s Fail Fast validací
Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
  // ✅ Fail Fast validace na začátku
  if (event.text.trim().isEmpty) {
    emit(const TodoListError('Text nesmí být prázdný'));
    return;  // Early return
  }

  if (event.text.length > 500) {
    emit(const TodoListError('Text je příliš dlouhý'));
    return;
  }

  // Business logika
  final todo = Todo(text: event.text.trim());
  await _repository.insert(todo);
  // ...
}
```

---

#### 🐛 **Oprava bugu**

**Co prostudovat:**
1. 📖 **[⚡ Fail Fast](bloc.md#-fail-fast---validation)** - reject bad inputs early
2. 📖 **[🧪 Testing BLoC](bloc.md#-testing-bloc)** - přidej regression test

**Postup:**
```bash
# 1. Snapshot před opravou
git commit -m "🔖 snapshot: Před opravou bugu v {feature}"

# 2. Identifikuj root cause
# - Chybí validace?
# - Chybí null check?
# - Wrong state transition?

# 3. Oprav
# - Přidej Fail Fast validaci pokud chyběla
# - Přidej null safety
# - Fix state logic

# 4. Přidej test který chrání před regresí
blocTest<TodoBloc, TodoState>(
  'should not add empty todo',
  build: () => bloc,
  act: (bloc) => bloc.add(AddTodo(text: '')),
  expect: () => [isA<TodoError>()],
);

# 5. Commit
git commit -m "🐛 fix: {popis bugu} v {feature}"
```

---

#### ♻️ **Refaktoring / optimalizace**

**Co prostudovat:**
1. 📖 **[🔄 Build Optimization](bloc.md#-build-optimization---performance)** - const, buildWhen, Equatable
2. 📖 **[🚫 YAGNI: Rule of Three](bloc.md#-yagni---you-arent-gonna-need-it)** - kdy abstraovat
3. 📖 **[⚖️ Widget Composition](bloc.md#️-widget-composition---high-cohesion-low-coupling)** - jak rozdělit velké widgety

**Checklist:**
- [ ] 🔖 Snapshot commit před refaktoringem
- [ ] 🧠 Použil jsem ultrathink - je to skutečně potřeba?
- [ ] ✅ Refaktoring nezměnil chování (testy prošly)
- [ ] 📝 Rule of Three: Je to 3. duplikace? Pokud ne, nech to tak!
- [ ] 🔖 Commit: `git commit -m "♻️ refactor: {důvod refaktoringu}"`

**Decision matrix:**
| Problém | Řešení |
|---------|--------|
| **God Widget (500+ řádků)** | Rozděl na menší widgety (Atomic Design) |
| **Duplicitní widget ve 2 features** | ❌ NIC - duplicita je OK! |
| **Duplicitní widget ve 3+ features** | ✅ Přesuň do core/widgets/ |
| **Zbytečné rebuildy** | Použij const, buildWhen, BlocSelector |
| **Slow list rendering** | Přidej Keys, použij ListView.builder |

---

### 📌 SCÉNÁŘ 3: "Komunikace mezi features"

**Otázka:** Potřebují features A a B komunikovat?

#### ❌ **NIKDY přímé volání mezi features**

```dart
// ❌ ŠPATNĚ - cross-feature import
import '../../other_feature/presentation/bloc/other_bloc.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final OtherBloc _otherBloc;  // ❌ ZAKÁZÁNO!

  Future<void> _onAddTodo(AddTodo event, Emitter emit) async {
    // ...
    _otherBloc.add(SomeEvent());  // ❌ ZAKÁZÁNO!
  }
}
```

#### ✅ **Komunikace přes BlocListener**

**Co prostudovat:**
1. 📖 **[🔄 BLoC Communication](bloc.md#-bloc-communication---feature-to-feature)** - 3 způsoby komunikace
2. 📖 **[🧱 SOLID: DIP](bloc.md#-solid-principles-v-flutterbloc)** - Dependency Inversion

**Způsob 1: BlocListener (nejjednodušší)**

```dart
// ✅ SPRÁVNĚ - TodoBloc emituje state, jiná feature poslouchá
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => TodoBloc(repo)),
        BlocProvider(create: (_) => MotivationCubit(aiRepo)),
      ],
      child: MultiBlocListener(
        listeners: [
          // ✅ Poslouchej TodoBloc state changes
          BlocListener<TodoBloc, TodoState>(
            listenWhen: (prev, curr) {
              // Reaguj jen když přidán nový todo
              if (prev is TodoLoaded && curr is TodoLoaded) {
                return curr.todos.length > prev.todos.length;
              }
              return false;
            },
            listener: (context, state) {
              // ✅ TodoBloc changed → MotivationCubit reaguje
              if (state is TodoLoaded && state.todos.isNotEmpty) {
                context.read<MotivationCubit>().celebrate(state.todos.last);
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

**Způsob 2: Stream Subscription (BLoC-to-BLoC)**

```dart
// ✅ MotivationCubit subscribuje na TodoBloc stream
class MotivationCubit extends Cubit<MotivationState> {
  final TodoBloc _todoBloc;
  StreamSubscription? _subscription;

  MotivationCubit(this._todoBloc) : super(MotivationInitial()) {
    // ✅ Subscribe na TodoBloc stream
    _subscription = _todoBloc.stream.listen((todoState) {
      if (todoState is TodoLoaded) {
        _onTodosChanged(todoState.todos);
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();  // ✅ Cleanup!
    return super.close();
  }
}
```

**Způsob 3: Event Bus (komplexní komunikace)**

```dart
// Viz bloc.md#bloc-communication pro kompletní implementaci
// ⚠️ YAGNI - použij jen když skutečně potřebuješ!
```

**Kdy použít co:**
| Způsob | Kdy použít | Složitost |
|--------|-----------|-----------|
| **BlocListener** | Jednoduchá reakce v UI | ⭐ Nízká (doporučeno) |
| **Stream Subscription** | BLoC-to-BLoC komunikace | ⭐⭐ Střední |
| **Event Bus** | 5+ features komunikující | ⭐⭐⭐ Vysoká (YAGNI!) |

---

### 📌 SCÉNÁŘ 4: "Přidej shared widget"

**Otázka:** Patří to do `core/widgets/` nebo do feature?

#### 🤔 **Decision Tree**

```
Je widget používán ve 3+ features?
│
├─ ANO → ✅ Přesuň do core/widgets/
│         (Rule of Three)
│
└─ NE  → Je widget používán ve 2 features?
          │
          ├─ ANO → ❌ NIC - duplicita je levnější než špatná abstrakce!
          │
          └─ NE  → ✅ Zůstává v features/{name}/presentation/widgets/
```

#### ✅ **Widget do core/widgets/** (použitý 3+ krát)

**Co prostudovat:**
1. 📖 **[⚖️ Widget Composition](bloc.md#️-widget-composition---high-cohesion-low-coupling)** - High Cohesion, Low Coupling
2. 📖 **[🚫 YAGNI: Rule of Three](bloc.md#-yagni---you-arent-gonna-need-it)** - kdy abstraovat
3. 📖 **[🔄 Build Optimization](bloc.md#-build-optimization---performance)** - const constructors

**Pravidla pro core/widgets/:**
- ✅ Žádná business logika
- ✅ Žádné BLoC dependencies
- ✅ Pure presentational component
- ✅ Const constructor kde možné
- ✅ Callback pattern pro akce

**Příklad:**
```dart
// ✅ SPRÁVNĚ - generic widget v core/widgets/
// lib/core/widgets/tag_chip.dart
class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onDelete;

  const TagChip({
    required this.label,
    required this.color,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

// Usage v jakékoliv feature
TagChip(
  label: 'work',
  color: Colors.blue,
  onDelete: () => context.read<TodoBloc>().add(RemoveTag('work')),
)
```

#### ❌ **Widget v features/{name}/presentation/widgets/** (feature-specific)

```dart
// ❌ NE do core/ - obsahuje business logiku specifickou pro Todo
// lib/features/todo_list/presentation/widgets/todo_card.dart
class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  // ❌ Specifická business logika (priority colors, completion logic)
  // → Zůstává ve features/todo_list/presentation/widgets/
}
```

---

### 📌 SCÉNÁŘ 5: "State Management Patterns"

**Otázka:** Jaký state management pattern použít?

#### 🎯 **Decision Tree**

```
Jaká je komplexita feature?
│
├─ Jednoduchá (toggle, counter)
│  → ✅ Cubit (jednodušší než BLoC)
│
├─ Střední (async operace, CRUD)
│  → ✅ BLoC (Events + States)
│
└─ Komplexní (real-time sync, offline-first)
   → ✅ BLoC + Repository pattern + Use Cases
```

#### **Cubit vs BLoC**

**Co prostudovat:**
1. 📖 **[🎯 Co je BLoC Pattern](bloc.md#-co-je-bloc-pattern)** - Cubit vs BLoC srovnání
2. 📖 **[🏗️ Anatomie jedné Feature](bloc.md#️-anatomie-jedné-feature)** - minimální vs plná struktura

**Kdy použít Cubit:**
```dart
// ✅ Cubit - pro jednoduché state
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// ✅ Cubit - pro toggle/settings
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState());

  void toggleDarkMode() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }
}
```

**Kdy použít BLoC:**
```dart
// ✅ BLoC - pro komplexní async operace
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;

  TodoListBloc(this._repository) : super(TodoListInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<FilterTodos>(_onFilterTodos);
  }

  // Multiple event handlers, async operations, error handling
}
```

| Kritérium | Cubit | BLoC |
|-----------|-------|------|
| **Jednoduchost** | ⭐⭐⭐ Jednodušší | ⭐⭐ Více boilerplate |
| **Struktura** | Methods | Events + Handlers |
| **Tracking** | Méně explicitní | Explicit event log |
| **Kdy použít** | Toggle, Settings, Counter | CRUD, Async, Complex flows |

---

### 📌 SCÉNÁŘ 6: "Performance Optimization"

**Otázka:** Aplikace je pomalá, kde optimalizovat?

#### 🎯 **Performance Checklist**

**Co prostudovat:**
1. 📖 **[🔄 Build Optimization](bloc.md#-build-optimization---performance)** - Const, buildWhen, Keys, Equatable

**Decision Tree:**

```
Kde je problém?
│
├─ Zbytečné rebuildy
│  → ✅ Použij const constructors
│  → ✅ Použij buildWhen / listenWhen
│  → ✅ Použij BlocSelector pro konkrétní property
│  → ✅ Equatable na states
│
├─ Pomalé scrollování (ListView)
│  → ✅ Přidej ValueKey na items
│  → ✅ Použij ListView.builder (ne ListView)
│  → ✅ Lazy loading (pagination)
│
├─ Pomalý initial load
│  → ✅ Lazy DI (registerLazySingleton)
│  → ✅ Async initialization v initState
│  → ✅ Show loading state okamžitě
│
└─ Memory leaks
   → ✅ Dispose StreamSubscriptions
   → ✅ Close BLoCs (nebo použij BlocProvider auto-dispose)
   → ✅ Cancel timers v dispose()
```

#### ✅ **Optimalizace: Const Constructors**

```dart
// ❌ PŘED - rebuild při každém parent rebuild
class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('TODO List'),  // ❌ Nový instance při rebuildu
    );
  }
}

// ✅ PO - const = žádný rebuild
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBar(
      title: Text('TODO List'),  // ✅ Const = cached instance
    );
  }
}
```

#### ✅ **Optimalizace: buildWhen**

```dart
// ❌ PŘED - rebuild při KAŽDÉ změně state
BlocBuilder<TodoBloc, TodoState>(
  builder: (context, state) {
    return Text('Count: ${state.todos.length}');
  },
)

// ✅ PO - rebuild JEN když se změní count
BlocBuilder<TodoBloc, TodoState>(
  buildWhen: (prev, curr) {
    if (prev is TodoLoaded && curr is TodoLoaded) {
      return prev.todos.length != curr.todos.length;  // ✅ Rebuild jen když count změnil
    }
    return true;
  },
  builder: (context, state) {
    return Text('Count: ${state.todos.length}');
  },
)

// ✅ JEŠTĚ LEPŠÍ - BlocSelector
final count = context.select<TodoBloc, int>(
  (bloc) => bloc.state.todos.length,  // ✅ Select jen count
);
return Text('Count: $count');
```

#### ✅ **Optimalizace: Keys pro ListView**

```dart
// ❌ PŘED - bez keys
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) {
    return TodoCard(todo: todos[index]);  // ❌ Flutter neví který item je který
  },
)

// ✅ PO - s ValueKey
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) {
    final todo = todos[index];
    return TodoCard(
      key: ValueKey(todo.id),  // ✅ Flutter ví který item přesunout/update
      todo: todo,
    );
  },
)
```

#### ✅ **Optimalizace: Equatable**

```dart
// ❌ PŘED - bez Equatable
class TodoState {
  final List<Todo> todos;
  TodoState({required this.todos});
}

emit(TodoState(todos: [todo1, todo2]));
emit(TodoState(todos: [todo1, todo2]));  // ❌ 2 emits = 2 rebuilds (i když obsah stejný!)

// ✅ PO - s Equatable
class TodoState extends Equatable {
  final List<Todo> todos;
  const TodoState({required this.todos});

  @override
  List<Object?> get props => [todos];  // ✅ Equatable porovná obsah
}

emit(TodoState(todos: [todo1, todo2]));
emit(TodoState(todos: [todo1, todo2]));  // ✅ Druhý emit ignorován - stejný obsah!
```

---

## 🎯 RYCHLÉ REFERENCE - Nejčastější úkoly

### ➕ Přidání nové feature (step-by-step)

```bash
# 1. PROSTUDUJ
- 📖 bloc.md#jak-přidávat-features (9 kroků)
- 📖 bloc.md#anatomie-jedné-feature
- 📖 bloc.md#bloc-anatomy

# 2. SNAPSHOT
git commit -m "🔖 snapshot: Před přidáním {nova_feature}"

# 3. VYTVOŘ STRUKTURU
mkdir -p lib/features/{nova_feature}/{presentation/bloc,data/repositories,domain}

# 4. IMPLEMENTUJ
# Krok 3: Domain (entities, repository interface)
# Krok 4: Data (repository impl, DTOs)
# Krok 5: Presentation (BLoC: events, states, handlers)
# Krok 6: UI (pages, widgets)
# Krok 7: DI (get_it / RepositoryProvider)
# Krok 8: Routing
# Krok 9: Tests

# 5. COMMIT
git commit -m "✨ feat: Přidání {nova_feature}"
```

---

### 🔧 Úprava existující feature

```bash
# 1. PROSTUDUJ
- 📖 bloc.md#fail-fast (validace)
- 📖 bloc.md#solid-principles (OCP)
- 📖 bloc.md#bloc-anatomy (jak upravit handler)

# 2. SNAPSHOT
git commit -m "🔖 snapshot: Před úpravou {feature}"

# 3. ULTRATHINK (pokud critical change)
# - Analyzuj dopad změny
# - Je to skutečně potřeba? (YAGNI)

# 4. UPRAV
# - Přidej Fail Fast validaci pokud chybí
# - Zachovej immutability (copyWith)
# - Update tests

# 5. TESTY
# - Ujisti se že testy prošly

# 6. COMMIT
git commit -m "♻️ refactor: {popis} v {feature}"
```

---

### 🐛 Oprava bugu

```bash
# 1. SNAPSHOT
git commit -m "🔖 snapshot: Před opravou bugu v {feature}"

# 2. IDENTIFIKUJ
# - Kde je problém? (BLoC handler, widget, repository?)
# - Proč vznikl? (chybí validace? null safety? wrong state?)

# 3. OPRAV
# - Přidej Fail Fast validaci pokud chyběla
# - Fix state transition logic
# - Add null safety

# 4. TEST
# - Přidej regression test
blocTest<TodoBloc, TodoState>(
  'should not crash on null input',
  build: () => bloc,
  act: (bloc) => bloc.add(AddTodo(text: null)),
  expect: () => [isA<TodoError>()],
);

# 5. COMMIT
git commit -m "🐛 fix: {popis bugu} v {feature}"
```

---

### 🔄 Performance optimization

```bash
# 1. IDENTIFIKUJ problém
# - Profiler (Flutter DevTools)
# - Widget rebuilds? → const, buildWhen
# - Slow scrolling? → Keys, ListView.builder
# - Memory leak? → dispose StreamSubscriptions

# 2. PROSTUDUJ
- 📖 bloc.md#build-optimization

# 3. APLIKUJ FIX
# - Const constructors
# - buildWhen / BlocSelector
# - ValueKey na ListView items
# - Equatable na states

# 4. VERIFY
# - Performance profiler - je to lepší?
# - Testy stále prošly?

# 5. COMMIT
git commit -m "⚡ perf: Optimalizace {co} v {feature}"
```

---

## 🧭 NAVIGAČNÍ ZKRATKY - Kam jít pro konkrétní téma

### 🎯 Principy a Best Practices
| Téma | Odkaz na bloc.md |
|------|------------------|
| SOLID v Flutter/BLoC | [🧱 SOLID Principles](bloc.md#-solid-principles-v-flutterbloc) |
| Widget Composition | [⚖️ Widget Composition](bloc.md#️-widget-composition---high-cohesion-low-coupling) |
| YAGNI | [🚫 YAGNI](bloc.md#-yagni---you-arent-gonna-need-it) |
| Build Optimization | [🔄 Build Optimization](bloc.md#-build-optimization---performance) |
| Fail Fast | [⚡ Fail Fast](bloc.md#-fail-fast---validation) |

### 🏗️ BLoC Pattern
| Téma | Odkaz na bloc.md |
|------|------------------|
| Co je BLoC Pattern | [🎯 Co je BLoC](bloc.md#-co-je-bloc-pattern) |
| BLoC Anatomy | [🎨 BLoC Anatomy](bloc.md#-bloc-anatomy---events-states-handlers) |
| State Management Patterns | [📊 State Management](bloc.md#-state-management-patterns) |
| BLoC Communication | [🔄 BLoC Communication](bloc.md#-bloc-communication---feature-to-feature) |
| Testing BLoC | [🧪 Testing](bloc.md#-testing-bloc) |

### 🏗️ Struktura a Implementace
| Téma | Odkaz na bloc.md |
|------|------------------|
| Feature-First struktura | [📁 Feature-First](bloc.md#-feature-first-struktura) |
| Anatomie jedné Feature | [🏗️ Anatomie Feature](bloc.md#️-anatomie-jedné-feature) |
| Jak přidávat features | [🔧 Jak přidávat features](bloc.md#-jak-správně-přidávat-features) |
| Core Infrastructure | [🎨 Core Infrastructure](bloc.md#-core-infrastructure---co-tam-patří) |
| Dependency Injection | [💉 DI](bloc.md#-dependency-injection) |

### ⚠️ Chyby a Checklist
| Téma | Odkaz na bloc.md |
|------|------------------|
| Časté chyby | [⚠️ Časté chyby](bloc.md#️-časté-chyby-a-jak-se-jim-vyhnout) |
| Checklist správnosti | [🎯 Checklist](bloc.md#-checklist-jsem-na-správné-cestě) |

---

## 📋 CHECKLIST PRO AI AGENTY - Před začátkem kódování

### ✅ Před přidáním nové feature:
- [ ] Přečetl jsem **[bloc.md#jak-přidávat-features](bloc.md#-jak-správně-přidávat-features)** (9 kroků)
- [ ] Identifikoval jsem business funkci (ne technické řešení!)
- [ ] Zkontroloval jsem že feature už neexistuje
- [ ] Rozhodl jsem se: Cubit vs BLoC (viz **[decision tree](bloc.md#-co-je-bloc-pattern)**)
- [ ] Použil jsem **YAGNI** - feature je skutečně potřeba TEĎ?
- [ ] Vytvořil jsem TODO list s 9 kroky (TodoWrite)
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před přidáním {feature}"`

### ✅ Před refaktoringem:
- [ ] Přečetl jsem **[bloc.md#yagni](bloc.md#-yagni---you-arent-gonna-need-it)**
- [ ] Použil jsem **ultrathink** - je to skutečně potřeba?
- [ ] Zkontroloval jsem **Rule of Three** - je to 3. duplikace?
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před refaktoringem {co}"`

### ✅ Před úpravou existující feature:
- [ ] Přečetl jsem **[bloc.md#fail-fast](bloc.md#-fail-fast---validation)**
- [ ] Přečetl jsem **[bloc.md#solid-principles](bloc.md#-solid-principles-v-flutterbloc)** (OCP)
- [ ] Použil jsem **ultrathink** pro critical changes
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před úpravou {feature}"`
- [ ] Testy prošly po změně

### ✅ Po dokončení úkolu:
- [ ] Testy prošly (unit + widget)
- [ ] Dodržel jsem principy z bloc.md (SOLID, YAGNI, Fail Fast)
- [ ] State je immutable (final fields, copyWith, Equatable)
- [ ] Žádná business logika v widgetech
- [ ] Vytvořil jsem commit s emoji + popis (viz CLAUDE.md)
- [ ] Zkontroloval jsem **[bloc.md#checklist](bloc.md#-checklist-jsem-na-správné-cestě)**

---

## 🚨 CRITICAL RULES - NIKDY NEPŘEKROČ

### ❌ ZAKÁZÁNO:

1. **Business logika v widgetech**
   ```dart
   // ❌ NIKDY!
   class TodoCard extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return InkWell(
         onTap: () async {
           // ❌ Business logika v UI!
           await database.update(...);
         },
       );
     }
   }
   ```
   → Business logika patří do BLoC/Cubit!

2. **Cross-feature imports**
   ```dart
   // ❌ NIKDY!
   import '../../other_feature/presentation/bloc/other_bloc.dart';
   ```
   → Použij BlocListener nebo Event Bus

3. **Mutable state**
   ```dart
   // ❌ NIKDY!
   class TodoState {
     List<Todo> todos = [];  // Mutable!
     void addTodo(Todo t) => todos.add(t);  // Direct mutation!
   }
   ```
   → State musí být immutable (final + copyWith)

4. **Zapomenuté dispose**
   ```dart
   // ❌ NIKDY!
   class _MyState extends State<MyWidget> {
     late final StreamSubscription _sub;
     // ❌ Zapomněl dispose → memory leak!
   }
   ```
   → Vždy dispose StreamSubscriptions, BLoCs, Controllers

5. **Spekulativní features (YAGNI violation)**
   ```dart
   // ❌ NIKDY!
   features/blockchain_integration/  // "Možná budeme potřebovat"
   ```
   → Implementuj POUZE když skutečně potřebuješ TEĎ

6. **Kódování bez studia bloc.md**
   ```dart
   // ❌ NIKDY!
   // Začít kódovat bez přečtení relevantní sekce
   ```
   → VŽDY nejprve prostuduj odpovídající sekci v bloc.md

---

## 💡 PRO-TIPY pro AI agenty

### 🧠 Ultrathink Usage

**Kdy použít ultrathink:**
- ✅ **Odstranění funkce** - analýza dopadu, dependencies, rizika
- ✅ **Přidání komplexní feature** - hodnocení nutnosti, alternativy (Cubit vs BLoC?)
- ✅ **Refaktoring** - je to skutečně potřeba? YAGNI?
- ✅ **Architektonická rozhodnutí** - Feature-First struktura, DI strategy

**Kdy NEPOUŽÍVAT ultrathink:**
- ❌ Rutinní bug fix (Fail Fast validace)
- ❌ Přidání jednoduchého event do BLoC
- ❌ Update dokumentace

### 🔖 Git Commit Strategy

**VŽDY snapshot před risky operací:**
```bash
# Před refaktoringem
git commit -m "🔖 snapshot: Před refaktoringem {feature}"

# Před odstraněním funkce
git commit -m "🔖 snapshot: Před odstraněním {feature}"

# Před velkým BLoC refactoringem
git commit -m "🔖 snapshot: Před BLoC refaktoringem v {feature}"
```

**Atomické commity:**
- ✅ 1 commit = 1 logická změna (1 feature, 1 fix, 1 refaktoring)
- ✅ Commit hned po dokončení úkolu (ne batch)
- ✅ Descriptive message (emoji + co + proč)

### 📝 TODO List Strategy

**VŽDY použij TodoWrite pro:**
- ✅ Přidání nové feature (9 kroků)
- ✅ Refaktoring komplexního BLoC
- ✅ Bug fix s multiple soubory
- ✅ Performance optimization (multiple steps)
- ✅ Vždy když uživatel poskytne seznam úkolů

**NEPOUŽÍVEJ TodoWrite pro:**
- ❌ Jednoduchá změna (1-2 kroky)
- ❌ Přidání jednoho event do BLoC
- ❌ Triviální update (text change, color update)
- ❌ Čistě konverzační dotazy

---

## 🎓 ZÁVĚR - Key Takeaways

### Pro AI agenty pracující s BLoC architekturou:

1. **📖 VŽDY začni studiem bloc.md** - najdi odpovídající sekci v tomto mapa-bloc.md
2. **🎯 Decision tree first** - identifikuj typ úkolu PŘED kódováním
3. **🧠 Ultrathink pro critical changes** - odstranění/přidání feature, architektonická rozhodnutí
4. **🔖 Snapshot commits** - před risky operací VŽDY
5. **✅ Dodržuj principy** - SOLID, YAGNI, Fail Fast, Widget Composition
6. **📝 TodoWrite pro komplexní úkoly** - organizuj práci systematicky (9 kroků pro novou feature!)
7. **❌ Business logika v widgetech = ZAKÁZÁNO** - pouze v BLoC/Cubit
8. **🔄 Immutable state** - final fields, copyWith, Equatable
9. **🚫 YAGNI** - implementuj POUZE co je potřeba TEĎ (Rule of Three!)
10. **🧪 Testy prošly** - před commitem VŽDY

### Zlaté pravidlo:

> **"Když nevíš co dělat, vrať se k mapa-bloc.md → najdi decision tree → prostuduj odpovídající sekci v bloc.md → aplikuj."**

**Tato mapa je tvůj kompas pro Flutter/BLoC projekty. Použij ji.** 🧭

---

## 📚 META - O tomto dokumentu

**Verzování:**
- 📅 Vytvořeno: 2025-10-09
- 📝 Autor: Claude Code (AI assistant)
- 🎯 Účel: Navigační mapa pro AI agenty pracující s BLoC ve Flutter

**Maintenance:**
- ✅ Aktualizuj když se mění bloc.md
- ✅ Přidávej nové workflows podle potřeby
- ✅ Udržuj odkazy na bloc.md funkční

**Feedback:**
- 💬 Pokud něco chybí, přidej nový scénář
- 💬 Pokud je něco nejasné, upřesni decision tree
- 💬 Tento dokument je **living document** - evolvuje s projektem

**Companion dokumenty:**
- 📘 **bloc.md** - Detailní BLoC best practices guide
- 🗺️ **mapa-bloc.md** - Tento soubor (navigační mapa)
- 📘 **CLAUDE.md** - Univerzální instrukce pro Claude Code
