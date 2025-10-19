import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../../core/theme/theme_colors.dart';
import '../../../../../core/services/tts_service.dart';
import '../../../domain/entities/todo.dart';

/// Dialog zobrazující AI motivaci pro úkol
///
/// Features:
/// - Markdown rendering
/// - TTS (text-to-speech) podpora
/// - Cache indikátor (💾 ULOŽENO badge)
/// - Kopírování do schránky
/// - Regenerace motivace (pouze pro cached)
class MotivationDialog {
  /// Zobrazit dialog s AI motivací (včetně cache indikátoru + tlačítka "Nová")
  static void show(
    BuildContext context, {
    required Todo todo,
    required String motivation,
    required bool isCached,
    required Future<void> Function() onRegenerate,
  }) {
    final theme = Theme.of(context);
    final scrollController = ScrollController();
    final ttsService = TtsService();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: theme.appColors.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.appColors.magenta, width: 2),
            ),
            insetPadding: const EdgeInsets.all(3),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 6,
                maxHeight: MediaQuery.of(context).size.height * 0.95,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: theme.appColors.magenta, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI MOTIVACE',
                          style: TextStyle(
                            color: theme.appColors.magenta,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // 💾 ULOŽENO badge (pouze pokud isCached)
                      if (isCached) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.appColors.green.withValues(alpha: 0.2),
                            border: Border.all(color: theme.appColors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '💾 ULOŽENO',
                            style: TextStyle(
                              color: theme.appColors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: Icon(Icons.close, color: theme.appColors.base5, size: 22),
                        onPressed: () {
                          ttsService.stop();
                          Navigator.of(dialogContext).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(color: theme.appColors.base3, height: 16),

                  // Task preview
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.appColors.bgAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.appColors.base3),
                    ),
                    child: Text(
                      '📋 ${todo.task}',
                      style: TextStyle(
                        color: theme.appColors.fg,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Motivation text s MARKDOWN renderingem - Scrollable
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.appColors.bgAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.appColors.base3.withValues(alpha: 0.3)),
                      ),
                      child: Markdown(
                        controller: scrollController,
                        data: motivation, // Markdown text (AI vrací **bold**, *italic*, atd.)
                        selectable: true, // Umožnit výběr textu
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        styleSheet: MarkdownStyleSheet(
                          // Základní text styling (zachovat emoji!)
                          p: TextStyle(
                            color: theme.appColors.fg,
                            fontSize: 16,
                            height: 1.6,
                          ),
                          // Bold text (**text**)
                          strong: TextStyle(
                            color: theme.appColors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          // Italic text (*text*)
                          em: TextStyle(
                            color: theme.appColors.cyan,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                          // Heading 1 (# text)
                          h1: TextStyle(
                            color: theme.appColors.magenta,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          // Heading 2 (## text)
                          h2: TextStyle(
                            color: theme.appColors.blue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          // Lists (bullet points)
                          listBullet: TextStyle(
                            color: theme.appColors.green,
                            fontSize: 16,
                          ),
                          // Code inline (`code`)
                          code: TextStyle(
                            color: theme.appColors.orange,
                            fontSize: 14,
                            fontFamily: 'monospace',
                            backgroundColor: theme.appColors.base1,
                          ),
                          // Block quotes (> text)
                          blockquote: TextStyle(
                            color: theme.appColors.base5,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: theme.appColors.base1,
                            border: Border(
                              left: BorderSide(
                                color: theme.appColors.cyan,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action buttons (kompaktní layout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // TTS button
                      IconButton(
                        onPressed: () async {
                          if (ttsService.isSpeaking) {
                            await ttsService.stop();
                          } else {
                            // speak() automaticky čistí markdown (zachovává emoji!)
                            await ttsService.speak(motivation);
                          }
                          setState(() {}); // Rebuild pro změnu ikony
                        },
                        icon: Icon(
                          ttsService.isSpeaking ? Icons.stop : Icons.volume_up,
                          color: theme.appColors.green,
                          size: 24,
                        ),
                        tooltip: ttsService.isSpeaking ? 'Zastavit' : 'Číst nahlas',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      // Copy to clipboard button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: motivation)); // Kopírovat markdown
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('✅ Text zkopírován do schránky'),
                                backgroundColor: theme.appColors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.copy, color: theme.appColors.cyan, size: 18),
                        label: Text(
                          'Kopírovat',
                          style: TextStyle(color: theme.appColors.cyan, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.appColors.cyan),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Regenerate button (pouze pokud isCached)
                      if (isCached) ...[
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Zavřít současný dialog
                            Navigator.of(dialogContext).pop();
                            // Vygenerovat NOVOU motivaci
                            await onRegenerate();
                          },
                          icon: Icon(Icons.refresh, color: theme.appColors.yellow, size: 18),
                          label: Text(
                            'Nová',
                            style: TextStyle(color: theme.appColors.yellow, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.appColors.yellow),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Close button
                      ElevatedButton(
                        onPressed: () {
                          ttsService.stop();
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.appColors.magenta,
                          foregroundColor: theme.appColors.bg,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Zavřít', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
