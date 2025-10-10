import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../pages/settings_page.dart';
import '../../../ai_split/data/datasources/openrouter_datasource.dart';
import '../../../ai_split/domain/entities/ai_split_request.dart';

/// AiSplitDemoWidget - Live demo pro AI Split funkci s OpenRouter API
///
/// Funkce:
/// - TextField pro zadání testovacího úkolu
/// - Kontrola API key a modelu v databázi
/// - Live volání OpenRouter API
/// - Zobrazení výsledku (rozdělené podúkoly)
/// - Error handling (missing API key, network errors)
/// - Rate limiting warning
class AiSplitDemoWidget extends StatefulWidget {
  const AiSplitDemoWidget({super.key});

  @override
  State<AiSplitDemoWidget> createState() => _AiSplitDemoWidgetState();
}

class _AiSplitDemoWidgetState extends State<AiSplitDemoWidget> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseHelper _db = DatabaseHelper();

  bool _isLoading = false;
  String? _result;
  String? _error;
  bool _hasApiKey = false;
  String? _model;

  @override
  void initState() {
    super.initState();
    _controller.text = 'Naplánovat dovolenou v Itálii';
    _checkApiConfiguration();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Zkontrolovat zda je API key a model nakonfigurován
  Future<void> _checkApiConfiguration() async {
    final settings = await _db.getSettings();
    setState(() {
      final apiKey = settings['api_key'] as String?;
      _hasApiKey = apiKey != null && apiKey.isNotEmpty;
      _model = settings['model'] as String?;
    });
  }

  /// Zavolat OpenRouter API a rozdělit úkol
  Future<void> _splitTask() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _error = 'Zadej text úkolu!';
      });
      return;
    }

    if (!_hasApiKey || _model == null) {
      setState(() {
        _error = 'OpenRouter API key nebo model není nakonfigurován.\n'
            'Jdi do Nastavení → AI Nastavení → Nastav klíč a model.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Načíst settings z databáze
      final settings = await _db.getSettings();
      final apiKey = settings['api_key'] as String;
      final model = settings['model'] as String;
      final temperature = settings['temperature'] as double;
      final maxTokens = settings['max_tokens'] as int;

      // Vytvořit request
      final request = AiSplitRequest(
        taskText: _controller.text.trim(),
        priority: null,
        deadline: null,
        tags: const [],
        userNote: null,
      );

      // Zavolat API
      final datasource = OpenRouterDataSource(client: http.Client());
      final response = await datasource.splitTask(
        request: request,
        apiKey: apiKey,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      setState(() {
        _result = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Chyba při volání API:\n${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.appColors.cyan, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.appColors.cyan, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🤖 AI Split Demo',
                    style: TextStyle(
                      color: theme.appColors.cyan,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.appColors.base5),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(color: theme.appColors.base3, height: 24),

            // API Status
            _buildApiStatus(theme),
            const SizedBox(height: 16),

            // Input
            Text(
              'Zadej úkol pro rozdělení:',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !_isLoading,
              style: TextStyle(color: theme.appColors.fg, fontSize: 14),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Naplánovat dovolenou v Itálii',
                hintStyle: TextStyle(color: theme.appColors.base5),
                filled: true,
                fillColor: theme.appColors.base2,
                border: OutlineInputBorder(
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

            // Split button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _splitTask,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(theme.appColors.bg),
                        ),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(
                  _isLoading ? 'ZPRACOVÁVÁM...' : '🚀 ROZDĚLIT ÚKOL',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasApiKey
                      ? theme.appColors.green
                      : theme.appColors.base4,
                  foregroundColor: theme.appColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Result / Error
            Expanded(
              child: SingleChildScrollView(
                child: _buildContent(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// API Status indicator
  Widget _buildApiStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasApiKey
            ? theme.appColors.green.withOpacity(0.1)
            : theme.appColors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasApiKey ? theme.appColors.green : theme.appColors.yellow,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasApiKey ? Icons.check_circle : Icons.warning_amber,
            color: _hasApiKey ? theme.appColors.green : theme.appColors.yellow,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _hasApiKey
                  ? 'API: ✅ Nakonfigurováno (Model: ${_model ?? "N/A"})'
                  : '⚠️ API key není nakonfigurován - Jdi do Nastavení',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!_hasApiKey)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              child: Text(
                'Settings',
                style: TextStyle(color: theme.appColors.yellow, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  /// Content (result nebo error nebo example)
  Widget _buildContent(ThemeData theme) {
    if (_error != null) {
      return _buildError(theme);
    }

    if (_result != null) {
      return _buildResult(theme);
    }

    return _buildExampleInfo(theme);
  }

  /// Zobrazení erroru
  Widget _buildError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.appColors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: theme.appColors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '❌ Chyba:',
                style: TextStyle(
                  color: theme.appColors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Zobrazení výsledku
  Widget _buildResult(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.appColors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.appColors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                '✅ Úkol rozdělen:',
                style: TextStyle(
                  color: theme.appColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.appColors.base2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _result!,
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.appColors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'V produkční verzi by se podúkoly automaticky přidaly do seznamu.',
                  style: TextStyle(
                    color: theme.appColors.base5,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Příklad info (před spuštěním)
  Widget _buildExampleInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.appColors.blue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: theme.appColors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Příklad výsledku:',
                    style: TextStyle(
                      color: theme.appColors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'PODÚKOLY:\n'
                '1. Zjistit termín dovolené\n'
                '2. Vybrat destinaci (Řím vs. Florencie)\n'
                '3. Rezervovat letenky\n'
                '4. Najít ubytování\n'
                '5. Naplánovat aktivity\n'
                '6. Zařídit pojištění',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 12,
                  height: 1.6,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, color: theme.appColors.cyan, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Klikni na "Rozdělit úkol" pro živé demo s AI!',
                style: TextStyle(
                  color: theme.appColors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
