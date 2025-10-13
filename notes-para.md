# Notes + PARA System - Komplexní Analýza a Design

**Datum**: 2025-10-13
**Účel**: Technické zhodnocení Notes feature s PARA metodou a AI asistencí
**Status**: Phase 1 - Milestones Implementation

---

## 📋 TODO - Milestones pro Postupnou Implementaci

**⚠️ CRITICAL: Po každém milestonu VŽDY aktualizuj tento seznam!**

### ✅ MILESTONE 0: Příprava (DOKONČENO)
- [x] Snapshot commit před začátkem
- [x] Vytvoření notes-para.md s kompletní analýzou
- [x] Aktualizace CLAUDE.md s informací o nové feature

### ✅ MILESTONE 1: Databáze + Základní Entity (2-3h) - **DOKONČENO**
**Cíl**: SQLite tabulka + Note entity + základní CRUD operace

**Kroky:**
1. [x] Vytvořit databázovou tabulku `notes`
   - SQL schema: `id`, `content`, `created_at`, `updated_at`
   - DB upgrade na verzi 18
   - Indexy na created_at a updated_at pro rychlé sortování

2. [x] Vytvořit Note entity
   - `lib/models/note.dart`
   - Immutable pattern (final fields)
   - `copyWith()`, `toMap()`, `fromMap()`
   - `toString()`, `==`, `hashCode`

3. [x] Implementovat CRUD operace v DatabaseHelper
   - `insertNote()`, `getAllNotes()`, `getNoteById()`
   - `updateNote()`, `deleteNote()`
   - `getNotesCount()`, `getRecentNotes()`

4. [ ] ~~Vytvořit NotesRepository interface~~ (přeskočeno pro MVP - přímý přístup k DB)

5. [ ] ~~Implementovat NotesDbDatasource~~ (přeskočeno - DatabaseHelper stačí)

6. [ ] ~~Implementovat NotesRepositoryImpl~~ (přeskočeno - DatabaseHelper stačí)

7. [ ] ~~Unit testy~~ (přeskočeno pro rychlý progres)

8. [x] Commit po dokončení - `dc5b89a`

**Deliverable**: ✅ Funkční databáze s CRUD operacemi pro poznámky.

**Co bylo implementováno:**
- SQL tabulka `notes` v DatabaseHelper
- Note entity model v `lib/models/note.dart`
- 7 CRUD metod v DatabaseHelper
- DB upgrade na verzi 18

**Zjednodušení:**
- Přeskočena repository vrstva (použit přímý přístup k DatabaseHelper)
- Unit testy odloženy na později
- Feature-first struktura odložena - MVP používá `lib/models/`

---

### 🔜 MILESTONE 2: GUI - Input Bar + Seznam Poznámek (3-4h)
**Cíl**: Plnohodnotný input bar (jako v TODO) + seznam poznámek + základní "All Notes" folder

**Kroky:**
1. [ ] Vytvořit NotesBloc (state management)
   ```
   lib/features/notes/presentation/bloc/
   - notes_bloc.dart
   - notes_event.dart (CreateNote, UpdateNote, DeleteNote, LoadNotes)
   - notes_state.dart (NotesLoaded, NotesLoading, NotesError)
   ```

2. [ ] Vytvořit NotesListPage
   ```
   lib/features/notes/presentation/pages/notes_list_page.dart

   Layout:
   ┌─────────────────────────────────────┐
   │ AppBar: "Notes"                     │
   ├─────────────────────────────────────┤
   │                                     │
   │ [FOLDERS TAB BAR]                   │ ← "All Notes" (zatím pouze jeden)
   │                                     │
   │ ListView:                           │
   │  ┌───────────────────────────────┐  │
   │  │ Note 1 Title (auto-gen)       │  │
   │  │ First line preview...         │  │
   │  │ 2025-10-13 20:15              │  │
   │  └───────────────────────────────┘  │
   │  ┌───────────────────────────────┐  │
   │  │ Note 2 Title                  │  │
   │  │ ...                           │  │
   │  └───────────────────────────────┘  │
   │                                     │
   ├─────────────────────────────────────┤
   │ BOTTOM INPUT BAR (ipnuté dole):     │
   │ ┌────────────┬────────┬──────────┐ │
   │ │ [🔍]       │ [Text] │ [✖️ Save]│ │ ← 🔍 placeholder, ✖️ uloží
   │ └────────────┴────────┴──────────┘ │
   └─────────────────────────────────────┘

   Po kliknutí do textového pole:
   - Klávesnice se vysune
   - Input bar se přesune NAD klávesnici (stejně jako v TODO!)
   - TextField se dynamicky zvětšuje směrem NAHORU při psaní
   ```

3. [ ] Vytvořit NoteInputBar widget (reusable)
   ```
   lib/features/notes/presentation/widgets/note_input_bar.dart

   Komponenty:
   - TextField (multiline, expands vertically)
   - Search icon (vlevo) - zatím placeholder, nefunkční
   - Save button (vpravo) - křížek → uloží poznámku

   Chování:
   - Focus → klávesnice se vysune, bar nad ní
   - Text roste → TextField expanduje nahoru (max 5 řádků)
   - Kliknutí ✖️ → CreateNoteEvent, TextField se vyprázdní
   ```

4. [ ] Vytvořit NoteCard widget
   ```
   lib/features/notes/presentation/widgets/note_card.dart

   Zobrazuje:
   - displayTitle (auto-gen z prvního řádku)
   - Preview prvních 2 řádků obsahu
   - Timestamp (created_at)

   Akce:
   - Tap → otevře note editor (Milestone 3)
   - Long press → delete (s confirmací)
   ```

5. [ ] Implementovat Folders Tab Bar (zatím jen "All Notes")
   ```
   Horizontal scrollable tabs jako v TODO Agenda:
   [All Notes] ← Zatím pouze jeden tab

   Později přidáme: [Recent] [Favorites] [Projects] [Areas] ...
   ```

6. [ ] Registrovat NotesPage v routing
   ```
   lib/routes.dart nebo main.dart
   - Přidat Notes tab do bottom navigation (3. tab)
   - TODO | Pomodoro | Notes | Settings
   ```

7. [ ] Widget testy pro NoteInputBar
   - Expanze při psaní textu
   - Save button funkčnost

8. [ ] Commit po dokončení

**Deliverable**: Plně funkční Notes list page s input barem jako v TODO + jeden základní "All Notes" folder.

---

### 🔜 MILESTONE 3: Note Editor + Základní Tagy (2-3h)
**Cíl**: Otevření poznámky na celou obrazovku + editace + naseptávání tagů

**Kroky:**
1. [ ] Vytvořit NoteEditorPage
   ```
   lib/features/notes/presentation/pages/note_editor_page.dart

   Layout:
   ┌─────────────────────────────────────┐
   │ AppBar: [← Back] [Save] [Delete]    │
   ├─────────────────────────────────────┤
   │                                     │
   │ TextField (full screen):            │
   │                                     │
   │ Text content s tagy *tag*...        │
   │                                     │
   │                                     │
   └─────────────────────────────────────┘
   ```

2. [ ] Integrovat TagAutocompleteField (reuse z TODO!)
   ```
   lib/core/widgets/tag_autocomplete_field.dart

   Detekce *tag* patternů při psaní
   Naseptávání existujících tagů
   ```

3. [ ] Implementovat NotesTagParser
   ```
   lib/features/notes/domain/services/notes_tag_parser.dart

   Parse patterns:
   - *tag* → běžný tag
   - *123* → link na TODO (zatím jen parse, linking později)
   - *[[Note]]* → link na jinou poznámku (parsing, linking Phase 2)
   ```

4. [ ] Přidat note_tags tabulku do DB
   ```sql
   CREATE TABLE note_tags (
     note_id TEXT NOT NULL,
     tag TEXT NOT NULL,
     created_at INTEGER NOT NULL,
     PRIMARY KEY (note_id, tag)
   );
   ```

5. [ ] Rozšířit Note entity o tags
   ```dart
   class Note {
     ...
     final List<String> tags; // Parsované z contentu
   }
   ```

6. [ ] Update NotesRepository
   - getAllUniqueTags() pro autocomplete
   - getNotesByTag(String tag)

7. [ ] Commit po dokončení

**Deliverable**: Plně funkční editor s naseptáváním tagů (jako v TODO).

---

### 🔜 MILESTONE 4: Folders - Recent + Favorites (2h)
**Cíl**: Přidat "Recent" a "Favorites" filtry do Folders tabu

**Kroky:**
1. [ ] Přidat `is_favorite` column do `notes` tabulky

2. [ ] Rozšířit Note entity
   ```dart
   final bool isFavorite;
   ```

3. [ ] Implementovat filtry v NotesBloc
   - NotesViewMode enum (all, recent, favorites)
   - ChangeViewModeEvent
   - Filter logika v state

4. [ ] Přidat Favorite toggle do NoteCard
   - Star icon (prázdná/plná hvězdička)
   - Tap → toggle favorite status

5. [ ] Rozšířit Folders Tab Bar
   ```
   [All Notes] [Recent] [Favorites]
   ```

6. [ ] Implementovat Recent filter (posledních 7 dní)

7. [ ] Commit po dokončení

