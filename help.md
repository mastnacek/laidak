# 📘 INTERAKTIVNÍ NÁPOVĚDA - Design & Implementace

> **Účel**: Komplexní help systém s interaktivními AI demo
> **Status**: 📋 Plánováno (design phase)
> **Priorita**: ⭐⭐⭐ Vysoká (kritické pro onboarding)
> **Odhad**: 3-4 hodiny implementace

---

## 🎯 VIZE

Vytvořit **interaktivní nápovědu** která:
- ✅ Vysvětlí všechny funkce aplikace na **praktických příkladech**
- ✅ Umožní **vyzkoušet AI funkce** (split, motivation) živě
- ✅ Naučí uživatele **používat tagy** s real-time náhledem
- ✅ Bude **zábavná a intuitivní** - ne nudná dokumentace!

---

## 📐 UX DESIGN - 3 Varianty

### **Varianta A: Tab-based Layout**
```
┌─────────────────────────────────────┐
│ 📘 Nápověda              [Zavřít]   │
├─────────────────────────────────────┤
│ [🏷️ Tagy] [🤖 AI] [💬 Prompty]    │ ← Tabs
├─────────────────────────────────────┤
│ Content scrollable area             │
│                                     │
│ Vysvětlení + Příklady + Demo       │
│                                     │
│ [🎮 Vyzkoušet interaktivně]        │
└─────────────────────────────────────┘
```

**Výhody**: ✅ Organized, ✅ Desktop-friendly
**Nevýhody**: ❌ Více tapů, ❌ Méně mobile-friendly

---

### **Varianta B: Card-based Layout** ⭐ **DOPORUČUJI!**
```
┌─────────────────────────────────────┐
│ 📘 Nápověda              [Zavřít]   │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏷️ Jak používat tagy?          │ │
│ │ *a* *dnes* *nakoupit*          │ │
│ │                                 │ │
│ │ [📖 Zobrazit příklady]         │ │
│ │ [🎮 Vyzkoušet živě]            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🤖 AI Rozdělení úkolu          │ │
│ │ Rozděl složitý úkol na kroky   │ │
│ │                                 │ │
│ │ ⚠️ Vyžaduje API key             │ │
│ │ [🎮 Vyzkoušet demo]            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💬 Motivační prompty           │ │
│ │ AI ti pomůže s motivací        │ │
│ │                                 │ │
│ │ ⚠️ Vyžaduje API key             │ │
│ │ [🎮 Vyzkoušet demo]            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ (scrollable...)                     │
└─────────────────────────────────────┘
```

**Výhody**: ✅ Intuitivní, ✅ Mobile-first, ✅ Visual hierarchy
**Nevýhody**: ❌ Delší scrolling

---

### **Varianta C: Wizard-style (First-time only)**
```
┌─────────────────────────────────────┐
│ 👋 Vítej v TODO aplikaci!          │
├─────────────────────────────────────┤
│                                     │
│  Krok 1 / 5                         │
│  [████████░░░░░░░░░░]              │
│                                     │
│  📝 Vytvoř svůj první úkol         │
│                                     │
│  Zadej text úkolu:                  │
│  [________________________]         │
│                                     │
│                                     │
│  [Přeskočit] [Další →]             │
└─────────────────────────────────────┘
```

**Výhody**: ✅ Guided, ✅ Progressive disclosure
**Nevýhody**: ❌ Zdlouhavé, ❌ Nelze rychle najít info

---

## ✅ ROZHODNUTÍ: Kombinace B + C

1. **First-time user**: Wizard (3-5 kroků, skippable)
2. **Returning user**: Card-based help page (accessible anytime)

---

## 🎨 SEKCE NÁPOVĚDY (Priority)

### **1. 🏷️ Tagy a TagParser** (Must-have)

**Vysvětlení:**
- Priorita: `*a*`, `*b*`, `*c*`
- Datum: `*dnes*`, `*zitra*`, `*DD.MM.*`
- Akce: `*koupit*`, `*zavolat*`, `*napsat*`
- Custom tagy: `*prace*`, `*domov*`, `*sport*`

**Příklady:**
```
*a* *dnes* Zavolat doktorovi
→ Priorita A, Deadline dnes

*b* *15.1.* Koupit dárek mámě
→ Priorita B, Deadline 15.1.2025

*c* Uklidit garáž *domov*
→ Priorita C, Tag: domov
```

**Interaktivní demo:**
- Live input field s real-time highlighting
- Show parsed result instantly
- Copy-paste examples

