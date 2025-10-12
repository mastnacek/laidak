# Daily Brief - AI-Powered Task Planning Assistant

**Feature Type**: AI-powered morning briefing + strategic task overview
**Priority**: ⭐⭐⭐ High (Killer feature)
**Effort**: 8-10h (MVP), 12-16h (polished)
**Status**: 📝 Design & Analysis Phase
**Created**: 2025-10-12

---

## 🎯 Cíl a hodnota pro uživatele

### Problém
- **Information Overload**: Uživatel má 50+ aktivních úkolů → ztráta orientace
- **Decision Paralysis**: Co dělat TEĎ? Čím začít?
- **Missing Big Picture**: Jak spolu úkoly souvisí? Jaké jsou dependencies?
- **Neefektivní prioritizace**: Urgentní ≠ důležité

### Řešení - Daily Brief
- **Morning Routine**: "Start My Day" - AI ti řekne co dnes dělat
- **Strategic Overview**: Souvislosti mezi úkoly (úkol 5 vyřeší podúkol 3.1)
- **Smart Prioritization**: AI doporučí pořadí na základě deadlines + dependencies
- **Weekly Planning**: Přehled na týden dopředu
- **Clickable Navigation**: Proklik na úkol přímo z briefu (*5* → jump to task 5)

### Rozdíl od existujících features

| Feature | Scope | Interakce | Cíl |
|---------|-------|-----------|-----|
| **AI Chat** | 1 úkol | Konverzační | Diskuze NAD konkrétním úkolem |
| **Daily Brief** | Všechny úkoly | Statický přehled | Strategický overview + prioritizace |
| **AI Split** | 1 úkol | One-shot | Rozklad úkolu na podúkoly |

---

## 🔍 Competitive Research

### Trevor AI - "Start My Day" Email
- ✅ **Wake-up progress reviews** (denní email)
- ✅ **Personalized insights** (na míru uživateli)
- ✅ **AI coaching** (motivace + tipy)
- ❌ Subscription $40/měsíc

### Motion - AI Day Planner
- ✅ **Continuous analysis** (deadlines, workload, availability)
- ✅ **Adaptive planning** (mění se podle priorit)
- ✅ **Auto-scheduling** (naplánuje den za tebe)
- ❌ Subscription $19/měsíc

### Morgen - AI Calendar Integration
- ✅ **Optimal time scheduling** (naplánuje úkoly na nejlepší čas)
- ✅ **Multi-calendar sync** (Google, Outlook, etc.)
- ❌ Omezená task management funkcionalita

### Org-mode - Traditional Agenda
- ✅ **Agenda view** (day/week/month)
- ✅ **Linked to source** (proklik zpět na úkol v souboru)
- ✅ **Free & open source**
- ❌ Bez AI - statický přehled

### Naše USP (Unique Selling Proposition)
1. **Plně customizable** - user řídí co AI vidí (completed tasks, subtasks, ai_recommendations)
2. **Task linking** - prokliknutelné úkoly přímo z briefu (*5* → jump to task)
3. **Open source** - žádné subscription fees (jen API cost ~$0.02/brief)
4. **Dependency intelligence** - AI najde vazby mezi úkoly (completing X unblocks Y)
5. **Integrated** - všechno v jedné aplikaci (ne external email/calendar)

---

## 🏗️ Architektura - Feature-First + BLoC

```
lib/features/daily_brief/
├── presentation/
│   ├── pages/
│   │   └── daily_brief_page.dart         # Fullscreen briefing view
│   ├── widgets/
│   │   ├── brief_section.dart            # Section (Today, This Week, etc.)
│   │   ├── task_link_widget.dart         # Clickable *5* → úkol 5
│   │   ├── brief_markdown_view.dart      # Markdown renderer s custom links
│   │   ├── brief_loading.dart            # Loading state (AI generation)
│   │   └── regenerate_button.dart        # Refresh briefing (with confirmation)
│   └── bloc/
│       ├── daily_brief_bloc.dart
│       ├── daily_brief_event.dart
│       └── daily_brief_state.dart
├── domain/
│   ├── entities/
│   │   ├── brief_config.dart             # User configuration (settings)
│   │   ├── brief_response.dart           # AI response entity
│   │   └── task_context.dart             # Context builder (tasks + metadata)
│   └── repositories/
│       └── daily_brief_repository.dart   # Repository interface
└── data/
    ├── datasources/
    │   ├── brief_datasource.dart         # OpenRouter API client
    │   └── brief_db_datasource.dart      # DB queries (tasks, subtasks, etc.)
    └── repositories/
        └── daily_brief_repository_impl.dart
```

### BLoC Design

**Events:**
```dart
sealed class DailyBriefEvent {}

class GenerateBriefEvent extends DailyBriefEvent {
  final BriefConfig config;
}

class RegenerateBriefEvent extends DailyBriefEvent {
  // Force regenerate (ignore cache)
}

class LoadCachedBriefEvent extends DailyBriefEvent {
  // Load last generated brief
}
```

**States:**
```dart
sealed class DailyBriefState {}

class BriefInitial extends DailyBriefState {}

class BriefLoading extends DailyBriefState {
  final String? message; // "Načítám úkoly...", "Generuji brief..."
}

class BriefLoaded extends DailyBriefState {
  final BriefResponse response;
  final DateTime generatedAt;

  // Cache valid for 1 hour
  bool get isCacheValid {
    final now = DateTime.now();
    return now.difference(generatedAt) < Duration(hours: 1);
  }
}

class BriefError extends DailyBriefState {
  final String message;
}
```

---

## 📊 Data Flow

### 1. Načíst data z DB