**Deliverable**: 3 funkční folders: All Notes, Recent (7 dní), Favorites.

---

### 🔜 MILESTONE 5: Fulltext Search (2-3h)
**Cíl**: Funkční 🔍 v input baru - hledat poznámky podle obsahu

**Kroky:**
1. [ ] Přidat FTS5 virtual table do DB
   ```sql
   CREATE VIRTUAL TABLE notes_fts USING fts5(...);
   -- + triggers pro auto-update
   ```

2. [ ] Implementovat searchNotes() v repository
   - FTS5 query
   - Return NoteSearchResult s snippet

3. [ ] Vytvořit SearchNotesEvent v NotesBloc

4. [ ] Aktivovat 🔍 icon v NoteInputBar
   - Kliknutí → změní se na search mode
   - TextField placeholder: "Hledat poznámky..."
   - Live search při psaní

5. [ ] Zobrazit search results v NotesListPage
   - Highlight matched text (snippet)

6. [ ] Commit po dokončení

**Deliverable**: Funkční fulltext search přes všechny poznámky.

---

### 🔜 MILESTONE 6: PARA Folders - Základy (4-5h)
**Cíl**: Přidat PARA organizaci - Projects, Areas, Resources, Archives

**⚠️ TODO: Detailní breakdown bude přidán po dokončení Milestone 5**

---

### 🔜 MILESTONE 7: AI Helper - PARA Klasifikace (5-6h)
**Cíl**: AI navrhuje PARA folder + tagy pro poznámku

**⚠️ TODO: Detailní breakdown bude přidán po dokončení Milestone 6**

---

### 🔜 MILESTONE 8: Backlinks + Note Linking (3-4h)
**Cíl**: *[[Note]]* linky + backlinks panel

**⚠️ TODO: Detailní breakdown bude přidán po dokončení Milestone 7**

---

### 🔜 MILESTONE 9: Unified Input Bar - TODO/Notes Auto-Detection (3-4h)
**Cíl**: Jeden inteligentní input bar pro TODO i Notes - automatická detekce typu

#### 💡 Koncept:

**User píše text** → Systém detekuje TODO systémové tagy → Rozhodne:
```
"Koupit mléko *dnes* *a*"        → TODO (má *dnes*, *a*)
"Nápad na novou feature"          → Note (žádné TODO tagy)
"Meeting s klientem *práce*"     → Note (pouze běžný tag)
```

**TODO systémové tagy:**
- Priorita: `*a*`, `*b*`, `*c*`
- Datum: `*dnes*`, `*zítra*`, `*datum[...]*`
- TODO link: `*#123*`

**Všechno ostatní** = Note

#### 🎨 GUI:

**Indikátor před uložením:**
```
┌─────────────────────────────────────┐
│ [TextField________________]         │
│ "Koupit mléko *dnes* *a*"           │
│                                     │
│ 💾 Uložit jako: [TODO ▼] [✖️]      │ ← Dropdown s override
└─────────────────────────────────────┘

Options v dropdownu:
- Auto (doporučeno) ← Default
- TODO
- Note
```

**Auto mode logic:**
```dart
InputType detectInputType(String text) {
  final hasTodoTag = _hasTodoSystemTag(text);
  return hasTodoTag ? InputType.todo : InputType.note;
}

bool _hasTodoSystemTag(String text) {
  // Priority tags
  if (RegExp(r'\*[abc]\*').hasMatch(text)) return true;

  // Date tags
  if (RegExp(r'\*(dnes|zítra|datum\[.*?\])\*').hasMatch(text)) return true;

  // TODO link
  if (RegExp(r'\*#\d+\*').hasMatch(text)) return true;

  return false;
}
```

#### 📋 Kroky:

1. [ ] Vytvořit InputTypeDetector service
   ```dart
   lib/core/services/input_type_detector.dart

   class InputTypeDetector {
     InputType detect(String text);
     bool hasTodoSystemTag(String text);
   }

   enum InputType { todo, note, auto }
   ```

2. [ ] Vytvořit UnifiedInputBar widget
   ```dart
   lib/core/widgets/unified_input_bar.dart

   Nahrazuje:
   - TodoInputBar (z TODO feature)
   - NoteInputBar (z Notes feature)

   Features:
   - TextField (multiline, expands)
   - Type dropdown (Auto / TODO / Note)
   - Save button (✖️)
   - Live detection indicator
   ```

3. [ ] Implementovat dropdown selection logic
   ```dart
   State:
   - InputMode _mode = InputMode.auto; // User override
   - InputType _detectedType = InputType.note; // Auto-detected

   Computed:
   - InputType get effectiveType =>
       _mode == InputMode.auto ? _detectedType : _mode.toInputType();
   ```

4. [ ] Integrovat do TodoListPage a NotesListPage
   ```dart
   // Společný input bar na obou stránkách

   UnifiedInputBar(
     onSave: (text, type) {
       if (type == InputType.todo) {
         _todoBloc.add(CreateTodoEvent(text));
       } else {
         _notesBloc.add(CreateNoteEvent(text));
       }
     },
   )
   ```

5. [ ] Feature flag v Settings
   ```dart
   lib/features/settings/domain/entities/app_settings.dart

   class AppSettings {
     ...
     final bool useUnifiedInputBar; // Default: false (zatím beta)
   }

   Settings UI:
   ☐ Inteligentní input bar (beta)
      "Automaticky rozpozná TODO vs Note podle tagů"
   ```

6. [ ] A/B testing setup
   - Metric: % users who prefer unified vs separated
   - Track: Manual override rate (kolikrát user mění Auto → TODO/Note)
   - Decision point: Pokud override rate < 20% → make it default

7. [ ] Unit testy
   ```dart
   test('detects TODO with priority tag', () {
     expect(detector.detect('Koupit mléko *a*'), InputType.todo);
   });

   test('detects Note without system tags', () {
     expect(detector.detect('Nápad na feature'), InputType.note);
   });

   test('detects Note with custom tag only', () {
     expect(detector.detect('Meeting *práce*'), InputType.note);
   });
   ```

8. [ ] Widget testy
   ```dart
   testWidgets('dropdown allows manual override', (tester) async {
     // Auto detects Note
     // User changes to TODO manually
     // Verify saves as TODO
   });
   ```

9. [ ] Commit po dokončení

#### ⚙️ Settings Integration:

**Nová sekce v Settings:**
```
Settings → Input & Productivity

☐ Inteligentní input bar (beta)
   "Jeden input bar pro TODO i poznámky.
    Automaticky rozpozná typ podle tagů."

   Default: OFF (fallback na oddělené input bary)
```

**Podmíněné renderování:**
```dart
// V TodoListPage / NotesListPage:

Widget _buildInputBar() {
  final useUnified = context.watch<SettingsBloc>().state.useUnifiedInputBar;

  if (useUnified) {
    return UnifiedInputBar(
      onSave: _handleUnifiedSave,
    );
  } else {
    // Separate input bars (original behavior)
    return _isOnTodoTab
      ? TodoInputBar(onSave: _handleTodoSave)
      : NoteInputBar(onSave: _handleNoteSave);
  }
}
```

#### 🎯 UX Benefits:

**Pros:**
- ✅ Friction-less capture (žádné přepínání TODO/Notes tab)
- ✅ Konzistentní UX (jeden input bar všude)
- ✅ Inteligentní (user nemusí rozhodovat)
- ✅ Flexibilní (manual override pokud AI se splete)

**Cons:**
- ❌ Složitější implementace
- ❌ Může zmást uživatele (proč to někdy jde do TODO, někdy do Notes?)
- ❌ Edge cases (co když user chce Note, ale napsal "dnes" jako běžné slovo?)

#### 📊 Success Metrics:

**Beta testing (3 měsíce):**
- [ ] 50+ active users testing
- [ ] Override rate < 20% (AI accuracy > 80%)
- [ ] User satisfaction > 4.0/5
- [ ] Bug reports < 5

**Decision:**
- ✅ Success → make default in Milestone 10
- ❌ Failure → keep as opt-in feature

**Deliverable**: Beta feature - unified input bar s inteligentní detekcí TODO vs Note.

**Priority**: ⭐⭐ Medium (UX improvement, not critical)

**Effort**: 3-4h implementation + 1-2h testing

---

## 🎯 GUI Specifikace - Detailní Design

### 1. Input Bar Design (stejný jako TODO)

**Pozicování:**
```
Výchozí stav (bez focusu):
┌─────────────────────────────────────┐
│ AppBar                              │
├─────────────────────────────────────┤
│                                     │
│ Seznam poznámek                     │
│ (scrollable)                        │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ [🔍] [TextField______] [✖️ Save]    │ ← IPNUTÉ DOLE
└─────────────────────────────────────┘

Po kliknutí do TextField:
┌─────────────────────────────────────┐
│ AppBar                              │
├─────────────────────────────────────┤
│                                     │
│ Seznam poznámek                     │
│ (částečně zakrytý)                  │
│                                     │
├─────────────────────────────────────┤
│ [🔍] [TextField______] [✖️]         │ ← NAD KLÁVESNICÍ
│      ↑ roste nahoru                 │
│      při přidávání textu            │
├─────────────────────────────────────┤
│ 🎹 KLÁVESNICE                       │
└─────────────────────────────────────┘
```

