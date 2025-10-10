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

## 🤖 AI Split Feature - Implementační Plán

### 📋 Kompletní guide: [rodel.md](rodel.md)

**Funkce**: Rozdělit TODO úkol na podúkoly pomocí AI (OpenRouter API)

**Kdy použít**: Implementace nové feature `lib/features/ai_split/`

**Postup**:
1. Přečti si kompletní plán v [rodel.md](rodel.md)
2. Následuj 9-kroků implementace (Feature-First + BLoC architektura)
3. Dodržuj SCÉNÁŘ 1 z [mapa-bloc.md](mapa-bloc.md) - Přidání nové feature

**Klíčové komponenty**:
- 🎨 UI: `AiSplitButton` (🤖 ikona), `AiSplitDialog`, `SubtaskListView`
- 🧠 State: `AiSplitCubit` (states: Initial, Loading, Success, Error)
- 🗄️ Data: `OpenRouterDataSource`, `AiSplitRepository`
- 💾 DB: `subtasks` tabulka s CASCADE delete na `parent_todo_id`

**Poznámka**: Tato feature je inspirována Tauri verzí programu - viz analýza v [rodel.md](rodel.md)

---

## 📋 Agenda Views + Search + Sort - Implementační Plán

### 📋 Kompletní guide: [agenda.md](agenda.md)

**Funkce**: Views (Today/Week/Upcoming/Overdue), Vyhledávání a Sortování úkolů

**Kdy použít**: Rozšíření existující feature `lib/features/todo_list/`

**Postup**:
1. Přečti si kompletní plán v [agenda.md](agenda.md)
2. Následuj 7-kroků implementace (Dart-side filtering + SQLite indexy)
3. Dodržuj SCÉNÁŘ 2 z [mapa-bloc.md](mapa-bloc.md) - Úprava existující feature

**Klíčové komponenty**:
- 🔍 **Search**: Textové vyhledávání s debouncing (300ms)
- 📅 **Views**: 5 režimů (Všechny/Dnes/Týden/Nadcházející/Overdue)
- 🔄 **Sort**: 4 módy (Priorita/Deadline/Status/Datum) s one-click toggle
- 🎨 **UI**: Lupa vlevo od input, FilterChips pro views, kompaktní sort buttons
- ⚡ **Performance**: SQLite indexy + Dart-side filtering

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [agenda.md](agenda.md) (✅ symbol)
- 📝 Zaznamenej progress notes na konec souboru (sekce "## 📝 PROGRESS LOG")
- 🐛 Dokumentuj narazené problémy a řešení
- 🔄 Update TODO list v Claude Code UI

**Poznámka**: Feature inspirovaná Tauri TODO app (Org Mode Agenda style)

---

## 📱 Mobile-First UI Redesign - Implementační Plán

### 📋 Kompletní guide: [gui.md](gui.md)

**Funkce**: Redesign GUI podle Thumb Zone best practices pro mobilní zařízení

**Kdy použít**: Refaktoring layoutu TodoListPage (major UI změny)

**Postup**:
1. Přečti si kompletní specifikaci v [gui.md](gui.md)
2. Následuj implementační plán (4 fáze, 18 kroků)
3. Dodržuj SCÉNÁŘ 2 z [mapa-bloc.md](mapa-bloc.md) - Úprava existující feature
4. **Snapshot commit před každou fází!**

**Klíčové změny**:
- 📍 **Input box DOLE** (Easy Thumb Zone) - fixed bottom
- ⌨️ **Keyboard awareness** - SortBar/ViewBar se skryjí při psaní
- 📏 **Maximální TextField** - edge-to-edge ikony, Expanded widget
- 📊 **Stats dashboard** - TopBar s počítadly (jeden řádek!)
- 🎨 **Kompaktní controls** - všechny akce v dosahu palce

**Struktura nového layoutu (zdola nahoru)**:
```
TopBar:   [✅5][🔴12][📅3][⏰7]         [⚙️]  ← Stats + Settings
List:     (scrollable TODO items)             ← Stretch Zone
SortBar:  [🔴] [📅] [✅] [🆕]                ← Easy Zone (skryté při psaní)
ViewBar:  [📋] [📅] [🗓️] [⏰] [⚠️] [👁️]     ← Easy Zone (skryté při psaní)
InputBar: [🔍][___ TextField MAX ___][➕]    ← Easy Zone (vždy viditelný)
```

**Implementační fáze**:
- **Fáze 1**: Struktura (InputBar, ViewBar, SortBar, StatsRow widgets)
- **Fáze 2**: Chování (keyboard awareness, search mode, stats výpočty)
- **Fáze 3**: Testing (Android emulator, thumb reachability)
- **Fáze 4**: Polish (animace, tooltips, accessibility)

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [gui.md](gui.md) implementačním plánu
- 📝 Zaznamenej narazené problémy a řešení
- 🔄 Update TODO list v Claude Code UI po každé fázi
- 📸 Snapshot commit před každou fází!

**Poznámka**: Návrh založený na UX research 2024 (Thumb Zone, FAB best practices)

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

## 📚 META

Účel: Instrukce pro AI agenty pracující na Flutter/BLoC projektech

Companion dokumenty:
- bloc.md - Detailní BLoC best practices guide
- mapa-bloc.md - Navigační decision tree
- rodel.md - AI Split Feature implementační plán (OpenRouter API integrace)
- agenda.md - Agenda Views + Search + Sort implementační plán
- gui.md - Mobile-First UI Redesign specifikace (Thumb Zone best practices)
- CLAUDE.md - Univerzální instrukce (pro všechny projekty)

Verze: 1.3
Vytvořeno: 2025-10-09
Aktualizováno: 2025-10-10 (přidána Mobile-First UI Redesign specifikace)
Autor: Claude Code (AI asistent)

---

🎯 Pamatuj: Feature-First + BLoC = škálovatelná architektura pro Flutter projekty! 🚀
