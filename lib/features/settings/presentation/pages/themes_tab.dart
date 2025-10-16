import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/doom_one_theme.dart';
import '../../../../core/theme/blade_runner_theme.dart';
import '../../../../core/theme/osaka_jade_theme.dart';
import '../../../../core/theme/amoled_theme.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../cubit/settings_cubit.dart';

/// Tab pro výběr témat
class ThemesTab extends StatefulWidget {
  const ThemesTab({super.key});

  @override
  State<ThemesTab> createState() => _ThemesTabState();
}

class _ThemesTabState extends State<ThemesTab> {
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