**Dynamické Chování TextField:**
- Začíná s výškou 1 řádku (50dp)
- S každým novým řádkem roste směrem NAHORU (max 5 řádků = 250dp)
- Po 5 řádcích → scroll uvnitř TextField, ne dál expand
- Kliknutí ✖️ → uloží poznámku, TextField se vyprázdní

**Implementace:**
```dart
TextField(
  controller: _textController,
  focusNode: _focusNode,
  maxLines: null, // Multiline
  minLines: 1,
  maxLines: 5,    // Max expand
  textInputAction: TextInputAction.newline,
  decoration: InputDecoration(
    hintText: 'Nová poznámka...',
    border: InputBorder.none,
  ),
)
```

---

### 2. Folders Tab Bar (jako Agenda v TODO)

**Layout:**
```
┌──────────────────────────────────────┐
│ Horizontally scrollable tabs:        │
│                                      │
│ [All Notes] [Recent] [Favorites]     │ ← Milestone 4
│                                      │
│ Později:                             │
│ [All] [Recent] [Fav] [Projects] ... │
└──────────────────────────────────────┘
```

**Vizuální Design:**
- Stejný styl jako Agenda tabs v TODO
- Active tab = barevný (accent color)
- Inactive = šedá
- Icons + text (volitelné)

---

### 3. NoteCard Design

**Layout jedné karty:**
```
┌────────────────────────────────────┐
│ Meeting s klientem           [⭐]  │ ← Title + favorite icon
│ Diskutovali jsme o Q4 roadmap...  │ ← Preview (2 řádky)
│ 2025-10-13 20:15  •  *práce*      │ ← Timestamp + první tag
└────────────────────────────────────┘
```

**Akce:**
- Tap → otevře NoteEditorPage
- Long press → zobrazí dialog (Delete / Share / ...)
- Swipe → delete s undo (optional, Milestone 9+)

---

### 4. Responsive Behavior

**Klávesnice Show/Hide:**
```dart
// V NotesListPage state:

@override
void initState() {
  super.initState();
  _keyboardListener = KeyboardVisibilityController().onChange.listen((visible) {
    setState(() {
      _isKeyboardVisible = visible;
    });
  });
}

// Layout:
Column(
  children: [
    Expanded(child: ListView(...)), // Seznam poznámek
    NoteInputBar(
      onSave: _handleSaveNote,
      isKeyboardVisible: _isKeyboardVisible,
    ),
  ],
)
```

**Input Bar Position:**
```dart
// V NoteInputBar widget:
Positioned(
  bottom: isKeyboardVisible
    ? MediaQuery.of(context).viewInsets.bottom  // NAD klávesnicí
    : 0,                                        // Dole na obrazovce
  left: 0,
  right: 0,
  child: _buildInputBarContent(),
)
```

---

## 🧠 Executive Summary

**Klíčový insight**: Máme unikátní příležitost vytvořit "Second Brain" systém, který kombinuje:
1. ✅ **Existující TODO systém** (tagy, agenda views, AI Brief)
2. 🆕 **Notes s PARA organizací** (Apple Notes + Obsidian inspirace)
3. 🤖 **AI-asistovaná klasifikace** (OpenRouter API)
4. 🔗 **Bidirectional linking** mezi poznámkami a úkoly

**Výsledek**: Holistický produktivní systém, ne jen "další notes app".

---

## 📊 Porovnání Existujících Systémů

### Apple Notes (2025)
**Co dělají dobře:**
- Jednoduché `#tagy` (hashtag syntax)
- Smart Folders = dynamické filtry (tagy, datum, checklist, mentions)
- Smart Folders jsou "views" - neobsahují data, jen reference
- Tags browser - automatický seznam všech tagů
- Konverze složky → Smart Folder (tagy + přesun do Notes folder)

**Limity:**
- Není PARA organizace
- Žádné backlinky (jednosměrné linky)
- AI pouze v iOS 18+ (Apple Intelligence)

### Obsidian
**Co dělají dobře:**
- **Wiki-style linky**: `[[Note Name]]` - bidirectional!
- **Backlinks**: Automatická detekce "kdo linkuje na tuto poznámku"
- **Graph View**: Vizualizace knowledge graph
- Markdown-first (lokální soubory)
- Plugins ekosystém

**Limity:**
- Komplexní pro běžného uživatele
- Není TODO systém
- Není mobilní-first

### PARA metoda (Tiago Forte)
**Struktura:**
```
📁 Projects (projekty s deadline)
   └─ S termínem, aktivní práce
📁 Areas (oblasti odpovědnosti)
   └─ Životní oblasti bez termínu (zdraví, finance...)
📁 Resources (zdroje)
   └─ Reference materiály, nápady pro budoucnost
📁 Archives (archiv)
   └─ Dokončené projekty, neaktivní oblasti
```

**Klíčový princip**: Organizace podle **actionability**, ne podle tématu!

**Příklad:**
- ❌ Špatně: Složka "Marketing" obsahuje aktivní kampaň i staré nápady
- ✅ Správně: Aktivní kampaň → Projects, nápady → Resources, stará kampaň → Archives

---

## 🎯 Naše Implementace - Analýza Požadavků

### 1. Tagy - Adaptace na Náš Systém

**Existující systém:**
- Custom oddělovače (default `*tag*`)
- Naseptávání funguje výborně
- TODO systém: `*a*` (priorita), `*dnes*` (datum), `*#123*` (link na úkol)

**Pro Notes:**
```
*tag*           → Běžný tag (stejné jako TODO)
*#123*          → Link na TODO úkol
*[[Note Name]]* → Link na jinou poznámku (Obsidian-style)
*@osoba*        → Mention (pro budoucnost)
```

**Implementace:**
```dart
// services/notes_tag_parser.dart
class NotesTagParser {
  // Regex patterns
  static final RegExp _tagPattern = RegExp(r'\*(\w+)\*');
  static final RegExp _todoLinkPattern = RegExp(r'\*#(\d+)\*');
  static final RegExp _noteLinkPattern = RegExp(r'\*\[\[([^\]]+)\]\]\*');
  static final RegExp _mentionPattern = RegExp(r'\*@(\w+)\*');

  ParsedNoteTags parse(String content) {
    return ParsedNoteTags(
      tags: _extractTags(content),
      todoLinks: _extractTodoLinks(content),
      noteLinks: _extractNoteLinks(content),
      mentions: _extractMentions(content),
    );
  }
}
```

**Benefit**: Konzistentní UX napříč TODO a Notes!

---

### 2. Smart Folders vs Agenda Views

**Zjištění**: Smart Folders v Apple Notes = naše Agenda Views!

**Současný stav Agenda Views:**
```dart
enum ViewMode {
  all,
  today,
  week,
  overdue,
  aiBrief,
  custom // CustomView s filtry!
}
```

**Pro Notes:**
```dart
enum NotesViewMode {
  all,
  recent,         // Za posledních 7 dní
  favorites,      // Oblíbené (nový flag)
  paraProjects,   // PARA: Projects
  paraAreas,      // PARA: Areas
  paraResources,  // PARA: Resources
  paraArchives,   // PARA: Archives
  custom,         // CustomView s filtry
}
```

**CustomView rozšíření:**
```dart
class CustomView {
  final String id;
  final String name;
  final String? icon;
  final List<FilterRule> rules;
  final ViewType type; // NEW: 'todo' | 'notes' | 'both'

  // Existing filters pro TODO:
  // - tags, priority, dueDate, completed...

  // NEW filters pro Notes:
  // - noteCreatedAt, noteUpdatedAt
  // - hasAttachment (checklist, image, audio)
  // - paraFolder (projects, areas, resources, archives)
  // - linkedToTodo (bool)
  // - wordCount (min/max)
}
```

**Výhoda**: Jeden unified systém pro TODO i Notes filtry!

---

### 3. PARA Organizace - Hlubší Analýza

**Problém**: Jak automaticky klasifikovat poznámku do PARA?

**AI Model Input (OpenRouter API):**
```json
{
  "model": "anthropic/claude-3.5-sonnet",
  "messages": [
    {
      "role": "system",
      "content": "Jsi expert na PARA organizaci podle Tiago Forte. Klasifikuj poznámku do PARA struktury..."
    },
    {
      "role": "user",
      "content": {
        "noteTitle": "Nápad na novou feature",
        "noteContent": "Vytvořit dashboard pro reporting...",
        "existingTags": ["práce", "nápad"],
        "userContext": {
          "job": "Product Manager v SaaS startupu",
          "currentProjects": ["Q4 Roadmap", "User Research"],
          "responsibilities": ["Product Strategy", "Team Management"]
        },
        "existingPARA": {
          "projects": ["Q4 Roadmap", "User Research"],
          "areas": ["Product Strategy", "Team Management", "Health"],
          "resources": ["Design Inspiration", "Market Research"]
        }
      }
    }
  ]
}
```