```dart
class TaskContext {
  final List<Todo> tasks;
  final List<SubtaskModel> subtasks;
  final Map<int, List<PomodoroSession>> pomodoroSessions;
  final DateTime currentDate;

  static Future<TaskContext> build(
    DatabaseHelper db,
    BriefConfig config,
  ) async {
    // Načíst úkoly podle konfigurace
    final tasks = await db.getTasks(
      includeCompleted: config.includeCompleted,
      dateRange: config.dateRange, // today, week, custom
    );

    // Načíst subtasks (pokud enabled)
    final subtasks = config.includeSubtasks
        ? await db.getAllSubtasks()
        : <SubtaskModel>[];

    // Načíst Pomodoro statistiky (pokud enabled)
    final pomodoroSessions = config.includePomodoroStats
        ? await _loadPomodoroStats(db, tasks)
        : <int, List<PomodoroSession>>{};

    return TaskContext(
      tasks: tasks,
      subtasks: subtasks,
      pomodoroSessions: pomodoroSessions,
      currentDate: DateTime.now(),
    );
  }
}
```

### 2. Sestavit AI prompt

**System Prompt** (dlouhý, detailní - viz sekce AI Prompt Strategy)

**User Context:**
```dart
String _buildUserContext(TaskContext context, BriefConfig config) {
  final buffer = StringBuffer();

  buffer.writeln('# USER TASK DATA\n');
  buffer.writeln('Current Date: ${_formatDate(context.currentDate)}\n');
  buffer.writeln('Day of Week: ${_getDayOfWeek(context.currentDate)}\n\n');

  // Tasks
  buffer.writeln('## TASKS (${context.tasks.length} total)\n');
  for (final task in context.tasks) {
    buffer.writeln('### Task ID: ${task.id}');
    buffer.writeln('- **Text**: ${task.task}');
    buffer.writeln('- **Priority**: ${task.priority ?? "none"} (a=high, b=medium, c=low)');

    if (task.dueDate != null) {
      final daysUntil = task.dueDate!.difference(context.currentDate).inDays;
      buffer.writeln('- **Due Date**: ${_formatDate(task.dueDate!)} (${daysUntil} days)');
    } else {
      buffer.writeln('- **Due Date**: none');
    }

    buffer.writeln('- **Status**: ${task.isCompleted ? "✅ completed" : "⭕ active"}');
    buffer.writeln('- **Tags**: ${task.tags.isEmpty ? "none" : task.tags.join(", ")}');

    // Subtasks
    if (config.includeSubtasks && task.subtasks != null && task.subtasks!.isNotEmpty) {
      final completed = task.subtasks!.where((s) => s.completed).length;
      final total = task.subtasks!.length;
      buffer.writeln('- **Subtasks**: $completed/$total completed');

      // List incomplete subtasks
      final incomplete = task.subtasks!.where((s) => !s.completed).toList();
      if (incomplete.isNotEmpty) {
        buffer.writeln('  Remaining:');
        for (final sub in incomplete) {
          buffer.writeln('    ${sub.subtaskNumber}. ${sub.text}');
        }
      }
    }

    // AI Recommendations (z AI Split)
    if (config.includeAiRecommendations && task.aiRecommendations != null) {
      buffer.writeln('- **AI Recommendations**: ${task.aiRecommendations}');
    }

    // Pomodoro stats
    if (config.includePomodoroStats) {
      final sessions = context.pomodoroSessions[task.id];
      if (sessions != null && sessions.isNotEmpty) {
        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.duration.inMinutes);
        buffer.writeln('- **Time Spent**: ${totalMinutes} minutes across ${sessions.length} Pomodoro sessions');
      }
    }

    buffer.writeln();
  }

  // Brief requirements (z config)
  buffer.writeln('\n## BRIEF REQUIREMENTS\n');
  buffer.writeln('**Time Range**: ${_getDateRangeDescription(config.dateRange)}');

  if (config.prioritization) {
    buffer.writeln('- ✅ Include prioritization recommendations');
  }
  if (config.dependencies) {
    buffer.writeln('- ✅ Identify task dependencies and relationships');
  }
  if (config.timing) {
    buffer.writeln('- ✅ Suggest optimal timing for tasks');
  }
  if (config.quickWins) {
    buffer.writeln('- ✅ Highlight quick wins (easy + impactful tasks)');
  }

  buffer.writeln('\n**User Expectation**: Provide a clear, actionable brief that helps me plan my ${config.dateRange == DateRange.today ? "day" : "week"}.');

  return buffer.toString();
}
```

### 3. Zavolat AI model

```dart
class BriefDatasource {
  final OpenRouterClient _client;

  Future<String> generateBrief({
    required String systemPrompt,
    required String userContext,
    required BriefConfig config,
  }) async {
    final response = await _client.chatCompletion(
      model: config.aiModel, // claude-3.5-sonnet
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userContext},
      ],
      temperature: config.temperature, // 0.3 - low temp pro konzistenci
      maxTokens: config.maxTokens, // 2000 default
    );

    return response['choices'][0]['message']['content'];
  }
}
```

### 4. Parsovat response

```dart
class BriefResponse {
  final String rawMarkdown;          // Celý AI response
  final List<int> referencedTaskIds; // Parsed task IDs (*5*, *12*, etc.)
  final DateTime generatedAt;

  const BriefResponse({
    required this.rawMarkdown,
    required this.referencedTaskIds,
    required this.generatedAt,
  });

  // Factory: Parse AI response
  factory BriefResponse.fromAiResponse(String markdown) {
    return BriefResponse(
      rawMarkdown: markdown,
      referencedTaskIds: _parseTaskIds(markdown),
      generatedAt: DateTime.now(),
    );
  }

  // Parse task IDs from markdown (*5*, *12*, *18*)
  static List<int> _parseTaskIds(String markdown) {
    final regex = RegExp(r'\*(\d+)\*');
    return regex
        .allMatches(markdown)
        .map((m) => int.parse(m.group(1)!))
        .toSet() // unique IDs
        .toList()
      ..sort(); // sorted
  }

  // Validate task IDs proti DB (catch AI hallucinations)
  Future<List<int>> validateTaskIds(DatabaseHelper db) async {
    final validIds = <int>[];

    for (final id in referencedTaskIds) {
      final exists = await db.todoExists(id);
      if (exists) {
        validIds.add(id);
      } else {
        AppLogger.warn('⚠️ AI referenced non-existent task ID: $id');
      }
    }

    return validIds;
  }
}
```

---

## 🎨 UI/UX Design

### Entry Point: Tlačítko v AppBar

