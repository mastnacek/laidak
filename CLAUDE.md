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

## 🤖 AI Chat - Konverzace s AI asistentem nad úkolem

### 📋 Kompletní guide: [ai-chat.md](ai-chat.md)

**Funkce**: Chat interface pro diskuzi s AI asistentem v kontextu konkrétního TODO úkolu

**Kdy použít**: Implementace nové feature `lib/features/ai_chat/`

**Postup**:
1. Přečti si kompletní plán v [ai-chat.md](ai-chat.md)
2. Následuj **8 kroků** implementace (Feature-First + BLoC architektura)
3. Dodržuj SCÉNÁŘ 1 z [mapa-bloc.md](mapa-bloc.md) - Přidání nové feature

**Klíčové komponenty**:
- 💬 **AiChatPage** - Fullscreen chat UI (message bubbles, input bar)
- 📋 **ContextSummaryCard** - Kompaktní přehled úkolu (expandable)
- 🧠 **AiChatBloc** - State management (Events + States)
- 🗄️ **OpenRouterChatDataSource** - Chat Completion API client
- 🤖 **Entry Point** - 🤖 ikona v TodoCard → otevře chat

**Architektura**:
```
lib/features/ai_chat/
├── presentation/
│   ├── pages/ai_chat_page.dart          # Fullscreen chat
│   ├── widgets/
│   │   ├── chat_message_bubble.dart     # Message UI
│   │   ├── chat_input.dart              # Input + Send
│   │   ├── typing_indicator.dart        # AI typing animation
│   │   └── context_summary_card.dart    # Task context
│   └── bloc/
│       ├── ai_chat_bloc.dart
│       ├── ai_chat_event.dart
│       └── ai_chat_state.dart
├── domain/
│   ├── entities/
│   │   ├── chat_message.dart            # Message entity
│   │   ├── task_context.dart            # Context builder
│   │   └── chat_session.dart            # Session (optional)
│   └── repositories/ai_chat_repository.dart
└── data/
    ├── datasources/openrouter_chat_datasource.dart
    └── repositories/ai_chat_repository_impl.dart
```

**Kontext úkolu (co AI vidí)**:
- ✅ Celý obsah úkolu (task, priority, deadline, tags)
- ✅ Všechny podúkoly (subtasks) včetně completion stavu
- ✅ AI recommendations (z předchozího AI Split)
- ✅ AI deadline analysis
- ✅ Historie Pomodoro sessions (kolik času stráveno)
- ✅ Metadata (created_at, updated_at, completion status)

**Use Cases**:
- 💡 Poradit se s AI jak úkol rozdělit jinak
- 📝 Požádat o detailní rozpis konkrétního podúkolu
- ⏰ Konzultovat deadline a prioritizaci
- 🧠 Brainstorming nad řešením problému
- 📊 Analýza progresu (kolik Pomodoro sessions, co zbývá)

**API Integration**:
- 🌐 **OpenRouter Chat Completion API**: https://openrouter.ai/docs/api-reference/chat-completion
- 🧠 **Model**: Používá Task model z nastavení (claude-3.5-sonnet - inteligentní)
- 📝 **Messages format**: System prompt (context) + User/Assistant messages
- 💾 **Persistence**: V1.0 session-based (chat v paměti), v2.0 DB persistence

**Implementační kroky**:
1. **Krok 1**: Domain Layer (30 min) - ChatMessage, TaskContext, Repository
2. **Krok 2**: Data Layer (1.5h) - OpenRouter datasource, Repository impl
3. **Krok 3**: Presentation Layer (1h) - BLoC events/states/handlers
4. **Krok 4**: UI Implementation (2-3h) - Page + Widgets (bubbles, input, typing)
5. **Krok 5**: Integration (20 min) - 🤖 ikona v TodoCard
6. **Krok 6**: Testing (30 min) - Unit + Widget testy
7. **Krok 7**: Polish (30 min) - Copy to clipboard, markdown support
8. **Krok 8**: Git Commit

**Tracking postupu realizace**:
- ✅ Markuj dokončené kroky v [ai-chat.md](ai-chat.md) (checkboxy)
- 📝 Zaznamenej UX findings a AI response quality
- 🐛 Dokumentuj API edge cases (rate limits, errors)
- 🔄 Update TODO list v Claude Code UI

**Priorita**: ⭐⭐⭐ Vysoká (game-changer pro user experience - AI asistent na jednom místě)

**Poznámka**: Session-based chat (v1.0) - KISS princip, DB persistence až v2.0

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
- voice.md - TTS (Text-to-Speech) feature dokumentace
- custom-agenda-views.md - Custom Agenda Views implementační plán (konfigurovatelné views)
- ai-chat.md - AI Chat feature implementační plán (konverzace s AI nad úkolem)
- CLAUDE.md - Univerzální instrukce (pro všechny projekty)

Verze: 1.8
Vytvořeno: 2025-10-09
Aktualizováno: 2025-10-12 (přidán AI Chat - konverzace s AI nad úkolem)
Autor: Claude Code (AI asistent)

---

🎯 Pamatuj: Feature-First + BLoC = škálovatelná architektura pro Flutter projekty! 🚀
