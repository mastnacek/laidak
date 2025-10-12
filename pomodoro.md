# 🍅 Pomodoro Timer - Implementační Plán

## 📋 Přehled

**Funkce**: Pomodoro Timer pro produktivitu - klasická technika 25 min práce + 5 min přestávka

**Inspirace**: Tauri TODO aplikace (`d:\01_programovani\tauri-todo-linux\`)

**Klíčové vlastnosti**:
- ⏱️ Konfigurovatelný timer (výchozí 25 min práce / 5 min break)
- 🔔 Android notifikace s foreground service (běží v pozadí)
- 📊 Historie Pomodoro sessions v databázi
- 🎨 UI jako TAB v top AppBar (mezi Sparkles a Settings)
- 📱 Persistent notification s časovačem (Android status bar)

---

## 🔍 Analýza Tauri Implementace

### Klíčové komponenty z Tauri verze:

#### 1. **Core State Management** (`pomodoro.js`)
```javascript
pomodoroState = {
  isRunning: false,
  isPaused: false,
  isBreak: false,           // Je to přestávka?
  taskId: null,
  taskText: '',
  startTime: null,
  remainingTime: POMODORO_DURATION,
  totalDuration: POMODORO_DURATION,
  timerInterval: null,
  sessionId: null,
  pomodoroCount: 0,         // Kolik Pomodoro na tento úkol
  customDuration: null      // Vlastní délka v minutách
}
```

#### 2. **Databázový model** (SQLite)
```sql
CREATE TABLE pomodoro_sessions (
  id INTEGER PRIMARY KEY,
  task_id INTEGER,
  started_at INTEGER,      -- Unix timestamp
  ended_at INTEGER,
  duration INTEGER,        -- v sekundách
  completed BOOLEAN
);
```

#### 3. **Commands & Events**
- `startPomodoro(task, customMinutes)` - Start timer
- `stopPomodoro()` - Stop timer
- `pausePomodoro()` / `resumePomodoro()` - Pause/Resume
- `getPomodoroStatus()` - Aktuální stav
- `getPomodoroHistory(taskId)` - Historie sessions
- `continuePomodoro()` - Další Pomodoro na stejný úkol
- `startBreak()` - 5min přestávka
- `markTaskCompleted()` - Dokončit úkol

**Events**:
- `pomodoro-tick` - Každou sekundu (update UI)
- `pomodoro-complete` - Pomodoro dokončeno
- `pomodoro-break-complete` - Přestávka dokončena
- `pomodoro-reset` - Reset stavu

#### 4. **UI zobrazení**
```html
<!-- Tauri panel zobrazuje: -->
<div class="pomodoro-active">
  <div class="pomodoro-tomato">🍅</div>
  <div class="pomodoro-timer">24:35</div>
  <div class="pomodoro-task-info">
    <span>[5]</span>
    <span>Napsat dokumentaci</span>
  </div>
</div>
```

---

## 🎯 Flutter Návrh - Multi-Platform Approach

### **Problém**: Android vs Windows/Desktop rozdíly

| Platform | Background Timer | Foreground Notification | UI Approach |
|----------|-----------------|------------------------|-------------|
| **Android** | ✅ Foreground Service | ✅ Persistent notification | Tab v AppBar |
| **Windows** | ❌ Nelze native background | ❌ Žádné system tray notif. | **Pomodoro Tab** |
| **iOS** | ⚠️ Omezené (BGTaskScheduler) | ✅ Local notifications | Tab v AppBar |

### **Řešení: Hybrid Přístup**

#### **Varianta A: Tab-Based UI (DOPORUČENO)** ✅
- Nová TAB stránka "Pomodoro" v top AppBar
- Ikona rajčete 🍅 mezi Sparkles ✨ a Settings ⚙️
- Kliknutím na 🍅 → Switch na Pomodoro Tab
- **Výhody**: Funguje na všech platformách, konzistentní UX
- **Nevýhody**: Na Androidu user musí mít app otevřenou (NEBO persistent notification)

#### **Varianta B: Floating Widget** (Android only)
- FAB (Floating Action Button) s timer overlay
- Persistent na všech screens
- **Výhody**: Vždy viditelný timer
- **Nevýhody**: Zabírá místo, Windows/iOS nefunguje

#### **Varianta C: Status Bar Integration** (Komplexní)
- Android: Foreground service + notification
- Windows: Tray icon (pomocí `tray_manager` package)
- iOS: Background fetch + local notifications
- **Výhody**: Native experience na každé platformě
- **Nevýhody**: 3x více kódu, komplexní maintenance

---

## ✅ DOPORUČENÝ PŘÍSTUP: Hybrid (Tab + Notifications)

### **UI Design**:

1. **Top AppBar struktura**:
```
┌─────────────────────────────────────────┐
│ [📋] [📅] [🗓️] [⏰] [⚠️] [👁️]         │  ← ViewBar (existující)
│ [✅5][🔴12][📅3][⏰7]    [✨][🍅][⚙️][?] │  ← StatsRow + Actions
└─────────────────────────────────────────┘
                              ↑
                        Nová ikona!
```

2. **Pomodoro Tab Page**:
```
┌─────────────────────────────────────────┐
│          🍅 POMODORO TIMER              │
│                                         │
│           ┌─────────────┐               │
│           │   24:35     │  ← Velký timer
│           └─────────────┘               │
│                                         │
│  Úkol: [5] Napsat dokumentaci           │
│  Session: #3 (75 minut celkem)          │
│                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  START  │ │  PAUSE  │ │  STOP   │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  ⚙️ Nastavení:                          │
│  ⏱️ Délka práce: [25] min               │
│  ☕ Délka pauzy: [5] min                │
│                                         │
│  📊 Historie (dnes):                    │
│  ✅ 10:30 - 10:55 (25 min) - Úkol #5    │
│  ✅ 11:00 - 11:25 (25 min) - Úkol #5    │
│  ⏸️ 11:30 - (přerušeno) - Úkol #3       │
└─────────────────────────────────────────┘
```

3. **Android Persistent Notification** (když timer běží):
```
┌─────────────────────────────────────┐
│ 🍅 Pomodoro Timer                   │
│ 24:35 zbývá - Napsat dokumentaci    │
│ [⏸️ Pauza] [⏹️ Stop]                 │
└─────────────────────────────────────┘
```

---

## 🏗️ Architektura - Feature-First + BLoC

### **Struktura**:
```
lib/features/pomodoro/
├── presentation/
│   ├── pages/
│   │   └── pomodoro_page.dart           # Tab stránka
│   ├── widgets/
│   │   ├── timer_display.dart           # Velký časovač widget
│   │   ├── timer_controls.dart          # Start/Pause/Stop buttons
│   │   ├── settings_panel.dart          # Konfigurace minut
│   │   └── history_list.dart            # Seznam sessions
│   ├── bloc/
│   │   ├── pomodoro_bloc.dart           # Main BLoC
│   │   ├── pomodoro_event.dart          # Events
│   │   └── pomodoro_state.dart          # States
│   └── services/
│       ├── pomodoro_timer_service.dart  # Timer isolate
│       └── notification_service.dart    # Android notifications
├── data/
│   ├── repositories/
│   │   └── pomodoro_repository_impl.dart
│   ├── datasources/
│   │   ├── pomodoro_local_datasource.dart  # SQLite
│   │   └── pomodoro_notification_ds.dart   # Notifications
│   └── models/
│       └── pomodoro_session_dto.dart
└── domain/
    ├── entities/
    │   └── pomodoro_session.dart        # Entity
    ├── repositories/
    │   └── pomodoro_repository.dart     # Interface
    └── enums/
        └── timer_state.dart             # Running/Paused/Stopped/Break
```

---

## 🗄️ Databázový Model (SQLite)

### **Nová tabulka**:
```sql
CREATE TABLE pomodoro_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  started_at INTEGER NOT NULL,     -- Unix timestamp (sekundy)
  ended_at INTEGER,                -- NULL pokud běží
  duration INTEGER NOT NULL,       -- Plánovaná délka v sekundách
  actual_duration INTEGER,         -- Skutečná délka (pokud přerušeno)
  completed INTEGER NOT NULL,      -- 0/1 (BOOLEAN)
  is_break INTEGER NOT NULL,       -- 0/1 (je to přestávka?)
  FOREIGN KEY (task_id) REFERENCES todos(id) ON DELETE CASCADE
);