**Umístění**: V `TodoListPage` AppBar, vedle oka pro zobrazení completed tasks

```dart
// lib/features/todo_list/presentation/pages/todo_list_page.dart

AppBar(
  title: Text('TODO List'),
  actions: [
    // NOVÉ: Daily Brief button
    IconButton(
      icon: Icon(Icons.wb_sunny_outlined), // ☀️ morning brief
      tooltip: 'Daily Brief',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DailyBriefPage(),
          ),
        );
      },
    ),

    // Existující: Show completed tasks
    IconButton(
      icon: Icon(showCompleted ? Icons.visibility : Icons.visibility_off),
      tooltip: showCompleted ? 'Skrýt hotové' : 'Zobrazit hotové',
      onPressed: () {
        setState(() => showCompleted = !showCompleted);
      },
    ),
  ],
)
```

### DailyBriefPage - Main UI

```
┌─────────────────────────────────────────────┐
│ ☀️ Daily Brief        [⚙️] [🔄]            │ AppBar
│                                             │
├─────────────────────────────────────────────┤
│                                             │
│ 📅 Generated: Today 8:05 AM                │ Timestamp
│ 🔄 Cache valid until 9:05 AM               │ Cache info
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 🌅 TODAY (3 tasks)                      ││ Section
│ │                                         ││
│ │ • *12* Dokončit prezentaci pro klienta ││ Clickable *12*
│ │   ⏰ 14:00 🔴 High priority            ││
│ │                                         ││
│ │ • *5* Code review PR #123 🟡           ││ Clickable *5*
│ │                                         ││
│ │ • *18* Team meeting 15:00 ⭕           ││ Clickable *18*
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 📅 THIS WEEK                            ││ Section
│ │                                         ││
│ │ • *22* Implementovat feature X         ││
│ │   (deadline Pátek) 🔴                  ││
│ │                                         ││
│ │ • *7* Update dokumentace 🟢            ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 📊 KEY INSIGHTS                         ││ Section
│ │                                         ││
│ │ **Blocking chain**: *12* blocks *22*   ││ Dependencies
│ │ (needs approval first)                  ││
│ │                                         ││
│ │ **Subtask synergy**: Completing *5*    ││ Smart insights
│ │ will auto-resolve subtask 3.1 of *12*  ││
│ │                                         ││
│ │ **Time conflict**: *18* meeting        ││ Warnings
│ │ overlaps with *12* deadline            ││
│ └─────────────────────────────────────────┘│
│                                             │
│ ┌─────────────────────────────────────────┐│
│ │ 💡 RECOMMENDATIONS                      ││ Section
│ │                                         ││
│ │ ### Priority Order (Start Here)        ││
│ │ 1. **START NOW**: *12*                 ││ Numbered list
│ │    (High priority + blocks *22*)       ││
│ │                                         ││
│ │ 2. **Quick Win**: *5*                  ││
│ │    (15 min, unblocks subtask)          ││
│ │                                         ││
│ │ 3. **After Lunch**: *18*               ││
│ │    (meeting, fixed time)               ││
│ │                                         ││
│ │ ### Strategy                            ││
│ │ - Morning (8-12): Focus on *12*        ││ Time blocks
│ │ - Afternoon: *5* then *18*             ││
│ │                                         ││
│ │ ### Capacity Check                      ││
│ │ ✅ 3 tasks today is realistic          ││ Feedback
│ │ ⚠️ Watch for meeting overrun           ││
│ └─────────────────────────────────────────┘│
│                                             │
└─────────────────────────────────────────────┘
```

**Features:**
- **Scrollable**: Celý brief v `SingleChildScrollView`
- **Markdown rendering**: Custom markdown renderer s podporou task links
- **Clickable task IDs**: `*12*` → RichText s `GestureRecognizer` → jump to task
- **Refresh button**: Regenerate brief (s confirmation dialog - costs tokens!)
- **Settings button**: Jump to Brief settings tab
- **Cache indicator**: Ukazuje kdy byl brief generován a do kdy je validní

### Task Link Widget - Clickable *5*

```dart
class TaskLinkText extends StatelessWidget {
  final String markdown;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: theme.appColors.fg,
          fontSize: 16,
          height: 1.5,
        ),
        children: _parseAndBuildSpans(markdown, context),
      ),
    );
  }

  List<InlineSpan> _parseAndBuildSpans(String text, BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*(\d+)\*');

    int lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      // Text před linkem (normální text)
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }

      // Clickable task link
      final taskId = int.parse(match.group(1)!);
      spans.add(TextSpan(
        text: '*$taskId*',
        style: TextStyle(
          color: theme.appColors.cyan,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: theme.appColors.cyan,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _jumpToTask(context, taskId),
      ));

      lastIndex = match.end;
    }

    // Zbylý text po posledním linku
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }

    return spans;
  }

  void _jumpToTask(BuildContext context, int taskId) {
    // Close brief page
    Navigator.pop(context);

    // Expand task v TodoListPage
    context.read<TodoListBloc>().add(
      ToggleExpandTodoEvent(taskId),
    );

    // Optional: Scroll to task (pokud implementujeme GlobalKey)
    _scrollToTask(context, taskId);
  }

  void _scrollToTask(BuildContext context, int taskId) {
    // Najít context TodoCard widgetu pomocí ValueKey
    final key = ValueKey('todo_$taskId');
    final cardContext = key.currentContext;

    if (cardContext != null) {
      Scrollable.ensureVisible(
        cardContext,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    }
  }
}
```

### Loading State

