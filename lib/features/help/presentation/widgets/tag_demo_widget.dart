import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../services/tag_parser.dart';

/// TagDemoWidget - Interaktivní demo pro živé parsování tagů (bez API)
///
/// Funkce:
/// - TextField pro zadání testovacího textu
/// - Real-time parsing při změně textu
/// - Zobrazení výsledku parsování:
///   - Čistý text (bez tagů)
///   - Priorita
///   - Deadline
///   - Custom tagy
/// - Copy-paste ready examples
class TagDemoWidget extends StatefulWidget {
  const TagDemoWidget({super.key});

  @override
  State<TagDemoWidget> createState() => _TagDemoWidgetState();
}

class _TagDemoWidgetState extends State<TagDemoWidget> {
  final TextEditingController _controller = TextEditingController();
  ParsedTask? _parsedResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Defaultní example text
    _controller.text = '*a* *dnes* Zavolat doktorovi';
    _parseText(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parsovat text pomocí TagParser
  Future<void> _parseText(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _parsedResult = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await TagParser.parse(text);
      setState(() {
        _parsedResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _parsedResult = null;
        _isLoading = false;
      });
    }
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.label, color: theme.appColors.cyan, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🏷️ Tag Demo - Živé parsování',
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

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.appColors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.appColors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zadej text s tagy a uvidíš výsledek parsování v reálném čase!',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input TextField
            Text(
              'Zadej text úkolu:',
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: (text) => _parseText(text),
              style: TextStyle(
                color: theme.appColors.fg,
                fontSize: 14,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '*a* *dnes* Zavolat doktorovi',
                hintStyle: TextStyle(color: theme.appColors.base5),
                filled: true,
                fillColor: theme.appColors.base2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.base4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.appColors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Examples buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExampleChip(
                  context,
                  '*a* *dnes* Zavolat doktorovi',
                  'Priorita A + Dnes',
                ),
                _buildExampleChip(
                  context,
                  '*b* *15.1.2025* Koupit dárek',
                  'Priorita B + Datum',
                ),
                _buildExampleChip(
                  context,
                  '*c* Uklidit garáž *domov*',
                  'Priorita C + Custom tag',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parsed Result
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_parsedResult != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _buildParsedResult(theme, _parsedResult!),
                ),
              )
            else
              Center(
                child: Text(
                  'Zadej text pro zobrazení výsledku...',
                  style: TextStyle(
                    color: theme.appColors.base5,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Chip s příkladem (kliknutím vyplní TextField)
  Widget _buildExampleChip(BuildContext context, String text, String label) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        _controller.text = text;
        _parseText(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.appColors.magenta.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.appColors.magenta),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.appColors.magenta,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Zobrazení výsledku parsování
  Widget _buildParsedResult(ThemeData theme, ParsedTask result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appColors.base2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.appColors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.appColors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                '✅ Výsledek parsování:',
                style: TextStyle(
                  color: theme.appColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Čistý text
          _buildResultRow(
            theme,
            'Čistý text',
            result.cleanText.isEmpty
                ? '(prázdný)'
                : result.cleanText,
            Icons.text_fields,
          ),
          const SizedBox(height: 12),

          // Priorita
          _buildResultRow(
            theme,
            'Priorita',
            result.priority != null
                ? result.priority!.toUpperCase()
                : '(žádná)',
            Icons.priority_high,
            color: result.priority != null ? theme.appColors.red : null,
          ),
          const SizedBox(height: 12),

          // Deadline
          _buildResultRow(
            theme,
            'Deadline',
            result.dueDate != null
                ? TagParser.formatDate(result.dueDate!)
                : '(žádný)',
            Icons.calendar_today,
            color: result.dueDate != null ? theme.appColors.yellow : null,
          ),
          const SizedBox(height: 12),

          // Custom tagy
          _buildResultRow(
            theme,
            'Custom tagy',
            result.tags.isEmpty
                ? '(žádné)'
                : result.tags.join(', '),
            Icons.label,
            color: result.tags.isNotEmpty ? theme.appColors.cyan : null,
          ),
        ],
      ),
    );
  }

  /// Řádek s výsledkem
  Widget _buildResultRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color ?? theme.appColors.base5,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color ?? theme.appColors.fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
