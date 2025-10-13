# CLAUDE-bloc.md - Flutter/BLoC Project Instructions

## 🚨 PRIORITNÍ INSTRUKCE - VŽDY DODRŽUJ

### 📁 Dva klíčové soubory v tomto Flutter/BLoC projektu:

1. **[mapa-bloc.md](mapa-bloc.md)** - Decision tree pro každý typ úkolu
2. **[bloc.md](bloc.md)** - Detailní best practices pro Feature-First + BLoC architekturu

---

## ⚡ POVINNÝ WORKFLOW

### Když dostaneš JAKÝKOLIV úkol:

```
1. Otevři mapa-bloc.md
2. Najdi svůj scénář v Quick Reference (10 sekund)
3. Klikni na odkaz do bloc.md
4. Přečti relevantní sekci
5. Aplikuj postup
```

### ❌ NIKDY:
- ❌ Nezačínej kódovat bez čtení mapa-bloc.md + bloc.md
- ❌ Nehádej workflow - vždy použij decision tree z mapa-bloc.md
- ❌ Neignoruj Critical Rules z mapa-bloc.md
- ❌ Nedávej business logiku do widgetů - POUZE do BLoC/Cubit
- ❌ Neimportuj mezi features (import other_feature)
- ❌ Nevytvářej mutable state - VŽDY immutable (final + copyWith)

### ✅ VŽDY:
- ✅ mapa-bloc.md → Quick Reference → Najdi scénář
- ✅ Klikni na odkaz bloc.md → Čti best practices
- ✅ Snapshot commit před risky operací
- ✅ Ultrathink pro critical changes (přidání/odstranění feature)
- ✅ Business logika v BLoC/Cubit, UI v widgetech
- ✅ Immutable state s Equatable a copyWith
- ✅ Fail Fast validace na začátku event handlerů

---

## 🎯 Typy úkolů v mapa-bloc.md:

| Úkol | Scénář |
|------|--------|
| ➕ Přidat novou feature | SCÉNÁŘ 1 |
| 🔧 Upravit existující feature | SCÉNÁŘ 2 |
| 🐛 Opravit bug | SCÉNÁŘ 2 |
| ♻️ Refaktorovat | SCÉNÁŘ 2 |
| 📣 Features komunikace | SCÉNÁŘ 3 |
| 🎨 Shared widget | SCÉNÁŘ 4 |
| 📊 State management | SCÉNÁŘ 5 |
| ⚡ Performance | SCÉNÁŘ 6 |

---

---

## 🚨 CRITICAL RULES - NIKDY NEPŘEKROČ

### 1. ❌ Business logika v widgetech → ✅ POUZE v BLoC/Cubit

### 2. ❌ Cross-feature imports → ✅ BlocListener / Event Bus

### 3. ❌ Mutable state → ✅ Immutable (final + copyWith + Equatable)

### 4. ❌ Duplicita → okamžitě abstrahi → ✅ Rule of Three

Widget použitý ve 2 features? → ❌ NIC - duplicita je levnější než špatná abstrakce!
Widget použitý ve 3+ features? → ✅ Přesuň do core/widgets/

### 5. ❌ "Možná budeme potřebovat..." → ✅ YAGNI (implementuj až když potřebuješ)

### 6. ❌ Zapomenuté dispose → ✅ Vždy cleanup resources

---

## 📋 Checklist před KAŽDÝM úkolem:

- [ ] Otevřel jsem mapa-bloc.md
- [ ] Našel jsem scénář v Quick Reference
- [ ] Přečetl jsem relevantní sekci v bloc.md
- [ ] Snapshot commit (pokud risky operace)
- [ ] Ultrathink (pokud critical change)
- [ ] Vytvořil jsem TODO list (pokud 3+ kroky)

---

## 🎯 Flutter/BLoC Specifické Principy:

### 1️⃣ Feature-First organizace

```
lib/features/{business_funkce}/
├── presentation/          # UI layer
│   ├── bloc/             # BLoC/Cubit
│   ├── pages/            # Full page widgets
│   └── widgets/          # Feature-specific widgets
├── data/                 # Data layer
│   ├── repositories/     # Repository implementation
│   └── models/           # DTOs (Data Transfer Objects)
└── domain/               # Business logic
    ├── entities/         # Pure Dart entities
    └── repositories/     # Repository interfaces
```

### 2️⃣ BLoC Pattern - Events, States, Handlers

Sealed classes pro Events a States
Equatable pro state comparison
Immutable state s copyWith