```dart
class BriefLoadingWidget extends StatelessWidget {
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.appColors.cyan,
          ),
          SizedBox(height: 16),
          Text(
            message ?? 'Generuji Daily Brief...',
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Trvá 3-5 sekund',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Regenerate Confirmation Dialog

```dart
void _showRegenerateDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.yellow, width: 2),
      ),
      title: Row(
        children: [
          Icon(Icons.warning, color: theme.appColors.yellow),
          SizedBox(width: 12),
          Text(
            'Regenerovat Brief?',
            style: TextStyle(color: theme.appColors.yellow),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tato akce spotřebuje API tokeny.',
            style: TextStyle(color: theme.appColors.fg),
          ),
          SizedBox(height: 8),
          Text(
            'Odhadované náklady: ~\$0.02',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cache je validní ještě ${_getCacheTimeRemaining()} minut.',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // Trigger regenerate
            context.read<DailyBriefBloc>().add(RegenerateBriefEvent());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.yellow,
            foregroundColor: theme.appColors.bg,
          ),
          child: Text('Regenerovat'),
        ),
      ],
    ),
  );
}
```

---

## ⚙️ Settings Tab - Brief Configuration

**Lokace**: `Settings > Brief` (nový tab)

```
Settings > Brief

┌──────────────────────────────────────────┐
│ ⚙️ Daily Brief Settings                  │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 📊 CONTEXT (Co předat AI?)              │
│                                          │
│ ☑ Nesplněné úkoly                       │
│ ☑ Podúkoly (subtasks)                   │
│ ☑ AI doporučení z rozkladu              │
│ ☐ Splněné úkoly (posledních 7 dní)     │
│ ☑ Pomodoro statistiky                   │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 📅 ČASOVÉ ROZMEZÍ                       │
│                                          │
│ ○ Jen dnes (today)                      │
│ ● Celý týden (7 dnů)                    │
│ ○ Vlastní rozsah (custom)               │
│                                          │
│ [Pokud custom: Date pickers]            │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 💡 TYP DOPORUČENÍ                       │
│                                          │
│ ☑ Prioritizace úkolů                   │
│   (doporuč pořadí plnění)              │
│                                          │
│ ☑ Vazby mezi úkoly                      │
│   (dependencies, blocking)              │
│                                          │
│ ☑ Optimální časování                    │
│   (morning/afternoon recommendations)   │
│                                          │
│ ☑ Quick wins                             │
│   (rychlé + impactful úkoly)           │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 🤖 AI MODEL                             │
│                                          │
│ Model: Task Model ℹ️                    │
│ (claude-3.5-sonnet)                     │
│                                          │
│ Temperature: 0.3 ───────●─────          │
│ (nízká = konzistentní výstup)          │
│                                          │
│ Max tokens: 2000 ────────●────          │
│ (délka briefu)                          │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 💾 CACHE                                │
│                                          │
│ Cache validita: 1 hodina ✓              │
│ Automaticky se regeneruje po expiraci   │
│                                          │
│ [Vymazat cache]                         │
│                                          │
├──────────────────────────────────────────┤
│                                          │
│ 📊 STATISTIKY                           │
│                                          │
│ Briefs vygenerované: 42                 │
│ API cost tento měsíc: $0.84             │
│ Cache hit rate: 73%                     │
│                                          │
└──────────────────────────────────────────┘
```

### BriefConfig Entity

```dart
class BriefConfig {
  // ===== CONTEXT (Co předat AI?) =====
  final bool includeCompleted;           // Splněné úkoly (last 7 days)
  final bool includeSubtasks;            // Podúkoly
  final bool includeAiRecommendations;   // AI doporučení z rozkladu
  final bool includePomodoroStats;       // Pomodoro statistiky

  // ===== ČASOVÉ ROZMEZÍ =====
  final DateRange dateRange;             // enum: today, week, custom
  final DateTime? customStart;           // Pokud custom
  final DateTime? customEnd;             // Pokud custom

  // ===== TYP DOPORUČENÍ =====
  final bool prioritization;             // Prioritizace úkolů
  final bool dependencies;               // Vazby mezi úkoly
  final bool timing;                     // Optimální časování
  final bool quickWins;                  // Quick wins

  // ===== AI SETTINGS =====
  final String aiModel;                  // Task model (claude-3.5-sonnet)
  final double temperature;              // 0.3 default (low = konzistentní)
  final int maxTokens;                   // 2000 default

  // ===== CACHE =====
  final Duration cacheValidity;          // 1 hour default

  const BriefConfig({
    // Defaults
    this.includeCompleted = false,
    this.includeSubtasks = true,
    this.includeAiRecommendations = true,
    this.includePomodoroStats = true,
    this.dateRange = DateRange.week,
    this.customStart,
    this.customEnd,
    this.prioritization = true,
    this.dependencies = true,
    this.timing = true,
    this.quickWins = true,
    required this.aiModel,
    this.temperature = 0.3,
    this.maxTokens = 2000,
    this.cacheValidity = const Duration(hours: 1),
  });

  // copyWith, toJson, fromJson...
}

enum DateRange {
  today,   // Jen dnes
  week,    // Příštích 7 dní
  custom,  // Vlastní rozsah
}
```

### Persistence

**Settings Table** (extend existing):
```sql
ALTER TABLE settings ADD COLUMN brief_config TEXT; -- JSON

