# 🔊 Text-to-Speech (TTS) Feature - Předčítání úkolů nahlas

> **Účel**: Implementační dokumentace pro přidání TTS funkcionality do TODO aplikace
> **Plugin**: flutter_tts (https://pub.dev/packages/flutter_tts)
> **Datum vytvoření**: 2025-01-10
> **Status**: 📋 Plánováno (není implementováno)

---

## 📋 Přehled

Funkce umožní uživatelům **poslechnout si text úkolu nahlas** kliknutím na ikonu 🔊 reproduktoru v každém TODO kartě. Ideální pro:
- ♿ **Accessibility** - Podpora pro zrakově postižené
- 🚗 **Hands-free použití** - Poslech úkolů při řízení
- 🎧 **Multitasking** - Poslech při práci na jiných věcech

---

## 🔍 Research - Zjištěné informace

### WebSearch výsledky (2025-01-10):

**flutter_tts** je nejlepší volba:
- ✅ Nejpopulárnější TTS plugin pro Flutter
- ✅ Podporuje: Android, iOS, Web, Windows, macOS
- ✅ Trust Score: 8.3/10
- ✅ 63+ code snippets v dokumentaci
- ✅ Aktivně udržovaný (poslední update 2024)

### Context7 dokumentace (/dlutton/flutter_tts):

**Klíčové API:**
```dart
FlutterTts flutterTts = FlutterTts();
await flutterTts.setLanguage("cs-CZ");      // Čeština
await flutterTts.setSpeechRate(0.5);        // Rychlost (0.0 - 1.0)
await flutterTts.setVolume(1.0);            // Hlasitost (0.0 - 1.0)
await flutterTts.setPitch(1.0);             // Výška hlasu (0.5 - 2.0)
await flutterTts.speak("Text k přečtení");  // Přečíst nahlas
await flutterTts.stop();                    // Zastavit
```

**Android požadavky:**
- minSdkVersion 21+ (✅ už máme)
- Android Manifest update (queries element)

---

## 📱 Implementační plán

### **Fáze 1: Setup (5 min)**

#### 1.1 Přidat dependency

`pubspec.yaml`:
```yaml
dependencies:
  flutter_tts: ^4.2.0
```

#### 1.2 Android Manifest

`android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
  <!-- ... -->

  <queries>
    <intent>
      <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
  </queries>

  <!-- ... -->
</manifest>
```

#### 1.3 Ověřit minSdkVersion

`android/app/build.gradle`:
```groovy
android {
  defaultConfig {
    minSdkVersion 21  // ✅ Už máme!
  }
}
```

---

### **Fáze 2: TTS Service (10 min)**

Vytvořit `lib/services/tts_service.dart`:

```dart
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton service pro Text-to-Speech
///
/// Použití:
/// ```dart
/// final tts = TtsService();
/// await tts.speak("Nakoupit mléko");
/// ```
class TtsService {
  // Singleton pattern
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  /// Inicializace TTS enginu
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Nastavení pro češtinu
      await _flutterTts.setLanguage("cs-CZ");

      // Optimální nastavení pro srozumitelnost
      await _flutterTts.setSpeechRate(0.5);  // Pomalejší = lépe srozumitelné
      await _flutterTts.setVolume(1.0);      // Plná hlasitost
      await _flutterTts.setPitch(1.0);       // Normální výška

      // Callbacky pro state tracking
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      print('TTS Initialization failed: $e');
    }
  }

  /// Přečíst text nahlas
  Future<void> speak(String text) async {
    await initialize();

    if (_isSpeaking) {
      await stop(); // Zastavit předchozí řeč
    }

    await _flutterTts.speak(text);
  }

  /// Zastavit aktuální řeč
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  /// Zjistit, zda momentálně mluví
  bool get isSpeaking => _isSpeaking;

  /// Cleanup při dispose
  void dispose() {
    _flutterTts.stop();
  }
}
```

---

### **Fáze 3: UI Update - TodoCard (10 min)**

Upravit `lib/features/todo_list/presentation/widgets/todo_card.dart`:

#### 3.1 Import TTS service

```dart
import '../../../../services/tts_service.dart';
import 'package:intl/intl.dart';
```

#### 3.2 Přidat TTS tlačítko

V trailing sekci TodoCard (před Checkbox):

```dart
// Aktuální trailing:
trailing: Checkbox(
  value: todo.isCompleted,
  onChanged: (value) {
    context.read<TodoListBloc>().add(
      ToggleTodoEvent(todo.id!, value ?? false),
    );
  },
),

