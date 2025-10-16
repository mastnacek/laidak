# AI Brief - Inteligentní filtrování úkolů

**Feature Type**: AI-powered task filtering v Agenda view
**Priority**: ⭐⭐⭐ High (Killer feature)
**Effort**: 6-8h (MVP), 10-12h (polished)
**Status**: 📝 Design & Analysis Phase
**Created**: 2025-10-12
**Updated**: 2025-10-13

---

## 🎯 Cíl a hodnota pro uživatele

### Problém
- **Information Overload**: Uživatel má 50+ aktivních úkolů → ztráta orientace
- **Decision Paralysis**: Co dělat TEĎ? Čím začít?
- **Missing Big Picture**: Jak spolu úkoly souvisí? Jaké jsou dependencies?
- **Neefektivní prioritizace**: Urgentní ≠ důležité

### Řešení - AI Brief View
- **On-demand filter**: User klikne "Brief" button → AI instantly filtruje úkoly
- **Inteligentní sekce**: Focus Now (top 3), Key Insights, Motivation
- **Real TodoCards**: Pracuješ s normálními úkoly (done, edit, pomodoro)
- **AI komentář**: Nad každou sekcí vysvětlení PROČ tyto úkoly
- **No navigation**: Všechno na jednom místě, žádné clickable linky

### Rozdíl od existujících features

| Feature | Scope | Interakce | Cíl |
|---------|-------|-----------|-----|
| **AI Chat** | 1 úkol | Konverzační | Diskuze NAD konkrétním úkolem |
| **AI Brief** | Všechny úkoly | View filter | Smart prioritizace + zobrazení |
| **AI Split** | 1 úkol | One-shot | Rozklad úkolu na podúkoly |
| **Agenda views** | Filtr (Today, Week) | Statický | Čas-based filter |

---

## 🏗️ Architektura - Brief jako AgendaView Filter

### Koncept

Brief je **nový typ Agenda view** (jako Today, This Week, Overdue), ale **inteligentně filtrovaný AI**:

```
┌─────────────────────────────────────────┐
│ TodoListPage                            │
│                                         │
│ [All] [Today] [Week] [Overdue] [Brief] │ ← Brief tab
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎯 FOCUS NOW                        │ │ ← AI commentary
│ │ "Tyhle 3 úkoly jsou teď nejdůležitější" │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Task 5: Dokončit prezentaci       │ │ ← Real TodoCard
│ │   Priority: A, Due: 14:00           │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Task 12: Code review PR #123      │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Task 8: Call s klientem           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📊 KEY INSIGHTS                     │ │ ← AI commentary
│ │ "Úkol 5 blokuje 12 a 18"           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Task 22: Feature X                │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Task 7: Update docs               │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 💪 MOTIVATION                       │ │ ← AI motivation
│ │ "Skvěle! Ještě 3 úkoly a máš rekord!"│
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Klíčové: User vidí REAL TodoCards, může hned editovat, označit done, spustit pomodoro!**

---

### File Structure

```
lib/features/ai_brief/
├── presentation/
│   ├── widgets/
│   │   ├── brief_section_header.dart      # AI komentář nad sekcí
│   │   ├── brief_loading_indicator.dart   # Loading (AI generuje)
│   │   └── brief_error_widget.dart        # Error state
│   └── bloc/
│       ├── ai_brief_bloc.dart
│       ├── ai_brief_event.dart
│       └── ai_brief_state.dart
├── domain/
│   ├── entities/
│   │   ├── brief_config.dart              # User settings
│   │   ├── brief_response.dart            # AI response entity
│   │   └── brief_section.dart             # Section (title, commentary, task IDs)
│   └── repositories/
│       └── ai_brief_repository.dart       # Repository interface
└── data/
    ├── datasources/
    │   ├── brief_ai_datasource.dart       # OpenRouter API client
    │   └── brief_db_datasource.dart       # DB queries (tasks)
    └── repositories/
        └── ai_brief_repository_impl.dart