### 3️⃣ Fail Fast - validace na začátku

Validace na začátku event handlerů
Early returns při chybě
Explicitní error states

### 4️⃣ Widget Composition - Atomic Design

Atoms → Molecules → Organisms → Pages

### 5️⃣ Performance Optimization

- Const constructors
- buildWhen / listenWhen
- BlocSelector
- ValueKey na ListView items
- Equatable na states

---

## 🔧 Přidání nové feature - 9 kroků:

1. Snapshot commit
2. Vytvoř strukturu (presentation/bloc, data, domain)
3. Domain layer (entities, repository interface)
4. Data layer (repository impl, DTOs)
5. Presentation layer (BLoC: events, states, handlers)
6. UI (pages, widgets)
7. DI (get_it / RepositoryProvider)
8. Routing (GoRouter / Navigator)
9. Tests (unit, widget)
10. Commit

Viz bloc.md#jak-přidávat-features pro detaily každého kroku!

---

## 🎓 Závěrečné principy:

### Zlaté pravidlo:
> "mapa-bloc.md → Quick Reference → Decision tree → bloc.md → Aplikuj"

### Klíčové myšlenky:

1. Feature-First + BLoC - kód organizovaný podle business funkcí
2. Immutable State - final fields, copyWith, Equatable
3. SOLID Principles - SRP, OCP, LSP, ISP, DIP
4. YAGNI > Premature Optimization - Rule of Three
5. Fail Fast - validuj na začátku event handlerů
6. Widget Composition - malé, reusable widgety
7. Performance - const, buildWhen, Keys, Equatable
8. Testing - unit test BLoC, widget test UI
9. Separation of Concerns - UI vs logika vs data
10. No Cross-Feature Imports - BlocListener

---

## 📊 Decision Matrix:

| Problém | Řešení |
|---------|--------|
| Nová business funkce | Vytvoř feature v lib/features/ |
| Jednoduchý state | Použij Cubit |
| Komplexní async | Použij BLoC (Events + States) |
| Widget ve 2 features | ❌ Nech duplicitu |
| Widget ve 3+ features | ✅ Přesuň do core/widgets/ |
| Features komunikují | BlocListener (ne direct import!) |
| Pomalé rebuildy | const, buildWhen, BlocSelector |
| Pomalý ListView | ValueKey na items |

---

## 🚨 CRITICAL REMINDER:

Když nevíš co dělat:
1. Otevři mapa-bloc.md
2. Najdi svůj scénář v Quick Reference
3. Klikni na odkaz do bloc.md
4. Přečti best practices
5. Aplikuj

Tento workflow je POVINNÝ pro všechny úkoly!

---

## ✨ AI Brief - Inteligentní filtrování úkolů

### 📋 Kompletní guide: [brief.md](brief.md)

**Funkce**: AI-powered filter v Agenda view - inteligentní prioritizace úkolů

**Kdy použít**: Implementace nové feature `lib/features/ai_brief/` + integrace do TodoListPage

**DŮLEŽITÉ**: Brief NENÍ samostatná stránka! Je to **nový tab v Agenda views** (All, Today, Week, Overdue, **Brief**)

### 🎯 Koncept

User klikne "Brief" tab → AI filtruje úkoly do sekcí:
- 🎯 **FOCUS NOW** (top 3 úkoly)
- 📊 **KEY INSIGHTS** (dependencies, quick wins)
- 💪 **MOTIVATION** (progress, encouragement)

**Klíčové**: Zobrazí se **real TodoCards** (ne clickable linky!), user může hned pracovat (done, edit, pomodoro)

### 📐 Architektura

```
lib/features/ai_brief/
├── presentation/
│   ├── widgets/
│   │   ├── brief_section_header.dart      # AI komentář nad sekcí
│   │   ├── brief_loading_indicator.dart   # Loading state
│   │   └── brief_error_widget.dart        # Error state
│   └── bloc/
│       ├── ai_brief_bloc.dart
│       ├── ai_brief_event.dart
│       └── ai_brief_state.dart
├── domain/
│   ├── entities/
│   │   ├── brief_config.dart              # Settings
│   │   ├── brief_response.dart            # AI response
│   │   └── brief_section.dart             # Section entity
│   └── repositories/
│       └── ai_brief_repository.dart
└── data/
    ├── datasources/
    │   ├── brief_ai_datasource.dart       # OpenRouter API
    │   └── brief_db_datasource.dart       # DB queries
    └── repositories/
        └── ai_brief_repository_impl.dart
```

**PLUS: Integrace do TodoListBloc** (ne nový BLoC!)

