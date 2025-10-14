# Oprava Smart Folders - podle Custom Agenda Views principu

## 🎯 Cíl
Předělat Smart Folders implementaci tak, aby byla **identická** s Custom Agenda Views pro TODO.

## 📋 Co mám teď (ŠPATNĚ)
1. ❌ Separátní stránka `SmartFolderSettingsPage`
2. ❌ Bottom sheet `SmartFolderFormSheet` s hardcoded emoji list
3. ❌ Složitý `FilterRules` model s různými typy filtrů
4. ❌ Database model s `is_system`, `filter_rules` JSON, `display_order`
5. ❌ CRUD v NotesBloc (CreateSmartFolderEvent, UpdateSmartFolderEvent, DeleteSmartFolderEvent)

## ✅ Co mám udělat (SPRÁVNĚ)
1. ✅ Tab v Settings (jako Agenda Tab)
2. ✅ Dialog s full emoji pickerem (package `emoji_picker_flutter`)
3. ✅ Jednoduchý model - pouze **název** + **tag filter** + **emoji** (jako CustomAgendaView)
4. ✅ Built-in folders jako toggles v settings (show_all_notes, show_recent_notes)
5. ✅ CRUD v SettingsCubit (ne v NotesBloc!)

---

## 📐 Nová architektura

### 1. Database Schema

**Stará tabulka (SMAZAT):**
```sql
CREATE TABLE note_smart_folders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  is_system INTEGER DEFAULT 0,
  filter_rules TEXT NOT NULL,  -- ❌ Zbytečně složité!
  display_order INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Nová tabulka (JEDNODUCHÁ):**
```sql
CREATE TABLE custom_notes_views (
  id TEXT PRIMARY KEY,           -- UUID (jako custom_agenda_views)
  name TEXT NOT NULL,            -- "Projekty"
  tag_filter TEXT NOT NULL,      -- "projekt" (bez oddělovačů!)
  emoji TEXT NOT NULL DEFAULT '📁',
  sort_order INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,   -- milliseconds

  CHECK (LENGTH(name) > 0),
  CHECK (LENGTH(tag_filter) > 0)
)
```

**Built-in views v settings tabulce:**
```sql
ALTER TABLE settings ADD COLUMN show_all_notes INTEGER NOT NULL DEFAULT 1;
ALTER TABLE settings ADD COLUMN show_recent_notes INTEGER NOT NULL DEFAULT 1;
```

### 2. Domain Model

**SMAZAT:**
- `lib/features/notes/domain/models/smart_folder.dart`
- `lib/features/notes/domain/models/filter_rules.dart`

**VYTVOŘIT:**
```dart
// lib/features/notes/domain/models/custom_notes_view.dart
class CustomNotesView extends Equatable {
  final String id;           // UUID
  final String name;         // "Projekty"
  final String tagFilter;    // "projekt"
  final String emoji;        // "📁"
  final int sortOrder;
  final bool isEnabled;

  const CustomNotesView({
    required this.id,
    required this.name,
    required this.tagFilter,
    required this.emoji,
    this.sortOrder = 0,
    this.isEnabled = true,
  });

  // JSON serialization pro DB
  Map<String, dynamic> toJson() { ... }
  factory CustomNotesView.fromJson(Map<String, dynamic> json) { ... }
  CustomNotesView copyWith(...) { ... }
}
```

```dart
// lib/features/notes/domain/models/notes_view_config.dart
class NotesViewConfig extends Equatable {
  final bool showAllNotes;        // Toggle v settings
  final bool showRecentNotes;     // Toggle v settings
  final List<CustomNotesView> customViews;

  const NotesViewConfig({
    this.showAllNotes = true,
    this.showRecentNotes = true,
    this.customViews = const [],
  });

  NotesViewConfig copyWith(...) { ... }
}
```

### 3. SettingsCubit - přidat Notes Views

**Rozšířit SettingsState:**
```dart
class SettingsLoaded extends SettingsState {
  // Existing...
  final AgendaViewConfig agendaConfig;

  // NEW: Notes Views
  final NotesViewConfig notesConfig;

  const SettingsLoaded({
    // ...
    required this.agendaConfig,
    required this.notesConfig,  // ← NOVÝ
  });
}
```

**Přidat metody do SettingsCubit:**
```dart
// Built-in toggles
Future<void> toggleBuiltInNotesView(String viewName, bool enabled) async {
  // viewName: 'all_notes' nebo 'recent_notes'
  await _db.updateBuiltInNotesViewSettings(
    showAllNotes: viewName == 'all_notes' ? enabled : null,
    showRecentNotes: viewName == 'recent_notes' ? enabled : null,
  );
  await loadSettings();
}

