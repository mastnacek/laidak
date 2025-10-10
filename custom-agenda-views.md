# Custom Agenda Views - Implementační Plán

## 📋 Přehled

**Feature**: Konfigurovatelné Agenda Views - uživatel si sám vybere které views chce vidět v GUI

**Priorita**: ⭐⭐⭐ Vysoká (game-changer pro UX)

**Složitost**: Střední (UI práce, žádné DB migrace)

**Čas**: 3-4 hodiny celkem

---

## 🎯 Cíl

Umožnit uživateli:
1. **Zapnout/vypnout** built-in views (All, Today, Week, Upcoming, Overdue)
2. **Vytvořit custom views** na základě tagů (např. `***` = Oblíbené, `#projekt` = Projekt)
3. **Přizpůsobit ViewBar** - zobrazit pouze enabled views
4. **Spravovat vše** z nové záložky **Settings > Agenda**

---

## 💡 Koncept

### Settings UI:
```
┌─────────────────────────────────────────┐
│ ⚙️ Settings > Agenda Views              │
├─────────────────────────────────────────┤
│ 📋 BUILT-IN VIEWS                       │
│ [✅] 📋 Všechny                         │
│ [✅] 📅 Dnes                            │
│ [✅] 🗓️ Týden                           │
│ [ ] ⏰ Nadcházející                     │
│ [✅] ⚠️ Overdue                         │
├─────────────────────────────────────────┤
│ 🆕 CUSTOM VIEWS                         │
│ [➕ Přidat Custom View]                │
│                                         │
│ ⭐ Oblíbené                             │
│   Tag: ***                              │
│   [✏️ Upravit] [🗑️ Smazat]             │
│                                         │
│ 🏢 Projekt                              │
│   Tag: #projekt                         │
│   [✏️ Upravit] [🗑️ Smazat]             │
└─────────────────────────────────────────┘
```

### ViewBar (dynamicky generovaný):
```
Původně: [📋][📅][🗓️][⏰][⚠️]

Po customizaci: [📋][📅][⚠️][⭐][🏢]
                 ↑   ↑   ↑   ↑   ↑
                All Dnes Over Fav Proj
```

---

## 🏗️ Architektura

### Struktura:
```
lib/features/settings/
├── domain/
│   └── models/
│       ├── agenda_view_config.dart      // 🆕 Config model
│       └── custom_agenda_view.dart      // 🆕 Custom view model
├── data/
│   └── repositories/
│       └── settings_repository_impl.dart // Rozšíření (agenda config)
└── presentation/
    ├── cubit/
    │   └── settings_cubit.dart          // Rozšíření (agenda state)
    └── pages/
        ├── settings_page.dart           // Přidat tab "Agenda"
        └── agenda_settings_tab.dart     // 🆕 Nové UI

lib/features/todo_list/
├── domain/
│   └── enums/
│       └── view_mode.dart               // Rozšíření (custom views)
├── domain/
│   └── extensions/
│       └── todo_filtering.dart          // Rozšíření (custom filtering)
└── presentation/
    └── widgets/
        └── view_bar.dart                // Refaktoring (dynamic rendering)
```

---

## 📊 Data Models

### 1️⃣ AgendaViewConfig (domain model)