**AI Model Output:**
```json
{
  "paraClassification": {
    "mainFolder": "resources",
    "subFolder": "product_ideas",
    "reasoning": "Jedná se o nápad, ne aktivní projekt. Patří do Resources pro budoucí referenci.",
    "confidence": 0.85
  },
  "suggestedTags": ["*product*", "*feature-ideas*", "*dashboard*"],
  "suggestedActions": [
    "Převést na Project, pokud dostane deadline",
    "Propojit s existující Area 'Product Strategy'"
  ]
}
```

**PARA Hierarchie (max 3 úrovně):**
```
Projects/
├─ Q4_Roadmap/
│  ├─ Feature_Specs/
│  │  └─ note1.md
│  └─ Design_Mockups/
│     └─ note2.md
└─ User_Research/
   └─ Interview_Notes/
      └─ note3.md

Areas/
├─ Product_Strategy/
│  └─ Strategy_Documents/
└─ Health/
   ├─ Workout_Plans/
   └─ Nutrition/

Resources/
├─ Product_Ideas/     ← Náš nápad jde sem!
├─ Design_Inspiration/
└─ Market_Research/

Archives/
└─ 2024_Q3/
   └─ Completed_Projects/
```

**Implementace:**
```dart
// domain/entities/para_folder.dart
class ParaFolder {
  final String id;
  final ParaType type; // projects, areas, resources, archives
  final String name;
  final String? parentId; // Null = root level
  final int level; // 0, 1, 2 (max 3 úrovně)
  final DateTime createdAt;
}

enum ParaType {
  projects,   // Aktivní projekty s deadline
  areas,      // Oblasti odpovědnosti
  resources,  // Referenční materiály
  archives,   // Dokončené/neaktivní
}
```

---

### 4. AI Helper - Detailní Specifikace

**UI/UX:**
```
┌─────────────────────────────────────┐
│ Note Title: "Nápad na dashboard"    │
├─────────────────────────────────────┤
│ Content:                            │
│ Vytvořit dashboard pro reporting... │
│                                     │
│ [✨ AI Helper]  ← Floating button   │
└─────────────────────────────────────┘
```

**Po kliknutí na AI Helper:**
```
┌─────────────────────────────────────┐
│ 🤖 AI Asistent                      │
├─────────────────────────────────────┤
│ 📂 PARA Klasifikace:                │
│   └─ Resources → Product Ideas      │
│   Confidence: 85%                   │
│                                     │
│ 🏷️ Navrhované tagy:                 │
│   *product* *feature-ideas* *dash*  │
│   [Použít vše] [Vybrat]             │
│                                     │
│ 🔗 Souvisí s:                        │
│   • Area: Product Strategy          │
│   • TODO: #245 (Q4 Roadmap)         │
│   [Propojit]                        │
│                                     │
│ 💡 Doporučení:                       │
│   "Převeď na Project, až dostane    │
│    deadline a přiřaď k Q4 Roadmap"  │
└─────────────────────────────────────┘
```

**Backend Flow:**
```dart
// features/notes/domain/services/ai_helper_service.dart
class AiHelperService {
  final OpenRouterClient _client;
  final NotesRepository _notesRepo;
  final TodoRepository _todoRepo;
  final ParaFolderRepository _paraRepo;
  final SettingsRepository _settingsRepo;

  Future<AiHelperSuggestions> analyzNote(Note note) async {
    // 1. Načíst user context z Settings
    final userContext = await _settingsRepo.getUserContext();

    // 2. Načíst existující PARA strukturu
    final paraStructure = await _paraRepo.getFullStructure();

    // 3. Načíst všechny existující tagy
    final allTags = await _notesRepo.getAllUniqueTags();

    // 4. Volat OpenRouter API
    final aiResponse = await _client.chat(
      model: 'anthropic/claude-3.5-sonnet',
      systemPrompt: _buildSystemPrompt(),
      userContext: _buildUserContext(
        note: note,
        userContext: userContext,
        paraStructure: paraStructure,
        allTags: allTags,
      ),
    );

    // 5. Parsovat response
    return AiHelperSuggestions.fromJson(aiResponse);
  }
}
```

**Cost Estimation:**
- Model: Claude 3.5 Sonnet
- Input: ~2000 tokens (note + context)
- Output: ~500 tokens (suggestions)
- Cost: ~$0.015 per analysis
- → Za 100 použití = $1.50 (levné!)

---

### 5. Markdown Formátování

**Současný stav:**
Poznámky jsou plain text s tagy.

**Cílový stav:**
```markdown
# Nápad na Dashboard

## Kontext
Potřebujeme *reporting dashboard* pro tracking KPIs.

## Features
- [ ] Real-time data
- [ ] Export do PDF
- [x] Základní grafy

## Související
- *[[Market Research 2024]]* (jiná poznámka)
- *#245* (TODO úkol: Q4 Roadmap)
- *product* *dashboard* (tagy)

---
Created: 2025-10-13 19:30
```

**AI Formátování:**
```
┌─────────────────────────────────────┐
│ Raw text:                           │
│ Nápad na dashboard Potrebujeme      │
│ reporting pro KPIs Features real    │
│ time data export pdf grafy          │
│                                     │
│ [✨ Format with AI]                 │
└─────────────────────────────────────┘
```

**AI převede na:**
```markdown
# Nápad na Dashboard

## Kontext
Potřebujeme reporting dashboard pro tracking KPIs.

## Plánované Features
- Real-time data
- Export do PDF
- Grafy

---
*Formátováno AI • 2025-10-13*
```

**Implementace:**
```dart
// features/notes/domain/services/markdown_formatter_service.dart
class MarkdownFormatterService {
  final OpenRouterClient _client;

  Future<String> formatToMarkdown(String rawText) async {
    final response = await _client.chat(
      model: 'anthropic/claude-3.5-sonnet',
      systemPrompt: '''
      Jsi expert na Markdown formátování.
      Převeď raw text na strukturovaný Markdown:
      - Detekuj nadpisy a použij #, ##, ###
      - Najdi seznamy a použij -, [ ]
      - Identifikuj důležité výrazy a použij **bold** nebo *italic*
      - Přidej --- pro oddělení sekcí
      - ZACHOVEJ všechny tagy ve formátu *tag*!
      ''',
      userMessage: rawText,
    );

    return response.content;
  }
}
```

---

### 6. Propojení s TODO Úkoly

**Existující systém:**
- TODO má tagy: `*projekt-x*`, `*a*`, `*dnes*`
- Notes bude mít stejné tagy

**Nové vazby:**

**Z Notes → TODO:**
```markdown
# Meeting Notes

## Action Items
- *#123* Připravit prezentaci (link na TODO)
- *#124* Zavolat klientovi (link na TODO)

*projekt-x* *meeting* (sdílené tagy)
```

**Z TODO → Notes:**
```
[Card TodoCard]
  Title: Připravit prezentaci
  Tags: *projekt-x* *a*

  [📝 Related Notes: 2]  ← Badge s počtem
     └─ "Meeting Notes 2025-10-13"
     └─ "Prezentace - Draft"
```

**Implementace - Backlinks:**
```dart
// domain/services/backlink_service.dart
class BacklinkService {
  final NotesRepository _notesRepo;
  final TodoRepository _todoRepo;

  // Najít všechny poznámky linkující na TODO
  Future<List<Note>> getNotesLinkingToTodo(int todoId) async {
    final allNotes = await _notesRepo.getAllNotes();
    return allNotes.where((note) {
      return note.content.contains('*#$todoId*');
    }).toList();
  }

  // Najít všechny poznámky linkující na jinou poznámku
  Future<List<Note>> getNotesLinkingToNote(String noteId) async {
    final allNotes = await _notesRepo.getAllNotes();
    final targetNote = await _notesRepo.getNoteById(noteId);

    return allNotes.where((note) {
      return note.content.contains('*[[${targetNote.title}]]*');
    }).toList();
  }

  // Najít všechny TODO úkoly sdílející tag s poznámkou
  Future<List<Todo>> getTodosBySharedTags(Note note) async {
    final noteTags = NotesTagParser().parse(note.content).tags;
    final allTodos = await _todoRepo.getAllTodos();

    return allTodos.where((todo) {
      final todoTags = TagParser.parse(todo.task).tags;
      return noteTags.any((tag) => todoTags.contains(tag));
    }).toList();
  }
}
```

**UI - Backlinks Panel:**
```
┌─────────────────────────────────────┐
│ 📝 Meeting Notes                    │
├─────────────────────────────────────┤
│ Content...                          │
│                                     │
│ ─────────────────────────────────   │
│ 🔗 Linked Items (5)                 │
│                                     │
│ ✅ TODOs (2)                         │
│   • #123 Připravit prezentaci       │
│   • #124 Zavolat klientovi          │
│                                     │
│ 📝 Notes (1)                         │
│   • "Prezentace - Draft"            │
│                                     │
│ 🏷️ Shared Tags (2)                  │
│   • *projekt-x* (3 TODOs, 2 Notes)  │
│   • *meeting* (1 TODO, 4 Notes)     │
└─────────────────────────────────────┘
```

---

### 7. Graph View (Volitelné - Phase 2)

**Inspirace Obsidian:**
```
     [Note A]
       /  \
      /    \
  [TODO]  [Note B]
     |      /
     |     /
  [Note C]
```

