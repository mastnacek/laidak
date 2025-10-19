import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/color_utils.dart';

/// Dialog pro výběr barvy s circular color pickrem a glow efektem
class ColorPickerDialog extends StatefulWidget {
  final String initialColor; // hex barva
  final bool initialGlowEnabled;
  final double initialGlowStrength;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.initialGlowEnabled = false,
    this.initialGlowStrength = 0.5,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;
  late bool _glowEnabled;
  late double _glowStrength;

  @override
  void initState() {
    super.initState();
    // Inicializovat barvu z hex stringu
    _selectedColor = ColorUtils.isValidHex(widget.initialColor)
        ? ColorUtils.hexToColor(widget.initialColor)
        : Colors.cyan;
    _glowEnabled = widget.initialGlowEnabled;
    _glowStrength = widget.initialGlowStrength;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                maxWidth: 500,
              ),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                curve: Curves.decelerate,
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: IntrinsicHeight(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(Icons.palette, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Výběr barvy',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 22),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                        Divider(color: theme.colorScheme.outline, height: 16),

                        // Color Picker (HSV Wheel)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ColorPicker(
                                  pickerColor: _selectedColor,
                                  onColorChanged: (color) {
                                    setState(() => _selectedColor = color);
                                  },
                                  colorPickerWidth: 300,
                                  pickerAreaHeightPercent: 0.7,
                                  enableAlpha: false,
                                  displayThumbColor: true,
                                  paletteType: PaletteType.hueWheel,
                                  labelTypes: const [],
                                  pickerAreaBorderRadius: BorderRadius.circular(12),
                                ),
                                const SizedBox(height: 24),

                                // Hex kód (read-only display)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hex: ',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        ColorUtils.colorToHex(_selectedColor),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Glow efekt toggle
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _glowEnabled
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: _glowEnabled
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Glow efekt',
                                              style: TextStyle(
                                                color: _glowEnabled
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurface,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: _glowEnabled,
                                            onChanged: (value) {
                                              setState(() => _glowEnabled = value);
                                            },
                                            activeThumbColor: theme.colorScheme.primary,
                                          ),
                                        ],
                                      ),

                                      // Slider pro sílu glow efektu (pouze když je zapnutý)
                                      if (_glowEnabled) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Síla glow efektu',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Slider(
                                          value: _glowStrength,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 10,
                                          label: '${(_glowStrength * 100).toInt()}%',
                                          onChanged: (value) {
                                            setState(() => _glowStrength = value);
                                          },
                                          activeColor: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(height: 16),

                                        // Náhled glow efektu
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _selectedColor,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: _glowEnabled
                                                  ? [
                                                      BoxShadow(
                                                        color: _selectedColor.withValues(alpha: _glowStrength),
                                                        blurRadius: 20 * _glowStrength,
                                                        spreadRadius: 5 * _glowStrength,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              'NÁHLED GLOW',
                                              style: TextStyle(
                                                color: _selectedColor.computeLuminance() > 0.5
                                                    ? Colors.black
                                                    : Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Akční tlačítka
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Zrušit',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                // Vrátit výsledek jako Map
                                Navigator.of(context).pop({
                                  'color': ColorUtils.colorToHex(_selectedColor),
                                  'glowEnabled': _glowEnabled,
                                  'glowStrength': _glowStrength,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: const Text('Vybrat'),
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
}