```dart
// lib/features/settings/domain/models/agenda_view_config.dart

import 'package:equatable/equatable.dart';
import 'custom_agenda_view.dart';

/// Konfigurace Agenda Views (built-in + custom)
class AgendaViewConfig extends Equatable {
  /// Built-in views (enable/disable)
  final bool showAll;
  final bool showToday;
  final bool showWeek;
  final bool showUpcoming;
  final bool showOverdue;

  /// Custom views (tag-based filters)
  final List<CustomAgendaView> customViews;

  const AgendaViewConfig({
    this.showAll = true,
    this.showToday = true,
    this.showWeek = true,
    this.showUpcoming = false,
    this.showOverdue = true,
    this.customViews = const [],
  });

  /// Default config (pro first launch)
  factory AgendaViewConfig.defaultConfig() {
    return const AgendaViewConfig(
      showAll: true,
      showToday: true,
      showWeek: true,
      showUpcoming: false,
      showOverdue: true,
      customViews: [],
    );
  }

  /// CopyWith
  AgendaViewConfig copyWith({
    bool? showAll,
    bool? showToday,
    bool? showWeek,
    bool? showUpcoming,
    bool? showOverdue,
    List<CustomAgendaView>? customViews,
  }) {
    return AgendaViewConfig(
      showAll: showAll ?? this.showAll,
      showToday: showToday ?? this.showToday,
      showWeek: showWeek ?? this.showWeek,
      showUpcoming: showUpcoming ?? this.showUpcoming,
      showOverdue: showOverdue ?? this.showOverdue,
      customViews: customViews ?? this.customViews,
    );
  }

  /// Serialization (SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'showAll': showAll,
      'showToday': showToday,
      'showWeek': showWeek,
      'showUpcoming': showUpcoming,
      'showOverdue': showOverdue,
      'customViews': customViews.map((v) => v.toJson()).toList(),
    };
  }

  factory AgendaViewConfig.fromJson(Map<String, dynamic> json) {
    return AgendaViewConfig(
      showAll: json['showAll'] ?? true,
      showToday: json['showToday'] ?? true,
      showWeek: json['showWeek'] ?? true,
      showUpcoming: json['showUpcoming'] ?? false,
      showOverdue: json['showOverdue'] ?? true,
      customViews: (json['customViews'] as List<dynamic>?)
          ?.map((v) => CustomAgendaView.fromJson(v))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
    showAll,
    showToday,
    showWeek,
    showUpcoming,
    showOverdue,
    customViews,
  ];
}
```

### 2️⃣ CustomAgendaView (domain model)

```dart
// lib/features/settings/domain/models/custom_agenda_view.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Custom Agenda View definice (tag-based filtr)
class CustomAgendaView extends Equatable {
  /// Unikátní ID (UUID)
  final String id;

  /// Název view (zobrazený v InfoDialog)
  final String name;

  /// Tag pro filtrování (např. "***", "#projekt")
  final String tagFilter;

  /// Ikona (Material Icons code point)
  final int iconCodePoint;

  /// Barva (optional, hex string)
  final String? colorHex;

  const CustomAgendaView({
    required this.id,
    required this.name,
    required this.tagFilter,
    required this.iconCodePoint,
    this.colorHex,
  });

  /// Helper: IconData z code pointu
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// Helper: Color z hex stringu
  Color? get color => colorHex != null
    ? Color(int.parse(colorHex!.substring(1), radix: 16) + 0xFF000000)
    : null;

  /// Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagFilter': tagFilter,
      'iconCodePoint': iconCodePoint,
      'colorHex': colorHex,
    };
  }

  factory CustomAgendaView.fromJson(Map<String, dynamic> json) {
    return CustomAgendaView(
      id: json['id'],
      name: json['name'],
      tagFilter: json['tagFilter'],
      iconCodePoint: json['iconCodePoint'],
      colorHex: json['colorHex'],
    );
  }

  /// CopyWith
  CustomAgendaView copyWith({
    String? id,
    String? name,
    String? tagFilter,
    int? iconCodePoint,
    String? colorHex,
  }) {
    return CustomAgendaView(
      id: id ?? this.id,
      name: name ?? this.name,
      tagFilter: tagFilter ?? this.tagFilter,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [id, name, tagFilter, iconCodePoint, colorHex];
}
```

---

## 🔧 Implementační Kroky

### ✅ **FÁZE 1: Data Layer** (30 min)

#### Krok 1.1: Vytvořit domain models
- [ ] `lib/features/settings/domain/models/agenda_view_config.dart`
- [ ] `lib/features/settings/domain/models/custom_agenda_view.dart`
- [ ] Testy: toJson/fromJson/copyWith