-- Index pro rychlé dotazy
CREATE INDEX idx_pomodoro_task ON pomodoro_sessions(task_id);
CREATE INDEX idx_pomodoro_date ON pomodoro_sessions(started_at);
```

### **Migration (Database Helper)**:
```dart
// database_helper.dart - version 12
if (oldVersion < 12) {
  await db.execute('''
    CREATE TABLE pomodoro_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      task_id INTEGER NOT NULL,
      started_at INTEGER NOT NULL,
      ended_at INTEGER,
      duration INTEGER NOT NULL,
      actual_duration INTEGER,
      completed INTEGER NOT NULL,
      is_break INTEGER NOT NULL,
      FOREIGN KEY (task_id) REFERENCES todos(id) ON DELETE CASCADE
    )
  ''');

  await db.execute(
    'CREATE INDEX idx_pomodoro_task ON pomodoro_sessions(task_id)'
  );
  await db.execute(
    'CREATE INDEX idx_pomodoro_date ON pomodoro_sessions(started_at)'
  );
}
```

---

## 🎨 Domain Models

### **PomodoroSession Entity**:
```dart
class PomodoroSession extends Equatable {
  final int? id;
  final int taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;          // Plánovaná
  final Duration? actualDuration;   // Skutečná (pokud přerušeno)
  final bool completed;
  final bool isBreak;

  const PomodoroSession({
    this.id,
    required this.taskId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    this.actualDuration,
    required this.completed,
    this.isBreak = false,
  });

  @override
  List<Object?> get props => [
    id, taskId, startedAt, endedAt,
    duration, actualDuration, completed, isBreak
  ];

  PomodoroSession copyWith({...}) => PomodoroSession(...);
}
```

### **TimerState Enum**:
```dart
enum TimerState {
  idle,      // Nezačato
  running,   // Běží
  paused,    // Pozastaveno
  break,     // Přestávka
}
```

### **PomodoroConfig** (Settings):
```dart
class PomodoroConfig extends Equatable {
  final Duration workDuration;   // Výchozí 25 min
  final Duration breakDuration;  // Výchozí 5 min
  final bool autoStartBreak;     // Auto start break po dokončení
  final bool soundEnabled;       // Zvuk při dokončení

  const PomodoroConfig({
    this.workDuration = const Duration(minutes: 25),
    this.breakDuration = const Duration(minutes: 5),
    this.autoStartBreak = false,
    this.soundEnabled = true,
  });

  @override
  List<Object?> get props => [
    workDuration, breakDuration, autoStartBreak, soundEnabled
  ];

  PomodoroConfig copyWith({...}) => PomodoroConfig(...);
}
```

---

## 🧠 BLoC Design

### **PomodoroState**:
```dart
class PomodoroState extends Equatable {
  final TimerState timerState;
  final int? currentTaskId;
  final Duration remainingTime;
  final Duration totalDuration;
  final int sessionCount;           // Kolik Pomodoro na tento úkol
  final PomodoroSession? currentSession;
  final List<PomodoroSession> history;
  final PomodoroConfig config;
  final bool isLoading;
  final String? errorMessage;

  const PomodoroState({
    this.timerState = TimerState.idle,
    this.currentTaskId,
    this.remainingTime = const Duration(minutes: 25),
    this.totalDuration = const Duration(minutes: 25),
    this.sessionCount = 0,
    this.currentSession,
    this.history = const [],
    this.config = const PomodoroConfig(),
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
    timerState, currentTaskId, remainingTime, totalDuration,
    sessionCount, currentSession, history, config, isLoading, errorMessage
  ];

  PomodoroState copyWith({...}) => PomodoroState(...);
}
```

### **PomodoroEvents**:
```dart
sealed class PomodoroEvent extends Equatable {
  const PomodoroEvent();
}

class StartPomodoroEvent extends PomodoroEvent {
  final int taskId;
  final Duration? customDuration;

