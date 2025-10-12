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
- ai-chat.md - AI Chat feature implementační plán (konverzace s AI nad úkolem)

Verze: 1.8
Vytvořeno: 2025-10-09
Aktualizováno: 2025-10-12 (přidán AI Chat - konverzace s AI nad úkolem)
Autor: Claude Code (AI asistent)

---

🎯 Pamatuj: Feature-First + BLoC = škálovatelná architektura pro Flutter projekty! 🚀