#### Krok 1.2: Rozšířit SettingsState
```dart
// lib/features/settings/presentation/cubit/settings_state.dart

class SettingsState extends Equatable {
  // Existující fields...
  final String? openRouterApiKey;
  final String? openRouterModel;

  // 🆕 PŘIDAT:
  final AgendaViewConfig agendaConfig;

  const SettingsState({
    // ...
    this.agendaConfig = const AgendaViewConfig.defaultConfig(),
  });

  @override
  List<Object?> get props => [
    // ...
    agendaConfig,
  ];
}
```

#### Krok 1.3: Persistence (SharedPreferences)
```dart
// lib/features/settings/data/repositories/settings_repository_impl.dart

// Přidat metody:
Future<AgendaViewConfig> getAgendaConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString('agenda_config');
  if (json == null) return AgendaViewConfig.defaultConfig();
  return AgendaViewConfig.fromJson(jsonDecode(json));
}

Future<void> saveAgendaConfig(AgendaViewConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('agenda_config', jsonEncode(config.toJson()));
}
```

#### Krok 1.4: SettingsCubit metody
```dart
// lib/features/settings/presentation/cubit/settings_cubit.dart

// Přidat metody:
Future<void> toggleBuiltInView(String viewName, bool enabled) async {
  final updated = switch (viewName) {
    'all' => state.agendaConfig.copyWith(showAll: enabled),
    'today' => state.agendaConfig.copyWith(showToday: enabled),
    'week' => state.agendaConfig.copyWith(showWeek: enabled),
    'upcoming' => state.agendaConfig.copyWith(showUpcoming: enabled),
    'overdue' => state.agendaConfig.copyWith(showOverdue: enabled),
    _ => state.agendaConfig,
  };

  await _repository.saveAgendaConfig(updated);
  emit(state.copyWith(agendaConfig: updated));
}

Future<void> addCustomView(CustomAgendaView view) async {
  final updated = state.agendaConfig.copyWith(
    customViews: [...state.agendaConfig.customViews, view],
  );

  await _repository.saveAgendaConfig(updated);
  emit(state.copyWith(agendaConfig: updated));
}

Future<void> updateCustomView(CustomAgendaView view) async {
  final updated = state.agendaConfig.copyWith(
    customViews: state.agendaConfig.customViews
      .map((v) => v.id == view.id ? view : v)
      .toList(),
  );

  await _repository.saveAgendaConfig(updated);
  emit(state.copyWith(agendaConfig: updated));
}

Future<void> deleteCustomView(String id) async {
  final updated = state.agendaConfig.copyWith(
    customViews: state.agendaConfig.customViews
      .where((v) => v.id != id)
      .toList(),
  );

  await _repository.saveAgendaConfig(updated);
  emit(state.copyWith(agendaConfig: updated));
}
```

**Commit**: `🔧 feat: Data layer pro Custom Agenda Views`

---

### ✅ **FÁZE 2: Settings UI** (1.5-2h)

#### Krok 2.1: Přidat tab "Agenda" do SettingsPage
```dart
// lib/features/settings/presentation/pages/settings_page.dart

// Přidat TabBar:
DefaultTabController(
  length: 3,  // Was 2, now 3
  child: Scaffold(
    appBar: AppBar(
      title: const Text('Nastavení'),
      bottom: const TabBar(
        tabs: [
          Tab(text: 'Obecné'),
          Tab(text: 'AI'),
          Tab(text: 'Agenda'),  // 🆕 NOVÁ ZÁLOŽKA
        ],
      ),
    ),
    body: TabBarView(
      children: [
        _GeneralSettingsTab(),
        _AiSettingsTab(),
        const AgendaSettingsTab(),  // 🆕
      ],
    ),
  ),
)
```