-- Example JSON:
{
  "includeCompleted": false,
  "includeSubtasks": true,
  "dateRange": "week",
  "prioritization": true,
  ...
}
```

---

## 🤖 AI Prompt Strategy

### System Prompt (Ultra-detailed)

```dart
const String BRIEF_SYSTEM_PROMPT = '''
You are an expert task planning assistant. Your role is to analyze a user's task list and provide a clear, actionable daily/weekly brief.

# OBJECTIVE

Provide a structured overview that helps the user:
1. **Understand what needs to be done TODAY**
2. **See upcoming work for THIS WEEK**
3. **Identify task dependencies and relationships**
4. **Get smart recommendations on prioritization and timing**

# OUTPUT FORMAT RULES

## Structure

Use these sections in order:

1. **🌅 TODAY** - Tasks due today (max 5 tasks)
2. **📅 THIS WEEK** - Tasks due in next 7 days (max 7 tasks)
3. **⚠️ OVERDUE** - Tasks past deadline (if any)
4. **📊 KEY INSIGHTS** - Dependencies, relationships, patterns
5. **💡 RECOMMENDATIONS** - Prioritization strategy

## Task References

- **ALWAYS** reference tasks using format: `*[task_id]*`
- Example: `*12*` for task with ID 12
- User can click `*12*` to jump to that task
- Use this format consistently throughout the brief

## Emoji Usage

- **Section headers**: 🌅 📅 ⚠️ 📊 💡
- **Priority**: 🔴 High, 🟡 Medium, 🟢 Low
- **Time**: ⏰ for deadlines
- **Status**: ✅ completed, ⭕ active
- **Other**: 🎯 goal, 🚀 quick win, 🔗 dependency, ⚡ urgent

## Markdown Formatting

- Use `##` for section headers
- Use `###` for sub-headers
- Use `-` or `•` for bullet lists
- Use `1.` for numbered lists
- Use `**bold**` for important info
- Keep sections concise and scannable

# ANALYSIS GUIDELINES

## Dependencies

Identify if completing task A unlocks/helps task B:

**Examples:**
- "Completing `*5*` will resolve subtask 3.1 of `*12*`"
- "`*12*` blocks `*22*` (needs approval first)"
- "`*7*` and `*14*` can be done in parallel"

## Prioritization Factors

Consider:
1. **Deadline urgency**: today > this week > future
2. **Priority level**: high (a) > medium (b) > low (c)
3. **Dependencies**: blocking others? blocked by others?
4. **Estimated effort**: from subtask count
5. **Quick wins**: easy + high impact

## Smart Recommendations

### Priority Order
1. Start with highest-priority blocking tasks
2. Suggest quick wins for motivation
3. Group related tasks together
4. Warn about deadline conflicts

### Timing Suggestions
- Morning (8-12): Deep work, high-concentration tasks
- Afternoon (13-17): Meetings, collaboration, lighter work
- Evening: Wrap-up, planning for tomorrow

### Capacity Check
- Warn if too many tasks for one day (>5 is risky)
- Suggest realistic daily capacity (3-4 tasks)
- Highlight if deadlines conflict

# EXAMPLE OUTPUT

## 🌅 TODAY (3 tasks)

- `*12*` Dokončit prezentaci pro klienta ⏰ 14:00 🔴 High priority
  - 3 subtasks remaining
  - Blocks `*22*` (needs approval)

- `*5*` Code review PR #123 🟡 Medium priority
  - Quick win (estimated 15 min)
  - Unblocks subtask 3.1 of `*12*`

- `*18*` Team meeting 15:00 ⭕
  - Fixed time, cannot reschedule

## 📅 THIS WEEK

- `*22*` Implementovat feature X (deadline Pátek) 🔴
  - Blocked by `*12*` approval
  - Estimate: 8 hours

- `*7*` Update dokumentace 🟢
  - Low priority, flexible timing

- `*14*` Sprint planning (Středa 10:00)

## 📊 KEY INSIGHTS

### Dependencies
- **Blocking chain**: `*12*` → `*22*` → `*25*`
- **Subtask synergy**: Completing `*5*` auto-resolves subtask 3.1 of `*12*`

### Time Conflicts
- ⚠️ `*18*` meeting (15:00) overlaps with `*12*` deadline (14:00)
- **Suggestion**: Finish `*12*` by 13:00 to have buffer

### Effort Distribution
- High effort: `*12*` (3 subtasks), `*22*` (8h estimate)
- Quick wins: `*5*` (15 min), `*7*` (30 min)

## 💡 RECOMMENDATIONS

### Priority Order (Start Here)

1. **START NOW**: `*12*` Dokončit prezentaci 🔴
   - Highest priority + blocks `*22*`
   - Needs focus time → do in morning

2. **Quick Win**: `*5*` Code review 🚀
   - 15 min, easy
   - Unblocks subtask of `*12*`
   - Do before lunch

3. **After Lunch**: `*18*` Team meeting
   - Fixed time (15:00)
   - Prepare notes beforehand

### Daily Strategy

**Morning (8:00-12:00)**
- 🎯 Focus on `*12*` (deep work, no interruptions)
- Target: Finish by 13:00 (1h buffer before deadline)

**Afternoon (13:00-17:00)**
- 🚀 Quick win: `*5*` code review (13:00-13:15)
- 📅 `*18*` Team meeting (15:00-16:00)
- 📝 Update notes and plan for tomorrow

### Capacity Check
✅ **3 tasks today is realistic**
⚠️ **Watch for**:
- Meeting overrun affecting `*12*` deadline
- Context switching between `*12*` and `*18*`

### Next Steps
- Once `*12*` is approved, start `*22*` immediately (high priority)
- Schedule `*7*` documentation for Friday afternoon (low priority)

---

**Remember**: Keep it actionable, concise, and user-friendly!
''';
```

### Context Size Management

**Problem**: Context může být velký (50+ úkolů × 200 tokens = 10k+ tokens)

**Řešení**: Filtering + summarization

```dart
List<Todo> _filterRelevantTasks(
  List<Todo> allTasks,
  BriefConfig config,
) {
  // Filter by date range
  final now = DateTime.now();
  final filtered = allTasks.where((task) {
    if (task.isCompleted && !config.includeCompleted) {
      return false; // Skip completed unless explicitly requested
    }

    if (task.dueDate == null) {
      return true; // Always include tasks without deadline
    }

    // Filter by date range
    return switch (config.dateRange) {
      DateRange.today => _isToday(task.dueDate!, now),
      DateRange.week => _isThisWeek(task.dueDate!, now),
      DateRange.custom => _isInCustomRange(task.dueDate!, config),
    };
  }).toList();

  // Sort: high priority + soonest deadline first
  filtered.sort((a, b) {
    // Priority: a > b > c > none
    final priorityA = _priorityScore(a.priority);
    final priorityB = _priorityScore(b.priority);

    if (priorityA != priorityB) {
      return priorityB.compareTo(priorityA); // Descending
    }

    // Then by deadline (soonest first)
    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }

    return 0;
  });

  // Limit: max 20 tasks (aby context nebyl obří)
  return filtered.take(20).toList();
}

