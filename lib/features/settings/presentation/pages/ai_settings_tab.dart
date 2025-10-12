import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/models/openrouter_model.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/database_debug_utils.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../ai_split/data/datasources/openrouter_datasource.dart';

/// Tab s AI nastavením (API klíč, model, temperature, max_tokens)
class AISettingsTab extends StatefulWidget {
  const AISettingsTab({super.key});

  @override
  State<AISettingsTab> createState() => _AISettingsTabState();
}

class _AISettingsTabState extends State<AISettingsTab> {
  final DatabaseHelper _db = DatabaseHelper();

  // ===== MOTIVATION MODEL =====
  final TextEditingController _motivationTempController = TextEditingController();
  final TextEditingController _motivationTokensController = TextEditingController();
  String? _selectedMotivationModel;

  // ===== TASK MODEL =====
  final TextEditingController _taskTempController = TextEditingController();
  final TextEditingController _taskTokensController = TextEditingController();
  String? _selectedTaskModel;

  // ===== SHARED =====
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isLoading = true;
  bool _isEnabled = true;

  // Model dropdown state
  List<OpenRouterModel> _availableModels = [];
  bool _isLoadingModels = false;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

  // Doporučené modely podle účelu
  final List<String> _motivationModels = [
    'mistralai/mistral-medium',
    'mistralai/mistral-large',
    'anthropic/claude-3-opus',
    'openai/gpt-4o',
  ];

