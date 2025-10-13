# AI Brief - Progress Report

**Datum**: 2025-10-13
**Status**: 🟡 70% Complete - BLoC Integration in progress
**Token Usage**: ~116k / 200k

---

## ✅ HOTOVO (100%)

### 1. Domain Layer ✅
- ✅ `lib/features/ai_brief/domain/entities/brief_section.dart`
  - Entity pro jednu sekci (Focus Now, Key Insights, Motivation)
  - Obsahuje: type, title, commentary, taskIds
  - fromJson, toJson, copyWith, Equatable

- ✅ `lib/features/ai_brief/domain/entities/brief_response.dart`
  - Entity pro celou AI odpověď
  - Obsahuje: sections, generatedAt
  - **validate()** - odstraní neplatné task IDs (anti-hallucination)
  - **isCacheValid** - 1h cache validity check
  - fromJson, toJson, Equatable

- ✅ `lib/features/ai_brief/domain/entities/brief_config.dart`
  - Konfigurace: includeSubtasks, includePomodoroStats, temperature, maxTokens
  - Výchozí hodnoty: temperature=0.3, maxTokens=500

- ✅ `lib/features/ai_brief/domain/repositories/ai_brief_repository.dart`
  - Repository interface
  - `generateBrief()` metoda

### 2. Data Layer ✅
- ✅ `lib/features/ai_brief/data/datasources/brief_ai_datasource.dart`
  - OpenRouter API client
  - System prompt (z brief.md) - AI vrací JSON s task_ids + commentary
  - generateBrief() metoda

- ✅ `lib/features/ai_brief/data/datasources/brief_context_builder.dart`
  - Sestaví strukturovaný user context pro AI
  - Format: TASK_ID, Text, Priority, Due Date, Subtasks, Tags
  - Počítá urgency (OVERDUE, in 2h, today, in 3 days)
  - User stats (completed today, active tasks)

- ✅ `lib/features/ai_brief/data/repositories/ai_brief_repository_impl.dart`
  - Repository implementace
  - Získá OpenRouter API key z DB (settings.openrouter_api_key)
  - Zavolá AI datasource
  - **Parsuje JSON** (s cleanMarkdownJson fallback)
  - **Validuje task IDs** proti allTodos

### 3. BLoC Integration ✅ (partial)
- ✅ `lib/features/todo_list/domain/enums/view_mode.dart`
  - Přidán **ViewMode.aiBrief**
  - Label: "✨ Brief"
  - Description: "AI prioritizované úkoly"
  - Emoji: ✨

- ✅ `lib/features/todo_list/domain/models/brief_section_with_todos.dart`
  - Helper class: BriefSection + List<Todo>
  - Používá se v TodoListState.briefSections getter

- ✅ `lib/features/todo_list/presentation/bloc/todo_list_state.dart` (UPDATED)
  - Přidány fields:
    - `aiBriefData: BriefResponse?`
    - `isGeneratingBrief: bool`
    - `briefError: String?`
  - Přidán computed getter: `briefSections` - mapuje task IDs na real Todo objekty
  - Rozšířen copyWith() - clearAiBriefData, isGeneratingBrief, briefError
  - Rozšířen props - obsahuje všechny nové fields

- ✅ `lib/features/todo_list/presentation/bloc/todo_list_event.dart` (UPDATED)
  - Přidán **RegenerateBriefEvent** (force regenerate, ignore cache)

---

## 🟡 ROZPRACOVÁNO (30%)

### 4. BLoC Integration - Event Handlers 🟡
**CO ZBÝVÁ:**

#### A) Upravit TodoListBloc constructor
Soubor: `lib/features/todo_list/presentation/bloc/todo_list_bloc.dart`

