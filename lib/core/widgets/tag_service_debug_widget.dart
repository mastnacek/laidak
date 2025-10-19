import 'package:flutter/material.dart';
import '../../services/tag_service.dart';
import '../../models/tag_definition.dart';

/// Debug widget pro zobrazení stavu TagService přímo v UI
///
/// Použití:
/// ```dart
/// FloatingActionButton(
///   onPressed: () {
///     showDialog(
///       context: context,
///       builder: (_) => const TagServiceDebugWidget(),
///     );
///   },
///   child: Icon(Icons.bug_report),
/// )
/// ```
class TagServiceDebugWidget extends StatelessWidget {
  const TagServiceDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🐛 TagService Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<TagDefinition>>(
                future: _loadTagDefinitions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '❌ Chyba: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final definitions = snapshot.data ?? [];

                  if (definitions.isEmpty) {
                    return const Center(
                      child: Text(
                        '⚠️ TagService cache je PRÁZDNÁ!',
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: definitions.length,
                    itemBuilder: (context, index) {
                      final def = definitions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${def.emoji ?? '❓'} ',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  Text(
                                    def.tagName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${def.tagType.name})',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildColorPreview(def.color),
                              const SizedBox(height: 4),
                              Text(
                                'Color: "${def.color ?? "NULL"}"',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Enabled: ${def.enabled}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zavřít'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<TagDefinition>> _loadTagDefinitions() async {
    try {
      final tagService = TagService();
      return tagService.getAllDefinitions();
    } catch (e) {
      throw Exception('TagService není inicializovaný: $e');
    }
  }

  Widget _buildColorPreview(String? hexColor) {
    if (hexColor == null) {
      return Container(
        width: double.infinity,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            '❌ NULL',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Parse hex color
    final color = _parseHexColor(hexColor);

    if (color == null) {
      return Container(
        width: double.infinity,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '⚠️ INVALID HEX: $hexColor',
            style: const TextStyle(color: Colors.orange, fontSize: 10),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey),
      ),
      child: Center(
        child: Text(
          '✅ OK',
          style: TextStyle(
            color: _getContrastColor(color),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color? _parseHexColor(String hexString) {
    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 3) {
        hex = hex.split('').map((c) => c + c).join();
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          return Color(value);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Color _getContrastColor(Color bgColor) {
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
