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
import '../features/tag_management/presentation/pages/tag_management_page.dart';
import '../core/services/database_helper.dart';
import '../core/services/database_debug_utils.dart';

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
          _AISettingsTab(),
          _PromptsTab(),
          TagManagementPage(),
          _ThemesTab(),
          _AgendaTab(),
        ],
      ),
    );
  }
}

/// Tab s AI nastavením (API klíč, model, temperature, max_tokens)
class _AISettingsTab extends StatefulWidget {
  const _AISettingsTab();

  @override
  State<_AISettingsTab> createState() => _AISettingsTabState();
}

class _AISettingsTabState extends State<_AISettingsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();

  bool _isLoading = true;
  bool _isEnabled = true;
  bool _obscureApiKey = true;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

  // Populární modely
  final List<String> _popularModels = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-opus',
    'openai/gpt-4-turbo',
    'openai/gpt-4o',
    'google/gemini-pro-1.5',
    'mistralai/mistral-medium-3.1',
    'mistralai/mistral-large',
    'meta-llama/llama-3.1-70b-instruct',
    'meta-llama/llama-3.1-405b-instruct',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  /// Načíst AI nastavení z databáze
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await _db.getSettings();

    setState(() {
      _apiKeyController.text = settings['api_key'] as String? ?? '';
      _modelController.text = settings['model'] as String;
      _temperatureController.text = (settings['temperature'] as double).toString();
      _maxTokensController.text = (settings['max_tokens'] as int).toString();
      _isEnabled = (settings['enabled'] as int) == 1;
      _isLoading = false;
    });
  }

  /// Uložit nastavení do databáze
  Future<void> _saveSettings() async {
    try {
      await _db.updateSettings(
        apiKey: _apiKeyController.text.trim(),
        model: _modelController.text.trim(),
        temperature: double.tryParse(_temperatureController.text) ?? 1.0,
        maxTokens: int.tryParse(_maxTokensController.text) ?? 1000,
        enabled: _isEnabled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Nastavení bylo úspěšně uloženo'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při ukládání: $e'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    'Konfigurace AI modelu pro motivační zprávy.\nAPI klíč můžeš získat na openrouter.ai',
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

          // Enable/Disable switch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.appColors.bgAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.base3),
            ),
            child: Row(
              children: [
                Icon(
                  _isEnabled ? Icons.check_circle : Icons.cancel,
                  color: _isEnabled ? theme.appColors.green : theme.appColors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Motivace',
                        style: TextStyle(
                          color: theme.appColors.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEnabled ? 'Zapnuto' : 'Vypnuto',
                        style: TextStyle(
                          color: theme.appColors.base5,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: (value) {
                    setState(() => _isEnabled = value);
                  },
                  activeThumbColor: theme.appColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // API Key
          _buildSectionTitle('🔑 API Klíč'),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            style: TextStyle(
              color: theme.appColors.fg,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'sk-or-v1-xxxxxxxxxxxxxxxx',
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
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  color: theme.appColors.base5,
                ),
                onPressed: () {
                  setState(() => _obscureApiKey = !_obscureApiKey);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model
          _buildSectionTitle('🤖 AI Model'),
          const SizedBox(height: 8),
          TextField(
            controller: _modelController,
            style: TextStyle(
              color: theme.appColors.fg,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'mistralai/mistral-medium-3.1',
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
          const SizedBox(height: 12),

          // Populární modely
          Text(
            'Populární modely:',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularModels.map((model) {
              return InkWell(
                onTap: () {
                  setState(() => _modelController.text = model);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _modelController.text == model
                        ? theme.appColors.cyan.withValues(alpha: 0.2)
                        : theme.appColors.base2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _modelController.text == model
                          ? theme.appColors.cyan
                          : theme.appColors.base4,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    model.split('/').last,
                    style: TextStyle(
                      color: _modelController.text == model
                          ? theme.appColors.cyan
                          : theme.appColors.base5,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Temperature
          _buildSectionTitle('🌡️ Temperature (Kreativita)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _temperatureController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: theme.appColors.fg),
                  decoration: InputDecoration(
                    hintText: '0.0 - 2.0',
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
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.appColors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.appColors.yellow),
                ),
                child: Text(
                  _getTemperatureLabel(),
                  style: TextStyle(
                    color: theme.appColors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Max Tokens
          _buildSectionTitle('📏 Max Tokens (Délka odpovědi)'),
          const SizedBox(height: 8),
          TextField(
            controller: _maxTokensController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: theme.appColors.fg),
            decoration: InputDecoration(
              hintText: '100 - 4000',
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
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'tokens',
                  style: TextStyle(
                    color: theme.appColors.base5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Debug sekce (DATABASE INFO)
          _buildSectionTitle('🔧 DEBUG - Informace o databázi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.appColors.yellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.yellow, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: theme.appColors.yellow, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Debug nástroje pro diagnostiku databáze',
                        style: TextStyle(
                          color: theme.appColors.yellow,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final info = await DatabaseDebugUtils.getDatabaseInfo();
                      final isValid = await DatabaseDebugUtils.validateDatabaseStructure();

                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: theme.appColors.bg,
                            title: Text(
                              'Databáze Info',
                              style: TextStyle(color: theme.appColors.cyan),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Verze: ${info['version']}',
                                    style: TextStyle(
                                      color: theme.appColors.fg,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tabulky: ${(info['tables'] as List).join(', ')}',
                                    style: TextStyle(
                                      color: theme.appColors.fg,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sloupce v todos: ${(info['todos_columns'] as List).join(', ')}',
                                    style: TextStyle(
                                      color: theme.appColors.fg,
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isValid
                                          ? theme.appColors.green.withValues(alpha: 0.2)
                                          : theme.appColors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isValid ? '✅ Databáze je validní' : '❌ Databáze má chybnou strukturu',
                                      style: TextStyle(
                                        color: isValid ? theme.appColors.green : theme.appColors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Zavřít', style: TextStyle(color: theme.appColors.cyan)),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Chyba: $e'),
                            backgroundColor: theme.appColors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.info, size: 18),
                  label: const Text('ZOBRAZIT INFO DATABÁZE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.cyan,
                    foregroundColor: theme.appColors.bg,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Potvrzující dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: theme.appColors.bg,
                        title: Text(
                          '⚠️ POZOR',
                          style: TextStyle(color: theme.appColors.red),
                        ),
                        content: Text(
                          'Opravdu chceš resetovat databázi?\n\n'
                          'Tato akce SMAŽE všechna data (TODO úkoly, nastavení, prompty) a vytvoří čistou databázi.\n\n'
                          'Toto nelze vrátit zpět!',
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
                            child: const Text('SMAZAT VŠE'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await DatabaseDebugUtils.resetDatabase();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Databáze byla resetována. Restartuj aplikaci.'),
                              backgroundColor: theme.appColors.green,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Chyba při resetování: $e'),
                              backgroundColor: theme.appColors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('RESETOVAT DATABÁZI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.red,
                    foregroundColor: theme.appColors.bg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.green,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ULOŽIT NASTAVENÍ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.appColors.fg,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getTemperatureLabel() {
    final temp = double.tryParse(_temperatureController.text) ?? 1.0;
    if (temp < 0.3) return 'Minimální';
    if (temp < 0.7) return 'Nízká';
    if (temp < 1.3) return 'Střední';
    if (temp < 1.7) return 'Vysoká';
    return 'Maximální';
  }
}

/// Tab s motivačními prompty
class _PromptsTab extends StatefulWidget {
  const _PromptsTab();

  @override
  State<_PromptsTab> createState() => _PromptsTabState();
}

class _PromptsTabState extends State<_PromptsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _prompts = [];
  bool _isLoading = true;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  /// Načíst všechny prompty z databáze
  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    final prompts = await _db.getAllPrompts();
    setState(() {
      _prompts = prompts;
      _isLoading = false;
    });
  }

  /// Zobrazit dialog pro editaci promptu
  Future<void> _editPrompt(Map<String, dynamic> prompt) async {
    final categoryController = TextEditingController(text: prompt['category']);
    final promptController = TextEditingController(text: prompt['system_prompt']);
    final tagsController = TextEditingController(
      text: (prompt['tags'] as String)
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', ''),
    );
    final styleController = TextEditingController(text: prompt['style']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.cyan, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.edit, color: theme.appColors.cyan, size: 28),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'EDITOVAT PROMPT',
                        style: TextStyle(
                          color: theme.appColors.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                _buildDialogField('Kategorie', categoryController, 'práce, domov, sport...'),
                const SizedBox(height: 16),
                _buildDialogField('System Prompt (Jak má AI mluvit)', promptController, 'Jsi můj motivační kouč...', maxLines: 10),
                const SizedBox(height: 16),
                _buildDialogField('Tagy (oddělené čárkou)', tagsController, 'práce, work, job, office'),
                const SizedBox(height: 16),
                _buildDialogField('Styl', styleController, 'profesionální, rodinný, sportovní...'),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final db = await _db.database;
                        final tagsList = tagsController.text.split(',').map((t) => '"${t.trim()}"').join(',');

                        await db.update(
                          'custom_prompts',
                          {
                            'category': categoryController.text.trim(),
                            'system_prompt': promptController.text.trim(),
                            'tags': '[$tagsList]',
                            'style': styleController.text.trim(),
                          },
                          where: 'id = ?',
                          whereArgs: [prompt['id']],
                        );

                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.appColors.cyan,
                        foregroundColor: theme.appColors.bg,
                      ),
                      child: const Text('Uložit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Prompt byl úspěšně uložen'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    }
  }

  /// Přidat nový prompt
  Future<void> _addPrompt() async {
    final categoryController = TextEditingController();
    final promptController = TextEditingController(
      text: 'Jsi motivační kouč. Tvým úkolem je motivovat uživatele k dokončení úkolu. Buď stručný, inspirativní a konkrétní. Používej emoji.',
    );
    final tagsController = TextEditingController();
    final styleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.green, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: theme.appColors.green, size: 28),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'NOVÝ PROMPT',
                        style: TextStyle(
                          color: theme.appColors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                _buildDialogField('Kategorie', categoryController, 'práce, domov, sport...'),
                const SizedBox(height: 16),
                _buildDialogField('System Prompt (Jak má AI mluvit)', promptController, 'Jsi můj motivační kouč...', maxLines: 10),
                const SizedBox(height: 16),
                _buildDialogField('Tagy (oddělené čárkou)', tagsController, 'práce, work, job, office'),
                const SizedBox(height: 16),
                _buildDialogField('Styl', styleController, 'profesionální, rodinný, sportovní...'),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (categoryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Kategorie nesmí být prázdná'),
                              backgroundColor: theme.appColors.red,
                            ),
                          );
                          return;
                        }

                        final db = await _db.database;
                        final tagsList = tagsController.text.split(',').map((t) => '"${t.trim()}"').join(',');

                        try {
                          await db.insert('custom_prompts', {
                            'category': categoryController.text.trim(),
                            'system_prompt': promptController.text.trim(),
                            'tags': '[$tagsList]',
                            'style': styleController.text.trim(),
                          });

                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chyba: $e'),
                                backgroundColor: theme.appColors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.appColors.green,
                        foregroundColor: theme.appColors.bg,
                      ),
                      child: const Text('Přidat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Prompt byl úspěšně přidán'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    }
  }

  /// Smazat prompt
  Future<void> _deletePrompt(Map<String, dynamic> prompt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        title: Text('Smazat prompt?', style: TextStyle(color: theme.appColors.red)),
        content: Text(
          'Opravdu chceš smazat prompt "${prompt['category']}"?',
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
      final db = await _db.database;
      await db.delete('custom_prompts', where: 'id = ?', whereArgs: [prompt['id']]);

      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Prompt byl smazán'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Info panel
        Container(
          color: theme.appColors.bgAlt,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.appColors.magenta),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zde můžeš upravit AI prompty pro různé kategorie úkolů.',
                  style: TextStyle(color: theme.appColors.fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.appColors.base3),

        // Seznam promptů
        Expanded(
          child: _prompts.isEmpty
              ? Center(
                  child: Text(
                    'Žádné prompty.\nPřidej první!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: theme.appColors.base5),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _prompts.length,
                  itemBuilder: (context, index) => _buildPromptCard(_prompts[index]),
                ),
        ),

        // Add button (sticky bottom)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            border: Border(top: BorderSide(color: theme.appColors.base3)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPrompt,
              icon: const Icon(Icons.add),
              label: const Text('PŘIDAT NOVÝ PROMPT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.green,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(Map<String, dynamic> prompt) {
    final tags = (prompt['tags'] as String)
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((t) => t.trim())
        .toList();

    return Card(
      color: theme.appColors.bgAlt,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.appColors.base3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prompt['category'] as String,
                    style: TextStyle(
                      color: theme.appColors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.appColors.cyan, size: 20),
                  onPressed: () => _editPrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.appColors.red, size: 20),
                  onPressed: () => _deletePrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Styl: ${prompt['style']}',
              style: TextStyle(
                color: theme.appColors.base5,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.appColors.magenta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.appColors.magenta, width: 1),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: theme.appColors.magenta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.base2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt['system_prompt'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: theme.appColors.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.appColors.base5),
            filled: true,
            fillColor: theme.appColors.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.appColors.base4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tab pro výběr témat
class _ThemesTab extends StatefulWidget {
  const _ThemesTab();

  @override
  State<_ThemesTab> createState() => _ThemesTabState();
}

class _ThemesTabState extends State<_ThemesTab> {
  final DatabaseHelper _db = DatabaseHelper();
  String _selectedTheme = 'doom_one';
  bool _isLoading = true;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

  /// Definice dostupných témat
  final List<Map<String, dynamic>> _availableThemes = [
    {
      'id': 'doom_one',
      'name': 'Doom One',
      'description': 'Klasické tmavé téma inspirované Emacs Doom',
      'icon': '🌑',
      'colors': {
        'primary': DoomOneTheme.cyan,
        'secondary': DoomOneTheme.magenta,
        'accent': DoomOneTheme.green,
        'background': DoomOneTheme.bg,
      },
    },
    {
      'id': 'blade_runner',
      'name': 'Blade Runner 2049',
      'description': 'Sci-fi téma inspirované filmem Blade Runner 2049',
      'icon': '🌃',
      'colors': {
        'primary': BladeRunnerTheme.cyan,
        'secondary': BladeRunnerTheme.magenta,
        'accent': BladeRunnerTheme.yellow,
        'background': BladeRunnerTheme.bg,
      },
    },
    {
      'id': 'osaka_jade',
      'name': 'Osaka Jade',
      'description': 'Japonské neonové město s jadenou zelení',
      'icon': '🏙️',
      'colors': {
        'primary': OsakaJadeTheme.cyan,
        'secondary': OsakaJadeTheme.magenta,
        'accent': OsakaJadeTheme.green,
        'background': OsakaJadeTheme.bg,
      },
    },
    {
      'id': 'amoled',
      'name': 'AMOLED Black',
      'description': 'Maximálně černé téma pro OLED displeje s béžovými prvky',
      'icon': '⬛',
      'colors': {
        'primary': AmoledTheme.cyan,
        'secondary': AmoledTheme.magenta,
        'accent': AmoledTheme.green,
        'background': AmoledTheme.bg,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedTheme();
  }

  /// Načíst aktuálně vybrané téma z databáze
  Future<void> _loadSelectedTheme() async {
    setState(() => _isLoading = true);
    final settings = await _db.getSettings();
    setState(() {
      _selectedTheme = settings['selected_theme'] as String? ?? 'doom_one';
      _isLoading = false;
    });
  }

  /// Uložit a okamžitě aplikovat vybrané téma
  Future<void> _saveTheme(String themeId) async {
    try {
      // Zavolat SettingsCubit.changeTheme() - okamžitě aplikuje téma
      context.read<SettingsCubit>().changeTheme(themeId);

      setState(() => _selectedTheme = themeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Téma bylo okamžitě aplikováno!'),
            backgroundColor: theme.appColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při ukládání: $e'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Info panel
        Container(
          color: theme.appColors.bgAlt,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.appColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vyber vizuální téma aplikace. Pro aplikování změn je potřeba restartovat aplikaci.',
                  style: TextStyle(color: theme.appColors.fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.appColors.base3),

        // Seznam témat
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _availableThemes.length,
            itemBuilder: (context, index) {
              final themeItem = _availableThemes[index];
              final isSelected = _selectedTheme == themeItem['id'];

              return Card(
                color: isSelected ? theme.appColors.bgAlt : theme.appColors.base2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? theme.appColors.cyan : theme.appColors.base3,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _saveTheme(themeItem['id'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header s názvem tématu
                        Row(
                          children: [
                            Text(
                              themeItem['icon'] as String,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    themeItem['name'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? theme.appColors.cyan
                                          : theme.appColors.fg,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    themeItem['description'] as String,
                                    style: TextStyle(
                                      color: theme.appColors.base5,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.appColors.cyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.appColors.cyan,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: theme.appColors.cyan,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'AKTIVNÍ',
                                      style: TextStyle(
                                        color: theme.appColors.cyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Náhled barev
                        Text(
                          'Náhled barev:',
                          style: TextStyle(
                            color: theme.appColors.base5,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildColorChip(
                              'Primary',
                              (themeItem['colors'] as Map<String, Color>)['primary']!,
                            ),
                            const SizedBox(width: 8),
                            _buildColorChip(
                              'Secondary',
                              (themeItem['colors'] as Map<String, Color>)['secondary']!,
                            ),
                            const SizedBox(width: 8),
                            _buildColorChip(
                              'Accent',
                              (themeItem['colors'] as Map<String, Color>)['accent']!,
                            ),
                            const SizedBox(width: 8),
                            _buildColorChip(
                              'Background',
                              (themeItem['colors'] as Map<String, Color>)['background']!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Vytvořit barevný chip pro náhled
  Widget _buildColorChip(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.appColors.base4,
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
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
    return Card(
      color: theme.appColors.bgAlt,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.appColors.base3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (view.color ?? theme.appColors.magenta).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: view.color ?? theme.appColors.magenta,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  view.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.name,
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tag: ${view.tagFilter}',
                    style: TextStyle(
                      color: theme.appColors.base5,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.appColors.cyan, size: 20),
                  onPressed: () => _showEditCustomViewDialog(context, theme, view),
                  tooltip: 'Upravit',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.appColors.red, size: 20),
                  onPressed: () => _deleteCustomView(context, theme, view),
                  tooltip: 'Smazat',
                ),
              ],
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
            const SizedBox(height: 8),
            TextField(
              controller: _tagController,
              style: TextStyle(
                color: theme.appColors.fg,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'projekt, nakup, sport',
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
                    bgColor: theme.appColors.bg,
                    categoryViewConfig: CategoryViewConfig(
                      indicatorColor: theme.appColors.cyan,
                      iconColor: theme.appColors.base5,
                      iconColorSelected: theme.appColors.cyan,
                      backgroundColor: theme.appColors.bg,
                      categoryIcons: const CategoryIcons(),
                    ),
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: theme.appColors.bg,
                      buttonMode: ButtonMode.MATERIAL,
                      columns: 8,
                      emojiSizeMax: 28,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: theme.appColors.bgAlt,
                      hintText: 'Hledat emoji...',
                    ),
                    skinToneConfig: const SkinToneConfig(
                      enabled: true,
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