```

---

## 📊 Data Flow

### 1. User klikne "Brief" tab

```dart
// TodoListPage - Brief tab selected
onPressed: () {
  context.read<TodoListBloc>().add(
    ChangeViewModeEvent(ViewMode.aiBrief),
  );
}
```

### 2. BLoC spustí AI generaci

```dart
sealed class TodoListEvent {}

class ChangeViewModeEvent extends TodoListEvent {
  final ViewMode mode; // all, today, week, overdue, aiBrief
}

// V BLoC handler:
if (event is ChangeViewModeEvent && event.mode == ViewMode.aiBrief) {
  // Check cache first
  if (_aiBriefCache != null && _aiBriefCache!.isValid) {
    emit(state.copyWith(
      currentView: ViewMode.aiBrief,
      aiBriefData: _aiBriefCache,
    ));
    return;
  }

  // Generate new brief
  emit(state.copyWith(
    currentView: ViewMode.aiBrief,
    isGeneratingBrief: true,
  ));

  final briefResponse = await _aiBriefRepository.generateBrief(
    tasks: state.todos,
    config: _briefConfig,
  );

  _aiBriefCache = briefResponse;

  emit(state.copyWith(
    aiBriefData: briefResponse,
    isGeneratingBrief: false,
  ));
}
```

### 3. Sestavit AI prompt

**System Prompt** (stručný, konkrétní):

```dart
const String BRIEF_SYSTEM_PROMPT = '''
You are a task prioritization assistant. Analyze the user's tasks and return a structured JSON response.

# OBJECTIVE
Help user understand:
1. What to do RIGHT NOW (top 3 tasks)
2. Key insights (dependencies, patterns)
3. Motivation (progress, encouragement)

# INPUT FORMAT
You will receive tasks in this format:

TASK_ID: 5
Text: Dokončit prezentaci pro klienta
Priority: a (high)
Due Date: 2025-10-13 14:00 (in 2 hours)
Subtasks: 2/5 completed
Status: active
Tags: work, urgent

# OUTPUT FORMAT (JSON)

{
  "sections": [
    {
      "type": "focus_now",
      "title": "🎯 FOCUS NOW",
      "commentary": "Tyhle 3 úkoly jsou teď nejdůležitější",
      "task_ids": [5, 12, 8]
    },
    {
      "type": "key_insights",
      "title": "📊 KEY INSIGHTS",
      "commentary": "Úkol 5 blokuje 12 a 18. Udělej ho první!",
      "task_ids": [5, 12, 18, 22]
    },
    {
      "type": "motivation",
      "title": "💪 MOTIVATION",
      "commentary": "Skvěle! Dokončil jsi 3 úkoly dnes. Ještě *5* a máš rekord týdne!",
      "task_ids": [3, 7, 11]
    }
  ],
  "generated_at": "2025-10-13T10:30:00Z"
}

# ANALYSIS RULES

## Focus Now (top 3)
- Pick 3 most important tasks RIGHT NOW
- Consider: deadline urgency, priority, blocking others
- Max 3 tasks (not more!)
- **Pravidlo č. 2**: Maximálně 3 úkoly na den = realistický plán

## Key Insights (optional section)
- Identify dependencies (task A blocks task B)
- Find quick wins (easy + high impact)
- Warn about conflicts (overlapping deadlines)
- List ALL tasks mentioned in insights

## Motivation (always include)
- Celebrate progress (completed tasks today/this week)
- Include task_ids of completed tasks that you mention
- Encourage next steps
- Reference specific completed tasks in commentary
- **Pravidlo č. 7**: Předpokládej nedokončení - "15 úkolů ve frontě je OK!"

# PRODUCTIVITY RULES (APPLY ALWAYS)

## Pravidlo č. 3: Detekce akčních sloves
- **Akční slovesa** (✅ GOOD): napsat, zavolat, odpovědět, naplánovat, najít, vyhledat, odeslat, připravit
- **Vágní slovesa** (⚠️ WARNING): přemýšlet, zvážit, zkoumat, revize, pochopit
- **Content consumption** (⚠️ WARNING): číst, sledovat, poslouchat

Když detekuješ vágní sloveso:
- Přidej **warning v commentary**: "Úkol X má vágní popis - doporuč přeformulovat"
- Navrhni konkrétní akci: "Zvážit nákup auta" → "Najít 3 nabídky na auta"

Když detekuješ "číst/sledovat/poslouchat":
- Přidej **poznámku v Insights**: "Úkoly typu 'číst článek' nejsou prioritní - přesuň do Readwise/Pocket"
- NEZAHRŇ tyto úkoly do FOCUS NOW!

## Pravidlo č. 4: Relevantní informace
- Pokud úkol nemá kontext (odkaz, email, tel.), varuj:
  - "Úkol X chybí relevantní info - doplň odkaz/kontakt"

## Pravidlo č. 6: Řiďte se energií
- **HIGH-ENERGY úkoly** (ráno): tagy *high-energy*, *deep-work*, složité mentální úkoly
- **LOW-ENERGY úkoly** (odpoledne): tagy *low-energy*, *phone*, *email*, rutinní práce

Pokud detekuješ energy pattern, přidej sekci:
```json
{
  "type": "morning_deep_work",
  "title": "🧠 MORNING DEEP WORK",
  "commentary": "Ráno = vysoká energie → ideální pro soustředěnou práci",
  "task_ids": [úkoly s *high-energy* nebo složité]
}
```

```json
{
  "type": "afternoon_tasks",
  "title": "😌 AFTERNOON TASKS",
  "commentary": "Odpoledne = nízká energie → lehké úkoly (hovory, emaily)",
  "task_ids": [úkoly s *low-energy*, *phone*, *email*]
}
```

# IMPORTANT
- Return ONLY valid JSON (no markdown, no extra text)
- task_ids MUST be integers from input
- commentary MUST be in Czech
- Be concise (max 2 sentences per commentary)
- Apply productivity rules in commentary (varování, doporučení)
''';
```

**User Context** (strukturovaný seznam):

```dart
String _buildUserContext(List<Todo> tasks) {
  final buffer = StringBuffer();
  final now = DateTime.now();

  buffer.writeln('CURRENT TIME: ${now.toIso8601String()}');
  buffer.writeln('DAY: ${_getDayOfWeek(now)} (${_formatDate(now)})');
  buffer.writeln('\n--- TASKS ---\n');

  // Filter: jen aktivní úkoly
  final activeTasks = tasks.where((t) => !t.isCompleted).toList();

  for (final task in activeTasks) {
    buffer.writeln('TASK_ID: ${task.id}');
    buffer.writeln('Text: ${task.task}');
    buffer.writeln('Priority: ${task.priority ?? "none"} (a=high, b=medium, c=low)');

    if (task.dueDate != null) {
      final hoursUntil = task.dueDate!.difference(now).inHours;
      final daysUntil = task.dueDate!.difference(now).inDays;

      String urgency;
      if (hoursUntil < 0) {
        urgency = 'OVERDUE by ${-hoursUntil}h';
      } else if (hoursUntil < 2) {
        urgency = 'in ${hoursUntil}h (URGENT!)';
      } else if (daysUntil == 0) {
        urgency = 'today at ${_formatTime(task.dueDate!)}';
      } else {
        urgency = 'in ${daysUntil} days';
      }

      buffer.writeln('Due Date: ${_formatDateTime(task.dueDate!)} ($urgency)');
    } else {
      buffer.writeln('Due Date: none');
    }

    // Subtasks
    if (task.subtasks != null && task.subtasks!.isNotEmpty) {
      final completed = task.subtasks!.where((s) => s.completed).length;
      final total = task.subtasks!.length;
      buffer.writeln('Subtasks: $completed/$total completed');
    }

    buffer.writeln('Status: ${task.isCompleted ? "completed" : "active"}');
    buffer.writeln('Tags: ${task.tags.isEmpty ? "none" : task.tags.join(", ")}');
    buffer.writeln('');
  }

  // Stats
  final completedToday = tasks.where((t) =>
    t.isCompleted &&
    t.completedAt != null &&
    _isToday(t.completedAt!)
  ).length;

  buffer.writeln('\n--- USER STATS ---\n');
  buffer.writeln('Completed today: $completedToday tasks');
  buffer.writeln('Active tasks: ${activeTasks.length}');

  return buffer.toString();
}
```

### 4. AI vrací JSON

```json
{
  "sections": [
    {
      "type": "focus_now",
      "title": "🎯 FOCUS NOW",
      "commentary": "Tyhle 3 úkoly jsou teď nejdůležitější. Prezentace má deadline za 2h!",
      "task_ids": [5, 12, 8]
    },
    {
      "type": "key_insights",
      "title": "📊 KEY INSIGHTS",
      "commentary": "Úkol 5 blokuje 12 a 18. Review PR (12) je quick win - 15 minut.",
      "task_ids": [5, 12, 18, 22]
    },
    {
      "type": "motivation",
      "title": "💪 MOTIVATION",
      "commentary": "Skvělý progress! Dokončil jsi 3 úkoly dnes. Ještě 5 a máš rekord týdne! 🚀",
      "task_ids": [3, 7, 11]
    }
  ],
  "generated_at": "2025-10-13T10:30:00Z"
}
```

### 5. Parse + Validate

```dart
class BriefResponse {
  final List<BriefSection> sections;
  final DateTime generatedAt;

