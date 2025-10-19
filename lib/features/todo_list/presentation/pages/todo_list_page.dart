import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/cubit/settings_state.dart';
import '../../domain/enums/view_mode.dart';
import '../../domain/enums/completion_filter.dart';
import '../bloc/todo_list_bloc.dart';
import '../bloc/todo_list_event.dart';
import '../bloc/todo_list_state.dart';
import '../widgets/todo_card.dart';
import '../widgets/input_bar.dart';
import '../widgets/view_bar.dart';
import '../widgets/sort_bar.dart';
import '../widgets/brief_section_widget.dart';
import '../widgets/brief_settings_sheet.dart';
import '../../../ai_prank/presentation/cubit/prank_cubit.dart';
import '../../../ai_prank/presentation/cubit/prank_state.dart';
import '../../../ai_prank/presentation/widgets/prank_celebration_screen.dart';
import '../../domain/entities/todo.dart';

/// TodoListPage - Hlavní stránka s TODO seznamem (Mobile-First redesign)
///
/// Layout (zdola nahoru):
/// - InputBar (bottom fixed) - Easy Thumb Zone
/// - ViewBar (kompaktní ikony) - Easy Thumb Zone (skrytý při psaní!)
/// - SortBar (kompaktní ikony) - Easy Thumb Zone (skrytý při psaní!)
/// - TODO List (scrollable) - Stretch Zone
/// - StatsRow (AppBar) - Hard Zone (ale jen info)
///
/// Keyboard awareness:
/// - ViewBar a SortBar se skryjí při focus na InputBar
/// - Šetří místo pro klávesnici a TODO list
///
/// Používá BLoC pattern pro state management.
/// UI je immutable a reaguje na změny state.
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Zobrazit gesture hint pro nové uživatele (po 2 sekundách)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGestureHintIfNeeded();
    });
  }

  /// Zobrazit gesture hint pokud uživatel ho ještě neviděl
  void _showGestureHintIfNeeded() {
    final settingsCubit = context.read<SettingsCubit>();
    final settingsState = settingsCubit.state;
    
    if (settingsState is SettingsLoaded && !settingsState.hasSeenGestureHint) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '💡 Long press = edit, Swipe = actions',
              style: TextStyle(fontSize: 14),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: theme.appColors.bgAlt,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 120, // Nad InputBar (aby nepřekrýval controls)
              left: 16,
              right: 16,
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: theme.appColors.cyan,
              onPressed: () {
                settingsCubit.markGestureHintSeen();
              },
            ),
          ),
        ).closed.then((_) {
          // Označit jako viděný i když byl automaticky dismissed (po 5 sekundách)
          final currentState = settingsCubit.state;
          if (currentState is SettingsLoaded && !currentState.hasSeenGestureHint) {
            settingsCubit.markGestureHintSeen();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TodoListPage už NENÍ Scaffold - je child widgetem MainPage PageView!
    // AppBar je v MainPage, zde pouze body content
    return BlocListener<PrankCubit, PrankState>(
      listener: (context, prankState) {
        AppLogger.debug('🎭 BlocListener prank state změněn: ${prankState.runtimeType}');

        // ⏳ Zobrazit loading dialog při generování
        if (prankState is PrankLoading) {
          AppLogger.debug('⏳ Prank se generuje...');
          _showPrankLoadingDialog(context);
        }
        // 🎉 Zobrazit fullscreen prank/good deed celebration když je vygenerován
        else if (prankState is PrankLoaded) {
          // Zavřít loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          final type = prankState.isPrank ? 'Prank' : 'Good Deed';
          AppLogger.debug('🎉 Zobrazuji ${type}CelebrationScreen');
          PrankCelebrationScreen.show(
            context,
            completedTodo: prankState.completedTodo,
            prankMessage: prankState.prankMessage,
            isPrank: prankState.isPrank,
          );

          // Reset PrankCubit po zobrazení
          AppLogger.debug('🔄 Resetuji PrankCubit');
          context.read<PrankCubit>().reset();
        }
        // ❌ Zobrazit error a zavřít loading dialog
        else if (prankState is PrankError) {
          // Zavřít loading dialog
          Navigator.of(context, rootNavigator: true).pop();

          AppLogger.error('❌ Prank error: ${prankState.errorMessage}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(prankState.errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocListener<SettingsCubit, SettingsState>(
        listener: (context, settingsState) {
          // Auto-switch na "All" když vypnu aktivní custom view
          if (settingsState is SettingsLoaded) {
            final todoState = context.read<TodoListBloc>().state;
            if (todoState is TodoListLoaded &&
                todoState.viewMode == ViewMode.custom &&
                todoState.currentCustomViewId != null) {
              // Zkontroluj jestli aktivní custom view je stále enabled
              final activeCustomView = settingsState.agendaConfig.customViews
                  .where((v) => v.id == todoState.currentCustomViewId)
                  .firstOrNull;

              if (activeCustomView == null || !activeCustomView.isEnabled) {
                // Custom view byl vypnut nebo smazán → přepni na "All"
                context.read<TodoListBloc>().add(const ChangeViewModeEvent(ViewMode.all));
              }
            }
          }
        },
        child: BlocConsumer<TodoListBloc, TodoListState>(
          listener: (context, state) {
            // Zobrazit error snackbar
            if (state is TodoListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.appColors.red,
                ),
              );
            }
          },
          builder: (context, state) {
          return Column(
            children: [
              // TODO List (scrollable) - Expanded = zabere zbytek místa
              Expanded(
                child: switch (state) {
                  TodoListInitial() => const Center(
                      child: Text('Inicializace...'),
                    ),
                  TodoListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  TodoListLoaded() => _buildTodoList(context, state),
                  TodoListError() => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: theme.appColors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Chyba při načítání úkolů',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.appColors.fg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.appColors.base5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context
                                  .read<TodoListBloc>()
                                  .add(const LoadTodosEvent());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Zkusit znovu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.appColors.yellow,
                              foregroundColor: theme.appColors.bg,
                            ),
                          ),
                        ],
                      ),
                    ),
                },
              ),

              // Bottom Controls (KEYBOARD AWARE!)
              // KRITICKÉ: BEZ SafeArea wrapperu! (SafeArea je uvnitř InputBaru)
              Container(
                // DŮLEŽITÉ: Padding podle keyboard inset!
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SortBar (skrytý při psaní s animací!)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _isInputFocused
                          ? const SizedBox.shrink()
                          : const SortBar(),
                    ),

                    // ViewBar (skrytý při psaní s animací!)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: _isInputFocused
                          ? const SizedBox.shrink()
                          : const ViewBar(),
                    ),

                    // InputBar (VŽDY viditelný, má vlastní SafeArea uvnitř)
                    InputBar(
                      onFocusChanged: (hasFocus) {
                        setState(() {
                          _isInputFocused = hasFocus;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  /// Sestavit seznam úkolů (Loaded state)
  Widget _buildTodoList(BuildContext context, TodoListLoaded state) {
    final theme = Theme.of(context);

    // Pokud viewMode == aiBrief → zobraz Brief view
    if (state.viewMode == ViewMode.aiBrief) {
      return _buildBriefView(context, state);
    }

    // Jinak → normální ListView
    final displayedTodos = state.displayedTodos;

    if (displayedTodos.isEmpty) {
      final emptyMessage = switch (state.completionFilter) {
        CompletionFilter.completed => 'Žádné hotové úkoly.',
        CompletionFilter.incomplete => 'Zatím žádné úkoly.\nPřidej první úkol!',
        CompletionFilter.all => 'Zatím žádné úkoly.',
      };

      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: theme.appColors.base5,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedTodos.length,
      itemBuilder: (context, index) {
        final todo = displayedTodos[index];
        return TodoCard(
          todo: todo,
          isExpanded: state.expandedTodoId == todo.id,
        );
      },
    );
  }

  /// Sestavit Brief view (AI prioritizované úkoly)
  Widget _buildBriefView(BuildContext context, TodoListLoaded state) {
    final theme = Theme.of(context);

    // Loading state
    if (state.isGeneratingBrief) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generuji AI Brief...',
              style: TextStyle(
                fontSize: 16,
                color: theme.appColors.fg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trvá 3-5 sekund',
              style: TextStyle(
                fontSize: 12,
                color: theme.appColors.base5,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (state.briefError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.appColors.red),
            const SizedBox(height: 16),
            Text(
              'Chyba při generování briefu',
              style: TextStyle(
                fontSize: 18,
                color: theme.appColors.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.briefError!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.appColors.base5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<TodoListBloc>().add(
                    const RegenerateBriefEvent(),
                  ),
              icon: const Icon(Icons.refresh),
              label: const Text('Zkusit znovu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.yellow,
                foregroundColor: theme.appColors.bg,
              ),
            ),
          ],
        ),
      );
    }

    // No data yet
    if (state.briefSections == null || state.briefSections!.isEmpty) {
      return Center(
        child: Text(
          'Načítám Brief...',
          style: TextStyle(
            fontSize: 16,
            color: theme.appColors.base5,
          ),
        ),
      );
    }

    // Brief sections s TodoCards + Header (gear + refresh)
    return Column(
      children: [
        // Header s gear + refresh tlačítky
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.appColors.bgAlt.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(
                color: theme.appColors.base3.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Brief title
              Icon(
                Icons.auto_awesome,
                color: theme.appColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Brief',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.appColors.fg,
                ),
              ),
              const Spacer(),

              // Settings icon
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const BriefSettingsSheet(),
                  );
                },
                icon: Icon(
                  Icons.settings,
                  color: theme.appColors.base5,
                  size: 20,
                ),
                tooltip: 'Nastavení Briefu',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),

              // Refresh icon
              IconButton(
                onPressed: () {
                  context.read<TodoListBloc>().add(const RegenerateBriefEvent());
                },
                icon: Icon(
                  Icons.refresh,
                  color: theme.appColors.base5,
                  size: 20,
                ),
                tooltip: 'Regenerovat Brief',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ),

        // Brief sections
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: state.briefSections!.length,
            itemBuilder: (context, index) {
              final sectionData = state.briefSections![index];
              return BriefSectionWidget(
                section: sectionData.section,
                todos: sectionData.todos,
                expandedTodoId: state.expandedTodoId,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Zobrazit loading dialog při generování pranku/good deed
  void _showPrankLoadingDialog(BuildContext context) {
    final theme = Theme.of(context);

    // Určit jestli jde o prank nebo good deed
    final prankState = context.read<PrankCubit>().state;
    final isPrank = prankState is PrankLoading ? prankState.isPrank : true;

    // Vtipné texty
    final loadingTexts = isPrank
        ? [
            '🎭 Pozoooor, vymýšlím vtipný prank...',
            '🤔 Hmmm, co by bylo vtipné...',
            '😄 Tohle bude legrace!',
            '🎉 Chystám skvělý nápad...',
            '🎪 Moment, kontroluji bezpečnost...',
          ]
        : [
            '💚 Chvíli, vymýšlím dobrý skutek...',
            '🌟 Hledám něco hezkého pro tebe...',
            '✨ Tohle bude krásné!',
            '💝 Připravuji laskavý nápad...',
            '🌈 Moment, najdu něco speciálního...',
          ];

    // Náhodný text
    final randomText = (loadingTexts..shuffle()).first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: theme.appColors.base2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrank ? theme.appColors.yellow : theme.appColors.green,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: isPrank ? theme.appColors.yellow : theme.appColors.green,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                randomText,
                style: TextStyle(
                  color: theme.appColors.base8,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