int _priorityScore(String? priority) {
  return switch (priority) {
    'a' => 3, // High
    'b' => 2, // Medium
    'c' => 1, // Low
    _ => 0,   // None
  };
}
```

---

## 🧪 Technické výzvy a řešení

### 1. Clickable Task IDs v textu

**Výzva**: Jak udělat `*5*` clickable v Markdown textu?

**Řešení**: RichText + TapGestureRecognizer

```dart
// Viz sekce "Task Link Widget" výše
// Parse regex \*(\d+)\* → extract task IDs → build TextSpan s recognizer
```

**Alternativa**: Custom Markdown renderer (flutter_markdown package)

```dart
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownBody(
  data: briefResponse.rawMarkdown,
  styleSheet: MarkdownStyleSheet.fromTheme(theme),
  onTapText: () {
    // Parse clicked text, check if it's *5* format
    // If yes → jump to task
  },
)
```

### 2. Caching (neregenerate při každém otevření)

**Výzva**: AI generace stojí tokeny (~$0.02) a trvá 3-5s

**Řešení**: In-memory cache v BLoC state

```dart
class BriefLoaded extends DailyBriefState {
  final BriefResponse response;
  final DateTime generatedAt;
  final Duration cacheValidity; // 1 hour default

  bool get isCacheValid {
    final now = DateTime.now();
    return now.difference(generatedAt) < cacheValidity;
  }
}

// V BLoC handler
@override
Stream<DailyBriefState> mapEventToState(DailyBriefEvent event) async* {
  if (event is GenerateBriefEvent) {
    // Check cache first
    if (state is BriefLoaded && (state as BriefLoaded).isCacheValid) {
      // Use cached version
      return;
    }

    // Cache expired or no cache → generate new
    yield BriefLoading(message: 'Načítám úkoly...');

    final context = await TaskContext.build(db, event.config);

    yield BriefLoading(message: 'Generuji brief...');

    final markdown = await repository.generateBrief(
      context: context,
      config: event.config,
    );

    final response = BriefResponse.fromAiResponse(markdown);

    yield BriefLoaded(
      response: response,
      generatedAt: DateTime.now(),
    );
  }
}
```

**Persistence**: Optional - uložit do DB pro offline access

```sql
CREATE TABLE brief_cache (
  id INTEGER PRIMARY KEY,
  config_hash TEXT,        -- Hash of BriefConfig (to detect changes)
  markdown TEXT,           -- AI response
  generated_at INTEGER,    -- Timestamp
  expires_at INTEGER       -- Timestamp
);
```

### 3. Scroll to task po kliknutí na *5*

**Výzva**: Jak scrollnout na konkrétní TodoCard v ListView?

**Řešení**: ValueKey + Scrollable.ensureVisible

```dart
// V TodoListPage - každý TodoCard má unique key
ListView.builder(
  itemBuilder: (context, index) {
    final todo = todos[index];
    return TodoCard(
      key: ValueKey('todo_${todo.id}'),  // DŮLEŽITÉ: ValueKey s ID
      todo: todo,
      isExpanded: expandedTodoId == todo.id,
    );
  },
)

