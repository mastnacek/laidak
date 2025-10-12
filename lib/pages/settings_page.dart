import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../core/theme/doom_one_theme.dart';
import '../core/theme/blade_runner_theme.dart';
import '../core/theme/osaka_jade_theme.dart';
import '../core/theme/amoled_theme.dart';
import '../core/theme/theme_colors.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/cubit/settings_state.dart';
import '../features/settings/domain/models/agenda_view_config.dart';
import '../features/settings/domain/models/custom_agenda_view.dart';
import '../features/settings/presentation/pages/ai_settings_tab.dart';
import '../features/settings/presentation/pages/prompts_tab.dart';
import '../features/settings/presentation/pages/themes_tab.dart';
import '../features/tag_management/presentation/pages/tag_management_page.dart';
import '../core/services/database_helper.dart';

/// Stránka s nastavením AI motivace
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASTAVENÍ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.appColors.cyan,
          labelColor: theme.appColors.cyan,
          unselectedLabelColor: theme.appColors.base5,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.settings_suggest),
              text: 'AI NASTAVENÍ',
            ),
            Tab(
              icon: Icon(Icons.psychology),
              text: 'MOTIVAČNÍ PROMPTY',
            ),
            Tab(
              icon: Icon(Icons.label),
              text: 'SPRÁVA TAGŮ',
            ),
            Tab(
              icon: Icon(Icons.palette),
              text: 'THEMES',
            ),
            Tab(
              icon: Icon(Icons.view_agenda),
              text: 'AGENDA',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AISettingsTab(),
          PromptsTab(),
          TagManagementPage(),
          ThemesTab(),
          _AgendaTab(),
        ],
      ),
    );
  }
}

