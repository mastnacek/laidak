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

## 📘 Interaktivní Nápověda (Help System) - Implementační Plán

### 📋 Kompletní guide: [help.md](help.md)

**Funkce**: Interaktivní nápověda s AI demo pro onboarding uživatelů

**Kdy použít**: Nová feature `lib/features/help/` s interaktivními tutoriály

**Postup**:
1. Přečti si kompletní návrh v [help.md](help.md)
2. Následuj implementační plán (5 fází, 3-4 hodiny)
3. Dodržuj SCÉNÁŘ 1 z [mapa-bloc.md](mapa-bloc.md) - Přidání nové feature

**Klíčové komponenty**:
- 📱 **HelpPage** - Card-based layout s kategoriemi
- 🏷️ **Tag Demo** - Interaktivní TagParser demo (bez API)
- 🤖 **AI Split Demo** - Live AI rozdělení úkolu (s OpenRouter)
- 💬 **Motivation Demo** - AI motivační prompty (s OpenRouter)
- 🧙 **Wizard** - First-time onboarding (optional)

**Architektura**:
```
lib/features/help/
├── presentation/
│   ├── pages/help_page.dart, wizard_page.dart
│   ├── widgets/tag_demo_widget.dart, ai_split_demo_widget.dart
│   └── cubit/help_cubit.dart
└── domain/models/help_section.dart
```

**Implementační fáze**:
- **Fáze 1** (1-2h): Základní Help Page + static content
- **Fáze 2** (30min): Tag Demo (live parsing, no API)
- **Fáze 3** (1h): AI Split Demo (OpenRouter integration)
- **Fáze 4** (1h): Motivation Demo (prompt templates + API)
- **Fáze 5** (1-2h): First-time Wizard (optional)

**Bezpečnost & validace**:
- ✅ API key check před demo
- ✅ Model selection validation
- ✅ Rate limiting (max 5 demos/min)
- ✅ Error handling (network, API failures)
- ✅ Clear cost communication

**UX Features**:
- 📖 Příklady s copy-paste
- 🎮 Interaktivní demo (try-before-use)
- ⚠️ API requirements warnings
- 💾 Save demo results to real todos
- ♿ Accessibility support

**Tracking postupu realizace**:
- ✅ Markuj dokončené fáze v [help.md](help.md)
- 📝 Zaznamenej UX findings a user feedback
- 🐛 Dokumentuj API edge cases
- 🔄 Update TODO list v Claude Code UI po každé fázi

**Priorita**: ⭐⭐⭐ Vysoká (kritické pro user adoption)

**Poznámka**: Kombinace card-based layout + wizard pro optimální onboarding experience

---

## ⚙️ Custom Agenda Views - Implementační Plán

### 📋 Kompletní guide: [custom-agenda-views.md](custom-agenda-views.md)

**Funkce**: Konfigurovatelné Agenda Views - uživatel si sám vybere které views chce vidět

**Kdy použít**: Rozšíření Settings + refaktoring ViewBar (cross-feature úprava)

**Postup**:
1. Přečti si kompletní plán v [custom-agenda-views.md](custom-agenda-views.md)
2. Následuj **5 fází** implementace (malé kroky, commit po každé fázi)
3. **DŮLEŽITÉ**: Toto je cross-feature úprava (Settings + TodoList) - postupuj opatrně!
4. Dodržuj SCÉNÁŘ 2 z [mapa-bloc.md](mapa-bloc.md) - Úprava existujících features

**Klíčové komponenty**:
- ⚙️ **Settings > Agenda** - Nová záložka pro konfiguraci views
- 📊 **Built-in Views Toggle** - Zapnout/vypnout All, Today, Week, Upcoming, Overdue
- 🆕 **Custom Views** - Tag-based filtry (např. `projekt` = Projekty, `nakup` = Nákupy)
- 🎨 **ViewBar Dynamic** - Zobrazí pouze enabled views
- 💾 **Persistence** - SharedPreferences (žádné DB migrace!)

