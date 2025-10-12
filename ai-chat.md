# 🤖 AI CHAT - Konverzace s AI asistentem nad konkrétním úkolem

**Datum vytvoření**: 2025-10-12
**Účel**: Přidat AI chat pro diskuzi s AI asistentem v kontextu konkrétního TODO úkolu
**Inspirace**: ChatGPT, Claude - konverzační AI s kontextem

---

## 🎯 CÍL

Vytvořit **chat interface** pro konverzaci s AI asistentem, který má plný kontext konkrétního úkolu:

**Co AI asistent vidí:**
- ✅ Celý obsah úkolu (task, priority, deadline, tags)
- ✅ Všechny podúkoly (subtasks) včetně completion stavu
- ✅ AI recommendations (z předchozího AI Split)
- ✅ AI deadline analysis
- ✅ Historie Pomodoro sessions (kolik času stráveno na úkolu)
- ✅ Metadata (created_at, updated_at, completion status)

**Použití:**
- 💡 Poradit se s AI jak úkol rozdělit jinak
- 📝 Požádat o detailní rozpis konkrétního podúkolu
- ⏰ Konzultovat deadline a prioritizaci
- 🧠 Brainstorming nad řešením problému
- 📊 Analýza progresu (kolik Pomodoro sessions, co zbývá)

---

## 🏗️ ARCHITEKTURA

### **Feature Structure**

```
lib/features/ai_chat/
├── presentation/
│   ├── pages/
│   │   └── ai_chat_page.dart          # 🆕 Chat page (fullscreen)
│   ├── widgets/
│   │   ├── chat_message_bubble.dart   # 🆕 Message bubble (user/AI)
│   │   ├── chat_input.dart            # 🆕 Input field + send button
│   │   ├── typing_indicator.dart      # 🆕 AI typing animation
│   │   └── context_summary_card.dart  # 🆕 Kompaktní summary úkolu (nahoře)
│   ├── bloc/
│   │   ├── ai_chat_bloc.dart          # 🆕 BLoC pro chat state
│   │   ├── ai_chat_event.dart         # 🆕 Events
│   │   └── ai_chat_state.dart         # 🆕 States
│   └── cubit/
│       └── chat_history_cubit.dart    # 🆕 Persistence historie (optional)
├── domain/
│   ├── entities/
│   │   ├── chat_message.dart          # 🆕 Message entity (role: user/assistant)
│   │   ├── chat_session.dart          # 🆕 Session entity (messages + metadata)
│   │   └── task_context.dart          # 🆕 Context data (todo + subtasks + pomodoro)
│   ├── repositories/
│   │   └── ai_chat_repository.dart    # 🆕 Interface
│   └── usecases/
│       └── send_message_usecase.dart  # 🆕 Business logic (optional)
└── data/
    ├── repositories/
    │   └── ai_chat_repository_impl.dart  # 🆕 Implementation
    ├── datasources/
    │   └── openrouter_chat_datasource.dart  # 🆕 OpenRouter API client
    └── models/
        ├── chat_message_model.dart      # 🆕 DTO
        └── openrouter_chat_request.dart  # 🆕 API request model
```

---

## 🎨 UI/UX DESIGN

### **1. Entry Point - TodoCard 🤖 ikona**

**Umístění:** TodoCard má novou ikonu "🤖 AI Chat" vedle existujících akcí

```
┌─────────────────────────────────────────────────────┐
│ 🔴 A │ Nakoupit │ ⏰ Dnes │ 🛒 rodina │              │
│                                                      │
│ [✏️ Edit] [🗑️ Delete] [🍅 Pomodoro] [🤖 AI Chat]  │ <- NOVÁ AKCE
└─────────────────────────────────────────────────────┘
```

**Implementace:**
```dart
// lib/features/todo_list/presentation/widgets/todo_card.dart
IconButton(
  icon: const Icon(Icons.smart_toy), // nebo emoji 🤖
  tooltip: 'Chat s AI asistentem',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatPage(
          todo: todo,
          subtasks: subtasks,
          pomodoroSessions: pomodoroSessions,
        ),
      ),
    );
  },
)
```

---

### **2. AI Chat Page - Fullscreen Layout**

**Struktura:**

```
┌───────────────────────────────────────────────────────┐
│  ← AI Chat: "Nakoupit"                     [📋] [⚙️] │ <- AppBar
├───────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐ │
│  │ 📋 Úkol: Nakoupit                               │ │ <- Context Summary Card
│  │ 🔴 A │ ⏰ Dnes │ 3/5 podúkolů │ 🍅 2 sessions    │ │ (expandable)
│  └─────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 💬 Jak ti můžu pomoct s tímto úkolem?          │ │ <- AI Message (left)
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│                  ┌─────────────────────────────────┐ │
│                  │ Můžeš mi poradit jak naplánovat│ │ <- User Message (right)
│                  │ nákup aby to trvalo co nejméně?│ │
│                  └─────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 💡 Doporučuji rozdělit nákup podle obchodů:    │ │ <- AI Message
│  │ 1. Albert (potraviny) - 20 min                 │ │
│  │ 2. DM (drogerie) - 10 min                      │ │
│  │ 3. Lidl (doplňky) - 15 min                     │ │
│  │ Celkem: ~45 minut                              │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ AI píše...                                      │ │ <- Typing Indicator
│  └─────────────────────────────────────────────────┘ │
│                                                       │
├───────────────────────────────────────────────────────┤
│  [TextField: Zeptej se AI...]              [➤ Send] │ <- Input Bar (fixed)
└───────────────────────────────────────────────────────┘
```

