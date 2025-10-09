# 🤖 AI ROZDĚL ÚKOL - Implementační Plán

> **Účel**: Přidat AI funkci "Rozděl úkol na podúkoly" do Flutter/BLoC Todo aplikace
> **Inspirace**: Tauri verze (`d:\01_programovani\tauri-todo-linux\`)
> **Architektura**: Feature-First + BLoC Pattern
> **Datum**: 2025-10-09

---

## 📋 OBSAH

1. [Přehled funkce](#1-přehled-funkce)
2. [Architektura řešení](#2-architektura-řešení)
3. [Databázové změny](#3-databázové-změny)
4. [Implementační kroky](#4-implementační-kroky)
5. [Testing](#5-testing)
6. [Deployment](#6-deployment)

---

## 1. PŘEHLED FUNKCE

### 🎯 Co funkce dělá

**Vstup:**
- Uživatel klikne na ikonu 🤖 v editačním režimu úkolu
- Systém pošle úkol do AI (OpenRouter API)
- AI vrátí strukturovaný návrh rozdělení

**Výstup:**
- 3-8 konkrétních podúkolů (max 50 znaků každý)
- Doporučení (tipy, odkazy, rady)
- Analýza termínu (reálnost deadline)

**Flow:**
```
[Uživatel] → [Edit režim] → [🤖 ikona] → [AI API]
    → [Návrh] → [Accept/Reject] → [DB: subtasks]
```

### 🔑 Klíčové vlastnosti z Tauri verze

✅ **Z Tauri projektu převezmeme:**
- System prompt (strukturovaný výstup)
- User prompt formát (úkol + priorita + termín + tagy)
- Parsing logika (PODÚKOLY:/DOPORUČENÍ:/TERMÍN:)
- Retry mechanismus s user note
- Max 50 znaků na podúkol
- 3-8 podúkolů limit

❌ **Nepoužijeme:**
- Terminal command interface (máme GUI)
- Pending state v globálním JS scope (použijeme BLoC state)
- Direct Tauri commands (máme Dart/Flutter)

---

## 2. ARCHITEKTURA ŘEŠENÍ

### 📁 Feature-First struktura

Podle **[mapa-bloc.md → SCÉNÁŘ 1](mapa-bloc.md)** přidáváme **NOVOU FEATURE**.

```
lib/features/ai_split/
├── presentation/
│   ├── cubit/
│   │   ├── ai_split_cubit.dart          # BLoC logika
│   │   └── ai_split_state.dart          # Sealed states
│   └── widgets/
│       ├── ai_split_button.dart         # 🤖 ikona v edit režimu
│       ├── ai_split_dialog.dart         # Dialog s návrhem
│       └── subtask_list_view.dart       # Zobrazení subtasks
├── data/
│   ├── repositories/
│   │   └── ai_split_repository_impl.dart
│   ├── models/
│   │   ├── ai_split_request_model.dart
│   │   └── ai_split_response_model.dart
│   └── datasources/
│       └── openrouter_datasource.dart   # HTTP client pro API
└── domain/
    ├── entities/
    │   ├── ai_split_request.dart        # Pure Dart entity
    │   ├── ai_split_response.dart       # Parse result
    │   └── subtask.dart                 # Subtask entity
    └── repositories/
        └── ai_split_repository.dart     # Interface
```

### 🗂️ Existující struktury k rozšíření

```
lib/features/todo_list/
├── domain/entities/
│   └── todo.dart                        # Přidat: List<Subtask>? subtasks
├── data/models/
│   └── todo_model.dart                  # Přidat: subtasks mapping
└── presentation/
    └── widgets/
        └── todo_card.dart               # Přidat: zobrazení subtasks
```

### 🔄 BLoC Pattern - States

```dart
// ai_split_state.dart
sealed class AiSplitState extends Equatable {
  const AiSplitState();
}

class AiSplitInitial extends AiSplitState {}

class AiSplitLoading extends AiSplitState {
  final String taskText;
  final String model;
}

class AiSplitLoaded extends AiSplitState {
  final AiSplitResponse response;  // subtasks, recommendations, analysis
  final int taskId;
}

class AiSplitAccepted extends AiSplitState {
  final int taskId;
  final List<Subtask> subtasks;
  final String message;
}

class AiSplitRejected extends AiSplitState {}

class AiSplitError extends AiSplitState {
  final String message;
}
```

### 🔄 BLoC Pattern - Events

```dart
// ai_split_cubit.dart
class AiSplitCubit extends Cubit<AiSplitState> {

  // Zavolat AI API
  Future<void> splitTask({
    required int taskId,
    required String taskText,
    String? priority,
    DateTime? deadline,
    List<String>? tags,
    String? userNote,  // Pro retry
  }) async { ... }

  // Přijmout návrh (uloží do DB)
  Future<void> acceptSuggestion() async { ... }

  // Odmítnout návrh
  void rejectSuggestion() { ... }

  // Znovu vygenerovat s poznámkou
  Future<void> retrySuggestion(String userNote) async { ... }
}
```

---

## 3. DATABÁZOVÉ ZMĚNY

### 📊 Nová tabulka: `subtasks`

```sql
CREATE TABLE subtasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_todo_id INTEGER NOT NULL,
  subtask_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY(parent_todo_id) REFERENCES todos(id) ON DELETE CASCADE,
  UNIQUE(parent_todo_id, subtask_number)
);
```

**Indexy:**
```sql
CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id);
CREATE INDEX idx_subtasks_completed ON subtasks(completed);
```

### 📝 Aktualizace tabulky: `todos`

**Přidat sloupce pro AI metadata:**
```sql
ALTER TABLE todos ADD COLUMN ai_recommendations TEXT;
ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT;
```

**Vysvětlení:**
- `ai_recommendations` - uloží "DOPORUČENÍ:" část z AI
- `ai_deadline_analysis` - uloží "TERMÍN:" analýzu

### 🔧 DatabaseHelper změny

**Soubor:** `lib/core/services/database_helper.dart`

**Přidat metody:**
```dart
// Vytvořit subtasks tabulku
Future<void> _createSubtasksTable(Database db) async {
  await db.execute('''
    CREATE TABLE subtasks (...)
  ''');
}