**Architektura**:
```
lib/features/settings/
├── domain/models/
│   ├── agenda_view_config.dart       🆕 Config model
│   └── custom_agenda_view.dart       🆕 Custom view model
└── presentation/
    ├── cubit/settings_cubit.dart     Rozšířeno
    └── pages/
        ├── settings_page.dart        + tab "Agenda"
        └── agenda_settings_tab.dart  🆕 UI

lib/features/todo_list/
├── domain/enums/view_mode.dart       + ViewMode.custom
├── domain/extensions/todo_filtering  + filterByCustomView()
└── presentation/
    ├── bloc/
    │   ├── todo_list_event.dart      + ChangeToCustomViewEvent
    │   └── todo_list_state.dart      + currentCustomView
    └── widgets/view_bar.dart         Refaktoring (dynamic)
```

**Implementační fáze (postupuj PŘESNĚ v tomto pořadí!)**:

### **FÁZE 1: Data Layer** ⏱️ 30 min
**Cíl**: Vytvořit domain models + SharedPreferences persistence

**Kroky**:
- [ ] 1.1 Vytvoř `agenda_view_config.dart` (toJson/fromJson/copyWith)
- [ ] 1.2 Vytvoř `custom_agenda_view.dart` (toJson/fromJson/copyWith)
- [ ] 1.3 Rozšiř `SettingsState` - přidej `agendaConfig` field
- [ ] 1.4 Přidej persistence do `settings_repository_impl.dart`
- [ ] 1.5 Přidej metody do `SettingsCubit` (toggle, add, update, delete)
- [ ] **Commit**: `🔧 feat: Data layer pro Custom Agenda Views`

**Tracking**: Markuj kroky v [custom-agenda-views.md](custom-agenda-views.md) FÁZE 1

---

### **FÁZE 2: Settings UI** ⏱️ 1.5-2h
**Cíl**: Přidat záložku "Agenda" s UI pro konfiguraci

**Kroky**:
- [ ] 2.1 Přidej tab "Agenda" do `SettingsPage` (TabBar length = 3)
- [ ] 2.2 Vytvoř `agenda_settings_tab.dart`
- [ ] 2.3 Implementuj built-in views section (SwitchListTile)
- [ ] 2.4 Implementuj custom views section (Card list + buttons)
- [ ] 2.5 Vytvoř `_CustomViewDialog` (Add/Edit dialog)
- [ ] 2.6 Přidej icon picker (dropdown s 5 ikonami)
- [ ] **Commit**: `🎨 feat: Settings UI pro Custom Agenda Views`

**Tracking**: Markuj kroky v [custom-agenda-views.md](custom-agenda-views.md) FÁZE 2

---

### **FÁZE 3: ViewBar Refaktoring** ⏱️ 1h
**Cíl**: ViewBar dynamicky zobrazuje pouze enabled views

**Kroky**:
- [ ] 3.1 Rozšiř `ViewMode` enum - přidej `custom`
- [ ] 3.2 Refaktoruj `view_bar.dart` - dynamic rendering
- [ ] 3.3 Přidej `ChangeToCustomViewEvent` do `todo_list_event.dart`
- [ ] 3.4 Rozšiř `TodoListState` - přidej `currentCustomView`
- [ ] 3.5 Implementuj empty state hint
- [ ] 3.6 Přidej horizontal scroll pro > 6 views
- [ ] **Commit**: `🎨 feat: ViewBar dynamic rendering based on AgendaViewConfig`

**Tracking**: Markuj kroky v [custom-agenda-views.md](custom-agenda-views.md) FÁZE 3

---

### **FÁZE 4: Filtrování** ⏱️ 30 min
**Cíl**: Custom views filtrují úkoly podle tagů

**Kroky**:
- [ ] 4.1 Přidej `filterByCustomView()` do `todo_filtering.dart`
- [ ] 4.2 Přidaj handler `_onChangeToCustomView` do `todo_list_bloc.dart`
- [ ] 4.3 Registruj event handler v konstruktoru
- [ ] 4.4 Rozšiř `displayedTodos` getter - custom filtering
- [ ] **Commit**: `✨ feat: Custom View filtering by tag`