**Klíčové prvky:**

1. **Context Summary Card** (nahoře)
   - Kompaktní přehled úkolu
   - Expandable (klik → zobrazí všechny podúkoly + metadata)
   - Použitelné jako reference při scrollování

2. **Chat Messages** (scrollable)
   - AI messages: Vlevo, šedé bubliny
   - User messages: Vpravo, accent color bubliny
   - Markdown support (bold, lists, links)
   - Copy button na každé AI message

3. **Typing Indicator**
   - Animované "..." při čekání na AI odpověď
   - Scrolluje automaticky dolů

4. **Input Bar** (fixed bottom)
   - TextField s multiline support
   - Send button (disabled když prázdný text)
   - Keyboard aware (push content nahoru)

---

### **3. Context Summary Card**

**Collapsed State:**
```
┌─────────────────────────────────────────────────────┐
│ 📋 Úkol: Nakoupit                          [▼]     │
│ 🔴 A │ ⏰ Dnes │ 3/5 podúkolů │ 🍅 2 sessions       │
└─────────────────────────────────────────────────────┘
```

**Expanded State:**
```
┌─────────────────────────────────────────────────────┐
│ 📋 Úkol: Nakoupit                          [▲]     │
│ 🔴 A │ ⏰ Dnes │ 🛒 rodina, nakup                   │
├─────────────────────────────────────────────────────┤
│ Podúkoly (3/5 hotovo):                              │
│ ✅ 1. Koupit mléko                                  │
│ ✅ 2. Koupit chléb                                  │
│ ✅ 3. Koupit máslo                                  │
│ ☐ 4. Koupit jogurt                                  │
│ ☐ 5. Koupit ovoce                                   │
├─────────────────────────────────────────────────────┤
│ 🍅 Pomodoro: 2 sessions (50 min celkem)             │
│ 💡 AI doporučení: Rozdělit podle obchodů            │
│ 📅 Deadline analýza: Stihnout dnes odpoledne        │
└─────────────────────────────────────────────────────┘
```

**Implementace:**
```dart
class ContextSummaryCard extends StatefulWidget {
  final Todo todo;
  final List<Subtask> subtasks;
  final List<PomodoroSession> pomodoroSessions;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('📋 Úkol: ${todo.task}'),
      subtitle: _buildSummaryLine(),
      children: [
        _buildSubtasksList(),
        _buildPomodoroSummary(),
        _buildAIMetadata(),
      ],
    );
  }
}
```

---

## 🔧 IMPLEMENTACE

### **Krok 1: Domain Layer** (30 min)

#### **1.1 ChatMessage Entity**

**`lib/features/ai_chat/domain/entities/chat_message.dart`**
```dart
import 'package:equatable/equatable.dart';

/// Message v AI chat konverzaci
class ChatMessage extends Equatable {
  /// Unique ID (pro ListView keys)
  final String id;

  /// Role: 'user' nebo 'assistant'
  final String role;

  /// Obsah zprávy
  final String content;

  /// Timestamp
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Factory pro user message
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Factory pro AI assistant message
  factory ChatMessage.assistant(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Je to user message?
  bool get isUser => role == 'user';

  /// Je to AI message?
  bool get isAssistant => role == 'assistant';

  @override
  List<Object?> get props => [id, role, content, timestamp];
}
```

---

#### **1.2 TaskContext Entity**