**Implementace:**
```dart
// TagDemoWidget
TextField(
  onChanged: (text) {
    final parsed = TagParser.parse(text);
    setState(() => _parsedResult = parsed);
  },
)

// Live preview:
Card(
  child: Column([
    Text('Čistý text: ${_parsedResult.cleanText}'),
    Text('Priorita: ${_parsedResult.priority}'),
    Text('Deadline: ${_parsedResult.dueDate}'),
  ]),
)
```

---

### **2. 🤖 AI Rozdělení úkolu** (Should-have)

**Vysvětlení:**
- Rozděl komplexní úkol na menší kroky
- AI navrhne podúkoly
- Můžeš upravit a uložit

**Příklad:**
```
Input: "Naplánovat dovolenou v Itálii"

AI Output:
1. ✅ Zjistit termín dovolené
2. ✅ Vybrat destinaci (Řím vs. Florencie)
3. ✅ Rezervovat letenky
4. ✅ Najít ubytování
5. ✅ Naplánovat aktivity
6. ✅ Zařídit pojištění
```

**Interaktivní demo:**
```
┌─────────────────────────────────────┐
│ 🎮 Vyzkoušej AI Split               │
├─────────────────────────────────────┤
│ Zadej testovací úkol:               │
│ [Naplánovat dovolenou__________]    │
│                                     │
│ OpenRouter API: ✅ Nakonfigurováno  │
│ Model: claude-3.5-sonnet            │
│                                     │
│ [🚀 Rozdělit úkol]                 │
└─────────────────────────────────────┘

↓ Po kliknutí ↓

┌─────────────────────────────────────┐
│ 🎉 Úkol rozdělen!                   │
├─────────────────────────────────────┤
│ ☑ Zjistit termín dovolené           │
│ ☑ Vybrat destinaci                  │
│ ☑ Rezervovat letenky                │
│ ☑ Najít ubytování                   │
│ ☑ Naplánovat aktivity               │
│                                     │
│ [💾 Uložit do skutečných TODO]     │
│ [🔄 Zkusit jiný úkol]              │
└─────────────────────────────────────┘
```

**Implementace:**
```dart
class AiSplitDemoWidget extends StatefulWidget {
  // State: idle, loading, success, error
  // API call s error handling
  // Save to real todos option
}
```

---

### **3. 💬 Motivační prompty** (Should-have)

**Vysvětlení:**
- Vlastní prompty pro AI motivaci
- Typy:励志 (励志), Humor, Deadline pressure, Gentle
- AI ti pomůže s prokrastinací

**Příklad:**
```
Úkol: "Napsat seminární práci"
Prompt typ:励志 (励志)

AI Response:
"💪 Tvoje seminární práce bude skvělá!
Začni s úvodem dnes a za týden budeš mít
hotovo. Každý velký úspěch začíná malým
krokem. Věřím v tebe! 🚀"
```

**Interaktivní demo:**
```
┌─────────────────────────────────────┐
│ 🎮 Vyzkoušej motivační prompt       │
├─────────────────────────────────────┤
│ Vyber nebo napiš úkol:              │
│ [Napsat seminární práci_______]     │
│                                     │
│ Typ motivace:                       │
│ ○ 励志 (励志)                        │
│ ● Humor                             │
│ ○ Deadline tlak                     │
│ ○ Jemný push                        │
│                                     │
│ [💬 Získat motivaci]                │
└─────────────────────────────────────┘
```

**Implementace:**
```dart
class MotivationDemoWidget extends StatefulWidget {
  // Prompt templates
  // API call to OpenRouter
  // Display response in nice card
  // Option to save as note/reminder
}
```

---

### **4. 📊 Režimy zobrazení (Views)** (Must-have)

**Vysvětlení:**
- 📋 Všechny - Kompletní seznam
- 📅 Dnes - Úkoly s deadline dnes
- 🗓️ Týden - Nadcházející týden
- ⏰ Nadcházející - Všechny s deadline
- ⚠️ Po termínu - Overdue úkoly
- 👁️ Hotové - Dokončené úkoly

**Vizuální guide:**
```
FilterChips s ikonami
[📋][📅][🗓️][⏰][⚠️][👁️]
 ↑ Active
```

**Demo:**
- Screenshot každého režimu
- Nebo live demo s fake data

---

### **5. 🔍 Vyhledávání a řazení** (Must-have)

**Vysvětlení:**
- **Search**: Lupa vlevo, live filtering
- **Sort**: Tlačítka [🔴][📅][✅][🆕]
  - Priorita (A → C)
  - Deadline (nejbližší první)
  - Status (nedokončené první)
  - Datum vytvoření (nejnovější)

**Demo:**
- Animated GIF nebo interactive widget

---

### **6. ⚙️ Nastavení a konfigurace** (Should-have)

**Vysvětlení:**
- OpenRouter API key setup
- Model selection
- Custom prompt templates
- Tag color customization
- Theme settings

