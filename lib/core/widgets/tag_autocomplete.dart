import 'package:flutter/material.dart';
import '../services/database_helper.dart';

/// Widget pro tag autocomplete
///
/// Zobrazí 10 nejpoužívanějších tagů pod input fieldem.
/// Klik na tag = doplní do inputu (s oddělovači).
class TagAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String startDelimiter;
  final String endDelimiter;

  const TagAutocomplete({
    super.key,
    required this.controller,
    this.startDelimiter = '*',
    this.endDelimiter = '*',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getTopCustomTags(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final tags = snapshot.data!;

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final tagName = tag['display_name'] as String;
              final usageCount = tag['usage_count'] as int;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text('$tagName ($usageCount)'),
                  avatar: const Icon(Icons.label, size: 16),
                  onPressed: () {
                    // Doplnit tag do inputu
                    final currentText = controller.text;
                    final newText = currentText.isEmpty
                        ? '$startDelimiter$tagName$endDelimiter '
                        : '$currentText $startDelimiter$tagName$endDelimiter ';

                    controller.text = newText;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: newText.length),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