  const StartPomodoroEvent(this.taskId, [this.customDuration]);

  @override
  List<Object?> get props => [taskId, customDuration];
}

class PausePomodoroEvent extends PomodoroEvent {
  @override
  List<Object?> get props => [];
}

class ResumePomodoroEvent extends PomodoroEvent {
  @override
  List<Object?> get props => [];
}

class StopPomodoroEvent extends PomodoroEvent {
  @override
  List<Object?> get props => [];
}

class TimerTickEvent extends PomodoroEvent {
  final Duration remainingTime;

  const TimerTickEvent(this.remainingTime);

  @override
  List<Object?> get props => [remainingTime];
}

class TimerCompleteEvent extends PomodoroEvent {
  @override
  List<Object?> get props => [];
}

class StartBreakEvent extends PomodoroEvent {
  @override
  List<Object?> get props => [];
}

class ContinuePomodoroEvent extends PomodoroEvent {
  final Duration? customDuration;

  const ContinuePomodoroEvent([this.customDuration]);

  @override
  List<Object?> get props => [customDuration];
}

class LoadHistoryEvent extends PomodoroEvent {
  final int? taskId;

  const LoadHistoryEvent([this.taskId]);

  @override
  List<Object?> get props => [taskId];
}

class UpdateConfigEvent extends PomodoroEvent {
  final PomodoroConfig config;

  const UpdateConfigEvent(this.config);

  @override
  List<Object?> get props => [config];
}
```

---

## ⏱️ Timer Service - Isolate Background Timer

### **Proč Isolate?**
- Flutter Timer v UI threadu může lagovat při heavy load
- Isolate běží na separátním threadu → přesný timing
- Background execution i když je app minimalizovaná (Android)

### **PomodoroTimerService**:
```dart
import 'dart:async';
import 'dart:isolate';

class PomodoroTimerService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;
  StreamController<Duration>? _tickController;

  Stream<Duration> get tickStream => _tickController!.stream;

  // Spustit isolate timer
  Future<void> start(Duration duration) async {
    _receivePort = ReceivePort();
    _tickController = StreamController<Duration>.broadcast();

    _isolate = await Isolate.spawn(
      _timerIsolate,
      _TimerData(
        sendPort: _receivePort!.sendPort,
        duration: duration,
      ),
    );

    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is Duration) {
        _tickController!.add(message);
      } else if (message == 'complete') {
        _tickController!.add(Duration.zero);
      }
    });
  }

  // Pause timer
  void pause() {
    _sendPort?.send('pause');
  }

  // Resume timer
  void resume() {
    _sendPort?.send('resume');
  }

  // Stop timer
  void stop() {
    _sendPort?.send('stop');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _tickController?.close();
  }

  // Isolate entry point
  static void _timerIsolate(_TimerData data) {
    final receivePort = ReceivePort();
    data.sendPort.send(receivePort.sendPort);

    Timer? timer;
    bool isPaused = false;
    Duration remaining = data.duration;

    receivePort.listen((message) {
      if (message == 'pause') {
        isPaused = true;
        timer?.cancel();
      } else if (message == 'resume') {
        isPaused = false;
        _startTimer();
      } else if (message == 'stop') {
        timer?.cancel();
        receivePort.close();
      }
    });

    void _startTimer() {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!isPaused && remaining > Duration.zero) {
          remaining -= const Duration(seconds: 1);
          data.sendPort.send(remaining);

          if (remaining == Duration.zero) {
            data.sendPort.send('complete');
            t.cancel();
          }
        }
      });
    }

    _startTimer();
  }
}

class _TimerData {
  final SendPort sendPort;
  final Duration duration;

  _TimerData({required this.sendPort, required this.duration});
}
```

---

## 🔔 Android Notification Service

### **PomodoroNotificationService** (Android):
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PomodoroNotificationService {
  static const _channelId = 'pomodoro_timer';
  static const _channelName = 'Pomodoro Timer';
  static const _notificationId = 1;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('app_icon');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    // Vytvořit notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pomodoro timer foreground service',
      importance: Importance.low, // Aby nebyl intrusive
      playSound: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Zobrazit persistent notification s timerem
  Future<void> showTimerNotification({
    required Duration remaining,
    required String taskText,
    required bool isPaused,
  }) async {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final timeText = '${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Pomodoro timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Nelze swipe away
      autoCancel: false,
      showWhen: false,
      icon: 'pomodoro_icon', // Vlastní ikona
      actions: [
        AndroidNotificationAction(
          'pause',
          isPaused ? 'Resume' : 'Pause',
          icon: DrawableResourceAndroidBitmap(isPaused ? 'ic_play' : 'ic_pause'),
        ),
        AndroidNotificationAction(
          'stop',
          'Stop',
          icon: DrawableResourceAndroidBitmap('ic_stop'),
        ),
      ],
    );

    await _notifications.show(
      _notificationId,
      '🍅 Pomodoro Timer',
      '$timeText - $taskText',
      NotificationDetails(android: androidDetails),
    );
  }

  // Skrýt notification
  Future<void> cancelNotification() async {
    await _notifications.cancel(_notificationId);
  }

  // Handle notification actions
  void handleNotificationAction(String action) {
    // Emit event do BLoC
    // Např. pomocí EventBus nebo Callback
  }
}
```

### **AndroidManifest.xml úpravy**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application>
        <!-- Foreground Service -->
        <service
            android:name="com.dexterous.flutterlocalnotifications.ForegroundService"
            android:exported="false"
            android:stopWithTask="false"
            android:foregroundServiceType="specialUse">
        </service>

        <!-- Receivers -->
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver"
        />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
        />
    </application>
</manifest>
```

---

## 🎬 BLoC Implementation - Event Handlers

### **PomodoroBloc**:
```dart
class PomodoroBloc extends Bloc<PomodoroEvent, PomodoroState> {
  final PomodoroRepository _repository;
  final PomodoroTimerService _timerService;
  final PomodoroNotificationService? _notificationService; // Pouze Android