### 🔧 Implementační kroky (6-8h MVP)

#### **Krok 1: Snapshot commit** (5 min)

```bash
git add -A && git commit -m "🔖 snapshot: Před implementací AI Brief feature"
```

#### **Krok 2: Domain Layer** (1.5h)

Vytvoř entity v `lib/features/ai_brief/domain/entities/`:

**2.1 BriefSection** (15 min)
```dart
class BriefSection {
  final String type;        // focus_now, key_insights, motivation
  final String title;       // "🎯 FOCUS NOW"
  final String commentary;  // AI komentář
  final List<int> taskIds;  // [5, 12, 8]
}
```

**2.2 BriefResponse** (30 min)
```dart
class BriefResponse {
  final List<BriefSection> sections;
  final DateTime generatedAt;

  // Validate task IDs proti DB (catch AI hallucinations)
  Future<BriefResponse> validate(DatabaseHelper db);

  // Cache validity check (1 hour)
  bool get isCacheValid;
}
```

**2.3 BriefConfig** (15 min)
```dart
class BriefConfig {
  final bool includeSubtasks;
  final bool includePomodoroStats;
  final double temperature;
  final int maxTokens;
}
```

**2.4 Repository Interface** (30 min)
```dart
abstract class AiBriefRepository {
  Future<BriefResponse> generateBrief({
    required List<Todo> tasks,
    required BriefConfig config,
  });
}
```

#### **Krok 3: Data Layer** (2h)

**3.1 BriefAiDatasource** (1h)
```dart
class BriefAiDatasource {
  final OpenRouterClient _client;

  Future<String> generateBrief({
    required String systemPrompt,
    required String userContext,
  });
}
```

Použij **system prompt z brief.md** (řádky 177-246) - AI má vrátit JSON!

**3.2 Context Builder** (30 min)
```dart
String _buildUserContext(List<Todo> tasks) {
  // Strukturovaný seznam úkolů pro AI:
  // TASK_ID: 5
  // Text: Dokončit prezentaci
  // Priority: a (high)
  // Due Date: 2025-10-13 14:00 (in 2 hours)
  // Subtasks: 2/5 completed
  // ...
}
```

**3.3 Repository Implementation** (30 min)
```dart
class AiBriefRepositoryImpl implements AiBriefRepository {
  @override
  Future<BriefResponse> generateBrief(...) async {
    final aiResponse = await _datasource.generateBrief(...);
    final briefResponse = BriefResponse.fromJson(jsonDecode(aiResponse));
    return await briefResponse.validate(_db); // Validace task IDs
  }
}
```

#### **Krok 4: Integrace do TodoListBloc** (1h)

**4.1 Extend TodoListState** (20 min)
```dart
class TodoListState extends Equatable {
  // Existing fields...

  // NEW: AI Brief
  final ViewMode currentView;          // all, today, week, overdue, aiBrief
  final BriefResponse? aiBriefData;
  final bool isGeneratingBrief;
  final String? briefError;

  // Computed: Brief sections s real Todo objekty
  List<BriefSectionWithTodos>? get briefSections { ... }
}

enum ViewMode {
  all, today, week, overdue, aiBrief,  // NEW
}
```

**4.2 Přidej Events** (10 min)
```dart
class ChangeViewModeEvent extends TodoListEvent {
  final ViewMode mode;
}

class RegenerateBriefEvent extends TodoListEvent {}
```

**4.3 Event Handlers** (30 min)
```dart
on<ChangeViewModeEvent>((event, emit) async {
  if (event.mode == ViewMode.aiBrief) {
    // Check cache first
    if (_aiBriefCache != null && _aiBriefCache!.isCacheValid) {
      emit(state.copyWith(
        currentView: ViewMode.aiBrief,
        aiBriefData: _aiBriefCache,
      ));
      return;
    }

    // Generate new brief
    emit(state.copyWith(isGeneratingBrief: true));

    final briefResponse = await _aiBriefRepository.generateBrief(...);
    _aiBriefCache = briefResponse;

    emit(state.copyWith(
      aiBriefData: briefResponse,
      isGeneratingBrief: false,
    ));
  }
});
```

#### **Krok 5: UI Implementation** (1.5h)

**5.1 Přidej Brief Tab** (30 min)