**Tracking**: Markuj kroky v [custom-agenda-views.md](custom-agenda-views.md) FÁZE 4

---

### **FÁZE 5: Testing & Polish** ⏱️ 30 min
**Cíl**: Manuální testing + edge cases

**Checklist**:
- [ ] 5.1 Settings > Agenda tab zobrazuje built-in views ✅
- [ ] 5.2 Zapnutí/vypnutí built-in view funguje ✅
- [ ] 5.3 Přidání custom view funguje ✅
- [ ] 5.4 Úprava custom view funguje ✅
- [ ] 5.5 Smazání custom view funguje ✅
- [ ] 5.6 ViewBar zobrazuje pouze enabled views ✅
- [ ] 5.7 Klik na custom view filtruje správně ✅
- [ ] 5.8 Long-press zobrazí InfoDialog ✅
- [ ] 5.9 Empty state hint funguje ✅
- [ ] 5.10 Horizontal scroll funguje (> 6 views) ✅
- [ ] 5.11 Persistence po restartu ✅
- [ ] **Commit**: `✅ test: Manual testing Custom Agenda Views`

**Tracking**: Markuj checklist v [custom-agenda-views.md](custom-agenda-views.md) FÁZE 5

---

**Celkový čas**: 3-4 hodiny

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [custom-agenda-views.md](custom-agenda-views.md) (checkboxy)
- 📝 Přidej poznámky do sekce "PROGRESS LOG" na konci souboru
- 🐛 Dokumentuj problémy a jejich řešení
- 📸 **POVINNÝ commit po KAŽDÉ fázi!**
- 🔄 Update TODO list v Claude Code UI

**Edge Cases**:
- Co když uživatel vypne všechny views? → Show hint "Zapni views v Settings"
- Co když custom view má neexistující tag? → Zobrazí prázdný list (expected)
- Persistence funguje? → Test restart app

**Priorita**: ⭐⭐⭐ Vysoká (game-changer pro UX - customizace pro každého usera)

**Poznámka**: Cross-feature úprava - dotýká se Settings + TodoList, postupuj opatrně a commituj po každé fázi!

---

## 🗄️ SQLite Database Refactoring - Implementační Plán

### 📋 Kompletní guide: [sqlite-final.md](sqlite-final.md)

**Funkce**: Refaktoring databáze podle best practices - Tags normalizace + Custom Agenda Views do DB

**Kdy použít**: Major database refactoring (přidání tabulek, migrace dat, performance optimalizace)

**Postup**:
1. Přečti si kompletní plán v [sqlite-final.md](sqlite-final.md)
2. Následuj **3 milestones** (MILESTONE 1 → 2 → 3)
3. **DŮLEŽITÉ**: Toto je kritická operace - snapshot commit před každým milestone!
4. **⚠️ Nelze downgrade** z DB verze 11 → 10 (testuj na kopii databáze!)

**Klíčové změny**:
- 🗄️ **Tags normalizace** - CSV → `tags` + `todo_tags` tabulky (many-to-many)
- 🎨 **Tag autocomplete** - 10 nejpoužívanějších tagů (UX game-changer!)
- 📊 **Custom Agenda Views** - Přesun z SharedPreferences → DB
- ⚡ **Performance** - 10-100x rychlejší search, WAL mode, optimální indexy

**Architektura (PŘED → PO)**:
```
PŘED:
- 5 tabulek, 40 sloupců
- Tags jako CSV string (❌ pomalé)
- Custom views v SharedPrefs (❌ inconsistence)

PO:
- 8 tabulek, 58 sloupců
- Tags normalizované (✅ rychlé, autocomplete)
- Custom views v DB (✅ konzistence)
```

**Implementační milestones (postupuj PŘESNĚ v tomto pořadí!)**:

### **MILESTONE 1: Tags Normalization** ⏱️ 4-6h
**Priorita**: 🔴 CRITICAL