#### Krok 2.2: Vytvořit AgendaSettingsTab widget
```dart
// lib/features/settings/presentation/pages/agenda_settings_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../../domain/models/custom_agenda_view.dart';
import 'package:uuid/uuid.dart';

class AgendaSettingsTab extends StatelessWidget {
  const AgendaSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Built-in views section
            _buildBuiltInViewsSection(context, state),

            const SizedBox(height: 24),

            // Custom views section
            _buildCustomViewsSection(context, state),
          ],
        );
      },
    );
  }

  Widget _buildBuiltInViewsSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Built-in Views',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Zapnout/vypnout standardní agenda pohledy',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        _buildBuiltInViewSwitch(
          context,
          state,
          'all',
          '📋 Všechny',
          state.agendaConfig.showAll,
        ),
        _buildBuiltInViewSwitch(
          context,
          state,
          'today',
          '📅 Dnes',
          state.agendaConfig.showToday,
        ),
        _buildBuiltInViewSwitch(
          context,
          state,
          'week',
          '🗓️ Týden',
          state.agendaConfig.showWeek,
        ),
        _buildBuiltInViewSwitch(
          context,
          state,
          'upcoming',
          '⏰ Nadcházející',
          state.agendaConfig.showUpcoming,
        ),
        _buildBuiltInViewSwitch(
          context,
          state,
          'overdue',
          '⚠️ Overdue',
          state.agendaConfig.showOverdue,
        ),
      ],
    );
  }

  Widget _buildBuiltInViewSwitch(
    BuildContext context,
    SettingsState state,
    String viewName,
    String label,
    bool value,
  ) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: (enabled) {
        context.read<SettingsCubit>().toggleBuiltInView(viewName, enabled);
      },
    );
  }

  Widget _buildCustomViewsSection(BuildContext context, SettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🆕 Custom Views',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Vlastní agenda pohledy na základě tagů',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Add button
        ElevatedButton.icon(
          onPressed: () => _showAddCustomViewDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Přidat Custom View'),
        ),

        const SizedBox(height: 16),

        // Custom views list
        ...state.agendaConfig.customViews.map((view) {
          return _buildCustomViewCard(context, view);
        }),
      ],
    );
  }

  Widget _buildCustomViewCard(BuildContext context, CustomAgendaView view) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(view.icon, color: view.color),
        title: Text(view.name),
        subtitle: Text('Tag: ${view.tagFilter}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCustomViewDialog(context, view),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                context.read<SettingsCubit>().deleteCustomView(view.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomViewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomViewDialog(
        onSave: (name, tagFilter, iconCodePoint) {
          final view = CustomAgendaView(
            id: const Uuid().v4(),
            name: name,
            tagFilter: tagFilter,
            iconCodePoint: iconCodePoint,
          );
          context.read<SettingsCubit>().addCustomView(view);
        },
      ),
    );
  }

  void _showEditCustomViewDialog(BuildContext context, CustomAgendaView view) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomViewDialog(
        initialName: view.name,
        initialTagFilter: view.tagFilter,
        initialIconCodePoint: view.iconCodePoint,
        onSave: (name, tagFilter, iconCodePoint) {
          final updated = view.copyWith(
            name: name,
            tagFilter: tagFilter,
            iconCodePoint: iconCodePoint,
          );
          context.read<SettingsCubit>().updateCustomView(updated);
        },
      ),
    );
  }
}

/// Dialog pro vytvoření/úpravu custom view
class _CustomViewDialog extends StatefulWidget {
  final String? initialName;
  final String? initialTagFilter;
  final int? initialIconCodePoint;
  final void Function(String name, String tagFilter, int iconCodePoint) onSave;

  const _CustomViewDialog({
    this.initialName,
    this.initialTagFilter,
    this.initialIconCodePoint,
    required this.onSave,
  });

  @override
  State<_CustomViewDialog> createState() => _CustomViewDialogState();
}

class _CustomViewDialogState extends State<_CustomViewDialog> {
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late int _selectedIconCodePoint;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _tagController = TextEditingController(text: widget.initialTagFilter);
    _selectedIconCodePoint = widget.initialIconCodePoint ?? Icons.star.codePoint;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Nový Custom View' : 'Upravit Custom View'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Název',
              hintText: 'Oblíbené',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(
              labelText: 'Tag Filter',
              hintText: '*** nebo #projekt',
            ),
          ),
          const SizedBox(height: 16),

          // Icon picker (simple version)
          DropdownButton<int>(
            value: _selectedIconCodePoint,
            items: [
              DropdownMenuItem(value: Icons.star.codePoint, child: const Row(children: [Icon(Icons.star), SizedBox(width: 8), Text('Star')])),
              DropdownMenuItem(value: Icons.work.codePoint, child: const Row(children: [Icon(Icons.work), SizedBox(width: 8), Text('Work')])),
              DropdownMenuItem(value: Icons.warning.codePoint, child: const Row(children: [Icon(Icons.warning), SizedBox(width: 8), Text('Warning')])),
              DropdownMenuItem(value: Icons.favorite.codePoint, child: const Row(children: [Icon(Icons.favorite), SizedBox(width: 8), Text('Favorite')])),
              DropdownMenuItem(value: Icons.home.codePoint, child: const Row(children: [Icon(Icons.home), SizedBox(width: 8), Text('Home')])),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedIconCodePoint = value);
              }
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
            if (_nameController.text.isNotEmpty && _tagController.text.isNotEmpty) {
              widget.onSave(
                _nameController.text,
                _tagController.text,
                _selectedIconCodePoint,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Uložit'),
        ),
      ],
    );
  }
}
```

