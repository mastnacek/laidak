import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';
import '../../domain/models/help_section.dart';
import '../widgets/help_card.dart';
import '../widgets/tag_demo_widget.dart';
import '../widgets/ai_split_demo_widget.dart';
import '../widgets/motivation_demo_widget.dart';
import 'wizard_page.dart';

/// HelpPage - Interaktivní nápověda (Card-based layout podle help.md Varianta B)
///
/// Struktura:
/// - AppBar s tlačítkem Zavřít
/// - Scrollable seznam HelpCard komponent
/// - Každá karta má:
///   - Titul + ikona + popis
///   - Příklady (collapsible)
///   - Tlačítko "Vyzkoušet interaktivně" (pokud má demo)
///   - Warning pokud vyžaduje API key
///
/// Features:
/// - TagDemo: Live parsing tagů (bez API)
/// - AiSplitDemo: AI rozdělení úkolu (s OpenRouter)
/// - MotivationDemo: AI motivační prompty (s OpenRouter)
/// - Statické info: Views, Search/Sort, Settings
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = HelpSection.allSections;

    return Scaffold(
      backgroundColor: theme.appColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: theme.appColors.cyan, size: 28),
            const SizedBox(width: 12),
            Text(
              'NÁPOVĚDA',
              style: TextStyle(
                color: theme.appColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.appColors.fg),
          tooltip: 'Zavřít',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Wizard button (pro opakované spuštění onboardingu)
          IconButton(
            icon: Icon(Icons.school, color: theme.appColors.magenta),
            tooltip: 'Průvodce pro začátečníky',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WizardPage()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sections.length + 1, // +1 pro info panel na konci
        itemBuilder: (context, index) {
          if (index == sections.length) {
            // Info panel na konci
            return _buildInfoPanel(context);
          }

          final section = sections[index];
          return HelpCard(
            section: section,
            onTryDemo: section.hasInteractiveDemo
                ? () => _openDemo(context, section)
                : null,
          );
        },
      ),
    );
  }

  /// Otevřít demo podle typu
  void _openDemo(BuildContext context, HelpSection section) {
    switch (section.demoType) {
      case DemoType.tagParsing:
        // Import TagDemoWidget dynamicky (vytvoříme později)
        _showTagDemo(context);
        break;
      case DemoType.aiSplit:
        _showAiSplitDemo(context);
        break;
      case DemoType.motivationPrompt:
        _showMotivationDemo(context);
        break;
      case null:
        break;
    }
  }

  /// Zobrazit Tag Demo dialog
  void _showTagDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TagDemoWidget(),
    );
  }

  /// Zobrazit AI Split Demo dialog
  void _showAiSplitDemo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AiSplitDemoWidget(),
    );
  }

  /// Zobrazit Motivation Demo fullscreen
  void _showMotivationDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MotivationDemoWidget(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Info panel na konci stránky
  Widget _buildInfoPanel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.appColors.blue, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.appColors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Potřebuješ pomoct?',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pro AI funkce (rozdělení úkolu, motivace) je potřeba nakonfigurovat OpenRouter API klíč v Nastavení.',
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('OTEVŘÍT NASTAVENÍ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.blue,
              foregroundColor: theme.appColors.bg,
            ),
          ),
        ],
      ),
    );
  }
}