**Guide:**
- Step-by-step s screenshoty
- Bezpečnostní tipy (API key security)

---

## 🏗️ ARCHITEKTURA

### **Feature Structure:**
```
lib/features/help/
├── presentation/
│   ├── pages/
│   │   ├── help_page.dart              # Main help page
│   │   └── wizard_page.dart            # First-time wizard
│   ├── widgets/
│   │   ├── help_card.dart              # Reusable card component
│   │   ├── tag_demo_widget.dart        # Tag parsing demo
│   │   ├── ai_split_demo_widget.dart   # AI split interactive demo
│   │   └── motivation_demo_widget.dart # Motivation prompt demo
│   └── cubit/
│       ├── help_cubit.dart             # State management
│       └── help_state.dart             # States (idle/demo/success/error)
└── domain/
    └── models/
        ├── help_section.dart           # Data model
        └── demo_result.dart            # Demo state model
```

### **Data Model:**
```dart
class HelpSection {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<String> examples;
  final bool hasInteractiveDemo;
  final DemoType? demoType;
  final bool requiresApiKey;
}

enum DemoType {
  tagParsing,      // No API needed
  aiSplit,         // Needs OpenRouter
  motivationPrompt // Needs OpenRouter
}

class HelpState {
  final bool isLoading;
  final String? errorMessage;
  final DemoResult? demoResult;
}

class DemoResult {
  final String input;
  final dynamic output; // List<String> for splits, String for motivation
  final DateTime timestamp;
}
```

---

## 🔒 BEZPEČNOST & VALIDACE

### **API Key Check:**
```dart
Future<bool> _checkApiConfiguration() async {
  final apiKey = await SecureStorage.getApiKey();
  final model = await Prefs.getSelectedModel();

  if (apiKey == null || apiKey.isEmpty) {
    _showError('⚠️ OpenRouter API key není nakonfigurován.\n'
                'Jdi do Nastavení → API → Nastav klíč');
    return false;
  }

  if (model == null) {
    _showError('⚠️ Model není vybrán.\n'
                'Jdi do Nastavení → Model → Vyber model');
    return false;
  }

  return true;
}
```

### **Rate Limiting:**
```dart
// Max 5 demo requests per minute
final RateLimiter _rateLimiter = RateLimiter(
  maxRequests: 5,
  duration: Duration(minutes: 1),
);

Future<void> _runDemo() async {
  if (!await _rateLimiter.checkLimit()) {
    _showError('⏱️ Příliš mnoho pokusů.\n'
                'Počkej chvíli a zkus znovu.');
    return;
  }
  // ... proceed with demo
}
```

### **Error Handling:**
```dart
try {
  final result = await _aiSplitService.splitTask(input);
  setState(() => _state = HelpState.success(result));
} on ApiException catch (e) {
  setState(() => _state = HelpState.error(
    'API chyba: ${e.message}\n'
    'Zkontroluj API key a model v nastavení.'
  ));
} on NetworkException catch (e) {
  setState(() => _state = HelpState.error(
    'Síťová chyba: ${e.message}\n'
    'Zkontroluj internetové připojení.'
  ));
} catch (e) {
  setState(() => _state = HelpState.error(
    'Neočekávaná chyba: $e'
  ));
}
```

---

## 🎨 UI/UX SPECIFIKACE