**Implementace:**
```dart
// features/notes/presentation/pages/graph_view_page.dart
class GraphViewPage extends StatelessWidget {
  // Použít package 'fl_graph' nebo 'graphview'

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotesBloc, NotesState>(
      builder: (context, state) {
        final nodes = _buildNodes(state.notes, state.todos);
        final edges = _buildEdges(state.notes, state.todos);

        return InteractiveViewer(
          child: GraphView(
            graph: Graph()
              ..nodes = nodes
              ..edges = edges,
            algorithm: FruchtermanReingoldAlgorithm(),
          ),
        );
      },
    );
  }
}
```

---

### 8. User Context Settings - Detailní Specifikace

**Účel**: AI potřebuje znát uživatele, aby mohlo správně klasifikovat poznámky do PARA.

**Nová záložka v Settings:**
```
Settings
├─ Theme & Appearance
├─ TODO Preferences
├─ AI Configuration
└─ 🆕 User Context (pro AI Helper)
```

**UI - User Context Page:**
```
┌─────────────────────────────────────┐
│ ← User Context                      │
├─────────────────────────────────────┤
│ ℹ️  Tyto informace pomáhají AI       │
│    lépe organizovat vaše poznámky   │
│    do PARA struktury.               │
│                                     │
│ 👤 Základní Info                    │
│ ┌─────────────────────────────────┐ │
│ │ Jméno:                          │ │
│ │ [Jaroslav_____________]         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 💼 Práce & Kariéra                  │
│ ┌─────────────────────────────────┐ │
│ │ Pozice:                         │ │
│ │ [Product Manager______]         │ │
│ │                                 │ │
│ │ Firma/Obor:                     │ │
│ │ [SaaS startup_________]         │ │
│ │                                 │ │
│ │ Aktuální projekty (📝):         │ │
│ │ • Q4 Roadmap              [🗑️]  │ │
│ │ • User Research           [🗑️]  │ │
│ │ [+ Přidat projekt]              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎯 Oblasti Odpovědnosti             │
│ ┌─────────────────────────────────┐ │
│ │ • Product Strategy        [🗑️]  │ │
│ │ • Team Management         [🗑️]  │ │
│ │ • Health & Fitness        [🗑️]  │ │
│ │ [+ Přidat oblast]               │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 👨‍👩‍👧‍👦 Rodina & Osobní Život         │
│ ┌─────────────────────────────────┐ │
│ │ Stav:                           │ │
│ │ [Ženatý/Vdaná_____▼]            │ │
│ │                                 │ │
│ │ Děti:                           │ │
│ │ [2_____]                        │ │
│ │                                 │ │
│ │ Životní situace:                │ │
│ │ [Vlastní byt, 2 děti ve škole] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🎨 Koníčky & Zájmy                  │
│ ┌─────────────────────────────────┐ │
│ │ • Programování          [🗑️]    │ │
│ │ • Fotografování         [🗑️]    │ │
│ │ • Běhání                [🗑️]    │ │
│ │ [+ Přidat koníček]              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 💡 Další Kontext (volitelné)        │
│ ┌─────────────────────────────────┐ │
│ │ [Dlouhodobé cíle, vzdělání...] │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [💾 Uložit Context]                 │
└─────────────────────────────────────┘
```

**Datový Model:**
```dart
// features/settings/domain/entities/user_context.dart
class UserContext {
  final String? name;
  final WorkInfo? workInfo;
  final List<String> currentProjects;
  final List<String> responsibilities;
  final PersonalInfo? personalInfo;
  final List<String> hobbies;
  final String? additionalContext;

  // Validace: alespoň 1 pole vyplněné
  bool get isValid =>
    (name?.isNotEmpty ?? false) ||
    workInfo != null ||
    currentProjects.isNotEmpty ||
    responsibilities.isNotEmpty;
}

class WorkInfo {
  final String position;
  final String? company;
  final String? industry;
}

class PersonalInfo {
  final String? maritalStatus;
  final int? numberOfChildren;
  final String? lifeSituation;
}
```

**Backend - Posílání do AI:**
```dart
// V AiHelperService.analyzNote()
Future<AiHelperSuggestions> analyzNote(Note note) async {
  final userContext = await _settingsRepo.getUserContext();
  final paraStructure = await _paraRepo.getFullStructure();

  final prompt = _buildUserContextPrompt(userContext, paraStructure, note);

  // ...
}

String _buildUserContextPrompt(
  UserContext userContext,
  List<ParaFolder> paraStructure,
  Note note,
) {
  return '''
KONTEXT O UŽIVATELI:
- Jméno: ${userContext.name ?? 'neznámé'}
- Pozice: ${userContext.workInfo?.position ?? 'neznámá'}
- Firma: ${userContext.workInfo?.company ?? 'neznámá'}
- Aktuální projekty: ${userContext.currentProjects.join(', ')}
- Oblasti odpovědnosti: ${userContext.responsibilities.join(', ')}
- Koníčky: ${userContext.hobbies.join(', ')}
${userContext.additionalContext != null ? '- Další: ${userContext.additionalContext}' : ''}

EXISTUJÍCÍ PARA STRUKTURA:

Projects (${_countFolders(paraStructure, ParaType.projects)} složek):
${_formatParaTree(paraStructure, ParaType.projects)}

Areas (${_countFolders(paraStructure, ParaType.areas)} složek):
${_formatParaTree(paraStructure, ParaType.areas)}

Resources (${_countFolders(paraStructure, ParaType.resources)} složek):
${_formatParaTree(paraStructure, ParaType.resources)}

Archives (${_countFolders(paraStructure, ParaType.archives)} složek):
${_formatParaTree(paraStructure, ParaType.archives)}

---

POZNÁMKA K ANALÝZE:
Název: "${note.title}"
Obsah: "${note.content}"
Tagy: ${note.tags.join(', ')}

---

Na základě kontextu uživatele a existující PARA struktury:
1. Kam tuto poznámku zařadit? (využij EXISTUJÍCÍ složky nebo navrhni NOVOU)
2. Jaké tagy by měla mít?
3. Souvisí s nějakým existujícím projektem nebo oblastí?
''';
}

// Helper: Formátovat PARA tree
String _formatParaTree(List<ParaFolder> folders, ParaType type) {
  final typeFolders = folders.where((f) => f.type == type).toList();

  if (typeFolders.isEmpty) {
    return '  (žádné složky)';
  }

  final buffer = StringBuffer();
  for (final folder in typeFolders) {
    final indent = '  ' * folder.level;
    buffer.writeln('$indent└─ ${folder.name}');

    // Zobrazit poznámky v této složce (volitelné)
    final notesCount = _countNotesInFolder(folder.id);
    if (notesCount > 0) {
      buffer.writeln('$indent   ($notesCount notes)');
    }
  }

  return buffer.toString();
}
```

**Příklad AI Input (kompletní):**
```
KONTEXT O UŽIVATELI:
- Jméno: Jaroslav
- Pozice: Product Manager
- Firma: SaaS startup
- Aktuální projekty: Q4 Roadmap, User Research
- Oblasti odpovědnosti: Product Strategy, Team Management, Health
- Koníčky: Programování, Fotografování, Běhání
- Další: Plánuji launch nového produktu Q1 2026

EXISTUJÍCÍ PARA STRUKTURA:

Projects (3 složek):
  └─ Q4_Roadmap
     (5 notes)
  └─ User_Research
    └─ Interview_Notes
       (8 notes)
  └─ Product_Launch_Prep
     (2 notes)

Areas (4 složek):
  └─ Product_Strategy
    └─ Strategy_Documents
       (3 notes)
  └─ Team_Management
     (1 note)
  └─ Health
    └─ Workout_Plans
       (6 notes)
    └─ Nutrition
       (4 notes)
  └─ Photography
     (0 notes)

Resources (2 složek):
  └─ Design_Inspiration
     (12 notes)
  └─ Market_Research
     (7 notes)

Archives (1 složka):
  └─ 2024_Q3
    └─ Completed_Projects
       (15 notes)

---

POZNÁMKA K ANALÝZE:
Název: "Nápad na onboarding flow"
Obsah: "Uživatelé se ztrácejí při prvním použití app. Potřebujeme interaktivní tour s tooltips. Inspirace: Duolingo, Notion. Možná AI-driven personalizace?"
Tagy: nápad, ux

---

Na základě kontextu uživatele a existující PARA struktury:
1. Kam tuto poznámku zařadit? (využij EXISTUJÍCÍ složky nebo navrhni NOVOU)
2. Jaké tagy by měla mít?
3. Souvisí s nějakým existujícím projektem nebo oblastí?
```

**AI Response:**
```json
{
  "paraClassification": {
    "mainFolder": "resources",
    "subFolder": "product_ideas",
    "reasoning": "Je to nápad, nikoliv aktivní projekt. Patří do Resources jako referenční materiál. Navrhuju NOVOU podsložku 'Product Ideas', protože ji ještě nemáš.",
    "confidence": 0.92,
    "suggestNewFolder": {
      "name": "Product_Ideas",
      "parentFolder": "resources",
      "reason": "Chybí ti místo pro nápady na features - budou se ti hodit do budoucna."
    }
  },
  "suggestedTags": ["*ux*", "*onboarding*", "*product-ideas*", "*ai*"],
  "relatedToExisting": [
    {
      "type": "project",
      "name": "Q4_Roadmap",
      "reason": "Onboarding by mohl být součástí Q4 roadmapu."
    },
    {
      "type": "area",
      "name": "Product_Strategy",
      "reason": "UX zlepšení je součástí product strategy."
    }
  ],
  "suggestedActions": [
    "Pokud se rozhodneš implementovat, převeď na Project 'Onboarding_Improvement' s deadline.",
    "Přilinkuj k existujícímu projektu Q4_Roadmap jako research note."
  ]
}
```

