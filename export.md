# Export.md - Markdown Export Feature

## 🎯 Koncept

**Automatický export TODO + Notes do Markdown souborů** s podporou dvou formátů:
1. **Výchozí** - náš custom formát s oddělovači `*tag*`, `*a*`, `*#123*`
2. **Obsidian** - standardní markdown s frontmatter, `#hashtags`, backlinks `[[Note]]`

### 📐 Struktura exportovaných souborů

```
[User-selected directory]/
├── tasks/
│   ├── Dokoncit_prezentaci_pro_klienta.md
│   ├── Napsat_email_managerovi.md
│   └── Uklidit_stul.md
└── notes/
    ├── Note-15.md
    ├── Note-23.md
    └── Note-42.md
```

---

## 🗺️ Milestones Overview

| Milestone | Čas | Popis |
|-----------|-----|-------|
| **MILESTONE 1** | 3-4h | Markdown formatter + File writer služby |
| **MILESTONE 2** | 2h | Settings UI + Directory picker |
| **MILESTONE 3** | 1.5h | Repository + Integrace do BLoC |
| **Celkem** | **6.5-7.5h** | Kompletní implementace |

**Token Budget Strategy**: Po každém milestone commit + pause → nová konverzace pokud potřeba

---

## 📦 Dependencies

### Balíčky (již v projektu):
- ✅ `file_picker: ^8.1.4` - výběr cílové složky
- ✅ `path_provider: ^2.1.5` - app documents directory

### Nové balíčky (OPTIONAL):
- ⚠️ `permission_handler` - pouze pro starší Android (≤10)
  - Android 11+ používá SAF (Storage Access Framework) - **žádné permissions!**

---

## 📁 Architektura

```
lib/features/markdown_export/
├── domain/
│   ├── entities/
│   │   ├── export_format.dart           # Enum: default, obsidian
│   │   └── export_config.dart           # Config entita
│   ├── repositories/
│   │   └── markdown_export_repository.dart
│   └── services/
│       ├── markdown_formatter_service.dart  # Format converter
│       └── file_writer_service.dart         # File I/O
├── data/
│   ├── repositories/
│   │   └── markdown_export_repository_impl.dart
│   └── datasources/
│       └── markdown_export_datasource.dart
└── presentation/
    └── widgets/
        └── export_settings_section.dart  # Settings UI widget
```

---

## 🏗️ MILESTONE 1: Formatter + File Writer (3-4h)

### 1.1 Domain Entities (30 min)

#### `lib/features/markdown_export/domain/entities/export_format.dart`
```dart
/// Export formát pro markdown soubory
enum ExportFormat {
  /// Výchozí formát - náš custom syntax s oddělovači *tag*
  default_,

  /// Obsidian formát - frontmatter + #hashtags + [[backlinks]]
  obsidian,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.default_:
        return 'Výchozí (vlastní tagy)';
      case ExportFormat.obsidian:
        return 'Obsidian (frontmatter)';
    }
  }
}
```

#### `lib/features/markdown_export/domain/entities/export_config.dart`
```dart
import 'package:equatable/equatable.dart';
import 'export_format.dart';

/// Konfigurace pro markdown export
class ExportConfig extends Equatable {
  /// Cílová složka pro export (user-selected)
  final String? targetDirectory;

  /// Formát exportu (default / obsidian)
  final ExportFormat format;

  /// Exportovat TODO úkoly?
  final bool exportTodos;

  /// Exportovat Notes poznámky?
  final bool exportNotes;

  /// Automatický export při každém uložení?
  final bool autoExportOnSave;

  const ExportConfig({
    this.targetDirectory,
    this.format = ExportFormat.default_,
    this.exportTodos = true,
    this.exportNotes = true,
    this.autoExportOnSave = false,
  });

  /// Default config (žádná složka vybraná)
  const ExportConfig.initial()
      : targetDirectory = null,
        format = ExportFormat.default_,
        exportTodos = true,
        exportNotes = true,
        autoExportOnSave = false;

  ExportConfig copyWith({
    String? targetDirectory,
    ExportFormat? format,
    bool? exportTodos,
    bool? exportNotes,
    bool? autoExportOnSave,
  }) {
    return ExportConfig(
      targetDirectory: targetDirectory ?? this.targetDirectory,
      format: format ?? this.format,
      exportTodos: exportTodos ?? this.exportTodos,
      exportNotes: exportNotes ?? this.exportNotes,
      autoExportOnSave: autoExportOnSave ?? this.autoExportOnSave,
    );
  }

  @override
  List<Object?> get props => [
        targetDirectory,
        format,
        exportTodos,
        exportNotes,
        autoExportOnSave,
      ];
}
```

---

### 1.2 Markdown Formatter Service (1.5h)

#### `lib/features/markdown_export/domain/services/markdown_formatter_service.dart`

**Zodpovědnosti**:
- Konverze TODO → Markdown (2 formáty)
- Konverze Note → Markdown (2 formáty)
- Extrakce tagů, note links, date tags
- Sanitizace textu pro markdown

**Klíčové metody**:

```dart
class MarkdownFormatterService {
  // ==================== TODO FORMATTING ====================

  /// Konvertuje TODO do markdown formátu
  String formatTodo(Todo todo, ExportFormat format) {
    if (format == ExportFormat.obsidian) {
      return _formatTodoObsidian(todo);
    }
    return _formatTodoDefault(todo);
  }

  /// Obsidian formát TODO s frontmatter
  String _formatTodoObsidian(Todo todo) {
    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('id: ${todo.id}');
    buffer.writeln('created: ${_formatIso8601(todo.createdAt)}');

    if (todo.dueDate != null) {
      buffer.writeln('due: ${_formatIso8601(todo.dueDate!)}');
    }

    if (todo.priority != null) {
      buffer.writeln('priority: ${todo.priority}');
    }

    if (todo.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in todo.tags) {
        buffer.writeln('  - $tag');  // YAML array
      }
    }

    buffer.writeln('completed: ${todo.isCompleted}');
    buffer.writeln('---');
    buffer.writeln();

    // Task checkbox (Obsidian syntax: - [ ] nebo - [x])
    buffer.write(todo.isCompleted ? '- [x] ' : '- [ ] ');

    // Task text (escape markdown special chars)
    buffer.writeln(_escapeMarkdown(todo.task));
    buffer.writeln();

    // Tags jako hashtags (Obsidian inline tags)
    if (todo.tags.isNotEmpty) {
      buffer.writeln(todo.tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }

    // Backlinks pro linked note IDs (konverze *#123* → [[Note-123]])
    final noteLinks = _extractNoteLinks(todo.task);
    if (noteLinks.isNotEmpty) {
      buffer.writeln('## Linked Notes');
      for (final noteId in noteLinks) {
        buffer.writeln('- [[Note-$noteId]]');
      }
    }

    return buffer.toString();
  }

  /// Výchozí formát TODO (náš custom syntax)
  String _formatTodoDefault(Todo todo) {
    final buffer = StringBuffer();

    // Checkbox
    buffer.write(todo.isCompleted ? '[x] ' : '[ ] ');

    // Task text (ponechat original s našimi tagy)
    buffer.write(todo.task);

    // Priority tag
    if (todo.priority != null) {
      buffer.write(' *${todo.priority}*');
    }

    // Date tag
    if (todo.dueDate != null) {
      final dateStr = _formatDateTag(todo.dueDate!);
      buffer.write(' *$dateStr*');
    }

    // Custom tags
    for (final tag in todo.tags) {
      buffer.write(' *$tag*');
    }

    buffer.writeln();
    return buffer.toString();
  }

  // ==================== NOTE FORMATTING ====================

  /// Konvertuje Note do markdown formátu
  String formatNote(Note note, ExportFormat format) {
    if (format == ExportFormat.obsidian) {
      return _formatNoteObsidian(note);
    }
    return _formatNoteDefault(note);
  }

  /// Obsidian formát Note s frontmatter
  String _formatNoteObsidian(Note note) {
    final buffer = StringBuffer();

    // YAML Frontmatter
    buffer.writeln('---');
    buffer.writeln('id: ${note.id}');
    buffer.writeln('title: ${_escapeYaml(note.displayTitle)}');
    buffer.writeln('created: ${_formatIso8601(note.createdAt)}');

    if (note.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in note.tags) {
        buffer.writeln('  - $tag');
      }
    }

    buffer.writeln('---');
    buffer.writeln();

    // Note title jako H1
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();

    // Note content
    buffer.writeln(note.content);
    buffer.writeln();

    // Tags jako hashtags
    if (note.tags.isNotEmpty) {
      buffer.writeln(note.tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }

    // Backlinks (TODO IDs + Note IDs)
    final todoLinks = _extractTodoLinks(note.content);
    final noteLinks = _extractNoteLinks(note.content);

    if (todoLinks.isNotEmpty || noteLinks.isNotEmpty) {
      buffer.writeln('## Backlinks');

      for (final todoId in todoLinks) {
        buffer.writeln('- [[TODO-$todoId]]');
      }

      for (final noteId in noteLinks) {
        buffer.writeln('- [[Note-$noteId]]');
      }
    }

    return buffer.toString();
  }

  /// Výchozí formát Note (náš custom syntax)
  String _formatNoteDefault(Note note) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();

    // Content (ponechat original s našimi tagy)
    buffer.writeln(note.content);
    buffer.writeln();

    // Tags
    if (note.tags.isNotEmpty) {
      buffer.write('Tags: ');
      buffer.writeln(note.tags.map((t) => '*$t*').join(' '));
    }

    return buffer.toString();
  }

  // ==================== HELPER METHODS ====================

  /// Extrahuje TODO link IDs z textu (*@123* → [123])
  List<int> _extractTodoLinks(String text) {
    final regex = RegExp(r'\*@(\d+)\*');
    return regex.allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .toList();
  }

  /// Extrahuje Note link IDs z textu (*#123* → [123])
  List<int> _extractNoteLinks(String text) {
    final regex = RegExp(r'\*#(\d+)\*');
    return regex.allMatches(text)
        .map((m) => int.parse(m.group(1)!))
        .toList();
  }

  /// Escape markdown special characters
  String _escapeMarkdown(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('*', '\\*')
        .replaceAll('_', '\\_')
        .replaceAll('[', '\\[')
        .replaceAll(']', '\\]')
        .replaceAll('`', '\\`');
  }

  /// Escape YAML string (pro frontmatter)
  String _escapeYaml(String text) {
    if (text.contains(':') || text.contains('#') || text.contains('-')) {
      return '"${text.replaceAll('"', '\\"')}"';
    }
    return text;
  }

  /// Formátuje DateTime do ISO 8601 (pro Obsidian)
  String _formatIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Formátuje datum do našeho date tagu (DD.MM.YYYY HH:MM)
  String _formatDateTag(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
```