**Commit**: `🎨 feat: Settings UI pro Custom Agenda Views`

---

### ✅ **FÁZE 3: ViewBar Refaktoring** (1h)

#### Krok 3.1: Rozšířit ViewMode enum
```dart
// lib/features/todo_list/domain/enums/view_mode.dart

enum ViewMode {
  all,
  today,
  week,
  upcoming,
  overdue,

  // Custom views (dynamicky načtené z settings)
  custom,  // Indikátor že je to custom view
}

// Přidat extension:
extension ViewModeExtension on ViewMode {
  bool get isCustom => this == ViewMode.custom;
}
```

#### Krok 3.2: Refaktorovat ViewBar - dynamic rendering
```dart
// lib/features/todo_list/presentation/widgets/view_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/info_dialog.dart';
import '../../../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../../../features/settings/presentation/cubit/settings_state.dart';
import '../../../../features/settings/domain/models/custom_agenda_view.dart';
import '../../domain/enums/view_mode.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';

class ViewBar extends StatelessWidget {
  const ViewBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final agendaConfig = settingsState.agendaConfig;

        // Build list of visible views
        final visibleViews = <_ViewItem>[];

        // Built-in views
        if (agendaConfig.showAll) {
          visibleViews.add(_ViewItem.builtIn(ViewMode.all));
        }
        if (agendaConfig.showToday) {
          visibleViews.add(_ViewItem.builtIn(ViewMode.today));
        }
        if (agendaConfig.showWeek) {
          visibleViews.add(_ViewItem.builtIn(ViewMode.week));
        }
        if (agendaConfig.showUpcoming) {
          visibleViews.add(_ViewItem.builtIn(ViewMode.upcoming));
        }
        if (agendaConfig.showOverdue) {
          visibleViews.add(_ViewItem.builtIn(ViewMode.overdue));
        }

        // Custom views
        for (final customView in agendaConfig.customViews) {
          visibleViews.add(_ViewItem.custom(customView));
        }

        // Empty state
        if (visibleViews.isEmpty) {
          return Container(
            height: 56,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Žádné views aktivní. Zapni je v Settings > Agenda',
                style: TextStyle(color: theme.appColors.base5),
              ),
            ),
          );
        }

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt,
            border: Border(
              top: BorderSide(color: theme.appColors.base3, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // View mode buttons (kompaktní ikony)
                Expanded(
                  child: BlocBuilder<TodoListBloc, TodoListState>(
                    builder: (context, todoState) {
                      final currentViewMode = todoState is TodoListLoaded
                        ? todoState.viewMode
                        : ViewMode.all;

                      final currentCustomViewId = todoState is TodoListLoaded
                        ? todoState.currentCustomViewId
                        : null;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: visibleViews.map((viewItem) {
                            final isSelected = viewItem.isBuiltIn
                              ? currentViewMode == viewItem.builtInMode
                              : currentCustomViewId == viewItem.customView?.id;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  final bloc = context.read<TodoListBloc>();

                                  if (viewItem.isBuiltIn) {
                                    // Built-in view
                                    if (isSelected && viewItem.builtInMode != ViewMode.all) {
                                      bloc.add(const ChangeViewModeEvent(ViewMode.all));
                                    } else {
                                      bloc.add(ChangeViewModeEvent(viewItem.builtInMode!));
                                    }
                                  } else {
                                    // Custom view
                                    if (isSelected) {
                                      bloc.add(const ChangeViewModeEvent(ViewMode.all));
                                    } else {
                                      bloc.add(ChangeToCustomViewEvent(viewItem.customView!));
                                    }
                                  }
                                },
                                onLongPress: () {
                                  _showInfoDialog(context, viewItem, theme);
                                },
                                borderRadius: BorderRadius.circular(22),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    viewItem.icon,
                                    size: 20,
                                    color: isSelected
                                        ? theme.appColors.yellow
                                        : theme.appColors.base5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // Divider před visibility toggle
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: theme.appColors.base3,
                ),

                // Visibility toggle (výraznější ikona 24dp)
                BlocBuilder<TodoListBloc, TodoListState>(
                  builder: (context, state) {
                    final showCompleted =
                        state is TodoListLoaded ? state.showCompleted : false;

                    return IconButton(
                      icon: Icon(
                        showCompleted ? Icons.visibility : Icons.visibility_off,
                        size: 24,
                      ),
                      tooltip: showCompleted
                          ? 'Skrýt hotové úkoly'
                          : 'Zobrazit hotové úkoly',
                      color: showCompleted
                          ? theme.appColors.green
                          : theme.appColors.base5,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context
                            .read<TodoListBloc>()
                            .add(const ToggleShowCompletedEvent());
                      },
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

  void _showInfoDialog(BuildContext context, _ViewItem viewItem, ThemeData theme) {
    if (viewItem.isBuiltIn) {
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: viewItem.label,
          icon: viewItem.icon,
          iconColor: theme.appColors.yellow,
          description: _getViewModeDescription(viewItem.builtInMode!),
          examples: _getViewModeExamples(viewItem.builtInMode!),
          tip: 'Klikni na ikonku pro aktivaci tohoto pohledu. Klikni znovu pro vrácení na "Všechny".',
        ),
      );
    } else {
      // Custom view info
      showDialog(
        context: context,
        builder: (context) => InfoDialog(
          title: viewItem.label,
          icon: viewItem.icon,
          iconColor: viewItem.customView?.color ?? theme.appColors.yellow,
          description: 'Vlastní pohled filtrující úkoly podle tagu: ${viewItem.customView?.tagFilter}',
          examples: [
            'Zobrazí pouze úkoly s tagem ${viewItem.customView?.tagFilter}',
            'Nastavení: Settings > Agenda > Custom Views',
          ],
          tip: 'Klikni na ikonku pro aktivaci. Upravit můžeš v Settings.',
        ),
      );
    }
  }

  String _getViewModeDescription(ViewMode mode) {
    return switch (mode) {
      ViewMode.all =>
        'Zobrazí všechny úkoly bez filtru. Toto je výchozí pohled, kde vidíš kompletní seznam všech aktivních i dokončených úkolů.',
      ViewMode.today =>
        'Zobrazí pouze úkoly s termínem dnes. Ideální pro denní plánování - vidíš co musíš stihnout ještě dnes.',
      ViewMode.week =>
        'Zobrazí úkoly s termínem v příštích 7 dnech. Pomůže ti plánovat týden dopředu a rozložit práci.',
      ViewMode.upcoming =>
        'Zobrazí všechny úkoly s termínem v budoucnosti (od zítřka dál). Pro dlouhodobé plánování.',
      ViewMode.overdue =>
        'Zobrazí úkoly po termínu - ty, které jsi nestihl včas. Prioritizuj je jako první!',
      ViewMode.custom =>
        'Vlastní pohled',
    };
  }

  List<String> _getViewModeExamples(ViewMode mode) {
    return switch (mode) {
      ViewMode.all => [
          '📋 Všechny aktivní úkoly',
          '📋 Dokončené úkoly',
          '📋 Bez jakéhokoliv filtru',
        ],
      ViewMode.today => [
          '📅 Termín: Dnes 14:00',
          '📅 Dnes do konce dne',
          '📅 Urgentní úkoly na dnes',
        ],
      ViewMode.week => [
          '🗓️ Pondělí - Prezentace',
          '🗓️ Středa - Code review',
          '🗓️ Pátek - Team meeting',
        ],
      ViewMode.upcoming => [
          '📆 Příští týden - Projekt X',
          '📆 Konec měsíce - Report',
          '📆 Budoucí plánování',
        ],
      ViewMode.overdue => [
          '⚠️ Včera mělo být hotovo!',
          '⚠️ 3 dny po termínu',
          '⚠️ Nesplněné deadlines',
        ],
      ViewMode.custom => [],
    };
  }
}

/// Helper class pro view items
class _ViewItem {
  final ViewMode? builtInMode;
  final CustomAgendaView? customView;

  bool get isBuiltIn => builtInMode != null;

  IconData get icon {
    if (isBuiltIn) {
      return builtInMode!.icon;
    } else {
      return customView!.icon;
    }
  }

  String get label {
    if (isBuiltIn) {
      return builtInMode!.label;
    } else {
      return customView!.name;
    }
  }

  _ViewItem.builtIn(this.builtInMode) : customView = null;
  _ViewItem.custom(this.customView) : builtInMode = null;
}
```