  const BriefResponse({
    required this.sections,
    required this.generatedAt,
  });

  factory BriefResponse.fromJson(Map<String, dynamic> json) {
    return BriefResponse(
      sections: (json['sections'] as List)
          .map((s) => BriefSection.fromJson(s))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }

  // Validate task IDs proti DB
  Future<BriefResponse> validate(DatabaseHelper db) async {
    final validatedSections = <BriefSection>[];

    for (final section in sections) {
      final validIds = <int>[];

      for (final id in section.taskIds) {
        final exists = await db.todoExists(id);
        if (exists) {
          validIds.add(id);
        } else {
          AppLogger.warn('⚠️ AI hallucination: task $id not found');
        }
      }

      validatedSections.add(section.copyWith(taskIds: validIds));
    }

    return BriefResponse(
      sections: validatedSections,
      generatedAt: generatedAt,
    );
  }

  // Cache validity check
  bool get isCacheValid {
    final now = DateTime.now();
    return now.difference(generatedAt) < Duration(hours: 1);
  }
}

class BriefSection {
  final String type;        // focus_now, key_insights, motivation
  final String title;       // "🎯 FOCUS NOW"
  final String commentary;  // AI komentář
  final List<int> taskIds;  // [5, 12, 8]

  const BriefSection({
    required this.type,
    required this.title,
    required this.commentary,
    required this.taskIds,
  });