**Storage:**
```dart
// data/datasources/settings_db_datasource.dart
class SettingsDbDatasource {
  Future<void> saveUserContext(UserContext context) async {
    await _db.insert(
      'user_context',
      {
        'name': context.name,
        'work_position': context.workInfo?.position,
        'work_company': context.workInfo?.company,
        'work_industry': context.workInfo?.industry,
        'current_projects': jsonEncode(context.currentProjects),
        'responsibilities': jsonEncode(context.responsibilities),
        'marital_status': context.personalInfo?.maritalStatus,
        'number_of_children': context.personalInfo?.numberOfChildren,
        'life_situation': context.personalInfo?.lifeSituation,
        'hobbies': jsonEncode(context.hobbies),
        'additional_context': context.additionalContext,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
```

**Privacy & Security:**
```
⚠️ DŮLEŽITÉ: User Context je CITLIVÁ DATA!

1. Ukládáme lokálně (SQLite) - ŽÁDNÉ cloud
2. AI API dostane jen to, co je NUTNÉ pro klasifikaci
3. V Settings: Toggle "Share User Context with AI" (default: ON)
4. Pokud OFF → AI dostane jen PARA strukturu (bez osobních info)
5. Export/Backup: Šifrování User Context (AES-256)
```

**UI Flow - První Použití:**
```
User otevře Settings → User Context

[Popup]
┌─────────────────────────────────────┐
│ 🤖 AI Helper Personalizace          │
├─────────────────────────────────────┤
│ Vyplněním informací o sobě pomůžeš │
│ AI lépe organizovat poznámky do     │
│ PARA struktury.                     │
│                                     │
│ Co AI uvidí:                        │
│ ✅ Vaše pracovní pozice             │
│ ✅ Aktuální projekty                │
│ ✅ Oblasti odpovědnosti             │
│ ✅ Koníčky                          │
│                                     │
│ Co AI NEUVIDÍ:                      │
│ ❌ Obsah poznámek (jen metadata)    │
│ ❌ Osobní identifikátory            │
│                                     │
│ [Vyplnit Teď] [Možná Později]      │
└─────────────────────────────────────┘
```

**Benefit:**
- AI má kontext → lepší klasifikace (85%+ accuracy)
- Navrhuje NOVÉ složky, když chybí
- Propojí poznámky s existujícími projekty
- Personalizované tagy (ne generic "work", ale "product-strategy")

---

### 9. Databázové Schema + Inteligentní Linking

**Problém**: Uživatel nechce vyplňovat název poznámky. Jak tedy linkovat?

**Řešení Obsidian:**
- Každá poznámka = soubor s názvem (např. `Meeting Notes 2025-10-13.md`)
- Autocomplete při `[[` → nabízí poznámky podle názvu souboru
- **Placeholder linky**: Můžeš napsat `[[Neexistující poznámka]]` → vytvoří se placeholder

**Náš systém - Lepší řešení:**
- **ID-based linking** (ne název!)
- **Auto-generated titly** z prvního řádku nebo timestampu
- **Fulltext search** autocomplete (ne jen název!)

---

#### 9.1. Databázové Schema

```sql
-- Tabulka: notes
CREATE TABLE notes (
  id TEXT PRIMARY KEY,              -- UUID
  title TEXT,                       -- Nullable! Auto-gen z prvního řádku
  content TEXT NOT NULL,            -- Markdown content s tagy
  created_at INTEGER NOT NULL,      -- Unix timestamp
  updated_at INTEGER NOT NULL,      -- Unix timestamp
  para_folder_id TEXT,              -- FK → para_folders (nullable)
  is_favorite INTEGER DEFAULT 0,   -- Boolean (0/1)
  word_count INTEGER DEFAULT 0,    -- Cache pro rychlé filtry

  -- Fulltext search index
  content_fts TEXT,                 -- Denormalizovaný obsah pro FTS

  FOREIGN KEY (para_folder_id) REFERENCES para_folders(id)
    ON DELETE SET NULL
);

-- FTS5 Virtual Table pro fulltext search
CREATE VIRTUAL TABLE notes_fts USING fts5(
  note_id UNINDEXED,
  title,
  content,
  content=notes,                    -- Content table
  content_rowid=rowid
);

-- Trigger: Auto-update FTS při změně
CREATE TRIGGER notes_ai AFTER INSERT ON notes BEGIN
  INSERT INTO notes_fts(rowid, note_id, title, content)
  VALUES (new.rowid, new.id, new.title, new.content);
END;

CREATE TRIGGER notes_au AFTER UPDATE ON notes BEGIN
  UPDATE notes_fts SET title = new.title, content = new.content
  WHERE rowid = old.rowid;
END;

CREATE TRIGGER notes_ad AFTER DELETE ON notes BEGIN
  DELETE FROM notes_fts WHERE rowid = old.rowid;
END;

-- Tabulka: note_links (propojení mezi poznámkami)
CREATE TABLE note_links (
  id TEXT PRIMARY KEY,
  source_note_id TEXT NOT NULL,    -- Poznámka, která obsahuje link
  target_note_id TEXT,              -- Cílová poznámka (nullable pro placeholders!)
  target_placeholder TEXT,          -- Text placeholder, pokud poznámka neexistuje
  link_type TEXT NOT NULL,          -- 'note', 'todo', 'mention'
  created_at INTEGER NOT NULL,

  FOREIGN KEY (source_note_id) REFERENCES notes(id) ON DELETE CASCADE,
  FOREIGN KEY (target_note_id) REFERENCES notes(id) ON DELETE CASCADE
);

-- Index pro backlinks (rychlé dotazy)
CREATE INDEX idx_note_links_target ON note_links(target_note_id);
CREATE INDEX idx_note_links_source ON note_links(source_note_id);

-- Tabulka: note_tags (M:N vztah)
CREATE TABLE note_tags (
  note_id TEXT NOT NULL,
  tag TEXT NOT NULL,
  created_at INTEGER NOT NULL,

  PRIMARY KEY (note_id, tag),
  FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
);

CREATE INDEX idx_note_tags_tag ON note_tags(tag);

-- Tabulka: para_folders
CREATE TABLE para_folders (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,               -- 'projects', 'areas', 'resources', 'archives'
  name TEXT NOT NULL,
  parent_id TEXT,                   -- Self-referencing FK (nullable)
  level INTEGER NOT NULL DEFAULT 0, -- 0, 1, 2 (max 3 úrovně)
  sort_order INTEGER DEFAULT 0,    -- Pro custom pořadí
  created_at INTEGER NOT NULL,

  FOREIGN KEY (parent_id) REFERENCES para_folders(id) ON DELETE CASCADE
);

CREATE INDEX idx_para_folders_type ON para_folders(type);
CREATE INDEX idx_para_folders_parent ON para_folders(parent_id);
```

---

#### 9.2. Auto-Generated Title

**Problém**: Uživatel nechce vyplňovat název.

**Řešení:**
1. **První řádek jako název** (Obsidian-style)
2. **Fallback na timestamp** (Apple Notes-style)

```dart
// domain/entities/note.dart
class Note {
  final String id;
  final String? title;              // Nullable!
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paraFolderId;
  final bool isFavorite;
  final int wordCount;

  // Computed: Displayable title
  String get displayTitle {
    // 1. Pokud je title vyplněný → použij ho
    if (title != null && title!.isNotEmpty) {
      return title!;
    }

    // 2. Pokud není → extrahuj z prvního řádku
    final firstLine = _extractFirstLine(content);
    if (firstLine.isNotEmpty) {
      return firstLine;
    }

    // 3. Fallback → timestamp
    return 'Note ${DateFormat('yyyy-MM-dd HH:mm').format(createdAt)}';
  }

  String _extractFirstLine(String content) {
    // Odstranit markdown headings (#, ##, ###)
    final cleaned = content.replaceFirst(RegExp(r'^#+\s*'), '');

    // První řádek (max 60 znaků)
    final lines = cleaned.split('\n');
    final firstLine = lines.isNotEmpty ? lines.first.trim() : '';

    if (firstLine.length > 60) {
      return '${firstLine.substring(0, 60)}...';
    }

    return firstLine;
  }
}
```

**Příklady:**

```markdown
# Meeting s klientem
Diskutovali jsme o...

→ displayTitle = "Meeting s klientem"
```

```markdown
Nápad na novou feature - dashboard pro analytics.
Potřebujeme visualizovat...

→ displayTitle = "Nápad na novou feature - dashboard pro analytics."
```

```markdown
(prázdný content)

→ displayTitle = "Note 2025-10-13 20:15"
```

---

#### 9.3. Inteligentní Linking - Fulltext Search Autocomplete