#### Krok 3.3: Přidat event pro custom view
```dart
// lib/features/todo_list/presentation/bloc/todo_list_event.dart

// Přidat nový event:
final class ChangeToCustomViewEvent extends TodoListEvent {
  final CustomAgendaView customView;

  const ChangeToCustomViewEvent(this.customView);

  @override
  List<Object?> get props => [customView];
}
```

#### Krok 3.4: Rozšířit TodoListState
```dart
// lib/features/todo_list/presentation/bloc/todo_list_state.dart

class TodoListLoaded extends TodoListState {
  // Existující fields...
  final ViewMode viewMode;

  // 🆕 PŘIDAT:
  final CustomAgendaView? currentCustomView;

  String? get currentCustomViewId => currentCustomView?.id;

  const TodoListLoaded({
    // ...
    this.viewMode = ViewMode.all,
    this.currentCustomView,
  });

  TodoListLoaded copyWith({
    // ...
    ViewMode? viewMode,
    CustomAgendaView? currentCustomView,
    bool clearCustomView = false,
  }) {
    return TodoListLoaded(
      // ...
      viewMode: viewMode ?? this.viewMode,
      currentCustomView: clearCustomView ? null : (currentCustomView ?? this.currentCustomView),
    );
  }
}
```

**Commit**: `🎨 feat: ViewBar dynamic rendering based on AgendaViewConfig`