/// Tab pro konfiguraci Agenda Views (built-in + custom)
class _AgendaTab extends StatelessWidget {
  const _AgendaTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final agendaConfig = state.agendaConfig;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.appColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.appColors.blue, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.appColors.blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Přizpůsob si ViewBar podle svých potřeb. Zapni/vypni built-in views nebo vytvoř vlastní filtry podle tagů.',
                        style: TextStyle(
                          color: theme.appColors.fg,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Built-in views section
              _buildBuiltInViewsSection(context, theme, agendaConfig),

              const SizedBox(height: 32),

              // Custom views section
              _buildCustomViewsSection(context, theme, agendaConfig),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuiltInViewsSection(
    BuildContext context,
    ThemeData theme,
    AgendaViewConfig agendaConfig,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 BUILT-IN VIEWS',
          style: TextStyle(
            color: theme.appColors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Zapnout/vypnout standardní agenda pohledy',
          style: TextStyle(
            color: theme.appColors.base5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        _buildBuiltInViewSwitch(
          context,
          theme,
          'all',
          '📋 Všechny',
          agendaConfig.showAll,
        ),
        _buildBuiltInViewSwitch(
          context,
          theme,
          'today',
          '📅 Dnes',
          agendaConfig.showToday,
        ),
        _buildBuiltInViewSwitch(
          context,
          theme,
          'week',
          '🗓️ Týden',
          agendaConfig.showWeek,
        ),
        _buildBuiltInViewSwitch(
          context,
          theme,
          'upcoming',
          '⏰ Nadcházející',
          agendaConfig.showUpcoming,
        ),
        _buildBuiltInViewSwitch(
          context,
          theme,
          'overdue',
          '⚠️ Overdue',
          agendaConfig.showOverdue,
        ),
      ],
    );
  }

  Widget _buildBuiltInViewSwitch(
    BuildContext context,
    ThemeData theme,
    String viewName,
    String label,
    bool value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.appColors.bgAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.base3),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        value: value,
        activeColor: theme.appColors.green,
        onChanged: (enabled) {
          context.read<SettingsCubit>().toggleBuiltInView(viewName, enabled);
        },
      ),
    );
  }

  Widget _buildCustomViewsSection(
    BuildContext context,
    ThemeData theme,
    AgendaViewConfig agendaConfig,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🆕 CUSTOM VIEWS',
          style: TextStyle(
            color: theme.appColors.magenta,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vlastní agenda pohledy na základě tagů (např. *projekt*, *nakup*)',
          style: TextStyle(
            color: theme.appColors.base5,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),

        // Add button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddCustomViewDialog(context, theme),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('PŘIDAT CUSTOM VIEW'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.green,
              foregroundColor: theme.appColors.bg,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Custom views list
        if (agendaConfig.customViews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.appColors.base2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.base3),
            ),
            child: Center(
              child: Text(
                'Žádné custom views.\nPřidej první pomocí tlačítka výše!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ...agendaConfig.customViews.map((view) {
            return _buildCustomViewCard(context, theme, view);
          }),
      ],
    );
  }

  Widget _buildCustomViewCard(
    BuildContext context,
    ThemeData theme,
    CustomAgendaView view,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.appColors.bgAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.base3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Emoji
            Text(
              view.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    view.name,
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Tag: ${view.tagFilter}',
                    style: TextStyle(
                      color: theme.appColors.base5,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Edit/Delete actions (doprostřed)
            IconButton(
              icon: Icon(Icons.edit, color: theme.appColors.cyan, size: 18),
              onPressed: () => _showEditCustomViewDialog(context, theme, view),
              tooltip: 'Upravit',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete, color: theme.appColors.red, size: 18),
              onPressed: () => _deleteCustomView(context, theme, view),
              tooltip: 'Smazat',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
            const SizedBox(width: 8),

            // Switch (na stejném místě jako built-in views)
            Switch(
              value: view.isEnabled,
              activeColor: theme.appColors.green,
              onChanged: (enabled) {
                context.read<SettingsCubit>().toggleCustomView(view.id, enabled);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== DIALOGS ==========

  void _showAddCustomViewDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomViewDialog(
        theme: theme,
        onSave: (name, tagFilter, emoji) {
          final view = CustomAgendaView(
            id: const Uuid().v4(),
            name: name,
            tagFilter: tagFilter,
            emoji: emoji,
          );
          context.read<SettingsCubit>().addCustomView(view);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Custom view přidán'),
              backgroundColor: theme.appColors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditCustomViewDialog(
    BuildContext context,
    ThemeData theme,
    CustomAgendaView view,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CustomViewDialog(
        theme: theme,
        initialName: view.name,
        initialTagFilter: view.tagFilter,
        initialEmoji: view.emoji,
        onSave: (name, tagFilter, emoji) {
          final updated = view.copyWith(
            name: name,
            tagFilter: tagFilter,
            emoji: emoji,
          );
          context.read<SettingsCubit>().updateCustomView(updated);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Custom view aktualizován'),
              backgroundColor: theme.appColors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCustomView(
    BuildContext context,
    ThemeData theme,
    CustomAgendaView view,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        title: Text(
          'Smazat custom view?',
          style: TextStyle(color: theme.appColors.red),
        ),
        content: Text(
          'Opravdu chceš smazat "${view.name}"?',
          style: TextStyle(color: theme.appColors.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.red,
              foregroundColor: theme.appColors.bg,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      context.read<SettingsCubit>().deleteCustomView(view.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Custom view smazán'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
    }
  }
}

/// Dialog pro vytvoření/úpravu custom view
class _CustomViewDialog extends StatefulWidget {
  final ThemeData theme;
  final String? initialName;
  final String? initialTagFilter;
  final String? initialEmoji;
  final void Function(String name, String tagFilter, String emoji) onSave;

  const _CustomViewDialog({
    required this.theme,
    this.initialName,
    this.initialTagFilter,
    this.initialEmoji,
    required this.onSave,
  });

  @override
  State<_CustomViewDialog> createState() => _CustomViewDialogState();
}

class _CustomViewDialogState extends State<_CustomViewDialog> {
  late TextEditingController _nameController;
  late TextEditingController _tagController;
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _tagController = TextEditingController(text: widget.initialTagFilter);
    _selectedEmoji = widget.initialEmoji ?? '⭐';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isEdit = widget.initialName != null;

    return AlertDialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEdit ? theme.appColors.cyan : theme.appColors.green,
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.add_circle,
            color: isEdit ? theme.appColors.cyan : theme.appColors.green,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            isEdit ? 'UPRAVIT VIEW' : 'NOVÝ VIEW',
            style: TextStyle(
              color: isEdit ? theme.appColors.cyan : theme.appColors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            Text(
              'Název',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.appColors.fg),
              decoration: InputDecoration(
                hintText: 'Oblíbené',
                hintStyle: TextStyle(color: theme.appColors.base5),
                filled: true,
                fillColor: theme.appColors.base2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tag filter field
            Text(
              'Tag Filter',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zadej tag BEZ oddělovačů (např. "projekt", ne "*projekt*")',
              style: TextStyle(
                color: theme.appColors.yellow,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              style: TextStyle(
                color: theme.appColors.fg,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'projekt',
                hintStyle: TextStyle(color: theme.appColors.base5),
                helperText: 'Pouze holý tag (lowercase)',
                helperStyle: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 11,
                ),
                filled: true,
                fillColor: theme.appColors.base2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker (button)
            Text(
              'Emoji',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showEmojiPickerBottomSheet(context, theme),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.appColors.base2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.appColors.cyan, width: 2),
                ),
                child: Row(
                  children: [
                    // Vybrané emoji (velké)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.appColors.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.appColors.cyan,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vyber emoji',
                            style: TextStyle(
                              color: theme.appColors.cyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Klikni pro otevření emoji pickeru',
                            style: TextStyle(
                              color: theme.appColors.base5,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ikona
                    Icon(
                      Icons.arrow_forward_ios,
                      color: theme.appColors.cyan,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty ||
                _tagController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('❌ Název a tag nesmí být prázdné'),
                  backgroundColor: theme.appColors.red,
                ),
              );
              return;
            }

            widget.onSave(
              _nameController.text.trim(),
              _tagController.text.trim(),
              _selectedEmoji,
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isEdit ? theme.appColors.cyan : theme.appColors.green,
            foregroundColor: theme.appColors.bg,
          ),
          child: Text(isEdit ? 'Uložit' : 'Přidat'),
        ),
      ],
    );
  }

  /// Zobrazit emoji picker v bottom sheet
  void _showEmojiPickerBottomSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.appColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.appColors.base3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Vyber emoji',
                      style: TextStyle(
                        color: theme.appColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
              ),
              // Emoji Picker
              Expanded(
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() => _selectedEmoji = emoji.emoji);
                    Navigator.pop(bottomSheetContext);
                  },
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: theme.appColors.bg,
                      columns: 8,
                      emojiSizeMax: 28,
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      gridPadding: EdgeInsets.zero,
                      recentsLimit: 28,
                      replaceEmojiOnLimitExceed: false,
                      noRecents: Text(
                        'Žádné nedávné emoji',
                        style: TextStyle(fontSize: 20, color: theme.appColors.base5),
                        textAlign: TextAlign.center,
                      ),
                      loadingIndicator: const SizedBox.shrink(),
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                    skinToneConfig: const SkinToneConfig(
                      enabled: true,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: theme.appColors.bg,
                      indicatorColor: theme.appColors.cyan,
                      iconColor: theme.appColors.base5,
                      iconColorSelected: theme.appColors.cyan,
                      categoryIcons: const CategoryIcons(),
                      initCategory: Category.RECENT,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: theme.appColors.bg,
                      buttonColor: theme.appColors.cyan,
                      buttonIconColor: theme.appColors.bg,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: theme.appColors.bgAlt,
                      buttonIconColor: theme.appColors.cyan,
                      hintText: 'Hledat emoji...',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