// CRUD operace pro subtasks
Future<int> insertSubtask(Map<String, dynamic> subtask) async { ... }
Future<List<Map<String, dynamic>>> getSubtasksByTodoId(int todoId) async { ... }
Future<int> updateSubtask(int id, Map<String, dynamic> subtask) async { ... }
Future<int> deleteSubtask(int id) async { ... }
Future<int> toggleSubtaskCompleted(int id, bool completed) async { ... }

// Update todo s AI metadata
Future<int> updateTodoAIMetadata(int id, {
  String? aiRecommendations,
  String? aiDeadlineAnalysis,
}) async { ... }
```

### 🔄 Migration

**Soubor:** `lib/core/services/database_helper.dart`

**Přidat do `onCreate`:**
```dart
await _createSubtasksTable(db);
```

**Přidat migraci do `onUpgrade`:**
```dart
if (oldVersion < 3) {
  // Přidat AI sloupce
  await db.execute('ALTER TABLE todos ADD COLUMN ai_recommendations TEXT');
  await db.execute('ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT');

  // Vytvořit subtasks tabulku
  await _createSubtasksTable(db);
}
```

---

## 4. IMPLEMENTAČNÍ KROKY

Podle **[mapa-bloc.md → SCÉNÁŘ 1](mapa-bloc.md)** postupujeme v 9 krocích.

---

### ✅ KROK 1: Snapshot commit

```bash
git add -A
git commit -m "🔖 snapshot: Před implementací AI rozděl funkce"
```

**Účel:** Záloha před velkými změnami.

---

### ✅ KROK 2: Vytvořit Feature-First strukturu

**Akce:**
```bash
mkdir -p lib/features/ai_split/presentation/cubit
mkdir -p lib/features/ai_split/presentation/widgets
mkdir -p lib/features/ai_split/data/repositories
mkdir -p lib/features/ai_split/data/models
mkdir -p lib/features/ai_split/data/datasources
mkdir -p lib/features/ai_split/domain/entities
mkdir -p lib/features/ai_split/domain/repositories
```

**Výstup:** Prázdná adresářová struktura.

**Commit:**
```bash
git add lib/features/ai_split/
git commit -m "📁 feat: Vytvořena struktura pro AI Split feature"
```

---

### ✅ KROK 3: Domain Layer (entities + repository interface)

#### 3.1 Entity: `Subtask`

**Soubor:** `lib/features/ai_split/domain/entities/subtask.dart`

```dart
import 'package:equatable/equatable.dart';

/// Subtask entity - Pure Dart object
class Subtask extends Equatable {
  final int? id;
  final int parentTodoId;
  final int subtaskNumber;  // Pořadí (1, 2, 3...)
  final String text;
  final bool completed;
  final DateTime createdAt;

  const Subtask({
    this.id,
    required this.parentTodoId,
    required this.subtaskNumber,
    required this.text,
    this.completed = false,
    required this.createdAt,
  });

  Subtask copyWith({
    int? id,
    int? parentTodoId,
    int? subtaskNumber,
    String? text,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      parentTodoId: parentTodoId ?? this.parentTodoId,
      subtaskNumber: subtaskNumber ?? this.subtaskNumber,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, parentTodoId, subtaskNumber, text, completed, createdAt];
}
```

#### 3.2 Entity: `AiSplitRequest`

**Soubor:** `lib/features/ai_split/domain/entities/ai_split_request.dart`

```dart
import 'package:equatable/equatable.dart';

/// Request pro AI split API
class AiSplitRequest extends Equatable {
  final String taskText;
  final String? priority;
  final DateTime? deadline;
  final List<String> tags;
  final String? userNote;  // Pro retry

  const AiSplitRequest({
    required this.taskText,
    this.priority,
    this.deadline,
    this.tags = const [],
    this.userNote,
  });

  @override
  List<Object?> get props => [taskText, priority, deadline, tags, userNote];
}
```

#### 3.3 Entity: `AiSplitResponse`

**Soubor:** `lib/features/ai_split/domain/entities/ai_split_response.dart`

```dart
import 'package:equatable/equatable.dart';

/// Parsed AI response
class AiSplitResponse extends Equatable {
  final List<String> subtasks;
  final String recommendations;
  final String deadlineAnalysis;

  const AiSplitResponse({
    required this.subtasks,
    required this.recommendations,
    required this.deadlineAnalysis,
  });

  @override
  List<Object?> get props => [subtasks, recommendations, deadlineAnalysis];
}
```

#### 3.4 Repository Interface

**Soubor:** `lib/features/ai_split/domain/repositories/ai_split_repository.dart`

```dart
import '../entities/ai_split_request.dart';
import '../entities/ai_split_response.dart';
import '../entities/subtask.dart';

/// Repository interface pro AI split
abstract class AiSplitRepository {
  /// Zavolat OpenRouter API a vrátit parsed response
  Future<AiSplitResponse> splitTask(AiSplitRequest request);

