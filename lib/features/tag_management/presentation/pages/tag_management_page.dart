import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../utils/color_utils.dart';
import '../../../../widgets/color_picker_dialog.dart';
import '../../domain/entities/tag_definition.dart';
import '../providers/tag_management_provider.dart';

/// Stránka pro správu tagů - Feature-First + Riverpod architektura
class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagManagementAsync = ref.watch(tagManagementProvider);

    return tagManagementAsync.when(
      data: (state) {
        if (state is! TagManagementLoaded) {
          return const SizedBox.shrink();
        }

        return _buildLoadedView(context, ref, state, theme);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Chyba: $error',
          style: TextStyle(color: theme.appColors.red),
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    WidgetRef ref,
    TagManagementLoaded state,
    ThemeData theme,
  ) {
    // Seskupit tagy podle typu
    final tagsByType = <TagType, List<TagDefinition>>{};
    for (final tag in state.tags) {
      tagsByType.putIfAbsent(tag.tagType, () => []).add(tag);
    }

    return Column(
      children: [
        // Celá scrollovatelná oblast
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Info panel
              _buildInfoPanel(theme),
              Divider(height: 1, color: theme.appColors.base3),

              // Nastavení oddělovačů tagů
              _DelimiterSelector(
                tagDelimiterStart: state.tagDelimiterStart,
                tagDelimiterEnd: state.tagDelimiterEnd,
                onSave: (start, end) => ref.read(tagManagementProvider.notifier).saveDelimiters(start, end),
                onDelimiterChange: (start, end) {
                  ref.read(tagManagementProvider.notifier).updateDelimitersTemporarily(start, end);
                },
              ),
              Divider(height: 1, color: theme.appColors.base3),

              // Seznam tagů seskupených podle typu
              ...TagType.values.map((type) {
                final tags = tagsByType[type] ?? [];
                if (tags.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Text(
                        type.displayName.toUpperCase(),
                        style: TextStyle(
                          color: theme.appColors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...tags.map((tag) => _TagCard(
                          tag: tag,
                          onEdit: () => _showEditTagDialog(context, tag),
                          onDelete: () => _confirmDeleteTag(context, tag),
                          onToggle: () {
                            if (tag.id != null) {
                              ref.read(tagManagementProvider.notifier).toggleTag(tag.id!, !tag.enabled);
                            }
                          },
                        )),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          ),
        ),

        // Add button (sticky bottom)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            border: Border(top: BorderSide(color: theme.appColors.base3)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddTagDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('PŘIDAT NOVÝ TAG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.green,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(ThemeData theme) {
    return Container(
      color: theme.appColors.bgAlt,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.appColors.yellow),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Zde můžeš spravovat systémové tagy. Nové tagy se automaticky rozpoznávají v textu úkolů.',
              style: TextStyle(color: theme.appColors.fg, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Zobrazit dialog pro přidání nového tagu
  Future<void> _showAddTagDialog(BuildContext context) async {
    final result = await showDialog<TagDefinition>(
      context: context,
      builder: (context) => const _TagDialog(mode: TagDialogMode.add),
    );

    if (result != null && context.mounted) {
      ref.read(tagManagementProvider.notifier).addTag(result);
    }
  }

  /// Zobrazit dialog pro editaci tagu
  Future<void> _showEditTagDialog(BuildContext context, TagDefinition tag) async {
    final result = await showDialog<TagDefinition>(
      context: context,
      builder: (context) => _TagDialog(mode: TagDialogMode.edit, initialTag: tag),
    );

    if (result != null && context.mounted) {
      ref.read(tagManagementProvider.notifier).updateTag(result);
    }
  }

  /// Potvrdit smazání tagu
  Future<void> _confirmDeleteTag(BuildContext context, TagDefinition tag) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.appColors.bg,
        title: Text('Smazat tag?', style: TextStyle(color: theme.appColors.red)),
        content: Text(
          'Opravdu chceš smazat tag "*${tag.tagName}*"?',
          style: TextStyle(color: theme.appColors.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.red,
              foregroundColor: theme.appColors.bg,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted && tag.id != null) {
      ref.read(tagManagementProvider.notifier).deleteTag(tag.id!);
    }
  }
}

// ============================================================================
// TAG CARD WIDGET
// ============================================================================

class _TagCard extends StatelessWidget {
  final TagDefinition tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _TagCard({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: tag.enabled ? theme.appColors.bgAlt : theme.appColors.base2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: tag.enabled ? theme.appColors.base3 : theme.appColors.base4,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji a název
            Expanded(
              child: Row(
                children: [
                  if (tag.emoji != null && tag.emoji!.isNotEmpty)
                    Text(
                      tag.emoji!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '*${tag.tagName}*',
                          style: TextStyle(
                            color: tag.enabled ? theme.appColors.cyan : theme.appColors.base5,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (tag.displayName != null && tag.displayName!.isNotEmpty)
                          Text(
                            tag.displayName!,
                            style: TextStyle(
                              color: tag.enabled ? theme.appColors.base5 : theme.appColors.base6,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enable/disable switch
            Switch(
              value: tag.enabled,
              onChanged: (_) => onToggle(),
              activeThumbColor: theme.appColors.green,
            ),

            // Edit button
            IconButton(
              icon: Icon(Icons.edit, color: theme.appColors.cyan, size: 20),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete, color: theme.appColors.red, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAG DIALOG (ADD/EDIT)
// ============================================================================

enum TagDialogMode { add, edit }

class _TagDialog extends StatefulWidget {
  final TagDialogMode mode;
  final TagDefinition? initialTag;

  const _TagDialog({
    required this.mode,
    this.initialTag,
  });

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;
  late TextEditingController _emojiController;
  late TextEditingController _colorController;
  late TagType _selectedType;
  late bool _glowEnabled;
  late double _glowStrength;

  @override
  void initState() {
    super.initState();

    final tag = widget.initialTag;
    _nameController = TextEditingController(text: tag?.tagName ?? '');
    _displayNameController = TextEditingController(text: tag?.displayName ?? '');
    _emojiController = TextEditingController(text: tag?.emoji ?? '');
    _colorController = TextEditingController(text: tag?.color ?? '');
    _selectedType = tag?.tagType ?? TagType.custom;
    _glowEnabled = tag?.glowEnabled ?? false;
    _glowStrength = tag?.glowStrength ?? 0.5;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _emojiController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mode == TagDialogMode.edit;

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEdit ? theme.appColors.cyan : theme.appColors.green,
          width: 2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.minHeight,
                maxHeight: viewportConstraints.maxHeight,
                maxWidth: 600,
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                curve: Curves.decelerate,
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: IntrinsicHeight(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              isEdit ? Icons.edit : Icons.add_circle,
                              color: isEdit ? theme.appColors.cyan : theme.appColors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit ? 'Editace tagu' : 'Nový tag',
                                style: TextStyle(
                                  color: isEdit ? theme.appColors.cyan : theme.appColors.green,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: theme.appColors.base5, size: 22),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                        Divider(color: theme.appColors.base3, height: 16),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildDialogField(
                                  'Název tagu (bez hvězdiček)',
                                  _nameController,
                                  isEdit ? 'např. dnes, a, udelat' : 'např. vikend, projekt',
                                  theme,
                                ),
                                const SizedBox(height: 16),

                                _buildDialogField(
                                  'Zobrazovaný název',
                                  _displayNameController,
                                  isEdit ? 'např. Dnešní termín, Vysoká priorita' : 'např. Víkendový úkol',
                                  theme,
                                ),
                                const SizedBox(height: 16),

                                _buildDialogField(
                                  'Emoji',
                                  _emojiController,
                                  isEdit ? '🔥' : '🏖️',
                                  theme,
                                ),
                                const SizedBox(height: 16),

                                // Color picker button
                                _buildColorPickerButton(theme),
                                const SizedBox(height: 16),

                                // Typ tagu dropdown
                                _buildTypeDropdown(theme),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tlačítka
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5, fontSize: 14)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _saveTag(context, theme),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEdit ? theme.appColors.cyan : theme.appColors.green,
                                foregroundColor: theme.appColors.bg,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: Text(isEdit ? 'Uložit' : 'Přidat', style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    String hint,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: theme.appColors.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.appColors.base5),
            filled: true,
            fillColor: theme.appColors.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.appColors.base4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPickerButton(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barva',
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => ColorPickerDialog(
                initialColor: _colorController.text.trim().isEmpty
                    ? (widget.mode == TagDialogMode.add ? '#50FA7B' : '#50FA7B')
                    : _colorController.text.trim(),
                initialGlowEnabled: _glowEnabled,
                initialGlowStrength: _glowStrength,
              ),
            );

            if (result != null) {
              setState(() {
                _colorController.text = result['color'] as String;
                _glowEnabled = result['glowEnabled'] as bool;
                _glowStrength = result['glowStrength'] as double;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.appColors.base2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.base4),
            ),
            child: Row(
              children: [
                // Color preview box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorUtils.isValidHex(_colorController.text)
                        ? ColorUtils.hexToColor(_colorController.text)
                        : (widget.mode == TagDialogMode.add
                            ? theme.appColors.green
                            : theme.appColors.cyan),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.appColors.base6, width: 2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _colorController.text.trim().isEmpty
                        ? 'Vyberte barvu'
                        : _colorController.text,
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Icon(
                  Icons.palette,
                  color: widget.mode == TagDialogMode.add
                      ? theme.appColors.green
                      : theme.appColors.cyan,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Typ tagu',
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TagType>(
          initialValue: _selectedType,
          dropdownColor: theme.appColors.base2,
          style: TextStyle(color: theme.appColors.fg),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.appColors.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.appColors.base4),
            ),
          ),
          items: TagType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
        ),
      ],
    );
  }

  void _saveTag(BuildContext context, ThemeData theme) {
    // Validace
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Název tagu nesmí být prázdný'),
          backgroundColor: theme.appColors.red,
        ),
      );
      return;
    }

    // Vytvoř nový nebo upravený tag
    final tag = widget.mode == TagDialogMode.edit && widget.initialTag != null
        ? widget.initialTag!.copyWith(
            tagName: _nameController.text.trim().toLowerCase(),
            displayName: _displayNameController.text.trim(),
            emoji: _emojiController.text.trim(),
            color: _colorController.text.trim(),
            tagType: _selectedType,
            glowEnabled: _glowEnabled,
            glowStrength: _glowStrength,
          )
        : TagDefinition(
            tagName: _nameController.text.trim().toLowerCase(),
            tagType: _selectedType,
            displayName: _displayNameController.text.trim(),
            emoji: _emojiController.text.trim(),
            color: _colorController.text.trim(),
            glowEnabled: _glowEnabled,
            glowStrength: _glowStrength,
            enabled: true,
          );

    Navigator.of(context).pop(tag);
  }
}

// ============================================================================
// DELIMITER SELECTOR WIDGET
// ============================================================================

class _DelimiterSelector extends StatelessWidget {
  final String tagDelimiterStart;
  final String tagDelimiterEnd;
  final void Function(String start, String end) onSave;
  final void Function(String start, String end) onDelimiterChange;

  const _DelimiterSelector({
    required this.tagDelimiterStart,
    required this.tagDelimiterEnd,
    required this.onSave,
    required this.onDelimiterChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.appColors.bgAlt,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: theme.appColors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                '🏷️ ODDĚLOVAČE TAGŮ',
                style: TextStyle(
                  color: theme.appColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Zvol symboly pro označení tagů v textu:',
            style: TextStyle(
              color: theme.appColors.base5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // Předvolené vzory oddělovačů
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDelimiterChip('*', '*', 'Hvězdičky', theme),
              _buildDelimiterChip('@', '@', 'Zavináče', theme),
              _buildDelimiterChip('!', '!', 'Vykřičníky', theme),
              _buildDelimiterChip('#', '#', 'Mřížky', theme),
              _buildDelimiterChip('[', ']', 'Hranaté závorky', theme),
              _buildDelimiterChip('{', '}', 'Složené závorky', theme),
            ],
          ),
          const SizedBox(height: 12),

          // Live preview
          _buildPreview(theme),
          const SizedBox(height: 12),

          // Save button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => onSave(tagDelimiterStart, tagDelimiterEnd),
              icon: const Icon(Icons.save, size: 16),
              label: const Text('ULOŽIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.green,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelimiterChip(String start, String end, String label, ThemeData theme) {
    final isSelected = tagDelimiterStart == start && tagDelimiterEnd == end;

    return InkWell(
      onTap: () => onDelimiterChange(start, end),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.appColors.cyan.withValues(alpha: 0.2)
              : theme.appColors.base2,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? theme.appColors.cyan : theme.appColors.base4,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$start tag $end',
              style: TextStyle(
                color: isSelected ? theme.appColors.cyan : theme.appColors.fg,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.appColors.cyan : theme.appColors.base5,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.appColors.base2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Řádek 1: Základní příklad (priority, datum, action)
          Wrap(
            spacing: 4,
            children: [
              Text(
                'Náhled: ',
                style: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 12,
                ),
              ),
              Text(
                tagDelimiterStart,
                style: TextStyle(
                  color: theme.appColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'a',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$tagDelimiterEnd ',
                style: TextStyle(
                  color: theme.appColors.cyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                tagDelimiterStart,
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'dnes',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$tagDelimiterEnd ',
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                tagDelimiterStart,
                style: TextStyle(
                  color: theme.appColors.magenta,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'udelat',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                tagDelimiterEnd,
                style: TextStyle(
                  color: theme.appColors.magenta,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Řádek 2: DateTime příklad (S MEZEROU - preferovaný formát)
          Wrap(
            spacing: 4,
            children: [
              Text(
                'Čas: ',
                style: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 12,
                ),
              ),
              Text(
                tagDelimiterStart,
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'dnes 14:00',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$tagDelimiterEnd ',
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                tagDelimiterStart,
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'zítra 9.30',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                tagDelimiterEnd,
                style: TextStyle(
                  color: theme.appColors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