---

### ✅ **FÁZE 4: Filtrování Custom Views** (30 min)

#### Krok 4.1: Rozšířit todo_filtering.dart
```dart
// lib/features/todo_list/domain/extensions/todo_filtering.dart

// Přidat metodu:
/// Filtrovat podle custom view (tag-based)
List<Todo> filterByCustomView(String tagFilter) {
  return where((todo) => todo.tags.contains(tagFilter)).toList();
}
```

#### Krok 4.2: Rozšířit TodoListBloc handler
```dart
// lib/features/todo_list/presentation/bloc/todo_list_bloc.dart

// Přidat handler:
void _onChangeToCustomView(
  ChangeToCustomViewEvent event,
  Emitter<TodoListState> emit,
) {
  final currentState = state;
  if (currentState is! TodoListLoaded) return;

  emit(currentState.copyWith(
    viewMode: ViewMode.custom,
    currentCustomView: event.customView,
  ));
}

// Registrovat v konstruktoru:
TodoListBloc(this._repository) : super(const TodoListInitial()) {
  // ...
  on<ChangeToCustomViewEvent>(_onChangeToCustomView);
}
```

#### Krok 4.3: Rozšířit displayedTodos getter
```dart
// lib/features/todo_list/presentation/bloc/todo_list_state.dart

// Upravit displayedTodos:
List<Todo> get displayedTodos {
  var filtered = allTodos;

  // 1. Search filter
  if (searchQuery.isNotEmpty) {
    filtered = filtered.filterBySearch(searchQuery);
  }

  // 2. View mode filter
  if (viewMode == ViewMode.custom && currentCustomView != null) {
    // Custom view filtering
    filtered = filtered.filterByCustomView(currentCustomView!.tagFilter);
  } else {
    // Built-in view filtering
    filtered = filtered.filterByViewMode(viewMode);
  }

  // 3. Show completed filter
  if (!showCompleted) {
    filtered = filtered.where((t) => !t.isCompleted).toList();
  }

  // 4. Sort
  if (sortMode != null && sortDirection != null) {
    filtered = filtered.sortBy(sortMode!, sortDirection!);
  }

  return filtered;
}
```