// Změnit na Row s TTS button:
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // TTS button
    IconButton(
      icon: const Icon(Icons.volume_up, size: 20),
      tooltip: 'Přečíst nahlas',
      color: theme.appColors.blue,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      onPressed: () {
        _speakTodo(context, todo);
      },
    ),

    const SizedBox(width: 4),

    // Checkbox (původní)
    Checkbox(
      value: todo.isCompleted,
      onChanged: (value) {
        context.read<TodoListBloc>().add(
          ToggleTodoEvent(todo.id!, value ?? false),
        );
      },
    ),
  ],
),
```

#### 3.3 Metoda pro TTS

Přidat do `_TodoCardState`:

```dart
void _speakTodo(BuildContext context, Todo todo) {
  final tts = TtsService();

  // Sestavit text k přečtení
  final buffer = StringBuffer();

  // Základní text úkolu
  buffer.write(todo.task);
  buffer.write('. ');

  // Priorita
  if (todo.priority != null) {
    final priorityText = {
      'A': 'Priorita A',
      'B': 'Priorita B',
      'C': 'Priorita C',
    }[todo.priority];
    buffer.write(priorityText ?? 'Priorita ${todo.priority}');
    buffer.write('. ');
  }

  // Deadline
  if (todo.dueDate != null) {
    final dateText = DateFormat.yMd("cs").format(todo.dueDate!);
    buffer.write('Termín $dateText. ');
  }

  // Tagy
  if (todo.tags != null && todo.tags!.isNotEmpty) {
    buffer.write('Štítky: ${todo.tags!.join(", ")}. ');
  }

  // Status
  if (todo.isCompleted) {
    buffer.write('Hotovo.');
  } else {
    buffer.write('Nedokončeno.');
  }

  // Přečíst
  tts.speak(buffer.toString());
}
```

---

### **Fáze 4: UX Vylepšení (Optional, 10 min)**

#### 4.1 Vizuální feedback při mluvení

```dart
// StatefulWidget tracking
bool _isSpeakingThis = false;