**Příklady výstupu**:

**TODO (Obsidian formát)**:
```markdown
---
id: 42
created: 2025-10-16T10:30:00Z
due: 2025-10-17T14:00:00Z
priority: a
tags:
  - work
  - urgent
completed: false
---

- [ ] Dokončit prezentaci pro klienta

#work #urgent

## Linked Notes
- [[Note-15]]
- [[Note-23]]
```

**TODO (Výchozí formát)**:
```markdown
[ ] Dokončit prezentaci pro klienta *a* *17.10.2025 14:00* *work* *urgent* *#15* *#23*
```

**Note (Obsidian formát)**:
```markdown
---
id: 15
title: Meeting notes - Q4 Planning
created: 2025-10-15T09:00:00Z
tags:
  - meeting
  - planning
---

# Meeting notes - Q4 Planning

## Agenda
- Review Q3 results
- Plan Q4 objectives

#meeting #planning

## Backlinks
- [[TODO-42]]
- [[Note-23]]
```

**Note (Výchozí formát)**:
```markdown
# Meeting notes - Q4 Planning

## Agenda
- Review Q3 results
- Plan Q4 objectives

Tags: *meeting* *planning*
```

---

### 1.3 File Writer Service (1h)

#### `lib/features/markdown_export/domain/services/file_writer_service.dart`

**Zodpovědnosti**:
- Zápis markdown do souborů
- Vytvoření složek `tasks/` a `notes/`
- Sanitizace názvů souborů
- Error handling (permissions, disk space, etc.)

```dart
import 'dart:io';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../notes/domain/entities/note.dart';

class FileWriterService {
  /// Zapíše TODO jako markdown soubor
  ///
  /// File path: {targetDirectory}/tasks/{sanitized_task_name}.md
  Future<void> writeTodoFile({
    required String targetDirectory,
    required Todo todo,
    required String markdownContent,
  }) async {
    try {
      // Sanitizovat název souboru
      final fileName = _sanitizeFileName(todo.task);
      final filePath = '$targetDirectory/tasks/$fileName.md';

      // Vytvořit tasks/ složku pokud neexistuje
      final file = File(filePath);
      await file.create(recursive: true);

      // Zapsat markdown content
      await file.writeAsString(markdownContent, encoding: utf8);
    } catch (e) {
      throw FileWriterException('Failed to write TODO file: $e');
    }
  }

  /// Zapíše Note jako markdown soubor
  ///
  /// File path: {targetDirectory}/notes/Note-{id}.md
  Future<void> writeNoteFile({
    required String targetDirectory,
    required Note note,
    required String markdownContent,
  }) async {
    try {
      // Název souboru: Note-{id}.md
      final fileName = 'Note-${note.id}';
      final filePath = '$targetDirectory/notes/$fileName.md';

      // Vytvořit notes/ složku pokud neexistuje
      final file = File(filePath);
      await file.create(recursive: true);

      // Zapsat markdown content
      await file.writeAsString(markdownContent, encoding: utf8);
    } catch (e) {
      throw FileWriterException('Failed to write Note file: $e');
    }
  }

  /// Vymaže všechny exportované soubory (pro clean re-export)
  Future<void> clearExportedFiles(String targetDirectory) async {
    try {
      final tasksDir = Directory('$targetDirectory/tasks');
      final notesDir = Directory('$targetDirectory/notes');

      if (await tasksDir.exists()) {
        await tasksDir.delete(recursive: true);
      }

      if (await notesDir.exists()) {
        await notesDir.delete(recursive: true);
      }
    } catch (e) {
      throw FileWriterException('Failed to clear exported files: $e');
    }
  }

  /// Sanitizuje název souboru (odstraní nepovolené znaky)
  ///
  /// - Vezme prvních 50 znaků
  /// - Odstraní speciální znaky: < > : " / \ | ? *
  /// - Trim whitespace
  /// - Fallback: 'untitled' pokud je prázdný
  String _sanitizeFileName(String text) {
    // Vezmi prvních 50 znaků
    final truncated = text.length > 50
        ? text.substring(0, 50)
        : text;

    // Odstraň nepovolené znaky pro file system
    final sanitized = truncated
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')  // Whitespace → underscore
        .trim();

    // Fallback pokud je prázdný
    return sanitized.isEmpty ? 'untitled' : sanitized;
  }
}

/// Custom exception pro file writer errors
class FileWriterException implements Exception {
  final String message;

  FileWriterException(this.message);

  @override
  String toString() => 'FileWriterException: $message';
}
```

