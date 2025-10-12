import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';
import '../widgets/timer_display.dart';
import '../widgets/timer_controls.dart';
import '../widgets/settings_panel.dart';
import '../widgets/history_list.dart';
import '../../domain/services/pomodoro_timer_service.dart';
import '../../data/repositories/pomodoro_repository_impl.dart';
import '../../../../core/services/database_helper.dart';

/// Stránka Pomodoro Timer
///
/// Zobrazuje:
/// - Velký časovač
/// - Control buttons (Start/Pause/Stop)
/// - Nastavení (work/break duration)
/// - Historie sessions
///
/// Parametr [showAppBar]:
/// - false: Používá se v PageView (MainPage má společný AppBar)
/// - true: Používá se jako samostatný route (např. z TODO Card)
///
/// Parametr [taskId] a [duration]:
/// - Pokud jsou nastaveny, timer se automaticky spustí při otevření
class PomodoroPage extends StatelessWidget {
  final bool showAppBar;
  final int? taskId;
  final Duration? duration;

  const PomodoroPage({
    super.key,
    this.showAppBar = false,
    this.taskId,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final content = BlocProvider(
      create: (context) {
        final bloc = PomodoroBloc(
          repository: PomodoroRepositoryImpl(
            databaseHelper: DatabaseHelper(),
          ),
          timerService: PomodoroTimerService(),
        );

        // Load history
        bloc.add(const LoadHistoryEvent());

        // Auto-start timer pokud máme taskId a duration
        if (taskId != null && duration != null) {
          bloc.add(StartPomodoroEvent(taskId!, duration));
        }

        return bloc;
      },
      child: BlocListener<PomodoroBloc, PomodoroState>(
        listener: (context, state) {
          // Zobrazit error message jako SnackBar
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Timer Display (kompaktni casovac)
              const TimerDisplay(),
              const SizedBox(height: 16),

              // Task Info
              const _TaskInfo(),
              const SizedBox(height: 24),

              // Controls (Start/Pause/Stop buttons)
              const TimerControls(),
              const SizedBox(height: 32),

              // Settings Panel (konfigurace)
              const SettingsPanel(),
              const SizedBox(height: 32),

              // History (seznam sessions)
              const HistoryList(),
            ],
          ),
        ),
      ),
    );

    // Pokud showAppBar = true, obal do Scaffold s AppBar
    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🍅 Pomodoro Timer'),
          centerTitle: true,
        ),
        body: content,
      );
    }

    // Jinak vrať pouze content (pro PageView v MainPage)
    return content;
  }
}

/// Widget zobrazující informace o aktuálním úkolu
class _TaskInfo extends StatelessWidget {
  const _TaskInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) =>
          previous.currentTaskId != current.currentTaskId ||
          previous.sessionCount != current.sessionCount,
      builder: (context, state) {
        if (state.currentTaskId == null) {
          return const Text(
            'Vyberte úkol ze seznamu úkolů',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          );
        }

        return Column(
          children: [
            Text(
              'Úkol #${state.currentTaskId}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Session: #${state.sessionCount}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}