```dart
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;
  final AiBriefRepository _aiBriefRepository; // ← PŘIDAT

  // Cache pro Brief (1h validity)
  BriefResponse? _aiBriefCache; // ← PŘIDAT

  TodoListBloc(
    this._repository,
    this._aiBriefRepository, // ← PŘIDAT
  ) : super(const TodoListInitial()) {
    // ... existing handlers ...

    // ← PŘIDAT
    on<RegenerateBriefEvent>(_onRegenerateBrief);
  }
```

#### B) Upravit _onChangeViewMode handler
**Současný stav:** Handler jen mění viewMode, bez AI logiky

**CO PŘIDAT:**
```dart
void _onChangeViewMode(
  ChangeViewModeEvent event,
  Emitter<TodoListState> emit,
) async { // ← ZMĚNIT na async
  final currentState = state;
  if (currentState is! TodoListLoaded) return;

  // Pokud přepínáme NA aiBrief
  if (event.viewMode == ViewMode.aiBrief) {
    // ✅ Check cache first
    if (_aiBriefCache != null && _aiBriefCache!.isCacheValid) {
      emit(currentState.copyWith(
        viewMode: ViewMode.aiBrief,
        aiBriefData: _aiBriefCache,
        clearCustomView: true,
      ));
      return;
    }

    // ❌ Cache neexistuje nebo je starý → Generate new
    emit(currentState.copyWith(
      viewMode: ViewMode.aiBrief,
      isGeneratingBrief: true, // ← Loading state
      clearCustomView: true,
      clearBriefError: true,
    ));

    try {
      // Generovat Brief
      final briefResponse = await _aiBriefRepository.generateBrief(
        tasks: currentState.allTodos
            .where((t) => !t.isCompleted)
            .toList(),
        config: BriefConfig.defaultConfig(),
      );

      // Uložit cache
      _aiBriefCache = briefResponse;

      // Emit success state
      emit(currentState.copyWith(
        viewMode: ViewMode.aiBrief,
        aiBriefData: briefResponse,
        isGeneratingBrief: false,
        clearBriefError: true,
      ));
    } catch (e) {
      // Emit error state
      emit(currentState.copyWith(
        viewMode: ViewMode.aiBrief,
        isGeneratingBrief: false,
        briefError: e.toString(),
        clearAiBriefData: true,
      ));
    }
    return;
  }

  // Pro ostatní view modes (není aiBrief)
  emit(currentState.copyWith(
    viewMode: event.viewMode,
    clearCustomView: true,
  ));
}
```

#### C) Přidat _onRegenerateBrief handler
**Nový handler (force regenerate):**

```dart
Future<void> _onRegenerateBrief(
  RegenerateBriefEvent event,
  Emitter<TodoListState> emit,
) async {
  final currentState = state;
  if (currentState is! TodoListLoaded) return;

  // Ignorovat cache - vždy generovat nový
  emit(currentState.copyWith(
    isGeneratingBrief: true,
    clearBriefError: true,
  ));

  try {
    final briefResponse = await _aiBriefRepository.generateBrief(
      tasks: currentState.allTodos
          .where((t) => !t.isCompleted)
          .toList(),
      config: BriefConfig.defaultConfig(),
    );

    // Update cache
    _aiBriefCache = briefResponse;

    emit(currentState.copyWith(
      aiBriefData: briefResponse,
      isGeneratingBrief: false,
      clearBriefError: true,
    ));
  } catch (e) {
    emit(currentState.copyWith(
      isGeneratingBrief: false,
      briefError: e.toString(),
    ));
  }
}
```

---

## ❌ TODO (zbývá)

### 5. Dependency Injection (DI) ❌
**Soubor:** `lib/main.dart` nebo `lib/core/di/injection.dart`

**CO UDĚLAT:**
1. Najít kde se registruje TodoRepository (pravděpodobně get_it)
2. Přidat registraci AiBriefRepository:

