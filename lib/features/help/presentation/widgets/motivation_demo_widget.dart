import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../pages/settings_page.dart';
import '../../../ai_motivation/data/repositories/motivation_repository_impl.dart';

/// MotivationDemoWidget - Live demo pro motivační prompty s OpenRouter API
///
/// Funkce:
/// - TextField pro zadání testovacího úkolu
/// - Kontrola API key a modelu v databázi
/// - Live volání OpenRouter API (přes MotivationRepository)
/// - Zobrazení motivační zprávy
/// - Error handling (missing API key, network errors)
/// - Rate limiting warning
class MotivationDemoWidget extends StatefulWidget {
  const MotivationDemoWidget({super.key});

  @override
  State<MotivationDemoWidget> createState() => _MotivationDemoWidgetState();
}

class _MotivationDemoWidgetState extends State<MotivationDemoWidget> {
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
    _controller.text = 'Napsat seminární práci z historie';
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

  /// Zavolat OpenRouter API a získat motivaci
  Future<void> _generateMotivation() async {
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
      // Použít MotivationRepository pro volání API
      final repository = MotivationRepositoryImpl(_db);
      final message = await repository.getMotivation(
        taskText: _controller.text.trim(),
        priority: null, // Demo nepotřebuje prioritu
        tags: null, // Demo nepotřebuje tagy
      );

      setState(() {
        _result = message;
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
        side: BorderSide(color: theme.appColors.magenta, width: 2),
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
                Icon(Icons.psychology,
                    color: theme.appColors.magenta, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '💬 Motivační Demo',
                    style: TextStyle(
                      color: theme.appColors.magenta,
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
              'Zadej úkol pro motivaci:',
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
                hintText: 'Napsat seminární práci z historie',
                hintStyle: TextStyle(color: theme.appColors.base5),
                filled: true,
                fillColor: theme.appColors.base2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: theme.appColors.magenta, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateMotivation,
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
                  _isLoading ? 'GENERUJI...' : '💪 VYGENEROVAT MOTIVACI',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasApiKey
                      ? theme.appColors.magenta
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
        color: theme.appColors.magenta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.appColors.magenta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: theme.appColors.magenta, size: 20),
              const SizedBox(width: 8),
              Text(
                '💬 Motivační zpráva:',
                style: TextStyle(
                  color: theme.appColors.magenta,
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
                fontSize: 13,
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
                  'V reálné aplikaci klikni na 💬 u jakéhokoliv úkolu!',
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
                '💪 Tvoje seminární práce bude skvělá! Začni s úvodem dnes a za týden budeš mít hotovo. Každý velký úspěch začíná malým krokem. Věřím v tebe! 🚀',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 12,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.yellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.appColors.yellow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.appColors.yellow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '💡 Tip:',
                    style: TextStyle(
                      color: theme.appColors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'AI přizpůsobí motivaci podle tvých tagů! V Nastavení můžeš vytvořit vlastní motivační prompty pro různé kategorie (práce, sport, domov...).',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.info_outline, color: theme.appColors.magenta, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Klikni na "Vygenerovat motivaci" pro živé demo s AI!',
                style: TextStyle(
                  color: theme.appColors.magenta,
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