// Button s animací
IconButton(
  icon: Icon(
    _isSpeakingThis ? Icons.volume_off : Icons.volume_up,
    size: 20,
  ),
  color: _isSpeakingThis
      ? theme.appColors.red
      : theme.appColors.blue,
  // ...
)
```

#### 4.2 Long press = stop

```dart
GestureDetector(
  onTap: () => _speakTodo(context, todo),
  onLongPress: () {
    TtsService().stop();
  },
  child: Icon(Icons.volume_up, size: 20),
)
```

#### 4.3 Nastavení TTS v SettingsPage

Přidat do `lib/pages/settings_page.dart`:

```dart
// TTS rychlost
ListTile(
  title: const Text('Rychlost přečítání'),
  subtitle: Slider(
    value: _speechRate,
    min: 0.1,
    max: 1.0,
    divisions: 9,
    label: _speechRate.toStringAsFixed(1),
    onChanged: (value) {
      setState(() => _speechRate = value);
      _flutterTts.setSpeechRate(value);
    },
  ),
),
```

---

## 📊 Výsledek

### Před implementací:
```
┌─────────────────────────┐
│ ☑ Nakoupit mléko       │
│   *a* *dnes*           │
│                      ☐  │
└─────────────────────────┘
```

### Po implementaci:
```
┌─────────────────────────┐
│ ☑ Nakoupit mléko       │
│   *a* *dnes*           │
│                 🔊 ☐    │ ← Nová ikona!
└─────────────────────────┘
```

**Tap na 🔊** → Telefon přečte:
> *"Nakoupit mléko. Priorita A. Termín 10. 1. 2025. Nedokončeno."*

---

## ⚙️ Konfigurace

### Podporované jazyky:
- ✅ `cs-CZ` - Čeština
- ✅ `en-US` - Angličtina
- ✅ `de-DE` - Němčina
- ✅ `sk-SK` - Slovenština
- ... (další dle systému)

### Optimální nastavení pro češtinu:
```dart
speechRate: 0.5  // Pomalejší = lépe srozumitelné
volume: 1.0      // Plná hlasitost
pitch: 1.0       // Normální výška
```

---

## 🧪 Testování

### Test checklist:
- [ ] TTS funguje v české lokalizaci
- [ ] Přečte úkol s prioritou
- [ ] Přečte úkol s deadlinem
- [ ] Přečte úkol s tagy
- [ ] Zastaví předchozí řeč při novém kliknutí
- [ ] Funguje na Android 11+
- [ ] Funguje na starších Android 7-10
- [ ] Chování při zamčené obrazovce
- [ ] Hlasitost respektuje systémové nastavení

---

## 📦 Velikost APK

**Dopad na velikost:**
- flutter_tts plugin: ~200 KB
- Bez zvětšení native TTS enginů (používá systémové)

**Celková velikost APK:**
- Před: 49.7 MB
- Po: ~49.9 MB (+200 KB)

---

## ♿ Accessibility benefity

1. **Zrakově postižení** - Kompletní přístup k TODO aplikaci
2. **Dyslexie** - Poslech místo čtení
3. **Multitasking** - Poslech při jiných aktivitách
4. **Driving mode** - Bezpečné sledování úkolů při řízení

---

## 🔧 Troubleshooting

### Problém: TTS nemluví česky
**Řešení**: Zkontrolovat, zda je v systému nainstalován český TTS engine
```dart
List<dynamic> languages = await flutterTts.getLanguages();
print('Dostupné jazyky: $languages');
```

### Problém: Příliš rychlá řeč
**Řešení**: Snížit speechRate
```dart
await flutterTts.setSpeechRate(0.3);  // Ještě pomalejší
```

### Problém: TTS nefunguje na emulátoru
**Řešení**: TTS vyžaduje fyzické zařízení nebo emulátor s Google Play Services

---

## 📚 Reference

### Dokumentace:
- flutter_tts pub.dev: https://pub.dev/packages/flutter_tts
- GitHub repo: https://github.com/dlutton/flutter_tts
- Android TTS API: https://developer.android.com/reference/android/speech/tts/TextToSpeech

### Použité MCP servery:
- ✅ WebSearch: "Flutter text to speech TTS plugin 2025"
- ✅ Context7: `/dlutton/flutter_tts` (Trust Score: 8.3)

---

## 🎯 Implementační status

**Aktuální status**: 📋 **Plánováno** (není implementováno)

**Odhadovaný čas implementace**: 25-35 minut
- Fáze 1 (Setup): 5 min
- Fáze 2 (Service): 10 min
- Fáze 3 (UI): 10 min
- Fáze 4 (Testing): 5-10 min

**Priorita**: ⭐⭐ Střední (Nice-to-have feature)

---

## 📝 Poznámky

- TTS používá **systémový engine** (žádné extra downloady)
- Kvalita hlasu závisí na **zařízení a Android verzi**
- Google TTS je obvykle nejkvalitnější
- Starší zařízení mohou mít robotičtější hlas
- TTS funguje i **offline** (pokud je jazyk nainstalován)

---

**Vytvořeno**: 2025-01-10
**Autor**: Claude Code (AI asistent)
**Verze dokumentace**: 1.0