**`lib/features/ai_chat/domain/entities/task_context.dart`**
```dart
import '../../../todo_list/domain/entities/todo.dart';
import '../../../ai_split/domain/entities/subtask.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';

/// Kontext úkolu pro AI chat
///
/// Obsahuje všechna relevantní data pro AI asistenta:
/// - Hlavní úkol (task, priority, deadline, tags)
/// - Podúkoly (subtasks) včetně completion stavu
/// - Pomodoro sessions (čas strávený na úkolu)
/// - AI metadata (recommendations, deadline analysis)
class TaskContext {
  /// Hlavní TODO úkol
  final Todo todo;

  /// Podúkoly (pokud existují)
  final List<Subtask> subtasks;

  /// Pomodoro sessions (historie práce na úkolu)
  final List<PomodoroSession> pomodoroSessions;

  const TaskContext({
    required this.todo,
    this.subtasks = const [],
    this.pomodoroSessions = const [],
  });

  /// Vytvoř system prompt pro AI
  ///
  /// Toto je první message v konverzaci, která dává AI kontext.
  String toSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('Jsi AI asistent pomáhající s TODO úkolem.');
    buffer.writeln('');
    buffer.writeln('KONTEXT ÚKOLU:');
    buffer.writeln('Název: ${todo.task}');

    if (todo.priority != null) {
      buffer.writeln('Priorita: ${todo.priority!.toUpperCase()}');
    }

    if (todo.dueDate != null) {
      buffer.writeln('Deadline: ${_formatDate(todo.dueDate!)}');
    }

    if (todo.tags.isNotEmpty) {
      buffer.writeln('Tagy: ${todo.tags.join(", ")}');
    }

    buffer.writeln('Stav: ${todo.isCompleted ? "✅ Hotovo" : "⏳ Aktivní"}');

    // Podúkoly
    if (subtasks.isNotEmpty) {
      final completed = subtasks.where((s) => s.completed).length;
      buffer.writeln('');
      buffer.writeln('PODÚKOLY ($completed/${subtasks.length} hotovo):');
      for (var subtask in subtasks) {
        buffer.writeln('${subtask.completed ? "✅" : "☐"} ${subtask.subtaskNumber}. ${subtask.text}');
      }
    }

    // Pomodoro sessions
    if (pomodoroSessions.isNotEmpty) {
      final totalMinutes = pomodoroSessions.fold<int>(
        0,
        (sum, session) => sum + session.durationMinutes,
      );
      buffer.writeln('');
      buffer.writeln('HISTORIE PRÁCE:');
      buffer.writeln('🍅 Pomodoro sessions: ${pomodoroSessions.length}x');
      buffer.writeln('⏱️ Celkový čas: $totalMinutes minut');
    }

    // AI metadata
    if (todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('AI DOPORUČENÍ:');
      buffer.writeln(todo.aiRecommendations);
    }

    if (todo.aiDeadlineAnalysis != null && todo.aiDeadlineAnalysis!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('AI ANALÝZA TERMÍNU:');
      buffer.writeln(todo.aiDeadlineAnalysis);
    }

    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Tvoje role: Pomáhej uživateli s tímto úkolem. Buď konstruktivní, konkrétní a praktický.');

    return buffer.toString();
  }

  /// Format date to Czech format
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Počet dokončených podúkolů
  int get completedSubtasks => subtasks.where((s) => s.completed).length;

  /// Celkový čas strávený na úkolu (v minutách)
  int get totalPomodoroMinutes => pomodoroSessions.fold<int>(
    0,
    (sum, session) => sum + session.durationMinutes,
  );
}
```

---

#### **1.3 Repository Interface**

**`lib/features/ai_chat/domain/repositories/ai_chat_repository.dart`**
```dart
import '../entities/chat_message.dart';
import '../entities/task_context.dart';

/// Repository interface pro AI chat
abstract class AiChatRepository {
  /// Poslat zprávu AI a získat odpověď
  ///
  /// [taskContext] - kontext úkolu (první message = system prompt)
  /// [messages] - historie konverzace
  /// [userMessage] - aktuální user message
  ///
  /// Returns: AI odpověď
  Future<ChatMessage> sendMessage({
    required TaskContext taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  });

  /// Optional: Uložit chat historii do DB (pro persistence)
  Future<void> saveChatHistory(int todoId, List<ChatMessage> messages);

  /// Optional: Načíst chat historii z DB
  Future<List<ChatMessage>> loadChatHistory(int todoId);

  /// Optional: Smazat chat historii
  Future<void> clearChatHistory(int todoId);
}
```

---

### **Krok 2: Data Layer** (1.5h)

#### **2.1 OpenRouter Chat DataSource**

**`lib/features/ai_chat/data/datasources/openrouter_chat_datasource.dart`**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';

/// OpenRouter Chat Completion API client
///
/// Docs: https://openrouter.ai/docs/api-reference/chat-completion
class OpenRouterChatDataSource {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _chatEndpoint = '/chat/completions';

  final http.Client client;

  OpenRouterChatDataSource({http.Client? client})
      : client = client ?? http.Client();