  final List<String> _taskModels = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-opus',
    'openai/gpt-4o',
    'google/gemini-pro-1.5',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchModels(); // Načíst modely z OpenRouter API
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _motivationTempController.dispose();
    _motivationTokensController.dispose();
    _taskTempController.dispose();
    _taskTokensController.dispose();
    super.dispose();
  }

  /// Načíst AI nastavení z databáze
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await _db.getSettings();

    setState(() {
      // Shared
      _apiKeyController.text = settings['openrouter_api_key'] as String? ?? '';
      _isEnabled = (settings['enabled'] as int) == 1;

      // Motivation
      _selectedMotivationModel = settings['ai_motivation_model'] as String;
      _motivationTempController.text = (settings['ai_motivation_temperature'] as double).toString();
      _motivationTokensController.text = (settings['ai_motivation_max_tokens'] as int).toString();

      // Task
      _selectedTaskModel = settings['ai_task_model'] as String;
      _taskTempController.text = (settings['ai_task_temperature'] as double).toString();
      _taskTokensController.text = (settings['ai_task_max_tokens'] as int).toString();

      _isLoading = false;
    });
  }

  /// Načíst seznam modelů z OpenRouter API
  Future<void> _fetchModels() async {
    setState(() => _isLoadingModels = true);

    try {
      final client = http.Client();
      final openRouterDataSource = OpenRouterDataSource(client: client);

      // Fetch models z API
      final models = await openRouterDataSource.fetchAvailableModels();

      // Seřadit modely: podle providera (A-Z), pak FREE → nejlevnější → nejdražší
      models.sort((a, b) {
        // 1. Seřadit podle providera (alphabetically)
        final providerCompare = a.provider.compareTo(b.provider);
        if (providerCompare != 0) return providerCompare;

        // 2. FREE modely na začátek (v rámci providera)
        if (a.isFree && !b.isFree) return -1;
        if (!a.isFree && b.isFree) return 1;

        // 3. Seřadit podle ceny (od nejlevnějšího)
        final priceA = a.averagePrice ?? double.infinity;
        final priceB = b.averagePrice ?? double.infinity;
        return priceA.compareTo(priceB);
      });

      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });

      client.close();
    } catch (e) {
      setState(() => _isLoadingModels = false);

      // Fallback na doporučené modely jako OpenRouterModel objekty (bez pricing)
      final fallbackModels = [..._motivationModels, ..._taskModels].toSet().toList();
      setState(() {
        _availableModels = fallbackModels
            .map((id) => OpenRouterModel(
                  id: id,
                  name: id.split('/').last,
                ))
            .toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Nepodařilo se načíst modely z API. Použity doporučené modely.'),
            backgroundColor: theme.appColors.yellow,
          ),
        );
      }
    }
  }

  /// Vytvořit strukturované dropdown items (seskupené podle providera, seřazené podle ceny)
  List<DropdownMenuItem<String>> _buildModelDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    // Custom input option
    items.add(DropdownMenuItem<String>(
      value: null,
      child: Text(
        '✏️ Zadat vlastní model...',
        style: TextStyle(
          color: theme.appColors.base5,
          fontStyle: FontStyle.italic,
        ),
      ),
    ));

    if (_availableModels.isEmpty) return items;

    // Separator
    items.add(const DropdownMenuItem<String>(
      enabled: false,
      value: '__separator__',
      child: Divider(height: 1),
    ));

    // Seskupit modely podle providera
    String? currentProvider;

    for (final model in _availableModels) {
      // Pokud je nový provider, přidat header row
      if (model.provider != currentProvider) {
        currentProvider = model.provider;

        // Provider header (disabled, styled)
        items.add(DropdownMenuItem<String>(
          enabled: false,
          value: '__header_$currentProvider',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '━━━ ${currentProvider.toUpperCase()} ━━━',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ));
      }

      // Model row s ID a cenou
      items.add(DropdownMenuItem<String>(
        value: model.id,
        child: Row(
          children: [
            Expanded(
              child: Text(
                model.shortLabel,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              model.priceLabel,
              style: TextStyle(
                fontSize: 10,
                color: model.isFree ? theme.appColors.green : theme.appColors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ));
    }

    return items;
  }

  /// Zobrazit dialog pro zadání vlastního model ID
  Future<void> _showCustomModelDialog(ValueChanged<String?> onChanged) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.cyan, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.edit, color: theme.appColors.cyan, size: 28),
            const SizedBox(width: 12),
            Text(
              'VLASTNÍ MODEL',
              style: TextStyle(
                color: theme.appColors.cyan,
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
              Text(
                'Zadej ID modelu (např. mistralai/mistral-medium-3.1)',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'vendor/model-name',
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('❌ Model ID nesmí být prázdné'),
                    backgroundColor: theme.appColors.red,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.cyan,
              foregroundColor: theme.appColors.bg,
            ),
            child: const Text('Potvrdit'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      onChanged(result);
    }
  }

  /// Uložit nastavení do databáze
  Future<void> _saveSettings() async {
    try {
      await _db.updateSettings(
        // Shared
        openRouterApiKey: _apiKeyController.text.trim(),
        enabled: _isEnabled,

        // Motivation
        aiMotivationModel: _selectedMotivationModel?.trim() ?? 'mistralai/mistral-medium',
        aiMotivationTemperature: double.tryParse(_motivationTempController.text) ?? 0.9,
        aiMotivationMaxTokens: int.tryParse(_motivationTokensController.text) ?? 200,

        // Task
        aiTaskModel: _selectedTaskModel?.trim() ?? 'anthropic/claude-3.5-sonnet',
        aiTaskTemperature: double.tryParse(_taskTempController.text) ?? 0.3,
        aiTaskMaxTokens: int.tryParse(_taskTokensController.text) ?? 1000,
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
          // ===== INFO PANEL =====
          _buildInfoPanel(),
          const SizedBox(height: 24),

          // ===== ENABLE/DISABLE SWITCH =====
          _buildEnableSwitch(),
          const SizedBox(height: 24),

          // ===== API KEY (SHARED) =====
          _buildSectionTitle('🔑 OpenRouter API Klíč (společný pro oba modely)'),
          const SizedBox(height: 8),
          _buildApiKeyField(),
          const SizedBox(height: 32),

          // ===== SEKCE 1: MOTIVACE =====
          _buildDivider('💬 MODEL PRO MOTIVACI', 'Uncensored, kreativní'),
          const SizedBox(height: 16),
          _buildMotivationSection(),
          const SizedBox(height: 32),

          // ===== SEKCE 2: TASK SPLIT =====
          _buildDivider('🧠 MODEL PRO ROZDĚLENÍ ÚKOLŮ', 'Seriózní práce, JSON-ready'),
          const SizedBox(height: 16),
          _buildTaskSection(),
          const SizedBox(height: 32),

          // ===== DEBUG (optional) =====
          _buildDebugSection(),
          const SizedBox(height: 32),

          // ===== SAVE BUTTON =====
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===== HELPER METODY =====

  Widget _buildInfoPanel() {
    return Container(
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
              'Konfigurace AI modelů pro motivaci a rozdělení úkolů.\nAPI klíč můžeš získat na openrouter.ai',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
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

          // Model - Dropdown s možností vlastního textu
          _buildSectionTitle('🤖 AI Model'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.appColors.base2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.base4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _availableModels.any((m) => m.id == _selectedModel) ? _selectedModel : null,
                      isExpanded: true,
                      dropdownColor: theme.appColors.base2,
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      hint: Text(
                        _selectedModel ?? 'mistralai/mistral-medium-3.1',
                        style: TextStyle(
                          color: theme.appColors.fg,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: _buildModelDropdownItems(),
                      onChanged: (value) {
                        if (value == null) {
                          // Zobrazit dialog pro vlastní model
                          _showCustomModelDialog();
                        } else if (!value.startsWith('__')) {
                          // Ignorovat header rows (začínají '__')
                          setState(() {
                            _selectedModel = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Refresh button vedle dropdownu
                if (_isLoadingModels)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Načíst modely z OpenRouter API',
                    onPressed: _fetchModels,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick select populární modely
          Text(
            'Rychlý výběr:',
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
              final isSelected = _selectedModel == model;
              return InkWell(
                onTap: () {
                  setState(() => _selectedModel = model);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.appColors.cyan.withValues(alpha: 0.2)
                        : theme.appColors.base2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? theme.appColors.cyan : theme.appColors.base4,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    model.split('/').last,
                    style: TextStyle(
                      color: isSelected ? theme.appColors.cyan : theme.appColors.base5,
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
