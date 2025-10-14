# Smart Folders - Návrh implementace pro Notes

## 🎯 Koncept

**Smart Folders** jsou dynamické pohledy na poznámky založené na pravidlech, které si uživatel nadefinuje. Inspirováno Apple Notes + Obsidian + Notion.

### Princip:
- User vytvoří folder "Favorites"
- Nastaví pravidlo: "Zobraz poznámky s tagem `*oblibene*` nebo `*fav*`"
- Všechny poznámky s těmito tagy se automaticky zobrazí ve folderu "Favorites"

### Rozdíl oproti TODO Agenda Views:
| Feature | TODO Agenda Views | Notes Smart Folders |
|---------|-------------------|---------------------|
| Typ | Statické pohledy (All, Today, Week, Overdue) | Dynamické, uživatelem definovatelné |
| Filtry | Hardcoded (podle date, priority) | Konfigurovatelné pravidla |
| Settings | Není potřeba | Dedicated Settings tab |
| Custom views | Ne (jen Brief s AI) | Ano (neomezené množství) |

---

## 📐 Architektura

### 1. Database Schema

```sql
-- Smart Folders tabulka
CREATE TABLE note_smart_folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,              -- "Favorites", "Work Notes", "Personal"
  icon TEXT NOT NULL,               -- "⭐", "💼", "🏠", "📚"
  is_system INTEGER DEFAULT 0,     -- 1 = built-in (All, Recent), 0 = custom
  filter_rules TEXT NOT NULL,      -- JSON: FilterRules object
  display_order INTEGER NOT NULL,  -- Order in tabs
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Default folders (seeded on first run)
INSERT INTO note_smart_folders (name, icon, is_system, filter_rules, display_order, created_at, updated_at) VALUES
  ('All Notes', '📝', 1, '{"type":"all"}', 0, datetime('now'), datetime('now')),
  ('Recent', '🕐', 1, '{"type":"recent","days":7}', 1, datetime('now'), datetime('now')),
  ('Favorites', '⭐', 1, '{"type":"tags","tags":["oblibene","fav"],"operator":"OR"}', 2, datetime('now'), datetime('now'));
```

**Poznámky:**
- `is_system = 1` → nelze smazat, lze pouze editovat pravidla
- `filter_rules` → JSON string s filtrovacími pravidly
- `display_order` → pořadí v horizontal scroll tab bar

---

### 2. Models

#### 2.1 SmartFolder Model

```dart
class SmartFolder {
  final int? id;
  final String name;
  final String icon;
  final bool isSystem;
  final FilterRules rules;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SmartFolder({
    this.id,
    required this.name,
    required this.icon,
    this.isSystem = false,
    required this.rules,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_system': isSystem ? 1 : 0,
      'filter_rules': jsonEncode(rules.toJson()),
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SmartFolder.fromMap(Map<String, dynamic> map) {
    return SmartFolder(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isSystem: (map['is_system'] as int) == 1,
      rules: FilterRules.fromJson(jsonDecode(map['filter_rules'] as String)),
      displayOrder: map['display_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  SmartFolder copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isSystem,
    FilterRules? rules,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      rules: rules ?? this.rules,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### 2.2 FilterRules Model

```dart
/// Pravidla pro filtrování poznámek
class FilterRules {
  final FilterType type;
  final List<String> includeTags;   // Zobraz poznámky S těmito tagy
  final List<String> excludeTags;   // Nezobrazuj poznámky S těmito tagy
  final FilterOperator operator;    // AND = všechny tagy, OR = alespoň jeden tag
  final int? recentDays;            // Pro type=recent: počet dní
  final DateRange? dateRange;       // Pro type=date_range: custom range