  factory BriefSection.fromJson(Map<String, dynamic> json) {
    return BriefSection(
      type: json['type'],
      title: json['title'],
      commentary: json['commentary'],
      taskIds: (json['task_ids'] as List).cast<int>(),
    );
  }

  BriefSection copyWith({List<int>? taskIds}) {
    return BriefSection(
      type: type,
      title: title,
      commentary: commentary,
      taskIds: taskIds ?? this.taskIds,
    );
  }
}
```

---

## 🎨 UI Implementation

### TodoListState (extended)

```dart
class TodoListState extends Equatable {
  final List<Todo> todos;
  final Filter currentFilter;
  final SortOrder sortOrder;
  final ViewMode currentView;          // NEW: all, today, week, overdue, aiBrief

  // AI Brief specific
  final BriefResponse? aiBriefData;    // NEW: AI response
  final bool isGeneratingBrief;        // NEW: Loading state
  final String? briefError;            // NEW: Error message

  // Computed: zobrazené todos (podle view mode)
  List<Todo> get displayedTodos {
    switch (currentView) {
      case ViewMode.all:
        return applyFiltersAndSort(todos);

      case ViewMode.today:
        return applyFiltersAndSort(
          todos.where((t) => t.dueDate != null && _isToday(t.dueDate!)).toList()
        );

      case ViewMode.week:
        return applyFiltersAndSort(
          todos.where((t) => t.dueDate != null && _isThisWeek(t.dueDate!)).toList()
        );

      case ViewMode.overdue:
        return applyFiltersAndSort(
          todos.where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).toList()
        );

      case ViewMode.aiBrief:
        // Special case: Brief view displays todos in sections
        // (handled in UI, not here)
        return todos;
    }
  }

