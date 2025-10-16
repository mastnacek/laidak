import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_colors.dart';
import '../features/settings/presentation/pages/ai_settings_tab.dart';
import '../features/settings/presentation/pages/prompts_tab.dart';
import '../features/settings/presentation/pages/themes_tab.dart';
import '../features/settings/presentation/pages/agenda_tab.dart';
import '../features/settings/presentation/pages/notes_tab.dart';
import '../features/tag_management/presentation/pages/tag_management_page.dart';
import '../features/markdown_export/presentation/widgets/export_settings_section.dart';
import '../features/markdown_export/domain/repositories/markdown_export_repository.dart';

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
    _tabController = TabController(length: 7, vsync: this);
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
            Tab(
              icon: Icon(Icons.folder_special),
              text: 'NOTES VIEWS',
            ),
            Tab(
              icon: Icon(Icons.save_alt),
              text: 'EXPORT',
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
          AgendaTab(),
          NotesTab(),
          SingleChildScrollView(
            child: ExportSettingsSection(
              exportRepository: context.read<MarkdownExportRepository>(),
            ),
          ),
        ],
      ),
    );
  }
}