**Příklady sanitizovaných názvů**:
- `"Dokončit prezentaci pro klienta"` → `Dokoncit_prezentaci_pro_klienta.md`
- `"Meeting: Q4 Planning (urgent!)"` → `Meeting_Q4_Planning_urgent.md`
- `"Email → manager [ASAP]"` → `Email_manager_ASAP.md`

---

### 1.4 Checklist MILESTONE 1 ✅

Po dokončení tohoto milestonu:

- [ ] Vytvořena složka `lib/features/markdown_export/`
- [ ] Domain entities: `export_format.dart`, `export_config.dart`
- [ ] Service: `markdown_formatter_service.dart` (TODO + Note, 2 formáty)
- [ ] Service: `file_writer_service.dart` (file I/O + sanitization)
- [ ] Unit testy formatter service (validace Obsidian frontmatter)
- [ ] Snapshot commit

```bash
git add -A && git commit -m "🔖 snapshot: Před implementací Markdown Export Milestone 1"
# ... implementace ...
git add -A && git commit -m "✨ feat: Markdown Export - Formatter + File Writer services

- MarkdownFormatterService: 2 formáty (default/obsidian)
- Obsidian frontmatter, hashtags, backlinks support
- FileWriterService: write tasks/ a notes/ folders
- Sanitizace názvů souborů

MILESTONE 1/3 dokončen (3.5h)
"
```

---

## 🏗️ MILESTONE 2: Settings UI + Directory Picker (2h)

### 2.1 Extend SettingsState (30 min)

#### `lib/features/settings/presentation/cubit/settings_state.dart`

Přidat `exportConfig` do SettingsState:

```dart
class SettingsLoaded extends SettingsState {
  // Existing fields...
  final ExportConfig exportConfig;  // NEW

  const SettingsLoaded({
    // Existing params...
    this.exportConfig = const ExportConfig.initial(),  // Default
  });

  @override
  SettingsLoaded copyWith({
    // Existing params...
    ExportConfig? exportConfig,
  }) {
    return SettingsLoaded(
      // Existing params...
      exportConfig: exportConfig ?? this.exportConfig,
    );
  }

  @override
  List<Object?> get props => [
    // Existing props...
    exportConfig,
  ];
}
```

#### `lib/features/settings/presentation/cubit/settings_cubit.dart`

Přidat metodu pro update export config:

```dart
class SettingsCubit extends Cubit<SettingsState> {
  // Existing code...

  /// Aktualizovat export konfiguraci
  Future<void> updateExportConfig(ExportConfig config) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      // Uložit do shared preferences
      await _saveExportConfig(config);

      emit(currentState.copyWith(exportConfig: config));
    } catch (e) {
      // Error handling - fallback to previous state
      emit(currentState);
    }
  }

  /// Uložit export config do SharedPreferences
  Future<void> _saveExportConfig(ExportConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('export_target_directory', config.targetDirectory ?? '');
    await prefs.setString('export_format', config.format.name);
    await prefs.setBool('export_todos', config.exportTodos);
    await prefs.setBool('export_notes', config.exportNotes);
    await prefs.setBool('export_auto_on_save', config.autoExportOnSave);
  }

  /// Načíst export config ze SharedPreferences
  Future<ExportConfig> _loadExportConfig() async {
    final prefs = await SharedPreferences.getInstance();

    final targetDir = prefs.getString('export_target_directory');
    final formatStr = prefs.getString('export_format') ?? 'default_';
    final format = ExportFormat.values.firstWhere(
      (e) => e.name == formatStr,
      orElse: () => ExportFormat.default_,
    );

    return ExportConfig(
      targetDirectory: targetDir?.isEmpty ?? true ? null : targetDir,
      format: format,
      exportTodos: prefs.getBool('export_todos') ?? true,
      exportNotes: prefs.getBool('export_notes') ?? true,
      autoExportOnSave: prefs.getBool('export_auto_on_save') ?? false,
    );
  }
}
```

---

### 2.2 Export Settings Widget (1h)

#### `lib/features/markdown_export/presentation/widgets/export_settings_section.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/entities/export_config.dart';
import '../../domain/entities/export_format.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../domain/repositories/markdown_export_repository.dart';