**Kroky**:
- [ ] 1.1 Vytvoř tabulku `tags` (15 min)
- [ ] 1.2 Vytvoř tabulku `todo_tags` (10 min)
- [ ] 1.3 Migrace CSV → normalizované tagy (30 min)
- [ ] 1.4 Přidej CRUD metody pro tags (30 min)
- [ ] 1.5 Update TodoRepository (45 min)
- [ ] 1.6 Přidej Tag Autocomplete UI (60 min)
- [ ] 1.7 Testing & Commit (30 min)
- [ ] **Commit**: `✨ feat: Tags normalization (MILESTONE 1)`

**Výsledek**: 10-100x rychlejší search, tag autocomplete

---

### **MILESTONE 2: Custom Agenda Views to DB** ⏱️ 2-3h
**Priorita**: 🟡 HIGH

**Kroky**:
- [ ] 2.1 Vytvoř tabulku `custom_agenda_views` (15 min)
- [ ] 2.2 Přidej built-in view settings do `settings` (10 min)
- [ ] 2.3 Migrace SharedPrefs → DB (30 min)
- [ ] 2.4 Přidej CRUD metody (30 min)
- [ ] 2.5 Update SettingsCubit (30 min)
- [ ] 2.6 Testing & Commit (20 min)
- [ ] **Commit**: `✨ feat: Custom Agenda Views to DB (MILESTONE 2)`

**Výsledek**: Konzistence dat, vše v DB

---

### **MILESTONE 3: Cleanup & Performance** ⏱️ 1-2h
**Priorita**: 🟢 MEDIUM

**Kroky**:
- [ ] 3.1 Mark deprecated `tags` column (5 min)
- [ ] 3.2 Enable WAL mode (10 min)
- [ ] 3.3 Add ANALYZE helper (10 min)
- [ ] 3.4 Add VACUUM helper (10 min)
- [ ] 3.5 Check page size (15 min)
- [ ] 3.6 Final testing & commit (30 min)
- [ ] **Commit**: `⚡ perf: Cleanup & Performance (MILESTONE 3)`

**Výsledek**: Code hygiene, performance optimalizace

---

**Celkový čas**: 7-11 hodin

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [sqlite-final.md](sqlite-final.md) (checkboxy)
- 📝 Follow step-by-step guide - každý krok má přesný kód!
- 🐛 Dokumentuj narazené problémy a řešení
- 📸 **POVINNÝ snapshot commit PŘED každým milestone!**
- 🔄 Update TODO list v Claude Code UI

**Database Version Bump**:
```dart
// database_helper.dart řádek 28
version: 11,  // ← ZMĚNIT z 10 na 11
```

**⚠️ KRITICKÉ UPOZORNĚNÍ**:
- **Nelze downgrade** z DB verze 11 → 10!
- **Testuj na kopii** databáze (Android emulator)
- **Backup** před migrací (export/import)
- **Foreign keys** musí být enabled: `PRAGMA foreign_keys = ON`

**Očekávané zlepšení**:

| Metrická | PŘED | PO | Zlepšení |
|----------|------|----|-----------|
| Search s tagem | 🐌 O(n) | ⚡ O(log n) | **10-100x rychlejší** |
| Tag autocomplete | ❌ Nelze | ✅ Instant | **♾️** |
| Tag normalizace | ❌ "Projekt" ≠ "projekt" | ✅ Unified | **♾️** |
| Custom views | ⚠️ SharedPrefs | ✅ DB | **Unified** |

**Priorita**: ⭐⭐⭐ CRITICAL (největší performance win v celém projektu!)

**Poznámka**: Toto je nejvíce impactful refactoring - tag autocomplete + 100x rychlejší search = game-changer pro UX!

**Dodatečné dokumenty**:
- [sqlite.md](sqlite.md) - Původní audit (problémy + návrhy řešení)
- [sqlite-columns-analysis.md](sqlite-columns-analysis.md) - Analýza sloupců + SQLite limity
- [sqlite-final.md](sqlite-final.md) - **HLAVNÍ GUIDE** (step-by-step implementace)