// Custom views CRUD
Future<void> addCustomNotesView(CustomNotesView view) async {
  await _db.insertCustomNotesView(view.toJson());
  await loadSettings();
}

Future<void> updateCustomNotesView(CustomNotesView view) async {
  await _db.updateCustomNotesView(view.id, view.toJson());
  await loadSettings();
}

Future<void> deleteCustomNotesView(String id) async {
  await _db.deleteCustomNotesView(id);
  await loadSettings();
}

Future<void> toggleCustomNotesView(String id, bool enabled) async {
  await _db.toggleCustomNotesView(id, enabled);
  await loadSettings();
}
```

### 4. Database Helper - CRUD metody

**SMAZAT:**
- `getAllSmartFolders()`
- `getSmartFolderById()`
- `insertSmartFolder()`
- `updateSmartFolder()`
- `deleteSmartFolder()`
- `_seedDefaultSmartFolders()`

**PŘIDAT:**
```dart
// ==================== CUSTOM NOTES VIEWS CRUD ====================

Future<List<Map<String, dynamic>>> getAllCustomNotesViews() async {
  final db = await database;
  return await db.query('custom_notes_views', orderBy: 'sort_order ASC');
}

Future<List<Map<String, dynamic>>> getEnabledCustomNotesViews() async {
  final db = await database;
  return await db.query(
    'custom_notes_views',
    where: 'enabled = ?',
    whereArgs: [1],
    orderBy: 'sort_order ASC',
  );
}

Future<void> insertCustomNotesView(Map<String, dynamic> view) async {
  final db = await database;
  await db.insert('custom_notes_views', view);
}

Future<void> updateCustomNotesView(String id, Map<String, dynamic> view) async {
  final db = await database;
  await db.update(
    'custom_notes_views',
    view,
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> deleteCustomNotesView(String id) async {
  final db = await database;
  await db.delete('custom_notes_views', where: 'id = ?', whereArgs: [id]);
}

Future<void> toggleCustomNotesView(String id, bool enabled) async {
  final db = await database;
  await db.update(
    'custom_notes_views',
    {'enabled': enabled ? 1 : 0},
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> updateBuiltInNotesViewSettings({
  bool? showAllNotes,
  bool? showRecentNotes,
}) async {
  final db = await database;
  final updates = <String, dynamic>{};

  if (showAllNotes != null) updates['show_all_notes'] = showAllNotes ? 1 : 0;
  if (showRecentNotes != null) updates['show_recent_notes'] = showRecentNotes ? 1 : 0;

  if (updates.isNotEmpty) {
    await db.update('settings', updates, where: 'id = 1');
  }
}
```

### 5. NotesBloc - zjednodušení

**SMAZAT eventy:**
- `CreateSmartFolderEvent`
- `UpdateSmartFolderEvent`
- `DeleteSmartFolderEvent`

**Pozměnit ChangeSmartFolderEvent → ChangeNotesViewModeEvent:**
```dart
// Místo SmartFolder objektu používat ViewMode + customViewId
enum NotesViewMode {
  allNotes,      // Built-in
  recentNotes,   // Built-in (7 dní)
  custom,        // Custom view (podle customViewId)
}

class ChangeNotesViewModeEvent extends NotesEvent {
  final NotesViewMode mode;
  final String? customViewId;  // Pokud mode=custom

  const ChangeNotesViewModeEvent(this.mode, {this.customViewId});
}

// NEBO alternativně:
class ChangeToCustomNotesViewEvent extends NotesEvent {
  final CustomNotesView view;
  const ChangeToCustomNotesViewEvent(this.view);
}
```

**NotesState:**
```dart
class NotesLoaded extends NotesState {
  final List<Note> notes;
  final NotesViewMode viewMode;
  final String? currentCustomViewId;  // Pokud viewMode=custom
  final int? expandedNoteId;

  // Computed property
  List<Note> get displayedNotes {
    // Filtrování podle viewMode + customViewId
  }
}
```

### 6. FoldersTabBar - renderování z SettingsCubit

**Změnit:**
```dart
class FoldersTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        if (settingsState is! SettingsLoaded) {
          return _buildFallbackBar();
        }

        final notesConfig = settingsState.notesConfig;
        final visibleViews = <_ViewItem>[];

        // Built-in views
        if (notesConfig.showAllNotes) {
          visibleViews.add(_ViewItem.builtIn(NotesViewMode.allNotes));
        }
        if (notesConfig.showRecentNotes) {
          visibleViews.add(_ViewItem.builtIn(NotesViewMode.recentNotes));
        }

        // Custom views (pouze enabled)
        for (final customView in notesConfig.customViews) {
          if (customView.isEnabled) {
            visibleViews.add(_ViewItem.custom(customView));
          }
        }

        return _buildViewBar(context, visibleViews);
      },
    );
  }
}
```

### 7. Settings Page - Nový Tab

**SMAZAT:**
- `lib/features/notes/presentation/pages/smart_folder_settings_page.dart`
- `lib/features/notes/presentation/widgets/smart_folder_form_sheet.dart`

**VYTVOŘIT:**
```dart
// lib/features/settings/presentation/pages/notes_tab.dart
class NotesTab extends StatelessWidget {
  // Kopírovat strukturu z AgendaTab!