/// Settings sekce pro Markdown Export
///
/// Features:
/// - Directory picker (file_picker)
/// - Format dropdown (default / obsidian)
/// - Auto-export toggle
/// - Manual export button
class ExportSettingsSection extends StatelessWidget {
  const ExportSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const SizedBox.shrink();
        }

        final config = state.exportConfig;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.appColors.base3.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(
                    Icons.save_alt,
                    color: theme.appColors.cyan,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Markdown Export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Directory picker
              _buildDirectoryPicker(context, config),
              const SizedBox(height: 12),

              // Format dropdown
              _buildFormatDropdown(context, config),
              const SizedBox(height: 12),

              // Export options (TODOs, Notes)
              _buildExportOptions(context, config),
              const SizedBox(height: 12),

              // Auto-export toggle
              _buildAutoExportToggle(context, config),
              const SizedBox(height: 16),

              // Manual export button
              _buildManualExportButton(context, config),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectoryPicker(BuildContext context, ExportConfig config) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cílová složka',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.appColors.base3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  config.targetDirectory ?? 'Není vybrána složka',
                  style: TextStyle(
                    fontSize: 13,
                    color: config.targetDirectory != null
                        ? theme.appColors.fg
                        : theme.appColors.base5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final directory = await FilePicker.platform.getDirectoryPath();
                  if (directory != null) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(targetDirectory: directory),
                        );
                  }
                },
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Vybrat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appColors.cyan,
                  foregroundColor: theme.appColors.bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatDropdown(BuildContext context, ExportConfig config) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export formát',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.appColors.base3),
          ),
          child: DropdownButton<ExportFormat>(
            value: config.format,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.appColors.bgAlt,
            style: TextStyle(
              fontSize: 14,
              color: theme.appColors.fg,
            ),
            items: ExportFormat.values.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (format) {
              if (format != null) {
                context.read<SettingsCubit>().updateExportConfig(
                      config.copyWith(format: format),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportOptions(BuildContext context, ExportConfig config) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Co exportovat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: config.exportTodos,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(exportTodos: value),
                        );
                  }
                },
                title: const Text('TODO úkoly'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.appColors.cyan,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                value: config.exportNotes,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(exportNotes: value),
                        );
                  }
                },
                title: const Text('Notes poznámky'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.appColors.cyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoExportToggle(BuildContext context, ExportConfig config) {
    final theme = Theme.of(context);

    return SwitchListTile(
      value: config.autoExportOnSave,
      onChanged: (value) {
        context.read<SettingsCubit>().updateExportConfig(
              config.copyWith(autoExportOnSave: value),
            );
      },
      title: Text(
        'Automatický export při uložení',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.appColors.fg,
        ),
      ),
      subtitle: Text(
        'Export markdown souborů při každé změně TODO/Note',
        style: TextStyle(
          fontSize: 12,
          color: theme.appColors.base5,
        ),
      ),
      activeColor: theme.appColors.cyan,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildManualExportButton(BuildContext context, ExportConfig config) {
    final theme = Theme.of(context);
    final isEnabled = config.targetDirectory != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled
            ? () async {
                // Zobraz loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: theme.appColors.cyan,
                    ),
                  ),
                );

                try {
                  // Trigger manual export
                  final exportRepo = context.read<MarkdownExportRepository>();
                  await exportRepo.exportAll(config);

                  // Close loading dialog
                  Navigator.of(context).pop();

                  // Show success snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Export dokončen!'),
                      backgroundColor: theme.appColors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // Close loading dialog
                  Navigator.of(context).pop();

                  // Show error snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Export selhal: $e'),
                      backgroundColor: theme.appColors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            : null,
        icon: const Icon(Icons.download, size: 20),
        label: const Text('Exportovat vše nyní'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? theme.appColors.cyan
              : theme.appColors.base3,
          foregroundColor: theme.appColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

---

### 2.3 Integrace do SettingsPage (30 min)

#### `lib/pages/settings_page.dart`

Přidat `ExportSettingsSection` do settings page:

```dart
import '../features/markdown_export/presentation/widgets/export_settings_section.dart';

// V build() metode, přidat sekci:
ListView(
  children: [
    // Existing sections...

    // Markdown Export Section
    const ExportSettingsSection(),

    // Existing sections...
  ],
)
```

---

### 2.4 Checklist MILESTONE 2 ✅

Po dokončení tohoto milestonu:

- [ ] Extend `SettingsState` s `exportConfig`
- [ ] Extend `SettingsCubit` s `updateExportConfig()` + persistence
- [ ] Vytvořen widget `ExportSettingsSection`
- [ ] Directory picker (file_picker) funguje
- [ ] Format dropdown funguje
- [ ] Integrace do SettingsPage
- [ ] UI testováno (manual test)
- [ ] Commit

```bash
git add -A && git commit -m "✨ feat: Markdown Export - Settings UI + Directory Picker

- ExportSettingsSection widget (directory picker, format dropdown)
- Extend SettingsState/Cubit s exportConfig
- SharedPreferences persistence pro export config
- Manual export button (loading dialog + success/error feedback)

MILESTONE 2/3 dokončen (2h)
"
```

---

## 🏗️ MILESTONE 3: Repository + BLoC Integrace (1.5h)

### 3.1 Repository Interface (15 min)

#### `lib/features/markdown_export/domain/repositories/markdown_export_repository.dart`

```dart
import '../../../todo_list/domain/entities/todo.dart';
import '../../../notes/domain/entities/note.dart';
import '../entities/export_config.dart';

/// Repository pro markdown export
abstract class MarkdownExportRepository {
  /// Exportovat jeden TODO úkol
  Future<void> exportTodo(Todo todo, ExportConfig config);

  /// Exportovat jednu Note poznámku
  Future<void> exportNote(Note note, ExportConfig config);

  /// Exportovat všechny TODO + Notes (full export)
  Future<void> exportAll(ExportConfig config);
}
```

---

### 3.2 Repository Implementation (45 min)

#### `lib/features/markdown_export/data/repositories/markdown_export_repository_impl.dart`

```dart
import '../../domain/repositories/markdown_export_repository.dart';
import '../../domain/entities/export_config.dart';
import '../../domain/services/markdown_formatter_service.dart';
import '../../domain/services/file_writer_service.dart';
import '../../../todo_list/domain/repositories/todo_repository.dart';
import '../../../notes/domain/repositories/notes_repository.dart';
import '../../../todo_list/domain/entities/todo.dart';
import '../../../notes/domain/entities/note.dart';

class MarkdownExportRepositoryImpl implements MarkdownExportRepository {
  final MarkdownFormatterService _formatter;
  final FileWriterService _fileWriter;
  final TodoRepository _todoRepo;
  final NotesRepository _notesRepo;

  MarkdownExportRepositoryImpl({
    required MarkdownFormatterService formatter,
    required FileWriterService fileWriter,
    required TodoRepository todoRepo,
    required NotesRepository notesRepo,
  })  : _formatter = formatter,
        _fileWriter = fileWriter,
        _todoRepo = todoRepo,
        _notesRepo = notesRepo;

  @override
  Future<void> exportTodo(Todo todo, ExportConfig config) async {
    // Validace: targetDirectory musí být nastavený
    if (config.targetDirectory == null) {
      throw ExportException('Target directory not set in config');
    }

    if (!config.exportTodos) {
      return; // Skip pokud user zakázal TODO export
    }

    try {
      // Format todo do markdown
      final markdown = _formatter.formatTodo(todo, config.format);

      // Zapsat do souboru
      await _fileWriter.writeTodoFile(
        targetDirectory: config.targetDirectory!,
        todo: todo,
        markdownContent: markdown,
      );
    } catch (e) {
      throw ExportException('Failed to export TODO ${todo.id}: $e');
    }
  }

  @override
  Future<void> exportNote(Note note, ExportConfig config) async {
    // Validace: targetDirectory musí být nastavený
    if (config.targetDirectory == null) {
      throw ExportException('Target directory not set in config');
    }

    if (!config.exportNotes) {
      return; // Skip pokud user zakázal Notes export
    }

    try {
      // Format note do markdown
      final markdown = _formatter.formatNote(note, config.format);

      // Zapsat do souboru
      await _fileWriter.writeNoteFile(
        targetDirectory: config.targetDirectory!,
        note: note,
        markdownContent: markdown,
      );
    } catch (e) {
      throw ExportException('Failed to export Note ${note.id}: $e');
    }
  }

  @override
  Future<void> exportAll(ExportConfig config) async {
    // Validace: targetDirectory musí být nastavený
    if (config.targetDirectory == null) {
      throw ExportException('Target directory not set in config');
    }

    try {
      // Clear existující soubory (clean re-export)
      await _fileWriter.clearExportedFiles(config.targetDirectory!);

      // Export všech TODOs
      if (config.exportTodos) {
        final todos = await _todoRepo.getAllTodos();
        for (final todo in todos) {
          await exportTodo(todo, config);
        }
      }

      // Export všech Notes
      if (config.exportNotes) {
        final notes = await _notesRepo.getAllNotes();
        for (final note in notes) {
          await exportNote(note, config);
        }
      }
    } catch (e) {
      throw ExportException('Failed to export all: $e');
    }
  }
}

/// Custom exception pro export errors
class ExportException implements Exception {
  final String message;

  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}
```

---

### 3.3 DI Setup (GetIt) (15 min)

#### `lib/main.dart` nebo `lib/core/di/injection.dart`

Registrovat markdown export služby:

```dart
// Singleton services
getIt.registerLazySingleton(() => MarkdownFormatterService());
getIt.registerLazySingleton(() => FileWriterService());

// Repository
getIt.registerLazySingleton<MarkdownExportRepository>(
  () => MarkdownExportRepositoryImpl(
    formatter: getIt<MarkdownFormatterService>(),
    fileWriter: getIt<FileWriterService>(),
    todoRepo: getIt<TodoRepository>(),
    notesRepo: getIt<NotesRepository>(),
  ),
);
```

---

### 3.4 BLoC Integrace - Auto Export (30 min)

#### `lib/features/todo_list/presentation/bloc/todo_list_bloc.dart`

Přidat auto-export po Add/Update TODO:

```dart
class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final TodoRepository _repository;
  final MarkdownExportRepository _exportRepository;  // NEW
  final SettingsCubit _settingsCubit;  // NEW

  TodoListBloc(
    this._repository,
    this._exportRepository,
    this._settingsCubit,
  ) : super(const TodoListInitial()) {
    // Existing handlers...
  }

  /// Handler: Přidat nový todo (s auto-export)
  Future<void> _onAddTodo(
    AddTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ... existing validation ...

    try {
      // Vytvořit novou Todo entitu
      final newTodo = Todo(
        task: event.taskText,
        createdAt: DateTime.now(),
        priority: event.priority,
        dueDate: event.dueDate,
        tags: event.tags,
      );

      // Uložit do databáze
      await _repository.insertTodo(newTodo);

      // ✨ AUTO-EXPORT pokud je zapnutý
      await _autoExportIfEnabled(newTodo);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při přidávání úkolu: $e'));
    }
  }

  /// Handler: Aktualizovat existující todo (s auto-export)
  Future<void> _onUpdateTodo(
    UpdateTodoEvent event,
    Emitter<TodoListState> emit,
  ) async {
    // ... existing validation ...

    try {
      await _repository.updateTodo(event.todo);

      // ✨ AUTO-EXPORT pokud je zapnutý
      await _autoExportIfEnabled(event.todo);

      // Reload todos
      add(const LoadTodosEvent());
    } catch (e) {
      emit(TodoListError('Chyba při aktualizaci úkolu: $e'));
    }
  }

  /// Helper: Auto-export TODO pokud je zapnutý v settings
  Future<void> _autoExportIfEnabled(Todo todo) async {
    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is! SettingsLoaded) return;

      final exportConfig = settingsState.exportConfig;

      // Check: auto-export zapnutý + target directory nastavený
      if (exportConfig.autoExportOnSave &&
          exportConfig.targetDirectory != null &&
          exportConfig.exportTodos) {
        await _exportRepository.exportTodo(todo, exportConfig);
      }
    } catch (e) {
      // Fail silently - nebudeme blokovat hlavní operaci kvůli export erroru
      print('Auto-export failed: $e');
    }
  }
}
```

#### `lib/features/notes/presentation/bloc/notes_bloc.dart`

Analogicky přidat auto-export pro Notes:

```dart
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository _repository;
  final MarkdownExportRepository _exportRepository;  // NEW
  final SettingsCubit _settingsCubit;  // NEW

  // Analogické handlery jako TodoListBloc
  Future<void> _autoExportIfEnabled(Note note) async {
    try {
      final settingsState = _settingsCubit.state;
      if (settingsState is! SettingsLoaded) return;

      final exportConfig = settingsState.exportConfig;

      if (exportConfig.autoExportOnSave &&
          exportConfig.targetDirectory != null &&
          exportConfig.exportNotes) {
        await _exportRepository.exportNote(note, exportConfig);
      }
    } catch (e) {
      print('Auto-export failed: $e');
    }
  }
}
```

---

### 3.5 Checklist MILESTONE 3 ✅

Po dokončení tohoto milestonu:

- [ ] Repository interface + implementation
- [ ] DI setup (GetIt) pro export services
- [ ] TodoListBloc: auto-export po Add/Update
- [ ] NotesBloc: auto-export po Add/Update
- [ ] Manual export button v Settings funguje
- [ ] Error handling (try-catch, fail silently pro auto-export)
- [ ] Integration test (create TODO → check file exported)
- [ ] Commit

```bash
git add -A && git commit -m "✨ feat: Markdown Export - Repository + BLoC integrace

- MarkdownExportRepository (exportTodo, exportNote, exportAll)
- DI setup pro export services (GetIt)
- Auto-export v TodoListBloc/NotesBloc (při Add/Update)
- Manual export button funkční (loading + success/error feedback)
- Fail-safe auto-export (silent errors, neblokuje hlavní operaci)

MILESTONE 3/3 dokončen (1.5h)

🎉 Markdown Export feature COMPLETE!
"
```

---

## 📊 Příklady exportovaných souborů

### TODO v Obsidian formátu

**File**: `tasks/Dokoncit_prezentaci_pro_klienta.md`

```markdown
---
id: 42
created: 2025-10-16T10:30:00Z
due: 2025-10-17T14:00:00Z
priority: a
tags:
  - work
  - urgent
completed: false
---

- [ ] Dokončit prezentaci pro klienta

#work #urgent

## Linked Notes
- [[Note-15]]
- [[Note-23]]
```

### TODO ve výchozím formátu

**File**: `tasks/Dokoncit_prezentaci_pro_klienta.md`

```markdown
[ ] Dokončit prezentaci pro klienta *a* *17.10.2025 14:00* *work* *urgent* *#15* *#23*
```

### Note v Obsidian formátu

**File**: `notes/Note-15.md`

```markdown
---
id: 15
title: Meeting notes - Q4 Planning
created: 2025-10-15T09:00:00Z
tags:
  - meeting
  - planning
---

# Meeting notes - Q4 Planning

## Agenda
- Review Q3 results
- Plan Q4 objectives

## Action Items
- Prepare Q4 budget proposal
- Schedule team workshops

#meeting #planning

## Backlinks
- [[TODO-42]]
- [[Note-23]]
```

### Note ve výchozím formátu

**File**: `notes/Note-15.md`

```markdown
# Meeting notes - Q4 Planning

## Agenda
- Review Q3 results
- Plan Q4 objectives

## Action Items
- Prepare Q4 budget proposal
- Schedule team workshops

Tags: *meeting* *planning*
```

---

## 🔧 Android Permissions (KRITICKÉ!)

### Android 11+ (SAF - Storage Access Framework)

**DOBRÉ ZPRÁVY**: Od Android 11 `file_picker.getDirectoryPath()` používá **SAF** → **žádné runtime permissions nejsou potřeba!**

User vybere složku přes systémový picker → app dostane **persistent URI permission** automaticky.

### Android ≤10 (Legacy Storage)

Pro starší Android verze přidat do `AndroidManifest.xml`:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
      android:maxSdkVersion="28" />
</manifest>
```

**Poznámka**: `maxSdkVersion="28"` znamená že permission platí pouze pro Android ≤9 (API 28).

---

## 🚨 CRITICAL RULES

### 1. ❌ Nepřepisovat existující soubory → ✅ Clean re-export
- Při `exportAll()` nejdřív smazat `tasks/` a `notes/` složky
- Pak vytvořit fresh export všech úkolů

### 2. ❌ Blokovací auto-export → ✅ Fail silently
- Auto-export nesmí blokovat hlavní operaci (Add/Update TODO)
- Try-catch kolem `_autoExportIfEnabled()` - logovat error, ale pokračovat

### 3. ❌ Duplikátní názvy souborů → ✅ Sanitizace
- `_sanitizeFileName()` musí odstranit nepovolené znaky
- Pokud 2 úkoly mají stejný název (po sanitizaci) → druhý přepíše první (OK)

### 4. ❌ Nekontrolovaný target directory → ✅ Validace
- Před každým exportem zkontrolovat `config.targetDirectory != null`
- Throw `ExportException` pokud není nastavený

### 5. ❌ Zapomenout na UTF-8 encoding → ✅ Explicitní encoding
- `file.writeAsString(content, encoding: utf8)`

---

## 📋 TODO Seznam pro Implementaci

### MILESTONE 1: Formatter + File Writer (3-4h)
- [ ] 🔖 Snapshot commit
- [ ] Vytvořit složku `lib/features/markdown_export/`
- [ ] Entity: `export_format.dart`
- [ ] Entity: `export_config.dart`
- [ ] Service: `markdown_formatter_service.dart`
  - [ ] `formatTodo()` - Obsidian formát
  - [ ] `formatTodo()` - Výchozí formát
  - [ ] `formatNote()` - Obsidian formát
  - [ ] `formatNote()` - Výchozí formát
  - [ ] Helper: `_extractNoteLinks()`, `_extractTodoLinks()`
  - [ ] Helper: `_escapeMarkdown()`, `_escapeYaml()`
- [ ] Service: `file_writer_service.dart`
  - [ ] `writeTodoFile()`
  - [ ] `writeNoteFile()`
  - [ ] `clearExportedFiles()`
  - [ ] `_sanitizeFileName()`
- [ ] Unit testy: formatter service
- [ ] ✅ Commit MILESTONE 1

### MILESTONE 2: Settings UI (2h)
- [ ] 🔖 Snapshot commit
- [ ] Extend `SettingsState` s `exportConfig`
- [ ] Extend `SettingsCubit`:
  - [ ] `updateExportConfig()`
  - [ ] `_saveExportConfig()` (SharedPreferences)
  - [ ] `_loadExportConfig()` (SharedPreferences)
- [ ] Widget: `export_settings_section.dart`
  - [ ] Directory picker button
  - [ ] Format dropdown
  - [ ] Export options (TODOs/Notes checkboxes)
  - [ ] Auto-export toggle
  - [ ] Manual export button
- [ ] Integrace do `SettingsPage`
- [ ] UI test (manual)
- [ ] ✅ Commit MILESTONE 2

### MILESTONE 3: Repository + BLoC (1.5h)
- [ ] 🔖 Snapshot commit
- [ ] Repository interface
- [ ] Repository implementation
- [ ] DI setup (GetIt)
- [ ] TodoListBloc: `_autoExportIfEnabled()`
- [ ] NotesBloc: `_autoExportIfEnabled()`
- [ ] Integration test (create TODO → check file)
- [ ] ✅ Commit MILESTONE 3
- [ ] 🎉 **FEATURE COMPLETE!**

---

## 💡 Budoucí rozšíření (OPTIONAL)

### Phase 2 (pokud bude zájem):
1. **Incremental export** - exportovat jen změněné soubory (ne všechny)
2. **Export scheduling** - denní auto-export v 22:00
3. **Cloud sync** - automatický upload na Google Drive / Dropbox
4. **Import z Obsidian** - obousměrná synchronizace
5. **Export statistics** - kolik souborů exportováno, velikost, čas

---

## 📊 Metriky

| Metrika | Hodnota |
|---------|---------|
| **Celková doba** | 6.5-7.5h |
| **Počet souborů** | ~10 nových souborů |
| **Dependencies** | 0 nových (file_picker + path_provider už máme) |
| **Testovatelnost** | ⭐⭐⭐⭐⭐ (unit testy formatter, integration test export) |
| **Udržovatelnost** | ⭐⭐⭐⭐⭐ (clean architecture, SOLID) |
| **UX Impact** | ⭐⭐⭐⭐⭐ (killer feature - Obsidian integrace!) |

---

## 🎓 Závěr

**Markdown Export** je **killer feature** pro power users kteří používají Obsidian nebo jiné markdown-based tools!

**Klíčové výhody**:
- ✅ **Žádné nové dependencies** (file_picker už máme)
- ✅ **Žádné permissions na Android 11+** (díky SAF)
- ✅ **2 formáty** (vlastní + Obsidian) - max flexibilita
- ✅ **Auto-export** - zero friction workflow
- ✅ **Bidirectional links** - `[[Note-123]]` backlinks
- ✅ **Clean architecture** - snadno rozšiřitelné

**Ready to start?** 🚀

Začni s **MILESTONE 1** - Formatter + File Writer services!