  // Computed: Brief sections s real Todo objekty
  List<BriefSectionWithTodos>? get briefSections {
    if (aiBriefData == null) return null;

    return aiBriefData!.sections.map((section) {
      // Map task IDs to real Todo objects
      final sectionTodos = section.taskIds
          .map((id) => todos.firstWhere((t) => t.id == id, orElse: () => null))
          .whereType<Todo>()
          .toList();

      return BriefSectionWithTodos(
        section: section,
        todos: sectionTodos,
      );
    }).toList();
  }
}

enum ViewMode {
  all,
  today,
  week,
  overdue,
  aiBrief,  // NEW
}

class BriefSectionWithTodos {
  final BriefSection section;
  final List<Todo> todos;

  const BriefSectionWithTodos({
    required this.section,
    required this.todos,
  });
}
```

### TodoListPage - Brief Tab

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getViewTitle(state.currentView)),
            actions: [
              // Refresh button (jen pro Brief view)
              if (state.currentView == ViewMode.aiBrief)
                IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Regenerovat Brief',
                  onPressed: () {
                    _showRegenerateConfirmation(context);
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // View mode tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ViewTab(
                      label: 'All',
                      icon: Icons.list,
                      isSelected: state.currentView == ViewMode.all,
                      onTap: () => _changeView(context, ViewMode.all),
                    ),
                    _ViewTab(
                      label: 'Today',
                      icon: Icons.today,
                      isSelected: state.currentView == ViewMode.today,
                      onTap: () => _changeView(context, ViewMode.today),
                    ),
                    _ViewTab(
                      label: 'Week',
                      icon: Icons.calendar_view_week,
                      isSelected: state.currentView == ViewMode.week,
                      onTap: () => _changeView(context, ViewMode.week),
                    ),
                    _ViewTab(
                      label: 'Overdue',
                      icon: Icons.warning,
                      isSelected: state.currentView == ViewMode.overdue,
                      onTap: () => _changeView(context, ViewMode.overdue),
                    ),
                    _ViewTab(
                      label: 'Brief',
                      icon: Icons.auto_awesome, // ✨ sparkle icon
                      isSelected: state.currentView == ViewMode.aiBrief,
                      onTap: () => _changeView(context, ViewMode.aiBrief),
                    ),
                  ],
                ),
              ),

              // Content (Brief view OR normal list)
              Expanded(
                child: state.currentView == ViewMode.aiBrief
                    ? _buildBriefView(context, state)
                    : _buildNormalListView(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBriefView(BuildContext context, TodoListState state) {
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
              onPressed: () => _changeView(context, ViewMode.aiBrief), // retry
              child: Text('Zkusit znovu'),
            ),
          ],
        ),
      );
    }

    // No data yet
    if (state.briefSections == null) {
      return Center(
        child: Text('Načítám Brief...'),
      );
    }

    // Brief sections s TodoCards
    return ListView.builder(
      padding: EdgeInsets.all(8),
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

  Widget _buildNormalListView(BuildContext context, TodoListState state) {
    final todos = state.displayedTodos;

    if (todos.isEmpty) {
      return Center(child: Text('Žádné úkoly'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoCard(
          key: ValueKey('todo_${todo.id}'),
          todo: todo,
          isExpanded: state.expandedTodoId == todo.id,
        );
      },
    );
  }

  void _changeView(BuildContext context, ViewMode mode) {
    context.read<TodoListBloc>().add(ChangeViewModeEvent(mode));
  }

  void _showRegenerateConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Regenerovat Brief?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tato akce spotřebuje API tokeny.'),
            SizedBox(height: 8),
            Text('Odhadované náklady: ~\$0.02', style: TextStyle(fontSize: 12)),
            SizedBox(height: 8),
            Text('Brief je validní ještě X minut.', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TodoListBloc>().add(RegenerateBriefEvent());
            },
            child: Text('Regenerovat'),
          ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### BriefSectionWidget - Section s TodoCards

```dart
class _BriefSectionWidget extends StatelessWidget {
  final BriefSection section;
  final List<Todo> todos;