// Jump to task
void _jumpToTask(int taskId) {
  // 1. Expand task
  context.read<TodoListBloc>().add(ToggleExpandTodoEvent(taskId));

  // 2. Find context pomocí ValueKey
  final key = ValueKey('todo_$taskId');
  final cardContext = key.currentContext;

  if (cardContext != null) {
    // 3. Scroll to visible
    Scrollable.ensureVisible(
      cardContext,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  } else {
    // Task not found in current list (maybe filtered out?)
    AppLogger.warn('Task $taskId not found in list');

    // Fallback: Switch to "All" view first
    context.read<TodoListBloc>().add(ChangeViewModeEvent(ViewMode.all));

    // Then try again after rebuild
    Future.delayed(Duration(milliseconds: 100), () {
      _jumpToTask(taskId);
    });
  }
}
```

### 4. Token cost control

**Výzva**: Users mohou spamovat regenerate → vysoké API costs

**Řešení**:
1. **Cache** (1 hour validity)
2. **Confirmation dialog** pro manual regenerate
3. **Cost display** v settings (API cost tento měsíc)
4. **Rate limiting** (max 1 generate per 5 minutes)

```dart
class BriefRateLimiter {
  DateTime? _lastGenerated;
  final Duration _minInterval = Duration(minutes: 5);

  bool canGenerate() {
    if (_lastGenerated == null) return true;

    final elapsed = DateTime.now().difference(_lastGenerated!);
    return elapsed >= _minInterval;
  }

  Duration getRemainingCooldown() {
    if (_lastGenerated == null) return Duration.zero;

    final elapsed = DateTime.now().difference(_lastGenerated!);
    return _minInterval - elapsed;
  }

  void markGenerated() {
    _lastGenerated = DateTime.now();
  }
}

// V BLoC
final _rateLimiter = BriefRateLimiter();

if (!_rateLimiter.canGenerate()) {
  final cooldown = _rateLimiter.getRemainingCooldown();
  yield BriefError(
    'Počkej ještě ${cooldown.inSeconds}s před dalším generováním'
  );
  return;
}
```

### 5. AI Hallucination (neexistující task ID)

**Výzva**: AI může vymyslet task ID *99* který neexistuje

**Řešení**: Validace parsed IDs proti DB

```dart
class BriefResponse {
  final String rawMarkdown;
  final List<int> referencedTaskIds;
  final List<int> validTaskIds;      // Validované proti DB
  final List<int> invalidTaskIds;    // Hallucination (warning)

  static Future<BriefResponse> create(
    String markdown,
    DatabaseHelper db,
  ) async {
    final parsed = _parseTaskIds(markdown);

    // Validate proti DB
    final valid = <int>[];
    final invalid = <int>[];

    for (final id in parsed) {
      final exists = await db.todoExists(id);
      if (exists) {
        valid.add(id);
      } else {
        invalid.add(id);
        AppLogger.warn('⚠️ AI hallucination: task *$id* not found');
      }
    }

    return BriefResponse(
      rawMarkdown: markdown,
      referencedTaskIds: parsed,
      validTaskIds: valid,
      invalidTaskIds: invalid,
      generatedAt: DateTime.now(),
    );
  }
}

// V UI - show warning pokud jsou invalid IDs
if (response.invalidTaskIds.isNotEmpty) {
  SnackBar(
    content: Text(
      '⚠️ AI zmínil neexistující úkoly: ${response.invalidTaskIds.join(", ")}'
    ),
    backgroundColor: theme.appColors.yellow,
  );
}
```

---

## 📊 Cost Analysis

### API Cost (OpenRouter - Claude 3.5 Sonnet)

**Pricing:**
- Input: **$3** per million tokens
- Output: **$15** per million tokens

**Average Brief:**
- Input: ~2000 tokens (context: tasks + metadata)
- Output: ~1000 tokens (brief markdown)
- **Cost per brief: ~$0.021** (2.1 cents)

**User Budget:**
- 100 briefs/month = **$2.10/month**
- WITH 1-hour cache: ~20 actual API calls/month = **$0.42/month**
- WITH rate limiting: ~10-15 calls/month = **$0.21-$0.31/month**

**Sustainable!** ✅

### Comparison

| Feature | API Cost | Subscription | Total/month |
|---------|----------|--------------|-------------|
| **Naše Brief** | $0.42 | $0 | **$0.42** |
| Trevor AI | N/A | $40 | **$40** |
| Motion | N/A | $19 | **$19** |

**ROI**: Naše řešení je **95x levnější** než Trevor AI! 🚀

---

## 📅 Implementační plán

### Phase 1: MVP (8-10 hodin)

**Cíl**: Funkční Daily Brief s basic UI

#### Krok 1: Domain Layer (2h)
- [ ] `BriefConfig` entity (settings)
- [ ] `BriefResponse` entity (AI response + parsed IDs)
- [ ] `TaskContext` entity (context builder)
- [ ] `DailyBriefRepository` interface

#### Krok 2: Data Layer (3h)
- [ ] `BriefDatasource` - OpenRouter API client
- [ ] `BriefDbDatasource` - DB queries (tasks, subtasks, pomodoro)
- [ ] `DailyBriefRepositoryImpl`
- [ ] System prompt konstanta
- [ ] User context builder

#### Krok 3: Presentation Layer (3h)
- [ ] `DailyBriefBloc` - events, states, handlers
- [ ] `DailyBriefPage` - basic UI (markdown rendering)
- [ ] Loading state widget
- [ ] Error state widget
- [ ] Entry button v `TodoListPage` AppBar

#### Krok 4: Testing (2h)
- [ ] Unit tests: `BriefResponse.parseTaskIds()`
- [ ] Unit tests: `TaskContext.build()`
- [ ] BLoC tests: GenerateBriefEvent flow
- [ ] Integration test: E2E brief generation

**Deliverable**: Funkční brief generation + basic UI ✅

---

### Phase 2: Polish & UX (4-6 hodin)

**Cíl**: Clickable task links, cache, settings

#### Krok 5: Task Linking (2h)
- [ ] `TaskLinkText` widget (RichText + TapGestureRecognizer)
- [ ] `_jumpToTask()` logic (navigate + expand + scroll)
- [ ] ValueKey integration v `TodoCard`
- [ ] Fallback pro filtered out tasks

#### Krok 6: Settings Tab (2h)
- [ ] Brief settings page UI
- [ ] `BriefConfig` persistence (DB + JSON)
- [ ] Settings cubit integration
- [ ] Default config

#### Krok 7: Cache & Optimization (2h)
- [ ] Cache v `BriefLoaded` state (1-hour validity)
- [ ] Optional: DB persistence pro offline
- [ ] Regenerate confirmation dialog
- [ ] Cache indicator v UI

**Deliverable**: Polished UX + settings ✅

---

### Phase 3: Advanced Features (optional, 4-6 hodin)

**Cíl**: Nice-to-have features

#### Krok 8: Rate Limiting (1h)
- [ ] `BriefRateLimiter` class
- [ ] Min 5-minute interval between generates
- [ ] Cooldown timer v UI

#### Krok 9: Cost Tracking (1h)
- [ ] API call counter v DB
- [ ] Cost calculator (tokens × pricing)
- [ ] Display v settings ("API cost tento měsíc")

#### Krok 10: Email/Notification (2h) - FUTURE
- [ ] Morning notification (8:00 AM)
- [ ] Background generation
- [ ] Email brief (optional)

#### Krok 11: Voice Output (2h) - FUTURE
- [ ] Text-to-speech integration
- [ ] "Read my brief" button
- [ ] Pause/resume controls

**Deliverable**: Power features ✅

---

## 🧪 Testing Strategy

### Unit Tests

```dart
group('BriefResponse', () {
  test('parseTaskIds extracts IDs from markdown', () {
    const markdown = '''
    ## Today
    - *12* Task A
    - *5* Task B

    ## Insights
    Completing *5* unblocks *12*.
    ''';

    final ids = BriefResponse._parseTaskIds(markdown);

    expect(ids, [5, 12]); // Sorted, unique
  });

  test('validateTaskIds catches hallucinations', () async {
    final db = MockDatabaseHelper();
    when(db.todoExists(5)).thenAnswer((_) async => true);
    when(db.todoExists(99)).thenAnswer((_) async => false);

    final response = BriefResponse(
      rawMarkdown: '...',
      referencedTaskIds: [5, 99],
      generatedAt: DateTime.now(),
    );

    final valid = await response.validateTaskIds(db);

    expect(valid, [5]);
  });
});

group('TaskContext', () {
  test('filters tasks by date range', () async {
    final db = MockDatabaseHelper();
    final config = BriefConfig(dateRange: DateRange.today);

    // Setup mock tasks
    when(db.getTasks()).thenAnswer((_) async => [
      Todo(id: 1, task: 'Today task', dueDate: DateTime.now()),
      Todo(id: 2, task: 'Tomorrow task', dueDate: DateTime.now().add(Duration(days: 1))),
    ]);

    final context = await TaskContext.build(db, config);

    expect(context.tasks.length, 1); // Only today's task
    expect(context.tasks[0].id, 1);
  });
});
```

### Widget Tests

```dart
testWidgets('TaskLinkText is clickable', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: TaskLinkText(
        markdown: 'Complete *5* first',
        onTaskTap: (id) => tapped = true,
      ),
    ),
  ));

  // Find *5* link
  final link = find.text('*5*');
  expect(link, findsOneWidget);

  // Tap it
  await tester.tap(link);
  await tester.pump();

  expect(tapped, true);
});

