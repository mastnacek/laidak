import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../domain/models/smart_folder.dart';
import '../../domain/models/filter_rules.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';

/// SmartFolderFormSheet - Bottom sheet pro vytváření/editaci Smart Folders (PHASE 3)
///
/// Podporuje:
/// - Create mode: SmartFolder folder = null
/// - Edit mode: SmartFolder folder != null
/// - FilterType: all, recent, tags, dateRange
/// - Emoji picker (zatím hardcoded list)
/// - Validation
class SmartFolderFormSheet extends StatefulWidget {
  final SmartFolder? folder; // null = create, not null = edit

  const SmartFolderFormSheet({
    super.key,
    this.folder,
  });

  @override
  State<SmartFolderFormSheet> createState() => _SmartFolderFormSheetState();
}

class _SmartFolderFormSheetState extends State<SmartFolderFormSheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = '📁';
  FilterType _filterType = FilterType.all;
  int _recentDays = 7;

  bool get _isEditMode => widget.folder != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill v edit mode
    if (_isEditMode) {
      _nameController.text = widget.folder!.name;
      _selectedIcon = widget.folder!.icon;
      _filterType = widget.folder!.filterRules.type;
      _recentDays = widget.folder!.filterRules.recentDays ?? 7;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.appColors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEditMode ? 'Upravit složku' : 'Nová složka',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.fg,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.appColors.base5),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name field
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: theme.appColors.fg),
            decoration: InputDecoration(
              labelText: 'Název složky',
              labelStyle: TextStyle(color: theme.appColors.base5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.appColors.base4),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.appColors.base4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.appColors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Icon picker
          Text(
            'Ikona',
            style: TextStyle(
              fontSize: 14,
              color: theme.appColors.base5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildIconPicker(theme),
          const SizedBox(height: 16),

          // Filter type selector
          Text(
            'Typ filtru',
            style: TextStyle(
              fontSize: 14,
              color: theme.appColors.base5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterTypeSelector(theme),

          // Filter options (recent days)
          if (_filterType == FilterType.recent) ...[
            const SizedBox(height: 16),
            _buildRecentDaysSlider(theme),
          ],

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.blue,
                foregroundColor: theme.appColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isEditMode ? 'Uložit změny' : 'Vytvořit složku',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Icon picker - horizontal scroll s emoji
  Widget _buildIconPicker(ThemeColors theme) {
    const icons = ['📁', '📝', '⭐', '🕐', '📊', '💼', '🎯', '🔥', '✨', '📌'];

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final icon = icons[index];
          final isSelected = _selectedIcon == icon;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedIcon = icon;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.blue.withOpacity(0.2)
                      : theme.base2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? theme.blue : theme.base4,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Filter type selector - radio buttons
  Widget _buildFilterTypeSelector(ThemeColors theme) {
    return Column(
      children: [
        _buildRadioOption(
          theme,
          FilterType.all,
          'Všechny poznámky',
          'Zobrazí všechny poznámky bez filtru',
        ),
        _buildRadioOption(
          theme,
          FilterType.recent,
          'Poslední dny',
          'Zobrazí poznámky za poslední X dní',
        ),
        // TODO: tags a dateRange v MILESTONE 3.1
      ],
    );
  }

  Widget _buildRadioOption(
    ThemeColors theme,
    FilterType type,
    String title,
    String subtitle,
  ) {
    final isSelected = _filterType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _filterType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.blue.withOpacity(0.1) : theme.base2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.blue : theme.base4,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.blue : theme.base5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.base5,
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

  /// Recent days slider (pro FilterType.recent)
  Widget _buildRecentDaysSlider(ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Počet dní: $_recentDays',
          style: TextStyle(
            fontSize: 14,
            color: theme.fg,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: _recentDays.toDouble(),
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: theme.blue,
          inactiveColor: theme.base4,
          onChanged: (value) {
            setState(() {
              _recentDays = value.toInt();
            });
          },
        ),
      ],
    );
  }

  /// Handle save button
  void _handleSave() {
    final name = _nameController.text.trim();

    // Validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Název složky nesmí být prázdný'),
          backgroundColor: Theme.of(context).appColors.red,
        ),
      );
      return;
    }

    // Vytvořit FilterRules podle typu
    final filterRules = FilterRules(
      type: _filterType,
      recentDays: _filterType == FilterType.recent ? _recentDays : null,
    );

    // Vytvořit/update SmartFolder
    final folder = SmartFolder(
      id: _isEditMode ? widget.folder!.id : null,
      name: name,
      icon: _selectedIcon,
      isSystem: false, // Custom folders jsou vždy isSystem=false
      filterRules: filterRules,
      displayOrder: _isEditMode
          ? widget.folder!.displayOrder
          : 100, // Custom folders na konec
      createdAt: _isEditMode ? widget.folder!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Dispatch event
    if (_isEditMode) {
      context.read<NotesBloc>().add(UpdateSmartFolderEvent(folder));
    } else {
      context.read<NotesBloc>().add(CreateSmartFolderEvent(folder));
    }

    // Close sheet
    Navigator.pop(context);
  }
}
