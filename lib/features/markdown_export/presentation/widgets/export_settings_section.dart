import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/saf_file_writer.dart';
import '../../domain/entities/export_config.dart';
import '../../domain/entities/export_format.dart';
import '../../domain/repositories/markdown_export_repository.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';

/// Settings sekce pro Markdown Export
///
/// Features:
/// - Directory picker (file_picker)
/// - Format dropdown (default / obsidian)
/// - Export options (TODOs/Notes checkboxes)
/// - Auto-export toggle
/// - Manual export button
class ExportSettingsSection extends StatelessWidget {
  final MarkdownExportRepository exportRepository;

  const ExportSettingsSection({
    super.key,
    required this.exportRepository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const SizedBox.shrink();
        }

        final config = state.exportConfig;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.appColors.base3.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(
                    Icons.save_alt,
                    color: theme.appColors.cyan,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Markdown Export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.appColors.fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Directory picker
              _buildDirectoryPicker(context, config, theme),
              const SizedBox(height: 12),

              // Format dropdown
              _buildFormatDropdown(context, config, theme),
              const SizedBox(height: 12),

              // Export options (TODOs, Notes)
              _buildExportOptions(context, config, theme),
              const SizedBox(height: 12),

              // Auto-export toggle
              _buildAutoExportToggle(context, config, theme),
              const SizedBox(height: 16),

              // Export ALL SETTINGS button (NEW)
              _buildExportAllSettingsButton(context, theme),
              const SizedBox(height: 8),

              // Import ALL SETTINGS button (NEW)
              _buildImportAllSettingsButton(context, theme),
              const SizedBox(height: 12),

              // Manual export button
              _buildManualExportButton(context, config, theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectoryPicker(
    BuildContext context,
    ExportConfig config,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cílová složka',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.appColors.base3),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  config.targetDirectory ?? 'Není vybrána složka',
                  style: TextStyle(
                    fontSize: 13,
                    color: config.targetDirectory != null
                        ? theme.appColors.fg
                        : theme.appColors.base5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  String? directory;

                  // Android: použij SAF picker (vrací content:// URI)
                  // Desktop: použij file_picker (vrací file path)
                  if (Platform.isAndroid) {
                    try {
                      directory = await SafFileWriter.pickDirectory();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Výběr složky selhal: $e'),
                            backgroundColor: theme.appColors.red,
                          ),
                        );
                      }
                      return;
                    }
                  } else {
                    directory = await FilePicker.platform.getDirectoryPath();
                  }

                  if (directory != null && context.mounted) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(targetDirectory: directory),
                        );
                  }
                },
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Vybrat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.appColors.cyan,
                  foregroundColor: theme.appColors.bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatDropdown(
    BuildContext context,
    ExportConfig config,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export formát',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.appColors.base3),
          ),
          child: DropdownButton<ExportFormat>(
            value: config.format,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: theme.appColors.bgAlt,
            style: TextStyle(
              fontSize: 14,
              color: theme.appColors.fg,
            ),
            items: ExportFormat.values.map((format) {
              return DropdownMenuItem(
                value: format,
                child: Text(format.displayName),
              );
            }).toList(),
            onChanged: (format) {
              if (format != null) {
                context.read<SettingsCubit>().updateExportConfig(
                      config.copyWith(format: format),
                    );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportOptions(
    BuildContext context,
    ExportConfig config,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Co exportovat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.appColors.fg,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: config.exportTodos,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(exportTodos: value),
                        );
                  }
                },
                title: const Text('TODO úkoly'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.appColors.cyan,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                value: config.exportNotes,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsCubit>().updateExportConfig(
                          config.copyWith(exportNotes: value),
                        );
                  }
                },
                title: const Text('Notes poznámky'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.appColors.cyan,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoExportToggle(
    BuildContext context,
    ExportConfig config,
    ThemeData theme,
  ) {
    return SwitchListTile(
      value: config.autoExportOnSave,
      onChanged: (value) {
        context.read<SettingsCubit>().updateExportConfig(
              config.copyWith(autoExportOnSave: value),
            );
      },
      title: Text(
        'Automatický export při uložení',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.appColors.fg,
        ),
      ),
      subtitle: Text(
        'Export markdown souborů při každé změně TODO/Note',
        style: TextStyle(
          fontSize: 12,
          color: theme.appColors.base5,
        ),
      ),
      activeColor: theme.appColors.cyan,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildManualExportButton(
    BuildContext context,
    ExportConfig config,
    ThemeData theme,
  ) {
    final isEnabled = config.isConfigured;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled
            ? () async {
                // Zobraz loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: theme.appColors.cyan,
                    ),
                  ),
                );

                try {
                  // Trigger manual export
                  await exportRepository.exportAll(config);

                  // Close loading dialog
                  if (context.mounted) Navigator.of(context).pop();

                  // Show success snackbar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Export dokončen!'),
                        backgroundColor: theme.appColors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) Navigator.of(context).pop();

                  // Show error snackbar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Export selhal: $e'),
                        backgroundColor: theme.appColors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            : null,
        icon: const Icon(Icons.download, size: 20),
        label: const Text('Exportovat vše nyní'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? theme.appColors.cyan : theme.appColors.base3,
          foregroundColor: theme.appColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// NEW: Export ALL SETTINGS button (API keys, custom prompts, tags, views...)
  Widget _buildExportAllSettingsButton(
    BuildContext context,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.yellow.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_backup_restore,
                color: theme.appColors.yellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'EXPORT NASTAVENÍ APLIKACE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Exportuje VŠECHNA nastavení do JSON souboru:\n'
            '• API klíče (OpenRouter)\n'
            '• AI modely a parametry\n'
            '• Custom prompty\n'
            '• Custom Agenda/Notes views\n'
            '• Tag definitions (barvy, emoji, glow)\n'
            '• Export config',
            style: TextStyle(
              fontSize: 12,
              color: theme.appColors.base5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Zavolat SettingsCubit.exportAllSettings()
                final cubit = context.read<SettingsCubit>();

                try {
                  // Trigger export (zobrazí SAF picker)
                  final filePath = await cubit.exportAllSettings();

                  if (filePath != null && context.mounted) {
                    // Success - zobraz snackbar s cestou
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Nastavení exportována:\n$filePath'),
                        backgroundColor: theme.appColors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else if (context.mounted) {
                    // User zrušil nebo chyba (logged v AppLogger)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('⚠️ Export zrušen nebo selhal'),
                        backgroundColor: theme.appColors.base4,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Chyba při exportu: $e'),
                        backgroundColor: theme.appColors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.file_download, size: 20),
              label: const Text('EXPORTOVAT NASTAVENÍ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.yellow,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// NEW: Import ALL SETTINGS button (API keys, custom prompts, tags, views...)
  Widget _buildImportAllSettingsButton(
    BuildContext context,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.appColors.blue.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upload_file,
                color: theme.appColors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'IMPORT NASTAVENÍ APLIKACE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Importuje VŠECHNA nastavení z JSON souboru.\n'
            '⚠️ POZOR: Přepíše všechna současná nastavení!\n\n'
            'Importuje:\n'
            '• API klíče (OpenRouter)\n'
            '• AI modely a parametry\n'
            '• Custom prompty\n'
            '• Custom Agenda/Notes views\n'
            '• Tag definitions (barvy, emoji, glow)\n'
            '• Export config',
            style: TextStyle(
              fontSize: 12,
              color: theme.appColors.base5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Zobraz confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: theme.appColors.bgAlt,
                    title: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: theme.appColors.yellow,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Potvrdit import?',
                          style: TextStyle(
                            color: theme.appColors.fg,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      'Tato akce PŘEPÍŠE všechna současná nastavení!\n\n'
                      'Chcete pokračovat?',
                      style: TextStyle(
                        color: theme.appColors.base5,
                        fontSize: 14,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          'Zrušit',
                          style: TextStyle(color: theme.appColors.base5),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.appColors.blue,
                          foregroundColor: theme.appColors.bg,
                        ),
                        child: const Text('ANO, IMPORTOVAT'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                // Zavolat SettingsCubit.importAllSettings()
                final cubit = context.read<SettingsCubit>();

                try {
                  // Trigger import (zobrazí file picker)
                  final success = await cubit.importAllSettings();

                  if (success && context.mounted) {
                    // Success - zobraz snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Nastavení úspěšně importována!\n'
                            'Aplikace se nyní restartuje...'),
                        backgroundColor: theme.appColors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else if (context.mounted) {
                    // User zrušil nebo chyba (logged v AppLogger)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('⚠️ Import zrušen nebo selhal'),
                        backgroundColor: theme.appColors.base4,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Chyba při importu: $e'),
                        backgroundColor: theme.appColors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.file_upload, size: 20),
              label: const Text('IMPORTOVAT NASTAVENÍ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.blue,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
