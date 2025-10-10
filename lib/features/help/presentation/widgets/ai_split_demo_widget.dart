import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';

/// AiSplitDemoWidget - Info dialog pro AI Split funkci (zjednodušená verze pro MVP)
///
/// Místo plného demo zobrazí:
/// - Vysvětlení jak funkce funguje
/// - Požadavky (API key, model)
/// - Link na Settings pro konfiguraci
/// - Příklad použití (textový popis)
///
/// TODO pro budoucnost: Plné demo s live API voláním (podle help.md Fáze 3)
class AiSplitDemoWidget extends StatelessWidget {
  const AiSplitDemoWidget({super.key});

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: theme.appColors.cyan, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '🤖 AI Rozdělení úkolu',
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

              // Vysvětlení
              Text(
                'Jak to funguje?',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI ti pomůže rozdělit složitý úkol na menší, zvladatelné kroky. Stačí kliknout na tlačítko 🤖 u jakéhokoliv úkolu v hlavním seznamu.',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Příklad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.appColors.base2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.appColors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: theme.appColors.yellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Příklad:',
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
                      'Input: "Naplánovat dovolenou v Itálii"',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Output:',
                      style: TextStyle(
                        color: theme.appColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...['1. Zjistit termín dovolené',
                      '2. Vybrat destinaci (Řím vs. Florencie)',
                      '3. Rezervovat letenky',
                      '4. Najít ubytování',
                      '5. Naplánovat aktivity',
                      '6. Zařídit pojištění',
                    ].map((step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            step,
                            style: TextStyle(
                              color: theme.appColors.fg,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Požadavky
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
                          '⚠️ Požadavky:',
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
                      '• OpenRouter API key (získáš na openrouter.ai)\n'
                      '• Vybraný AI model (např. mistralai/mistral-medium-3.1)\n'
                      '• Funkce musí být zapnutá v Nastavení',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tlačítko na Settings
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text(
                    'OTEVŘÍT NASTAVENÍ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.cyan,
                    foregroundColor: theme.appColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Info
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.appColors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Po konfiguraci najdeš tlačítko 🤖 u každého úkolu.',
                      style: TextStyle(
                        color: theme.appColors.base5,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