  StreamSubscription<Duration>? _timerSubscription;

  PomodoroBloc({
    required PomodoroRepository repository,
    required PomodoroTimerService timerService,
    PomodoroNotificationService? notificationService,
  })  : _repository = repository,
        _timerService = timerService,
        _notificationService = notificationService,
        super(const PomodoroState()) {
    on<StartPomodoroEvent>(_onStartPomodoro);
    on<PausePomodoroEvent>(_onPausePomodoro);
    on<ResumePomodoroEvent>(_onResumePomodoro);
    on<StopPomodoroEvent>(_onStopPomodoro);
    on<TimerTickEvent>(_onTimerTick);
    on<TimerCompleteEvent>(_onTimerComplete);
    on<StartBreakEvent>(_onStartBreak);
    on<ContinuePomodoroEvent>(_onContinuePomodoro);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<UpdateConfigEvent>(_onUpdateConfig);
  }

  Future<void> _onStartPomodoro(
    StartPomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    // Fail Fast validace
    if (state.timerState != TimerState.idle) {
      emit(state.copyWith(
        errorMessage: 'Timer již běží!',
      ));
      return;
    }

    final duration = event.customDuration ?? state.config.workDuration;
    final now = DateTime.now();

    // Vytvořit session v DB
    final session = PomodoroSession(
      taskId: event.taskId,
      startedAt: now,
      duration: duration,
      completed: false,
      isBreak: false,
    );

    try {
      final savedSession = await _repository.createSession(session);

      emit(state.copyWith(
        timerState: TimerState.running,
        currentTaskId: event.taskId,
        remainingTime: duration,
        totalDuration: duration,
        currentSession: savedSession,
        sessionCount: state.sessionCount,
      ));

      // Spustit isolate timer
      await _timerService.start(duration);

      // Subscribe na tick events
      _timerSubscription = _timerService.tickStream.listen((remaining) {
        if (remaining == Duration.zero) {
          add(TimerCompleteEvent());
        } else {
          add(TimerTickEvent(remaining));
        }
      });

      // Android notification
      if (_notificationService != null) {
        // TODO: Získat task text z repository
        await _notificationService!.showTimerNotification(
          remaining: duration,
          taskText: 'Úkol #${event.taskId}',
          isPaused: false,
        );
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nelze spustit Pomodoro: $e',
      ));
    }
  }

  Future<void> _onPausePomodoro(
    PausePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.timerState != TimerState.running) return;

    _timerService.pause();

    emit(state.copyWith(
      timerState: TimerState.paused,
    ));

    // Update notification
    if (_notificationService != null) {
      await _notificationService!.showTimerNotification(
        remaining: state.remainingTime,
        taskText: 'Úkol #${state.currentTaskId}',
        isPaused: true,
      );
    }
  }

  Future<void> _onResumePomodoro(
    ResumePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.timerState != TimerState.paused) return;

    _timerService.resume();

    emit(state.copyWith(
      timerState: TimerState.running,
    ));

    // Update notification
    if (_notificationService != null) {
      await _notificationService!.showTimerNotification(
        remaining: state.remainingTime,
        taskText: 'Úkol #${state.currentTaskId}',
        isPaused: false,
      );
    }
  }

  Future<void> _onStopPomodoro(
    StopPomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    _timerService.stop();
    _timerSubscription?.cancel();

    // Update session v DB
    if (state.currentSession != null) {
      final now = DateTime.now();
      final elapsed = now.difference(state.currentSession!.startedAt);

      await _repository.updateSession(
        state.currentSession!.copyWith(
          endedAt: now,
          actualDuration: elapsed,
          completed: false, // Přerušeno
        ),
      );
    }

    // Cancel notification
    await _notificationService?.cancelNotification();

    emit(state.copyWith(
      timerState: TimerState.idle,
      currentTaskId: null,
      currentSession: null,
      remainingTime: state.config.workDuration,
    ));
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<PomodoroState> emit,
  ) {
    emit(state.copyWith(
      remainingTime: event.remainingTime,
    ));

    // Update notification každých 5 sekund (aby nefloodilo)
    if (event.remainingTime.inSeconds % 5 == 0 && _notificationService != null) {
      _notificationService!.showTimerNotification(
        remaining: event.remainingTime,
        taskText: 'Úkol #${state.currentTaskId}',
        isPaused: false,
      );
    }
  }

  Future<void> _onTimerComplete(
    TimerCompleteEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    _timerService.stop();
    _timerSubscription?.cancel();

    // Update session jako completed
    if (state.currentSession != null) {
      final now = DateTime.now();

      await _repository.updateSession(
        state.currentSession!.copyWith(
          endedAt: now,
          actualDuration: state.totalDuration,
          completed: true,
        ),
      );
    }

    // Increment session count
    final newCount = state.sessionCount + 1;

    // Play sound (pokud enabled)
    if (state.config.soundEnabled) {
      // TODO: Play beep sound
    }

    // Show completion notification
    if (_notificationService != null) {
      // TODO: Show "Pomodoro Complete!" notification
    }

    // Auto-start break?
    if (state.config.autoStartBreak) {
      add(StartBreakEvent());
    } else {
      emit(state.copyWith(
        timerState: TimerState.idle,
        sessionCount: newCount,
        remainingTime: state.config.workDuration,
      ));
    }
  }

  Future<void> _onStartBreak(
    StartBreakEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    final duration = state.config.breakDuration;

    emit(state.copyWith(
      timerState: TimerState.break,
      remainingTime: duration,
      totalDuration: duration,
    ));

    await _timerService.start(duration);

    _timerSubscription = _timerService.tickStream.listen((remaining) {
      if (remaining == Duration.zero) {
        // Break complete
        _onBreakComplete(emit);
      } else {
        add(TimerTickEvent(remaining));
      }
    });

    // Show break notification
    if (_notificationService != null) {
      await _notificationService!.showTimerNotification(
        remaining: duration,
        taskText: '☕ Přestávka',
        isPaused: false,
      );
    }
  }

  void _onBreakComplete(Emitter<PomodoroState> emit) {
    _timerService.stop();
    _timerSubscription?.cancel();

    // Play sound
    if (state.config.soundEnabled) {
      // TODO: Play beep
    }

    _notificationService?.cancelNotification();

    emit(state.copyWith(
      timerState: TimerState.idle,
      remainingTime: state.config.workDuration,
    ));
  }

  Future<void> _onContinuePomodoro(
    ContinuePomodoroEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    if (state.currentTaskId == null) {
      emit(state.copyWith(errorMessage: 'Žádný úkol k pokračování'));
      return;
    }

    add(StartPomodoroEvent(
      state.currentTaskId!,
      event.customDuration,
    ));
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final history = event.taskId != null
          ? await _repository.getSessionsByTask(event.taskId!)
          : await _repository.getAllSessions();

      emit(state.copyWith(
        history: history,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nelze načíst historii: $e',
        isLoading: false,
      ));
    }
  }

  Future<void> _onUpdateConfig(
    UpdateConfigEvent event,
    Emitter<PomodoroState> emit,
  ) async {
    // Save to SharedPreferences
    await _repository.saveConfig(event.config);

    emit(state.copyWith(
      config: event.config,
    ));
  }

  @override
  Future<void> close() {
    _timerService.stop();
    _timerSubscription?.cancel();
    _notificationService?.cancelNotification();
    return super.close();
  }
}
```

---

## 📦 Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existující
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  sqflite: ^2.3.0

  # NOVÉ pro Pomodoro
  flutter_local_notifications: ^17.0.0  # Android notifications
  permission_handler: ^11.0.1           # Runtime permissions

  # OPTIONAL (pokud chceme Windows tray icon)
  # tray_manager: ^0.2.0                # Windows system tray
  # window_manager: ^0.3.7              # Desktop window control
```