---

## ⚙️ Settings Refactoring - God Object Elimination

### 📋 Problém: `settings_page.dart` má 2661 řádků (GOD OBJECT!)

**Současný stav**:
- ❌ `lib/pages/settings_page.dart` - 2661 lines (ŠPATNĚ!)
- ❌ 5 tabů v jednom souboru (massive violation)
- ❌ God object anti-pattern
- ✅ Feature struktura existuje: `lib/features/settings/` (ale prázdná!)

**Cíl**: Rozdělit god object podle Feature-First architektury

**Kdy použít**: Major refactoring existující feature (god object → clean architecture)

**Postup**:
1. Postupuj podle **4 fází** níže
2. Každá fáze = 1 commit (snapshot před risky operací)
3. Dodržuj SCÉNÁŘ 2 z [mapa-bloc.md](mapa-bloc.md) - Úprava existující feature

**Architektura PŘED → PO**:
```
PŘED (❌):
lib/pages/settings_page.dart         # 2661 lines GOD OBJECT
├── _AISettingsTab                   # 200 lines
├── _PromptsTab                      # 500 lines
├── _ThemesTab                       # 300 lines
├── _AgendaTab                       # 800 lines (už existuje v features!)
└── _CustomViewDialog                # 400 lines

PO (✅):
lib/features/settings/
├── presentation/
│   ├── pages/
│   │   ├── settings_page.dart       # 100 lines (main TabBar scaffold)
│   │   ├── ai_settings_tab.dart     # 200 lines
│   │   ├── prompts_tab.dart         # 500 lines
│   │   ├── themes_tab.dart          # 300 lines
│   │   └── agenda_tab.dart          # EXISTUJE (přesunuto z lib/pages/)
│   ├── widgets/
│   │   └── custom_view_dialog.dart  # 400 lines
│   └── cubit/settings_cubit.dart    # EXISTUJE
└── domain/models/                    # EXISTUJE
```

---

### **FÁZE 1: Extrakce AI Settings Tab** ⏱️ 30 min

**Cíl**: Přesunout `_AISettingsTab` do samostatného souboru

**Kroky**:
- [ ] 1.1 Vytvoř `lib/features/settings/presentation/pages/ai_settings_tab.dart`
- [ ] 1.2 Zkopíruj `_AISettingsTab` class (řádky ~100-1022)
- [ ] 1.3 Změň na public: `class AISettingsTab extends StatefulWidget`
- [ ] 1.4 Přidej import do `settings_page.dart`
- [ ] 1.5 Nahraď `_AISettingsTab()` → `AISettingsTab()`
- [ ] 1.6 Smaž původní `_AISettingsTab` z `settings_page.dart`
- [ ] **Test**: Ověř že AI Settings tab funguje
- [ ] **Commit**: `♻️ refactor: Extract AI Settings Tab (FÁZE 1)`

**Výsledek**: `settings_page.dart` zmenšen o ~900 řádků

---

### **FÁZE 2: Extrakce Prompts Tab** ⏱️ 30 min

**Cíl**: Přesunout `_PromptsTab` do samostatného souboru

**Kroky**:
- [ ] 2.1 Vytvoř `lib/features/settings/presentation/pages/prompts_tab.dart`
- [ ] 2.2 Zkopíruj `_PromptsTab` class (řádky ~1025-1554)
- [ ] 2.3 Změň na public: `class PromptsTab extends StatefulWidget`
- [ ] 2.4 Přidej import do `settings_page.dart`
- [ ] 2.5 Nahraď `_PromptsTab()` → `PromptsTab()`
- [ ] 2.6 Smaž původní `_PromptsTab` z `settings_page.dart`
- [ ] **Test**: Ověř že Prompts tab funguje
- [ ] **Commit**: `♻️ refactor: Extract Prompts Tab (FÁZE 2)`

**Výsledek**: `settings_page.dart` zmenšen o dalších ~500 řádků

---

