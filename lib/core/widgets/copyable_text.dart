import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_colors.dart';

/// CopyableText - Reusable widget pro text s možností kopírování do schránky
///
/// Features:
/// - Copy button (ikona nebo text)
/// - Automatická snackbar notifikace
/// - Customizovatelný vzhled
/// - Support pro selection (long press)
///
/// Usage:
/// ```dart
/// CopyableText(
///   text: 'Text ke kopírování',
///   showIcon: true,
/// )
/// ```
class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool showIcon;
  final IconData icon;
  final double iconSize;
  final String? copyButtonLabel;
  final String successMessage;
  final int maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final bool selectable;

  const CopyableText({
    super.key,
    required this.text,
    this.style,
    this.showIcon = true,
    this.icon = Icons.copy,
    this.iconSize = 16,
    this.copyButtonLabel,
    this.successMessage = '📋 Zkopírováno do schránky',
    this.maxLines = 999,
    this.overflow,
    this.textAlign = TextAlign.start,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text (selectable nebo ne)
        Expanded(
          child: selectable
              ? SelectableText(
                  text,
                  style: style,
                  maxLines: maxLines,
                  textAlign: textAlign,
                )
              : Text(
                  text,
                  style: style,
                  maxLines: maxLines,
                  overflow: overflow,
                  textAlign: textAlign,
                ),
        ),

        // Copy button
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _copyToClipboard(context),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: theme.appColors.cyan.withValues(alpha: 0.7),
                ),
                if (copyButtonLabel != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    copyButtonLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.appColors.cyan.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Kopírovat text do schránky
  Future<void> _copyToClipboard(BuildContext context) async {
    final theme = Theme.of(context);

    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: theme.appColors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při kopírování: $e'),
            backgroundColor: theme.appColors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// CopyButton - Samostatné tlačítko pro kopírování (bez textu)
///
/// Usage:
/// ```dart
/// CopyButton(
///   textToCopy: 'Text ke kopírování',
///   tooltip: 'Kopírovat text',
/// )
/// ```
class CopyButton extends StatelessWidget {
  final String textToCopy;
  final String? tooltip;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final String successMessage;

  const CopyButton({
    super.key,
    required this.textToCopy,
    this.tooltip,
    this.icon = Icons.copy,
    this.iconSize = 20,
    this.iconColor,
    this.successMessage = '📋 Zkopírováno do schránky',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.appColors.cyan;

    return IconButton(
      icon: Icon(icon, size: iconSize),
      color: effectiveIconColor,
      tooltip: tooltip ?? 'Kopírovat do schránky',
      onPressed: () => _copyToClipboard(context),
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }

  /// Kopírovat text do schránky
  Future<void> _copyToClipboard(BuildContext context) async {
    final theme = Theme.of(context);

    try {
      await Clipboard.setData(ClipboardData(text: textToCopy));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: theme.appColors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při kopírování: $e'),
            backgroundColor: theme.appColors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