```dart
// Register AI Brief dependencies
getIt.registerLazySingleton<BriefAiDatasource>(
  () => BriefAiDatasource(),
);

getIt.registerLazySingleton<AiBriefRepository>(
  () => AiBriefRepositoryImpl(
    db: getIt<DatabaseHelper>(),
    aiDatasource: getIt<BriefAiDatasource>(),
  ),
);
```

3. Upravit TodoListBloc factory - přidat _aiBriefRepository parametr

### 6. UI Implementation ❌

#### A) TodoListPage - Brief Tab
**Soubor:** Najít `lib/features/todo_list/presentation/pages/todo_list_page.dart`

**CO PŘIDAT:**
1. V horizontal scroll s view tabs přidat Brief tab:
```dart
_ViewTab(
  label: ViewMode.aiBrief.label, // "✨ Brief"
  icon: Icons.auto_awesome,
  isSelected: state.viewMode == ViewMode.aiBrief,
  onTap: () => context.read<TodoListBloc>().add(
    ChangeViewModeEvent(ViewMode.aiBrief),
  ),
),
```

2. V build body přidat conditional rendering:
```dart
// Pokud viewMode == aiBrief → zobraz Brief view
if (state.viewMode == ViewMode.aiBrief) {
  return _buildBriefView(context, state);
}

// Jinak → normální ListView
return _buildNormalListView(context, state);
```

3. Implementovat _buildBriefView():
```dart
Widget _buildBriefView(BuildContext context, TodoListLoaded state) {
  // Loading state
  if (state.isGeneratingBrief) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generuji AI Brief...'),
          Text('Trvá 3-5 sekund', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // Error state
  if (state.briefError != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Chyba při generování briefu'),
          SizedBox(height: 8),
          Text(state.briefError!, style: TextStyle(fontSize: 12)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<TodoListBloc>().add(
              RegenerateBriefEvent(),
            ),
            child: Text('Zkusit znovu'),
          ),
        ],
      ),
    );
  }

  // No data yet
  if (state.briefSections == null) {
    return Center(child: Text('Načítám Brief...'));
  }

  // Brief sections s TodoCards
  return ListView.builder(
    padding: EdgeInsets.all(8),
    itemCount: state.briefSections!.length,
    itemBuilder: (context, index) {
      final sectionData = state.briefSections![index];
      return BriefSectionWidget(
        section: sectionData.section,
        todos: sectionData.todos,
      );
    },
  );
}
```

#### B) BriefSectionWidget
**Vytvořit nový soubor:** `lib/features/todo_list/presentation/widgets/brief_section_widget.dart`

```dart
import 'package:flutter/material.dart';
import '../../../ai_brief/domain/entities/brief_section.dart';
import '../../domain/entities/todo.dart';
import 'todo_card.dart'; // ← Použít existující TodoCard!

class BriefSectionWidget extends StatelessWidget {
  final BriefSection section;
  final List<Todo> todos;

  const BriefSectionWidget({
    required this.section,
    required this.todos,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Commentary Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _getSectionColor(section.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSectionColor(section.type).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getSectionColor(section.type),
                ),
              ),
              SizedBox(height: 8),
              // AI Commentary
              Text(
                section.commentary,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),

        // Real TodoCards (user může hned pracovat!)
        if (todos.isNotEmpty)
          ...todos.map((todo) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: TodoCard(
              key: ValueKey('todo_${todo.id}'),
              todo: todo,
              // isExpanded: state.expandedTodoId == todo.id,
            ),
          )),

        // Spacing mezi sekcemi
        SizedBox(height: 16),
      ],
    );
  }

  Color _getSectionColor(String type) {
    switch (type) {
      case 'focus_now':
        return Colors.orange;
      case 'key_insights':
        return Colors.blue;
      case 'motivation':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
```

### 7. Testing ❌
**Vytvořit:** `test/features/ai_brief/domain/entities/brief_response_test.dart`

```dart
test('BriefResponse.fromJson parses correctly', () { ... });
test('validate removes invalid task IDs', () { ... });
test('isCacheValid returns true for fresh data', () { ... });
```