---

## 🎨 UI Implementation - Pomodoro Page

### **pomodoro_page.dart**:
```dart
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PomodoroBloc(
        repository: context.read<PomodoroRepository>(),
        timerService: PomodoroTimerService(),
        notificationService: Platform.isAndroid
            ? PomodoroNotificationService()
            : null,
      )..add(LoadHistoryEvent()),
      child: const _PomodoroPageContent(),
    );
  }
}

class _PomodoroPageContent extends StatelessWidget {
  const _PomodoroPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍅 Pomodoro Timer'),
      ),
      body: BlocListener<PomodoroBloc, PomodoroState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Timer Display
              const TimerDisplay(),

              const SizedBox(height: 24),

              // Task Info
              const _TaskInfo(),

              const SizedBox(height: 32),

              // Controls
              const TimerControls(),

              const SizedBox(height: 32),

              // Settings Panel
              const SettingsPanel(),

              const SizedBox(height: 32),

              // History
              const HistoryList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskInfo extends StatelessWidget {
  const _TaskInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      builder: (context, state) {
        if (state.currentTaskId == null) {
          return const Text(
            'Vyberte úkol ze seznamu úkolů',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          );
        }

        return Column(
          children: [
            Text(
              'Úkol: #${state.currentTaskId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Session: #${state.sessionCount}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}
```

### **timer_display.dart** (Velký časovač):
```dart
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) =>
          previous.remainingTime != current.remainingTime ||
          previous.timerState != current.timerState,
      builder: (context, state) {
        final minutes = state.remainingTime.inMinutes;
        final seconds = state.remainingTime.inSeconds % 60;
        final timeText =
            '${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}';

        final color = state.timerState == TimerState.break
            ? Colors.green
            : Theme.of(context).primaryColor;

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: Text(
            timeText,
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        );
      },
    );
  }
}
```

### **timer_controls.dart**:
```dart
class TimerControls extends StatelessWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // START button
            if (state.timerState == TimerState.idle)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show task picker dialog
                  // For now, hardcode task ID
                  context.read<PomodoroBloc>().add(
                    const StartPomodoroEvent(1),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('START'),
              ),

            // PAUSE button
            if (state.timerState == TimerState.running)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(PausePomodoroEvent());
                },
                icon: const Icon(Icons.pause),
                label: const Text('PAUSE'),
              ),

            // RESUME button
            if (state.timerState == TimerState.paused)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(ResumePomodoroEvent());
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('RESUME'),
              ),

            // STOP button
            if (state.timerState != TimerState.idle)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(StopPomodoroEvent());
                },
                icon: const Icon(Icons.stop),
                label: const Text('STOP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),

            // BREAK button (after pomodoro complete)
            if (state.timerState == TimerState.idle &&
                state.sessionCount > 0)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(StartBreakEvent());
                },
                icon: const Icon(Icons.coffee),
                label: const Text('BREAK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),

            // CONTINUE button
            if (state.timerState == TimerState.idle &&
                state.currentTaskId != null)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(
                    const ContinuePomodoroEvent(),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('CONTINUE'),
              ),
          ],
        );
      },
    );
  }
}
```

### **settings_panel.dart**:
```dart
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚙️ Nastavení',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Work Duration
                Row(
                  children: [
                    const Text('⏱️ Délka práce:'),
                    const Spacer(),
                    Text('${state.config.workDuration.inMinutes} min'),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showDurationPicker(
                          context,
                          'Délka práce',
                          state.config.workDuration,
                          (duration) {
                            context.read<PomodoroBloc>().add(
                              UpdateConfigEvent(
                                state.config.copyWith(workDuration: duration),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Break Duration
                Row(
                  children: [
                    const Text('☕ Délka pauzy:'),
                    const Spacer(),
                    Text('${state.config.breakDuration.inMinutes} min'),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showDurationPicker(
                          context,
                          'Délka pauzy',
                          state.config.breakDuration,
                          (duration) {
                            context.read<PomodoroBloc>().add(
                              UpdateConfigEvent(
                                state.config.copyWith(breakDuration: duration),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Auto-start break
                SwitchListTile(
                  title: const Text('Auto-start přestávky'),
                  value: state.config.autoStartBreak,
                  onChanged: (value) {
                    context.read<PomodoroBloc>().add(
                      UpdateConfigEvent(
                        state.config.copyWith(autoStartBreak: value),
                      ),
                    );
                  },
                ),

                // Sound
                SwitchListTile(
                  title: const Text('Zvuk při dokončení'),
                  value: state.config.soundEnabled,
                  onChanged: (value) {
                    context.read<PomodoroBloc>().add(
                      UpdateConfigEvent(
                        state.config.copyWith(soundEnabled: value),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDurationPicker(
    BuildContext context,
    String title,
    Duration current,
    Function(Duration) onSave,
  ) {
    // TODO: Show number picker dialog
    // For now, simple implementation
  }
}
```