V `TodoListPage` - horizontal scroll s tagy:
```dart
Row(
  children: [
    _ViewTab(label: 'All', icon: Icons.list, ...),
    _ViewTab(label: 'Today', icon: Icons.today, ...),
    _ViewTab(label: 'Week', icon: Icons.calendar_view_week, ...),
    _ViewTab(label: 'Overdue', icon: Icons.warning, ...),
    _ViewTab(label: 'Brief', icon: Icons.auto_awesome, ...), // NEW ✨
  ],
)
```

**5.2 Brief View Logic** (30 min)
```dart
Widget _buildBriefView(BuildContext context, TodoListState state) {
  // Loading state
  if (state.isGeneratingBrief) {
    return Center(child: CircularProgressIndicator());
  }

  // Error state
  if (state.briefError != null) {
    return ErrorWidget(...);
  }

  // Brief sections s TodoCards
  return ListView.builder(
    itemCount: state.briefSections!.length,
    itemBuilder: (context, index) {
      final sectionData = state.briefSections![index];
      return _BriefSectionWidget(
        section: sectionData.section,
        todos: sectionData.todos,
      );
    },
  );
}
```

**5.3 BriefSectionWidget** (30 min)

Widget pro jednu sekci (AI komentář + TodoCards):
```dart
class _BriefSectionWidget extends StatelessWidget {
  final BriefSection section;
  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AI Commentary Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(...),
          child: Column(
            children: [
              Text(section.title),      // "🎯 FOCUS NOW"
              Text(section.commentary), // AI komentář
            ],
          ),
        ),

        // Real TodoCards (user může hned pracovat!)
        ...todos.map((todo) => TodoCard(
          key: ValueKey('todo_${todo.id}'),
          todo: todo,
          isExpanded: false,
        )),
      ],
    );
  }
}
```

#### **Krok 6: Testing** (30 min)

**6.1 Unit Tests** (15 min)
```dart
test('BriefResponse.fromJson parses correctly', () { ... });
test('validate removes invalid task IDs', () { ... });
```

**6.2 Widget Tests** (15 min)
```dart
testWidgets('Brief view displays sections with TodoCards', (tester) async {
  // Mock state s aiBriefData
  // Verify section header + TodoCards displayed
});
```

#### **Krok 7: Git Commit** (5 min)

```bash
git add -A && git commit -m "✨ feat: AI Brief - inteligentní filtrování úkolů v Agenda view

- Brief jako nový tab (All, Today, Week, Overdue, Brief)
- AI vrací JSON s task IDs + komentáře (focus_now, key_insights, motivation)
- Zobrazí real TodoCards (user může hned pracovat)
- Cache 1h + validace task IDs (anti-hallucination)
- Cost: ~\$0.009 per brief

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### 🚨 CRITICAL RULES pro AI Brief

1. **Brief NENÍ samostatná stránka** → je to VIEW MODE v TodoListPage
2. **AI vrací JSON** (ne markdown!) - viz brief.md řádky 198-221
3. **Validuj task IDs** proti DB (catch hallucinations)
4. **Real TodoCards** - ne clickable linky!
5. **Cache 1h** - uložit v BLoC state (_aiBriefCache)
6. **Cost tracking** - každý API call ~$0.009

### 📋 Checklist před implementací

- [ ] Přečetl jsem celý [brief.md](brief.md)
- [ ] Pochopil jsem koncept (Brief = Agenda view tab, ne samostatná page)
- [ ] Snapshot commit před začátkem
- [ ] Vytvořil jsem TODO list (7 kroků)
- [ ] Dodržuji SCÉNÁŘ 1 z mapa-bloc.md (přidání nové feature)

### 💡 Tips

- **System prompt je v brief.md** (řádky 177-246) - zkopíruj přesně!
- **AI má vrátit POUZE JSON** - žádný markdown kolem
- **Cache je klíčový** - 1h validity saves money
- **Validation je povinná** - AI může hallucinate task IDs
- **TodoCard je reusable** - použij existující widget

**Priorita**: ⭐⭐⭐ Vysoká (killer feature - AI prioritizace)

**Effort**: 6-8h MVP, 10-12h polished

---

## 📚 META

Účel: Instrukce pro AI agenty pracující na Flutter/BLoC projektech

Companion dokumenty:
- bloc.md - Detailní BLoC best practices guide
- mapa-bloc.md - Navigační decision tree
- brief.md - AI Brief implementační plán

Verze: 1.9
Vytvořeno: 2025-10-09
Aktualizováno: 2025-10-13 (přidán AI Brief - inteligentní filtrování úkolů)
Autor: Claude Code (AI asistent)

---

🎯 Pamatuj: Feature-First + BLoC = škálovatelná architektura pro Flutter projekty! 🚀