### **FÁZE 3: Extrakce Themes Tab** ⏱️ 30 min

**Cíl**: Přesunout `_ThemesTab` do samostatného souboru

**Kroky**:
- [ ] 3.1 Vytvoř `lib/features/settings/presentation/pages/themes_tab.dart`
- [ ] 3.2 Zkopíruj `_ThemesTab` class (řádky ~1557-1868)
- [ ] 3.3 Změň na public: `class ThemesTab extends StatefulWidget`
- [ ] 3.4 Přidej import do `settings_page.dart`
- [ ] 3.5 Nahraď `_ThemesTab()` → `ThemesTab()`
- [ ] 3.6 Smaž původní `_ThemesTab` z `settings_page.dart`
- [ ] **Test**: Ověř že Themes tab funguje
- [ ] **Commit**: `♻️ refactor: Extract Themes Tab (FÁZE 3)`

**Výsledek**: `settings_page.dart` zmenšen o dalších ~300 řádků

---

### **FÁZE 4: Extrakce Agenda Tab + Cleanup** ⏱️ 45 min

**Cíl**: Přesunout `_AgendaTab` + `_CustomViewDialog` a přesunout main page

**Kroky**:
- [ ] 4.1 Zkontroluj jestli už neexistuje `agenda_tab.dart` v features/settings/
- [ ] 4.2 Pokud NE: Vytvoř `lib/features/settings/presentation/pages/agenda_tab.dart`
- [ ] 4.3 Zkopíruj `_AgendaTab` class (řádky ~1871-2286)
- [ ] 4.4 Vytvoř `lib/features/settings/presentation/widgets/custom_view_dialog.dart`
- [ ] 4.5 Zkopíruj `_CustomViewDialog` class (řádky ~2289-2661)
- [ ] 4.6 Změň na public widgety
- [ ] 4.7 Přidej importy do `settings_page.dart`
- [ ] 4.8 Nahraď private widgety → public
- [ ] 4.9 Smaž původní widgety z `settings_page.dart`
- [ ] 4.10 **Přesuň** `lib/pages/settings_page.dart` → `lib/features/settings/presentation/pages/settings_page.dart`
- [ ] 4.11 **Smaž** starý `lib/pages/settings_page.dart`
- [ ] 4.12 **Update importy** všude kde se používal import `lib/pages/settings_page.dart`
- [ ] **Test**: Kompletní manuální test všech 5 tabů
- [ ] **Commit**: `♻️ refactor: Extract Agenda Tab + move to features (FÁZE 4)`

**Výsledek**:
- ✅ God object eliminován
- ✅ `settings_page.dart` má ~100 řádků (pouze TabBar scaffold)
- ✅ Každý tab v samostatném souboru
- ✅ Vše v `lib/features/settings/`

---

**Celkový čas**: 2-3 hodiny

**Očekávaná struktura PO refaktoringu**:
```
lib/features/settings/
├── domain/models/
│   ├── agenda_view_config.dart       ✅ EXISTUJE
│   └── custom_agenda_view.dart       ✅ EXISTUJE
├── presentation/
│   ├── cubit/
│   │   ├── settings_cubit.dart       ✅ EXISTUJE
│   │   └── settings_state.dart       ✅ EXISTUJE
│   ├── pages/
│   │   ├── settings_page.dart        🆕 PŘESUNUTO (~100 lines)
│   │   ├── ai_settings_tab.dart      🆕 NOVÝ (200 lines)
│   │   ├── prompts_tab.dart          🆕 NOVÝ (500 lines)
│   │   ├── themes_tab.dart           🆕 NOVÝ (300 lines)
│   │   └── agenda_tab.dart           🆕 NOVÝ (800 lines)
│   └── widgets/
│       └── custom_view_dialog.dart   🆕 NOVÝ (400 lines)
```

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v checkboxech výše
- 📝 Poznamenej problémy při migraci
- 🐛 Dokumentuj edge cases (missing imports, etc.)
- 📸 **POVINNÝ commit po KAŽDÉ fázi!**
- 🔄 Update TODO list v Claude Code UI