**Inspirace Obsidian:** Autocomplete při `[[`, ale my budeme lepší!

**Náš systém:**
```
*[[           ← User začne psát link
*[[meet       ← Autocomplete nabídne:
┌─────────────────────────────────────┐
│ 🔍 Hledám poznámky...               │
├─────────────────────────────────────┤
│ 📝 Meeting s klientem               │
│    "...diskutovali jsme o Q4..."    │
│    Created: 2025-10-13              │
│                                     │
│ 📝 Meeting Notes 2024               │
│    "...action items: připravit..."  │
│    Created: 2024-12-01              │
│                                     │
│ 📝 Team Meeting Agenda              │
│    "...weekly sync každé pondělí..."│
│    Created: 2025-09-15              │
│                                     │
│ ➕ Vytvořit novou: "meet"           │
└─────────────────────────────────────┘
```

**Implementace:**

```dart
// presentation/widgets/note_link_autocomplete.dart
class NoteLinkAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<NoteLinkAutocomplete> createState() => _NoteLinkAutocompleteState();
}

class _NoteLinkAutocompleteState extends State<NoteLinkAutocomplete> {
  OverlayEntry? _overlayEntry;
  List<NoteSearchResult> _suggestions = [];
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Detekce *[[ pattern
    final linkPattern = RegExp(r'\*\[\[([^\]]*)\]?\]?$');
    final match = linkPattern.firstMatch(text.substring(0, cursorPos));

    if (match != null) {
      final query = match.group(1) ?? '';
      if (query != _currentQuery) {
        _currentQuery = query;
        _showSuggestions(query);
      }
    } else {
      _hideSuggestions();
    }
  }

  Future<void> _showSuggestions(String query) async {
    // Fulltext search v notes
    final results = await context.read<NotesBloc>().searchNotes(query);

    setState(() {
      _suggestions = results;
    });

    _overlayEntry?.remove();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + renderBox.size.height,
        width: renderBox.size.width,
        child: Material(
          elevation: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length + 1,
              itemBuilder: (context, index) {
                if (index == _suggestions.length) {
                  // "Create new" option
                  return ListTile(
                    leading: const Icon(Icons.add),
                    title: Text('Vytvořit novou: "$_currentQuery"'),
                    onTap: () => _createNewNote(_currentQuery),
                  );
                }

                final result = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.note),
                  title: Text(result.note.displayTitle),
                  subtitle: Text(
                    result.snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat('yyyy-MM-dd').format(result.note.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () => _insertLink(result.note),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _insertLink(Note note) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Najít *[[ pattern a nahradit za *[[noteId]]*
    final linkPattern = RegExp(r'\*\[\[([^\]]*)\]?\]?$');
    final beforeCursor = text.substring(0, cursorPos);
    final afterCursor = text.substring(cursorPos);

    final newBefore = beforeCursor.replaceFirst(
      linkPattern,
      '*[[${note.id}]]*', // ID-based link!
    );

    widget.controller.text = newBefore + afterCursor;
    widget.controller.selection = TextSelection.collapsed(
      offset: newBefore.length,
    );

    _hideSuggestions();
  }

  void _createNewNote(String title) async {
    // Vytvořit novou poznámku s placeholder title
    final newNote = await context.read<NotesBloc>().createNote(
      title: title,
      content: '',
    );

    _insertLink(newNote);
  }
}

// domain/entities/note_search_result.dart
class NoteSearchResult {
  final Note note;
  final String snippet;        // Context kolem match
  final double relevanceScore; // FTS rank

  // Sort by relevance
  static int compareByRelevance(NoteSearchResult a, NoteSearchResult b) {
    return b.relevanceScore.compareTo(a.relevanceScore);
  }
}
```

**Fulltext Search Query:**
```dart
// data/datasources/notes_db_datasource.dart
Future<List<NoteSearchResult>> searchNotes(String query) async {
  if (query.isEmpty) {
    return [];
  }

  // FTS5 query
  final results = await _db.rawQuery('''
    SELECT
      n.id, n.title, n.content, n.created_at, n.updated_at,
      n.para_folder_id, n.is_favorite, n.word_count,
      snippet(notes_fts, 1, '<b>', '</b>', '...', 30) AS snippet,
      rank AS relevance
    FROM notes_fts
    JOIN notes n ON notes_fts.rowid = n.rowid
    WHERE notes_fts MATCH ?
    ORDER BY rank
    LIMIT 10
  ''', [query]);

  return results.map((row) => NoteSearchResult(
    note: Note.fromMap(row),
    snippet: row['snippet'] as String,
    relevanceScore: (row['relevance'] as num).toDouble(),
  )).toList();
}
```

**FTS5 Match Syntax:**
```dart
// Obsidian-style fuzzy matching
String buildFtsQuery(String input) {
  // "meet client" → "meet* AND client*"
  final terms = input.split(' ').where((t) => t.isNotEmpty);
  return terms.map((t) => '$t*').join(' AND ');
}
```

---

#### 9.4. Rendering Linků v UI

**Problém**: Link je ID (`*[[abc-123]]*`), ale chceme zobrazit název poznámky.

**Řešení:**
```dart
// presentation/widgets/note_content_viewer.dart
class NoteContentViewer extends StatelessWidget {
  final Note note;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: _buildStyledContent(context, note.content),
      ),
    );
  }

  List<InlineSpan> _buildStyledContent(BuildContext context, String content) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\[\[([^\]]+)\]\]\*');

    int lastIndex = 0;
    for (final match in pattern.allMatches(content)) {
      // Text před linkem
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
        ));
      }

      // Link (ID nebo placeholder text)
      final linkTarget = match.group(1)!;
      spans.add(_buildLinkSpan(context, linkTarget));

      lastIndex = match.end;
    }

    // Zbytek textu
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
      ));
    }

    return spans;
  }

  InlineSpan _buildLinkSpan(BuildContext context, String target) {
    // Je to UUID? → fetch poznámku
    final isUuid = RegExp(r'^[a-f0-9-]{36}$').hasMatch(target);

    if (isUuid) {
      return FutureBuilder<Note?>(
        future: context.read<NotesBloc>().getNoteById(target),
        builder: (context, snapshot) {
          final displayText = snapshot.hasData
              ? snapshot.data!.displayTitle
              : 'Loading...';

          return WidgetSpan(
            child: GestureDetector(
              onTap: () {
                if (snapshot.hasData) {
                  _navigateToNote(context, snapshot.data!);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Text(
                  displayText,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Placeholder link (poznámka neexistuje)
      return WidgetSpan(
        child: GestureDetector(
          onTap: () => _createNoteFromPlaceholder(context, target),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey, width: 1, style: BorderStyle.dashed),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  target,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add, size: 12, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _navigateToNote(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(note: note),
      ),
    );
  }

  void _createNoteFromPlaceholder(BuildContext context, String title) {
    // Vytvořit novou poznámku s tímto názvem
    context.read<NotesBloc>().add(CreateNoteFromPlaceholderEvent(title));
  }
}
```

**Výsledek:**
```
Meeting Notes

Diskutovali jsme o [Q4 Roadmap]  ← klikatelný link (modrý)
                   ↑
                   ID: abc-123, ale zobrazí se "Q4 Roadmap"

Přilinkovat k [Nová poznámka] ← placeholder (šedý, dashed)
              ↑
              Neexistuje → kliknutím vytvoří
```

---

#### 9.5. Backlinks Cache

**Problém**: Backlinks jsou drahé (full scan notes).

**Řešení:** Cache v `note_links` tabulce.

```dart
// domain/services/backlink_service.dart
class BacklinkService {
  final NotesRepository _notesRepo;
  final Database _db;

  // Update backlinks po save note
  Future<void> updateBacklinks(Note note) async {
    // 1. Odstranit staré linky z této poznámky
    await _db.delete(
      'note_links',
      where: 'source_note_id = ?',
      whereArgs: [note.id],
    );

    // 2. Parsovat obsah pro linky
    final links = _extractLinks(note.content);

    // 3. Insert nové linky
    for (final link in links) {
      await _db.insert('note_links', {
        'id': Uuid().v4(),
        'source_note_id': note.id,
        'target_note_id': link.isUuid ? link.target : null,
        'target_placeholder': link.isUuid ? null : link.target,
        'link_type': link.type,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // Get backlinks (rychlé!)
  Future<List<Note>> getBacklinks(String noteId) async {
    final results = await _db.rawQuery('''
      SELECT n.*
      FROM notes n
      JOIN note_links nl ON n.id = nl.source_note_id
      WHERE nl.target_note_id = ?
      ORDER BY nl.created_at DESC
    ''', [noteId]);

    return results.map((row) => Note.fromMap(row)).toList();
  }
}
```

---

## 🏗️ Architektura - Feature-First + BLoC