### **history_list.dart**:
```dart
class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      builder: (context, state) {
        if (state.history.isEmpty) {
          return const Text('Žádná historie');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Historie (dnes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...state.history.map((session) {
              final time = DateFormat.Hm().format(session.startedAt);
              final duration = session.actualDuration ?? session.duration;
              final icon = session.completed ? '✅' : '⏸️';
              final typeIcon = session.isBreak ? '☕' : '🍅';

              return ListTile(
                leading: Text(
                  typeIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text('$time - ${duration.inMinutes} min'),
                subtitle: Text('Úkol #${session.taskId}'),
                trailing: Text(icon),
              );
            }),
          ],
        );
      },
    );
  }
}
```

---

## 🔗 Integrace do TodoListPage

### **Přidání Pomodoro akce do úkolu**:
```dart
// todo_list_page.dart - v každém TodoItem
IconButton(
  icon: const Icon(Icons.timer, color: Colors.orange),
  tooltip: 'Spustit Pomodoro',
  onPressed: () {
    // Navigate to Pomodoro tab
    // NEBO show quick start dialog
    _showPomodoroQuickStart(context, todo.id);
  },
)

void _showPomodoroQuickStart(BuildContext context, int taskId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('🍅 Spustit Pomodoro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Délka:'),
          DropdownButton<int>(
            value: 25,
            items: [15, 25, 30, 45, 60].map((min) {
              return DropdownMenuItem(
                value: min,
                child: Text('$min minut'),
              );
            }).toList(),
            onChanged: (value) {
              // Update selected duration
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: () {
            // Start Pomodoro
            context.read<PomodoroBloc>().add(
              StartPomodoroEvent(taskId, const Duration(minutes: 25)),
            );
            Navigator.pop(context);

            // Navigate to Pomodoro tab
            // TODO: Implement tab switching
          },
          child: const Text('START'),
        ),
      ],
    ),
  );
}
```

---

## 🧭 Top AppBar - Přidání Pomodoro ikony

### **Aktualizace TopBar**:
```dart
// lib/features/todo_list/presentation/widgets/top_bar.dart
Row(
  children: [
    // Existující Stats
    _buildStat('✅', completedCount, Colors.green),
    _buildStat('🔴', urgentCount, Colors.red),
    _buildStat('📅', dueTodayCount, Colors.orange),
    _buildStat('⏰', overdueCount, Colors.red.shade700),

    const Spacer(),

    // Sparkles (AI)
    IconButton(
      icon: const Icon(Icons.auto_awesome),
      onPressed: () {
        // Navigate to AI features
      },
    ),

    // 🆕 POMODORO IKONA
    IconButton(
      icon: const Icon(Icons.timer, color: Colors.orange),
      tooltip: 'Pomodoro Timer',
      onPressed: () {
        // Navigate to Pomodoro tab
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PomodoroPage(),
          ),
        );
      },
    ),

    // Settings
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        // Navigate to Settings
      },
    ),

    // Help
    IconButton(
      icon: const Icon(Icons.help_outline),
      onPressed: () {
        // Navigate to Help
      },
    ),
  ],
)
```

---

## 📊 Implementační Fáze

### **MILESTONE 1: Core Timer Logic** ⏱️ 4-6h
**Priorita**: 🔴 CRITICAL

**Kroky**:
- [ ] 1.1 Vytvoř domain entities (PomodoroSession, TimerState, PomodoroConfig)
- [ ] 1.2 Vytvoř repository interface
- [ ] 1.3 Implementuj PomodoroTimerService (Isolate timer)
- [ ] 1.4 Vytvoř PomodoroBloc (events, states, handlers)
- [ ] 1.5 Testing - Unit test PomodoroBloc
- [ ] **Commit**: `✨ feat: Pomodoro Core Logic (MILESTONE 1)`

**Výsledek**: Funkční timer v Dart (bez UI, bez DB)

---

### **MILESTONE 2: Database Integration** ⏱️ 2-3h
**Priorita**: 🟡 HIGH

**Kroky**:
- [ ] 2.1 Přidej `pomodoro_sessions` tabulku do database_helper.dart
- [ ] 2.2 Vytvoř migration (version 12)
- [ ] 2.3 Implementuj PomodoroLocalDataSource
- [ ] 2.4 Implementuj PomodoroRepositoryImpl
- [ ] 2.5 Propoj BLoC s repository
- [ ] 2.6 Testing - DB CRUD operations
- [ ] **Commit**: `✨ feat: Pomodoro Database Integration (MILESTONE 2)`

**Výsledek**: Sessions ukládány do SQLite

---

### **MILESTONE 3: Basic UI** ⏱️ 3-4h
**Priorita**: 🟡 HIGH

**Kroky**:
- [ ] 3.1 Vytvoř PomodoroPage (základní layout)
- [ ] 3.2 Implementuj TimerDisplay widget
- [ ] 3.3 Implementuj TimerControls widget
- [ ] 3.4 Implementuj SettingsPanel widget
- [ ] 3.5 Implementuj HistoryList widget
- [ ] 3.6 Přidej Pomodoro ikonu do TopBar
- [ ] 3.7 Testing - UI manuálně
- [ ] **Commit**: `🎨 feat: Pomodoro UI (MILESTONE 3)`