  const _BriefSectionWidget({
    required this.section,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header (AI komentář)
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

        // TodoCards (pokud jsou task IDs)
        if (todos.isNotEmpty)
          ...todos.map((todo) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: TodoCard(
              key: ValueKey('todo_${todo.id}'),
              todo: todo,
              isExpanded: false, // TODO: manage expand state
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

---

## 🔧 BLoC Events

```dart
sealed class TodoListEvent {}

class ChangeViewModeEvent extends TodoListEvent {
  final ViewMode mode;

  ChangeViewModeEvent(this.mode);
}

class RegenerateBriefEvent extends TodoListEvent {
  // Force regenerate (ignore cache)
}

class LoadCachedBriefEvent extends TodoListEvent {
  // Try to load from cache first
}
```

---

## 📊 Cost Analysis

### API Cost (OpenRouter - Claude 3.5 Sonnet)

**Pricing:**
- Input: **$3** per million tokens
- Output: **$15** per million tokens

**Average Brief:**
- Input: ~1500 tokens (tasks list + stats)
- Output: ~300 tokens (JSON response)
- **Cost per brief: ~$0.009** (0.9 cents)

**User Budget:**
- 50 briefs/month = **$0.45/month**
- WITH 1-hour cache: ~10 actual API calls/month = **$0.09/month**

**Sustainable!** ✅

---

## 📅 Implementační plán

### Phase 1: MVP (6-8 hodin)

#### Krok 1: Domain Layer (1.5h)
- [ ] `BriefResponse` entity (sections, generatedAt)
- [ ] `BriefSection` entity (type, title, commentary, taskIds)
- [ ] `BriefConfig` entity (settings)
- [ ] Repository interface

#### Krok 2: Data Layer (2h)
- [ ] `BriefAiDatasource` - OpenRouter API client
- [ ] System prompt konstanta
- [ ] User context builder (structured task list)
- [ ] JSON parsing + validation

#### Krok 3: BLoC Integration (2h)
- [ ] Extend `TodoListState` (aiBriefData, isGeneratingBrief, briefError)
- [ ] Add `ViewMode.aiBrief` enum
- [ ] Event handlers (ChangeViewMode, RegenerateBrief)
- [ ] Cache logic (1-hour validity)

#### Krok 4: UI (2.5h)
- [ ] Brief tab v TodoListPage
- [ ] `_BriefSectionWidget` (section header + TodoCards)
- [ ] Loading state widget
- [ ] Error state widget
- [ ] Regenerate confirmation dialog

**Deliverable**: Funkční AI Brief view s real TodoCards ✅

---

### Phase 2: Polish (2-4 hodiny)

#### Krok 5: Settings (1h)
- [ ] Brief settings page (context options, cache validity)
- [ ] `BriefConfig` persistence (SharedPreferences)
- [ ] Default config

#### Krok 6: Optimization (1h)
- [ ] Rate limiting (max 1 generate per 5 min)
- [ ] Cost tracking (DB counter)
- [ ] Cache indicator v UI

#### Krok 7: Error Handling (1h)
- [ ] AI hallucination detection (invalid task IDs)
- [ ] Fallback při API failure
- [ ] User-friendly error messages

**Deliverable**: Polished UX + settings ✅

---

## 🧪 Testing Strategy

### Unit Tests

```dart
group('BriefResponse', () {
  test('fromJson parses correctly', () {
    const json = {
      'sections': [
        {
          'type': 'focus_now',
          'title': '🎯 FOCUS NOW',
          'commentary': 'Top 3 tasks',
          'task_ids': [5, 12, 8],
        }
      ],
      'generated_at': '2025-10-13T10:30:00Z',
    };

    final response = BriefResponse.fromJson(json);

    expect(response.sections.length, 1);
    expect(response.sections[0].taskIds, [5, 12, 8]);
  });

  test('validate removes invalid task IDs', () async {
    final db = MockDatabaseHelper();
    when(db.todoExists(5)).thenAnswer((_) async => true);
    when(db.todoExists(99)).thenAnswer((_) async => false);

    final response = BriefResponse(
      sections: [
        BriefSection(
          type: 'focus_now',
          title: 'Test',
          commentary: 'Test',
          taskIds: [5, 99],
        ),
      ],
      generatedAt: DateTime.now(),
    );

    final validated = await response.validate(db);

    expect(validated.sections[0].taskIds, [5]);
  });
});
```

### Widget Tests

```dart
testWidgets('Brief view displays sections with TodoCards', (tester) async {
  final bloc = MockTodoListBloc();

  when(bloc.state).thenReturn(TodoListState(
    todos: [
      Todo(id: 5, task: 'Task 5'),
      Todo(id: 12, task: 'Task 12'),
    ],
    currentView: ViewMode.aiBrief,
    aiBriefData: BriefResponse(
      sections: [
        BriefSection(
          type: 'focus_now',
          title: '🎯 FOCUS NOW',
          commentary: 'Top 2 tasks',
          taskIds: [5, 12],
        ),
      ],
      generatedAt: DateTime.now(),
    ),
  ));

  await tester.pumpWidget(MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: TodoListPage(),
    ),
  ));

  // Should show section header
  expect(find.text('🎯 FOCUS NOW'), findsOneWidget);
  expect(find.text('Top 2 tasks'), findsOneWidget);

  // Should show TodoCards
  expect(find.text('Task 5'), findsOneWidget);
  expect(find.text('Task 12'), findsOneWidget);
});
```

---

## 🎯 Závěr

### Proč je to elegantní řešení?

1. **Minimální UI changes**: Brief je jen další Agenda view tab
2. **Reuses existing components**: TodoCard, expand logic, done action - vše funguje!
3. **No navigation**: User vidí všechno na jednom místě
4. **AI má jasné instrukce**: Vrať JSON s task IDs + komentář
5. **Low cost**: ~$0.009 per brief (levnější než markdown brief)
6. **Fast implementation**: 6-8h (vs 8-10h původní design)

### Next Steps

1. ✅ **Schválit design** (tento dokument)
2. 🚀 **Implementovat MVP** (6-8h)
3. 🧪 **Testovat** (user feedback)
4. 📊 **Měřit úspěch** (usage rate, cache hit rate)

---

**Version**: 2.0
**Created**: 2025-10-12
**Updated**: 2025-10-13 (redesign: Brief jako AgendaView filter)
**Author**: Claude Code (AI Assistant)
**Status**: 📝 Design Complete - Ready for implementation

---

🎯 **Ready to build!** Brief view = inteligentní filtr nad existujícími úkoly! 🚀