**Commit**: `✨ feat: Custom View filtering by tag`

---

### ✅ **FÁZE 5: Testing & Polish** (30 min)

#### Krok 5.1: Manuální testing checklist
- [ ] Settings > Agenda tab zobrazuje built-in views
- [ ] Zapnutí/vypnutí built-in view funguje
- [ ] Přidání custom view funguje
- [ ] Úprava custom view funguje
- [ ] Smazání custom view funguje
- [ ] ViewBar zobrazuje pouze enabled views
- [ ] Klik na custom view filtruje správně
- [ ] Long-press na custom view zobrazí InfoDialog
- [ ] Empty state když žádné views (hint na Settings)
- [ ] Horizontal scroll když > 6 views

#### Krok 5.2: Edge cases
- [ ] Co když uživatel vypne všechny views? (show hint)
- [ ] Co když custom view má neexistující tag? (zobrazí prázdný list)
- [ ] Persistence funguje (restart app = views zachované)

#### Krok 5.3: UX improvements
- [ ] Animace při přidání/odebrání view
- [ ] Confirmation dialog před smazáním custom view
- [ ] Icon picker - lepší UI (grid místo dropdown)
- [ ] Default custom view: "⭐ Oblíbené" s tagem "***"

**Commit**: `✅ test: Manual testing + edge cases pro Custom Agenda Views`

---

## 🎯 Budoucí Rozšíření (Later)

### 🔮 Phase 2 features (neimplementovat teď):

1. **Reorder views** - drag & drop pro změnu pořadí
2. **Color picker** - vlastní barva pro každý custom view
3. **Advanced filters** - kombinace tagů (AND/OR), priorita, datum
4. **Export/Import** - sdílení agenda config mezi zařízeními
5. **Presets** - předpřipravené custom views ("Work", "Personal", "Urgent")

---

## 📝 Dependencies

```yaml
# pubspec.yaml - přidat pokud chybí:
dependencies:
  uuid: ^4.0.0  # Pro generování custom view IDs
```

---

## ✅ Acceptance Criteria

- [ ] Uživatel může zapnout/vypnout built-in views v Settings > Agenda
- [ ] Uživatel může přidat custom view s tagem, názvem a ikonou
- [ ] Uživatel může upravit existující custom view
- [ ] Uživatel může smazat custom view
- [ ] ViewBar zobrazuje pouze enabled views
- [ ] Klik na custom view filtruje úkoly podle tagu
- [ ] Empty state hint když žádné views enabled
- [ ] Horizontal scroll když > 6 views
- [ ] Persistence přes SharedPreferences funguje
- [ ] InfoDialog na long-press funguje pro custom views

---

## 📊 Tracking Postupu

Markuj kroky pomocí:
- `[ ]` - Not started
- `[⏳]` - In progress
- `[✅]` - Completed

---

## 🐛 Known Issues & Notes

- Icon picker je jednoduchý (dropdown) - později upgrade na grid picker
- Custom views nemají zatím barvu - přidat v Phase 2
- Reorder views není implementován - přidat v Phase 2

---

**Vytvořeno**: 2025-01-10
**Autor**: Claude Code (AI asistent)
**Status**: 📋 Ready for Implementation
