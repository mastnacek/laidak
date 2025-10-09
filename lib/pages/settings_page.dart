import 'package:flutter/material.dart';
import '../theme/doom_one_theme.dart';
import '../services/database_helper.dart';
import '../services/tag_service.dart';
import '../models/tag_definition.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASTAVENÍ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DoomOneTheme.cyan,
          labelColor: DoomOneTheme.cyan,
          unselectedLabelColor: DoomOneTheme.base5,
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AISettingsTab(),
          _PromptsTab(),
          _TagManagementTab(),
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
            backgroundColor: DoomOneTheme.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při ukládání: $e'),
            backgroundColor: DoomOneTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: DoomOneTheme.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DoomOneTheme.blue, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: DoomOneTheme.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konfigurace AI modelu pro motivační zprávy.\nAPI klíč můžeš získat na openrouter.ai',
                    style: TextStyle(
                      color: DoomOneTheme.fg,
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
              color: DoomOneTheme.bgAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DoomOneTheme.base3),
            ),
            child: Row(
              children: [
                Icon(
                  _isEnabled ? Icons.check_circle : Icons.cancel,
                  color: _isEnabled ? DoomOneTheme.green : DoomOneTheme.red,
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
                          color: DoomOneTheme.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEnabled ? 'Zapnuto' : 'Vypnuto',
                        style: TextStyle(
                          color: DoomOneTheme.base5,
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
                  activeColor: DoomOneTheme.green,
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
              color: DoomOneTheme.fg,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'sk-or-v1-xxxxxxxxxxxxxxxx',
              hintStyle: TextStyle(color: DoomOneTheme.base5),
              filled: true,
              fillColor: DoomOneTheme.base2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.cyan, width: 2),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  color: DoomOneTheme.base5,
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
              color: DoomOneTheme.fg,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'mistralai/mistral-medium-3.1',
              hintStyle: TextStyle(color: DoomOneTheme.base5),
              filled: true,
              fillColor: DoomOneTheme.base2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.cyan, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Populární modely
          Text(
            'Populární modely:',
            style: TextStyle(
              color: DoomOneTheme.base5,
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
                        ? DoomOneTheme.cyan.withOpacity(0.2)
                        : DoomOneTheme.base2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _modelController.text == model
                          ? DoomOneTheme.cyan
                          : DoomOneTheme.base4,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    model.split('/').last,
                    style: TextStyle(
                      color: _modelController.text == model
                          ? DoomOneTheme.cyan
                          : DoomOneTheme.base5,
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
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: '0.0 - 2.0',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.cyan, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DoomOneTheme.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DoomOneTheme.yellow),
                ),
                child: Text(
                  _getTemperatureLabel(),
                  style: TextStyle(
                    color: DoomOneTheme.yellow,
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
            style: TextStyle(color: DoomOneTheme.fg),
            decoration: InputDecoration(
              hintText: '100 - 4000',
              hintStyle: TextStyle(color: DoomOneTheme.base5),
              filled: true,
              fillColor: DoomOneTheme.base2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.base4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: DoomOneTheme.cyan, width: 2),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'tokens',
                  style: TextStyle(
                    color: DoomOneTheme.base5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: DoomOneTheme.green,
                foregroundColor: DoomOneTheme.bg,
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
        color: DoomOneTheme.fg,
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
        backgroundColor: DoomOneTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DoomOneTheme.cyan, width: 2),
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
                    Icon(Icons.edit, color: DoomOneTheme.cyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'EDITOVAT PROMPT',
                        style: TextStyle(
                          color: DoomOneTheme.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: DoomOneTheme.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: DoomOneTheme.base3, height: 24),

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
                      child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
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
                        backgroundColor: DoomOneTheme.cyan,
                        foregroundColor: DoomOneTheme.bg,
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
            backgroundColor: DoomOneTheme.green,
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
        backgroundColor: DoomOneTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DoomOneTheme.green, width: 2),
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
                    Icon(Icons.add_circle, color: DoomOneTheme.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'NOVÝ PROMPT',
                        style: TextStyle(
                          color: DoomOneTheme.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: DoomOneTheme.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: DoomOneTheme.base3, height: 24),

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
                      child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (categoryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Kategorie nesmí být prázdná'),
                              backgroundColor: DoomOneTheme.red,
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
                                backgroundColor: DoomOneTheme.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoomOneTheme.green,
                        foregroundColor: DoomOneTheme.bg,
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
            backgroundColor: DoomOneTheme.green,
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
        backgroundColor: DoomOneTheme.bg,
        title: Text('Smazat prompt?', style: TextStyle(color: DoomOneTheme.red)),
        content: Text(
          'Opravdu chceš smazat prompt "${prompt['category']}"?',
          style: TextStyle(color: DoomOneTheme.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoomOneTheme.red,
              foregroundColor: DoomOneTheme.bg,
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
            backgroundColor: DoomOneTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Info panel
        Container(
          color: DoomOneTheme.bgAlt,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: DoomOneTheme.magenta),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zde můžeš upravit AI prompty pro různé kategorie úkolů.',
                  style: TextStyle(color: DoomOneTheme.fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: DoomOneTheme.base3),

        // Seznam promptů
        Expanded(
          child: _prompts.isEmpty
              ? Center(
                  child: Text(
                    'Žádné prompty.\nPřidej první!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: DoomOneTheme.base5),
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
            color: DoomOneTheme.bg,
            border: Border(top: BorderSide(color: DoomOneTheme.base3)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPrompt,
              icon: const Icon(Icons.add),
              label: const Text('PŘIDAT NOVÝ PROMPT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoomOneTheme.green,
                foregroundColor: DoomOneTheme.bg,
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
      color: DoomOneTheme.bgAlt,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: DoomOneTheme.base3),
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
                      color: DoomOneTheme.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: DoomOneTheme.cyan, size: 20),
                  onPressed: () => _editPrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete, color: DoomOneTheme.red, size: 20),
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
                color: DoomOneTheme.base5,
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
                    color: DoomOneTheme.magenta.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: DoomOneTheme.magenta, width: 1),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: DoomOneTheme.magenta,
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
                color: DoomOneTheme.base2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt['system_prompt'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DoomOneTheme.fg,
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
            color: DoomOneTheme.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: DoomOneTheme.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DoomOneTheme.base5),
            filled: true,
            fillColor: DoomOneTheme.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: DoomOneTheme.base4),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tab pro správu tagů
class _TagManagementTab extends StatefulWidget {
  const _TagManagementTab();

  @override
  State<_TagManagementTab> createState() => _TagManagementTabState();
}

class _TagManagementTabState extends State<_TagManagementTab> {
  final TagService _tagService = TagService();
  List<TagDefinition> _allTags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  /// Načíst všechny tagy z databáze
  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await _tagService.loadAllDefinitionsFromDb();
    setState(() {
      _allTags = tags;
      _isLoading = false;
    });
  }

  /// Zobrazit dialog pro editaci tagu
  Future<void> _editTag(TagDefinition tag) async {
    final nameController = TextEditingController(text: tag.tagName);
    final displayNameController = TextEditingController(text: tag.displayName ?? '');
    final emojiController = TextEditingController(text: tag.emoji ?? '');
    final colorController = TextEditingController(text: tag.color ?? '');
    TagType selectedType = tag.tagType;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: DoomOneTheme.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: DoomOneTheme.cyan, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.edit, color: DoomOneTheme.cyan, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'EDITOVAT TAG',
                          style: TextStyle(
                            color: DoomOneTheme.cyan,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: DoomOneTheme.base5),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  Divider(color: DoomOneTheme.base3, height: 24),

                  _buildDialogField('Název tagu (bez hvězdiček)', nameController, 'např. dnes, a, udelat'),
                  const SizedBox(height: 16),

                  _buildDialogField('Zobrazovaný název', displayNameController, 'např. Dnešní termín, Vysoká priorita'),
                  const SizedBox(height: 16),

                  _buildDialogField('Emoji', emojiController, '🔥'),
                  const SizedBox(height: 16),

                  _buildDialogField('Barva (hex)', colorController, '#FF5555'),
                  const SizedBox(height: 16),

                  // Typ tagu dropdown
                  Text(
                    'Typ tagu',
                    style: TextStyle(
                      color: DoomOneTheme.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TagType>(
                    value: selectedType,
                    dropdownColor: DoomOneTheme.base2,
                    style: TextStyle(color: DoomOneTheme.fg),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: DoomOneTheme.base2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: DoomOneTheme.base4),
                      ),
                    ),
                    items: TagType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tlačítka
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final updatedTag = tag.copyWith(
                            tagName: nameController.text.trim().toLowerCase(),
                            displayName: displayNameController.text.trim(),
                            emoji: emojiController.text.trim(),
                            color: colorController.text.trim(),
                            tagType: selectedType,
                          );

                          await _tagService.updateDefinition(updatedTag);
                          if (context.mounted) Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoomOneTheme.cyan,
                          foregroundColor: DoomOneTheme.bg,
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
      ),
    );

    if (result == true) {
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Tag byl úspěšně uložen'),
            backgroundColor: DoomOneTheme.green,
          ),
        );
      }
    }
  }

  /// Přidat nový tag
  Future<void> _addTag() async {
    final nameController = TextEditingController();
    final displayNameController = TextEditingController();
    final emojiController = TextEditingController();
    final colorController = TextEditingController();
    TagType selectedType = TagType.custom;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: DoomOneTheme.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: DoomOneTheme.green, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle, color: DoomOneTheme.green, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'NOVÝ TAG',
                          style: TextStyle(
                            color: DoomOneTheme.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: DoomOneTheme.base5),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  Divider(color: DoomOneTheme.base3, height: 24),

                  _buildDialogField('Název tagu (bez hvězdiček)', nameController, 'např. vikend, projekt'),
                  const SizedBox(height: 16),

                  _buildDialogField('Zobrazovaný název', displayNameController, 'např. Víkendový úkol'),
                  const SizedBox(height: 16),

                  _buildDialogField('Emoji', emojiController, '🏖️'),
                  const SizedBox(height: 16),

                  _buildDialogField('Barva (hex)', colorController, '#50FA7B'),
                  const SizedBox(height: 16),

                  Text(
                    'Typ tagu',
                    style: TextStyle(
                      color: DoomOneTheme.fg,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TagType>(
                    value: selectedType,
                    dropdownColor: DoomOneTheme.base2,
                    style: TextStyle(color: DoomOneTheme.fg),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: DoomOneTheme.base2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: DoomOneTheme.base4),
                      ),
                    ),
                    items: TagType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Název tagu nesmí být prázdný'),
                                backgroundColor: DoomOneTheme.red,
                              ),
                            );
                            return;
                          }

                          final newTag = TagDefinition(
                            tagName: nameController.text.trim().toLowerCase(),
                            tagType: selectedType,
                            displayName: displayNameController.text.trim(),
                            emoji: emojiController.text.trim(),
                            color: colorController.text.trim(),
                            enabled: true,
                          );

                          try {
                            await _tagService.addDefinition(newTag);
                            if (context.mounted) Navigator.of(context).pop(true);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chyba: $e'),
                                  backgroundColor: DoomOneTheme.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DoomOneTheme.green,
                          foregroundColor: DoomOneTheme.bg,
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
      ),
    );

    if (result == true) {
      await _loadTags();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Tag byl úspěšně přidán'),
            backgroundColor: DoomOneTheme.green,
          ),
        );
      }
    }
  }

  /// Smazat tag
  Future<void> _deleteTag(TagDefinition tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DoomOneTheme.bg,
        title: Text('Smazat tag?', style: TextStyle(color: DoomOneTheme.red)),
        content: Text(
          'Opravdu chceš smazat tag "*${tag.tagName}*"?',
          style: TextStyle(color: DoomOneTheme.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoomOneTheme.red,
              foregroundColor: DoomOneTheme.bg,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true && tag.id != null) {
      await _tagService.deleteDefinition(tag.id!);
      await _loadTags();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Tag byl smazán'),
            backgroundColor: DoomOneTheme.red,
          ),
        );
      }
    }
  }

  /// Zapnout/vypnout tag
  Future<void> _toggleTag(TagDefinition tag) async {
    if (tag.id != null) {
      await _tagService.toggleDefinition(tag.id!, !tag.enabled);
      await _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Seskupit tagy podle typu
    final tagsByType = <TagType, List<TagDefinition>>{};
    for (final tag in _allTags) {
      tagsByType.putIfAbsent(tag.tagType, () => []).add(tag);
    }

    return Column(
      children: [
        // Info panel
        Container(
          color: DoomOneTheme.bgAlt,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: DoomOneTheme.yellow),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zde můžeš spravovat systémové tagy. Nové tagy se automaticky rozpoznávají v textu úkolů.',
                  style: TextStyle(color: DoomOneTheme.fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: DoomOneTheme.base3),

        // Seznam tagů seskupených podle typu
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: TagType.values.map((type) {
              final tags = tagsByType[type] ?? [];
              if (tags.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Text(
                      type.displayName.toUpperCase(),
                      style: TextStyle(
                        color: DoomOneTheme.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...tags.map((tag) => _buildTagCard(tag)),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          ),
        ),

        // Add button (sticky bottom)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DoomOneTheme.bg,
            border: Border(top: BorderSide(color: DoomOneTheme.base3)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              label: const Text('PŘIDAT NOVÝ TAG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DoomOneTheme.green,
                foregroundColor: DoomOneTheme.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagCard(TagDefinition tag) {
    return Card(
      color: tag.enabled ? DoomOneTheme.bgAlt : DoomOneTheme.base2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: tag.enabled ? DoomOneTheme.base3 : DoomOneTheme.base4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji a název
            Expanded(
              child: Row(
                children: [
                  if (tag.emoji != null && tag.emoji!.isNotEmpty)
                    Text(
                      tag.emoji!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '*${tag.tagName}*',
                          style: TextStyle(
                            color: tag.enabled ? DoomOneTheme.cyan : DoomOneTheme.base5,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (tag.displayName != null && tag.displayName!.isNotEmpty)
                          Text(
                            tag.displayName!,
                            style: TextStyle(
                              color: tag.enabled ? DoomOneTheme.base5 : DoomOneTheme.base6,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enable/disable switch
            Switch(
              value: tag.enabled,
              onChanged: (_) => _toggleTag(tag),
              activeColor: DoomOneTheme.green,
            ),

            // Edit button
            IconButton(
              icon: Icon(Icons.edit, color: DoomOneTheme.cyan, size: 20),
              onPressed: () => _editTag(tag),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete, color: DoomOneTheme.red, size: 20),
              onPressed: () => _deleteTag(tag),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: DoomOneTheme.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: DoomOneTheme.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: DoomOneTheme.base5),
            filled: true,
            fillColor: DoomOneTheme.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: DoomOneTheme.base4),
            ),
          ),
        ),
      ],
    );
  }
}
