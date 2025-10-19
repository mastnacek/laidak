import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_registry.dart';
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
  late List<ThemeMetadata> _availableThemes;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

  @override
  void initState() {
    super.initState();
    // Načíst všechny dostupné themes z registry
    _availableThemes = ThemeRegistry.getAllMetadata();
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
              final themeMetadata = _availableThemes[index];
              final isSelected = _selectedTheme == themeMetadata.id;

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
                  onTap: () => _saveTheme(themeMetadata.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          themeMetadata.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                themeMetadata.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.appColors.cyan
                                      : theme.appColors.fg,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                themeMetadata.description,
                                style: TextStyle(
                                  color: theme.appColors.base5,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