  /// Uložit subtasks do databáze
  Future<List<Subtask>> saveSubtasks({
    required int parentTodoId,
    required List<String> subtasksTexts,
  });

  /// Získat subtasks pro TODO
  Future<List<Subtask>> getSubtasks(int parentTodoId);

  /// Toggle subtask completed
  Future<void> toggleSubtask(int subtaskId, bool completed);

  /// Smazat subtask
  Future<void> deleteSubtask(int subtaskId);

  /// Update TODO s AI metadata
  Future<void> updateTodoAIMetadata({
    required int todoId,
    String? recommendations,
    String? deadlineAnalysis,
  });
}
```

**Commit:**
```bash
git add lib/features/ai_split/domain/
git commit -m "✨ feat: AI Split domain layer - entities + repository interface"
```

---

### ✅ KROK 4: Data Layer (models + datasource + repository impl)

#### 4.1 Model: `SubtaskModel`

**Soubor:** `lib/features/ai_split/data/models/subtask_model.dart`

```dart
import '../../domain/entities/subtask.dart';

/// Subtask model - DTO pro SQLite mapping
class SubtaskModel extends Subtask {
  const SubtaskModel({
    super.id,
    required super.parentTodoId,
    required super.subtaskNumber,
    required super.text,
    super.completed,
    required super.createdAt,
  });

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] as int?,
      parentTodoId: map['parent_todo_id'] as int,
      subtaskNumber: map['subtask_number'] as int,
      text: map['text'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_todo_id': parentTodoId,
      'subtask_number': subtaskNumber,
      'text': text,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SubtaskModel.fromEntity(Subtask entity) {
    return SubtaskModel(
      id: entity.id,
      parentTodoId: entity.parentTodoId,
      subtaskNumber: entity.subtaskNumber,
      text: entity.text,
      completed: entity.completed,
      createdAt: entity.createdAt,
    );
  }
}
```

#### 4.2 Model: `AiSplitRequestModel`

**Soubor:** `lib/features/ai_split/data/models/ai_split_request_model.dart`

```dart
import '../../domain/entities/ai_split_request.dart';

/// Request model - pro JSON serialization
class AiSplitRequestModel extends AiSplitRequest {
  const AiSplitRequestModel({
    required super.taskText,
    super.priority,
    super.deadline,
    super.tags,
    super.userNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskText': taskText,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'tags': tags,
      if (userNote != null) 'userNote': userNote,
    };
  }
}
```

#### 4.3 DataSource: OpenRouter API

**Soubor:** `lib/features/ai_split/data/datasources/openrouter_datasource.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/ai_split_request.dart';

class OpenRouterDataSource {
  final http.Client client;
  final String baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterDataSource({required this.client});

  /// Zavolat OpenRouter API
  Future<String> splitTask({
    required AiSplitRequest request,
    required String apiKey,
    required String model,
    double temperature = 0.7,
    int maxTokens = 800,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(request);

    final response = await client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('OpenRouter API error: ${response.statusCode}');
    }
  }

  String _buildSystemPrompt() {
    return '''
Jsi asistent pro rozklad složitých úkolů na menší, realizovatelné kroky.

TVŮJ ÚKOL:
1. Rozdělit úkol na 3-8 logických podúkolů
2. Seřadit je chronologicky (první = první krok)
3. Navrhnout konkrétní řešení/tipy/odkazy

FORMÁT ODPOVĚDI:
PODÚKOLY:
1. [krátký, actionable text - max 50 znaků]
2. [další podúkol...]

DOPORUČENÍ:
• [konkrétní tip, link, rada]
• [další rada...]

TERMÍN:
[posouzení reálnosti termínu vzhledem k podúkolům]

PRAVIDLA:
- Každý podúkol MAX 50 znaků
- 3-8 podúkolů (ne víc, ne míň)
- Konkrétní akce, ne abstrakce
- Pokud je úkol jednoduchý: "Tento úkol je již dostatečně konkrétní"
''';
  }

  String _buildUserPrompt(AiSplitRequest request) {
    final buffer = StringBuffer();
    buffer.writeln('ÚKOL: ${request.taskText}');

    if (request.priority != null) {
      buffer.writeln('PRIORITA: ${request.priority}');
    }

    if (request.deadline != null) {
      buffer.writeln('DEADLINE: ${_formatDeadline(request.deadline!)}');
    }

    if (request.tags.isNotEmpty) {
      buffer.writeln('KATEGORIE: ${request.tags.join(", ")}');
    }

    if (request.userNote != null) {
      buffer.writeln('POZNÁMKA UŽIVATELE: ${request.userNote}');
    }

    return buffer.toString();
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.inDays == 0) return 'Dnes';
    if (diff.inDays == 1) return 'Zítra';
    if (diff.inDays < 7) return '${diff.inDays} dní';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()} týdnů';
    return '${(diff.inDays / 30).round()} měsíců';
  }
}
```

#### 4.4 Repository Implementation

**Soubor:** `lib/features/ai_split/data/repositories/ai_split_repository_impl.dart`

```dart
import '../../../../core/services/database_helper.dart';
import '../../domain/entities/ai_split_request.dart';
import '../../domain/entities/ai_split_response.dart';
import '../../domain/entities/subtask.dart';
import '../../domain/repositories/ai_split_repository.dart';
import '../datasources/openrouter_datasource.dart';
import '../models/subtask_model.dart';

