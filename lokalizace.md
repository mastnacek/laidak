# Lokalizace TODO Doom - Implementační plán

## 📋 Obsah
1. [Technologie a důvody](#technologie-a-důvody)
2. [Podporované jazyky](#podporované-jazyky)
3. [Architektura](#architektura)
4. [Implementační kroky](#implementační-kroky)
5. [Soubory k vytvoření](#soubory-k-vytvoření)
6. [Strings k překladu](#strings-k-překladu)
7. [Testing checklist](#testing-checklist)

---

## 🎯 Technologie a důvody

### Zvolená technologie: **Flutter Intl (Official)**

**Proč Flutter Intl a NE easy_localization:**

| Feature | Flutter Intl | easy_localization |
|---------|-------------|-------------------|
| Oficiální Flutter podpora | ✅ Ano | ❌ Ne |
| Type-safe přístup | ✅ Ano (`AppLocalizations.of(context)!.addTask`) | ❌ Ne (`'add_task'.tr()`) |
| Compile-time kontrola | ✅ Ano (chyba při buildu) | ❌ Ne (runtime error) |
| IDE auto-complete | ✅ Ano | ⚠️ Částečně |
| Pluralizace | ✅ Built-in | ⚠️ Omezená |
| Gender support | ✅ Ano | ❌ Ne |
| Date/Number formatting | ✅ Ano | ⚠️ Částečně |
| Performance | ✅ Lepší (compiled) | ⚠️ Runtime parsing |
| Budoucnost | ✅ Long-term support | ⚠️ Community-driven |

**Rozhodnutí:** Flutter Intl - pro production-ready app s long-term maintenance.

---

## 🌍 Podporované jazyky

### Priorita 1 (Launch):
- 🇨🇿 **Čeština (cs)** - Primární jazyk, výchozí
- 🇬🇧 **Angličtina (en)** - Mezinárodní publikum

### Priorita 2 (Future):
- 🇸🇰 **Slovenština (sk)** - Blízký jazyk, snadný překlad
- 🇩🇪 **Němčina (de)** - DACH region
- 🇵🇱 **Polština (pl)** - V4 země

**Výchozí jazyk:** Čeština (cs)

**Fallback:** Pokud zařízení má jiný jazyk než cs/en → fallback na en

---

## 🏗️ Architektura

```
lib/
├── l10n/                           # Lokalizační soubory
│   ├── app_cs.arb                  # Česká lokalizace
│   ├── app_en.arb                  # Anglická lokalizace
│   └── app_sk.arb                  # Slovenská lokalizace (future)
│
├── core/
│   └── localization/
│       └── locale_manager.dart     # Správa locale (persistence v DB)
│
├── features/
│   └── settings/
│       └── presentation/
│           └── widgets/
│               └── language_selector.dart  # Widget pro výběr jazyka
│
└── generated/
    └── intl/                       # Auto-generované soubory (gitignored)
        ├── messages_all.dart
        ├── messages_cs.dart
        └── messages_en.dart
```

### ARB soubor struktura:

```json
{
  "@@locale": "cs",
  "@@last_modified": "2025-10-10T12:00:00.000Z",

  "appTitle": "TODO Doom",
  "@appTitle": {
    "description": "Název aplikace zobrazený v AppBar"
  },

  "addTask": "Přidat úkol",
  "@addTask": {
    "description": "Tlačítko pro přidání nového úkolu"
  }
}
```

**Proč `@key` metadata?**
- Kontext pro překladatele
- Dokumentace
- IDE tooltips

---

## 📝 Implementační kroky

### **Krok 1: Setup dependencies**

**Soubor:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  intl_utils: ^2.8.7  # Generování kódu
```

**Přidat flutter config:**

```yaml
flutter:
  generate: true  # Aktivovat code generation

  assets:
    - assets/translations/  # Pro fallback/custom resources
```

**Vytvořit:** `l10n.yaml`

```yaml
arb-dir: lib/l10n
template-arb-file: app_cs.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
nullable-getter: false
```

---

### **Krok 2: Vytvoření ARB souborů**

**Vytvoř:** `lib/l10n/app_cs.arb` (hlavní template)

Obsahuje VŠECHNY stringy z aplikace s `@key` metadaty.

**Vytvoř:** `lib/l10n/app_en.arb` (anglický překlad)

Zkopírovat strukturu z `app_cs.arb` a přeložit hodnoty.

---

### **Krok 3: Extrakce stringů**

**Projít všechny soubory a najít hard-coded texty:**

```bash
# Search pattern
grep -r "Text\|'[A-Z]" lib/ --include="*.dart"
```

**Kategorie stringů:**

1. **UI Labels** (tlačítka, titulky)
2. **Messages** (SnackBar zprávy, errory)
3. **Placeholders** (hint texty)
4. **Dialog texty**
5. **AI prompty** (system prompts - NEKONTROLOVAT!)

**DŮLEŽITÉ:** AI system prompty (v DB) NEMĚNIT - zůstávají v češtině!

---

### **Krok 4: Implementace LocaleManager**

**Vytvoř:** `lib/core/localization/locale_manager.dart`

```dart
import 'package:flutter/material.dart';
import '../services/database_helper.dart';

/// Singleton pro správu locale
/// Persistence v SQLite databázi
class LocaleManager {
  static final LocaleManager _instance = LocaleManager._internal();
  factory LocaleManager() => _instance;
  LocaleManager._internal();

  final DatabaseHelper _db = DatabaseHelper();
  Locale _currentLocale = const Locale('cs'); // Výchozí

  Locale get currentLocale => _currentLocale;

  /// Načíst locale z databáze
  Future<Locale> loadLocale() async {
    final settings = await _db.getSettings();
    final langCode = settings['language'] as String? ?? 'cs';
    _currentLocale = Locale(langCode);
    return _currentLocale;
  }

  /// Uložit locale do databáze
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    await _db.updateSettings(language: locale.languageCode);
  }

  /// Podporované lokály
  static const List<Locale> supportedLocales = [
    Locale('cs'), // Čeština
    Locale('en'), // Angličtina
  ];
}
```

---

### **Krok 5: Database schema update**

**Přidat sloupec `language` do `settings` tabulky:**

**V DatabaseHelper:**

```dart
// Version 7 → 8
if (oldVersion < 8) {
  await db.execute('''
    ALTER TABLE settings ADD COLUMN language TEXT NOT NULL DEFAULT 'cs'
  ''');
}
```

---

### **Krok 6: MaterialApp setup**

**Upravit:** `lib/main.dart`

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/localization/locale_manager.dart';

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  Locale _locale = const Locale('cs');

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await LocaleManager().loadLocale();
    setState(() {
      _locale = locale;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LocaleManager().setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO Doom',

      // Lokalizace
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleManager.supportedLocales,

      // Callback pro změnu jazyka
      builder: (context, child) {
        return LocaleProvider(
          changeLocale: _changeLocale,
          child: child!,
        );
      },

      theme: theme,
      home: const TodoListPage(),
    );
  }
}

/// Provider pro změnu locale z vnořených widgetů
class LocaleProvider extends InheritedWidget {
  final Function(Locale) changeLocale;

  const LocaleProvider({
    super.key,
    required this.changeLocale,
    required super.child,
  });

  static LocaleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) => false;
}
```

---

### **Krok 7: Language Selector Widget**

**Vytvoř:** `lib/features/settings/presentation/widgets/language_selector.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/localization/locale_manager.dart';
import '../../../../main.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text(_getLanguageName(currentLocale.languageCode)),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleManager.supportedLocales.map((locale) {
            return RadioListTile<Locale>(
              title: Text(_getLanguageName(locale.languageCode)),
              value: locale,
              groupValue: Localizations.localeOf(context),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  LocaleProvider.of(context)?.changeLocale(newLocale);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'cs': return '🇨🇿 Čeština';
      case 'en': return '🇬🇧 English';
      case 'sk': return '🇸🇰 Slovenčina';
      default: return code;
    }
  }
}
```

---

### **Krok 8: Použití v kódu**

**Před:**
```dart
Text('Přidat úkol')
```

**Po:**
```dart
final l10n = AppLocalizations.of(context)!;
Text(l10n.addTask)
```

**Pattern:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(l10n.appTitle),
        ElevatedButton(
          onPressed: () {},
          child: Text(l10n.addTask),
        ),
      ],
    );
  }
}
```

---

## 📄 Soubory k vytvoření

### 1. Konfigurační soubory:
- `l10n.yaml` (v root projektu)

### 2. ARB soubory:
- `lib/l10n/app_cs.arb` (primární template)
- `lib/l10n/app_en.arb` (anglický překlad)

### 3. Dart soubory:
- `lib/core/localization/locale_manager.dart`
- `lib/features/settings/presentation/widgets/language_selector.dart`

### 4. Database migration:
- Update `DatabaseHelper` - version 8, přidat `language` sloupec

### 5. MaterialApp update:
- Update `lib/main.dart` - přidat localization delegates

---

## 📝 Strings k překladu

### Kategorie 1: Obecné UI
- `appTitle` - "TODO Doom"
- `loading` - "Načítání..."
- `error` - "Chyba"
- `save` - "Uložit"
- `cancel` - "Zrušit"
- `delete` - "Smazat"
- `edit` - "Editovat"
- `close` - "Zavřít"
- `confirm` - "Potvrdit"
- `retry` - "Zkusit znovu"

### Kategorie 2: Todo List
- `addTask` - "Přidat úkol"
- `editTask` - "Editovat úkol"
- `deleteTask` - "Smazat úkol"
- `taskCompleted` - "Úkol dokončen"
- `taskIncomplete` - "Úkol nedokončen"
- `noTasks` - "Žádné úkoly"
- `showCompleted` - "Zobrazit dokončené"
- `hideCompleted` - "Skrýt dokončené"

### Kategorie 3: AI Split
- `aiSplit` - "AI rozdělení úkolu"
- `aiAnalyzing` - "AI analyzuje úkol..."
- `subtasks` - "Podúkoly"
- `recommendations` - "Doporučení"
- `deadline` - "Termín"
- `accept` - "Přijmout"
- `reject` - "Odmítnout"
- `retryNote` - "Poznámka pro retry..."

### Kategorie 4: Priority
- `priorityHigh` - "Vysoká priorita"
- `priorityMedium` - "Střední priorita"
- `priorityLow` - "Nízká priorita"

### Kategorie 5: Settings
- `settings` - "Nastavení"
- `language` - "Jazyk"
- `selectLanguage` - "Vybrat jazyk"
- `theme` - "Téma"
- `aiSettings` - "AI nastavení"
- `apiKey` - "API klíč"
- `model` - "Model"
- `temperature` - "Teplota"

### Kategorie 6: Errory
- `errorLoadingTasks` - "Chyba při načítání úkolů"
- `errorAddingTask` - "Chyba při přidávání úkolu"
- `errorUpdatingTask` - "Chyba při aktualizaci úkolu"
- `errorDeletingTask` - "Chyba při mazání úkolu"
- `errorAiSplit` - "Chyba při volání AI"
- `errorNoSubtasks` - "AI nevrátilo žádné podúkoly"
- `errorApiKey` - "API klíč není nastaven"

### Kategorie 7: SnackBar messages
- `taskAdded` - "✅ Úkol byl přidán"
- `taskUpdated` - "✅ Úkol byl aktualizován"
- `taskDeleted` - "🗑️ Úkol byl smazán"
- `subtasksAccepted` - "✓ {count} podúkolů přidáno"

### Kategorie 8: Placeholders
- `taskInputHint` - "*a* *dnes* *udelat* nakoupit, *rodina*"
- `searchHint` - "Hledat úkoly..."
- `noteHint` - "Poznámka..."

**CELKEM: ~60-80 stringů**

---

## 🧪 Testing Checklist

### Funkční testy:

- [ ] Změna jazyka v Settings funguje
- [ ] Jazyk se persistuje po restartu aplikace
- [ ] Všechny stringy jsou přeložené (žádný hard-coded text)
- [ ] Fallback na en funguje pro neznámé locale
- [ ] Výchozí jazyk je cs při první instalaci

### UI testy:

- [ ] Všechny widgety se vejdou (žádný overflow kvůli delším textům)
- [ ] Datum/čas se formátuje podle locale (cs: 10. 10. 2025, en: Oct 10, 2025)
- [ ] Čísla se formátují podle locale (cs: 1 234,56, en: 1,234.56)

### Edge cases:

- [ ] Přepnutí jazyka za běhu aplikace (hot-switch)
- [ ] Velmi dlouhé překlady (němčina má delší slova)
- [ ] RTL jazyky (future: arabština) - zatím neřešit
- [ ] Screen reader / accessibility

### Performance:

- [ ] Žádná lag při přepnutí jazyka
- [ ] Minimální memory footprint (compiled ARB)

---

## 📚 Best Practices

### ✅ DO:

1. **Vždy používej klíče ve formátu camelCase**
   ```json
   "addTask": "Přidat úkol"  ✅
   "add_task": "..."          ❌
   ```

2. **Přidávej metadata (@key) pro kontext**
   ```json
   "save": "Uložit",
   "@save": {
     "description": "Tlačítko pro uložení změn"
   }
   ```

3. **Používej placeholders pro dynamické hodnoty**
   ```json
   "subtasksCount": "{count} podúkolů",
   "@subtasksCount": {
     "placeholders": {
       "count": {
         "type": "int"
       }
     }
   }
   ```

4. **Odděluj kategorie prázdnými řádky v ARB**
   ```json
   {
     "appTitle": "TODO Doom",

     "addTask": "Přidat úkol",
     "editTask": "Editovat úkol"
   }
   ```

5. **Vytvoř helper extension pro častý pattern**
   ```dart
   extension LocalizationExtension on BuildContext {
     AppLocalizations get l10n => AppLocalizations.of(this)!;
   }

   // Použití:
   Text(context.l10n.addTask)
   ```

### ❌ DON'T:

1. **Nepřekládej AI system prompty**
   - Zůstávají v DB jako jsou (česky)
   - AI modely fungují lépe s konkrétním promptem

2. **Nepoužívej string concatenation**
   ```dart
   // ❌ BAD
   Text(l10n.you + ' ' + l10n.have + ' ' + count + ' ' + l10n.tasks)

   // ✅ GOOD
   Text(l10n.taskCount(count))  // "Máte {count} úkolů"
   ```

3. **Nemixtuj hard-coded text s lokalizací**
   ```dart
   // ❌ BAD
   Text('Úkol: ${l10n.addTask}')

   // ✅ GOOD
   Text(l10n.taskLabel(l10n.addTask))  // "Úkol: Přidat úkol"
   ```

4. **Nepoužívej emoji v ARB souborech**
   ```json
   // ❌ BAD
   "taskAdded": "✅ Úkol byl přidán"

   // ✅ GOOD
   "taskAdded": "Úkol byl přidán"  // Emoji přidat v Dart kódu
   ```

5. **Neignoruj pluralizaci**
   ```json
   // ✅ GOOD
   "taskCount": "{count, plural, =0{Žádné úkoly} =1{1 úkol} few{{count} úkoly} other{{count} úkolů}}"
   ```

---

## 🚀 Implementační timeline

### Fáze 1: Setup (30 min)
1. Přidat dependencies do pubspec.yaml
2. Vytvořit l10n.yaml
3. Vytvořit strukturu složek

### Fáze 2: ARB soubory (2-3 hod)
1. Extrakce stringů z kódu (grep)
2. Vytvoření app_cs.arb s metadaty
3. Překlad do app_en.arb

### Fáze 3: Core implementation (1-2 hod)
1. LocaleManager implementace
2. Database migration (version 8)
3. MaterialApp setup

### Fáze 4: UI updates (1-2 hod)
1. LanguageSelector widget
2. Přidání do Settings page
3. Replace hard-coded stringů

### Fáze 5: Testing (1 hod)
1. Funkční testy
2. UI testy
3. Edge cases

**CELKEM: ~6-9 hodin**

---

## 🎯 Výsledek

Po implementaci:

1. ✅ Plně lokalizovaná aplikace (cs + en)
2. ✅ Type-safe přístup k překladům
3. ✅ Persistentní uložení jazyka
4. ✅ UI pro výběr jazyka v Settings
5. ✅ Připraveno na další jazyky (sk, de, pl)
6. ✅ Production-ready implementace

---

**Vytvořeno:** 2025-10-10
**Autor:** Claude Code (AI asistent)
**Verze:** 1.0
**Status:** Plán - čeká na implementaci
