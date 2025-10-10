import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../pages/settings_page.dart';

/// MotivationDemoWidget - Info dialog pro Motivační prompty (zjednodušená verze pro MVP)
///
/// Místo plného demo zobrazí:
/// - Vysvětlení jak funkce funguje
/// - Požadavky (API key, model)
/// - Link na Settings pro konfiguraci promptů
/// - Příklad použití (textový popis)
///
/// TODO pro budoucnost: Plné demo s live API voláním (podle help.md Fáze 4)
class MotivationDemoWidget extends StatelessWidget {
  const MotivationDemoWidget({super.key});

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
        child: SingleChildScrollView(
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
                      '💬 Motivační prompty',
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
                'AI ti pomůže s motivací podle typu úkolu. Můžeš si vytvořit vlastní prompty pro různé kategorie (práce, sport, domov...). Stačí kliknout na tlačítko 💬 u jakéhokoliv úkolu.',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Příklad 1
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
                          'Příklad - Motivační styl:',
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
                      'Úkol: "Napsat seminární práci"',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.appColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.appColors.green),
                      ),
                      child: Text(
                        '💪 Tvoje seminární práce bude skvělá! Začni s úvodem dnes a za týden budeš mít hotovo. Každý velký úspěch začíná malým krokem. Věřím v tebe! 🚀',
                        style: TextStyle(
                          color: theme.appColors.fg,
                          fontSize: 12,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Příklad 2
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.appColors.base2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.appColors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mood, color: theme.appColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Příklad - Humorný styl:',
                          style: TextStyle(
                            color: theme.appColors.cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Úkol: "Uklidit garáž"',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.appColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.appColors.cyan),
                      ),
                      child: Text(
                        '😄 Garáž sama sebe neuklize! I když... kdyby mohla, už by to dávno udělala. Tak vzhůru do toho! Netflix počká. 🧹',
                        style: TextStyle(
                          color: theme.appColors.fg,
                          fontSize: 12,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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
                      '• Vybraný AI model\n'
                      '• Funkce musí být zapnutá v Nastavení\n'
                      '• Můžeš vytvořit vlastní prompty v Nastavení → Motivační Prompty',
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

              // Tlačítka
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
                    backgroundColor: theme.appColors.magenta,
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
                      'Tip: Po konfiguraci najdeš tlačítko 💬 u každého úkolu.',
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