class AiSplitRepositoryImpl implements AiSplitRepository {
  final OpenRouterDataSource dataSource;
  final DatabaseHelper db;

  AiSplitRepositoryImpl({
    required this.dataSource,
    required this.db,
  });

  @override
  Future<AiSplitResponse> splitTask(AiSplitRequest request) async {
    // Načíst settings z DB
    final settings = await db.getSettings();
    final apiKey = settings['api_key'] as String?;
    final model = settings['model'] as String;
    final temperature = settings['temperature'] as double;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API klíč není nastaven v nastavení');
    }

    // Zavolat OpenRouter API
    final rawResponse = await dataSource.splitTask(
      request: request,
      apiKey: apiKey,
      model: model,
      temperature: temperature,
      maxTokens: 800,
    );

    // Parsovat odpověď
    return _parseResponse(rawResponse);
  }

  @override
  Future<List<Subtask>> saveSubtasks({
    required int parentTodoId,
    required List<String> subtasksTexts,
  }) async {
    final savedSubtasks = <Subtask>[];
    final now = DateTime.now();

    for (var i = 0; i < subtasksTexts.length; i++) {
      final subtask = SubtaskModel(
        parentTodoId: parentTodoId,
        subtaskNumber: i + 1,
        text: subtasksTexts[i],
        completed: false,
        createdAt: now,
      );

      final id = await db.insertSubtask(subtask.toMap());
      savedSubtasks.add(subtask.copyWith(id: id));
    }

    return savedSubtasks;
  }

  @override
  Future<List<Subtask>> getSubtasks(int parentTodoId) async {
    final maps = await db.getSubtasksByTodoId(parentTodoId);
    return maps.map((map) => SubtaskModel.fromMap(map)).toList();
  }

  @override
  Future<void> toggleSubtask(int subtaskId, bool completed) async {
    await db.toggleSubtaskCompleted(subtaskId, completed);
  }

  @override
  Future<void> deleteSubtask(int subtaskId) async {
    await db.deleteSubtask(subtaskId);
  }

  @override
  Future<void> updateTodoAIMetadata({
    required int todoId,
    String? recommendations,
    String? deadlineAnalysis,
  }) async {
    await db.updateTodoAIMetadata(
      todoId,
      aiRecommendations: recommendations,
      aiDeadlineAnalysis: deadlineAnalysis,
    );
  }

  /// Parse AI response do struktury
  AiSplitResponse _parseResponse(String response) {
    final lines = response.split('\n');
    final subtasks = <String>[];
    final recommendations = <String>[];
    final deadlineAnalysisBuffer = StringBuffer();
    String section = '';

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('PODÚKOLY:')) {
        section = 'subtasks';
      } else if (trimmed.startsWith('DOPORUČENÍ:')) {
        section = 'recommendations';
      } else if (trimmed.startsWith('TERMÍN:')) {
        section = 'deadline';
      }

      // Parse subtasks (1. Text...)
      if (section == 'subtasks' && RegExp(r'^\d+\.').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (text.isNotEmpty) {
          subtasks.add(text);
        }
      }
      // Parse recommendations (• Text...)
      else if (section == 'recommendations' && trimmed.startsWith('•')) {
        recommendations.add(trimmed.substring(1).trim());
      }
      // Parse deadline analysis
      else if (section == 'deadline' && trimmed.isNotEmpty) {
        deadlineAnalysisBuffer.writeln(trimmed);
      }
    }

    return AiSplitResponse(
      subtasks: subtasks,
      recommendations: recommendations.join('\n'),
      deadlineAnalysis: deadlineAnalysisBuffer.toString().trim(),
    );
  }
}
```

**Commit:**
```bash
git add lib/features/ai_split/data/
git commit -m "✨ feat: AI Split data layer - models + datasource + repository"
```

---

### ✅ KROK 5: Presentation Layer (Cubit)

#### 5.1 States

**Soubor:** `lib/features/ai_split/presentation/cubit/ai_split_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_split_response.dart';
import '../../domain/entities/subtask.dart';

sealed class AiSplitState extends Equatable {
  const AiSplitState();

  @override
  List<Object?> get props => [];
}

class AiSplitInitial extends AiSplitState {
  const AiSplitInitial();
}

class AiSplitLoading extends AiSplitState {
  final String taskText;
  final String model;

  const AiSplitLoading({
    required this.taskText,
    required this.model,
  });

  @override
  List<Object?> get props => [taskText, model];
}

class AiSplitLoaded extends AiSplitState {
  final int taskId;
  final AiSplitResponse response;

  const AiSplitLoaded({
    required this.taskId,
    required this.response,
  });

  @override
  List<Object?> get props => [taskId, response];
}

class AiSplitAccepted extends AiSplitState {
  final int taskId;
  final List<Subtask> subtasks;
  final String message;

  const AiSplitAccepted({
    required this.taskId,
    required this.subtasks,
    required this.message,
  });

  @override
  List<Object?> get props => [taskId, subtasks, message];
}

class AiSplitRejected extends AiSplitState {
  const AiSplitRejected();
}

class AiSplitError extends AiSplitState {
  final String message;

