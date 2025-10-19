import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_colors.dart';

/// Dialog pro potvrzení pokračování v opakujícím se úkolu
///
/// Vrací: true = pokračovat, false = ukončit, null = zrušeno
class RecurrenceConfirmationDialog extends StatelessWidget {
  final DateTime nextDate;

  const RecurrenceConfirmationDialog({
    super.key,
    required this.nextDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.green, width: 2),
      ),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: theme.appColors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '✓ ÚKOL DOKONČEN!',
              style: TextStyle(
                color: theme.appColors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Další termín:',
            style: TextStyle(
              color: theme.appColors.fg,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE d.M.yyyy', 'cs').format(nextDate),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.appColors.magenta,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Ukončit
          child: Text(
            'Ukončit opakování',
            style: TextStyle(color: theme.appColors.base5),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // Pokračovat
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appColors.green,
            foregroundColor: theme.appColors.bg,
          ),
          child: const Text('Pokračovat'),
        ),
      ],
    );
  }
}