  /// Poslat chat message a získat AI odpověď
  ///
  /// [apiKey] - OpenRouter API key
  /// [model] - Model ID (např. 'anthropic/claude-3.5-sonnet')
  /// [taskContext] - Kontext úkolu
  /// [messages] - Historie konverzace
  /// [userMessage] - Aktuální user message
  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required TaskContext taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  }) async {
    AppLogger.debug('🤖 AI Chat - Sending message to OpenRouter...');
    AppLogger.debug('Model: $model');
    AppLogger.debug('User message: $userMessage');

    try {
      // Sestavit messages array pro OpenRouter API
      final apiMessages = _buildMessagesArray(
        taskContext: taskContext,
        messages: messages,
        userMessage: userMessage,
      );

      // API request
      final response = await client.post(
        Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://todo-app.local',
          'X-Title': 'TODO App - AI Chat',
        },
        body: jsonEncode({
          'model': model,
          'messages': apiMessages,
          'temperature': 0.7, // Mírně kreativní (není to JSON generation)
          'max_tokens': 1000, // Delší odpovědi jsou OK
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'OpenRouter API error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;

      AppLogger.debug('✅ AI Chat - Response received (${content.length} chars)');
      return content;
    } catch (e) {
      AppLogger.error('❌ AI Chat - Error: $e');
      rethrow;
    }
  }

  /// Sestavit messages array pro OpenRouter API
  ///
  /// Format:
  /// [
  ///   {"role": "system", "content": "Kontext úkolu..."},
  ///   {"role": "user", "content": "První otázka"},
  ///   {"role": "assistant", "content": "První odpověď"},
  ///   {"role": "user", "content": "Aktuální otázka"}
  /// ]
  List<Map<String, String>> _buildMessagesArray({
    required TaskContext taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  }) {
    final apiMessages = <Map<String, String>>[];

    // 1. System prompt (kontext úkolu)
    apiMessages.add({
      'role': 'system',
      'content': taskContext.toSystemPrompt(),
    });

    // 2. Historie konverzace
    for (var msg in messages) {
      apiMessages.add({
        'role': msg.role,
        'content': msg.content,
      });
    }

    // 3. Aktuální user message
    apiMessages.add({
      'role': 'user',
      'content': userMessage,
    });

    AppLogger.debug('📝 Messages array: ${apiMessages.length} messages');
    return apiMessages;
  }
}
```

---

#### **2.2 Repository Implementation**

**`lib/features/ai_chat/data/repositories/ai_chat_repository_impl.dart`**
```dart
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/openrouter_chat_datasource.dart';

/// Implementace AiChatRepository
class AiChatRepositoryImpl implements AiChatRepository {
  final OpenRouterChatDataSource dataSource;
  final DatabaseHelper db;

  AiChatRepositoryImpl({
    required this.dataSource,
    required this.db,
  });

  @override
  Future<ChatMessage> sendMessage({
    required TaskContext taskContext,
    required List<ChatMessage> messages,
    required String userMessage,
  }) async {
    // Načíst settings z DB
    final settings = await db.getSettings();
    final apiKey = settings['openrouter_api_key'] as String?;
    final model = settings['ai_task_model'] as String; // Použít task model (inteligentní)

    // Fail Fast: validace API klíče
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API klíč není nastaven v nastavení');
    }

    // Zavolat OpenRouter API
    final responseText = await dataSource.sendMessage(
      apiKey: apiKey,
      model: model,
      taskContext: taskContext,
      messages: messages,
      userMessage: userMessage,
    );

    // Vrátit jako ChatMessage entity
    return ChatMessage.assistant(responseText);
  }

  @override
  Future<void> saveChatHistory(int todoId, List<ChatMessage> messages) async {
    // TODO: Implementovat persistence do DB (optional v1.0)
    // Pro v1.0: Chat history je jen v paměti (session-based)
    AppLogger.debug('💾 Chat history save skipped (not implemented yet)');
  }

  @override
  Future<List<ChatMessage>> loadChatHistory(int todoId) async {
    // TODO: Implementovat load z DB (optional v1.0)
    AppLogger.debug('📂 Chat history load skipped (not implemented yet)');
    return [];
  }

  @override
  Future<void> clearChatHistory(int todoId) async {
    // TODO: Implementovat clear z DB (optional v1.0)
    AppLogger.debug('🗑️ Chat history clear skipped (not implemented yet)');
  }
}
```

---

### **Krok 3: Presentation Layer (BLoC)** (1h)

#### **3.1 Events**

**`lib/features/ai_chat/presentation/bloc/ai_chat_event.dart`**
```dart
import 'package:equatable/equatable.dart';

/// Events pro AI chat
sealed class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

/// Poslat zprávu AI
final class SendMessageEvent extends AiChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Vymazat chat historii
final class ClearChatEvent extends AiChatEvent {
  const ClearChatEvent();
}

/// Načíst historii z DB (optional)
final class LoadChatHistoryEvent extends AiChatEvent {
  const LoadChatHistoryEvent();
}
```

---

#### **3.2 States**

**`lib/features/ai_chat/presentation/bloc/ai_chat_state.dart`**
```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

/// States pro AI chat
sealed class AiChatState extends Equatable {
  const AiChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state - prázdný chat
final class AiChatInitial extends AiChatState {
  const AiChatInitial();
}

/// Loaded state - konverzace běží
final class AiChatLoaded extends AiChatState {
  /// Historie zpráv
  final List<ChatMessage> messages;

  /// AI právě odpovídá?
  final bool isTyping;