  const AiSplitError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### 5.2 Cubit

**Soubor:** `lib/features/ai_split/presentation/cubit/ai_split_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/ai_split_request.dart';
import '../../domain/repositories/ai_split_repository.dart';
import 'ai_split_state.dart';

class AiSplitCubit extends Cubit<AiSplitState> {
  final AiSplitRepository repository;

  AiSplitCubit({required this.repository}) : super(const AiSplitInitial());

  /// Zavolat AI API pro rozdělení úkolu
  Future<void> splitTask({
    required int taskId,
    required String taskText,
    String? priority,
    DateTime? deadline,
    List<String>? tags,
    String? userNote,
  }) async {
    try {
      // Fail Fast: validace
      if (taskText.trim().isEmpty) {
        emit(const AiSplitError('Text úkolu nesmí být prázdný'));
        return;
      }

      emit(AiSplitLoading(
        taskText: taskText,
        model: 'Loading...',  // TODO: Načíst z settings
      ));

      final request = AiSplitRequest(
        taskText: taskText,
        priority: priority,
        deadline: deadline,
        tags: tags ?? [],
        userNote: userNote,
      );

      final response = await repository.splitTask(request);

      // Validace response
      if (response.subtasks.isEmpty) {
        emit(const AiSplitError('AI nevrátilo žádné podúkoly'));
        return;
      }

      if (response.subtasks.length < 3 || response.subtasks.length > 8) {
        emit(const AiSplitError('AI vrátilo neplatný počet podúkolů (${response.subtasks.length})'));
        return;
      }

      emit(AiSplitLoaded(
        taskId: taskId,
        response: response,
      ));
    } catch (e) {
      emit(AiSplitError('Chyba při volání AI: $e'));
    }
  }

  /// Přijmout návrh (uložit do DB)
  Future<void> acceptSuggestion() async {
    final currentState = state;
    if (currentState is! AiSplitLoaded) {
      emit(const AiSplitError('Není co přijmout'));
      return;
    }

    try {
      // Uložit subtasks
      final subtasks = await repository.saveSubtasks(
        parentTodoId: currentState.taskId,
        subtasksTexts: currentState.response.subtasks,
      );

      // Uložit AI metadata
      await repository.updateTodoAIMetadata(
        todoId: currentState.taskId,
        recommendations: currentState.response.recommendations,
        deadlineAnalysis: currentState.response.deadlineAnalysis,
      );

      emit(AiSplitAccepted(
        taskId: currentState.taskId,
        subtasks: subtasks,
        message: '✓ ${subtasks.length} podúkolů přidáno',
      ));
    } catch (e) {
      emit(AiSplitError('Chyba při ukládání: $e'));
    }
  }

  /// Odmítnout návrh
  void rejectSuggestion() {
    emit(const AiSplitRejected());
  }

  /// Znovu vygenerovat s poznámkou
  Future<void> retrySuggestion({
    required int taskId,
    required String taskText,
    required String userNote,
    String? priority,
    DateTime? deadline,
    List<String>? tags,
  }) async {
    await splitTask(
      taskId: taskId,
      taskText: taskText,
      priority: priority,
      deadline: deadline,
      tags: tags,
      userNote: userNote,
    );
  }

  /// Reset state
  void reset() {
    emit(const AiSplitInitial());
  }
}
```

**Commit:**
```bash
git add lib/features/ai_split/presentation/cubit/
git commit -m "✨ feat: AI Split cubit - state management"
```

---

### ✅ KROK 6: UI Widgets

#### 6.1 AI Split Button (🤖 ikona)

**Soubor:** `lib/features/ai_split/presentation/widgets/ai_split_button.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../cubit/ai_split_cubit.dart';
import 'ai_split_dialog.dart';

/// 🤖 ikona v edit režimu
class AiSplitButton extends StatelessWidget {
  final Todo todo;

  const AiSplitButton({
    super.key,
    required this.todo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: const Icon(Icons.smart_toy, size: 24),
      color: theme.appColors.cyan,
      tooltip: 'AI rozděl úkol',
      onPressed: () => _showAiSplitDialog(context),
    );
  }

  void _showAiSplitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AiSplitCubit>(),
        child: AiSplitDialog(todo: todo),
      ),
    );
  }
}
```

#### 6.2 AI Split Dialog

**Soubor:** `lib/features/ai_split/presentation/widgets/ai_split_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../cubit/ai_split_cubit.dart';
import '../cubit/ai_split_state.dart';

class AiSplitDialog extends StatefulWidget {
  final Todo todo;

  const AiSplitDialog({super.key, required this.todo});

  @override
  State<AiSplitDialog> createState() => _AiSplitDialogState();
}

class _AiSplitDialogState extends State<AiSplitDialog> {
  final _retryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Zavolat AI hned při otevření dialogu
    context.read<AiSplitCubit>().splitTask(
          taskId: widget.todo.id!,
          taskText: widget.todo.taskText,
          priority: widget.todo.priority?.name,
          deadline: widget.todo.dueDate,
          tags: widget.todo.tags,
        );
  }

  @override
  void dispose() {
    _retryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.cyan, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: BlocConsumer<AiSplitCubit, AiSplitState>(
          listener: (context, state) {
            // Po akceptaci zavřít dialog
            if (state is AiSplitAccepted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.appColors.green,
                ),
              );
              Navigator.of(context).pop();
            }
            // Po odmítnutí zavřít dialog
            else if (state is AiSplitRejected) {
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const Divider(height: 24),
                Expanded(
                  child: _buildBody(context, state, theme),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.smart_toy, color: theme.appColors.cyan, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '🤖 AI ROZDĚLENÍ ÚKOLU',
            style: TextStyle(
              color: theme.appColors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: theme.appColors.base5),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AiSplitState state, ThemeData theme) {
    return switch (state) {
      AiSplitLoading() => _buildLoading(state, theme),
      AiSplitLoaded() => _buildLoaded(context, state, theme),
      AiSplitError() => _buildError(state, theme),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLoading(AiSplitLoading state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.appColors.cyan),
          const SizedBox(height: 16),
          Text(
            'AI analyzuje úkol...',
            style: TextStyle(color: theme.appColors.fg),
          ),
          const SizedBox(height: 8),
          Text(
            'Model: ${state.model}',
            style: TextStyle(color: theme.appColors.base5, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, AiSplitLoaded state, ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podúkoly
          if (state.response.subtasks.isNotEmpty) ...[
            Text(
              '📋 PODÚKOLY:',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...state.response.subtasks.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}.',
                      style: TextStyle(
                        color: theme.appColors.base5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: theme.appColors.fg),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Doporučení
          if (state.response.recommendations.isNotEmpty) ...[
            Text(
              '💡 DOPORUČENÍ:',
              style: TextStyle(
                color: theme.appColors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.response.recommendations,
              style: TextStyle(color: theme.appColors.fg),
            ),
            const SizedBox(height: 16),
          ],

          // Analýza termínu
          if (state.response.deadlineAnalysis.isNotEmpty) ...[
            Text(
              '⏰ TERMÍN:',
              style: TextStyle(
                color: theme.appColors.magenta,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.response.deadlineAnalysis,
              style: TextStyle(color: theme.appColors.fg),
            ),
            const SizedBox(height: 24),
          ],

          // Akce tlačítka
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Retry s poznámkou
              Expanded(
                child: TextField(
                  controller: _retryController,
                  style: TextStyle(color: theme.appColors.fg),
                  decoration: InputDecoration(
                    hintText: 'Poznámka pro retry...',
                    hintStyle: TextStyle(color: theme.appColors.base5),
                    filled: true,
                    fillColor: theme.appColors.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base4),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.refresh, color: theme.appColors.yellow),
                      onPressed: () => _retry(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Accept / Reject
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => context.read<AiSplitCubit>().rejectSuggestion(),
                child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.read<AiSplitCubit>().acceptSuggestion(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appColors.green,
                  foregroundColor: theme.appColors.bg,
                ),
                child: const Text('Přijmout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(AiSplitError state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.appColors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Chyba',
            style: TextStyle(
              color: theme.appColors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.appColors.fg),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.base3,
            ),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  void _retry(BuildContext context) {
    final note = _retryController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadejte poznámku pro retry')),
      );
      return;
    }

    context.read<AiSplitCubit>().retrySuggestion(
          taskId: widget.todo.id!,
          taskText: widget.todo.taskText,
          userNote: note,
          priority: widget.todo.priority?.name,
          deadline: widget.todo.dueDate,
          tags: widget.todo.tags,
        );

    _retryController.clear();
  }
}
```

#### 6.3 Subtask List View

**Soubor:** `lib/features/ai_split/presentation/widgets/subtask_list_view.dart`

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/subtask.dart';

/// Widget pro zobrazení subtasks v TodoCard
class SubtaskListView extends StatelessWidget {
  final List<Subtask> subtasks;
  final void Function(int subtaskId, bool completed) onToggle;
  final void Function(int subtaskId) onDelete;