**Edge Cases**:
- ⚠️ **Import conflicts**: Po přesunu `settings_page.dart` update všechny importy (GoRouter, main.dart, etc.)
- ⚠️ **TabBar length**: Ověř že TabBar má správný počet tabů (5)
- ⚠️ **Theme access**: Zkontroluj že všechny taby mají přístup k `Theme.of(context)`

**Priorita**: ⭐⭐⭐ CRITICAL (god object je code smell - musí se odstranit!)

**Poznámka**: Toto je čistící refaktoring (cleanup) - žádné nové funkce, pouze lepší organizace kódu!

**Bezpečnostní opatření**:
- ✅ Snapshot commit PŘED začátkem
- ✅ Test po každé fázi
- ✅ Commit po každé fázi
- ✅ Pokud něco selže → `git reset --hard HEAD~1`

---

## 🍅 Pomodoro Timer - Implementační Plán

### 📋 Kompletní guide: [pomodoro.md](pomodoro.md)

**Funkce**: Pomodoro Timer pro produktivní práci s úkoly (25 min práce + 5 min pauza)

**Kdy použít**: Implementace nové feature `lib/features/pomodoro/`

**Postup**:
1. Přečti si kompletní plán v [pomodoro.md](pomodoro.md)
2. Následuj **6 MILESTONES** (malé kroky, commit po každém milestonu)
3. **DŮLEŽITÉ**: Hlídej zbývající tokeny! Pokud < 50k, ukonči session a pokračuj v nové.
4. Dodržuj SCÉNÁŘ 1 z [mapa-bloc.md](mapa-bloc.md) - Přidání nové feature

**Klíčové komponenty**:
- ⏱️ **PomodoroTimerService** - Isolate-based timer (přesnost ~50ms)
- 🧠 **PomodoroBloc** - State management (Events + States)
- 🗄️ **PomodoroRepository** - SQLite persistence (pomodoro_sessions tabulka)
- 📱 **PomodoroPage** - UI s circular timer + controls
- 🔔 **NotificationService** - Android foreground notifications (optional)

**Architektura**:
```
lib/features/pomodoro/
├── presentation/
│   ├── bloc/
│   │   ├── pomodoro_bloc.dart
│   │   ├── pomodoro_event.dart
│   │   └── pomodoro_state.dart
│   ├── pages/pomodoro_page.dart
│   └── widgets/
│       ├── timer_display.dart
│       └── timer_controls.dart
├── domain/
│   ├── entities/
│   │   ├── pomodoro_session.dart
│   │   ├── timer_state.dart
│   │   └── pomodoro_config.dart
│   ├── repositories/pomodoro_repository.dart
│   └── services/pomodoro_timer_service.dart
└── data/
    └── repositories/pomodoro_repository_impl.dart
```

**Implementační milestones (postupuj PŘESNĚ v tomto pořadí!)**:

### **MILESTONE 1: Core Timer Logic** ⏱️ 4-6h
**Priorita**: 🔴 CRITICAL

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "📋 IMPLEMENTATION PROGRESS - MILESTONE 1"
- Domain entities (PomodoroSession, TimerState, PomodoroConfig)
- Repository interface
- Isolate-based timer service
- PomodoroBloc (events, states, handlers)
- Unit tests
- **Commit**: `✨ feat: Core Pomodoro Timer Logic (MILESTONE 1)`

---

### **MILESTONE 2: Database Integration** ⏱️ 2-3h
**Priorita**: 🔴 CRITICAL

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "MILESTONE 2"
- Přidej tabulku `pomodoro_sessions`
- DB migrace (version 12)
- PomodoroRepositoryImpl
- CRUD operace
- **Commit**: `💾 feat: Pomodoro Database Persistence (MILESTONE 2)`

---

