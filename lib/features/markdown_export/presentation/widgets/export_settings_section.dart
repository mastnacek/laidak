import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/theme_colors.dart';
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
                  final directory =
                      await FilePicker.platform.getDirectoryPath();
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
}