  const FilterRules({
    this.type = FilterType.all,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.operator = FilterOperator.or,
    this.recentDays,
    this.dateRange,
  });

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'includeTags': includeTags,
      'excludeTags': excludeTags,
      'operator': operator.name,
      'recentDays': recentDays,
      'dateRange': dateRange?.toJson(),
    };
  }

  factory FilterRules.fromJson(Map<String, dynamic> json) {
    return FilterRules(
      type: FilterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FilterType.all,
      ),
      includeTags: (json['includeTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
      excludeTags: (json['excludeTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? [],
      operator: FilterOperator.values.firstWhere(
        (e) => e.name == json['operator'],
        orElse: () => FilterOperator.or,
      ),
      recentDays: json['recentDays'] as int?,
      dateRange: json['dateRange'] != null
          ? DateRange.fromJson(json['dateRange'])
          : null,
    );
  }

  FilterRules copyWith({
    FilterType? type,
    List<String>? includeTags,
    List<String>? excludeTags,
    FilterOperator? operator,
    int? recentDays,
    DateRange? dateRange,
  }) {
    return FilterRules(
      type: type ?? this.type,
      includeTags: includeTags ?? this.includeTags,
      excludeTags: excludeTags ?? this.excludeTags,
      operator: operator ?? this.operator,
      recentDays: recentDays ?? this.recentDays,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

/// Typ filtru
enum FilterType {
  all,         // Všechny poznámky
  recent,      // Poslední X dní
  tags,        // Podle tagů
  dateRange,   // Custom date range
}

/// Operátor pro kombinaci tagů
enum FilterOperator {
  and,  // Musí obsahovat VŠECHNY tagy
  or,   // Musí obsahovat ALESPOŇ JEDEN tag
}

/// Date range pro custom filtering
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }
}
```

---

### 3. Database Helper Extension

```dart
// V DatabaseHelper.dart přidat:

/// SMART FOLDERS - CRUD operace

/// Načíst všechny smart folders (seřazené podle display_order)
Future<List<Map<String, dynamic>>> getAllSmartFolders() async {
  final db = await database;
  return await db.query(
    'note_smart_folders',
    orderBy: 'display_order ASC',
  );
}

/// Načíst smart folder podle ID
Future<Map<String, dynamic>?> getSmartFolder(int id) async {
  final db = await database;
  final results = await db.query(
    'note_smart_folders',
    where: 'id = ?',
    whereArgs: [id],
  );
  return results.isNotEmpty ? results.first : null;
}

/// Vytvořit nový smart folder
Future<int> insertSmartFolder(Map<String, dynamic> folder) async {
  final db = await database;
  return await db.insert('note_smart_folders', folder);
}

/// Aktualizovat smart folder
Future<int> updateSmartFolder(int id, Map<String, dynamic> folder) async {
  final db = await database;
  return await db.update(
    'note_smart_folders',
    folder,
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// Smazat smart folder (pouze custom, ne system)
Future<int> deleteSmartFolder(int id) async {
  final db = await database;

  // Check if system folder
  final folder = await getSmartFolder(id);
  if (folder != null && (folder['is_system'] as int) == 1) {
    throw Exception('Cannot delete system folder');
  }

  return await db.delete(
    'note_smart_folders',
    where: 'id = ?',
    whereArgs: [id],
  );
}

/// Seed default smart folders (volat při první inicializaci)
Future<void> _seedDefaultSmartFolders() async {
  final db = await database;

  // Check if already seeded
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM note_smart_folders'),
  );

  if (count == 0) {
    // Seed default folders
    await db.insert('note_smart_folders', {
      'name': 'All Notes',
      'icon': '📝',
      'is_system': 1,
      'filter_rules': jsonEncode({'type': 'all'}),
      'display_order': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('note_smart_folders', {
      'name': 'Recent',
      'icon': '🕐',
      'is_system': 1,
      'filter_rules': jsonEncode({'type': 'recent', 'recentDays': 7}),
      'display_order': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('note_smart_folders', {
      'name': 'Favorites',
      'icon': '⭐',
      'is_system': 1,
      'filter_rules': jsonEncode({
        'type': 'tags',
        'includeTags': ['oblibene', 'fav'],
        'operator': 'or',
      }),
      'display_order': 2,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
```

---

### 4. Notes Filtering Logic

#### 4.1 Update NotesState

```dart
class NotesLoaded extends NotesState {
  final List<Note> notes;           // Všechny poznámky (unfiltered)
  final SmartFolder? currentFolder; // Aktuální smart folder (NEW!)
  final int? expandedNoteId;

  const NotesLoaded({
    required this.notes,
    this.currentFolder,
    this.expandedNoteId,
  });

  @override
  List<Object?> get props => [notes, currentFolder, expandedNoteId];

  /// Computed: Filtrované poznámky podle currentFolder pravidel
  List<Note> get displayedNotes {
    if (currentFolder == null) return notes;

    final rules = currentFolder!.rules;

    switch (rules.type) {
      case FilterType.all:
        return notes;

      case FilterType.recent:
        final daysAgo = DateTime.now().subtract(
          Duration(days: rules.recentDays ?? 7),
        );
        return notes.where((note) => note.createdAt.isAfter(daysAgo)).toList();

      case FilterType.tags:
        return notes.where((note) {
          // Include tags filter
          if (rules.includeTags.isNotEmpty) {
            final hasIncludeTag = rules.operator == FilterOperator.or
                ? note.tags.any((tag) => rules.includeTags.contains(tag))
                : rules.includeTags.every((tag) => note.tags.contains(tag));

            if (!hasIncludeTag) return false;
          }

          // Exclude tags filter
          if (rules.excludeTags.isNotEmpty) {
            final hasExcludeTag = note.tags.any(
              (tag) => rules.excludeTags.contains(tag),
            );
            if (hasExcludeTag) return false;
          }

          return true;
        }).toList();

      case FilterType.dateRange:
        if (rules.dateRange == null) return notes;
        return notes.where((note) {
          return note.createdAt.isAfter(rules.dateRange!.start) &&
              note.createdAt.isBefore(rules.dateRange!.end);
        }).toList();
    }
  }

  NotesLoaded copyWith({
    List<Note>? notes,
    SmartFolder? currentFolder,
    int? expandedNoteId,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      currentFolder: currentFolder ?? this.currentFolder,
      expandedNoteId: expandedNoteId,
    );
  }
}
```

#### 4.2 Update NotesBloc

```dart
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final DatabaseHelper _db;
  List<SmartFolder> _smartFolders = []; // Cache smart folders

  NotesBloc(this._db) : super(const NotesInitial()) {
    on<LoadNotesEvent>(_onLoadNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<ChangeFolderEvent>(_onChangeFolder);
    on<LoadSmartFoldersEvent>(_onLoadSmartFolders); // NEW!
    on<ToggleExpandNoteEvent>(_onToggleExpandNote);
  }

  /// Handler: Načíst smart folders z DB
  Future<void> _onLoadSmartFolders(
    LoadSmartFoldersEvent event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final foldersData = await _db.getAllSmartFolders();
      _smartFolders = foldersData.map((data) => SmartFolder.fromMap(data)).toList();

      // Pokud jsou notes načtené, update state s první folder
      if (state is NotesLoaded) {
        final currentState = state as NotesLoaded;
        final defaultFolder = _smartFolders.isNotEmpty ? _smartFolders.first : null;
        emit(currentState.copyWith(currentFolder: defaultFolder));
      }
    } catch (e) {
      emit(NotesError('Chyba při načítání smart folders: $e'));
    }
  }

  /// Handler: Změnit folder
  Future<void> _onChangeFolder(
    ChangeFolderEvent event,
    Emitter<NotesState> emit,
  ) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;

      // Find folder by ID
      final folder = _smartFolders.firstWhere(
        (f) => f.id == event.folderId,
        orElse: () => _smartFolders.first,
      );

      emit(currentState.copyWith(currentFolder: folder));
    }
  }
}
```

---

## 🎨 UI Components

### 1. Settings Tab - Smart Folders

```
lib/features/settings/presentation/pages/smart_folders_settings_page.dart
```

**Features:**
- List všech smart folders (system + custom)
- Drag-to-reorder (změna display_order)
- Edit button → otevře formulář
- Add button → vytvoří nový folder
- Delete button (jen pro custom folders)

**Layout:**
```
┌─────────────────────────────────────────┐
│ Smart Folders                [+ Add]    │
├─────────────────────────────────────────┤
│ 📝 All Notes          [System]          │
│ 🕐 Recent (7 days)    [System]  [Edit]  │
│ ⭐ Favorites          [System]  [Edit]  │
│ 💼 Work Notes         [Custom]  [Edit] [Delete] │
│ 🏠 Personal           [Custom]  [Edit] [Delete] │
└─────────────────────────────────────────┘
```

### 2. Smart Folder Editor

```
lib/features/settings/presentation/widgets/smart_folder_editor.dart
```

**Form fields:**
```
┌─────────────────────────────────────────┐
│ Edit Smart Folder                       │
├─────────────────────────────────────────┤
│ Name: [Work Notes                    ]  │
│ Icon: [💼] [Pick Icon Picker]          │
├─────────────────────────────────────────┤
│ Filter Rules:                           │
│                                         │
│ Type: ○ All                             │
│       ○ Recent (last X days)            │
│       ● Tags                            │
│       ○ Date Range                      │
├─────────────────────────────────────────┤
│ Include Tags:                           │
│ [prace] [x]  [projekt] [x]  [+ Add]    │
│                                         │
│ Exclude Tags:                           │
│ [archiv] [x]  [+ Add]                   │
│                                         │
│ Operator: ○ AND (all tags)              │
│           ● OR (any tag)                │
├─────────────────────────────────────────┤
│           [Cancel]  [Save]              │
└─────────────────────────────────────────┘
```

### 3. Tag Selector Widget

```dart
class TagSelectorWidget extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  // Shows autocomplete dropdown with existing tags from notes
  // User can also type custom tag
}
```

### 4. Update FoldersTabBar

```dart
// lib/features/notes/presentation/widgets/folders_tab_bar.dart

class FoldersTabBar extends StatelessWidget {
  final List<SmartFolder> folders;  // Dynamic list z DB!
  final SmartFolder? currentFolder;
  final ValueChanged<int> onFolderChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: folders.map((folder) {
          final isActive = currentFolder?.id == folder.id;

          return GestureDetector(
            onTap: () => onFolderChanged(folder.id!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? theme.primary : theme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(folder.icon, style: TextStyle(fontSize: 18)),
                  SizedBox(width: 8),
                  Text(folder.name),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

---

## 📋 Implementační fáze

### **Phase 1: Database + Models** (2-3h)
**Checklist:**
- [ ] Přidat `note_smart_folders` tabulku do database schema
- [ ] Implementovat `_seedDefaultSmartFolders()` v DatabaseHelper
- [ ] Vytvořit `SmartFolder` model v `lib/features/notes/domain/models/smart_folder.dart`
- [ ] Vytvořit `FilterRules` model v `lib/features/notes/domain/models/filter_rules.dart`
- [ ] Vytvořit enums: `FilterType`, `FilterOperator`
- [ ] Vytvořit `DateRange` model
- [ ] Implementovat CRUD metody v DatabaseHelper:
  - `getAllSmartFolders()`
  - `getSmartFolder(int id)`
  - `insertSmartFolder(Map<String, dynamic>)`
  - `updateSmartFolder(int id, Map<String, dynamic>)`
  - `deleteSmartFolder(int id)`
- [ ] Napsat unit testy pro modely
- [ ] Commit: `✨ feat: Smart Folders - Database schema + Models`

---

### **Phase 2: BLoC Logic** (2-3h)
**Checklist:**
- [ ] Update `NotesState` - přidat `currentFolder: SmartFolder?`
- [ ] Implementovat `displayedNotes` getter s filtering logikou
- [ ] Přidat `LoadSmartFoldersEvent`
- [ ] Přidat `ChangeFolderEvent` s `folderId: int`
- [ ] Update `NotesBloc`:
  - Cache `_smartFolders` list
  - Handler `_onLoadSmartFolders`
  - Update `_onChangeFolder` pro práci s SmartFolder objekty
- [ ] Update `NotesListPage` - načíst smart folders při init
- [ ] Napsat BLoC testy pro filtering logic
- [ ] Commit: `✨ feat: Smart Folders - BLoC filtering logic`

---

### **Phase 3: Settings UI** (3-4h)
**Checklist:**
- [ ] Vytvořit `SmartFoldersSettingsPage` v `lib/features/settings/presentation/pages/`
- [ ] Implementovat list smart folders (system + custom)
- [ ] Přidat "Add Folder" button → navigace na editor
- [ ] Přidat "Edit" button → navigace na editor s pre-filled data
- [ ] Přidat "Delete" button s confirmation dialog (jen custom)
- [ ] Implementovat drag-to-reorder (reorder display_order)
- [ ] Vytvořit `SmartFolderEditorPage`
- [ ] Form fields:
  - Name input
  - Icon picker (emoji selector)
  - Filter type radio buttons
  - Tag selector (include/exclude)
  - Operator toggle (AND/OR)
  - Date range picker (pro type=dateRange)
- [ ] Vytvořit `TagSelectorWidget` s autocomplete
- [ ] Validace formuláře (name not empty, atd.)
- [ ] Save handler → update DB + reload folders
- [ ] Přidat Settings tab button: "Smart Folders"
- [ ] Commit: `✨ feat: Smart Folders - Settings UI`

---

### **Phase 4: UI Integration** (1-2h)
**Checklist:**
- [ ] Update `FoldersTabBar` - dynamický list z `_smartFolders`
- [ ] Handle klik na folder → emit `ChangeFolderEvent`
- [ ] Display current folder name v UI
- [ ] Refresh folders když se vrátíme ze Settings (BlocListener)
- [ ] Animace při změně folderu
- [ ] Empty state když folder nemá žádné poznámky
- [ ] Loading state při načítání folders
- [ ] Error handling (neplatný filter rule, atd.)
- [ ] Commit: `✨ feat: Smart Folders - UI integration complete`

---

### **Phase 5: Testing + Polish** (1-2h)
**Checklist:**
- [ ] Integration testy - end-to-end flow
- [ ] Test edge cases:
  - Prázdný include/exclude tags
  - Invalid date range
  - Delete system folder (should fail)
  - Reorder folders
- [ ] Performance test s 1000+ notes
- [ ] UI polish:
  - Smooth animations
  - Loading indicators
  - Error messages v češtině
- [ ] Update documentation
- [ ] Commit: `✅ test: Smart Folders - Complete testing & polish`

---

## 🎯 Example Use Cases

### Use Case 1: Favorites Folder
```
User creates folder "Favorites":
  - Include tags: ["oblibene", "fav"]
  - Operator: OR

User creates note: "*oblibene* nákupní seznam"
→ Note appears in "Favorites" folder ✅

User creates note: "*fav* oblíbený recept"
→ Note appears in "Favorites" folder ✅
```

### Use Case 2: Work Notes
```
User creates folder "Work Notes":
  - Include tags: ["prace", "projekt"]
  - Exclude tags: ["archiv"]
  - Operator: OR

User creates note: "*prace* meeting notes"
→ Note appears in "Work Notes" ✅

User edits note: "*prace* *archiv* meeting notes"
→ Note disappears from "Work Notes" (excluded) ✅
```

### Use Case 3: Recent Projects
```
User creates folder "Recent Projects":
  - Type: Recent (7 days)

Any note created in last 7 days appears ✅
Notes older than 7 days disappear automatically ✅
```

---

## 🚀 Future Enhancements (v2.0)

### 1. Advanced Filters
- **Backlinks**: "Show notes linked to [[Note Title]]"
- **Word count**: "Show notes with > 100 words"
- **Has attachments**: "Show notes with images"

### 2. Smart Folder Templates
- Prebuilt templates: "GTD", "Zettelkasten", "PARA"
- One-click setup

### 3. Folder Nesting
- Hierarchical folders: "Work > Projects > Active"
- Parent/child relationships

### 4. Saved Searches
- Quick filters: "Show untagged notes"
- Pinned searches in sidebar

### 5. AI-Powered Folders
- "Auto-categorize notes by AI"
- Smart suggestions: "Notes similar to this"

---

## 📊 Technical Considerations

### Performance
- **Caching**: Smart folders cached in memory
- **Lazy loading**: Notes loaded on-demand per folder
- **Indexing**: Database indexes on `tags` column for fast filtering

### Migration Strategy
```dart
// Database migration v2 → v3
Future<void> _migrateToV3(Database db, int oldVersion) async {
  if (oldVersion < 3) {
    // Add note_smart_folders table
    await db.execute('''
      CREATE TABLE note_smart_folders (...)
    ''');

    // Seed default folders
    await _seedDefaultSmartFolders();
  }
}
```

### Error Handling
- **Invalid filter rules**: Fallback to "All Notes" folder
- **Deleted tags**: Filter rules auto-cleanup
- **Corrupted JSON**: Try parse, fallback to empty rules

### Testing Strategy
- **Unit tests**: Filter logic, model serialization
- **Widget tests**: UI components, Settings forms
- **Integration tests**: End-to-end folder workflow
- **Performance tests**: 1000+ notes filtering speed

---

## 📝 Notes

- **Inspirace**: Apple Notes Smart Folders + Obsidian Dataview + Notion Filters
- **User story**: "Jako uživatel chci organizovat poznámky podle tagů bez manuálního třídění"
- **Success metric**: User vytvoří 3+ custom folders v prvním týdnu

---

**Vytvořeno**: 2025-10-14
**Autor**: Claude Code
**Status**: 📋 Design Document - Ready for implementation

---

## 🔗 Related Documents

- [bloc.md](bloc.md) - BLoC best practices pro tento projekt
- [mapa-bloc.md](mapa-bloc.md) - Decision tree pro implementaci
- [notes-para.md](notes-para.md) - Notes + PARA System design

---

**Next Steps:**
1. Review design document s týmem
2. Approve database schema
3. Start Phase 1: Database + Models
4. Iterate based on user feedback

🚀 Let's build Smart Folders!