```
lib/features/notes/
├── presentation/
│   ├── bloc/
│   │   ├── notes_bloc.dart
│   │   ├── notes_event.dart
│   │   └── notes_state.dart
│   ├── pages/
│   │   ├── notes_list_page.dart
│   │   ├── note_editor_page.dart
│   │   ├── para_browser_page.dart
│   │   └── graph_view_page.dart (optional)
│   └── widgets/
│       ├── note_card.dart
│       ├── ai_helper_bottom_sheet.dart
│       ├── para_folder_tree.dart
│       ├── markdown_preview.dart
│       └── backlinks_panel.dart
├── domain/
│   ├── entities/
│   │   ├── note.dart
│   │   ├── para_folder.dart
│   │   └── backlink.dart
│   ├── repositories/
│   │   ├── notes_repository.dart
│   │   └── para_folder_repository.dart
│   └── services/
│       ├── notes_tag_parser.dart
│       ├── ai_helper_service.dart
│       ├── markdown_formatter_service.dart
│       └── backlink_service.dart
└── data/
    ├── datasources/
    │   ├── notes_db_datasource.dart
    │   └── openrouter_notes_datasource.dart
    └── repositories/
        ├── notes_repository_impl.dart
        └── para_folder_repository_impl.dart
```

---

## 📋 Implementation Roadmap

### Phase 1: Core Notes (MVP)
**Effort**: 8-10 hodin

1. ✅ Basic Note entity (id, title, content, createdAt, updatedAt)
2. ✅ NotesPage s ListView
3. ✅ Note Editor s TagAutocompleteField (reuse z TODO)
4. ✅ Tag parsing (*tag*, *#123*, *[[Note]]*)
5. ✅ Notes storage (SQLite)
6. ✅ Filter by tags (reuse Agenda Views logiku)

**Deliverable**: Funkční Notes s tagy, propojené s TODO tagy.

### Phase 2: PARA + AI Helper
**Effort**: 12-15 hodin

1. ✅ ParaFolder entity + hierarchie (max 3 levels)
2. ✅ PARA Browser UI (tree view)
3. ✅ AI Helper Service (OpenRouter integration)
4. ✅ User Context Settings page
5. ✅ AI suggestion bottom sheet
6. ✅ Auto-classification do PARA

**Deliverable**: PARA organizace s AI asistencí.

### Phase 3: Advanced Features
**Effort**: 10-12 hodin

1. ✅ Markdown formatting (AI-assisted)
2. ✅ Backlinks service + UI panel
3. ✅ Rich text editor (bold, italic, headings)
4. ✅ Attachments (checklist, image, audio)
5. ✅ Search across notes

**Deliverable**: Plnohodnotný notes systém.

### Phase 4: Polish & Extras (Optional)
**Effort**: 8-10 hodin

1. ✅ Graph View
2. ✅ Export notes (Markdown, PDF)
3. ✅ Templates (meeting notes, project brief...)
4. ✅ Voice-to-text notes
5. ✅ Collaboration (future)

---

## 🎯 Klíčová Rozhodnutí

### 1. Tagy - Custom Oddělovače
**✅ Rozhodnutí**: Zachovat `*tag*` syntax místo `#tag`.

**Důvody:**
- Konzistence s TODO systémem
- Funguje naseptávání
- Flexibilnější (můžeš změnit oddělovač)

**Kompromis**: Zobrazit tagy jako `#tag` v UI, ale ukládat jako `*tag*`.

### 2. Smart Folders vs Agenda Views
**✅ Rozhodnutí**: Unified system - jeden CustomView pro TODO i Notes.

**Benefit**: Uživatel může vytvořit view "Projekt X", který zobrazí:
- TODO úkoly s `*projekt-x*`
- Notes s `*projekt-x*`
- Ve společném listu!

### 3. PARA - Povinné nebo Volitelné?
**✅ Rozhodnutí**: Volitelné, ale doporučené.

**Flow:**
1. Uživatel může vytvořit Notes bez PARA → jednoduše tagy
2. AI Helper navrhne PARA klasifikaci
3. Uživatel může ignorovat nebo přijmout
4. V Settings: "Enable PARA Organization" toggle

### 4. Markdown - Real-time nebo On-demand?
**✅ Rozhodnutí**: Hybrid.

**Flow:**
1. Editor = plain text s live preview tagů (jako teď)
2. Tlačítko "Preview" → Markdown rendering
3. Tlačítko "Format with AI" → Auto-formátování
4. Export → vždy Markdown

### 5. Backlinks - Automatic nebo Manual?
**✅ Rozhodnutí**: Automatic (jako Obsidian).

**Implementace:**
- Při každém save Note → BacklinkService.updateBacklinks()
- Async job (ne blocking)
- Cache v DB (backlinks table)

---

## 💡 Inovace - Co Dělá Náš Systém Unikátní?

### 1. TODO + Notes Integration
**Nikdo jiný to nemá!**
- Apple Notes nemá TODO systém
- Obsidian nemá nativní TODO
- Notion je heavyweight

**Náš benefit**: Poznámka z meetingu → klikneš "Create TODO" → AI navrhne task + tagy.

### 2. AI-Assisted PARA
**Tiago Forte doporučuje PARA, ale nemá AI tool!**
- AI automaticky klasifikuje
- Navrhuje, kam co patří
- Učí uživatele PARA myšlení

**Marketingový angle**: "Second Brain with AI Guide".

### 3. Unified Tagging Across TODO + Notes
**Silné spojení:**
- Tag `*projekt-x*` spojuje TODO úkoly, poznámky, pomodoro sessions
- Jeden "mental model" pro celou app
- Agenda Views = unified view

---

## 🚨 Potenciální Problémy a Řešení

### Problem 1: PARA Overwhelm
**Riziko**: Uživatel nerozumí PARA → ignoruje feature.

**Řešení:**
1. Onboarding tutorial (interactive)
2. "Simple Mode" vs "PARA Mode" toggle
3. AI helper vysvětlí *proč* navrhuje tu složku

### Problem 2: Too Many Features
**Riziko**: Scope creep → nikdy to nedokončíme.

**Řešení:**
1. Strict MVP (Phase 1)
2. Phase gating - dokončit Phase 1 před Phase 2
3. User feedback loop

### Problem 3: Performance
**Riziko**: 1000+ notes → pomalé filtrování/backlinks.

**Řešení:**
1. Indexování tagů v DB
2. Lazy loading (paginated lists)
3. Cache backlinks
4. Background sync pro AI suggestions

### Problem 4: AI Cost
**Riziko**: 1000 uživatelů × 10 AI calls/den = $150/den.

**Řešení:**
1. Freemium model: 5 AI calls/den zdarma
2. Pro plan: unlimited AI
3. Cache suggestions (stejný note content → stejný result)
4. User opt-in: "Enable AI Helper"

---

## 📊 Success Metrics

**MVP Launch (Phase 1):**
- [ ] 100% feature parity s Apple Notes tagy
- [ ] Backlinks fungují
- [ ] Notes ↔ TODO linking works

**Phase 2 Success:**
- [ ] 80% uživatelů používá alespoň 1 PARA složku
- [ ] AI Helper acceptance rate > 60%
- [ ] Average notes per user > 20

**Long-term:**
- [ ] Export "Second Brain" jako selling point
- [ ] Community templates pro PARA
- [ ] Obsidian migrace tool (import .md soubory)

---

## 🎓 Doporučení pro Implementaci

### Start with MVP (Phase 1)
**KISS principle**: Základní notes s tagy. Otestuj, že funguje propojení s TODO.

### Iteruj na AI Helper
**Testuj prompt engineering**: Několik verzí prompts pro PARA klasifikaci. A/B testing.

### User Research
**Před Phase 2**: Zeptej se 10 uživatelů:
- Znáš PARA metodu?
- Používáš složky pro poznámky?
- Co tě nejvíc štve na Apple Notes / Obsidian?

### Open Source Inspiration
**Studuj tyto projekty:**
- [Obsidian API](https://github.com/obsidianmd/obsidian-api)
- [Standard Notes](https://github.com/standardnotes/app)
- [Joplin](https://github.com/laurent22/joplin)

---

## 🔗 Reference

### PARA Method
- **Kniha**: "Building a Second Brain" - Tiago Forte
- **Blog**: https://fortelabs.com/blog/para/
- **Kurz**: https://www.buildingasecondbrain.com/

### Apple Notes
- **Dokumentace**: https://support.apple.com/en-us/102288
- **Smart Folders Guide**: https://support.apple.com/guide/notes/apd58edc7964/mac

### Obsidian
- **Docs**: https://help.obsidian.md/
- **Linking**: https://help.obsidian.md/link-notes
- **Backlinks**: https://help.obsidian.md/plugins/backlinks

### Markdown
- **CommonMark Spec**: https://commonmark.org/
- **GitHub Flavored Markdown**: https://github.github.com/gfm/

---

## 📝 Závěr

**Toto je ambiciózní, ale realizovatelné!**

Kombinujeme nejlepší prvky z:
- ✅ Apple Notes (jednoduchost, tagy, smart folders)
- ✅ Obsidian (backlinks, markdown, knowledge graph)
- ✅ PARA metoda (organizace podle actionability)
- ✅ AI asistence (unique selling point!)

**Náš TODO systém je silný fundament** - máme tagy, filtry, AI Brief. Notes je logické rozšíření.

**Next Step**: Snapshot commit, implementace Phase 1 MVP (8-10h práce).

---

**Autor**: Claude Code AI
**Metoda**: Ultrathink analysis + WebSearch research
**Status**: Ready for implementation 🚀