testWidgets('DailyBriefPage shows loading state', (tester) async {
  final bloc = MockDailyBriefBloc();
  when(bloc.state).thenReturn(BriefLoading(message: 'Generuji brief...'));

  await tester.pumpWidget(MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: DailyBriefPage(),
    ),
  ));

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text('Generuji brief...'), findsOneWidget);
});
```

### Integration Tests

```dart
testWidgets('E2E: Generate brief and jump to task', (tester) async {
  // Setup
  final db = await setupTestDatabase();
  await db.insertTodo(Todo(id: 5, task: 'Test task'));

  // Launch app
  await tester.pumpWidget(MyApp(db: db));

  // Tap Daily Brief button
  await tester.tap(find.byIcon(Icons.wb_sunny_outlined));
  await tester.pumpAndSettle();

  // Wait for generation
  await tester.pumpAndSettle(Duration(seconds: 5));

  // Should show brief
  expect(find.byType(DailyBriefPage), findsOneWidget);

  // Tap task link *5*
  await tester.tap(find.text('*5*'));
  await tester.pumpAndSettle();

  // Should navigate back and expand task 5
  expect(find.byType(TodoListPage), findsOneWidget);
  expect(find.text('Test task'), findsOneWidget);
});
```

---

## 📊 Metrics & Success Criteria

### Usage Metrics

**Target:**
- 50%+ users use Brief at least **1x/week**
- Average **3-5 briefs** per active user/week
- 70%+ cache hit rate

**Tracking:**
```dart
class BriefAnalytics {
  static Future<void> trackBriefGenerated(bool fromCache) async {
    await analytics.logEvent(
      name: 'brief_generated',
      parameters: {
        'from_cache': fromCache,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> trackTaskLinkClicked(int taskId) async {
    await analytics.logEvent(
      name: 'brief_task_link_clicked',
      parameters: {
        'task_id': taskId,
      },
    );
  }
}
```

### Quality Metrics

**Target:**
- 80%+ users find recommendations **helpful** (user survey)
- <5% invalid task ID references (AI hallucination rate)
- Average response time <5s (p95)

**Measurement:**
- In-app survey after 5th brief: "Byl tento brief užitečný? 👍/👎"
- Log invalid task IDs → track hallucination rate
- Performance monitoring (Sentry/Firebase)

### Performance Metrics

**Target:**
- Generation time: <5s (p95)
- Cache hit rate: >70%
- API cost: <$0.50 per user/month

---

## 🚨 Rizika a mitigace

| Riziko | Pravděpodobnost | Dopad | Mitigace |
|--------|-----------------|--------|----------|
| **AI hallucination** (neexistující task ID) | Medium | Low | Validate parsed IDs proti DB → show warning |
| **High token cost** | Low | Medium | Cache (1h) + rate limiting + user confirmation |
| **Slow generation** (5-10s) | High | Low | Loading state + cache + optimization |
| **User overwhelm** (too much info) | Medium | Medium | Konfigurovatelný output (settings) |
| **Context too large** (50+ tasks) | Medium | High | Filter top 20 tasks by priority+deadline |
| **Scroll to task fails** (filtered out) | Low | Low | Fallback: switch to "All" view first |
| **Cache invalidation** (stale data) | Low | Low | 1-hour validity + manual refresh |

---

## 🎯 Závěr a doporučení

### Proč je Daily Brief killer feature?

1. **Řeší reálný problém**: Information overload + decision paralysis
2. **Leveraguje AI**: Chytrá analýza dependencies + prioritizace
3. **Unique value proposition**: Task linking + dependency analysis (nemá konkurence)
4. **Sustainable**: Low cost (~$0.42/user/month)
5. **Scalable**: Feature-First architektura, clean BLoC pattern

### USP (Unique Selling Proposition)

| Co | Jak | Proč je to unikátní |
|----|-----|---------------------|
| **Task linking** | `*5*` → proklik | Org-mode style, ale v mobile app |
| **Dependency intelligence** | AI najde vazby | Motion má scheduling, ale ne dependencies |
| **Full customization** | User řídí kontext | Trevor AI je black box |
| **Open source** | No subscription | $0 vs $40/mo (Trevor) |

### Next Steps

1. ✅ **Schválit design** (tento dokument)
2. 🚀 **Implementovat MVP** (8-10h)
   - Domain + Data + Presentation layers
   - Basic UI + entry button
3. 🎨 **Polish UX** (4-6h)
   - Clickable links + settings + cache
4. 🧪 **Testing** (2h)
   - Unit + Widget + Integration tests
5. 📊 **Launch + Measure** (1 week)
   - User feedback survey
   - Usage analytics
   - Iterate based on data

### Success Definition

**MVP je úspěšný pokud:**
- ✅ 50%+ users try Brief in first week
- ✅ 80%+ users find it "helpful" (survey)
- ✅ <5% hallucination rate
- ✅ <$0.50 API cost per user/month

---

## 📚 Reference & Resources

### Competitive Apps
- [Trevor AI](https://www.trevorai.com/) - "Start My Day" email
- [Motion](https://www.usemotion.com/) - AI adaptive planning
- [Morgen](https://www.morgen.so/ai-planner) - AI calendar integration
- [Org-mode Agenda](https://orgmode.org/manual/Weekly_002fdaily-agenda.html) - Traditional agenda view

### Flutter Packages
- `flutter_markdown` - Markdown rendering
- `intl` - Date formatting
- `equatable` - Immutable entities
- `bloc` - State management

### API Documentation
- [OpenRouter API](https://openrouter.ai/docs/api-reference/chat-completion) - Chat Completion
- [Claude 3.5 Sonnet](https://www.anthropic.com/claude) - Model specs

---

**Version**: 1.0
**Created**: 2025-10-12
**Author**: Claude Code (AI Assistant)
**Status**: 📝 Design & Analysis Complete - Ready for implementation

---

🎯 **Ready to build!** Let's make task management intelligent. 🚀
