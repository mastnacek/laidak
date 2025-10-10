import 'package:flutter/material.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/theme/theme_colors.dart';
import '../widgets/tag_demo_widget.dart';
import 'help_page.dart';

/// WizardPage - First-time onboarding wizard (help.md Varianta C)
///
/// Struktura:
/// - 5 kroků (Welcome → Tagy → Views → AI Features → Done)
/// - Progress bar nahoře
/// - Skip button (uloží preference "don't show again")
/// - NavigationButtons (Zpět / Přeskočit / Další)
///
/// Spouští se při prvním otevření aplikace (main.dart check)
class WizardPage extends StatefulWidget {
  const WizardPage({super.key});

  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  int _currentStep = 0;
  final int _totalSteps = 5;
  final DatabaseHelper _db = DatabaseHelper();

  /// Uložit preference "wizard completed" do databáze
  Future<void> _completeWizard() async {
    final settings = await _db.getSettings();
    await _db.updateSettings(
      apiKey: settings['api_key'] as String?,
      model: settings['model'] as String,
      temperature: settings['temperature'] as double,
      maxTokens: settings['max_tokens'] as int,
      enabled: (settings['enabled'] as int) == 1,
      wizardCompleted: true, // Custom field (může vyžadovat DB migration)
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HelpPage()),
      );
    }
  }

  /// Skip wizard (uloží preference a zavře)
  Future<void> _skipWizard() async {
    await _completeWizard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: theme.appColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar + Skip button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.appColors.bgAlt,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Krok ${_currentStep + 1} / $_totalSteps',
                        style: TextStyle(
                          color: theme.appColors.base5,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _skipWizard,
                        child: Text(
                          'Přeskočit',
                          style: TextStyle(
                            color: theme.appColors.base5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.appColors.base3,
                    valueColor: AlwaysStoppedAnimation(theme.appColors.cyan),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            // Content (podle kroku)
            Expanded(
              child: _buildStepContent(theme),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.appColors.bgAlt,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Zpět button
                  if (_currentStep > 0)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Zpět'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.appColors.base5,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Další / Dokončit button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep < _totalSteps - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _completeWizard();
                      }
                    },
                    icon: Icon(
                      _currentStep < _totalSteps - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentStep < _totalSteps - 1 ? 'Další' : 'Dokončit',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.appColors.cyan,
                      foregroundColor: theme.appColors.bg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obsah podle aktuálního kroku
  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(theme);
      case 1:
        return _buildTagsStep(theme);
      case 2:
        return _buildViewsStep(theme);
      case 3:
        return _buildAiFeaturesStep(theme);
      case 4:
        return _buildCompletionStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Krok 1: Welcome
  Widget _buildWelcomeStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand,
            size: 80,
            color: theme.appColors.yellow,
          ),
          const SizedBox(height: 24),
          Text(
            '👋 Vítej v TODO aplikaci!',
            style: TextStyle(
              color: theme.appColors.cyan,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tato aplikace ti pomůže organizovat úkoly s pomocí tagů, AI motivace a smart filtrování.',
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.appColors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.appColors.blue),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.appColors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Co se naučíš:',
                        style: TextStyle(
                          color: theme.appColors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(theme, '🏷️', 'Jak používat tagy'),
                _buildFeatureItem(theme, '📊', 'Režimy zobrazení (Views)'),
                _buildFeatureItem(theme, '🤖', 'AI funkce pro produktivitu'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(ThemeData theme, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: theme.appColors.fg, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Krok 2: Tagy
  Widget _buildTagsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.label, size: 60, color: theme.appColors.cyan),
          const SizedBox(height: 16),
          Text(
            '🏷️ Jak používat tagy?',
            style: TextStyle(
              color: theme.appColors.cyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tagy jsou zkratky pro rychlé přidání priority, data nebo kategorií k úkolům.',
            style: TextStyle(color: theme.appColors.fg, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildTagExample(theme, '*a* *dnes* Zavolat doktorovi',
              'Priorita A + Deadline dnes'),
          const SizedBox(height: 12),
          _buildTagExample(theme, '*b* *15.1.* Koupit dárek',
              'Priorita B + Konkrétní datum'),
          const SizedBox(height: 12),
          _buildTagExample(
              theme, '*c* Uklidit garáž *domov*', 'Priorita C + Custom tag'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const TagDemoWidget(),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('🎮 VYZKOUŠET ŽIVĚ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.appColors.green,
                side: BorderSide(color: theme.appColors.green),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagExample(ThemeData theme, String example, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.base2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.base4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example,
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '→ $description',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Krok 3: Views
  Widget _buildViewsStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.filter_alt, size: 60, color: theme.appColors.cyan),
          const SizedBox(height: 16),
          Text(
            '📊 Režimy zobrazení',
            style: TextStyle(
              color: theme.appColors.cyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Filtruj úkoly podle časových kategorií pro lepší přehled.',
            style: TextStyle(color: theme.appColors.fg, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildViewItem(theme, '📋', 'Všechny', 'Kompletní seznam úkolů'),
          _buildViewItem(theme, '📅', 'Dnes', 'Úkoly s deadline dnes'),
          _buildViewItem(theme, '🗓️', 'Týden', 'Nadcházející týden'),
          _buildViewItem(
              theme, '⏰', 'Nadcházející', 'Všechny úkoly s deadline'),
          _buildViewItem(theme, '⚠️', 'Po termínu', 'Overdue úkoly'),
          _buildViewItem(theme, '👁️', 'Hotové', 'Dokončené úkoly'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.appColors.yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.yellow),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: theme.appColors.yellow, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: ViewBar najdeš pod input boxem v hlavní obrazovce',
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewItem(
      ThemeData theme, String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.appColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.cyan),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
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

  /// Krok 4: AI Features
  Widget _buildAiFeaturesStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 60, color: theme.appColors.magenta),
          const SizedBox(height: 16),
          Text(
            '🤖 AI Funkce',
            style: TextStyle(
              color: theme.appColors.magenta,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AI ti pomůže s produktivitou - rozdělit úkoly na kroky a motivovat tě.',
            style: TextStyle(color: theme.appColors.fg, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _buildAiFeatureCard(
            theme,
            '🤖 AI Rozdělení úkolu',
            'Rozděl složitý úkol na menší kroky pomocí AI',
            theme.appColors.cyan,
          ),
          const SizedBox(height: 12),
          _buildAiFeatureCard(
            theme,
            '💬 Motivační prompty',
            'AI motivace podle typu úkolu (humor, motivace, deadline tlak)',
            theme.appColors.magenta,
          ),
          const SizedBox(height: 24),
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
                    Icon(Icons.warning_amber,
                        color: theme.appColors.yellow, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '⚠️ Vyžaduje API key',
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
                  'Pro AI funkce potřebuješ OpenRouter API klíč.\n'
                  'Získáš ho zdarma na openrouter.ai\n\n'
                  'Nastavení → AI Nastavení → API klíč',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeatureCard(
      ThemeData theme, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
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

  /// Krok 5: Completion
  Widget _buildCompletionStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: theme.appColors.green,
          ),
          const SizedBox(height: 24),
          Text(
            '🎉 Jsi připraven!',
            style: TextStyle(
              color: theme.appColors.green,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Teď už víš všechno důležité.\nMůžeš začít používat aplikaci!',
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.appColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.appColors.cyan),
            ),
            child: Column(
              children: [
                Icon(Icons.help_outline, color: theme.appColors.cyan, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Nápovědu najdeš kdykoliv',
                  style: TextStyle(
                    color: theme.appColors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Klikni na ikonu ? v levém horním rohu',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
