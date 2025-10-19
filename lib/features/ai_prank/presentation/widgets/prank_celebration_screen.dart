import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/tts_service.dart';
import '../../../todo_list/domain/entities/todo.dart';

/// Fullscreen dialog pro AI Prank/Good Deed Celebration po dokončení úkolu
///
/// Features:
/// - Fullscreen zobrazení (stejná velikost jako Motivation)
/// - Markdown rendering
/// - TTS (text-to-speech) podpora
/// - Kopírování do schránky
/// - Úzké okraje (insetPadding: 3)
/// - Různé barvy pro prank (zelená) vs good deed (modrá)
class PrankCelebrationScreen {
  /// Zobrazit fullscreen prank/good deed celebration
  static void show(
    BuildContext context, {
    required Todo completedTodo,
    required String prankMessage,
    required bool isPrank, // true = prank (zelená), false = good deed (modrá)
  }) {
    final theme = Theme.of(context);
    final scrollController = ScrollController();
    final ttsService = TtsService();

    // 🎨 Barvy a texty podle typu
    final accentColor = isPrank ? theme.appColors.green : theme.appColors.blue;
    final icon = isPrank ? Icons.celebration : Icons.favorite;
    final title = isPrank ? 'SKVĚLÁ PRÁCE! 🎉' : 'ÚŽASNÉ! 💚';

    showDialog<void>(
      context: context,
      barrierDismissible: true, // Můžeš zavřít kliknutím mimo
      builder: (dialogContext) {
        bool isSpeaking = false; // ✅ Lokální state pro TTS

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
            backgroundColor: theme.appColors.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: accentColor, width: 2), // 🎉 Accent color podle typu
            ),
            insetPadding: const EdgeInsets.all(3), // ✅ Stejné jako motivation
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
                      Icon(icon,
                          color: accentColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: theme.appColors.base5, size: 22),
                        onPressed: () {
                          if (isSpeaking) {
                            ttsService.stop();
                          }
                          Navigator.of(dialogContext).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Divider(color: theme.appColors.base3, height: 16),

                  // Completed task preview
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.appColors.bgAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.appColors.base3),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            completedTodo.task,
                            style: TextStyle(
                              color: theme.appColors.fg,
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Prank message s MARKDOWN renderingem - Scrollable
                  Flexible(
                    child: Container(
                      width: double.infinity, // ✅ Zaplnit celou šířku
                      decoration: BoxDecoration(
                        color: theme.appColors.bgAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.appColors.base3.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.all(8), // ✅ Padding uvnitř
                      child: Markdown(
                        controller: scrollController,
                        data: prankMessage, // Markdown text z AI
                        selectable: true, // Umožnit výběr textu
                        shrinkWrap: true,
                        softLineBreak: true, // ✅ Zalomit dlouhé řádky
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
                            color: accentColor,
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
                            color: accentColor,
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
                          if (isSpeaking) {
                            await ttsService.stop();
                            setState(() {
                              isSpeaking = false;
                            });
                          } else {
                            // speak() automaticky čistí markdown (zachovává emoji!)
                            await ttsService.speak(prankMessage);
                            setState(() {
                              isSpeaking = true;
                            });
                          }
                        },
                        icon: Icon(
                          isSpeaking ? Icons.stop : Icons.volume_up,
                          color: accentColor,
                          size: 24,
                        ),
                        tooltip: isSpeaking ? 'Zastavit' : 'Číst nahlas',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      // Copy to clipboard button
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: prankMessage));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('✅ Text zkopírován do schránky'),
                                backgroundColor: accentColor,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.copy,
                            color: theme.appColors.cyan, size: 18),
                        label: Text(
                          'Kopírovat',
                          style: TextStyle(
                              color: theme.appColors.cyan, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.appColors.cyan),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      ElevatedButton(
                        onPressed: () {
                          if (isSpeaking) {
                            ttsService.stop();
                          }
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: theme.appColors.bg,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Zavřít',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
      },
    );
  }
}