  const SubtaskListView({
    super.key,
    required this.subtasks,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = subtasks.where((s) => s.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header s progress
        Row(
          children: [
            Icon(Icons.checklist, color: theme.appColors.cyan, size: 16),
            const SizedBox(width: 8),
            Text(
              'PODÚKOLY ($completedCount/${subtasks.length} hotovo)',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Seznam subtasks
        ...subtasks.map((subtask) => _SubtaskItem(
              subtask: subtask,
              onToggle: onToggle,
              onDelete: onDelete,
            )),
      ],
    );
  }
}

class _SubtaskItem extends StatelessWidget {
  final Subtask subtask;
  final void Function(int subtaskId, bool completed) onToggle;
  final void Function(int subtaskId) onDelete;

  const _SubtaskItem({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: subtask.completed,
            onChanged: (value) => onToggle(subtask.id!, value ?? false),
            activeColor: theme.appColors.green,
          ),

          // Text
          Expanded(
            child: Text(
              '${subtask.subtaskNumber}. ${subtask.text}',
              style: TextStyle(
                color: subtask.completed ? theme.appColors.base5 : theme.appColors.fg,
                decoration: subtask.completed ? TextDecoration.lineThrough : null,
                fontSize: 14,
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete, color: theme.appColors.red, size: 18),
            onPressed: () => onDelete(subtask.id!),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
```

**Commit:**
```bash
git add lib/features/ai_split/presentation/widgets/
git commit -m "✨ feat: AI Split widgets - button, dialog, subtask list"
```

---

### ✅ KROK 7: Integrace do existujících features

#### 7.1 Aktualizace Todo entity

**Soubor:** `lib/features/todo_list/domain/entities/todo.dart`

**Přidat:**
```dart
import '../../../ai_split/domain/entities/subtask.dart';

class Todo extends Equatable {
  // ... existující fieldy ...

  final List<Subtask>? subtasks;           // NOVĚ
  final String? aiRecommendations;         // NOVĚ
  final String? aiDeadlineAnalysis;        // NOVĚ

  const Todo({
    // ... existující parametry ...
    this.subtasks,
    this.aiRecommendations,
    this.aiDeadlineAnalysis,
  });

  Todo copyWith({
    // ... existující parametry ...
    List<Subtask>? subtasks,
    String? aiRecommendations,
    String? aiDeadlineAnalysis,
  }) {
    return Todo(
      // ... existující kopie ...
      subtasks: subtasks ?? this.subtasks,
      aiRecommendations: aiRecommendations ?? this.aiRecommendations,
      aiDeadlineAnalysis: aiDeadlineAnalysis ?? this.aiDeadlineAnalysis,
    );
  }

  @override
  List<Object?> get props => [
    // ... existující props ...
    subtasks,
    aiRecommendations,
    aiDeadlineAnalysis,
  ];
}
```

#### 7.2 Aktualizace TodoModel

**Soubor:** `lib/features/todo_list/data/models/todo_model.dart`

**Přidat:**
```dart
import '../../../ai_split/data/models/subtask_model.dart';
import '../../../ai_split/domain/entities/subtask.dart';

class TodoModel extends Todo {
  const TodoModel({
    // ... existující parametry ...
    super.subtasks,
    super.aiRecommendations,
    super.aiDeadlineAnalysis,
  });

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      // ... existující mapping ...

      // NOVĚ - zatím null, načteme později
      subtasks: null,  // Načte se v repository
      aiRecommendations: map['ai_recommendations'] as String?,
      aiDeadlineAnalysis: map['ai_deadline_analysis'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // ... existující mapping ...
      'ai_recommendations': aiRecommendations,
      'ai_deadline_analysis': aiDeadlineAnalysis,
    };
  }
}
```

#### 7.3 Aktualizace TodoRepositoryImpl

**Soubor:** `lib/features/todo_list/data/repositories/todo_repository_impl.dart`

**Přidat:**
```dart
import '../../../ai_split/data/models/subtask_model.dart';
import '../../../ai_split/domain/repositories/ai_split_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  final DatabaseHelper _db;
  final AiSplitRepository _aiSplitRepository;  // NOVĚ

  TodoRepositoryImpl(this._db, this._aiSplitRepository);

  @override
  Future<List<Todo>> getAllTodos() async {
    final maps = await _db.getAllTodos();
    final todos = <Todo>[];

    for (final map in maps) {
      final todo = TodoModel.fromMap(map);

      // Načíst subtasks pro tento todo
      final subtasks = await _aiSplitRepository.getSubtasks(todo.id!);

      todos.add(todo.copyWith(subtasks: subtasks));
    }

    return todos;
  }

  // ... zbytek metod ...
}
```

#### 7.4 Přidat AI Split Button do TodoCard

**Soubor:** `lib/features/todo_list/presentation/widgets/todo_card.dart`

**V edit režimu přidat:**
```dart
import '../../../ai_split/presentation/widgets/ai_split_button.dart';
import '../../../ai_split/presentation/widgets/subtask_list_view.dart';

// V _TodoCardEditState build() metodě:

Row(
  children: [
    // ... existující tlačítka ...

    // NOVĚ: AI Split button
    AiSplitButton(todo: widget.todo),

    IconButton(
      icon: const Icon(Icons.close),
      onPressed: widget.onCancel,
    ),
  ],
)

// Pod textem úkolu zobrazit subtasks:
if (widget.todo.subtasks != null && widget.todo.subtasks!.isNotEmpty) ...[
  const SizedBox(height: 16),
  SubtaskListView(
    subtasks: widget.todo.subtasks!,
    onToggle: (subtaskId, completed) {
      context.read<AiSplitCubit>().toggleSubtask(subtaskId, completed);
      // Reload todos
      context.read<TodoListBloc>().add(const LoadTodosEvent());
    },
    onDelete: (subtaskId) {
      context.read<AiSplitCubit>().deleteSubtask(subtaskId);
      // Reload todos
      context.read<TodoListBloc>().add(const LoadTodosEvent());
    },
  ),
],
```

**Commit:**
```bash
git add lib/features/todo_list/
git commit -m "♻️ refactor: Integrace AI Split do Todo entity a TodoCard"
```

---

### ✅ KROK 8: Dependency Injection (DI)

**Soubor:** `lib/main.dart`

**Přidat:**
```dart
import 'package:http/http.dart' as http;
import 'features/ai_split/data/datasources/openrouter_datasource.dart';
import 'features/ai_split/data/repositories/ai_split_repository_impl.dart';
import 'features/ai_split/presentation/cubit/ai_split_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper();
    final httpClient = http.Client();

    // AI Split dependencies
    final openRouterDataSource = OpenRouterDataSource(client: httpClient);
    final aiSplitRepository = AiSplitRepositoryImpl(
      dataSource: openRouterDataSource,
      db: db,
    );

    return MultiRepositoryProvider(
      providers: [
        // ... existující providers ...

        RepositoryProvider<AiSplitRepository>(
          create: (_) => aiSplitRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          // ... existující providers ...

          BlocProvider<AiSplitCubit>(
            create: (_) => AiSplitCubit(repository: aiSplitRepository),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return MaterialApp(
              // ... zbytek ...
            );
          },
        ),
      ),
    );
  }
}
```

**Commit:**
```bash
git add lib/main.dart
git commit -m "🔧 config: DI setup pro AI Split feature"
```

---

### ✅ KROK 9: DatabaseHelper - SQL migrace

**Soubor:** `lib/core/services/database_helper.dart`

**Přidat:**
```dart
// Verze databáze
static const int _version = 3;  // ZVÝŠIT z 2 na 3

// V onCreate:
Future<void> _onCreate(Database db, int version) async {
  // ... existující tabulky ...

  // NOVĚ: Subtasks tabulka
  await db.execute('''
    CREATE TABLE subtasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_todo_id INTEGER NOT NULL,
      subtask_number INTEGER NOT NULL,
      text TEXT NOT NULL,
      completed INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(parent_todo_id) REFERENCES todos(id) ON DELETE CASCADE,
      UNIQUE(parent_todo_id, subtask_number)
    )
  ''');

  await db.execute('CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id)');
}

// V onUpgrade:
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 3) {
    // Přidat AI sloupce do todos
    await db.execute('ALTER TABLE todos ADD COLUMN ai_recommendations TEXT');
    await db.execute('ALTER TABLE todos ADD COLUMN ai_deadline_analysis TEXT');

    // Vytvořit subtasks tabulku
    await db.execute('''
      CREATE TABLE subtasks (...)
    ''');

    await db.execute('CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id)');
  }
}

// CRUD metody:
Future<int> insertSubtask(Map<String, dynamic> subtask) async {
  final db = await database;
  return await db.insert('subtasks', subtask);
}

Future<List<Map<String, dynamic>>> getSubtasksByTodoId(int todoId) async {
  final db = await database;
  return await db.query(
    'subtasks',
    where: 'parent_todo_id = ?',
    whereArgs: [todoId],
    orderBy: 'subtask_number ASC',
  );
}

Future<int> updateSubtask(int id, Map<String, dynamic> subtask) async {
  final db = await database;
  return await db.update(
    'subtasks',
    subtask,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> deleteSubtask(int id) async {
  final db = await database;
  return await db.delete('subtasks', where: 'id = ?', whereArgs: [id]);
}

Future<int> toggleSubtaskCompleted(int id, bool completed) async {
  final db = await database;
  return await db.update(
    'subtasks',
    {'completed': completed ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> updateTodoAIMetadata(
  int id, {
  String? aiRecommendations,
  String? aiDeadlineAnalysis,
}) async {
  final db = await database;
  final updates = <String, dynamic>{};

  if (aiRecommendations != null) updates['ai_recommendations'] = aiRecommendations;
  if (aiDeadlineAnalysis != null) updates['ai_deadline_analysis'] = aiDeadlineAnalysis;

  return await db.update('todos', updates, where: 'id = ?', whereArgs: [id]);
}
```

**Commit:**
```bash
git add lib/core/services/database_helper.dart
git commit -m "💾 feat: Databázová migrace pro AI Split - subtasks tabulka"
```

---

## 5. TESTING

### Unit Tests

**Soubor:** `test/features/ai_split/domain/entities/subtask_test.dart`

```dart
test('Subtask copyWith creates new instance with updated values', () {
  final subtask = Subtask(...);
  final updated = subtask.copyWith(completed: true);
  expect(updated.completed, true);
});
```

**Soubor:** `test/features/ai_split/data/repositories/ai_split_repository_impl_test.dart`

```dart
test('parseResponse extracts subtasks correctly', () {
  final response = '''
PODÚKOLY:
1. First task
2. Second task

DOPORUČENÍ:
• Tip one
''';

  final parsed = repository._parseResponse(response);
  expect(parsed.subtasks, ['First task', 'Second task']);
});
```

### Widget Tests

**Soubor:** `test/features/ai_split/presentation/widgets/ai_split_button_test.dart`

```dart
testWidgets('AiSplitButton shows dialog on tap', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AiSplitButton(todo: mockTodo),
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.smart_toy));
  await tester.pumpAndSettle();

  expect(find.text('🤖 AI ROZDĚLENÍ ÚKOLU'), findsOneWidget);
});
```

**Commit:**
```bash
git add test/
git commit -m "✅ test: Unit + widget testy pro AI Split feature"
```

---

## 6. DEPLOYMENT

### Build

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Final Commit

```bash
git add -A
git commit -m "🚀 feat: AI Split úkol - kompletní implementace

✨ Nová funkce:
- 🤖 AI ikona v edit režimu úkolu
- 📋 Rozdělení na 3-8 podúkolů
- 💡 Doporučení a analýza termínu
- ✅ Accept/Reject/Retry workflow
- 💾 Subtasks v SQLite DB s CASCADE delete

🏗️ Architektura:
- Feature-First + BLoC pattern
- Clean Architecture (Domain/Data/Presentation)
- Repository pattern pro AI API
- Immutable state s Equatable

🔧 Technologie:
- OpenRouter API (Grok Beta default)
- SQLite relational DB
- Flutter BLoC state management

📚 Dokumentace: rodel.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 📚 REFERENCE

- **Tauri projekt**: `d:\01_programovani\tauri-todo-linux\`
- **Architektura**: `mapa-bloc.md`, `bloc.md`
- **BLoC pattern**: `lib/features/todo_list/presentation/bloc/`

---

## ✅ CHECKLIST PŘED IMPLEMENTACÍ

- [ ] Přečetl jsem `mapa-bloc.md` → SCÉNÁŘ 1
- [ ] Přečetl jsem `bloc.md` → Jak přidávat features
- [ ] Snapshot commit vytvořen
- [ ] Database backup před migrací
- [ ] API klíč v settings nastaven

---

**Verze**: 1.0
**Vytvořeno**: 2025-10-09
**Autor**: Claude Code (AI asistent)
**Status**: 📋 Plán připraven k implementaci

🎯 **Následující krok**: Snapshot commit a vytvoření adresářové struktury
