import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/models/openrouter_model.dart';
import '../../../../core/models/provider_route.dart';
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

  // ===== REWARD MODEL (prank + good deed) =====
  final TextEditingController _rewardTempController = TextEditingController();
  final TextEditingController _rewardTokensController = TextEditingController();
  String? _selectedRewardModel;

  // ===== AI TAG SUGGESTIONS =====
  final TextEditingController _tagSuggestionsTempController = TextEditingController();
  final TextEditingController _tagSuggestionsTokensController = TextEditingController();
  final TextEditingController _tagSuggestionsSeedController = TextEditingController();
  final TextEditingController _tagSuggestionsTopPController = TextEditingController();
  final TextEditingController _tagSuggestionsDebounceController = TextEditingController();
  String? _selectedTagSuggestionsModel;

  // ===== OPENROUTER PROVIDER ROUTE & CACHE (V36) =====
  ProviderRoute _motivationProviderRoute = ProviderRoute.default_;
  bool _motivationEnableCache = true;
  ProviderRoute _taskProviderRoute = ProviderRoute.floor;
  bool _taskEnableCache = true;
  ProviderRoute _rewardProviderRoute = ProviderRoute.default_;
  bool _rewardEnableCache = true;
  ProviderRoute _tagSuggestionsProviderRoute = ProviderRoute.floor;
  bool _tagSuggestionsEnableCache = true;

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
    'mistralai/mistral-medium-3.1',
  ];

  final List<String> _taskModels = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-opus',
    'openai/gpt-4o',
    'google/gemini-pro-1.5',
  ];

  final List<String> _rewardModels = [
    'anthropic/claude-3.5-sonnet',
    'anthropic/claude-3-opus',
    'openai/gpt-4o',
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
    _rewardTempController.dispose();
    _rewardTokensController.dispose();
    _tagSuggestionsTempController.dispose();
    _tagSuggestionsTokensController.dispose();
    _tagSuggestionsSeedController.dispose();
    _tagSuggestionsTopPController.dispose();
    _tagSuggestionsDebounceController.dispose();
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

      // Reward (prank + good deed)
      _selectedRewardModel = settings['ai_reward_model'] as String;
      _rewardTempController.text = (settings['ai_reward_temperature'] as double).toString();
      _rewardTokensController.text = (settings['ai_reward_max_tokens'] as int).toString();

      // Tag Suggestions
      _selectedTagSuggestionsModel = settings['ai_tag_suggestions_model'] as String;
      _tagSuggestionsTempController.text = (settings['ai_tag_suggestions_temperature'] as double).toString();
      _tagSuggestionsTokensController.text = (settings['ai_tag_suggestions_max_tokens'] as int).toString();
      _tagSuggestionsSeedController.text = settings['ai_tag_suggestions_seed']?.toString() ?? '';
      _tagSuggestionsTopPController.text = settings['ai_tag_suggestions_top_p']?.toString() ?? '';
      _tagSuggestionsDebounceController.text = (settings['ai_tag_suggestions_debounce_ms'] as int).toString();

      // OpenRouter Provider Route & Cache (V36)
      _motivationProviderRoute = ProviderRoute.fromString(settings['ai_motivation_provider_route'] as String? ?? 'default');
      _motivationEnableCache = (settings['ai_motivation_enable_cache'] as int? ?? 1) == 1;
      _taskProviderRoute = ProviderRoute.fromString(settings['ai_task_provider_route'] as String? ?? 'floor');
      _taskEnableCache = (settings['ai_task_enable_cache'] as int? ?? 1) == 1;
      _rewardProviderRoute = ProviderRoute.fromString(settings['ai_reward_provider_route'] as String? ?? 'default');
      _rewardEnableCache = (settings['ai_reward_enable_cache'] as int? ?? 1) == 1;
      _tagSuggestionsProviderRoute = ProviderRoute.fromString(settings['ai_tag_suggestions_provider_route'] as String? ?? 'floor');
      _tagSuggestionsEnableCache = (settings['ai_tag_suggestions_enable_cache'] as int? ?? 1) == 1;

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

      // ✅ Fail Fast: Check mounted PŘED setState
      if (!mounted) {
        client.close();
        return;
      }

      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });

      client.close();
    } catch (e) {
      // ✅ Fail Fast: Check mounted PŘED setState
      if (!mounted) return;

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
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.cyan, width: 2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.minHeight,
                  maxHeight: viewportConstraints.maxHeight,
                  maxWidth: 500,
                ),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.decelerate,
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: IntrinsicHeight(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(Icons.edit, color: theme.appColors.cyan, size: 20),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Vlastní model',
                                  style: TextStyle(
                                    color: theme.appColors.cyan,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: theme.appColors.base5, size: 22),
                                onPressed: () => Navigator.pop(dialogContext, null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                          Divider(color: theme.appColors.base3, height: 16),

                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
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
                          ),
                          const SizedBox(height: 16),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, null),
                                child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5, fontSize: 14)),
                              ),
                              const SizedBox(width: 12),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                child: const Text('Potvrdit', style: TextStyle(fontSize: 14)),
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
          },
        ),
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
        aiMotivationModel: _selectedMotivationModel?.trim() ?? 'mistralai/mistral-medium-3.1',
        aiMotivationTemperature: double.tryParse(_motivationTempController.text) ?? 0.9,
        aiMotivationMaxTokens: int.tryParse(_motivationTokensController.text) ?? 200,

        // Task
        aiTaskModel: _selectedTaskModel?.trim() ?? 'anthropic/claude-3.5-sonnet',
        aiTaskTemperature: double.tryParse(_taskTempController.text) ?? 0.3,
        aiTaskMaxTokens: int.tryParse(_taskTokensController.text) ?? 1000,

        // Reward (prank + good deed)
        aiRewardModel: _selectedRewardModel?.trim() ?? 'anthropic/claude-3.5-sonnet',
        aiRewardTemperature: double.tryParse(_rewardTempController.text) ?? 0.9,
        aiRewardMaxTokens: int.tryParse(_rewardTokensController.text) ?? 1000,

        // Tag Suggestions
        aiTagSuggestionsModel: _selectedTagSuggestionsModel?.trim() ?? 'anthropic/claude-3.5-haiku',
        aiTagSuggestionsTemperature: double.tryParse(_tagSuggestionsTempController.text) ?? 1.0,
        aiTagSuggestionsMaxTokens: int.tryParse(_tagSuggestionsTokensController.text) ?? 500,
        aiTagSuggestionsSeed: int.tryParse(_tagSuggestionsSeedController.text),
        aiTagSuggestionsTopP: double.tryParse(_tagSuggestionsTopPController.text),
        aiTagSuggestionsDebounceMs: int.tryParse(_tagSuggestionsDebounceController.text) ?? 500,

        // OpenRouter Provider Route & Cache (V36)
        aiMotivationProviderRoute: _motivationProviderRoute,
        aiMotivationEnableCache: _motivationEnableCache,
        aiTaskProviderRoute: _taskProviderRoute,
        aiTaskEnableCache: _taskEnableCache,
        aiRewardProviderRoute: _rewardProviderRoute,
        aiRewardEnableCache: _rewardEnableCache,
        aiTagSuggestionsProviderRoute: _tagSuggestionsProviderRoute,
        aiTagSuggestionsEnableCache: _tagSuggestionsEnableCache,
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

          // ===== SEKCE 3: REWARD (PRANK + GOOD DEED) =====
          _buildDivider('🎁 REWARD MODEL (PRANKY & DOBRÉ SKUTKY)', 'Model pro děti po splnění úkolů'),
          const SizedBox(height: 16),
          _buildRewardSection(),
          const SizedBox(height: 32),

          // ===== SEKCE 4: AI TAG SUGGESTIONS =====
          _buildDivider('🏷️ AI TAG SUGGESTIONS', 'Real-time návrhy tagů při psaní úkolů'),
          const SizedBox(height: 16),
          _buildTagSuggestionsSection(),
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
                  'AI Funkce',
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
    );
  }

  Widget _buildApiKeyField() {
    return TextField(
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
    );
  }

  Widget _buildDivider(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.cyan, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: theme.appColors.cyan, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.appColors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.appColors.base5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🤖 Model'),
        const SizedBox(height: 8),
        _buildModelDropdown(
          selectedModel: _selectedMotivationModel,
          onChanged: (value) => setState(() => _selectedMotivationModel = value),
          recommendedModels: _motivationModels,
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('🌡️ Temperature (Kreativita)'),
        const SizedBox(height: 8),
        _buildTemperatureField(_motivationTempController),
        const SizedBox(height: 16),

        _buildSectionTitle('📏 Max Tokens'),
        const SizedBox(height: 8),
        _buildTokensField(_motivationTokensController),
        const SizedBox(height: 16),

        // Provider Route & Cache (V36)
        _buildProviderRouteSection(
          selectedRoute: _motivationProviderRoute,
          onChanged: (route) => setState(() => _motivationProviderRoute = route),
        ),
        const SizedBox(height: 16),

        _buildCacheCheckbox(
          enabled: _motivationEnableCache,
          onChanged: (value) => setState(() => _motivationEnableCache = value),
        ),
        const SizedBox(height: 16),

        // Doporučení
        _buildRecommendationBox(
          '💡 Doporučení pro motivaci',
          [
            'Model: mistralai/mistral-medium-3.1 (uncensored)',
            'Temperature: 0.9 (kreativní)',
            'Max tokens: 200 (krátké zprávy)',
          ],
        ),
      ],
    );
  }

  Widget _buildTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🤖 Model'),
        const SizedBox(height: 8),
        _buildModelDropdown(
          selectedModel: _selectedTaskModel,
          onChanged: (value) => setState(() => _selectedTaskModel = value),
          recommendedModels: _taskModels,
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('🌡️ Temperature (Přesnost)'),
        const SizedBox(height: 8),
        _buildTemperatureField(_taskTempController),
        const SizedBox(height: 16),

        _buildSectionTitle('📏 Max Tokens'),
        const SizedBox(height: 8),
        _buildTokensField(_taskTokensController),
        const SizedBox(height: 16),

        // Provider Route & Cache (V36)
        _buildProviderRouteSection(
          selectedRoute: _taskProviderRoute,
          onChanged: (route) => setState(() => _taskProviderRoute = route),
        ),
        const SizedBox(height: 16),

        _buildCacheCheckbox(
          enabled: _taskEnableCache,
          onChanged: (value) => setState(() => _taskEnableCache = value),
        ),
        const SizedBox(height: 16),

        // Doporučení
        _buildRecommendationBox(
          '💡 Doporučení pro rozdělení úkolů',
          [
            'Model: anthropic/claude-3.5-sonnet (JSON expert)',
            'Temperature: 0.3 (přesný)',
            'Max tokens: 1000 (delší odpovědi)',
          ],
        ),
      ],
    );
  }

  Widget _buildRewardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🤖 Model'),
        const SizedBox(height: 8),
        _buildModelDropdown(
          selectedModel: _selectedRewardModel,
          onChanged: (value) => setState(() => _selectedRewardModel = value),
          recommendedModels: _rewardModels,
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('🌡️ Kreativita'),
        const SizedBox(height: 8),
        _buildTemperatureField(_rewardTempController),
        const SizedBox(height: 16),

        _buildSectionTitle('📏 Max Tokens'),
        const SizedBox(height: 8),
        _buildTokensField(_rewardTokensController),
        const SizedBox(height: 16),

        // Provider Route & Cache (V36)
        _buildProviderRouteSection(
          selectedRoute: _rewardProviderRoute,
          onChanged: (route) => setState(() => _rewardProviderRoute = route),
        ),
        const SizedBox(height: 16),

        _buildCacheCheckbox(
          enabled: _rewardEnableCache,
          onChanged: (value) => setState(() => _rewardEnableCache = value),
        ),
        const SizedBox(height: 16),

        // Doporučení
        _buildRecommendationBox(
          '💡 Doporučení pro pranky a dobré skutky',
          [
            'Model: anthropic/claude-3.5-sonnet (kreativní a vtipný)',
            'Temperature: 0.9 (kreativní)',
            'Max tokens: 1000 (vtipné příběhy)',
          ],
        ),
      ],
    );
  }

  Widget _buildTagSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🤖 Model'),
        const SizedBox(height: 8),
        _buildModelDropdown(
          selectedModel: _selectedTagSuggestionsModel,
          onChanged: (value) => setState(() => _selectedTagSuggestionsModel = value),
          recommendedModels: const ['anthropic/claude-3.5-haiku', 'anthropic/claude-3-haiku'],
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('🌡️ Kreativita AI (Temperature)'),
        const SizedBox(height: 8),
        _buildTemperatureField(_tagSuggestionsTempController),
        _buildHelpText(
          '• 0.0 = Velmi konzervativní (vždy stejné tagy)\n'
          '• 0.5 = Konzervativní - obvyklé, bezpečné tagy\n'
          '• 1.0 = BALANCED (doporučeno) - mix konzistence + variety\n'
          '• 1.5 = Kreativní - rozmanité, originální tagy\n'
          '• 2.0 = Maximálně kreativní - neočekávané nápady\n\n'
          'Pro tag suggestions doporučujeme: 1.0 (balanced)',
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('📏 Max Output Tokens'),
        const SizedBox(height: 8),
        _buildTokensField(_tagSuggestionsTokensController),
        _buildHelpText(
          'Maximální délka AI odpovědi (v tokenech).\n\n'
          '• 500 = Stačí pro 3-5 tag suggestions (doporučeno)\n'
          '• 800 = Více suggestions nebo delší reasoning\n'
          '• 1000 = Maximum pro krátké responses\n\n'
          '⚡ Cost: Více tokenů = dražší každý suggestion.\n'
          'Doporučujeme: 500 tokenů',
        ),
        const SizedBox(height: 16),

        _buildSectionTitle('⏱️ Debounce Delay (ms)'),
        const SizedBox(height: 8),
        _buildNumberField(_tagSuggestionsDebounceController, 'ms'),
        _buildHelpText(
          'Prodleva před odesláním API requestu (v milisekundách).\n\n'
          '• 300ms = Rychlé suggestions, více API calls\n'
          '• 500ms = BALANCED (doporučeno) - pohodlné + efektivní\n'
          '• 800ms = Pomalejší, méně API calls\n\n'
          'Nižší = rychlejší UX, ale dražší (více requestů).\n'
          'Vyšší = levnější, ale pomalejší odezva.',
        ),
        const SizedBox(height: 16),

        // Advanced parametry (optional)
        _buildSectionTitle('🔬 Pokročilé (optional)'),
        const SizedBox(height: 8),

        _buildNumberField(_tagSuggestionsSeedController, 'Seed (reproducibility)'),
        _buildHelpText(
          'Seed pro deterministickou generaci (nepovinné).\n\n'
          'Pokud nastavíte seed = stejný input → stejná odpověď.\n'
          'Užitečné pro debugging/testing.\n\n'
          '⚠️ Poznámka: Reproducibility není 100% garantována API.\n'
          'Pro běžné použití nechte prázdné.',
        ),
        const SizedBox(height: 12),

        _buildNumberField(_tagSuggestionsTopPController, 'Top-P (nucleus sampling)'),
        _buildHelpText(
          'Nucleus sampling parameter (0.0 - 1.0).\n\n'
          'Alternativa k temperature. Ovlivňuje variabilitu outputs.\n\n'
          '• Nižší Top-P = konzervativnější tagy\n'
          '• Vyšší Top-P = kreativnější tagy\n\n'
          'Pro většinu případů nechte prázdné (AI použije default).',
        ),
        const SizedBox(height: 16),

        // Provider Route & Cache (V36)
        _buildProviderRouteSection(
          selectedRoute: _tagSuggestionsProviderRoute,
          onChanged: (route) => setState(() => _tagSuggestionsProviderRoute = route),
        ),
        const SizedBox(height: 16),

        _buildCacheCheckbox(
          enabled: _tagSuggestionsEnableCache,
          onChanged: (value) => setState(() => _tagSuggestionsEnableCache = value),
        ),
        const SizedBox(height: 16),

        // Doporučení
        _buildRecommendationBox(
          '💡 DOPORUČENÉ NASTAVENÍ',
          [
            'Model: anthropic/claude-3.5-haiku',
            'Temperature: 1.0 (balanced)',
            'Max Tokens: 500',
            'Debounce: 500ms',
            'Seed: prázdné (null)',
            'Top-P: prázdné (null)',
            '',
            'Cost: ~\$0.0001 per suggestion (~0.25 Kč/100 suggestions)',
          ],
        ),
      ],
    );
  }

  Widget _buildModelDropdown({
    required String? selectedModel,
    required ValueChanged<String?> onChanged,
    required List<String> recommendedModels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    value: _availableModels.any((m) => m.id == selectedModel) ? selectedModel : null,
                    isExpanded: true,
                    dropdownColor: theme.appColors.base2,
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    hint: Text(
                      selectedModel ?? 'Vyber model',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: _buildModelDropdownItems(),
                    onChanged: (value) {
                      if (value == null) {
                        _showCustomModelDialog(onChanged);
                      } else if (!value.startsWith('__')) {
                        onChanged(value);
                      }
                    },
                  ),
                ),
              ),
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

        // Quick select
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
          children: recommendedModels.map((model) {
            final isSelected = selectedModel == model;
            final tooltip = _getModelTooltip(model);

            return Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: () => onChanged(model),
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTemperatureField(TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
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
            _getTemperatureLabel(controller),
            style: TextStyle(
              color: theme.appColors.yellow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokensField(TextEditingController controller) {
    return TextField(
      controller: controller,
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
    );
  }

  Widget _buildRecommendationBox(String title, List<String> points) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.appColors.blue,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: theme.appColors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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

  String _getTemperatureLabel(TextEditingController controller) {
    final temp = double.tryParse(controller.text) ?? 1.0;
    if (temp < 0.3) return 'Minimální';
    if (temp < 0.7) return 'Nízká';
    if (temp < 1.3) return 'Střední';
    if (temp < 1.7) return 'Vysoká';
    return 'Maximální';
  }

  String _getModelTooltip(String model) {
    // Motivace modely
    if (model == 'mistralai/mistral-medium-3.1') {
      return '💬 Uncensored, nejnovější verze pro kreativní motivaci';
    }

    // Task modely
    if (model == 'anthropic/claude-3.5-sonnet') {
      return '🧠 JSON expert, přesný a spolehlivý pro task split';
    }

    if (model == 'anthropic/claude-3-opus') {
      return '🚀 Nejsilnější model, nejlepší reasoning (drahý)';
    }

    if (model == 'openai/gpt-4o') {
      return '⚡ Rychlý a levný, dobrá volba pro oba účely';
    }

    if (model == 'google/gemini-pro-1.5') {
      return '📚 Velký context window (2M tokens), dobrý pro task split';
    }

    return 'Populární model pro AI úkoly';
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.appColors.fg),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: theme.appColors.base4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.appColors.base4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.appColors.blue, width: 2),
        ),
      ),
      style: TextStyle(color: theme.appColors.fg),
    );
  }

  Widget _buildHelpText(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.base1.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.base3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.appColors.fg.withOpacity(0.7),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  // ========== OPENROUTER PROVIDER ROUTE & CACHE UI KOMPONENTY ==========

  /// Sekce pro výběr Provider Route (radio buttons)
  Widget _buildProviderRouteSection({
    required ProviderRoute selectedRoute,
    required Function(ProviderRoute) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '⚡ Provider Route',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.help_outline, color: theme.appColors.base5, size: 18),
              onPressed: () => _showProviderRouteHelp(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Radio buttons pro všechny 3 routes
        ...ProviderRoute.values.map((route) {
          return RadioListTile<ProviderRoute>(
            title: Text(
              route.displayName,
              style: TextStyle(color: theme.appColors.fg, fontSize: 13),
            ),
            subtitle: Text(
              route.description,
              style: TextStyle(color: theme.appColors.base5, fontSize: 11),
            ),
            value: route,
            groupValue: selectedRoute,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            activeColor: theme.appColors.blue,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  /// Cache checkbox
  Widget _buildCacheCheckbox({
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.bgAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.base3),
      ),
      child: Row(
        children: [
          Checkbox(
            value: enabled,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            activeColor: theme.appColors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '💾 Enable Prompt Caching',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.help_outline, color: theme.appColors.base5, size: 16),
                      onPressed: () => _showCacheHelp(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  enabled ? 'Úspora až 75% tokenů (doporučeno)' : 'Vypnuto',
                  style: TextStyle(
                    color: enabled ? theme.appColors.green : theme.appColors.base5,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Provider Route Help Dialog
  void _showProviderRouteHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        title: Text('⚡ Provider Route', style: TextStyle(color: theme.appColors.fg)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OpenRouter umožňuje vybrat strategii výběru AI providera:',
                style: TextStyle(color: theme.appColors.fg, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildRouteHelpItem(
                '🎯 Default',
                'Automatický výběr',
                'OpenRouter balancuje mezi rychlostí, cenou a dostupností.',
              ),
              const SizedBox(height: 12),
              _buildRouteHelpItem(
                '💰 :floor',
                'Nejlevnější provider',
                'Prioritizuje nejlevnější provider (úspora 50-70%). Doporučeno pro Brief a batch operace.',
              ),
              const SizedBox(height: 12),
              _buildRouteHelpItem(
                '⚡ :nitro',
                'Nejrychlejší provider',
                'Prioritizuje nejrychlejší provider (vyšší cena). Vhodné pro real-time chat.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: theme.appColors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHelpItem(String title, String subtitle, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.appColors.blue,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: theme.appColors.fg, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: theme.appColors.base5, fontSize: 11, height: 1.3),
        ),
      ],
    );
  }

  /// Cache Help Dialog
  void _showCacheHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        title: Text('💾 Prompt Caching', style: TextStyle(color: theme.appColors.fg)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OpenRouter Prompt Caching umožňuje cachovat části promptu a ušetřit až 75% tokenů.',
                style: TextStyle(color: theme.appColors.fg, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildCacheHelpItem(
                '💰 Úspora',
                'Cached tokeny jsou zpoplatněny 75% levněji než normální input tokeny.',
              ),
              const SizedBox(height: 12),
              _buildCacheHelpItem(
                '⚡ Rychlost',
                'Cached prompt části se nemusí znovu zpracovávat, což zrychluje odpověď.',
              ),
              const SizedBox(height: 12),
              _buildCacheHelpItem(
                '🔄 Platnost',
                'Cache expiruje po 5 minutách neaktivity. Perfektní pro opakované dotazy.',
              ),
              const SizedBox(height: 16),
              Text(
                'Doporučení: Zapnuto pro všechny modely (výchozí nastavení).',
                style: TextStyle(
                  color: theme.appColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: theme.appColors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.appColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: theme.appColors.base5, fontSize: 11, height: 1.3),
        ),
      ],
    );
  }
}