### 8. Final Commit ❌
```bash
git add -A && git commit -m "✨ feat: AI Brief - inteligentní filtrování úkolů v Agenda view

- Brief jako nový ViewMode tab (All, Today, Week, Overdue, Brief)
- AI vrací JSON s task IDs + komentáře (focus_now, key_insights, motivation)
- Zobrazí real TodoCards (user může hned pracovat - done, edit, pomodoro)
- Cache 1h + validace task IDs (anti-hallucination)
- Cost: ~\$0.009 per brief
- Uses: OpenRouter API (Claude 3.5 Sonnet)

Domain Layer:
- BriefSection, BriefResponse, BriefConfig entities
- AiBriefRepository interface

Data Layer:
- BriefAiDatasource (OpenRouter client)
- BriefContextBuilder (strukturovaný task list pro AI)
- AiBriefRepositoryImpl (parsing + validation)

BLoC Integration:
- ViewMode.aiBrief enum value
- TodoListState extended (aiBriefData, isGeneratingBrief, briefError)
- RegenerateBriefEvent
- Event handlers s 1h cache logikou

UI:
- Brief tab v TodoListPage
- BriefSectionWidget (AI commentary + TodoCards)
- Loading + Error states

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 📊 Statistiky

**Soubory vytvořeny:** 9
**Soubory upraveny:** 4
**Řádky kódu:** ~1200+
**Effort:** ~6-8h práce (70% hotovo v této session)

**Zbývá:** ~2-3h práce
- Event handlers: 1h
- DI registration: 15 min
- UI implementation: 1-1.5h
- Testing: 30 min
- Final commit + smoke test: 15 min

---

## 🔑 Klíčové soubory pro pokračování

1. **TodoListBloc** - `lib/features/todo_list/presentation/bloc/todo_list_bloc.dart`
   - Přidat AiBriefRepository dependency
   - Upravit _onChangeViewMode (přidat AI logiku)
   - Přidat _onRegenerateBrief handler

2. **DI / main.dart** - najít kde se registrují dependencies
   - Registrovat BriefAiDatasource
   - Registrovat AiBriefRepository

3. **TodoListPage** - najít `lib/features/todo_list/presentation/pages/todo_list_page.dart`
   - Přidat Brief tab
   - Implementovat _buildBriefView()

4. **BriefSectionWidget** - vytvořit nový widget
   - AI commentary header
   - Real TodoCards

---

## ⚠️ DŮLEŽITÉ POZNÁMKY

1. **Brief není samostatná stránka!** Je to ViewMode v TodoListPage (jako Today, Week)
2. **Real TodoCards** - použít existující TodoCard widget, ne vytvářet nový
3. **Cache je klíčový** - 1h validity saves money (~$0.009 per brief)
4. **Validation je povinná** - AI může hallucinate task IDs
5. **System prompt je v BriefAiDatasource** - už implementovaný
6. **Context Builder je hotový** - sestaví strukturovaný task list pro AI

---

## 🚀 Next Steps (v nové session)

```bash
# 1. Otevři TodoListBloc
code lib/features/todo_list/presentation/bloc/todo_list_bloc.dart

# 2. Přidej AiBriefRepository dependency + cache field
# 3. Uprav _onChangeViewMode handler (přidat AI logiku)
# 4. Přidej _onRegenerateBrief handler
# 5. Registruj DI (najít kde se registruje TodoRepository)
# 6. Implementuj UI (TodoListPage + BriefSectionWidget)
# 7. Test + commit
```

**Až to spustíš v nové session, řekni:**
> "Pokračuj s implementací AI Brief podle AI_BRIEF_PROGRESS.md - začni TodoListBloc event handlers"

---

**Created:** 2025-10-13
**Token Budget Used:** ~116k / 200k
**Status:** Ready for continuation 🚀
