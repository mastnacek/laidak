import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme_colors.dart';
import '../utils/clipboard_content_detector.dart';

/// SmartClipboardDialog - Dialog s akcemi pro zkopírovaný obsah
///
/// Podle typu obsahu nabízí relevantní akce:
/// - Telefon: Zavolat, SMS, WhatsApp
/// - Email: Poslat email
/// - URL: Otevřít v prohlížeči
///
/// Usage:
/// ```dart
/// showSmartClipboardDialog(
///   context,
///   DetectedClipboardContent(type: phone, value: '+420123456789'),
/// );
/// ```
Future<void> showSmartClipboardDialog(
  BuildContext context,
  DetectedClipboardContent detected,
) async {
  final theme = Theme.of(context);

  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.cyan, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIconForType(detected.type),
                  color: theme.appColors.cyan,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTitleForType(detected.type),
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

            // Detekovaný obsah
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.base2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.appColors.base3),
              ),
              child: SelectableText(
                detected.value,
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Akce podle typu
            _buildActions(context, theme, detected),
          ],
        ),
      ),
    ),
  );
}

/// Získat ikonu podle typu
IconData _getIconForType(ClipboardContentType type) {
  switch (type) {
    case ClipboardContentType.phone:
      return Icons.phone;
    case ClipboardContentType.email:
      return Icons.email;
    case ClipboardContentType.url:
      return Icons.link;
    default:
      return Icons.content_paste;
  }
}

/// Získat titulek podle typu
String _getTitleForType(ClipboardContentType type) {
  switch (type) {
    case ClipboardContentType.phone:
      return '📞 TELEFONNÍ ČÍSLO';
    case ClipboardContentType.email:
      return '📧 EMAIL ADRESA';
    case ClipboardContentType.url:
      return '🔗 ODKAZ';
    default:
      return '📋 TEXT';
  }
}

/// Vytvořit akce podle typu
Widget _buildActions(
  BuildContext context,
  ThemeData theme,
  DetectedClipboardContent detected,
) {
  switch (detected.type) {
    case ClipboardContentType.phone:
      return _buildPhoneActions(context, theme, detected.value);
    case ClipboardContentType.email:
      return _buildEmailActions(context, theme, detected.value);
    case ClipboardContentType.url:
      return _buildUrlActions(context, theme, detected.value);
    default:
      return const SizedBox.shrink();
  }
}

/// Akce pro telefon
Widget _buildPhoneActions(BuildContext context, ThemeData theme, String phone) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Zavolat
      _ActionButton(
        icon: Icons.phone,
        label: 'Zavolat',
        color: theme.appColors.green,
        onPressed: () async {
          final uri = Uri.parse('tel:$phone');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            if (context.mounted) Navigator.of(context).pop();
          } else {
            if (context.mounted) {
              _showError(context, 'Nelze zavolat na toto číslo');
            }
          }
        },
      ),
      const SizedBox(height: 8),

      // SMS
      _ActionButton(
        icon: Icons.message,
        label: 'Poslat SMS',
        color: theme.appColors.blue,
        onPressed: () async {
          final uri = Uri.parse('sms:$phone');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            if (context.mounted) Navigator.of(context).pop();
          } else {
            if (context.mounted) {
              _showError(context, 'Nelze otevřít SMS');
            }
          }
        },
      ),
      const SizedBox(height: 8),

      // WhatsApp
      _ActionButton(
        icon: Icons.chat,
        label: 'Otevřít WhatsApp',
        color: Color(0xFF25D366), // WhatsApp zelená
        onPressed: () async {
          // Odstranit + z čísla pro WhatsApp
          final whatsappPhone = phone.replaceAll('+', '');
          final uri = Uri.parse('whatsapp://send?phone=$whatsappPhone');

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            if (context.mounted) Navigator.of(context).pop();
          } else {
            if (context.mounted) {
              _showError(context, 'WhatsApp není nainstalován');
            }
          }
        },
      ),
    ],
  );
}

/// Akce pro email
Widget _buildEmailActions(BuildContext context, ThemeData theme, String email) {
  return _ActionButton(
    icon: Icons.email,
    label: 'Poslat email',
    color: theme.appColors.blue,
    onPressed: () async {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (context.mounted) Navigator.of(context).pop();
      } else {
        if (context.mounted) {
          _showError(context, 'Nelze otevřít email klienta');
        }
      }
    },
  );
}

/// Akce pro URL
Widget _buildUrlActions(BuildContext context, ThemeData theme, String url) {
  return _ActionButton(
    icon: Icons.open_in_browser,
    label: 'Otevřít v prohlížeči',
    color: theme.appColors.cyan,
    onPressed: () async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) Navigator.of(context).pop();
      } else {
        if (context.mounted) {
          _showError(context, 'Nelze otevřít odkaz');
        }
      }
    },
  );
}

/// Zobrazit error
void _showError(BuildContext context, String message) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('❌ $message'),
      backgroundColor: theme.appColors.red,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Action button komponenta
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