**Výsledek**: Funkční Pomodoro Tab page

---

### **MILESTONE 4: Android Notifications** ⏱️ 2-3h
**Priorita**: 🟢 MEDIUM

**Kroky**:
- [ ] 4.1 Přidej dependencies (flutter_local_notifications, permission_handler)
- [ ] 4.2 Update AndroidManifest.xml (permissions, services)
- [ ] 4.3 Vytvoř PomodoroNotificationService
- [ ] 4.4 Implementuj foreground notification s časovačem
- [ ] 4.5 Handle notification actions (Pause/Stop)
- [ ] 4.6 Propoj s PomodoroBloc
- [ ] 4.7 Testing - Android emulator
- [ ] **Commit**: `🔔 feat: Android Foreground Notifications (MILESTONE 4)`

**Výsledek**: Persistent notification v Android status bar

---

### **MILESTONE 5: Integration & Polish** ⏱️ 2-3h
**Priorita**: 🟢 MEDIUM

**Kroky**:
- [ ] 5.1 Přidej "Start Pomodoro" button k TodoItem
- [ ] 5.2 Implementuj Task Picker Dialog
- [ ] 5.3 Přidej zvuk při dokončení (beep)
- [ ] 5.4 Implementuj Duration Picker dialog
- [ ] 5.5 Přidej animace (CircularProgressIndicator na timer)
- [ ] 5.6 Accessibility (tooltips, screen reader)
- [ ] 5.7 Testing - kompletní flow
- [ ] **Commit**: `✨ feat: Pomodoro Integration & Polish (MILESTONE 5)`

**Výsledek**: Kompletní Pomodoro feature

---

### **MILESTONE 6 (Optional): Windows/Desktop Support** ⏱️ 3-4h
**Priorita**: ⚪ LOW (budoucnost)

**Kroky**:
- [ ] 6.1 Přidej `tray_manager` package
- [ ] 6.2 Implementuj Windows system tray icon
- [ ] 6.3 Show timer v tray tooltip
- [ ] 6.4 Tray menu (Start/Pause/Stop)
- [ ] 6.5 Testing - Windows
- [ ] **Commit**: `🪟 feat: Windows System Tray Support (MILESTONE 6)`

**Výsledek**: Windows tray integration

---

## ⚠️ Edge Cases & Considerations

### **1. App v pozadí (Android)**
- ✅ Foreground service zajistí běh timeru
- ✅ Notification aktualizována každých 5s (ne každou sekundu - battery!)
- ⚠️ Doze mode může zpozdit alarm → použít `exactAllowWhileIdle`

### **2. App zabita (Force close)**
- ❌ Timer se ztratí (foreground service umře s appkou)
- **Řešení**: Použít WorkManager pro scheduled check (každých 15 min)
- NEBO: Uložit `expected_end_time` do DB → při restartu resumovat

### **3. Timer precision**
- ✅ Isolate timer je přesný na ~50ms
- ⚠️ Notification update každých 5s (ne každou sekundu)
- ⚠️ Při heavy load může lagovat → priorita Isolate threadu

### **4. Battery drain**
- ⚠️ Foreground service + každých 5s notification update
- **Optimalizace**: Update pouze při změně minuty (ne každých 5s)
- **Monitoring**: Android battery profiler

### **5. Multi-task support**
- ❌ V1: Pouze 1 Pomodoro současně
- ✅ V2: Fronta Pomodoro sessions?

### **6. Persistence po update/reboot**
- ✅ DB sessions přežijí
- ❌ Running timer se ztratí
- **Řešení**: Save `expected_end_time` → resume on restart

---

## 🧪 Testing Checklist

### **Unit Tests**:
- [ ] PomodoroBloc - všechny event handlery
- [ ] PomodoroTimerService - start/pause/resume/stop
- [ ] PomodoroRepository - CRUD operations
- [ ] TimerState transitions

### **Widget Tests**:
- [ ] TimerDisplay - správný formát času
- [ ] TimerControls - správné buttony podle state
- [ ] SettingsPanel - update config
- [ ] HistoryList - zobrazení sessions

### **Integration Tests**:
- [ ] Kompletní flow: Start → Pause → Resume → Complete
- [ ] Break flow: Complete → Auto-start break
- [ ] Continue flow: Complete → Continue
- [ ] DB persistence: Session ukládána správně

### **Manual Tests (Android)**:
- [ ] Notification zobrazena při startu
- [ ] Notification aktualizována každých 5s
- [ ] Pause/Stop akce z notifikace fungují
- [ ] Timer běží v pozadí (app minimalizována)
- [ ] Zvuk přehrán při dokončení
- [ ] Permission request (Android 13+)

### **Performance Tests**:
- [ ] Battery drain measurement (Android Battery Historian)
- [ ] Timer precision test (1000 ticks)
- [ ] Memory leaks (dispose BLoC, Isolate, Notification)

---

## 📚 Příklady použití

### **User Story 1: Základní Pomodoro**
```
1. User klikne na 🍅 ikonu v TopBar
2. Otevře se Pomodoro Tab
3. Klikne na "START"
4. Vybere úkol ze seznamu
5. Timer začne běžet (25 min)
6. Notification zobrazena v Android status bar
7. Po 25 min: Zvuk + "Pomodoro Complete!" notifikace
8. User klikne "BREAK" → 5 min přestávka
9. Po přestávce: Klikne "CONTINUE" → další Pomodoro
10. Po 4 Pomodoro: Klikne "DONE" → úkol dokončen
```

### **User Story 2: Custom Duration**
```
1. User v Settings změní work duration na 45 min
2. Klikne START
3. Timer běží 45 min místo 25
4. Config uložen v SharedPreferences
```

### **User Story 3: Pause & Resume**
```
1. Timer běží
2. User dostane telefonát → klikne PAUSE
3. Timer pozastaven (zůstává 15:30)
4. Po telefonu klikne RESUME
5. Timer pokračuje z 15:30
```

