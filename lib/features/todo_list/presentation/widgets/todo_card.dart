import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../features/ai_motivation/presentation/cubit/motivation_cubit.dart';
import '../../../../features/ai_split/presentation/widgets/ai_split_button.dart';
import '../../../../features/ai_split/presentation/cubit/ai_split_cubit.dart';
import '../../../../features/ai_split/data/models/subtask_model.dart';
import '../../../../features/pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../../features/pomodoro/domain/entities/pomodoro_session.dart';
import '../../../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../../../services/tag_parser.dart';
import '../../../../widgets/typewriter_text.dart';
import '../../../../widgets/highlighted_text_field.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import 'todo_tag_chip.dart';

/// TodoCard - Karta s TODO úkolem
///
/// Features:
/// - Swipe doprava = toggle hotovo/nehotovo
/// - Swipe doleva = smazat
/// - Tap = expand/collapse
/// - Long press = edit
/// - Motivate button = AI motivace
class TodoCard extends StatelessWidget {
  final Todo todo;
  final bool isExpanded;

  const TodoCard({
    super.key,
    required this.todo,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('todo_${todo.id}'),
      // Swipe doprava = toggle hotovo/nehotovo
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: todo.isCompleted
              ? theme.appColors.yellow
              : theme.appColors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Icon(
              todo.isCompleted ? Icons.refresh : Icons.check_circle,
              color: theme.appColors.bg,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              todo.isCompleted ? 'VRÁTIT' : 'HOTOVO',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Swipe doleva = smazat
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'SMAZAT',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.delete_forever,
              color: theme.appColors.bg,
              size: 32,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Zavřít klávesnici při jakékoli swipe akci
        FocusScope.of(context).unfocus();

        if (direction == DismissDirection.startToEnd) {
          // Swipe doprava = toggle hotovo/nehotovo
          context.read<TodoListBloc>().add(
                ToggleTodoEvent(
                  id: todo.id!,
                  isCompleted: !todo.isCompleted,
                ),
              );
          return false; // Neodstranit widget
        } else {
          // Swipe doleva = smazat (bez potvrzení)
          return true; // Odstranit widget
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Smazat úkol
          context.read<TodoListBloc>().add(DeleteTodoEvent(todo.id!));
        }
      },
      child: InkWell(
        onTap: () {
          // Zavřít klávesnici při expand/collapse
          FocusScope.of(context).unfocus();

          context
              .read<TodoListBloc>()
              .add(ToggleExpandTodoEvent(isExpanded ? null : todo.id));
        },
        onLongPress: () {
          // Zavřít klávesnici při otevření edit dialogu
          FocusScope.of(context).unfocus();
          _editTodoItem(context);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getTodoBorderColor(context),
              width: 1, // Subtilní border (clean minimal)
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Obsah (ID + text + metadata)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // První řádek: ID + text úkolu
                    Row(
                      children: [
                        // ID
                        Text(
                          '[${todo.id}]',
                          style: TextStyle(
                            color: theme.appColors.base5,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Text úkolu (oříznutý nebo plný)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todo.task,
                                maxLines: isExpanded ? null : 1,
                                overflow:
                                    isExpanded ? null : TextOverflow.ellipsis,
                                style: TextStyle(
                                  decoration: todo.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: todo.isCompleted
                                      ? theme.appColors.base5
                                      : theme.appColors.fg,
                                  fontSize: 16,
                                ),
                              ),

                              // Rozšířené info: Subtasks + AI metadata (pouze pokud expanded)
                              if (isExpanded) ...[
                                const SizedBox(height: 12),
                                _buildExpandedDetails(context, theme),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Druhý řádek: Metadata (priorita, datum, akce, tagy, subtasks)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Priorita
                        if (todo.priority != null)
                          TodoTagChip(
                            text:
                                '${TagParser.getPriorityIcon(todo.priority)} ${todo.priority!.toUpperCase()}',
                            color: _getPriorityColor(context),
                          ),

                        // Datum
                        if (todo.dueDate != null)
                          TodoTagChip(
                            text: '📅 ${TagParser.formatDate(todo.dueDate!)}',
                            color: theme.appColors.blue,
                          ),

                        // Subtasks počítadlo
                        if (todo.subtasks != null && todo.subtasks!.isNotEmpty)
                          TodoTagChip(
                            text: '🤖 ${todo.subtasks!.where((s) => s.completed).length}/${todo.subtasks!.length}',
                            color: theme.appColors.cyan,
                          ),

                        // Obecné tagy
                        ...todo.tags.map((tag) => TodoTagChip(
                              text: tag,
                              color: theme.appColors.cyan,
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              // Tlačítka (Pomodoro + Motivate + AI Chat v jednom řádku)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPomodoroButton(context),
                  const SizedBox(width: 4),
                  _buildMotivateButton(context),
                  const SizedBox(width: 4),
                  _buildAiChatButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Získat barvu rámečku úkolu podle stavu (Doom One styl: clean + elegant)
  Color _getTodoBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    if (todo.isCompleted) {
      // Splněné úkoly = krásná moderní zelená (celebrate the win!)
      return theme.appColors.green;
    } else {
      // Aktivní úkoly = pěkná decentní cyan/modrá (Doom One styl)
      return theme.appColors.cyan.withValues(alpha: 0.4);
    }
  }

  /// Získat barvu pro prioritu
  Color _getPriorityColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (todo.priority) {
      case 'a':
        return theme.appColors.red;
      case 'b':
        return theme.appColors.yellow;
      case 'c':
        return theme.appColors.green;
      default:
        return theme.appColors.base5;
    }
  }

  /// Editovat úkol
  Future<void> _editTodoItem(BuildContext context) async {
    final theme = Theme.of(context);

    // Rekonstruovat text s tagy pro editaci (async)
    final textWithTags = await TagParser.reconstructWithTags(
      cleanText: todo.task,
      priority: todo.priority,
      dueDate: todo.dueDate,
      tags: todo.tags,
    );

    final controller = TextEditingController(text: textWithTags);

    if (!context.mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.yellow, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.edit, color: theme.appColors.yellow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'EDITOVAT ÚKOL',
                      style: TextStyle(
                        color: theme.appColors.yellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Share button
                  IconButton(
                    icon: Icon(Icons.share, color: theme.appColors.cyan, size: 24),
                    tooltip: 'Sdílet úkol',
                    onPressed: () => _shareTodo(context),
                  ),
                  // AI Split button
                  AiSplitButton(todo: todo),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.appColors.base5),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              Divider(color: theme.appColors.base3, height: 24),

              // HighlightedTextField pro text úkolu (s obarvením tagů)
              Text(
                'Text úkolu:',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              HighlightedTextField(
                controller: controller,
                hintText: '*a* *dnes* *udelat* nakoupit, *rodina*',
              ),
              const SizedBox(height: 24),

              // Tlačítka
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text('Zrušit',
                        style: TextStyle(color: theme.appColors.base5)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        Navigator.of(dialogContext).pop(controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.appColors.yellow,
                      foregroundColor: theme.appColors.bg,
                    ),
                    child: const Text('Uložit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Pokud byl text změněn, uložit do databáze
    if (result != null && result != todo.task && context.mounted) {
      // Parsovat tagy z nového textu (async)
      final parsed = await TagParser.parse(result);

      // Vytvořit aktualizovaný Todo
      final updatedTodo = todo.copyWith(
        task: parsed.cleanText,
        priority: parsed.priority,
        dueDate: parsed.dueDate,
        tags: parsed.tags,
      );

      if (context.mounted) {
        context.read<TodoListBloc>().add(UpdateTodoEvent(updatedTodo));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Úkol byl aktualizován'),
            backgroundColor: theme.appColors.green,
          ),
        );
      }
    }
  }

  /// Vytvořit motivate tlačítko s moderním emoji (clean, bez glow)
  Widget _buildMotivateButton(BuildContext context) {
    return IconButton(
      icon: const Text(
        '✨',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      onPressed: () => _motivateTask(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'AI Motivace',
    );
  }

  /// Vytvořit Pomodoro tlačítko (rajčete emoji)
  Widget _buildPomodoroButton(BuildContext context) {
    return IconButton(
      icon: const Text(
        '🍅',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      onPressed: () => _showPomodoroQuickStart(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Spustit Pomodoro',
    );
  }

  /// Vytvořit AI Chat tlačítko
  Widget _buildAiChatButton(BuildContext context) {
    return IconButton(
      icon: const Text(
        '🤖',
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      onPressed: () => _openAiChat(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Chat s AI',
    );
  }

  /// Získat AI motivaci pro úkol
  Future<void> _motivateTask(BuildContext context) async {
    final theme = Theme.of(context);

    AppLogger.debug('🚀 _motivateTask START pro úkol: ${todo.task}');

    // Zavřít klávesnici (pokud je otevřená)
    FocusScope.of(context).unfocus();

    final soundManager = SoundManager();

    // Spustit typing_long zvuk
    AppLogger.debug('🔊 Spouštím typing_long zvuk');
    await soundManager.playTypingLong();

    // Zobrazit loading dialog
    AppLogger.debug('⏳ Zobrazuji loading dialog');
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: theme.appColors.magenta,
        ),
      ),
    );

    try {
      AppLogger.debug('🤖 Volám MotivationCubit.fetchMotivation...');
      // Zavolat AI Cubit
      final motivation = await context.read<MotivationCubit>().fetchMotivation(
        taskText: todo.task,
        priority: todo.priority,
        tags: todo.tags,
      );
      AppLogger.debug(
          '✅ AI odpověď obdržena: ${motivation.substring(0, motivation.length > 50 ? 50 : motivation.length)}...');

      // Přepnout na subtle typing zvuk
      AppLogger.debug('🔊 Přepínám na subtle typing zvuk');
      await soundManager.playSubtleTyping();

      // Zavřít loading dialog
      AppLogger.debug('❌ Zavírám loading dialog');
      if (context.mounted) Navigator.of(context).pop();

      // Zobrazit motivaci v dialogu s typewriter efektem
      AppLogger.debug('📝 Zobrazuji motivační dialog');
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => _buildMotivationDialog(context, motivation),
        );

        // Po zavření dialogu zastavit zvuk
        AppLogger.debug('⏹️ Zastavuji zvuk po zavření dialogu');
        await soundManager.stop();
      }
      AppLogger.debug('✅ _motivateTask KONEC (úspěch)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ EXCEPTION v _motivateTask', error: e, stackTrace: stackTrace);

      // Zastavit zvuk při chybě
      await soundManager.stop();

      // Zavřít loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Zobrazit error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při získávání motivace: $e'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
      AppLogger.debug('✅ _motivateTask KONEC (chyba)');
    }
  }

  /// Rozšířené detaily: Subtasks + AI metadata
  Widget _buildExpandedDetails(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtasks
        if (todo.subtasks != null && todo.subtasks!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.appColors.base1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.cyan, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 PODÚKOLY:',
                  style: TextStyle(
                    color: theme.appColors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...todo.subtasks!.map((subtask) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Dismissible(
                      key: Key('subtask_${subtask.id}'),
                      // Swipe doprava = toggle hotovo/nehotovo
                      background: Container(
                        decoration: BoxDecoration(
                          color: subtask.completed
                              ? theme.appColors.yellow
                              : theme.appColors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(
                          subtask.completed ? Icons.refresh : Icons.check,
                          color: theme.appColors.bg,
                          size: 20,
                        ),
                      ),
                      // Swipe doleva = smazat
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: theme.appColors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.delete,
                          color: theme.appColors.bg,
                          size: 20,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe doprava = toggle
                          await context
                              .read<AiSplitCubit>()
                              .toggleSubtask(subtask.id!, !subtask.completed);
                          // Reload todo list
                          if (context.mounted) {
                            context
                                .read<TodoListBloc>()
                                .add(const LoadTodosEvent());
                          }
                          return false; // Neodstranit widget
                        } else {
                          // Swipe doleva = smazat
                          return true; // Odstranit widget
                        }
                      },
                      onDismissed: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Smazat subtask
                          await context
                              .read<AiSplitCubit>()
                              .deleteSubtask(subtask.id!);
                          // Reload todo list
                          if (context.mounted) {
                            context
                                .read<TodoListBloc>()
                                .add(const LoadTodosEvent());
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: subtask.completed,
                            onChanged: (value) async {
                              // Toggle subtask completed
                              await context
                                  .read<AiSplitCubit>()
                                  .toggleSubtask(subtask.id!, value!);
                              // Reload todo list pro zobrazení změn
                              if (context.mounted) {
                                context
                                    .read<TodoListBloc>()
                                    .add(const LoadTodosEvent());
                              }
                            },
                            activeColor: theme.appColors.green,
                          ),
                          Expanded(
                            child: Text(
                              '${subtask.subtaskNumber}. ${subtask.text}',
                              style: TextStyle(
                                color: subtask.completed
                                    ? theme.appColors.base5
                                    : theme.appColors.fg,
                                decoration: subtask.completed
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // AI Doporučení
        if (todo.aiRecommendations != null &&
            todo.aiRecommendations!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.appColors.base1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.yellow, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 DOPORUČENÍ:',
                  style: TextStyle(
                    color: theme.appColors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  todo.aiRecommendations!,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // AI Analýza termínu
        if (todo.aiDeadlineAnalysis != null &&
            todo.aiDeadlineAnalysis!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.appColors.base1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.appColors.magenta, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏰ TERMÍN:',
                  style: TextStyle(
                    color: theme.appColors.magenta,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  todo.aiDeadlineAnalysis!,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Sdílet úkol do schránky (kompletní obsah včetně subtasks + AI metadata)
  Future<void> _shareTodo(BuildContext context) async {
    final theme = Theme.of(context);

    try {
      // Sestavit Markdown formátovaný text
      final buffer = StringBuffer();

      // Header
      buffer.writeln('# TODO: ${todo.task}');
      buffer.writeln();

      // Metadata
      buffer.writeln('## 📋 Základní info');
      buffer.writeln('- **ID**: ${todo.id}');
      buffer.writeln('- **Status**: ${todo.isCompleted ? "✅ Hotovo" : "⭕ Aktivní"}');
      if (todo.priority != null) {
        buffer.writeln('- **Priorita**: ${TagParser.getPriorityIcon(todo.priority)} ${todo.priority!.toUpperCase()}');
      }
      if (todo.dueDate != null) {
        buffer.writeln('- **Deadline**: 📅 ${TagParser.formatDate(todo.dueDate!)}');
      }
      if (todo.tags.isNotEmpty) {
        buffer.writeln('- **Tagy**: ${todo.tags.map((t) => '*$t*').join(', ')}');
      }
      buffer.writeln('- **Vytvořeno**: ${todo.createdAt.toLocal()}');
      buffer.writeln();

      // Subtasks
      if (todo.subtasks != null && todo.subtasks!.isNotEmpty) {
        buffer.writeln('## 📋 Podúkoly (${todo.subtasks!.where((s) => s.completed).length}/${todo.subtasks!.length})');
        for (final subtask in todo.subtasks!) {
          final checkbox = subtask.completed ? '✅' : '⬜';
          buffer.writeln('$checkbox ${subtask.subtaskNumber}. ${subtask.text}');
        }
        buffer.writeln();
      }

      // AI Doporučení
      if (todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty) {
        buffer.writeln('## 💡 AI Doporučení');
        buffer.writeln(todo.aiRecommendations);
        buffer.writeln();
      }

      // AI Analýza termínu
      if (todo.aiDeadlineAnalysis != null && todo.aiDeadlineAnalysis!.isNotEmpty) {
        buffer.writeln('## ⏰ AI Analýza termínu');
        buffer.writeln(todo.aiDeadlineAnalysis);
        buffer.writeln();
      }

      // Footer
      buffer.writeln('---');
      buffer.writeln('📱 Exportováno z TODO App');

      final shareText = buffer.toString();

      // Zkopírovat do schránky
      await Clipboard.setData(ClipboardData(text: shareText));

      // Zobrazit úspěšnou notifikaci
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Úkol zkopírován do schránky (Markdown formát)'),
            backgroundColor: theme.appColors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: theme.appColors.bg,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Error handling
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Chyba při kopírování: $e'),
            backgroundColor: theme.appColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Zobrazit Quick Start dialog pro Pomodoro
  Future<void> _showPomodoroQuickStart(BuildContext context) async {
    final theme = Theme.of(context);

    // Zavřít klávesnici
    FocusScope.of(context).unfocus();

    int? selectedMinutes; // null = vlastní hodnota
    final customController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: theme.appColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange, width: 2),
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
                    const Icon(Icons.timer, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '🍅 SPUSTIT POMODORO',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                // Úkol preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.appColors.bgAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.appColors.base3),
                  ),
                  child: Text(
                    '📋 ${todo.task}',
                    style: TextStyle(
                      color: theme.appColors.fg,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Výběr délky
                Text(
                  'Délka Pomodoro:',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Rychlé volby (tlačítka)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 5, 15, 25, 30, 45, 60].map((minutes) {
                    final isSelected = selectedMinutes == minutes;
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedMinutes = minutes;
                          customController.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.orange.withValues(alpha: 0.2)
                            : null,
                        side: BorderSide(
                          color: isSelected ? Colors.orange : theme.appColors.base5,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: isSelected ? Colors.orange : theme.appColors.fg,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Vlastní zadání (TextField)
                Text(
                  'Nebo zadej vlastní:',
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: theme.appColors.fg, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Zadej minuty (1-180)',
                    hintStyle: TextStyle(color: theme.appColors.base5),
                    suffixText: 'min',
                    suffixStyle: TextStyle(color: theme.appColors.base5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.appColors.base3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    // Pokud user píše, zrušit vybranou rychlou volbu
                    if (value.isNotEmpty) {
                      setState(() {
                        selectedMinutes = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Zrušit',
                        style: TextStyle(color: theme.appColors.base5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Určit finální počet minut
                        int? finalMinutes;
                        if (selectedMinutes != null) {
                          finalMinutes = selectedMinutes;
                        } else if (customController.text.isNotEmpty) {
                          finalMinutes = int.tryParse(customController.text);
                        }

                        // Validace
                        if (finalMinutes == null || finalMinutes < 1 || finalMinutes > 180) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('⚠️ Zadej platný počet minut (1-180)'),
                              backgroundColor: theme.appColors.yellow,
                            ),
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop(finalMinutes);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('START'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: theme.appColors.bg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pokud user klikl START, přejít na Pomodoro Page (s vlastním AppBar + auto-start)
    if (result != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PomodoroPage(
            showAppBar: true,
            taskId: todo.id,
            duration: Duration(minutes: result),
          ),
        ),
      );
    }
  }

  /// Vytvořit dialog s AI motivací
  Widget _buildMotivationDialog(BuildContext context, String motivation) {
    final theme = Theme.of(context);
    final soundManager = SoundManager();
    final scrollController = ScrollController();

    return Dialog(
      backgroundColor: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.appColors.magenta, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Max 80% výšky obrazovky
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: theme.appColors.magenta, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI MOTIVACE',
                    style: TextStyle(
                      color: theme.appColors.magenta,
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

            // Task preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.bgAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.appColors.base3),
              ),
              child: Text(
                '📋 ${todo.task}',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Motivation text s typewriter efektem - Scrollable
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: TypewriterText(
                  text: motivation,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  duration: const Duration(milliseconds: 20),
                  scrollController: scrollController,
                  onComplete: () {
                    // Zastavit zvuk po dokončení typewriter efektu
                    AppLogger.debug('🎬 Typewriter dokončen - zastavuji zvuk');
                    soundManager.stop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Copy to clipboard button
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: motivation));
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
                  icon: Icon(Icons.copy, color: theme.appColors.cyan),
                  label: Text(
                    'Kopírovat',
                    style: TextStyle(color: theme.appColors.cyan),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.appColors.cyan),
                  ),
                ),
                // Close button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.appColors.magenta,
                    foregroundColor: theme.appColors.bg,
                  ),
                  child: const Text('Zavřít'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Otevřít AI Chat
  Future<void> _openAiChat(BuildContext context) async {
    // Zavřít klávesnici
    FocusScope.of(context).unfocus();

    // Načíst subtasks
    final subtasks = await _loadSubtasks(todo.id!);

    // Načíst pomodoro sessions
    final sessions = await _loadPomodoroSessions(todo.id!);

    // Otevřít AI Chat page
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiChatPage(
            todo: todo,
            subtasks: subtasks,
            pomodoroSessions: sessions,
          ),
        ),
      );
    }
  }

  /// Načíst subtasks z databáze
  Future<List<SubtaskModel>> _loadSubtasks(int todoId) async {
    final db = DatabaseHelper();
    final maps = await db.getSubtasksByTodoId(todoId);
    return maps.map((m) => SubtaskModel.fromMap(m)).toList();
  }

  /// Načíst pomodoro sessions z databáze
  Future<List<PomodoroSession>> _loadPomodoroSessions(int todoId) async {
    final db = DatabaseHelper();
    final maps = await db.getPomodoroSessionsByTodoId(todoId);
    return maps.map((m) => PomodoroSession.fromMap(m)).toList();
  }
}