  // 1. Built-in views section s toggles:
  //    - 📝 Všechny poznámky (showAllNotes)
  //    - 🕐 Poslední týden (showRecentNotes)

  // 2. Custom views section:
  //    - Add button
  //    - Seznam custom views (emoji, název, tag filter)
  //    - Edit/Delete buttons
  //    - Enable/Disable switch

  // 3. Dialog s emoji pickerem (emoji_picker_flutter)
}
```

### 8. Database Migration

**Přidat novou verzi 21:**
```dart
if (oldVersion < 21) {
  // 1. Drop stará tabulka note_smart_folders
  await db.execute('DROP TABLE IF EXISTS note_smart_folders');

  // 2. Vytvořit novou tabulku custom_notes_views
  await db.execute('''
    CREATE TABLE custom_notes_views (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      tag_filter TEXT NOT NULL,
      emoji TEXT NOT NULL DEFAULT '📁',
      sort_order INTEGER NOT NULL DEFAULT 0,
      enabled INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL,

      CHECK (LENGTH(name) > 0),
      CHECK (LENGTH(tag_filter) > 0)
    )
  ''');

  await db.execute('CREATE INDEX idx_custom_notes_views_enabled ON custom_notes_views(enabled)');
  await db.execute('CREATE INDEX idx_custom_notes_views_sort ON custom_notes_views(sort_order)');

  // 3. Přidat built-in toggles do settings
  await db.execute('ALTER TABLE settings ADD COLUMN show_all_notes INTEGER NOT NULL DEFAULT 1');
  await db.execute('ALTER TABLE settings ADD COLUMN show_recent_notes INTEGER NOT NULL DEFAULT 1');
}
```

---

## 📝 Implementační kroky

### Krok 1: Database (30 min)
1. Přidat verzi 21 do `_onUpgrade()`
2. Drop stará tabulka `note_smart_folders`
3. Vytvořit `custom_notes_views` tabulku
4. Přidat `show_all_notes`, `show_recent_notes` do settings
5. Implementovat CRUD metody

### Krok 2: Domain Models (20 min)
1. Smazat `smart_folder.dart`, `filter_rules.dart`
2. Vytvořit `custom_notes_view.dart` (kopie CustomAgendaView)
3. Vytvořit `notes_view_config.dart`

### Krok 3: SettingsCubit (30 min)
1. Rozšířit `SettingsLoaded` o `notesConfig`
2. Implementovat CRUD metody pro notes views
3. Načítat custom_notes_views v `loadSettings()`

### Krok 4: NotesBloc zjednodušení (20 min)
1. Smazat CRUD eventy/handlers
2. Změnit `ChangeSmartFolderEvent` na `ChangeNotesViewModeEvent`
3. Upravit `NotesState` (viewMode + customViewId místo SmartFolder objektu)
4. Zjednodušit `displayedNotes` computed property

### Krok 5: FoldersTabBar refactor (30 min)
1. Přepsat na `BlocBuilder<SettingsCubit>`
2. Renderovat z `settingsState.notesConfig`
3. Stejná logika jako ViewBar pro TODO

### Krok 6: Settings Tab (60 min)
1. Vytvořit `notes_tab.dart`
2. Zkopírovat strukturu z `agenda_tab.dart`
3. Built-in views toggles
4. Custom views CRUD s emoji pickerem
5. Přidat do `settings_page.dart`

### Krok 7: Cleanup (15 min)
1. Smazat staré soubory
2. Odstranit import `folder_mode.dart`
3. Update `settings_page.dart` (remove NOTES SLOŽKY tab)
4. Git commit

---

## ✅ Checklist

- [x] Database verze 21 + migrace ✅ (commit: 94eb116)
- [x] Vytvořit nové modely (custom_notes_view, notes_view_config) ✅ (commit: 94eb116)
- [x] DatabaseHelper - CRUD pro custom_notes_views ✅ (commit: 94eb116)
- [x] SettingsState - rozšířit o notesConfig ✅ (commit: 94eb116)
- [ ] SettingsCubit - přidat CRUD metody pro Notes Views ⏳ (in progress)
- [ ] SettingsCubit - načítat notesConfig v loadSettings() ⏳ (in progress)
- [ ] Smazat staré modely (smart_folder, filter_rules)
- [ ] NotesBloc - zjednodušit (smazat CRUD eventy)
- [ ] FoldersTabBar - renderovat z SettingsCubit
- [ ] NotesTab - nový tab v Settings (kopie AgendaTab)
- [ ] Smazat staré soubory (SmartFolderSettingsPage, SmartFolderFormSheet)
- [ ] Remove "NOTES SLOŽKY" tab z settings_page.dart
- [ ] Git commit + test

---

## 📊 Progress Log

### 🚀 Session 1 (2025-10-14 - Claude Code)

**Commit: `94eb116` - WIP: Smart Folders → Custom Notes Views refactoring (částečný)**

✅ **Hotovo:**
1. Database migrace verze 21
   - Dropnuta `note_smart_folders` tabulka
   - Vytvořena `custom_notes_views` (identická s `custom_agenda_views`)
   - Přidány `show_all_notes`, `show_recent_notes` do `settings`

2. Domain modely vytvořeny
   - `lib/features/notes/domain/models/custom_notes_view.dart`
   - `lib/features/notes/domain/models/notes_view_config.dart`

3. DatabaseHelper CRUD metody
   - `getAllCustomNotesViews()`
   - `getEnabledCustomNotesViews()`
   - `insertCustomNotesView()`
   - `updateCustomNotesView()`
   - `deleteCustomNotesView()`
   - `toggleCustomNotesView()`
   - `updateBuiltInNotesViewSettings()`
   - Smazány staré Smart Folders CRUD metody

4. SettingsState rozšířen
   - Přidán `notesConfig: NotesViewConfig`
   - Import `notes_view_config.dart`
   - copyWith aktualizováno
   - props rozšířeny

⏳ **Zbývá (pro další session):**
1. SettingsCubit - dokončit
   - Přidat `_loadNotesConfig()` metodu
   - Přidat `toggleBuiltInNotesView()` metodu
   - Přidat `addCustomNotesView()`, `updateCustomNotesView()`, `deleteCustomNotesView()`, `toggleCustomNotesView()` metody
   - Volat `notesConfig` v `loadSettings()`

2. Smazat staré soubory
   - `lib/features/notes/domain/models/smart_folder.dart`
   - `lib/features/notes/domain/models/filter_rules.dart`
   - `lib/features/notes/presentation/pages/smart_folder_settings_page.dart`
   - `lib/features/notes/presentation/widgets/smart_folder_form_sheet.dart`

3. NotesBloc zjednodušení
   - Smazat `CreateSmartFolderEvent`, `UpdateSmartFolderEvent`, `DeleteSmartFolderEvent`
   - Změnit `ChangeSmartFolderEvent` → `ChangeNotesViewModeEvent`
   - Upravit `NotesState` (ViewMode místo SmartFolder objektu)

4. FoldersTabBar refaktor
   - Přepsat na `BlocBuilder<SettingsCubit>`
   - Renderovat z `settingsState.notesConfig`

5. NotesTab v Settings
   - Vytvořit `lib/features/settings/presentation/pages/notes_tab.dart`
   - Zkopírovat strukturu z `agenda_tab.dart`
   - Přidat do `settings_page.dart` jako nový tab

6. Finální cleanup + test
   - Odstranit "NOTES SLOŽKY" tab ze `settings_page.dart`
   - Commit + test kompilace

**Token budget na konci session:** 73k/200k (doporučuji novou konverzaci)

---

## 🎯 Výsledek

**Stejná logika jako Custom Agenda Views:**
1. Built-in views = toggles v settings (All Notes, Recent)
2. Custom views = tag-based filtering (+ emoji picker)
3. CRUD v SettingsCubit (ne v NotesBloc!)
4. FoldersTabBar renderuje z SettingsCubit
5. Settings Tab s DialogUI (ne separátní page)

**Jednodušší, konzistentnější, maintainovatelné!** ✨