### **HelpCard Component:**
```dart
class HelpCard extends StatelessWidget {
  final HelpSection section;
  final VoidCallback? onTryDemo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(section.icon, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Description
            Text(section.description),

            SizedBox(height: 12),

            // Examples (collapsible)
            if (section.examples.isNotEmpty)
              ExpansionTile(
                title: Text('📖 Zobrazit příklady'),
                children: section.examples.map((e) =>
                  ListTile(title: Text(e))
                ).toList(),
              ),

            // Demo button
            if (section.hasInteractiveDemo)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('🎮 Vyzkoušet interaktivně'),
                  onPressed: onTryDemo,
                ),
              ),

            // Warning if API needed
            if (section.requiresApiKey)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Vyžaduje OpenRouter API key',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 IMPLEMENTAČNÍ FÁZE

### **Fáze 1: Základní Help Page (1-2h)**
- ✅ Vytvořit HelpPage widget
- ✅ Implementovat HelpCard component
- ✅ Přidat static content (tagy, views, sort)
- ✅ Navigation z Settings nebo FAB

**Výstup**: Statická nápověda bez interaktivních demo

---

### **Fáze 2: Tag Demo (30min)**
- ✅ TagDemoWidget s live parsing
- ✅ Real-time highlighting
- ✅ Parsed result display
- ✅ Copy-paste examples

**Výstup**: Interaktivní tag demo (bez API)

---

### **Fáze 3: AI Split Demo (1h)**
- ✅ AiSplitDemoWidget
- ✅ API key validation
- ✅ OpenRouter integration
- ✅ Result display + save option
- ✅ Error handling

**Výstup**: Funkční AI split demo

---

### **Fáze 4: Motivation Demo (1h)**
- ✅ MotivationDemoWidget
- ✅ Prompt template selection
- ✅ API call
- ✅ Response display
- ✅ Save as note option

**Výstup**: Funkční motivation prompt demo

---

### **Fáze 5: First-time Wizard (1-2h)** (Optional)
- ✅ WizardPage with stepper
- ✅ 3-5 key steps
- ✅ Skip option
- ✅ "Don't show again" preference
- ✅ Launch on first app open

**Výstup**: Guided onboarding pro nové uživatele

---

## 📊 SUCCESS METRICS

**Měřitelné cíle:**
1. **Completion rate**: 70%+ uživatelů dokončí alespoň 1 interaktivní demo
2. **Time-to-first-todo**: Zkrácení o 50% (díky wizard)
3. **Feature adoption**: 80%+ uživatelů použije tagy po prohlédnutí help
4. **Support requests**: Snížení o 60%

---

## ♿ ACCESSIBILITY

- **Screen reader**: Semantic labeling všech widgets
- **High contrast**: Respektovat system theme
- **Font scaling**: Respektovat user preferences
- **Keyboard navigation**: Full support pro desktop
- **Skip options**: Možnost přeskočit wizard/demo

---

## 🌍 LOKALIZACE

**Jazyk**: Čeština (primární)

**Klíčové termíny:**
- Tag → Štítek
- Split → Rozdělit
- Motivation → Motivace
- Demo → Ukázka/Vyzkoušet
- Priority → Priorita
- Deadline → Termín

**AI responses**: Czech (via prompt engineering)

---

## 🧪 TESTOVÁNÍ

### **Test Cases:**
1. ✅ Help page otevření z Settings
2. ✅ Tag demo funguje bez API
3. ✅ AI demo shows error pokud chybí API key
4. ✅ AI demo funguje s validním API
5. ✅ Rate limiting funguje (max 5/min)
6. ✅ Error handling (network, API errors)
7. ✅ Save demo result to real todos
8. ✅ Wizard zobrazí se při prvním spuštění
9. ✅ "Don't show again" persistuje
10. ✅ Accessibility support (TalkBack)

---

## 📝 OPEN QUESTIONS

1. **Wizard**: Mandatory nebo optional?
   → **Doporučuji**: Optional s "Skip" button

2. **Demo data**: Fake data nebo real API calls?
   → **Doporučuji**: Real API (user experience)

3. **Demo limits**: Free demos vs. count towards quota?
   → **Doporučuji**: Count (transparentní)

4. **Video tutorials**: Embedded nebo external links?
   → **Fáze 2**: External links (YouTube)

5. **Search**: Searchable help content?
   → **Nice-to-have**: Lze přidat později

---

## 🎯 PRIORITIZACE

### **MVP (Must-have):**
- ✅ Help page (card layout)
- ✅ Tag demo (no API)
- ✅ Static content (views, sort, search)
- ✅ Navigation (FAB nebo Settings)

### **V1 (Should-have):**
- ✅ AI split demo
- ✅ Motivation demo
- ✅ API validation & error handling

### **V2 (Nice-to-have):**
- ✅ First-time wizard
- ✅ Video tutorials
- ✅ Searchable content
- ✅ Analytics tracking

---

## 📚 REFERENCE

**Inspirace:**
- Google Keep: Simple help cards
- Notion: Interactive onboarding
- Todoist: Contextual help tooltips
- Obsidian: Searchable docs

**Best Practices:**
- Progressive disclosure
- Learn-by-doing (interactive demos)
- Clear error messages
- Escape hatches (skip, close)
- Contextual help (in-app, not external)

---

## 🔗 RELATED DOCS

- `rodel.md` - AI Split feature (pro AI demo)
- `gui.md` - UI/UX design patterns
- `agenda.md` - Views a filtering (pro static help)
- `bloc.md` - BLoC architecture (pro HelpCubit)

---

## 📅 TIMELINE

**Odhadovaný čas**: 3-4 hodiny celkem

- Fáze 1: 1-2h
- Fáze 2: 30min
- Fáze 3: 1h
- Fáze 4: 1h
- Fáze 5: 1-2h (optional)

**Start date**: TBD
**Target completion**: TBD

---

**Status**: 📋 Design Complete
**Next step**: Update CLAUDE.md s implementačními instrukcemi
**Verze**: 1.0
**Autor**: Claude Code (AI asistent)
**Datum**: 2025-01-10