### **MILESTONE 3: Basic UI** ⏱️ 3-4h
**Priorita**: 🟡 HIGH

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "MILESTONE 3"
- Circular timer display (AnimatedBuilder)
- Control buttons (Start/Pause/Resume/Stop)
- BlocBuilder reactive UI
- Session info display
- **Commit**: `🎨 feat: Pomodoro Basic UI (MILESTONE 3)`

---

### **MILESTONE 4: Android Notifications** ⏱️ 2-3h
**Priorita**: 🟢 MEDIUM (optional)

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "MILESTONE 4"
- Foreground service setup
- Notification actions
- Background updates
- **Commit**: `🔔 feat: Android Notifications (MILESTONE 4)`

---

### **MILESTONE 5: Integration & Polish** ⏱️ 2-3h
**Priorita**: 🟡 HIGH

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "MILESTONE 5"
- TodoCard integration (🍅 button + dialog)
- Navigation setup
- History view
- Sound effects
- **Commit**: `✨ feat: Pomodoro Integration & Polish (MILESTONE 5)`

---

### **MILESTONE 6: Desktop Support** ⏱️ 3-4h
**Priorita**: 🟢 LOW (optional)

**Kroky**: Viz [pomodoro.md](pomodoro.md) sekce "MILESTONE 6"
- Windows tray icon
- Desktop notifications
- Platform checks
- **Commit**: `💻 feat: Pomodoro Desktop Support (MILESTONE 6)`

---

**Celkový čas**: 16-23 hodin (rozděleno do 6 milestones)

**⚠️ TOKEN BUDGET MANAGEMENT - KRITICKÉ!**:
```
Celkový budget: 200,000 tokens
Bezpečná hranice: 50,000 tokens zbývá
Nebezpečná zóna: < 30,000 tokens

PRAVIDLO:
- Před KAŽDÝM větším čtením/editací zkontroluj zbývající tokeny
- Pokud < 50,000 tokens zbývá → STOP a požádej o continuation
- NIKDY neriskuj autocompact mid-implementation!
- Každý milestone commituj → restart v nové session je bezpečný
```

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [pomodoro.md](pomodoro.md) (checkboxy)
- 📝 Update "IMPLEMENTATION PROGRESS" sekci po každém kroku
- 🐛 Dokumentuj narazené problémy a řešení
- 📸 **POVINNÝ commit po KAŽDÉM milestonu!**
- 🔄 Update TODO list v Claude Code UI
- 🔢 **Hlídej zbývající tokeny před každou operací!**

**Edge Cases**:
- Co když app je force-closed? → Timer se ztratí (future: save expected_end_time)
- Co když device restart? → Session lost (expected behavior v1.0)
- Jak battery optimization? → Notifications každých 5s (ne každou sekundu)
- Persistence settings? → PomodoroConfig v SharedPreferences

**Priorita**: ⭐⭐⭐ HIGH (produktivita feature - game-changer pro focus work)

**Poznámka**: Inspirováno Tauri TODO app - viz analýza Tauri implementace v [pomodoro.md](pomodoro.md)

**Současný stav**:
- ✅ Navigace setup (TODO Card → Dialog → PomodoroPage)
- ✅ Quick Start Dialog s výběrem délky
- ⏳ MILESTONE 1 pending (Core Timer Logic)

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
- help.md - Interaktivní nápověda s AI demo (onboarding & tutorials)
- voice.md - TTS (Text-to-Speech) feature dokumentace
- custom-agenda-views.md - Custom Agenda Views implementační plán (konfigurovatelné views)
- sqlite.md - SQLite database audit (problémy + návrhy řešení)
- sqlite-columns-analysis.md - Analýza sloupců + SQLite limity
- sqlite-final.md - SQLite refactoring implementační plán (step-by-step guide)
- CLAUDE.md - Univerzální instrukce (pro všechny projekty)

Verze: 1.7
Vytvořeno: 2025-10-09
Aktualizováno: 2025-01-10 (přidán Settings Refactoring - God Object Elimination)
Autor: Claude Code (AI asistent)

---

🎯 Pamatuj: Feature-First + BLoC = škálovatelná architektura pro Flutter projekty! 🚀