  const AiChatLoaded({
    required this.messages,
    this.isTyping = false,
  });

  AiChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return AiChatLoaded(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  @override
  List<Object?> get props => [messages, isTyping];
}

/// Error state
final class AiChatError extends AiChatState {
  final String message;

  const AiChatError(this.message);

  @override
  List<Object?> get props => [message];
}
```

---

#### **3.3 BLoC**

**`lib/features/ai_chat/presentation/bloc/ai_chat_bloc.dart`**
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/task_context.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

/// BLoC pro AI chat
class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiChatRepository repository;
  final TaskContext taskContext;

  AiChatBloc({
    required this.repository,
    required this.taskContext,
  }) : super(const AiChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
  }

  /// Poslat zprávu AI
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final currentState = state;

    // Validace
    if (event.message.trim().isEmpty) {
      return;
    }

    // Přidat user message
    final userMessage = ChatMessage.user(event.message);
    final messages = currentState is AiChatLoaded
        ? [...currentState.messages, userMessage]
        : [userMessage];

    // Emit loading state (AI typing)
    emit(AiChatLoaded(messages: messages, isTyping: true));

    try {
      // Zavolat repository
      final aiResponse = await repository.sendMessage(
        taskContext: taskContext,
        messages: messages.sublist(0, messages.length - 1), // Bez poslední user message
        userMessage: event.message,
      );

      // Přidat AI response
      final updatedMessages = [...messages, aiResponse];

      // Emit loaded state
      emit(AiChatLoaded(messages: updatedMessages, isTyping: false));
    } catch (e) {
      emit(AiChatError('Chyba při komunikaci s AI: $e'));
    }
  }

  /// Vymazat chat
  void _onClearChat(ClearChatEvent event, Emitter<AiChatState> emit) {
    emit(const AiChatInitial());
  }

  /// Načíst historii (optional)
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<AiChatState> emit,
  ) async {
    try {
      final messages = await repository.loadChatHistory(taskContext.todo.id!);
      if (messages.isNotEmpty) {
        emit(AiChatLoaded(messages: messages));
      }
    } catch (e) {
      emit(AiChatError('Chyba při načítání historie: $e'));
    }
  }
}
```

---

### **Krok 4: UI Implementation** (2-3h)

#### **4.1 AI Chat Page**

**`lib/features/ai_chat/presentation/pages/ai_chat_page.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/database_helper.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../ai_split/domain/entities/subtask.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';
import '../../data/datasources/openrouter_chat_datasource.dart';
import '../../data/repositories/ai_chat_repository_impl.dart';
import '../../domain/entities/task_context.dart';
import '../bloc/ai_chat_bloc.dart';
import '../bloc/ai_chat_event.dart';
import '../bloc/ai_chat_state.dart';
import '../widgets/context_summary_card.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input.dart';

/// AI Chat Page - konverzace s AI asistentem nad úkolem
class AiChatPage extends StatelessWidget {
  final Todo todo;
  final List<Subtask> subtasks;
  final List<PomodoroSession> pomodoroSessions;

  const AiChatPage({
    super.key,
    required this.todo,
    this.subtasks = const [],
    this.pomodoroSessions = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Vytvořit task context
    final taskContext = TaskContext(
      todo: todo,
      subtasks: subtasks,
      pomodoroSessions: pomodoroSessions,
    );

    // Vytvořit repository
    final repository = AiChatRepositoryImpl(
      dataSource: OpenRouterChatDataSource(),
      db: DatabaseHelper.instance,
    );

    return BlocProvider(
      create: (_) => AiChatBloc(
        repository: repository,
        taskContext: taskContext,
      ),
      child: _AiChatPageView(taskContext: taskContext),
    );
  }
}

/// Internal view widget
class _AiChatPageView extends StatefulWidget {
  final TaskContext taskContext;

  const _AiChatPageView({required this.taskContext});

  @override
  State<_AiChatPageView> createState() => _AiChatPageViewState();
}

class _AiChatPageViewState extends State<_AiChatPageView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to bottom (po přidání nové zprávy)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('🤖 AI Chat: ${widget.taskContext.todo.task}'),
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vymazat chat',
            onPressed: () {
              context.read<AiChatBloc>().add(const ClearChatEvent());
            },
          ),
          // Info button (expand context summary)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Zobrazit kontext',
            onPressed: () {
              // TODO: Scroll to top / expand summary
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Summary Card (top)
          ContextSummaryCard(taskContext: widget.taskContext),

          const Divider(height: 1),

          // Chat Messages (scrollable)
          Expanded(
            child: BlocConsumer<AiChatBloc, AiChatState>(
              listener: (context, state) {
                // Auto-scroll po přidání zprávy
                if (state is AiChatLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is AiChatInitial) {
                  return _buildEmptyState();
                }

                if (state is AiChatError) {
                  return _buildErrorState(state.message);
                }

                if (state is AiChatLoaded) {
                  return _buildChatList(state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          const Divider(height: 1),

          // Chat Input (bottom)
          ChatInput(
            onSend: (message) {
              context.read<AiChatBloc>().add(SendMessageEvent(message));
            },
          ),
        ],
      ),
    );
  }

  /// Empty state - první návštěva chatu
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '💬 Jak ti můžu pomoct s tímto úkolem?',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Zeptej se na cokoliv - plánování, rozdělení úkolu, tipy na efektivitu...',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Chyba',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Chat list
  Widget _buildChatList(AiChatLoaded state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator na konci
        if (state.isTyping && index == state.messages.length) {
          return const TypingIndicator();
        }

        final message = state.messages[index];
        return ChatMessageBubble(message: message);
      },
    );
  }
}
```

---

#### **4.2 ChatMessageBubble Widget**

**`lib/features/ai_chat/presentation/widgets/chat_message_bubble.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/chat_message.dart';

/// Message bubble v chatu
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 6),

            // Timestamp + Copy button (jen pro AI)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(context, message.content),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format timestamp (HH:MM)
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Copy to clipboard
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📋 Zkopírováno do schránky')),
    );
  }
}
```

---

#### **4.3 TypingIndicator Widget**

**`lib/features/ai_chat/presentation/widgets/typing_indicator.dart`**
```dart
import 'package:flutter/material.dart';

/// AI typing indicator (animované "...")
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final delay = index * 0.2;
        final opacity = ((_controller.value + delay) % 1.0) > 0.5 ? 1.0 : 0.3;

        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
```

---

#### **4.4 ChatInput Widget**

**`lib/features/ai_chat/presentation/widgets/chat_input.dart`**
```dart
import 'package:flutter/material.dart';

/// Input field + Send button pro chat
class ChatInput extends StatefulWidget {
  final void Function(String message) onSend;

  const ChatInput({
    super.key,
    required this.onSend,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_hasText) {
      widget.onSend(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Zeptej se AI...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: _hasText ? _send : null,
            tooltip: 'Odeslat',
          ),
        ],
      ),
    );
  }
}
```

---

#### **4.5 ContextSummaryCard Widget**

**`lib/features/ai_chat/presentation/widgets/context_summary_card.dart`**
```dart
import 'package:flutter/material.dart';
import '../../domain/entities/task_context.dart';

/// Kompaktní summary úkolu (nahoře v chatu)
class ContextSummaryCard extends StatefulWidget {
  final TaskContext taskContext;

  const ContextSummaryCard({
    super.key,
    required this.taskContext,
  });

  @override
  State<ContextSummaryCard> createState() => _ContextSummaryCardState();
}

class _ContextSummaryCardState extends State<ContextSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todo = widget.taskContext.todo;

    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text('📋 ${todo.task}'),
        subtitle: _buildSummaryLine(),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubtasksList(),
                const SizedBox(height: 12),
                _buildPomodoroSummary(),
                const SizedBox(height: 12),
                _buildAIMetadata(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine() {
    final todo = widget.taskContext.todo;
    final subtasks = widget.taskContext.subtasks;
    final pomodoro = widget.taskContext.pomodoroSessions;

    final parts = <String>[];

    if (todo.priority != null) {
      parts.add('${todo.priority!.toUpperCase()}');
    }

    if (todo.dueDate != null) {
      parts.add('⏰ ${_formatDate(todo.dueDate!)}');
    }

    if (subtasks.isNotEmpty) {
      final completed = widget.taskContext.completedSubtasks;
      parts.add('$completed/${subtasks.length} podúkolů');
    }

    if (pomodoro.isNotEmpty) {
      parts.add('🍅 ${pomodoro.length}x');
    }

    return Text(parts.join(' │ '));
  }

  Widget _buildSubtasksList() {
    final subtasks = widget.taskContext.subtasks;
    if (subtasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Podúkoly:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...subtasks.map((subtask) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${subtask.completed ? "✅" : "☐"} ${subtask.subtaskNumber}. ${subtask.text}',
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPomodoroSummary() {
    final sessions = widget.taskContext.pomodoroSessions;
    if (sessions.isEmpty) return const SizedBox.shrink();

    final totalMinutes = widget.taskContext.totalPomodoroMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pomodoro:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('🍅 ${sessions.length} sessions ($totalMinutes minut celkem)'),
      ],
    );
  }

  Widget _buildAIMetadata() {
    final todo = widget.taskContext.todo;
    final hasRecommendations =
        todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty;
    final hasDeadlineAnalysis = todo.aiDeadlineAnalysis != null &&
        todo.aiDeadlineAnalysis!.isNotEmpty;

    if (!hasRecommendations && !hasDeadlineAnalysis) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasRecommendations) ...[
          const Text(
            'AI Doporučení:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(todo.aiRecommendations!),
          const SizedBox(height: 8),
        ],
        if (hasDeadlineAnalysis) ...[
          const Text(
            'AI Analýza termínu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(todo.aiDeadlineAnalysis!),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
```

---

### **Krok 5: Integration do TodoCard** (20 min)

**`lib/features/todo_list/presentation/widgets/todo_card.dart`**

Přidat novou akci "🤖 AI Chat":

```dart
// V _buildActions() metodě:
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    // ... existující akce (Edit, Delete, Pomodoro)

    // 🆕 AI Chat button
    TextButton.icon(
      icon: const Icon(Icons.smart_toy, size: 18),
      label: const Text('AI Chat'),
      onPressed: () async {
        // Načíst subtasks
        final subtasks = await _loadSubtasks(todo.id!);

        // Načíst pomodoro sessions
        final sessions = await _loadPomodoroSessions(todo.id!);

        // Otevřít AI Chat page
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiChatPage(
                todo: todo,
                subtasks: subtasks,
                pomodoroSessions: sessions,
              ),
            ),
          );
        }
      },
    ),
  ],
)

// Helper metody:
Future<List<Subtask>> _loadSubtasks(int todoId) async {
  final db = DatabaseHelper.instance;
  final maps = await db.getSubtasksByTodoId(todoId);
  return maps.map((m) => SubtaskModel.fromMap(m)).toList();
}

Future<List<PomodoroSession>> _loadPomodoroSessions(int todoId) async {
  final db = DatabaseHelper.instance;
  final maps = await db.getPomodoroSessionsByTodoId(todoId);
  return maps.map((m) => PomodoroSession.fromMap(m)).toList();
}
```

---

### **Krok 6: Database Schema** (optional - pro persistence)

**V1.0: Chat history JEN V PAMĚTI (session-based)**

Pro budoucí verzi (v2.0) můžeš přidat tabulku:

```sql
CREATE TABLE chat_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  todo_id INTEGER NOT NULL,
  role TEXT NOT NULL,  -- 'user' nebo 'assistant'
  content TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE
);
```

---

### **Krok 7: Testing** (30 min)

**Unit testy:**
```dart
// test/features/ai_chat/domain/entities/task_context_test.dart
// - Test toSystemPrompt() generation
// - Test completedSubtasks getter
// - Test totalPomodoroMinutes getter
```

**Widget testy:**
```dart
// test/features/ai_chat/presentation/widgets/chat_message_bubble_test.dart
// - Test user vs. AI message alignment
// - Test copy to clipboard
```

**Integration test:**
```dart
// integration_test/ai_chat_flow_test.dart
// - Open chat from TodoCard
// - Send message
// - Receive AI response
// - Clear chat
```

---

### **Krok 8: Git Commit**

```bash
git add -A && git commit -m "✨ feat: AI Chat - konverzace s AI asistentem nad úkolem

Features:
- 🤖 AI Chat page s fullscreen UI
- 💬 Chat interface (user/AI message bubbles)
- 📋 Context summary card (task + subtasks + pomodoro)
- ⏱️ Typing indicator při čekání na AI
- 📝 OpenRouter Chat Completion API integration
- 🧠 Používá Task model (inteligentní Claude 3.5 Sonnet)
- 🎨 Copy to clipboard pro AI odpovědi
- 🚀 Session-based chat (v1.0 bez persistence)

Použití:
- Klikni na 🤖 ikonu v TodoCard
- Chat s AI o konkrétním úkolu
- AI vidí celý kontext (task, subtasks, pomodoro, recommendations)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 🎨 VIZUÁLNÍ MOCKUP

```
┌───────────────────────────────────────────────────────┐
│  ← AI Chat: "Nakoupit"                     [🗑️] [ℹ️] │
├───────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐ │
│  │ 📋 Nakoupit                             [▼]    │ │ <- Context Summary
│  │ 🔴 A │ ⏰ Dnes │ 3/5 podúkolů │ 🍅 2 sessions   │ │
│  └─────────────────────────────────────────────────┘ │
├───────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 💬 Jak ti můžu pomoct s tímto úkolem?          │ │ <- AI Message
│  │ 10:30                                       📋  │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
│                  ┌─────────────────────────────────┐ │
│                  │ Můžeš mi poradit jak efektivně │ │ <- User Message
│                  │ rozdělit čas na tento nákup?   │ │
│                  │ 10:31                          │ │
│                  └─────────────────────────────────┘ │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ 💡 Podle podúkolů doporučuji:                   │ │ <- AI Message
│  │                                                 │ │
│  │ 1. Mléko, chléb, máslo → Albert (15 min)       │ │
│  │ 2. Jogurt → cestou do Albertu (3 min)          │ │
│  │ 3. Ovoce → tržnice vedle (10 min)              │ │
│  │                                                 │ │
│  │ Celkem: ~30 minut + 10 min rezerva             │ │
│  │ Tip: Udělej 1 Pomodoro session (25 min)        │ │
│  │ 10:32                                       📋  │ │
│  └─────────────────────────────────────────────────┘ │
│                                                       │
├───────────────────────────────────────────────────────┤
│  [TextField: Zeptej se AI...]              [➤]      │
└───────────────────────────────────────────────────────┘
```

---

## 📊 USE CASES

### **1. Rozdělit úkol jinak**
```
User: "Můžeš mi navrhnout jiné rozdělení tohoto úkolu?"
AI: "Vidím že aktuální podúkoly jsou orientované na obchody.
     Můžu navrhnout rozdělení podle kategorií:
     1. Potraviny (mléko, chléb, máslo, jogurt)
     2. Ovoce a zelenina
     3. Doplňky
     Je to pro tebe užitečnější?"
```

### **2. Time management**
```
User: "Kolik času mi to zabere?"
AI: "Podle tvých 2 Pomodoro sessions (50 min) a 3/5 dokončených podúkolů:
     - Už jsi strávil: 50 minut
     - Zbývá: 2 podúkoly (jogurt + ovoce)
     - Odhad: 15-20 minut
     Celkem: ~70 minut na celý úkol"
```

### **3. Prioritizace**
```
User: "Je to urgentní? Deadline je dnes."
AI: "Ano, je to priorita A s deadlinem dnes.
     Doporučuji dokončit zbylé 2 podúkoly co nejdřív.
     Máš ještě čas dnes odpoledne, ale neprodlužuj to."
```

### **4. Brainstorming**
```
User: "Mám něco vynechat abych ušetřil čas?"
AI: "Ovoce můžeš koupit později v týdnu (není v AI doporučení).
     Soustřeď se na mléko, chléb, máslo, jogurt - to je základ.
     Ušetříš ~10 minut."
```

---

## 🚀 PERFORMANCE OČEKÁVÁNÍ

**Benchmarky:**
- **API call latency**: 1-3 sekundy (OpenRouter Claude 3.5 Sonnet)
- **UI rendering**: <16ms (60 FPS smooth)
- **Message list scroll**: Lazy loading (ListView.builder)
- **Context summary**: Expandable (žádné performance issues)

**Optimalizace:**
- ✅ Debouncing při psaní (optional - zatím NE)
- ✅ Memoization v BLoC (Equatable)
- ✅ Lazy rendering (ListView.builder)
- ✅ Session-based chat (žádné DB queries kromě initial load)

---

## 🎯 KLÍČOVÉ PRINCIPY

✅ **Kontext je král** - AI vidí celý úkol (task + subtasks + pomodoro + metadata)
✅ **Task model** - používá inteligentní model (claude-3.5-sonnet) z nastavení
✅ **Session-based** - chat history v paměti (v1.0 bez DB persistence)
✅ **Fullscreen UI** - chat si zaslouží celou obrazovku
✅ **One-click access** - ikona 🤖 přímo v TodoCard
✅ **Copy-friendly** - AI odpovědi lze zkopírovat jedním klikem
✅ **Typing indicator** - vizuální feedback při čekání na AI

---

## 🔮 BUDOUCÍ ROZŠÍŘENÍ (YAGNI - zatím NE!)

- ❌ DB persistence chat historie - v1.0 stačí session-based
- ❌ Voice input - nice-to-have, ne nutnost
- ❌ Streaming responses - OpenRouter nepodporuje SSE jednoduše
- ❌ Multi-model support - zatím stačí Task model
- ❌ Chat templates - YAGNI, freeform je flexibilnější
- ❌ Export chat - lze řešit copy-paste

---

## 📝 PROGRESS LOG

### 2025-10-12 - Inicializace projektu

**✅ Dokončeno:**
- Analýza požadavků (AI chat s kontextem úkolu)
- Architektonický návrh (Feature-First + BLoC)
- Vytvoření ai-chat.md s kompletním plánem
- UI/UX mockupy

**🔄 Aktuální stav:**
- Čeká na potvrzení k zahájení implementace

**📋 Příští kroky:**
1. Krok 1: Domain Layer (entities, repository interface)
2. Krok 2: Data Layer (OpenRouter datasource, repository impl)
3. Krok 3: Presentation Layer (BLoC events/states/handlers)
4. Krok 4: UI Implementation (page, widgets)
5. Krok 5: Integration do TodoCard
6. Krok 6: Testing
7. Krok 7: Git Commit

**🐛 Problémy:** Žádné

**💡 Poznámky:**
- Používá Task model (claude-3.5-sonnet) - inteligentní, JSON-capable
- Chat completion API: https://openrouter.ai/docs/api-reference/chat-completion
- Session-based (v1.0 bez DB persistence - KISS princip)

---

**Autor**: Claude Code
**Datum vytvoření**: 2025-10-12
**Verze**: 1.0
**Status**: ✅ READY FOR IMPLEMENTATION

---

🎯 **Mistře Jardo, tento plán je tvůj blueprint pro AI Chat feature. Začneme implementaci?** 🚀
