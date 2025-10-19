import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/sound_manager.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../utils/color_utils.dart';
import '../../../../services/tag_service.dart';
import '../../../../features/ai_motivation/presentation/cubit/motivation_cubit.dart';
import '../../../../features/ai_split/presentation/cubit/ai_split_cubit.dart';
import '../../../../features/ai_split/data/models/subtask_model.dart';
import '../../../../features/pomodoro/domain/entities/pomodoro_session.dart';
import '../../../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../../../features/ai_prank/presentation/cubit/prank_cubit.dart';
import '../../../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../../../features/profile/presentation/bloc/profile_state.dart';
import '../../../../features/profile/presentation/bloc/profile_event.dart';
import '../../../../features/profile/domain/entities/age_category.dart';
import '../../../../core/connectivity/cubit/connectivity_cubit.dart';
import '../../../../services/tag_parser.dart';
import '../../domain/entities/todo.dart';
import '../../domain/services/recurrence_generator.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';
import 'todo_tag_chip.dart';
import 'recurrence_confirmation_dialog.dart';
import 'dialogs/motivation_dialog.dart';
import 'dialogs/pomodoro_quickstart_dialog.dart';
import 'dialogs/edit_todo_dialog.dart';
import 'dialogs/share_todo_handler.dart';

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
      // Swipe doleva = AI Motivace
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.appColors.magenta,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'MOTIVACE ✨',
              style: TextStyle(
                color: theme.appColors.bg,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.auto_awesome,
              color: theme.appColors.bg,
              size: 32,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Zavřít klávesnici při jakékoli swipe akci
        FocusScope.of(context).unfocus();

        AppLogger.debug('🔄 TODO CARD SWIPE: direction=$direction, todo=[${todo.id}] ${todo.task}');

        if (direction == DismissDirection.startToEnd) {
          // Swipe doprava = toggle hotovo/nehotovo
          AppLogger.debug('➡️ SWIPE DOPRAVA: isCompleted=${todo.isCompleted}, hasRecurrence=${todo.hasRecurrence}');

          // ✅ Check: je to recurring úkol? (pouze pokud se dokončuje)
          if (!todo.isCompleted && todo.hasRecurrence) {
            // RECURRING TODO → show dialog
            final nextDate = RecurrenceGenerator.calculateNextDate(
              rule: todo.recurrenceRule!,
              currentDate: todo.dueDate ?? DateTime.now(),
            );

            if (nextDate == null) {
              // Chyba při výpočtu → fallback normal complete
              context.read<TodoListBloc>().add(
                    ToggleTodoEvent(
                      id: todo.id!,
                      isCompleted: true,
                    ),
                  );

              // 📊 Inkrementovat completed tasks count (pro střídání prank/good deed)
              context.read<ProfileBloc>().add(const IncrementCompletedTasksEvent());

              // 🎉 Trigger AI Prank/Good Deed pokud je uživatel dítě
              _triggerPrankIfChild(context);

              return false;
            }

            // Zobrazit dialog
            AppLogger.debug('📋 Zobrazuji RecurrenceConfirmationDialog...');
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => RecurrenceConfirmationDialog(
                nextDate: nextDate,
              ),
            );

            AppLogger.debug('📋 Dialog zavřen: shouldContinue=$shouldContinue');

            if (shouldContinue == true) {
              AppLogger.debug('✅ User zvolil: POKRAČOVAT');

              // 🎉 Trigger AI Prank/Good Deed PŘED inkrementací (potřebujeme aktuální count)
              AppLogger.debug('🎉 VOLÁM _triggerPrankIfChild() po POKRAČOVAT (PŘED inkrementací)...');
              _triggerPrankIfChild(context);

              // Pokračovat → posunout termín
              context.read<TodoListBloc>().add(
                    ContinueRecurrenceEvent(todo.id!, nextDate),
                  );

              // 📊 Inkrementovat completed tasks count (pro střídání prank/good deed)
              context.read<ProfileBloc>().add(const IncrementCompletedTasksEvent());
            } else if (shouldContinue == false) {
              AppLogger.debug('🛑 User zvolil: UKONČIT');

              // 🎉 Trigger AI Prank/Good Deed PŘED inkrementací (potřebujeme aktuální count)
              AppLogger.debug('🎉 VOLÁM _triggerPrankIfChild() po UKONČIT (PŘED inkrementací)...');
              _triggerPrankIfChild(context);

              // Ukončit → smazat rule + complete
              context.read<TodoListBloc>().add(
                    EndRecurrenceEvent(todo.id!),
                  );

              // 📊 Inkrementovat completed tasks count (pro střídání prank/good deed)
              context.read<ProfileBloc>().add(const IncrementCompletedTasksEvent());
            } else {
              AppLogger.debug('❌ User zavřel dialog (shouldContinue=null)');
            }
            // null = dialog dismissed → nic nedělat

            return false; // Neodstranit widget
          } else {
            // Běžný TODO nebo vrátit hotový → normální toggle
            final isCompletingNow = !todo.isCompleted; // true pokud právě dokončujeme

            AppLogger.debug('📝 BĚŽNÝ TODO: isCompletingNow=$isCompletingNow');

            context.read<TodoListBloc>().add(
                  ToggleTodoEvent(
                    id: todo.id!,
                    isCompleted: isCompletingNow,
                  ),
                );

            // 📊 Inkrementovat completed tasks count (pouze pokud dokončujeme)
            if (isCompletingNow) {
              AppLogger.debug('📊 Inkrementuji completed tasks count...');
              context.read<ProfileBloc>().add(const IncrementCompletedTasksEvent());
            }

            // 🎉 Trigger AI Prank/Good Deed pokud je uživatel dítě
            if (isCompletingNow) {
              AppLogger.debug('🎉 VOLÁM _triggerPrankIfChild()...');
              _triggerPrankIfChild(context);
            }

            return false; // Neodstranit widget
          }
        } else {
          // Swipe doleva = AI Motivace
          await _motivateTask(context);
          return false; // Neodstranit widget
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
          EditTodoDialog.show(
            context,
            todo: todo,
            onShare: () => ShareTodoHandler.share(context, todo: todo),
          );
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
                        // Priorita (s uživatelskou barvou z TagService)
                        if (todo.priority != null) ...[
                          () {
                            final priorityDef = TagService().getDefinition(todo.priority!);
                            return TodoTagChip(
                              text:
                                  '${TagParser.getPriorityIcon(todo.priority)} ${todo.priority!.toUpperCase()}',
                              color: priorityDef?.color != null
                                  ? ColorUtils.hexToColor(priorityDef!.color!)
                                  : _getPriorityColorFallback(context),
                              glowEnabled: priorityDef?.glowEnabled ?? false,
                              glowStrength: priorityDef?.glowStrength ?? 0.5,
                            );
                          }(),
                        ],

                        // Datum (s uživatelskou barvou z TagService)
                        if (todo.dueDate != null) ...[
                          () {
                            final dateText = TagParser.formatDate(todo.dueDate!);
                            // Extrahovat jen date část (bez času) pro TagService lookup
                            // Např: "dnes 13:00" → "dnes", "zítra 9:30" → "zítra"
                            final datePart = dateText.split(' ').first;
                            final dateDef = TagService().getDefinition(datePart);
                            return TodoTagChip(
                              text: '📅 $dateText',
                              color: dateDef?.color != null
                                  ? ColorUtils.hexToColor(dateDef!.color!)
                                  : theme.appColors.blue,
                              glowEnabled: dateDef?.glowEnabled ?? false,
                              glowStrength: dateDef?.glowStrength ?? 0.5,
                            );
                          }(),
                        ],

                        // 🔁 Ikona + frekvence (pokud má recurrence)
                        if (todo.hasRecurrence) ...[
                          TodoTagChip(
                            text: '🔁 ${RecurrenceGenerator.formatRecurrenceFrequency(todo.recurrenceRule!)}',
                            color: theme.appColors.magenta,
                          ),
                        ],

                        // Subtasks počítadlo
                        if (todo.subtasks != null && todo.subtasks!.isNotEmpty)
                          TodoTagChip(
                            text: '🤖 ${todo.subtasks!.where((s) => s.completed).length}/${todo.subtasks!.length}',
                            color: theme.appColors.cyan,
                          ),

                        // Obecné tagy (s uživatelskými barvami z TagService)
                        ...todo.tags.map((tag) {
                          final tagDef = TagService().getDefinition(tag);
                          return TodoTagChip(
                            text: tag,
                            color: tagDef?.color != null
                                ? ColorUtils.hexToColor(tagDef!.color!)
                                : theme.appColors.cyan,
                            glowEnabled: tagDef?.glowEnabled ?? false,
                            glowStrength: tagDef?.glowStrength ?? 0.5,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // Tlačítko pro rozšiřující funkce (AI Chat, Pomodoro, Motivace)
              _buildActionsMenuButton(context),
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

  /// Vytvořit rozbalovací menu s akcemi (AI Chat, Pomodoro, Motivace)
  Widget _buildActionsMenuButton(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.auto_awesome,
        color: theme.appColors.magenta,
        size: 20,
      ),
      tooltip: '', // Vypnuto kvůli multiple tickers error při rebuildu
      color: theme.appColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.appColors.magenta, width: 1),
      ),
      itemBuilder: (context) => [
        // AI Chat
        PopupMenuItem<String>(
          value: 'ai_chat',
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                'Chat s AI',
                style: TextStyle(color: theme.appColors.fg),
              ),
            ],
          ),
        ),
        // Pomodoro
        PopupMenuItem<String>(
          value: 'pomodoro',
          child: Row(
            children: [
              const Text('🍅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                'Spustit Pomodoro',
                style: TextStyle(color: theme.appColors.fg),
              ),
            ],
          ),
        ),
        // Motivace
        PopupMenuItem<String>(
          value: 'motivation',
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                'AI Motivace',
                style: TextStyle(color: theme.appColors.fg),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'ai_chat':
            _openAiChat(context);
            break;
          case 'pomodoro':
            PomodoroQuickStartDialog.show(context, todo: todo);
            break;
          case 'motivation':
            _motivateTask(context);
            break;
        }
      },
    );
  }

  /// Získat fallback barvu pro prioritu (pokud není definice v TagService)
  Color _getPriorityColorFallback(BuildContext context) {
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



  /// Získat AI motivaci pro úkol (s cache kontrolou)
  Future<void> _motivateTask(BuildContext context) async {
    AppLogger.debug('🚀 _motivateTask START pro úkol: ${todo.task}');

    // Zavřít klávesnici (pokud je otevřená)
    FocusScope.of(context).unfocus();

    // Zkontrolovat zda existuje cached motivace
    if (todo.aiMotivation != null && todo.aiMotivation!.isNotEmpty) {
      // Motivace existuje → OKAMŽITĚ zobrazit (BEZ loading)
      AppLogger.debug('💾 Zobrazuji CACHED motivaci');
      MotivationDialog.show(
        context,
        todo: todo,
        motivation: todo.aiMotivation!,
        isCached: true,
        onRegenerate: () => _generateAndShowMotivation(context),
      );
    } else {
      // Žádná motivace → vygenerovat NOVOU
      AppLogger.debug('🆕 Generuji NOVOU motivaci');
      await _generateAndShowMotivation(context);
    }
  }

  /// Vygenerovat NOVOU motivaci + uložit do DB
  Future<void> _generateAndShowMotivation(BuildContext context) async {
    final theme = Theme.of(context);
    final soundManager = SoundManager();

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
      // Zavolat API
      final motivation = await context.read<MotivationCubit>().fetchMotivation(
        taskText: todo.task,
        priority: todo.priority,
        tags: todo.tags,
      );
      AppLogger.debug(
          '✅ AI odpověď obdržena: ${motivation.substring(0, motivation.length > 50 ? 50 : motivation.length)}...');

      // Uložit do databáze
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Unix timestamp (seconds)
      final updatedTodo = todo.copyWith(
        aiMotivation: motivation,
        aiMotivationGeneratedAt: now,
      );

      if (context.mounted) {
        context.read<TodoListBloc>().add(UpdateTodoEvent(updatedTodo));
      }

      // Zastavit zvuk
      AppLogger.debug('⏹️ Zastavuji typing_long zvuk');
      await soundManager.stop();

      // Zavřít loading dialog
      AppLogger.debug('❌ Zavírám loading dialog');
      if (context.mounted) Navigator.of(context).pop();

      // Zobrazit motivaci s updatedTodo (obsahuje novou motivaci)
      AppLogger.debug('📝 Zobrazuji motivační dialog');
      if (context.mounted) {
        MotivationDialog.show(
          context,
          todo: updatedTodo, // ✅ Použít updatedTodo s novou motivací
          motivation: motivation,
          isCached: false,
          onRegenerate: () => _generateAndShowMotivation(context),
        );
      }
      AppLogger.debug('✅ _generateAndShowMotivation KONEC (úspěch)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ EXCEPTION v _generateAndShowMotivation', error: e, stackTrace: stackTrace);

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
      AppLogger.debug('✅ _generateAndShowMotivation KONEC (chyba)');
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




  /// Otevřít AI Chat
  Future<void> _openAiChat(BuildContext context) async {
    // Zavřít klávesnici
    FocusScope.of(context).unfocus();

    // Načíst subtasks
    final subtasks = await _loadSubtasks(todo.id!);

    // Načíst pomodoro sessions
    final sessions = await _loadPomodoroSessions(todo.id!);

    // Otevřít AI Chat page s task kontextem
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiChatPage.withTask(
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

  /// Trigger AI Prank/Good Deed pokud je uživatel v kategorii "child"
  ///
  /// Střídání: lichý count = prank, sudý count = good deed
  ///
  /// ✅ Kontroluje připojení k internetu před voláním AI
  void _triggerPrankIfChild(BuildContext context) {
    AppLogger.debug('═══════════════════════════════════════════');
    AppLogger.debug('🚀 _triggerPrankIfChild START (todo: ${todo.task})');
    AppLogger.debug('═══════════════════════════════════════════');

    final theme = Theme.of(context);

    // 🌐 KROK 1: Kontrola připojení k internetu (DOČASNĚ VYPNUTO - false positives na Android)
    // TODO: Opravit ConnectivityCubit pro Android emulátor
    final connectivityCubit = context.read<ConnectivityCubit>();
    AppLogger.debug('📶 Connectivity check: isConnected=${connectivityCubit.isConnected}, type=${connectivityCubit.connectionType}');

    // POZN: ConnectivityCubit má problémy na Android emulátoru (false positives)
    // → Spoléháme se na to, že API call sám selže pokud není internet
    // → Lepší UX: user uvidí konkrétní API error místo generické "no internet" zprávy

    /* VYPNUTO - false positives na Android
    if (!connectivityCubit.isConnected) {
      AppLogger.debug('❌ Žádné připojení k internetu → prank/good deed přeskočen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📡 Pro tipy od AI potřebuješ připojení k internetu'),
          backgroundColor: theme.appColors.yellow,
          duration: const Duration(seconds: 3),
        ),
      );
      AppLogger.debug('🏁 _triggerPrankIfChild KONEC (důvod: no internet)');
      return;
    }
    */

    AppLogger.debug('✅ Přeskakuji connectivity check (Android emulátor workaround) → pokračuji');

    // 👤 KROK 2: Získat profil uživatele
    final profileBloc = context.read<ProfileBloc>();
    final profileState = profileBloc.state;
    AppLogger.debug('👤 ProfileBloc state: ${profileState.runtimeType}');

    if (profileState is! ProfileLoaded) {
      AppLogger.debug('⚠️ ProfileBloc není ProfileLoaded → prank/good deed přeskočen');
      AppLogger.debug('🏁 _triggerPrankIfChild KONEC (důvod: profile not loaded)');
      return;
    }

    final userProfile = profileState.userProfile;
    AppLogger.debug('📊 User profile: ${userProfile != null ? "EXISTS" : "NULL"}');

    if (userProfile == null) {
      AppLogger.debug('⚠️ User profile je null → prank/good deed přeskočen');
      AppLogger.debug('🏁 _triggerPrankIfChild KONEC (důvod: profile is null)');
      return;
    }

    final ageCategory = userProfile.ageCategory;
    final age = userProfile.age;
    final count = userProfile.completedTasksCount;

    AppLogger.debug('════════════════════════');
    AppLogger.debug('📋 USER PROFILE INFO:');
    AppLogger.debug('  Name: ${userProfile.firstName} ${userProfile.lastName}');
    AppLogger.debug('  Age: $age');
    AppLogger.debug('  Age Category: ${ageCategory.name} (${ageCategory.czechName}) ${ageCategory.emoji}');
    AppLogger.debug('  Completed Tasks Count: $count');
    AppLogger.debug('════════════════════════');

    // 🎯 KROK 3: Kontrola: pouze pro děti (6-11 let podle fromAge v AgeCategory)
    if (ageCategory != AgeCategory.child) {
      AppLogger.debug('ℹ️ Uživatel NENÍ dítě (category: ${ageCategory.name}) → prank/good deed přeskočen');
      AppLogger.debug('🏁 _triggerPrankIfChild KONEC (důvod: not a child)');
      return;
    }

    AppLogger.debug('✅ Uživatel JE dítě → pokračuji s generováním prank/good deed');

    final isOdd = count % 2 == 1; // Lichý = prank, sudý = good deed
    final type = isOdd ? 'PRANK' : 'GOOD DEED';

    AppLogger.debug('🎲 Count=$count → isOdd=$isOdd → TYPE=$type');

    try {
      if (isOdd) {
        AppLogger.debug('🎭 Volám PrankCubit.generatePrank()...');
        context.read<PrankCubit>().generatePrank(todo);
        AppLogger.debug('✅ PrankCubit.generatePrank() zavoláno');
      } else {
        AppLogger.debug('💚 Volám PrankCubit.generateGoodDeed()...');
        context.read<PrankCubit>().generateGoodDeed(todo);
        AppLogger.debug('✅ PrankCubit.generateGoodDeed() zavoláno');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ EXCEPTION při volání PrankCubit', error: e, stackTrace: stackTrace);
    }

    AppLogger.debug('🏁 _triggerPrankIfChild KONEC (SUCCESS)');
    AppLogger.debug('═══════════════════════════════════════════');
  }
}