### **User Story 4: Historie**
```
1. User scrollne na HistoryList
2. Vidí seznam všech dnešních sessions:
   - ✅ 10:30 - 25 min - Úkol #5 (dokončeno)
   - ⏸️ 11:00 - 12 min - Úkol #3 (přerušeno)
3. Klikne na session → Detail (budoucnost)
```

---

## 🎯 Budoucí Rozšíření (V2)

### **1. Pomodoro Statistics** 📊
- Celkový počet Pomodoro (dnes/týden/měsíc)
- Průměrná délka session
- Success rate (dokončené vs přerušené)
- Chart s historií (flutter_charts)

### **2. Pomodoro Goals** 🎯
- Cíl: "4 Pomodoro denně"
- Progress bar
- Gamification (streaks, badges)

### **3. Task Auto-Select** 🤖
- AI navrhne úkol na Pomodoro (podle priority/deadline)
- "Start Next Pomodoro" → automaticky vybere úkol

### **4. Desktop Notifications** 🪟
- Windows: Toast notifications
- macOS: Native notifications
- Linux: libnotify

### **5. Multi-Device Sync** ☁️
- Pomodoro sessions sync přes cloud (Supabase)
- Pokračovat v Pomodoro na jiném zařízení

### **6. Team Pomodoro** 👥
- Sdílené Pomodoro sessions
- Group break notifications

### **7. Focus Mode** 🧘
- Disable jiné notifikace během Pomodoro
- "Do Not Disturb" integrace (Android DND API)

---

## 📝 Poznámky k implementaci

### **Rozdíly oproti Tauri verzi**:
1. **Timer mechanismus**:
   - Tauri: `setInterval` v JS (main thread)
   - Flutter: Isolate-based timer (separátní thread)

2. **Notifications**:
   - Tauri: Tauri native API
   - Flutter: `flutter_local_notifications` + Foreground Service

3. **State management**:
   - Tauri: Global JS object + events
   - Flutter: BLoC pattern (immutable state)

4. **DB Access**:
   - Tauri: Rust commands via IPC
   - Flutter: Direct SQLite access (sqflite)

5. **UI**:
   - Tauri: HTML/CSS panel (fixed position)
   - Flutter: Tab page (Material Design)

### **Výhody Flutter přístupu**:
- ✅ Type-safe (Dart strong typing)
- ✅ Reactive (BLoC streams)
- ✅ Testable (unit/widget/integration tests)
- ✅ Cross-platform (Android/iOS/Windows/Linux)
- ✅ Native performance (no web bridge)

### **Nevýhody**:
- ⚠️ Více boilerplate (events, states, repository pattern)
- ⚠️ Komplexnější notification setup (AndroidManifest)
- ⚠️ Platform-specific kód (Android foreground service)

---

## 🚀 Quick Start Guide

### **Pro rychlou implementaci (MVP)**:

1. **Začni s MILESTONE 1** (Core Timer Logic) - 4-6h
2. **Pokračuj MILESTONE 2** (Database) - 2-3h
3. **Pak MILESTONE 3** (UI) - 3-4h
4. **Android notifikace přidej později** (MILESTONE 4)

**Minimální funkční verze**: Milestones 1-3 (celkem ~10-13h práce)

**Plná verze s notifikacemi**: Milestones 1-5 (celkem ~15-20h práce)

---

## 🔗 Související Dokumenty

- [bloc.md](bloc.md) - BLoC best practices
- [mapa-bloc.md](mapa-bloc.md) - Decision tree (SCÉNÁŘ 1 - Nová feature)
- [rodel.md](rodel.md) - AI Split feature (podobný pattern)
- [sqlite-final.md](sqlite-final.md) - Database migration guide

---

## ✅ Checklist před implementací

- [ ] Přečetl jsem mapa-bloc.md (SCÉNÁŘ 1)
- [ ] Přečetl jsem bloc.md (Feature-First architektura)
- [ ] Rozumím Tauri implementaci
- [ ] Rozumím Flutter notification systému
- [ ] Rozumím Isolate-based timeru
- [ ] Snapshot commit před začátkem
- [ ] Připraven na 15-20h práce

---

**Verze**: 1.0
**Vytvořeno**: 2025-01-12
**Autor**: Claude Code (AI asistent)
**Status**: ✅ Připraveno k implementaci

---

## 🎬 Příklad kompletního flow (pseudokód)

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service (Android)
  if (Platform.isAndroid) {
    await PomodoroNotificationService().initialize();
  }

  runApp(MyApp());
}

// User clicks 🍅 icon
Navigator.push(context, MaterialPageRoute(
  builder: (_) => PomodoroPage(),
));

// User clicks START
context.read<PomodoroBloc>().add(
  StartPomodoroEvent(taskId: 5),
);

// BLoC handles event
Future<void> _onStartPomodoro(...) async {
  // 1. Create session in DB
  final session = await _repository.createSession(...);

  // 2. Start isolate timer
  await _timerService.start(Duration(minutes: 25));

  // 3. Subscribe to ticks
  _timerSubscription = _timerService.tickStream.listen((remaining) {
    add(TimerTickEvent(remaining));
  });

  // 4. Show Android notification
  await _notificationService?.showTimerNotification(...);

  // 5. Emit new state
  emit(state.copyWith(
    timerState: TimerState.running,
    remainingTime: Duration(minutes: 25),
  ));
}

// Every second: Update UI & notification
void _onTimerTick(TimerTickEvent event, ...) {
  emit(state.copyWith(remainingTime: event.remainingTime));

  if (event.remainingTime.inSeconds % 5 == 0) {
    _notificationService?.showTimerNotification(...);
  }
}

// When complete
void _onTimerComplete(...) async {
  // 1. Update session
  await _repository.updateSession(
    state.currentSession!.copyWith(completed: true),
  );

  // 2. Play sound
  // AudioPlayer.play('beep.mp3');

  // 3. Show completion notification
  await _notificationService?.showCompletionNotification();

  // 4. Auto-start break?
  if (state.config.autoStartBreak) {
    add(StartBreakEvent());
  }
}
```

---

🍅 **Happy Pomodoro Coding!** 🍅
